if IsValid(inventorySystem.backgroundFrame) then
    inventorySystem.backgroundFrame:Remove()
end

local function Empty(self, width, height)
end

local screenScale = 0.5
inventorySystem.openKey = KEY_B
inventorySystem.withoutInvModifier = KEY_LALT

function GenerateHoldingFrame()
    function DropItem(pnl, tbl, dropped, menuIndex, x, y)
        if not dropped then return end
        local parent = tbl[1]:GetParent()
        if not IsValid(parent.Inventory) then return end
        net.Start("inventorySystem.Drop")
        net.WriteUInt(parent.Inventory:GetInventoryId(), 16)
        net.WriteString(parent.SlotId)
        net.SendToServer()
    end

    inventorySystem.backgroundFrame = vgui.Create("DPanel")
    inventorySystem.backgroundFrame:SetSize(ScrW(), ScrH())
    inventorySystem.backgroundFrame:SetPos(0, 0)
    inventorySystem.backgroundFrame:Receiver("inventorySystem", DropItem)
    inventorySystem.backgroundFrame.Paint = Empty
    inventorySystem.holdingFrame = vgui.Create("Panel", inventorySystem.backgroundFrame)
    inventorySystem.holdingFrame:SetSize(math.max(ScrW() * screenScale, 640), math.max(ScrH() * screenScale, 360))
    inventorySystem.holdingFrame:Center()
    inventorySystem.holdingFrame:SetZPos(2)
    inventorySystem.holdingFrame:Hide()
    inventorySystem.storageFrame = vgui.Create("Panel", inventorySystem.backgroundFrame)
    inventorySystem.storageFrame:Hide()
    inventorySystem.storageFrame:SetZPos(2)
end

hook.Add("PlayerButtonDown", inventorySystem, function(self, ply, button)
    if inventorySystem.InitializedUI ~= true then return end

    if button == inventorySystem.openKey then
        if not input.IsKeyDown(KEY_LALT) then
            inventorySystem.holdingFrame:Show()
            inventorySystem.storageFrame:Show()
        end

        inventorySystem.backgroundFrame:MakePopup()
        inventorySystem.backgroundFrame:SetKeyboardInputEnabled(false)
        local playerPanel = inventorySystem.dPlayerPanel.dPlayer
        playerPanel:SetModel(LocalPlayer():GetModel())
        local minBounds, maxBounds = playerPanel.Entity:GetRenderBounds()
        local size = 0
        size = math.max(size, math.abs(minBounds.x) + math.abs(maxBounds.x))
        size = math.max(size, math.abs(minBounds.y) + math.abs(maxBounds.y))
        size = math.max(size, math.abs(minBounds.z) + math.abs(maxBounds.z))
        playerPanel:SetFOV(28)
        playerPanel:SetCamPos(Vector(size + 8, 0, size - 24))
        playerPanel:SetLookAt((minBounds + maxBounds) * 0.5)
        playerPanel.Entity:SetEyeTarget(Vector(size, 0, size))

        local poseParameters = {"move_x", "move_y",}

        function AnimatePlayer(entity)
            if LocalPlayer():Alive() then
                entity:SetSequence(LocalPlayer():GetSequence())

                for _, parameter in ipairs(poseParameters) do
                    local paramValue = LocalPlayer():GetPoseParameter(parameter)
                    local minVal, maxVal = LocalPlayer():GetPoseParameterRange(LocalPlayer():LookupPoseParameter(parameter))
                    local newValue = math.Remap(paramValue, 0, 1, minVal, maxVal)
                    entity:SetPoseParameter(parameter, newValue)
                end
            else
                for _, parameter in ipairs(poseParameters) do
                    entity:SetPoseParameter(parameter, 0)
                end
            end
        end

        AnimatePlayer(playerPanel.Entity)
        hook.Add("Think", playerPanel.Entity, AnimatePlayer)
    end
end)

hook.Add("PlayerButtonUp", inventorySystem, function(self, ply, button)
    if inventorySystem.InitializedUI ~= true then return end

    if button == inventorySystem.openKey then
        inventorySystem.holdingFrame:Hide()
        inventorySystem.storageFrame:Hide()
        inventorySystem.backgroundFrame:SetMouseInputEnabled(false)
        hook.Remove("Think", inventorySystem.dPlayerPanel.dPlayer.Entity)
        hook.Run("inventorySystem.HideLocalInventory")
    end
end)

