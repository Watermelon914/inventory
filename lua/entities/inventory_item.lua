AddCSLuaFile()
ENT.PrintName = "Inventory Item"
ENT.Spawnable = false
ENT.Type = "anim"

function ENT:Initialize()
    if not self.Item then
        if SERVER then
            self:Remove()
        elseif self:GetItemId() then
            self.Item = inventorySystem.GetItemFromId(self:GetItemId(), "item_loading")
        end
    end

    if SERVER then
        self:SetModel(self.Item:GetModel())
    end

    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
    end

    self:PhysWake()
    self.TrackedPlayers = {}
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:Use(ply, caller, usetype, integer)
    local inventory = ply:GetInventory()
    local slot = inventory:GetEmptySlot()
    if slot == nil then return end
    if not self.Item then return end
    inventory:AddItem(slot, self.Item)
    self:SetItemId(-1)
    self:PerformTakenAnimation(ply)
    self:Remove()
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ItemId")
    self:NetworkVarNotify("ItemId", self.OnStateChanged)
end

function ENT:OnStateChanged(name, old, new)
    local item = inventorySystem.GetItemFromId(old, "item_loading")

    if IsValid(item) and item.ItemLocation == self then
        item.ItemLocation = nil
    end

    if new == -1 then
        self.Item = nil

        return
    end

    self.Item = inventorySystem.GetItemFromId(new, "item_loading")

    if not IsValid(self.Item) then
        error("Set " .. self.ClassName .. " to an invalid item! (expected item, got " .. type(self.Item) .. ")")

        return
    end

    self.Item.ItemLocation = self
end

function ENT:OnRemove()
    if self.Item and SERVER then
        inventorySystem.DeleteItem(self.Item)
    end
end

if SERVER then
    function ENT:Tick()
        for _, ply in ipairs(player.GetHumans()) do
            local inPVS = ply:TestPVS(self)

            if not inPVS and TrackedPlayers[ply] then
                TrackedPlayers[ply] = nil
            elseif inPVS and not TrackedPlayers[ply] then
                TrackedPlayers[ply] = true
                self.Item:SendFullUpdate(ply)
            end
        end
    end

    function ENT:PerformTakenAnimation(plyTaker)
        net.Start("inventorySystem.PerformItemAnimation")
        net.WriteString(self:GetModel())
        net.WriteVector(self:GetPos())
        net.WriteAngle(self:GetAngles())
        net.WriteEntity(plyTaker)
        net.WriteFloat(1.11)
        net.SendPVS(self:GetPos())
    end
else
    function ENT:PerformTakenAnimation(plyTaker)
        return
    end

    net.Receive("inventorySystem.PerformItemAnimation", function(len)
        local model = net.ReadString()
        local from = net.ReadVector()
        local angle = net.ReadAngle()
        local plyTaker = net.ReadEntity()
        local speed = net.ReadFloat()
        -- if LocalPlayer() == plyTaker then return end
        local renderData = {}
        renderData.IsValid = function(self) return not renderData.Finished end
        renderData.Model = ClientsideModel(model, RENDERGROUP_OTHER)
        renderData.CurrentPos = from
        renderData.CurrentAngle = angle
        renderData.Speed = 1 / speed
        renderData.CurrentMatrix = Matrix()
        renderData.StartTime = CurTime()

        renderData.Finish = function(self)
            self.Finished = true
            self.Model:Remove()
        end

        local bone = plyTaker:LookupBone("ValveBiped.Bip01_Spine")
        renderData.OriginalDistance = (bone and plyTaker:GetBonePosition(bone) or plyTaker:GetPos()):Distance(renderData.CurrentPos)

        hook.Add("PostDrawOpaqueRenderables", renderData, function(self, drawingDepth, drawingSkybox)
            local position = bone and plyTaker:GetBonePosition(bone) or plyTaker:GetPos()
            local distance = self.CurrentPos:Distance(position)

            if not IsValid(plyTaker) or distance > 300 then
                self:Finish()

                return
            end

            render.SetBlend(math.min(distance / 100, 1))
            local scaleMatrix = Matrix()
            scaleMatrix:SetScale(Vector(1, 1, 1) * math.min(distance / self.OriginalDistance, 1))
            self.Model:EnableMatrix("RenderMultiply", scaleMatrix)
            self.CurrentPos = LerpVector(1 - math.pow(self.Speed, CurTime() - self.StartTime), self.CurrentPos, position)
            self.Model:SetPos(self.CurrentPos)
            self.Model:SetAngles(self.CurrentAngle)
            self.Model:DrawModel()

            if distance < 5 then
                self:Finish()

                return
            end
        end)
    end)
end