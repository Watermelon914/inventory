spawnmenu.AddContentType("item", function(container, obj)
    if not obj.material then return end
    if not obj.nicename then return end
    if not obj.spawnname then return end
    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("item")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)
    icon:SetColor(Color(205, 92, 92, 255))

    icon.DoClick = function()
        RunConsoleCommand("spawn_item", obj.spawnname)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    if IsValid(container) then
        container:Add(icon)
    end

    return icon
end)

spawnmenu.AddCreationTab("Items", function()
    local panel = vgui.Create("SpawnmenuContentPanel")
    panel:EnableSearch("inventorySystem", "inventorySystem.PopulateSpawnmenu")
    panel:CallPopulateHook("inventorySystem.PopulateSpawnmenu")

    return panel
end, "icon16/package.png", 25, "All items and configuration options for superadmins for every item")

hook.Add("inventorySystem.PopulateSpawnmenu", inventorySystem, function(self, pnlContent, tree)
    local Categorised = {}
    local SpawnableItems = inventorySystem.items

    if SpawnableItems then
        for k, v in pairs(SpawnableItems) do
            if not v.Spawnable then continue end
            local Category = v.Category or "Other"

            if not isstring(Category) then
                Category = tostring(Category)
            end

            Categorised[Category] = Categorised[Category] or {}
            v.SpawnName = k
            table.insert(Categorised[Category], v)
        end
    end

    for CategoryName, v in SortedPairs(Categorised) do
        local node = tree:AddNode(CategoryName, "icon16/package.png")

        node.DoPopulate = function(nodeSelf)
            if nodeSelf.ItemPanel then return end
            nodeSelf.ItemPanel = vgui.Create("ContentContainer", pnlContent)
            nodeSelf.ItemPanel:SetVisible(false)
            nodeSelf.ItemPanel:SetTriggerSpawnlistChange(false)

            for k, ent in SortedPairs(v) do
                spawnmenu.CreateContentIcon("item", nodeSelf.ItemPanel, {
                    nicename = ent.Name or ent.FileName,
                    spawnname = ent.FileName,
                    material = ent.IconOverride or "items/" .. ent.FileName .. ".png"
                })
            end
        end

        node.DoClick = function(nodeSelf)
            nodeSelf:DoPopulate()
            pnlContent:SwitchPanel(nodeSelf.ItemPanel)
        end
    end

    local FirstNode = tree:Root():GetChildNode(0)

    if IsValid(FirstNode) then
        FirstNode:InternalDoClick()
    end
end)