function GeneratePlayerPanel()
    inventorySystem.dPlayerPanel = vgui.Create("Panel", inventorySystem.holdingFrame)
    inventorySystem.dPlayerPanel:Dock(LEFT)
    inventorySystem.dPlayerPanel:InvalidateParent(true)
    inventorySystem.dPlayerPanel:SetSize(inventorySystem.holdingFrame:GetWide() / 4, inventorySystem.holdingFrame:GetTall())
    inventorySystem.dPlayerPanel.Paint = Empty
    inventorySystem.dPlayerPanel:DockMargin(0, 0, 0, 0)
    local playerPanel = inventorySystem.dPlayerPanel
    playerPanel.dPlayerPanel = vgui.Create("DPanel", playerPanel)
    playerPanel.dPlayerPanel:SetPos(0, 0)
    playerPanel.dPlayerPanel:SetSize(playerPanel:GetWide(), playerPanel:GetTall())
    local backgroundCol = Color(40, 40, 40)
    local borderCol = Color(20, 20, 20)

    function playerPanel.dPlayerPanel.Paint(self, width, height)
        surface.SetDrawColor(backgroundCol)
        surface.DrawRect(0, 0, width, height)
        surface.SetDrawColor(borderCol)
        surface.DrawRect(2, 2, width - 4, height - 4)
    end

    -- Player model panel
    playerPanel.dPlayer = vgui.Create("DModelPanel", playerPanel.dPlayerPanel)
    playerPanel.dPlayer:SetPos(0, 0)
    playerPanel.dPlayer:SetSize(playerPanel.dPlayerPanel:GetWide(), playerPanel.dPlayerPanel:GetTall())

    playerPanel.dPlayer.LayoutEntity = function(self, entity)
        playerPanel.dPlayer:RunAnimation()
    end

    function playerPanel.dPlayer:PostDrawModel(ent)
        inventorySystem.WeaponWorldModel = IsValid(inventorySystem.WeaponWorldModel) and inventorySystem.WeaponWorldModel or ClientsideModel("models/props_c17/FurnitureTable003a.mdl")
        local WorldModel = inventorySystem.WeaponWorldModel
        local activeWeapon = LocalPlayer():GetActiveWeapon()
        if not IsValid(activeWeapon) or activeWeapon:GetWeaponWorldModel() == "" or not activeWeapon:GetWeaponWorldModel() then return end
        local boneid = ent:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then return end
        local matrix = ent:GetBoneMatrix(boneid)
        if not matrix then return end
        WorldModel:SetModel(activeWeapon:GetWeaponWorldModel())
        local weaponBoneId = WorldModel:LookupBone("ValveBiped.Bip01_R_Hand")
        if not weaponBoneId then return end
        WorldModel:SetupBones()
        local weaponMatrix = WorldModel:GetBoneMatrix(weaponBoneId)
        if not weaponMatrix then return end
        local pos, ang = WorldToLocal(WorldModel:GetPos(), WorldModel:GetAngles(), weaponMatrix:GetTranslation(), weaponMatrix:GetAngles())
        local newpos, newang = LocalToWorld(pos, ang, matrix:GetTranslation(), matrix:GetAngles())

        render.Model({
            model = activeWeapon:GetWeaponWorldModel(),
            pos = newpos,
            angle = newang
        }, WorldModel)
    end
end

function inventorySystem.MakeSlotFunction(allSlots, inventory, zPos)
    zPos = zPos or 0

    return function(x, y, borderColor, parent, id, hoverInfo)
        local slot = vgui.Create("inventorySlot", parent)
        slot:SetMouseInputEnabled(true)
        slot:SetPos(x, y)
        slot.BorderColor = borderColor
        slot.HoverInfo = hoverInfo
        slot.SlotId = id

        if inventory then
            slot:GenerateItem(inventory)
        end

        allSlots[slot.SlotId] = slot

        return slot
    end
end

