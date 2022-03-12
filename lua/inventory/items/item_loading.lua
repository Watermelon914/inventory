ITEM.Name = "Loading.."
ITEM.Description = "This item is still loading! Please be patient"
ITEM.Base = "base_item"
ITEM.Category = "Other"
ITEM.Spawnable = false
ITEM.ItemType = "Miscellaneous"

ITEM.SlotsAllowed = {
    ["slot"] = true,
}

function ITEM:DrawLoading(width, height)
    local text = "Loading" .. string.rep(".", CurTime() % 3)
    surface.SetFont("item_title_text")
    local _, y = surface.GetTextSize(text)
    draw.DrawText(text, "item_title_text", width / 2, (height - y) / 2, self:GetTypeColor(), TEXT_ALIGN_CENTER)
end

function ITEM:DrawItemDescBox(panel, width, height)
    self:DrawBackground(width, height, true)
    self:DrawLoading(width, height)
end

function ITEM:DrawItem(panel, width, height)
    self:DrawBackground(width, height, false, 6)
    self:DrawLoading(width, height)
end