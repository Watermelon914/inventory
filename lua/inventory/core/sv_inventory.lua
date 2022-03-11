hook.Add("PlayerInitialSpawn", inventorySystem, function(self, ply, transition)
    local playerInventory = ply:CreateInventory()
    playerInventory:SetParent(ply)

    playerInventory:GenerateSlots(5, 2, {"helmet", "mask", "armor", "suit", "utility", "weapon1", "weapon2", "weapon3", "weapon4", "weapon5"})
end)

hook.Add("PlayerDeath", inventorySystem, function(self, ply, inflictor, attacker)
    local playerInv = ply:GetInventory()
    playerInv:ClearSlots()
end)

local ignoreWeapons = {
    ["weapon_fists"] = true,
    ["gmod_camera"] = true,
    ["gmod_tool"] = true
}

hook.Add("PlayerCanPickupWeapon", inventorySystem, function(self, ply, weapon)
    if IsValid(weapon.Item) then return end
    if ignoreWeapons[weapon:GetClass()] then return end
    -- Non-scripted weapons like the default hl2 weapons
    if not weapons.GetStored(weapon:GetClass()) then return end
    local playerInv = ply:GetInventory()
    local emptySlot = playerInv:GetEmptySlot()
    if not emptySlot then return false end
    local item = inventorySystem.CreateItem("base_weapon", true, weapon:GetClass())
    playerInv:AddItem(emptySlot, item)
    weapon:Remove()

    return false
end)

concommand.Add("spawn_item", function(ply, cmd, args, argStr)
    if not ply:IsSuperAdmin() then return end
    if not inventorySystem.ClassExists(args[1]) then return end
    local item = inventorySystem.CreateItem(args[1])
    local physicalEntity = item:CreatePhysical()
    physicalEntity:SetPos(ply:GetEyeTrace().HitPos)
    physicalEntity:Spawn()
    undo.Create("Item")
    undo.AddEntity(physicalEntity)
    undo.SetPlayer(ply)
    undo.Finish("Item (" .. item.Name .. ")")
end)