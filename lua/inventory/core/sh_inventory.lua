inventorySystem.inventoryMeta = inventorySystem.inventoryMeta or {}
local inventoryMeta = inventorySystem.inventoryMeta
inventorySystem.InteractionRange = 150

function inventoryMeta:Initialize()
    self.Listeners = {}
    self.Contents = {}
    self.ValidSlots = {}
end

function inventoryMeta:SetParent(entity)
    if SERVER and IsValid(self.Parent) and self.Parent:IsPlayer() then
        self:RemoveListener(self.Parent)
    end

    self.Parent = entity

    if not CLIENT then
        self.Parent:CallOnRemove("inventory" .. self:GetInventoryId(), function(ent)
            if self.Parent == ent then
                self:Remove()
            end
        end)
    end

    if SERVER then
        if entity:IsPlayer() then
            self:AddListener(entity)
        end

        self:SendFullUpdateToPlayer(self:GetListeners())
    end
end

function inventoryMeta:Remove()
    inventorySystem.DeleteInventory(self)
end

function inventoryMeta:GetParent()
    return self.Parent
end

function inventoryMeta:GetPos()
    if not self.Parent then return nil end

    return self.Parent:GetPos()
end

function inventoryMeta:GenerateSlots(x, y, specialSlots)
    self.SizeX = x or 5
    self.SizeY = y or 2
    self:ClearSlots()
    specialSlots = specialSlots or {}

    for _, slot in ipairs(specialSlots) do
        self.ValidSlots[slot] = true
    end

    for i = 1, x * y do
        self.ValidSlots["slot" .. i] = true
    end

    self:SendFullUpdateToPlayer(self:GetListeners())
end

function inventoryMeta:GetEmptySlot()
    for i = 1, self.SizeX * self.SizeY do
        if not IsValid(self.Contents["slot" .. i]) then return "slot" .. i end
    end

    return nil
end

function inventoryMeta:ClearSlots()
    for slot, value in pairs(self.Contents) do
        if IsValid(value) then
            inventorySystem.DeleteItem(value)
        end

        slot = nil
    end

    if SERVER then
        self:SendFullUpdateToPlayer(self:GetListeners())
    end
end

function inventoryMeta:GetItem(slot)
    return self.Contents[slot]
end

function inventoryMeta:IsValid()
    if self.__Deleted then return false end

    return true
end

function inventoryMeta:GetInventoryId()
    return self.__InventoryId
end

function inventoryMeta:AddListener(ply)
    self.Listeners[ply] = true
end

function inventoryMeta:RemoveListener(ply)
    self.Listeners[ply] = nil
end

function inventoryMeta:GetListeners()
    local listeners = {}

    for ply, key in pairs(self.Listeners) do
        if self:GetParent() and ply:GetPos():DistToSqr(self:GetPos()) > math.pow(inventorySystem.InteractionRange, 2) then
            self:RemoveListener(ply)
            continue
        end

        table.insert(listeners, ply)
    end

    return listeners
end

hook.Add("inventorySystem.CanTransferTo", inventorySystem, function(self, itemInventory, itemSlot, targetInventory, targetSlot)
    local ent1, ent2 = itemInventory:GetParent(), targetInventory:GetParent()
    if ent1:IsPlayer() and ent2:IsPlayer() and ent1 ~= ent2 then return false end
end)

-- Adds an item to the slot in the inventorySystem. Automatically fails if the slot is occupied
function inventoryMeta:AddItem(slot, item)
    if not self.ValidSlots[slot] then return false end
    local currentItem = self.Contents[slot]
    if IsValid(currentItem) then return false end
    item:AddToInventory(self, slot)
    self.Contents[slot] = item
    local listeners = self:GetListeners()

    self:SendUpdateToPlayer({slot}, listeners)

    return true
end

function inventoryMeta:RemoveItem(slot)
    local item = self.Contents[slot]

    if not IsValid(item) then
        self.Contents[slot] = nil

        return
    end

    item:RemoveFromInventory(self, slot)
    self.Contents[slot] = nil

    self:SendUpdateToPlayer({slot}, self:GetListeners())

    return item
end

inventoryMeta.__index = inventoryMeta
inventorySystem.__inventoryidtracker = inventorySystem.__inventoryidtracker or 1
inventorySystem.__inventories = inventorySystem.__inventories or {}

function inventorySystem.CreateInventory()
    local newInstance = {}

    if SERVER then
        newInstance.__InventoryId = inventorySystem.__inventoryidtracker
        inventorySystem.__inventories[newInstance.__InventoryId] = newInstance
        inventorySystem.__inventoryidtracker = inventorySystem.__inventoryidtracker + 1
    end

    setmetatable(newInstance, inventoryMeta)
    newInstance:Initialize()

    return newInstance
end

function inventorySystem.GetInventoryFromId(id)
    local inventory = inventorySystem.__inventories[id]

    if not IsValid(inventory) then
        if SERVER then return nil end
        inventory = inventorySystem.CreateInventory()
        inventory.__InventoryId = id
        inventorySystem.__inventories[id] = inventory
    end

    return inventory
end

function inventorySystem.DeleteInventory(inventoryToDiscard)
    inventoryToDiscard:ClearSlots()
    inventoryToDiscard.Listeners = nil
    inventoryToDiscard.Contents = nil
    inventorySystem.__inventories[inventoryToDiscard.__InventoryId] = nil
    inventoryToDiscard.__Deleted = true
end

local entMeta = FindMetaTable("Entity")

function entMeta:GetInventory()
    return self.Inventory
end

function entMeta:CreateInventory()
    if self.Inventory then
        inventorySystem.DeleteInventory(self.Inventory)
    end

    self.Inventory = inventorySystem.CreateInventory()

    return self.Inventory
end

function inventorySystem.GetSlotType(slotType)
    return string.gsub(slotType, "[0-9]", "")
end