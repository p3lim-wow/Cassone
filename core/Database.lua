local parentAddOnName = ...
local defaults = {
	KnownItems = {}, -- key = itemID, value = categoryKey
}

local database_name = 'LibContainerDB'
--[[ LibContainer:SetDatabase(globalName)
Set the global name for the database.

* globalName - global savedvariable name (string)
--]]
function LibContainer:SetDatabase(db)
	assert(type(db) == 'string', 'db argument is invalid.')
	assert(not _G[db], 'db argument is invalid.')

	-- TODO: consider using TOC metadata instead?
	database_name = db
end

--[[ LibContainer:ResetDatabase()
Resets the database back to the defaults.
--]]
function LibContainer:ResetDatabase()
	LibContainer.db = defaults
end

--[[ LibContainer:SetVariable(key, value)
Sets the variable value by key.

* key   - savedvariable key (string)
* value - savedvariable value (string|number|boolean)
--]]
function LibContainer:SetVariable(key, value)
	assert(type(key) == 'string', 'key argument is invalid.')
	assert(value ~= nil, 'value argument is invalid.')

	LibContainer.db[key] = value
end

--[[ LibContainer:GetVariable(key)
Returns the variable value by key.
--]]
function LibContainer:GetVariable(key)
	return LibContainer.db[key]
end

local function Initialize()
	local db = _G[database_name]
	if(not db) then
		db = defaults
	end

	LibContainer.db = db
	_G[database_name] = db
end

local Handler = CreateFrame('Frame')
Handler:RegisterEvent('ADDON_LOADED')
Handler:SetScript('OnEvent', function(self, event, name)
	if(name == parentAddOnName) then
		self:UnregisterEvent(event)
		Initialize()
	end
end)
