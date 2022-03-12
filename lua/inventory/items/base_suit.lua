ITEM.Name = "Suit"
ITEM.Description = "This is a suit that can be equipped and used."
ITEM.Base = "base_item"

ITEM.SlotsAllowed = {
    ["slot"] = true,
    ["suit"] = true
}

ITEM.ItemType = "Suit"
ITEM.TypeLightBGDifference = 0.2
ITEM.TypeLightBGLighter = false
DEFINE_BASECLASS("base_item")

function ITEM:Initialize()
    BaseClass.Initialize(self)
    self.TypeColor = Color(32, 168, 32, 255)
end

function ITEM:AddToInventory(inventory, slot)
    BaseClass.AddToInventory(self, inventory, slot)

    if inventorySystem.GetSlotType(slot) == "weapon" then
        self:ApplyModel(inventory:GetParent())
    end
end

function ITEM:RemoveFromInventory(inventory, slot)
    if inventorySystem.GetSlotType(slot) == "weapon" then
        self:RemoveModel(inventory:GetParent())
    end

    BaseClass.RemoveFromInventory(self, inventory, slot)
end

function ITEM:ApplyModel()
    if not self.ConfiguredModel then return end
    self.LastPlayerModel = ply:GetModel()
    ply:SetModel(self.ConfiguredModel)
end

function ITEM:RemoveModel()
    if not self.ConfiguredModel then return end

    if ply:GetModel() == self.ConfiguredModel and self.LastPlayerModel then
        ply:SetModel(self.LastPlayerModel)
        self.LastPlayerModel = nil
    end
end