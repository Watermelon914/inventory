inventorySystem.containerSystem = inventorySystem.containerSystem or {}
containerSystem = inventorySystem.containerSystem

function containerSystem:IsValid()
    return inventorySystem.containerSystem == self
end

function inventorySystem.MakeStackModel(model, offset)
    return {
        model = model,
        offset = offset or Vector(0, 0, 0)
    }
end

AddCSLuaFile("cl_container.lua")
AddCSLuaFile("container_editor.lua")

if CLIENT then
    include("cl_container.lua")
    include("container_editor.lua")
else
    include("sv_container.lua")
end