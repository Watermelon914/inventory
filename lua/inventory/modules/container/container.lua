inventorySystem.containerSystem = inventorySystem.containerSystem or {}
containerSystem = inventorySystem.containerSystem

function containerSystem:IsValid()
    return inventorySystem.containerSystem == self
end

AddCSLuaFile("cl_container.lua")

if CLIENT then
    include("cl_container.lua")
else
    include("sv_container.lua")
end