function GenerateSlots(clientInventory)
    local maxYSlots = 5
    local maxXSlots = 5
    local maxStorageRows = 2
    local utilitySlots = vgui.Create("Panel", inventorySystem.holdingFrame)
    utilitySlots:Dock(LEFT)
    utilitySlots:SetMouseInputEnabled(true)
    GeneratePlayerPanel()
    local weaponSlots = vgui.Create("Panel", inventorySystem.holdingFrame)
    weaponSlots:Dock(LEFT)
    weaponSlots:SetMouseInputEnabled(true)
    local storageSlots = vgui.Create("Panel", inventorySystem.holdingFrame)
    storageSlots:Dock(FILL)
    storageSlots:SetMouseInputEnabled(true)
    inventorySystem.holdingFrame:InvalidateLayout(true)
    inventorySystem.maxSlotLength = 128
    inventorySystem.slotSpacing = 5
    inventorySystem.slotLength = math.min(math.min(inventorySystem.holdingFrame:GetWide() / (2560 * screenScale), inventorySystem.holdingFrame:GetTall() / (1440 * screenScale)) * inventorySystem.maxSlotLength, (storageSlots:GetWide() - 10) / maxXSlots - inventorySystem.slotSpacing)
    utilitySlots:SetWidth(inventorySystem.slotLength + 10)
    weaponSlots:SetWidth(inventorySystem.slotLength + 10)

    surface.CreateFont("item_slot_text", {
        font = "Arial", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
        extended = false,
        size = inventorySystem.slotLength / 4,
        weight = 400,
        blursize = 0,
        scanlines = 1,
        antialias = true,
    })

    inventorySystem.holdingFrame:InvalidateLayout(true)
    local currentY = 0

    local ResetSlotY = function()
        currentY = (utilitySlots:GetTall() - ((inventorySystem.slotSpacing + inventorySystem.slotLength) * maxYSlots)) / 2
    end

    local NextSlotY = function()
        local returnValue = currentY
        currentY = currentY + inventorySystem.slotLength + inventorySystem.slotSpacing

        return returnValue
    end

    local allSlots = {}
    local MakeSlot = inventorySystem.MakeSlotFunction(allSlots, clientInventory, 2)
    ResetSlotY()
    MakeSlot(5, NextSlotY(), Color(0, 0, 255, 127), utilitySlots, "helmet", "Helmet")
    MakeSlot(5, NextSlotY(), Color(0, 0, 255, 127), utilitySlots, "mask", "Mask")
    MakeSlot(5, NextSlotY(), Color(0, 0, 255, 127), utilitySlots, "armor", "Armor")
    MakeSlot(5, NextSlotY(), Color(0, 255, 0, 127), utilitySlots, "suit", "Suit")
    MakeSlot(5, NextSlotY(), Color(255, 255, 0, 127), utilitySlots, "utility", "Utility")
    ResetSlotY()
    MakeSlot(5, NextSlotY(), Color(255, 0, 0, 127), weaponSlots, "weapon1", "Weapon")
    MakeSlot(5, NextSlotY(), Color(255, 0, 0, 127), weaponSlots, "weapon2", "Weapon")
    MakeSlot(5, NextSlotY(), Color(255, 0, 0, 127), weaponSlots, "weapon3", "Weapon")
    MakeSlot(5, NextSlotY(), Color(255, 0, 0, 127), weaponSlots, "weapon4", "Weapon")
    MakeSlot(5, NextSlotY(), Color(255, 0, 0, 127), weaponSlots, "weapon5", "Weapon")

    for row = 0, maxStorageRows - 1 do
        for i = 0, maxXSlots - 1 do
            local xPos = (storageSlots:GetWide() - (inventorySystem.slotSpacing + inventorySystem.slotLength) * maxXSlots) / 2
            xPos = xPos + i * (inventorySystem.slotLength + inventorySystem.slotSpacing)
            local yPos = row * (inventorySystem.slotLength + inventorySystem.slotSpacing)
            MakeSlot(xPos, yPos, Color(0, 0, 0, 127), storageSlots, "slot" .. (row * maxXSlots) + (i + 1))
        end
    end

    local prevX = inventorySystem.holdingFrame:GetWide()
    inventorySystem.storageFrame:Add(storageSlots)
    inventorySystem.holdingFrame:InvalidateLayout(true)
    inventorySystem.holdingFrame:SizeToChildren(true, false)
    inventorySystem.storageFrame:SetPos(inventorySystem.holdingFrame:GetWide() + inventorySystem.holdingFrame:GetX(), inventorySystem.holdingFrame:GetY() + (inventorySystem.slotSpacing + inventorySystem.slotLength) * maxStorageRows)
    inventorySystem.storageFrame:InvalidateLayout(true)
    inventorySystem.storageFrame:SetSize(prevX - inventorySystem.holdingFrame:GetWide(), (inventorySystem.slotSpacing + inventorySystem.slotLength) * maxStorageRows - inventorySystem.slotSpacing)

    function inventorySystem.UpdatePlayerInventory(inventory, slots)
        slots = slots or table.GetKeys(allSlots)

        for _, slot in ipairs(slots) do
            allSlots[slot]:GenerateItem(inventory)
        end
    end

    inventorySystem.holdingFrame.UpdateData = function(self, inventory, slots)
        inventorySystem.UpdatePlayerInventory(inventory, slots)
    end
end

function RegenerateSpawnMenu()
    local creationMenu = g_SpawnMenu:GetCreationMenu()
    local data = creationMenu:GetCreationTabs()
    local oldTabs = {}

    for key, value in pairs(data) do
        table.insert(oldTabs, value.Tab)
        value.Panel:Hide()
    end

    local tabs = spawnmenu.GetCreationTabs()

    for k, v in SortedPairsByMemberValue(tabs, "Order") do
        local tabData = data[k]
        local tab = creationMenu:AddSheet(k, tabData.Panel, v.Icon, nil, nil, v.Tooltip)
        data[k] = tab
    end

    for _, tab in ipairs(oldTabs) do
        if IsValid(tab) then
            creationMenu:CloseTab(tab, false)
        end
    end
end

function inventorySystem.GenerateInventoryUI(inventory)
    GenerateHoldingFrame()
    GenerateSlots(inventory)
    inventorySystem.InitializedUI = true
end

hook.Add("OnSpawnMenuOpen", inventorySystem, function(self)
    if not IsValid(g_SpawnMenu) then return end
    inventorySystem.itemTab = inventorySystem.itemTab or spawnmenu.GetCreationTabs()["Items"]
    local itemTab = inventorySystem.itemTab
    if not itemTab then return end

    if LocalPlayer():IsSuperAdmin() then
        if not spawnmenu.GetCreationTabs()["Items"] then
            spawnmenu.GetCreationTabs()["Items"] = itemTab
            RegenerateSpawnMenu()
        end
    else
        if spawnmenu.GetCreationTabs()["Items"] then
            spawnmenu.GetCreationTabs()["Items"] = nil
            RegenerateSpawnMenu()
        end
    end
end)