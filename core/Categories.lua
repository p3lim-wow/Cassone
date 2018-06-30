local MAX_INDEX = 999
local MIN_INDEX = 1

local function defaultSort(slotA, slotB)
	if(not slotA or not slotB) then
		return slotA or slotB
	elseif(slotA.itemQuality ~= slotB.itemQuality) then
		return slotA.itemQuality > slotB.itemQuality
	elseif(slotA.itemLevel ~= slotB.itemLevel) then
		return slotA.itemLevel > slotB.itemLevel
	elseif(slotA.itemID ~= slotB.itemID) then
		return slotA.itemID > slotB.itemID
	elseif(slotA.itemCount ~= slotB.itemCount) then
		return slotA.itemCount > slotB.itemCount
	else
		return slotA:GetID() > slotB:GetID()
	end
end

local categoryMixin = {}
--[[ Category:GetName()
Returns the name of the category.
--]]
function categoryMixin:GetName()
	return self.name
end

--[[ Category:GetLocalizedName()
Returns the localized name of the category.
--]]
function categoryMixin:GetLocalizedName()
	return self.localizedName
end

--[[ Category:Rename(localizedName)
Sets the localized name for a category.

* localizedName - localized name of the category (string)
--]]
function categoryMixin:Rename(localizedName)
	-- TODO
end

local categories = {}
--[[ LibContainer:AddCategory(index, name[, localizedName], filterFunc[, sortFunc])
Adds a category for the slots to be sorted and displayed within.

* index         - default priority for the category (integer)
* name          - name of the category (string)
* localizedName - localized name of the category (string, optional, default = name)
* filterFunc    - function that will determine how an item should be flagged as part of this category (function)
* sortFunc      - function that will determine how the items in the category should be sorted (function, optional)
--]]
function LibContainer:AddCategory(index, name, localizedName, filterFunc, sortFunc)
	assert(type(name) == 'string', 'AddCategory: name must be a string.')
	assert(not categories[index], 'AddCategory: category \'' .. name .. '\' already exists.')

	if(localizedName) then
		assert(type(localizedName) == 'string', 'AddCategory: localizedName must be a string if used.')
	else
		localizedName = name:gsub('^%l', string.upper)
	end

	assert(type(index) == 'number', 'AddCategory: index must be a number.')
	assert(index >= MIN_INDEX, 'AddCategory: index out of bounds.')
	assert(index <= MAX_INDEX, 'AddCategory: index out of bounds.')
	assert(type(filterFunc) == 'function', 'AddCategory: filterFunc must be a function if used.')

	if(sortFunc) then
		assert(type(sortFunc) == 'function', 'AddCategory: sortFunc must be a function if used.')
	else
		sortFunc = defaultSort
	end

	categories[index] = {
		index = index,
		name = name,
		localizedName = localizedName,
		filterFunc = filterFunc,
		sortFunc = sortFunc,
	}
end

--[[ LibContainer:GetCategories()
Returns a table of all categories.  
The table is indexed by the category index and valued with the Category data table.
--]]
function LibContainer:GetCategories()
	return categories
end

--[[ LibContainer:GetCategory(index)
Returns a table of the category, mixed in with the Category mixin.

* index - default priority for the category (index)
--]]
function LibContainer:GetCategory(index)
	assert(categories[index], 'GetCategory: category \'' .. index .. '\' doesn\'t exist.')
	return Mixin(categories[index], categoryMixin)
end

--[[ LibContainer:GetCategoryByName(name)
Returns a table of the category, mixed in with the Category mixin.

* name - name of the category (string)
--]]
function LibContainer:GetCategoryByName(name)
	for _, category in next, self:GetCategories() do
		if(category.name == name) then
			return Mixin(category, categoryMixin)
		end
	end
end
