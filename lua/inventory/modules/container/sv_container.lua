util.AddNetworkString("containerSystem.OpenInventory")
local plyMeta = FindMetaTable("Entity")
local IsPlayer = plyMeta.IsPlayer
local IsValid = IsValid
local CurTime = CurTime

hook.Add("PlayerUse", containerSystem, function(self, ply, ent)
    if (ply.ContainerCooldown or 0) > CurTime() then return end
    ply.ContainerCooldown = CurTime() + 1
    if IsPlayer(ply) then return end
    local inventory = ent:GetInventory()
    if not IsValid(inventory) then return end

    if not inventory.Listeners[ply] then
        inventory:AddListener(ply)

        inventory:SendFullUpdateToPlayer({ply})
    end

    net.Start("containerSystem.OpenInventory")
    net.WriteEntity(ent)
    net.WriteUInt(inventory:GetInventoryId(), 16)
    net.WriteUInt(inventory.SizeX, 8)
    net.WriteUInt(inventory.SizeY, 8)
    net.Send(ply)
end)

concommand.Add("spawn_container", function(ply, cmd, args, argStr)
    local sizeX, sizeY = tonumber(args[1]), tonumber(args[2])
    local model = args[3]
    local possibleItems = string.Explode(",", args[4] or "")
    if sizeX == nil or sizeY == nil then return end
    sizeX, sizeY = math.Clamp(sizeX, 0, 127), math.Clamp(sizeY, 0, 127)
    sizeX = math.floor(sizeX)
    sizeY = math.floor(sizeY)
    local ent

    if not util.IsValidModel(model) then
        ent = ply:GetEyeTrace().Entity
        if ent:IsPlayer() or ent:IsWorld() then return end
    else
        ent = ents.Create("base_anim")
        ent:SetPos(util.QuickTrace(ply:EyePos(), ply:GetAimVector() * 50, ply).HitPos)
        ent:SetModel(model)
        ent:Spawn()

        if SERVER then
            ent:PhysicsInit(SOLID_VPHYSICS)
        end

        ent:PhysWake()
    end

    ent:CreateInventory()
    local inventory = ent:GetInventory()
    inventory:SetParent(ent)
    inventory:GenerateSlots(sizeX, sizeY)
    local CurTime = CurTime

    if possibleItems and #possibleItems > 0 then
        inventory.NextRefill = 0
        inventory.PossibleItems = possibleItems

        hook.Add("Tick", inventory, function(self)
            if self.NextRefill > CurTime() then return end
            self.NextRefill = CurTime() + 10
            local emptySlot = self:GetEmptySlot()
            if not emptySlot then return end
            local item = self.PossibleItems[math.random(#self.PossibleItems)]
            local createdItem = inventorySystem.CreateItem(item)
            self:AddItem(emptySlot, createdItem)
        end)
    end
end)