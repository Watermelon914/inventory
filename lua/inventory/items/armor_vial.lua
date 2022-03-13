ITEM.Name = "Armor Battery"
ITEM.Description = "Provides the player with 10 armor"
ITEM.Base = "base_stack"
ITEM.Model = "models/Items/battery.mdl"
ITEM.Category = "HL2"
ITEM.Spawnable = true
ITEM.ItemType = "Armor"
ITEM.DrawModelMode = inventorySystem.DRAW_MODEL_TOP
ITEM.ArmorToGive = 10
ITEM.MaxStack = 3

ITEM.StackModels = {
    inventorySystem.MakeStackModel("models/Items/battery.mdl");
    inventorySystem.MakeStackModel("models/props_lab/reciever01b.mdl");
}

DEFINE_BASECLASS("base_stack")

function ITEM:Initialize()
    BaseClass.Initialize(self)
    self.TypeColor = Color(32, 32, 128)
end

function ITEM:GenerateRightClickMenu(menu)
    BaseClass.GenerateRightClickMenu(self, menu)
    local panel = menu:AddOption("Use", inventorySystem.CreateAction(self, "use"))
    panel:SetIcon("icon16/accept.png")
end

function ITEM:OnActionReceived(action, ply)
    BaseClass.OnActionReceived(self, action, ply)

    if action == "use" then
        self:HealPlayer(ply)
    end
end

function ITEM:HealPlayer(ply)
    if ply:Health() >= ply:GetMaxHealth() then
        ply:EmitSound("items/suitchargeno1.wav")

        return
    end

    if not self:Use(1) then return end
    ply:SetArmor(math.min(ply:GetMaxArmor(), ply:Armor() + self.ArmorToGive))
    ply:EmitSound("items/battery_pickup.wav")
end