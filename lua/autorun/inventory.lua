local core = "inventory/core/"
local modules = "inventory/modules/"
inventorySystem = inventorySystem or {}
inventorySystem.debug = true

function inventorySystem:IsValid()
    return inventorySystem == self
end

local function LoadCore()
    AddCSLuaFile(core .. "cl_inventory.lua")
    AddCSLuaFile(core .. "cl_slot.lua")
    AddCSLuaFile(core .. "sh_itemloader.lua")
    AddCSLuaFile(core .. "sh_inventory.lua")
    AddCSLuaFile(core .. "cl_networking.lua")
    AddCSLuaFile(core .. "cl_menu.lua")
    include(core .. "sh_inventory.lua")

    if CLIENT then
        include(core .. "cl_slot.lua")
        include(core .. "cl_inventory.lua")
        include(core .. "cl_networking.lua")
        include(core .. "cl_menu.lua")
    else
        include(core .. "sv_inventory.lua")
        include(core .. "sv_networking.lua")
    end
end

LoadCore()

local function LoadModules()
    local _, mods = file.Find(modules .. "*", "LUA")

    -- Loads in modules
    for _, mod in ipairs(mods) do
        AddCSLuaFile(modules .. mod .. "/" .. mod .. ".lua")
        include(modules .. mod .. "/" .. mod .. ".lua")
    end
end

LoadModules()
include(core .. "sh_itemloader.lua")