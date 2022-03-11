ITEM.Name = "Health Vial"
ITEM.Description = "Provides the player with 10 HP"
ITEM.Base = "base_item"
ITEM.Model = "models/Items/HealthKit.mdl"

ITEM.Category = "Health"
ITEM.Spawnable = true
ITEM.ItemType = "Health"
ITEM.AmountToHeal = 10

DEFINE_BASECLASS("base_item")

function ITEM:Initialize()
    BaseClass.Initialize(self)
    self.TypeColor = Color(32, 128, 32)
end

function ITEM:GenerateRightClickMenu(menu)
    local panel = menu:AddOption("Use", inventorySystem.CreateAction(self, "use"))
    panel:SetIcon("icon16/accept.png")
end

function ITEM:OnActionReceived(action, ply)
    if action == "use" then
        self:Use(ply)
    end
end

function ITEM:Use(ply)
    if(ply:Health() >= ply:GetMaxHealth()) then
        ply:EmitSound("items/medshotno1.wav")
        return
    end
    ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + self.AmountToHeal))
    ply:EmitSound("items/smallmedkit1.wav")
    self:Remove()
end