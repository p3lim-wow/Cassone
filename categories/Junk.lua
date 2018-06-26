local key = 'Junk'
local name = BAG_FILTER_JUNK -- "Junk"
local index = 998 -- as high as possible

local filter = function(Slot)
	local custom = LibContainer.db.KnownItems[Slot.itemID]
	if(custom and type(custom) == 'string') then
		return custom == key
	else
		return Slot:GetItemQuality() == LE_ITEM_QUALITY_POOR
	end
end

LibContainer:AddCategory(index, key, name, filter)
