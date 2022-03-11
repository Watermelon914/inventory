net.Receive("inventorySystem.Update", function(len)
    local inventoryId = net.ReadUInt(16)
    local parent = net.ReadEntity()
    local data = util.JSONToTable(util.Decompress(net.ReadData(net.ReadUInt(16))))
    local inventory = inventorySystem.GetInventoryFromId(inventoryId)
    inventory:SetParent(parent)
    local contents = inventory.Contents

    for slot, id in pairs(data) do
        if id ~= -1 then
            contents[slot] = inventorySystem.GetItemFromId(id, "base_item")
            contents[slot]:AddToInventory(inventory, slot)
        else
            contents[slot] = nil
        end
    end

    if parent == LocalPlayer() then
        inventorySystem.UpdatePlayerInventory(inventory)
        inventorySystem.localPlayerInventory = inventory
    elseif IsValid(inventory.InventoryUI) then
        inventory.InventoryUI:UpdateData(inventory)
    end
end)

net.Receive("inventorySystem.UpdateItem", function(len)
    local itemId = net.ReadUInt(16)
    local itemClass = net.ReadString()
    local metadata = inventorySystem.items[itemClass]
    local item = inventorySystem.GetItemFromId(itemId, itemClass)

    if getmetatable(item) == inventorySystem.items["base_item"] and itemClass ~= "base_item" then
        setmetatable(item, metadata)

        if item.InventoryLocation then
            inventorySystem.UpdatePlayerInventory(item.InventoryLocation)
        end
    end

    if not item.__Initialized then
        item:Initialize()
    end

    local amountOfVariables = net.ReadUInt(16)

    for i = 1, amountOfVariables do
        local variableName = net.ReadString()
        local netType = item.TrackedVariables[variableName]
        local value = net["Read" .. netType](32)

        if isfunction(item["On" .. variableName .. "Change"]) then
            item["On" .. variableName .. "Change"](item, value)
        end

        if inventorySystem.debug then
            print("Receiving information for " .. item:__tostring() .. " Var: " .. variableName .. " Value: " .. tostring(value))
        end

        item[variableName] = value
    end
end)

net.Receive("inventorySystem.DeleteItem", function(len)
    local itemId = net.ReadUInt(16)
    inventorySystem.DeleteItemId(itemId)
end)

local currentDrawingInstance

net.Receive("inventorySystem.Drop", function(len)
    local time = net.ReadUInt(4)
    local item = net.ReadString()
    local RenderTimeEnd = CurTime() + time
    currentDrawingInstance = {}
    currentDrawingInstance.IsValid = function(self) return RenderTimeEnd >= CurTime() and currentDrawingInstance == self end
    local width = ScrW() * 0.1
    local height = 12
    local x = (ScrW() - width) / 2
    local y = (ScrH() - height) / 2

    hook.Add("HUDPaint", currentDrawingInstance, function(self)
        surface.SetDrawColor(Color(20, 20, 20, 127))
        surface.DrawRect(x, y, width, height)
        surface.SetDrawColor(Color(255, 64, 64, 255))
        surface.DrawRect(x, y, width * (1 - math.Clamp(RenderTimeEnd - CurTime(), 0, 1)), height)
        surface.SetDrawColor(Color(0, 0, 0, 255))
        surface.DrawOutlinedRect(x, y, width, height, 1)
        surface.SetFont("Trebuchet24")
        local _, textY = surface.GetTextSize("Dropping " .. item)
        draw.DrawText("Dropping " .. item, "Trebuchet24", ScrW() / 2, y - (textY + 4), Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
    end)
end)

local inventoryMeta = inventorySystem.inventoryMeta

function inventoryMeta:SendUpdateToPlayer(slots, players)
    if self:GetParent() == LocalPlayer() then
        inventorySystem.UpdatePlayerInventory(inventory)
    end
end