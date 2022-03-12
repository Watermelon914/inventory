ITEM.Name = "Health Vial"
ITEM.Description = "Provides the player with 10 HP"
ITEM.Base = "base_stack"
ITEM.Model = "models/Items/HealthKit.mdl"
ITEM.Category = "Health"
ITEM.Spawnable = true
ITEM.ItemType = "Health"
ITEM.DrawModelMode = inventorySystem.DRAW_MODEL_TOP
ITEM.AmountToHeal = 10
ITEM.MaxStack = 3

ITEM.StackModels = {
    inventorySystem.MakeStackModel("models/healthvial.mdl");
    inventorySystem.MakeStackModel("models/Items/HealthKit.mdl", Vector(-7, 0, -3));
}

DEFINE_BASECLASS("base_stack")

function ITEM:Initialize()
    BaseClass.Initialize(self)
    self.TypeColor = Color(32, 128, 32)
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
        ply:EmitSound("items/medshotno1.wav")

        return
    end

    if not self:Use(1) then return end
    ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + self.AmountToHeal))
    ply:EmitSound("items/smallmedkit1.wav")
end