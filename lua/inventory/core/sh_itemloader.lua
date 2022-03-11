hook.Run("PreItemLoaded")
local path = "inventory/items/"
inventorySystem.items = {}
local result, folders = file.Find(path .. "*.lua", "LUA")

for _, itemFolder in ipairs(folders) do
    table.insert(result, 1, itemFolder .. "/" .. itemFolder .. ".lua")
end

for _, item in ipairs(result) do
    local fileName = string.sub(item, 1, #item - 4)

    if not baseclass.Get(fileName) then
        baseclass.Set(fileName, {})
    end
end

for _, item in ipairs(result) do
    local fileName = string.sub(item, 1, #item - 4)
    ITEM = baseclass.Get(fileName)
    ITEM.Name = "Unnamed"
    ITEM.Description = "No description available"
    ITEM.Base = "base_item"
    ITEM.Derma = {}
    ITEM.Derma.__index = ITEM.Derma
    ITEM.DermaDesc = {}
    ITEM.DermaDesc.__index = ITEM.DermaDesc
    ITEM.DermaDesc.SizeX = 200
    ITEM.DermaDesc.SizeY = 250
    AddCSLuaFile(path .. item)
    include(path .. item)
    ITEM.FileName = fileName -- Just in case they tried overriding it

    if ITEM.FileName ~= "base_item" and (not ITEM.Base or not baseclass.Get(ITEM.Base)) then
        print("WARNING: Scripted item " .. ITEM.FileName .. " has an invalid base item!")
    end

    ITEM.__index = ITEM
    inventorySystem.items[ITEM.FileName] = ITEM
end

for fileName, item in pairs(inventorySystem.items) do
    if inventorySystem.items[item.Base] then
        setmetatable(item, inventorySystem.items[item.Base])
        setmetatable(item.Derma, inventorySystem.items[item.Base].Derma)
        setmetatable(item.DermaDesc, inventorySystem.items[item.Base].DermaDesc)
    end
end

ITEM = {}
ITEM.DermaDesc = {}
ITEM.Derma = {}
--  Prevents errors during lua refreshes, but won't affect the last loaded item
inventorySystem.InvalidItem = {}
setmetatable(inventorySystem.InvalidItem, inventorySystem.BaseItem)
hook.Run("PostItemLoaded")

function inventorySystem.GetItemClass(className)
    return inventorySystem.items[className]
end

inventorySystem.__itemidtracker = inventorySystem.__itemidtracker or 1
inventorySystem.__items = inventorySystem.__items or {}

function inventorySystem.CreateItem(className, initialize, ...)
    if initialize == nil then
        initialize = true
    end

    local class = inventorySystem.items[className]

    if not class then
        error("Invalid class passed to inventorySystem.CreateItem (className: " .. tostring(className) .. ")")

        return
    end

    local newInstance = {
        Derma = {},
        DermaDesc = {}
    }

    if SERVER then
        newInstance.__ItemId = inventorySystem.__itemidtracker
        inventorySystem.__items[newInstance.__ItemId] = newInstance
        inventorySystem.__itemidtracker = inventorySystem.__itemidtracker + 1
    end

    setmetatable(newInstance, class)
    setmetatable(newInstance.Derma, class.Derma)
    setmetatable(newInstance.DermaDesc, class.DermaDesc)

    if initialize then
        newInstance:Initialize(...)
    end

    return newInstance
end

function inventorySystem.ClassExists(className)
    local class = inventorySystem.items[className]
    if not class then return false end

    return true
end

function inventorySystem.DeleteItem(item)
    if not IsValid(item) then
        if CLIENT then return end

        if item.__Deleted or item == item.InvalidItem then
            error("Tried to delete an item that is already deleted!")
        else
            error("Tried to delete an invalid item! (expected Item, got " .. type(item) .. ")")
        end

        return
    end

    if IsValid(item.InventoryLocation) then
        local inventory = item.InventoryLocation
        inventory:RemoveItem(item.SlotLocation)
    end

    if IsValid(item.ItemLocation) then
        item.ItemLocation:Remove()
    end

    item:OnRemove()
    item.__Deleted = true
    if not item.__ItemId then return end

    if SERVER then
        net.Start("inventorySystem.deleteItem")
        net.WriteUInt(item:GetItemId(), 16)
        net.Send(player.GetHumans())
    end

    inventorySystem.__items[item.__ItemId] = inventorySystem.InvalidItem
end

function inventorySystem.DeleteItemId(itemid)
    local item = inventorySystem.__items[itemid]
    if not IsValid(item) then return end
    if item == inventorySystem.InvalidItem then return end
    inventorySystem.DeleteItem(item)
end

function inventorySystem.GetItemFromId(itemid, expectedClass)
    local item = inventorySystem.__items[itemid]

    if not IsValid(item) then
        if SERVER then return nil end
        item = inventorySystem.CreateItem(expectedClass, false)
        item.__ItemId = itemid
        inventorySystem.__items[itemid] = item
    end

    return item
end

if CLIENT then
    function inventorySystem.CreateAction(item, action)
        return function()
            if not IsValid(item) then return end
            item:PerformAction(action)
        end
    end
end