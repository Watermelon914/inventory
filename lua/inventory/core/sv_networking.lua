util.AddNetworkString("inventorySystem.Movement")
util.AddNetworkString("inventorySystem.Update")
util.AddNetworkString("inventorySystem.Drop")
util.AddNetworkString("inventorySystem.UpdateItem")
util.AddNetworkString("inventorySystem.DeleteItem")
util.AddNetworkString("inventorySystem.PerformItemAnimation")
local inventoryMeta = inventorySystem.inventoryMeta

net.Receive("inventorySystem.Update", function(len, ply)
    if ply.ReceivedInventory ~= true then
        ply:GetInventory():SendFullUpdateToPlayer(ply)
        ply.ReceivedInventory = true
    end
end)

function inventoryMeta:SendFullUpdateToPlayer(plys)
    self:SendUpdateToPlayer(table.GetKeys(self.ValidSlots), plys)
end

function inventoryMeta:SendUpdateToPlayer(slots, plys)
    if not IsValid(plys) and table.Count(plys) <= 0 then return end
    local info = {}

    for _, slot in ipairs(slots) do
        if self.Contents[slot] == nil then
            info[slot] = -1
        else
            local item = self.Contents[slot]
            info[slot] = item:GetItemId()
            item:SendFullUpdate(plys)
        end
    end

    net.Start("inventorySystem.Update")
    net.WriteUInt(self:GetInventoryId(), 16)
    net.WriteEntity(self:GetParent())
    local data = util.Compress(util.TableToJSON(info))
    net.WriteUInt(#data, 16)
    net.WriteData(data, #data)
    net.Send(plys)
end

function inventorySystem.PerformItemDrop(ply, itemToRemove)
    if not IsValid(itemToRemove) then return end
    net.Start("inventorySystem.Drop")
    net.WriteUInt(1, 4)
    net.WriteString(itemToRemove:GetName())
    net.Send(ply)
    ply:DoAnimationEvent(ACT_GMOD_GESTURE_ITEM_DROP)

    timer.Simple(1, function()
        if not IsValid(itemToRemove) then return end

        if not IsValid(ply) then
            inventorySystem.DeleteItem(itemToRemove)

            return
        end

        local model = itemToRemove:CreatePhysical()
        model:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        model:SetPos(util.QuickTrace(ply:EyePos(), ply:GetAimVector() * 20).HitPos)
        model:SetAngles(ply:EyeAngles())
        model:Spawn()
        local phys = model:GetPhysicsObject()

        if IsValid(phys) then
            phys:SetVelocity(ply:GetAimVector() * 100)
        end

        timer.Simple(1, function()
            if not IsValid(model) then return end
            model:SetCollisionGroup(COLLISION_GROUP_NONE)
        end)
    end)
end

net.Receive("inventorySystem.Drop", function(len, ply)
    if (ply.NextInventoryMovement or 0) > CurTime() then return end
    ply.NextInventoryMovement = CurTime() + 0.1
    local itemInventory = inventorySystem.GetInventoryFromId(net.ReadUInt(16))
    if not itemInventory then return end
    local itemSlot = net.ReadString()
    if not itemInventory.ValidSlots[itemSlot] then return end
    if itemInventory:GetParent() ~= ply and itemInventory:GetPos():DistToSqr(ply:GetPos()) > math.pow(inventorySystem.InteractionRange, 2) then return end
    if hook.Run("inventorySystem.CanDrop", itemInventory, itemSlot) == false then return end
    local itemToRemove = itemInventory:RemoveItem(itemSlot)
    inventorySystem.PerformItemDrop(ply, itemToRemove)
end)

net.Receive("inventorySystem.Movement", function(len, ply)
    if (ply.NextInventoryMovement or 0) > CurTime() then return end
    ply.NextInventoryMovement = CurTime() + 0.1
    local itemInventory = inventorySystem.GetInventoryFromId(net.ReadUInt(16))
    if not itemInventory then return end
    local itemSlot = net.ReadString()
    if not itemInventory.ValidSlots[itemSlot] then return end
    local targetInventory = inventorySystem.GetInventoryFromId(net.ReadUInt(16))
    if not targetInventory then return end
    local targetSlot = net.ReadString()
    if not targetInventory.ValidSlots[targetSlot] then return end
    if not IsValid(itemInventory:GetParent()) or not IsValid(targetInventory:GetParent()) then return end
    if itemInventory:GetPos():DistToSqr(targetInventory:GetPos()) > math.pow(inventorySystem.InteractionRange, 2) then return end
    if hook.Run("inventorySystem.CanTransferTo", itemInventory, itemSlot, targetInventory, targetSlot) == false then return end
    local itemToCheck = targetInventory:GetItem(itemSlot)
    if not IsValid(itemToCheck) or not itemToCheck:CanAddToInventory(targetInventory, targetSlot) then return end
    local swappingItem = itemInventory:GetItem(targetSlot)
    if IsValid(swappingItem) and (not swappingItem:CanAddToInventory(itemInventory, itemSlot) or swappingItem:ReceiveDropped(itemToCheck) == true) then return end
    local removedItem = itemInventory:RemoveItem(itemSlot)
    if not IsValid(removedItem) then return end
    local itemToSwap = targetInventory:RemoveItem(targetSlot)
    targetInventory:AddItem(targetSlot, removedItem)

    if IsValid(itemToSwap) then
        itemInventory:AddItem(itemSlot, itemToSwap)
    end

    local function performItemAnimation(model, fromEnt, toEnt)
        local bone = fromEnt:LookupBone("ValveBiped.Bip01_Spine")
        local position = bone and fromEnt:GetBonePosition(bone) or fromEnt:GetPos()
        net.Start("inventorySystem.PerformItemAnimation")
        net.WriteString(model)
        net.WriteVector(position)
        net.WriteAngle(Angle(0, 0, 0))
        net.WriteEntity(toEnt)
        net.SendPVS(position)
    end

    if targetInventory ~= itemInventory then
        performItemAnimation(removedItem.Model, itemInventory:GetParent(), targetInventory:GetParent())

        if IsValid(itemToSwap) then
            performItemAnimation(itemToSwap.Model, targetInventory:GetParent(), itemInventory:GetParent())
        end
    end
end)