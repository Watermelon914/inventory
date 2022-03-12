ITEM.Name = "Weapon"
ITEM.Description = "This is a weapon that can be equipped and used."
ITEM.Base = "base_item"

ITEM.SlotsAllowed = {
    ["slot"] = true,
    ["weapon"] = true
}

ITEM.ItemType = "Weapon"
ITEM.TypeLightBGDifference = 0.15
ITEM.TypeLightBGLighter = false
DEFINE_BASECLASS("base_item")
local CurrentClass = ITEM

function ITEM:Initialize(weapon)
    BaseClass.Initialize(self)
    self.TypeColor = Color(96, 32, 32, 255)
    local weaponClass = weapons.Get(weapon or self.WeaponClass)

    if not weaponClass then
        BaseClass.Initialize(self)

        return
    end

    self:SetModel(weaponClass.WorldModel)

    if self:GetName() == CurrentClass.Name then
        self:SetName(weaponClass.PrintName)
    end

    if self:GetName() == CurrentClass.Description and weaponClass.Purpose ~= "" then
        self:SetDescription(weaponClass.Purpose)
    end

    self:SetWeaponClass(weaponClass.ClassName)

    if SERVER then
        self.Weapon = ents.Create(weaponClass.ClassName)
        self.Weapon.Item = self

        hook.Add("PlayerCanPickupWeapon", self, function(_, ply, pickedWeapon)
            if self.Weapon ~= pickedWeapon then return end
            local inventory = self.InventoryLocation
            if not inventory then return false end
            if inventory:GetParent() == ply and inventorySystem.GetSlotType(self.SlotLocation) == "weapon" then return true end

            return false
        end)

        self.Weapon:Spawn()
        self.Weapon:PhysicsInitStatic(SOLID_NONE)

        self.Weapon:CallOnRemove("weapon_inventorysystem_item", function(removedWeapon)
            if IsValid(self) then
                inventorySystem.DeleteItem(self)
            end
        end)
    end
end

function ITEM:SetupNetworkedVariables()
    BaseClass.SetupNetworkedVariables(self)
    self:CreateNetworkedVariable("WeaponClass", "String")
end

function ITEM:Remove()
    self.Weapon:Remove()
    BaseClass.Remove(self)
end

function ITEM:CanAddToInventory(inventory, slot)
    local result = BaseClass.CanAddToInventory(self, inventory, slot)
    if result == false then return result end
    if not self:GetWeaponClass() then return false end
    if inventorySystem.GetSlotType(slot) == "weapon" and (not IsValid(inventory:GetParent()) or inventory:GetParent():HasWeapon(self:GetWeaponClass())) then return false end

    return true
end

function ITEM:AddToInventory(inventory, slot)
    BaseClass.AddToInventory(self, inventory, slot)

    if inventorySystem.GetSlotType(slot) == "weapon" then
        self:GiveWeapon()
    end
end

function ITEM:RemoveFromInventory(inventory, slot)
    if inventorySystem.GetSlotType(slot) == "weapon" then
        self:RemoveWeapon()
    end

    BaseClass.RemoveFromInventory(self, inventory, slot)
end

function ITEM:GiveWeapon()
    if CLIENT then return end
    if not IsValid(self.Weapon) then return end
    local inventory = self.InventoryLocation
    if not IsValid(inventory) or not IsValid(inventory:GetParent()) then return end
    local ply = inventory:GetParent()
    self.Weapon:SetPos(ply:GetPos())
    self.Weapon:Use(ply, ply, SIMPLE_USE)
end

function ITEM:RemoveWeapon()
    if CLIENT then return end
    if not IsValid(self.Weapon) then return end
    local inventory = self.InventoryLocation
    if not IsValid(inventory) or not IsValid(inventory:GetParent()) then return end
    inventory:GetParent():DropWeapon(self.Weapon)
    self.Weapon:SetPos(Vector(0, 0, 0))
    self.Weapon:SetNoDraw(true)
    self.Weapon:PhysicsInitStatic(SOLID_NONE)
end