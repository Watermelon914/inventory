function inventorySystem.MakeStackModel(model, offset)
    return {
        model = model,
        offset = offset or Vector(0, 0, 0)
    }
end

local function CreateInventoryUI(inventory, sizeX, sizeY)
    local InventoryPanel = vgui.Create("DPanel", inventorySystem.backgroundFrame)
    local multiplier = inventorySystem.slotLength + inventorySystem.slotSpacing
    InventoryPanel:SetSize(multiplier * sizeX - inventorySystem.slotSpacing, multiplier * sizeY - inventorySystem.slotSpacing)
    InventoryPanel:Hide()
    InventoryPanel:SetZPos(1)
    local BackgroundCol = Color(10, 10, 10, 228)

    InventoryPanel.Paint = function(self, width, height)
        surface.SetDrawColor(BackgroundCol)
        surface.DrawRect(0, 0, width, height)
    end

    local parent = inventory:GetParent()
    local position = Vector(0, 0, 0)
    local center = Vector(0, 0, 0)

    hook.Add("PostDrawOpaqueRenderables", InventoryPanel, function(self)
        if not IsValid(parent) then
            hook.Remove("PostDrawOpaqueRenderables", InventoryPanel)

            return
        end

        position:Set(parent:GetPos())
        center:Set(parent:GetUp())
        center:Mul(-parent:OBBMaxs().z / 2)
        position:Sub(center)
        local screenPos = position:ToScreen()
        InventoryPanel:SetPos(screenPos.x - (multiplier * sizeX) / 2, screenPos.y)

        if not InventoryPanel:IsVisible() then
            InventoryPanel:Show()
            InventoryPanel:SetMouseInputEnabled(true)
        end
    end)

    hook.Add("Tick", InventoryPanel, function(self)
        if not IsValid(inventory:GetParent()) then
            InventoryPanel:Remove()

            return
        end

        if inventory:GetPos():DistToSqr(LocalPlayer():GetPos()) > math.pow(inventorySystem.InteractionRange, 2) then
            InventoryPanel:Remove()
        end
    end)

    local allSlots = {}
    local MakeSlot = inventorySystem.MakeSlotFunction(allSlots, inventory, 1)

    for y = 0, sizeY - 1 do
        for x = 0, sizeX - 1 do
            local xPos = x * (inventorySystem.slotLength + inventorySystem.slotSpacing)
            local yPos = y * (inventorySystem.slotLength + inventorySystem.slotSpacing)
            MakeSlot(xPos, yPos, Color(0, 0, 0, 127), InventoryPanel, "slot" .. (y * sizeX) + (x + 1))
        end
    end

    InventoryPanel.UpdateData = function(self, updatedInventory, slots)
        for _, slot in ipairs(slots) do
            allSlots[slot]:GenerateItem(updatedInventory)
        end
    end

    return InventoryPanel
end

net.Receive("containerSystem.OpenInventory", function(len)
    local ent = net.ReadEntity()
    local id = net.ReadUInt(16)
    local sizeX = net.ReadUInt(8)
    local sizeY = net.ReadUInt(8)
    ent.Inventory = inventorySystem.GetInventoryFromId(id)
    local inventory = ent.Inventory

    if not IsValid(inventory.InventoryUI) then
        inventory.InventoryUI = CreateInventoryUI(ent.Inventory, sizeX, sizeY)
    end
end)