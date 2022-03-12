inventorySystem.DRAW_MODEL_FORWARD = 1
inventorySystem.DRAW_MODEL_SIDE = 2
inventorySystem.DRAW_MODEL_TOP = 3
ITEM.Name = "Generic Item"
ITEM.Description = "This is a generic item that does absolutely nothing and has no current purpose"
ITEM.Base = nil
ITEM.Model = "models/props_c17/SuitCase001a.mdl"
ITEM.DrawModelMode = inventorySystem.DRAW_MODEL_SIDE
ITEM.DrawModelOffset = Vector(0, 0, 0)
ITEM.Category = "Other"
ITEM.Spawnable = false
ITEM.ItemType = "Miscellaneous"

ITEM.SlotsAllowed = {
    ["slot"] = true,
}

ITEM.TypeLightBGDifference = 0.2
ITEM.TypeLightBGLighter = false
ITEM.BGInvisiblie = true
local CurrentClass = ITEM

function ITEM:GetClass()
    return self.FileName
end

-- Called when the Item first loads. 
function ITEM:Initialize()
    if CLIENT then
        self.ExtraHeight = self.ExtraHeight or 12
        self.ParseObjTitle = markup.Parse("<font=Trebuchet24>" .. self.Name .. "</font>", self.DermaDesc.SizeX - 12)
        self.ParseObjDesc = markup.Parse("<font=item_desc_text>" .. self.Description .. "</font>", self.DermaDesc.SizeX - 28)
        self.DermaDesc.SizeY = 58 + self.ParseObjDesc:GetHeight() + self.ParseObjTitle:GetHeight() + self.ExtraHeight
        self.RenderedModel = ClientsideModel(self.Model, RENDERGROUP_OTHER)
        self.RenderedModel:SetNoDraw(true)
        self.RenderedModel:SetIK(false)
        self.CameraPos = Vector(0, 0, 0)
    end

    self.TrackedVariables = {}
    self:SetupNetworkedVariables()
    self.__Initialized = true
end

function ITEM:Remove()
    inventorySystem.DeleteItem(self)
end

function ITEM:OnRemove()
    if IsValid(self.RenderedModel) then
        self.RenderedModel:Remove()
    end
end

function ITEM:__tostring()
    if self == inventorySystem.InvalidItem or self.__Deleted or not self:GetItemId() then
        return "[Deleted Item " .. tostring(self:GetItemId()) .. "]"
    else
        return "Item [" .. self:GetItemId() .. "][" .. tostring(self:GetName()) .. "]"
    end
end

function ITEM:SetupNetworkedVariables()
    self:CreateNetworkedVariable("Name", "String")
    self:CreateNetworkedVariable("Description", "String")
    self:CreateNetworkedVariable("Model", "String")
    self:CreateNetworkedVariable("ItemType", "String")
end

function ITEM:SetNetworkedVariable(varName, value)
    local networkingType = self.TrackedVariables[varName]

    if not networkingType then
        error("Tried setting invalid networked variable (name: " .. varName .. ", value: " .. value .. ")")

        return
    end

    self[varName] = value

    local networkingArguments = {value}

    if networkingType == "Int" or networkingType == "UInt" then
        table.insert(networkingArguments, 32)
    end

    if not SERVER then return end
    local players = RecipientFilter()

    if IsValid(self.InventoryLocation) then
        for _, ply in ipairs(self.InventoryLocation:GetListeners()) do
            players:AddPlayer(ply)
        end
    elseif IsValid(self.ItemLocation) then
        players:AddPVS(self.ItemLocation:GetPos())
    else
        return -- Can't send any updates to anyone, we're not attached to anything and are currently an abstract item
    end

    net.Start("inventorySystem.UpdateItem")
    net.WriteUInt(self:GetItemId(), 16)
    net.WriteString(self:GetClass())
    net.WriteUInt(1, 16)
    net.WriteString(varName)
    net["Write" .. networkingType](unpack(networkingArguments))
    net.Send(players)
end

function ITEM:SendFullUpdate(ply)
    net.Start("inventorySystem.UpdateItem")
    net.WriteUInt(self:GetItemId(), 16)
    net.WriteString(self:GetClass())
    net.WriteUInt(table.Count(self.TrackedVariables), 16)

    for variable, networkingType in pairs(self.TrackedVariables) do
        local arguments = {self[variable]}

        if networkingType == "Int" or networkingType == "UInt" then
            table.insert(arguments, 32)
        end

        net.WriteString(variable)
        net["Write" .. networkingType](unpack(arguments))
    end

    net.Send(ply)
end

