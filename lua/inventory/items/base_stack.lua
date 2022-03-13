ITEM.Name = "Base Stack"
ITEM.Description = "This is the base for providing items with stack. If you are seeing this, tell a developer."
ITEM.Base = "base_item"
ITEM.MaxStack = 10
ITEM.DrawModelMode = inventorySystem.DRAW_MODEL_FORWARD

ITEM.StackModels = {
    inventorySystem.MakeStackModel("models/props_junk/cardboard_box004a.mdl");
    inventorySystem.MakeStackModel("models/props_junk/cardboard_box001a.mdl");
    inventorySystem.MakeStackModel("models/props_junk/wood_crate001a.mdl")
}

DEFINE_BASECLASS("base_item")

function ITEM:Initialize()
    BaseClass.Initialize(self)
    self:SetAmount(1)
    self:UpdateSize()
end

function ITEM:SetupNetworkedVariables()
    BaseClass.SetupNetworkedVariables(self)
    self:CreateNetworkedVariable("Amount", "Int")
    self:CreateNetworkedVariable("ChosenModel", "Int")
end

function ITEM:SplitStack(amount, inventory, slot)
    local amountUsed = self:Use(amount)
    if amountUsed <= 0 then return end
    local stackItem = inventorySystem.CreateItem(self:GetClass())
    stackItem:SetAmount(amountUsed)
    stackItem:UpdateSize()

    if IsValid(inventory) then
        inventory:AddItem(slot, stackItem)
    end

    return stackItem
end

function ITEM:OnChosenModelChange(value)
    if CLIENT then
        self.DrawModelOffset = self.StackModels[value].offset
    end
end

function ITEM:UpdateSize()
    local amountPerIndex = self.MaxStack / table.Count(self.StackModels)
    local chosenModel = self.StackModels[1].model
    local chosenModelIndex = 1

    for index, model in ipairs(self.StackModels) do
        if self:GetAmount() < (index - 1) * amountPerIndex then break end
        chosenModel = model.model
        chosenModelIndex = index
    end

    self:SetChosenModel(chosenModelIndex)
    self:SetModel(chosenModel)
end

function ITEM:Use(amount)
    if self:GetAmount() <= 0 then return 0 end
    local newAmount = self:GetAmount() - amount

    if newAmount < 0 then
        newAmount = newAmount + amount
    end

    self:SetAmount(newAmount)
    self:UpdateSize()

    if self:GetAmount() <= 0 then
        self:Remove()
    end

    return math.max(amount, amount - newAmount)
end

function ITEM:JoinStack(stackItem)
    local maxToGive = math.min(self.MaxStack - self:GetAmount(), stackItem:GetAmount())
    if maxToGive <= 0 then return false end
    stackItem:SetAmount(stackItem:GetAmount() - maxToGive)

    if stackItem:GetAmount() <= 0 then
        stackItem:Remove()
    else
        stackItem:UpdateSize()
    end

    self:SetAmount(self:GetAmount() + maxToGive)
    self:UpdateSize()

    return true
end

function ITEM:GenerateRightClickMenu(menu)
    if self:GetAmount() <= 1 then return end
    local subMenu, panel = menu:AddSubMenu("Split into..", inventorySystem.CreateAction(self, "split_custom"))
    panel:SetIcon("icon16/package_go.png")
    subMenu:AddOption("1", inventorySystem.CreateAction(self, "split_1")):SetIcon("icon16/bullet_blue.png")

    if self.MaxStack > 5 then
        subMenu:AddOption("5", inventorySystem.CreateAction(self, "split_5")):SetIcon("icon16/bullet_orange.png")
    end

    if self.MaxStack > 10 then
        subMenu:AddOption("10", inventorySystem.CreateAction(self, "split_10")):SetIcon("icon16/bullet_red.png")
    end

    if self:GetAmount() >= 2 then
        subMenu:AddOption("Half", inventorySystem.CreateAction(self, "split_half")):SetIcon("icon16/bullet_black.png")
    end
end

function ITEM:HandleManualSplit(amount, ply)
    local inventory = self.InventoryLocation
    local emptySlot = inventory:GetEmptySlot()

    if not emptySlot then
        local item = self:SplitStack(amount)
        inventorySystem.PerformItemDrop(ply, item)
    else
        self:SplitStack(amount, inventory, emptySlot)
    end
end

function ITEM:OnActionReceived(action, ply)
    if action == "split_1" then
        self:HandleManualSplit(1, ply)
    elseif action == "split_5" then
        self:HandleManualSplit(5, ply)
    elseif action == "split_10" then
        self:HandleManualSplit(10, ply)
    elseif action == "split_half" then
        if self:GetAmount() < 2 then return end
        self:HandleManualSplit(math.floor(self:GetAmount() / 2), ply)
    end
end

function ITEM:ReceiveDropped(item)
    if item:GetClass() == self:GetClass() and self:JoinStack(item) then return true end
end

function ITEM:DrawHover(item, w, h)
    if item:GetClass() == self:GetClass() and self:GetAmount() < self.MaxStack and item ~= self and item:GetAmount() < item.MaxStack then
        surface.SetAlphaMultiplier(0.1)
        surface.SetDrawColor(self:GetTypeColor())
        surface.DrawRect(0, 0, w, h)
        surface.SetAlphaMultiplier(1)
    else
        BaseClass.DrawHover(self, item, w, h)
    end
end

local white = Color(255, 255, 255)

function ITEM:DrawItem(panel, width, height)
    BaseClass.DrawItem(self, panel, width, height)
    surface.SetFont("item_title_text")
    local _, y = surface.GetTextSize(self:GetAmount())
    draw.DrawText(self:GetAmount(), "item_title_text", 8, height - y - 8, white, TEXT_ALIGN_LEFT)
end