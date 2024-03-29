local PANEL = {}

surface.CreateFont("item_desc_text", {
    font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
    extended = false,
    size = 14,
    weight = 800,
    blursize = 0,
    scanlines = 0,
    antialias = true,
})

surface.CreateFont("item_title_text", {
    font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
    extended = false,
    size = 18,
    weight = 800,
    blursize = 0,
    scanlines = 1,
    antialias = true,
})

function PANEL:Init()
    self:Receiver("inventorySystem", function(pnl, tbl, dropped, menuIndex, x, y)
        if not dropped then
            self.InternalColor = self.ColorHighlighted

            return
        else
            self.InternalColor = self.ColorNormal
        end

        local originSlot = tbl[1]:GetParent()
        if not IsValid(originSlot.Inventory) or not IsValid(self.Inventory) then return end
        net.Start("inventorySystem.Movement")
        net.WriteUInt(originSlot.Inventory:GetInventoryId(), 16)
        net.WriteString(originSlot.SlotId)
        net.WriteUInt(self.Inventory:GetInventoryId(), 16)
        net.WriteString(self.SlotId)
        net.SendToServer()
    end)

    self.ColorHighlighted = Color(80, 80, 80, 248)
    self.ColorNormal = Color(20, 20, 20, 248)
    self.InternalColor = self.ColorNormal
    self.BorderColor = Color(0, 0, 0, 127)
    self.TextHoverAlpha = 0
    self:SetSize(inventorySystem.slotLength, inventorySystem.slotLength)

    hook.Add("inventorySystem.HideLocalInventory", self, function()
        self.TextHoverAlpha = 0
    end)
end

function PANEL:Think()
    if dragndrop.IsDragging() then
        self.TextHoverAlpha = 0
        local droppable = dragndrop.GetDroppable("inventorySystem")[1]
        if not droppable then return end
        local myInventory = self.Inventory
        local mySlotId = self.SlotId
        local itemInventory = droppable:GetParent().Inventory
        local itemSlot = droppable:GetParent().SlotId

        if not IsValid(itemInventory) or not IsValid(myInventory) then
            self.InternalColor = self.ColorNormal

            return
        end

        local item = droppable:GetItem()

        if self:IsHovered() and item:CanAddToInventory(self.Inventory, self.SlotId) and hook.Run("inventorySystem.CanTransferTo", itemInventory, itemSlot, myInventory, mySlotId) ~= false then
            self.InternalColor = self.ColorHighlighted
        else
            self.InternalColor = self.ColorNormal
        end

        return
    end

    self.InternalColor = self.ColorNormal

    if self.HoverInfo then
        local animSeconds = 0.1
        local maxAlpha = 127

        if self:IsHovered() then
            self.TextHoverAlpha = math.min(self.TextHoverAlpha + (RealFrameTime() * maxAlpha) / animSeconds, maxAlpha)
        else
            self.TextHoverAlpha = math.max(self.TextHoverAlpha - (RealFrameTime() * maxAlpha) / animSeconds, 0)
        end
    end
end

local SetDrawColor = surface.SetDrawColor
local DrawRect = surface.DrawRect
local DrawOutlinedRect = surface.DrawOutlinedRect
local SetFont = surface.SetFont
local GetTextSize = surface.GetTextSize
local DrawText = draw.DrawText
local SetAlphaMultiplier = surface.SetAlphaMultiplier

function PANEL:Paint(w, h)
    SetDrawColor(self.InternalColor)
    DrawRect(0, 0, w, h)
    SetDrawColor(self.BorderColor)
    DrawOutlinedRect(0, 0, w, h, 1)

    if self.HoverInfo and not self.Item then
        SetFont("item_slot_text")
        local _, y = GetTextSize(self.HoverInfo)
        SetAlphaMultiplier(self.TextHoverAlpha / 255)
        DrawText(self.HoverInfo, "item_slot_text", w / 2, h / 2 - y / 2, self.BorderColor, TEXT_ALIGN_CENTER)
    end
end