function ITEM:OnNameChange(newValue)
    if CLIENT then
        self.ParseObjTitle = markup.Parse("<font=Trebuchet24>" .. newValue .. "</font>")
        self.DermaDesc.SizeX = math.max(self.ParseObjTitle:GetWidth() + 12, CurrentClass.DermaDesc.SizeX)
        self:UpdateDescBoxDimensions()
    end
end

function ITEM:OnDescriptionChange(newValue)
    if CLIENT then
        self.ParseObjDesc = markup.Parse("<font=item_desc_text>" .. newValue .. "</font>", self.DermaDesc.SizeX - 28)
        self:UpdateDescBoxDimensions()
    end
end

function ITEM:UpdateDescBoxDimensions()
    self.DermaDesc.SizeY = 58 + self.ParseObjDesc:GetHeight() + self.ParseObjTitle:GetHeight() + self.ExtraHeight
    local inventory = self.InventoryLocation

    if IsValid(inventory) and IsValid(inventory.InventoryUI) and inventory:GetItem(self.SlotLocation) == self then
        inventory.InventoryUI:UpdateData(inventory, {self.SlotLocation})
    end
end

function ITEM:CreateNetworkedVariable(name, netType)
    self.TrackedVariables[name] = netType

    self["Set" .. name] = function(_, value)
        if isfunction(self["On" .. name .. "Change"]) then
            self["On" .. name .. "Change"](self, value)
        end

        self:SetNetworkedVariable(name, value)
    end

    self["Get" .. name] = function(_, value) return self[name] end
end

function ITEM:GetTypeColor()
    self.TypeColor = self.TypeColor or Color(96, 96, 96, 255)

    return self.TypeColor
end

function ITEM:RenderModel(x1, y1, x2, y2)
    local model = self.RenderedModel
    if not IsValid(model) then return end
    model:SetAngles(Angle(0, 90, 0))
    model:SetModel(self.Model)
    local minBounds, maxBounds = model:GetModelRenderBounds()
    local width = x2 - x1
    local height = y2 - y1
    local cameraTarget = (minBounds + maxBounds) / 2
    cameraTarget:Add(self.DrawModelOffset)
    local size = 15
    size = math.max(size, math.abs(minBounds.x) + math.abs(maxBounds.x))
    size = math.max(size, math.abs(minBounds.y) + math.abs(maxBounds.y))
    size = math.max(size, math.abs(minBounds.z) + math.abs(maxBounds.z))
    local cameraPos = self.CameraPos

    if bit.band(self.DrawModelMode, inventorySystem.DRAW_MODEL_FORWARD) ~= 0 then
        cameraPos.x = size
    else
        cameraPos.x = 0
    end

    if bit.band(self.DrawModelMode, inventorySystem.DRAW_MODEL_SIDE) ~= 0 then
        cameraPos.y = size
    else
        cameraPos.y = 0
    end

    if bit.band(self.DrawModelMode, inventorySystem.DRAW_MODEL_TOP) ~= 0 then
        cameraPos.z = size
    else
        cameraPos.z = 0
    end

    local angle = (cameraTarget - cameraPos):Angle()
    cam.Start3D(cameraPos, angle, math.max(size * 3, 75), x1, y1, width, height, 5)
    render.SuppressEngineLighting(true)
    render.SetLightingOrigin(model:GetPos())
    render.ResetModelLighting(1, 1, 1)
    render.SetColorModulation(1, 1, 1)
    render.SetScissorRect(x1, y1, x2, y2, true)
    model:DrawModel()
    render.SetScissorRect(0, 0, 0, 0, false)
    render.SuppressEngineLighting(false)
    cam.End3D()
end

function ITEM:DrawBackground(w, h, isDescription, borderThickness)
    local hue, saturation, lightness = ColorToHSL(self:GetTypeColor())

    if not self.BGInvisiblie or isDescription then
        if self.TypeLightBGLighter then
            if lightness < 1 - self.TypeLightBGDifference then
                lightness = lightness + self.TypeLightBGDifference
            else
                lightness = 1
            end
        else
            if lightness > self.TypeLightBGDifference then
                lightness = lightness - self.TypeLightBGDifference
            else
                lightness = 0
            end
        end

        surface.SetDrawColor(HSVToColor(hue, saturation, lightness))
        surface.DrawRect(0, 0, w, h)
    end

    surface.SetDrawColor(self:GetTypeColor())
    surface.DrawOutlinedRect(0, 0, w, h, borderThickness)
end

function ITEM:GetItemId()
    return self.__ItemId
end

function ITEM:IsValid()
    if self.__Deleted then return false end

    return true
end

