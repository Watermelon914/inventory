util.AddNetworkString("containerSystem.OpenInventory")
local plyMeta = FindMetaTable("Entity")
local IsPlayer = plyMeta.IsPlayer
local IsValid = IsValid
local CurTime = CurTime
PrintTable(hook.GetTable()["PlayerUse"])

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

concommand.Add("create_ent_inventory", function(ply, cmd, args, argStr)
    local ent = ply:GetEyeTrace().Entity
    if ent:IsPlayer() or ent:IsWorld() then return end
    local sizeX, sizeY = tonumber(args[1]), tonumber(args[2])
    if sizeX == nil or sizeY == nil then return end
    ent:CreateInventory()
    local inventory = ent:GetInventory()
    inventory:SetParent(ent)
    inventory:GenerateSlots(sizeX, sizeY)
end)