function PANEL:GenerateItem(inventoryToUse)
    if self.ItemPanel then
        self.ItemPanel:Remove()
    end

    self.Inventory = inventoryToUse
    if not IsValid(inventoryToUse) then return end
    local item = inventoryToUse.Contents[self.SlotId]
    if not IsValid(item) then return end
    self.ItemPanel = vgui.Create("inventoryItem", self)
    self.ItemPanel:SetItem(item)
end

derma.DefineControl("inventorySlot", "A standard slot", PANEL, "DPanel")
PANEL = {}

function PANEL:Init()
    self.DescPanel = vgui.Create("DPanel")
    self.DescPanel:Hide()
    self:Droppable("inventorySystem")

    self:Receiver("inventorySystem", function(pnl, tbl, dropped, menuIndex, x, y)
        if not dropped then return end
        if tbl[1] == pnl then return end
        local originSlot = tbl[1]:GetParent()
        local targetSlot = pnl:GetParent()
        if not IsValid(originSlot.Inventory) or not IsValid(targetSlot.Inventory) then return end
        net.Start("inventorySystem.Movement")
        net.WriteUInt(originSlot.Inventory:GetInventoryId(), 16)
        net.WriteString(originSlot.SlotId)
        net.WriteUInt(targetSlot.Inventory:GetInventoryId(), 16)
        net.WriteString(targetSlot.SlotId)
        net.SendToServer()
    end)

    self:SetSize(inventorySystem.slotLength, inventorySystem.slotLength)
end

function PANEL:SetItem(info)
    self.Item = info
    self.Item:OnDermaGain(self)
end

function PANEL:Paint(width, height)
    if IsValid(self.Item) then
        self.Item:DrawItem(self, width, height)
    end
end

function PANEL:OnMousePressed(keyCode)
    if IsValid(self.Item) then return self.Item:OnMousePressed(self, keyCode) end
end

function PANEL:OnCursorEntered()
    if self:IsDragging() or IsValid(self.DescBox) then return end
    self.DescBox = vgui.Create("inventoryItemDesc")
    self.DescBox:SetDrawOnTop(true)
    self.DescBox:SetKeyboardInputEnabled(false)
    self.DescBox.ItemBox = self
    self.DescBox:SetItem(self:GetItem())
    self.DescBox:SetSize(self.DescBox.SizeX, self.DescBox.SizeY)
    self:OnCursorMoved(0, 0)
end

function PANEL:OnCursorMoved(x, y)
    if self:IsDragging() then return end

    if not IsValid(self.DescBox) then
        self:OnCursorEntered()
    end

    local mouseX, mouseY = input.GetCursorPos()
    self.DescBox:SetPos(mouseX + 10, mouseY - 5 - self.DescBox:GetTall())
end

function PANEL:OnCursorExited()
    if IsValid(self.DescBox) then
        self.DescBox.ItemBox = nil
        self.DescBox:Remove()
    end
end

function PANEL:GetItem()
    return self.Item
end

function PANEL:MakeUnequipped()
    self:Dock(FILL)
end

function PANEL:MakeEquipped()
    self:Dock(FILL)
end

derma.DefineControl("inventoryItem", "A standard item", PANEL, "DPanel")
PANEL = table.Copy(PANEL)

function PANEL:Init()
end

PANEL.OnCursorMoved = function(self) end
PANEL.OnCursorExited = function(self) end
PANEL.OnCursorEntered = function(self) end

function PANEL:SetItem(info)
    self.Item = info
    self.Item:OnDermaDescGain(self)
end

function PANEL:SetItemBox(panel)
    self.ItemBox = panel
end

function PANEL:Paint(width, height)
    if IsValid(self.Item) then
        self.Item:DrawItemDescBox(self, width, height)
    end
end

function PANEL:GetItemBox()
    return self.ItemBox
end

function PANEL:Think()
    if not IsValid(self.ItemBox) then
        self:Remove()
    else
        if not self.ItemBox:IsHovered() then
            self:Remove()

            return
        end
    end
end

derma.DefineControl("inventoryItemDesc", "A standard item description", PANEL, "DPanel")