function ITEM:DrawTitle(width, x, y)
    surface.SetFont("item_title_text")
    local strW, strH = surface.GetTextSize(self.ItemType)
    local color = self:GetTypeColor()
    local hue, saturation, lightness = ColorToHSL(color)

    if lightness < 0.5 then
        color = HSVToColor(hue, saturation, 0.5)
    end

    if width > strW then
        draw.SimpleText(self.ItemType, "item_title_text", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        local str = string.Replace(self.ItemType, " ", "\n")
        draw.DrawText(str, "item_title_text", x, y - strH, color, TEXT_ALIGN_CENTER)
    end
end

function ITEM:GetInventory()
    return self.InventoryLocation
end

function ITEM:GetParent()
    local inventory = self:GetInventory()
    if not IsValid(inventory) then return nil end
    if not IsValid(inventory:GetParent()) then return nil end

    return inventory:GetParent()
end

function ITEM:CanAddToInventory(inventory, slot)
    local slotType = inventorySystem.GetSlotType(slot)
    if not self.SlotsAllowed[slotType] then return false end

    return true
end

function ITEM:AddToInventory(inventory, slot)
    if IsValid(self.ItemLocation) then
        local location = self.ItemLocation

        if SERVER then
            self.ItemLocation:SetItemId(-1)
            location:Remove()
        end
    end

    self.InventoryLocation = inventory
    self.SlotLocation = slot
end

function ITEM:RemoveFromInventory(inventory, slot)
    self.InventoryLocation = nil
    self.SlotLocation = nil
end

function ITEM:CreatePhysical()
    if self.InventoryLocation and self.InventoryLocation:GetItem(self.SlotLocation) == self then
        self.InventoryLocation:RemoveItem(self.SlotLocation)
    end

    local entity = ents.Create("inventory_item")
    entity:SetItemId(self:GetItemId())

    return entity
end

function ITEM:ReceiveDropped(item)
end

function ITEM:DrawItem(panel, width, height)
    self:DrawBackground(width, height, false, 6)
    self:DrawTitle(width, height / 2, 28)
    local x1, y1 = panel:LocalToScreen(6, 36)
    local x2, y2 = panel:LocalToScreen(width - 6, height - 6)
    self:RenderModel(x1, y1, x2, y2)
end

function ITEM:DrawItemDescBox(panel, width, height)
    self:DrawBackground(width, height, true)
    -- Small line below title
    surface.SetDrawColor(self:GetTypeColor())
    surface.DrawRect(6, 56, width - 12, 1)
    draw.DrawText(self.ItemType, "item_title_text", width / 2, self.ParseObjTitle:GetHeight() - 14, self:GetTypeColor(), TEXT_ALIGN_CENTER)
    self.ParseObjTitle:Draw(width / 2, 31 + 9, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    self.ParseObjDesc:Draw(14, 74, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function ITEM.Derma:Paint(w, h)
    local item = self:GetItem()
    item:DrawItem(self, w, h)
end

function ITEM.DermaDesc:Paint(w, h)
    local item = self:GetItem()
    item:DrawItemDescBox(self, w, h)
end

DEFINE_BASECLASS("DPanel")

function ITEM.Derma:OnMousePressed(keyCode)
    if keyCode == MOUSE_RIGHT then
        local menuToOpen = DermaMenu()
        local item = self:GetItem()
        item:GenerateRightClickMenu(menuToOpen)
        if menuToOpen:ChildCount() <= 0 then return BaseClass.OnMousePressed(self, keyCode) end
        menuToOpen:Open()
    end

    return BaseClass.OnMousePressed(self, keyCode)
end

function ITEM:GenerateRightClickMenu(menu)
end

if CLIENT then
    function ITEM:PerformAction(action)
        net.Start("inventorySystem.PerformAction")
        net.WriteUInt(self:GetItemId(), 16)
        net.WriteString(action)
        net.SendToServer()
    end
end

function ITEM:OnActionReceived(action, ply)
end

if SERVER then
    util.AddNetworkString("inventorySystem.PerformAction")

    net.Receive("inventorySystem.PerformAction", function(len, ply)
        if (ply.NextInventoryMovement or 0) > CurTime() then return end
        ply.NextInventoryMovement = CurTime() + 0.1
        local id = net.ReadUInt(16)
        local action = net.ReadString()
        local item = inventorySystem.GetItemFromId(id)
        if not IsValid(item) then return end
        if not item:CanPerformAction(action, ply) then return end
        item:OnActionReceived(action, ply)
    end)
end

function ITEM:CanPerformAction(action, ply)
    if self:GetParent() ~= ply then return false end

    return true
end

inventorySystem.BaseItem = ITEM