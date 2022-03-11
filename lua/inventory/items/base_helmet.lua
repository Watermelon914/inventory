ITEM.Name = "Helmet"
ITEM.Description = "This is a helmet that can be equipped for defense"
ITEM.Base = "base_armor"
ITEM.TypeLightBGDifference = 0.2
ITEM.TypeLightBGLighter = false
ITEM.ArmorBodypart = {
    [HITGROUP_HEAD] = true
}
ITEM.ArmorHitSound = "physics/glass/glass_sheet_impact_hard[1-3].wav"
ITEM.ArmorSlot = "armor"
ITEM.AffectAllDamage = false

function ITEM:SetupArmorValues()
    return {
        DMG_BULLET = 1,
        DMG_BURN = 1
    }
end