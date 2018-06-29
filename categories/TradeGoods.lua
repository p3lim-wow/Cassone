local key = 'TradeGoods'
local name = AUCTION_CATEGORY_TRADE_GOODS -- "Trade Goods"
local index = 40

local filter = function(Slot)
	local custom = LibContainer.db.KnownItems[Slot:GetItemID()]
	if(custom and type(custom) == 'string') then
		return custom == key
	else
		return Slot:GetItemClass() == LE_ITEM_CLASS_TRADEGOODS
	end
end

LibContainer:AddCategory(index, key, name, filter)