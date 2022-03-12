local function OpenContainerCreation()
    local ContainerCreationPanel = vgui.Create("DFrame")
    ContainerCreationPanel:SetTitle("Container Creation Menu")
    ContainerCreationPanel:SetSize(250, 250)
    ContainerCreationPanel:Center()
    ContainerCreationPanel:MakePopup()
    local BackgroundColor = Color(40, 40, 40, 255)
    local TitleBarColor = Color(80, 80, 80, 255)

    ContainerCreationPanel.Paint = function(self, width, height)
        surface.SetDrawColor(BackgroundColor)
        surface.DrawRect(0, 0, width, height)
        surface.SetDrawColor(TitleBarColor)
        surface.DrawRect(0, 0, width, 24)
    end

    local SelectedModel = vgui.Create("DTextEntry", ContainerCreationPanel)
    SelectedModel:Dock(TOP)
    local SizePanel = vgui.Create("Panel", ContainerCreationPanel)
    SizePanel:Dock(TOP)
    local XLabel = Label("X: ", SizePanel)
    XLabel:Dock(LEFT)
    XLabel:SizeToContents()
    local XSlots = vgui.Create("DNumberWang", SizePanel)
    XSlots:Dock(LEFT)
    XSlots:SetMax(127)
    XSlots:SetMin(0)
    local YSlots = vgui.Create("DNumberWang", SizePanel)
    YSlots:Dock(RIGHT)
    YSlots:SetMax(127)
    YSlots:SetMin(0)
    local YLabel = Label("Y: ", SizePanel)
    YLabel:Dock(RIGHT)
    YLabel:SizeToContents()
    local Items = vgui.Create("DListView", ContainerCreationPanel)
    Items:Dock(FILL)
    Items:SetMultiSelect(true)
    local name = Items:AddColumn("Class Name", 1)
    local BarColor = Color(120, 120, 120, 255)
    name.Header:SetTextColor(Color(255, 255, 255, 255))

    name.Header.Paint = function(self, width, height)
        surface.SetDrawColor(BarColor)
        surface.DrawRect(0, 0, width, height)
    end

    local ItemsColor = Color(80, 80, 80, 255)

    Items.Paint = function(self, width, height)
        surface.SetDrawColor(ItemsColor)
        surface.DrawRect(0, 0, width, height)
    end

    local ColorToUse = Color(40, 40, 40, 127)

    local function ItemPaint(self, width, height)
        local hue, saturation, value = ColorToUse:ToHSV()

        if not self.Dark then
            value = value + 0.1
        end

        if self:IsSelected() then
            saturation = 1
            hue = 240
            value = 0.3
        elseif self:IsHovered() then
            value = value + 0.2
        end

        local Col = HSVToColor(hue, saturation, value)
        Col.a = 127
        surface.SetDrawColor(Col)
        surface.DrawRect(0, 0, width, height)
    end

    for index, className in ipairs(table.GetKeys(inventorySystem.items)) do
        if not inventorySystem.items[className].Spawnable then continue end
        local item = Items:AddLine(className)
        item.Paint = ItemPaint
        item.Columns[1]:SetTextColor(Color(200, 200, 200, 255))

        if index % 2 == 0 then
            item.Dark = true
        else
            item.Dark = false
        end
    end

    local CreateModel = vgui.Create("DButton", ContainerCreationPanel)
    CreateModel:Dock(BOTTOM)
    CreateModel:SetText("Create Container")
    CreateModel:SetTextColor(Color(200, 200, 200, 255))

    CreateModel.DoClick = function(self)
        local SelectedThings = {}
        local lines = Items:GetSelected()

        for _, line in ipairs(lines) do
            table.insert(SelectedThings, line:GetColumnText(1))
        end

        RunConsoleCommand("spawn_container", XSlots:GetValue(), YSlots:GetValue(), SelectedModel:GetText(), table.concat(SelectedThings, ","))
    end

    CreateModel.Paint = function(self, width, height)
        local hue, saturation, value = ColorToUse:ToHSV()
        value = value + 0.1

        if self:IsSelected() then
            value = value + 0.3
        elseif self:IsHovered() then
            value = value + 0.2
        end

        local Col = HSVToColor(hue, saturation, value)
        Col.a = 127
        surface.SetDrawColor(Col)
        surface.DrawRect(0, 0, width, height)
    end

    ContainerCreationPanel:InvalidateLayout(true)
end

concommand.Add("inventory_make_container", function(ply, cmd, args, argStr)
    if not ply:IsSuperAdmin() then return end
    OpenContainerCreation()
end)