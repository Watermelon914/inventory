ITEM.Name = "Armor"
ITEM.Description = "This is a vest that can be equipped for defense"
ITEM.Base = "base_item"
ITEM.ItemType = "Armor"
ITEM.TypeLightBGDifference = 0.2
ITEM.TypeLightBGLighter = false
ITEM.ArmorHitSound = "physics/glass/glass_sheet_impact_hard[1-3].wav"
ITEM.ArmorBodypart = {
    [HITGROUP_GENERIC] = true,
    [HITGROUP_CHEST] = true,
    [HITGROUP_STOMACH] = true,
    [HITGROUP_LEFTARM] = true,
    [HITGROUP_LEFTLEG] = true,
    [HITGROUP_RIGHTARM] = true,
    [HITGROUP_RIGHTLEG] = true
}
ITEM.ArmorSlot = "armor"
ITEM.AffectAllDamage = true

DEFINE_BASECLASS("base_item")

function ITEM:Initialize()
    BaseClass.Initialize(self)
    self.Armor = self:SetupArmorValues()
    self.SlotsAllowed = {
        ["slot"] = true,
        [self.ArmorSlot] = true
    }
    self.TypeColor = Color(32, 32, 168, 255)
end

function ITEM:SetupArmorValues()
    return {
        DMG_BULLET = 1,
        DMG_BURN = 1
    }
end

function ITEM:AddToInventory(inventory, slot)
    BaseClass.AddToInventory(self, inventory, slot)

    if(inventorySystem.GetSlotType(slot) == self.ArmorSlot) then
        hook.Add("EntityTakeDamage", self, self.HandleDamage)
        hook.Add("ScalePlayerDamage", self, self.HandleBulletDamage)
    end
end

function ITEM:RemoveFromInventory(inventory, slot)
    if(inventorySystem.GetSlotType(slot) == self.ArmorSlot) then
        hook.Remove("EntityTakeDamage", self, self.HandleDamage)
    end
    BaseClass.RemoveFromInventory(self, inventory, slot)
end

function ITEM:HandleBulletDamage(ply, hitgroup, dmg)
    return self:HandleDamage(ply, dmg, hitgroup)
end

function ITEM:HandleDamage(target, dmg, hitgroup)
    local parent = self:GetParent()
    if(not parent) then
        return
    end
    if(target == parent) then
        local biggestMultiplier = 0
        local canBlockDamage = false
        for dmgType, multiplier in pairs(self.Armor) do
            if(multiplier > biggestMultiplier and dmg:IsDamageType(dmgType)) then
                biggestMultiplier = multiplier
                canBlockDamage = true
            end
        end
        if(not hitgroup and self.AffectAllDamage or self.ArmorBodypart[hitgroup]) then
            dmg:ScaleDamage(biggestMultiplier)
            target:EmitSound(string.gsub(self.ArmorHitSound, "\\[([0-9]-[0-9])\\]", function(x)
                local data = string.Explode(x, "-")
                return math.Round(data[1] + math.random() * (data[2] - data[1]))
            end))
        end
    end
end