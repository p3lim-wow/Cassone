local callbackMixin = LibContainer.mixins.callback
local parentMixin = LibContainer.mixins.parent

--[[ Container:header
The Container mixin is the user-facing part of [Categories](Category), and it mostly serves as a
anchor point for all the [Slots](Slot) of a given [Category](Category).

Performance and efficiency are top priorities for this mixin, as it needs to resize and position
itself, as well as all the [Slots](Slot) that are anchored to it. As such, it's only updated when
there's been a [Slot](Slot) change.

- Callbacks:
   - On [Container](Container):
      - `PreUpdateSize(Container)` - Fires before a container size is changed.
      - `PostUpdateSize(Container)` - Fires after a container size is changed.
      - `PreUpdateSlotPositions(Container)` - Fires before a container's slots are positioned.
      - `PostUpdateSlotPositions(Container)` - Fires after a container's slots are positioned.
   - On [Parent](Parent):
      - `PreUpdateContainerPositions(Parent)` - Fires before all visible containers are positioned.
      - `PostUpdateContainerPositions(Parent)` - Fires after all visible containers are positioned.
      - `PostCreateContainer(Container)` - Fires after a container is created.
--]]

local containerMixin = {}
--[[ Container:AddSlot(Slot)
Adds a Slot to the container and marks the container as "dirty".

* Slot - Slot object to add to the container (Slot)
--]]
function containerMixin:AddSlot(Slot)
	assert(type(Slot) == 'table', 'Slot argument must be a Slot.')
	assert(Slot:GetObjectType() == 'Button', 'Slot argument must be a Slot.')

	table.insert(self.slots, Slot)
	self:SetDirty(true)
end

--[[ Container:RemoveSlot(Slot)
Removes a Slot from the container and marks the container as "dirty".

* Slot - Slot object to add to the container (Slot)
--]]
function containerMixin:RemoveSlot(Slot)
	assert(type(Slot) == 'table', 'Slot argument must be a Slot.')
	assert(Slot:GetObjectType() == 'Button', 'Slot argument must be a Slot.')

	for index, containerSlot in next, self.slots do
		if(Slot == containerSlot) then
			table.remove(self.slots, index)
			self:SetDirty(true)
			break
		end
	end
end

--[[ Container:GetSlots()
Returns a table of all slots associated witht he container's category.
--]]
function containerMixin:GetSlots()
	return self.slots
end

--[[ Container:SetDirty(flag)
Sets the container as "dirty", which means it will be updated in the next update cycle.

* flag - true/false if the container should be marked as "dirty" (boolean)
--]]
function containerMixin:SetDirty(flag)
	assert(type(flag) == 'boolean', 'flag argument must be a boolean.')
	self.dirty = flag
end

--[[ Container:IsDirty()
Returns true/false if the Container is "dirty" or not.
--]]
function containerMixin:IsDirty()
	return self.dirty
end

--[[ Container:UpdateSize()
Updates the size of the Container based on the number of Slots it has attached to itself.
--]]
function containerMixin:UpdateSize()
	self:Fire('PreUpdateSize', self)
	local numSlots = #self.slots
	local categoryIndex = self:GetID()

	if(numSlots > 0 or self:GetID() == 1 or self:GetID() == 999) then
		-- the Inventory and ReagentBank containers must always be shown,
		-- but with 0 slots it looks a bit wonky
		local slotSizeX, slotSizeY = self:GetSlotSize()
		local slotSpacingX, slotSpacingY = self:GetSlotSpacing()
		local slotPaddingX, slotPaddingY = self:GetSlotPadding()
		local paddingL, paddingR, paddingU, paddingD = self:GetPadding()

		local cols = self:GetMaxColumns()
		local rows = math.ceil(numSlots / cols)

		local width = (((slotSizeX + slotSpacingX) * cols) - slotSpacingX) + (slotPaddingX) + paddingL + paddingR
		local height = (((slotSizeY + slotSpacingY) * rows) - slotSpacingY) + (slotPaddingY) + paddingU + paddingD

		self:SetSize(width, height)
		self:UpdateSlotPositions()
		self:Show()
	else
		self:Hide()
	end

	self:Fire('PostUpdateSize', self)
	self:GetParent():UpdateContainerPositions()
end

--[[ Container:UpdateSlotPositions()
Updates the positions of the Slots the Container has attached to itself.
--]]
function containerMixin:UpdateSlotPositions()
	self:Fire('PreUpdateSlotPositions', self)

	local category = LibContainer:GetCategory(self:GetID())
	table.sort(self.slots, category.sortFunc)

	local slotSizeX, slotSizeY = self:GetSlotSize()
	local slotSpacingX, slotSpacingY = self:GetSlotSpacing()
	local slotGrowX, slotGrowY = self:GetSlotGrowDirection()
	local slotRelPoint = self:GetSlotRelPoint()

	local cols = self:GetMaxColumns()
	local paddingL, paddingR, paddingU, paddingD = self:GetPadding()

	local paddingX, paddingY
	if(slotRelPoint:match('TOP')) then
		paddingY = paddingU
	elseif(slotRelPoint:match('BOTTOM')) then
		paddingY = paddingD
	end

	if(slotRelPoint:match('LEFT')) then
		paddingX = paddingL
	elseif(slotRelPoint:match('RIGHT')) then
		paddingX = paddingR
	end

	for index, Slot in next, self.slots do
		local col = (index - 1) % cols
		local row = math.floor((index - 1) / cols)

		local x = ((col * (slotSizeX + slotSpacingX)) + paddingX) * slotGrowX
		local y = ((row * (slotSizeY + slotSpacingY)) + paddingY) * slotGrowY

		Slot:ClearAllPoints()
		Slot:SetPoint(slotRelPoint, self, x, y)
	end

	self:Fire('PostUpdateSlotPositions', self)
end

--[[ Container:SetMaxColumns(numColumns)
Sets the maximum amount of columns the Container should display before wrapping to a new row.

* numColumns - number of columns (integer, default = 8)
--]]
function containerMixin:SetMaxColumns(numColumns)
	assert(type(numColumns) == 'number', 'numColumns argument must be a number.')
	assert(numColumns > 0 and numColumns < 1e2, 'numColumns must be a valid number.')

	self.maxColumns = numColumns
end

--[[ Container:GetMaxColumns()
Returns the number of columns the Container should display before wrapping to a new row.
--]]
function containerMixin:GetMaxColumns()
	return self.maxColumns or 8
end

local relPoints = {
	CENTER = true,
	BOTTOM = true,
	TOP = true,
	BOTTOMRIGHT = true,
	TOPRIGHT = true,
	BOTTOMLEFT = true,
	TOPLEFT = true,
	RIGHT = true,
	LEFT = true,
}
--[[ Container:SetRelPoint(relPoint)
Sets relative point where the Container should anchor to the Parent.

* relPoint - relative point (string, default = 'BOTTOMRIGHT')
--]]
function containerMixin:SetRelPoint(relPoint)
	assert(type(relPoint) == 'string', 'relPoint argument must be a string.')
	assert(relPoints[relPoint], 'relPoint argument must be a valid point.')

	self.relPoint = relPoint
end

--[[ Container:GetRelPoint()
Returns the relative point where the Container should anchor to the Parent.
--]]
function containerMixin:GetRelPoint()
	return self.relPoint or 'BOTTOMRIGHT'
end

--[[ Container:SetGrowDirection(x, y)
Sets the horizontal and vertical directions the containers should grow.

* x - horizontal grow direction (string|integer, default = -1|'LEFT')
* y - vertical grow direction (string|integer, default = 1|'UP')
--]]
function containerMixin:SetGrowDirection(x, y)
	if(type(x) == 'number' and type(y) == 'number') then
		assert(math.abs(x) == 1, 'x argument must be -1 or 1.')
		assert(math.abs(y) == 1, 'y argument must be -1 or 1.')
	elseif(type(x) == 'string' and type(y) == 'string') then
		assert(x == 'LEFT' or x == 'RIGHT', 'x argument must be \'LEFT\' or \'RIGHT\'.')
		assert(y == 'UP' or y == 'DOWN', 'y argument must be \'UP\' or \'DOWN\'.')
	else
		error('x or y argument is invalid.')
	end

	self.growX = x == 'LEFT' and -1 or x == 'RIGHT' and 1
	self.growY = y == 'UP' and 1 or y == 'DOWN' and -1
end

--[[ Container:GetGrowDirection()
Returns the horizontal and vertical integers for the directions the container should grow.
--]]
function containerMixin:GetGrowDirection()
	return self.growX or -1, self.growY or 1
end

--[[ Container:SetSpacing(x[, y])
Sets the horizontal and vertical spacing between containers.

* x - horizontal spacing (integer, default = 2)
* y - vertical spacing (integer, default = x|2)
--]]
function containerMixin:SetSpacing(x, y)
	assert(type(x) == 'number', 'x argument must be a number.')
	assert(y == nil or type(y) == 'number', 'y argument must be a number or nil.')

	self.spacingX = x
	self.spacingY = y or x
end

--[[ Container:GetSpacing()
Returns the horizontal and vertical integers for the spacing between containers.
--]]
function containerMixin:GetSpacing()
	return self.spacingX or 2, self.spacingY or 2
end

--[[ Container:SetPadding(left[, right][, top][, bottom])
Sets the horizontal and vertical padding within containers.

* left   - horizontal padding (integer, default = 5)
* right  - horizontal padding (integer, default = left)
* top    - vertical padding (integer, default = left)
* bottom - vertical padding (integer, default = top)
--]]
function containerMixin:SetPadding(left, right, top, bottom)
	assert(type(left) == 'number', 'left argument must be a number.')
	if(not right) then
		right = left
	else
		assert(type(right) == 'number', 'right argument must be a number.')
	end

	if(not top) then
		top = right
	else
		assert(type(top) == 'number', 'top argument must be a number.')
	end

	if(not bottom) then
		bottom = top
	else
		assert(type(bottom) == 'number', 'bottom argument must be a number.')
	end

	self.paddingL = left
	self.paddingR = right
	self.paddingU = top
	self.paddingD = bottom
end

--[[ Container:GetPadding()
Returns the horizontal and vertical integers for the four padding sides within containers.  
Order: Left, Right, Up, Down
--]]
function containerMixin:GetPadding()
	return self.paddingL or 5,
		self.paddingR or self.paddingL or 5,
		self.paddingU or self.paddingL or 5,
		self.paddingD or self.paddingD or 5
end

--[[ Container:GetName()
Returns the name for the Category the container represents.
--]]
function containerMixin:GetName()
	return LibContainer:GetCategory(self:GetID()):GetName()
end

--[[ Container:GetLocalizedName()
Returns the localized name for the Category the container represents.
--]]
function containerMixin:GetLocalizedName()
	return LibContainer:GetCategory(self:GetID()):GetLocalizedName()
end

--[[ Container:SetSlotSize(width[, height])
Sets the width and height of the Slots in the container.  
It's adviced to set both the size for the Slot on the Slot and with this method.

* width - width of the slot (integer, default = 37)
* height - height of the slot (integer, default = width|37)
--]]
function containerMixin:SetSlotSize(width, height)
	assert(type(width) == 'number', 'width argument must be a number.')
	assert(height == nil or type(height) == 'number', 'height argument must be a number or nil.')

	self.slotSizeX = width
	self.slotSizeY = height or width
end

--[[ Container:GetSlotSize()
Returns the width and height of the Slots in the container.
--]]
function containerMixin:GetSlotSize()
	local width, height = self.slotSizeX, self.slotSizeY
	if(not width and not height) then
		width, height = 37, 37
	end

	return width, height
end

--[[ Container:SetSlotRelPoint(relPoint)
Sets relative point where the Slot should anchor to the container.

* relPoint - relative point (string, default = 'TOPLEFT')
--]]
function containerMixin:SetSlotRelPoint(relPoint)
	assert(type(relPoint) == 'string', 'relPoint argument must be a string.')
	assert(relPoints[relPoint], 'relPoint argument must be a valid point.')

	self.slotRelPoint = relPoint
end

--[[ Container:GetSlotRelPoint()
Returns the relative point where the Slot should anchor to the container.
--]]
function containerMixin:GetSlotRelPoint()
	return self.slotRelPoint or 'TOPLEFT'
end

--[[ Container:SetSlotSpacing(x[, y])
Sets the horizontal and vertical spacing between Slots.

* x - horizontal spacing (integer, default = 4)
* y - vertical spacing (integer, default = x|4)
--]]
function containerMixin:SetSlotSpacing(x, y)
	assert(type(x) == 'number', 'x argument must be a number.')
	assert(y == nil or type(y) == 'number', 'y argument must be a number or nil.')

	self.slotSpacingX = x
	self.slotSpacingY = y or x
end

--[[ Container:GetSlotSpacing()
Returns the horizontal and vertical integers for the spacing between Slots.
--]]
function containerMixin:GetSlotSpacing()
	return self.slotSpacingX or 4, self.slotSpacingY or 4
end

--[[ Container:SetSlotPadding(x[, y])
Sets the horizontal and vertical padding for Slots within the container.

* x - horizontal padding (integer, default = 10)
* y - vertical padding (integer, default = x|10)
--]]
function containerMixin:SetSlotPadding(x, y)
	assert(type(x) == 'number', 'x argument must be a number.')
	assert(y == nil or type(y) == 'number', 'y argument must be a number or nil.')

	self.slotPaddingX = x
	self.slotPaddingY = y or x
end

--[[ Container:GetSlotPadding()
Returns the horizontal and vertical padding for Slots within the container.
--]]
function containerMixin:GetSlotPadding()
	return self.slotPaddingX or 10, self.slotPaddingY or 10
end

--[[ Container:SetSlotGrowDirection(x, y)
Sets the horizontal and vertical directions the Slots should grow.

* x - horizontal grow direction (string|integer, default = 1|'RIGHT')
* y - vertical grow direction (string|integer, default = -1|'DOWN')
--]]
function containerMixin:SetSlotGrowDirection(x, y)
	if(type(x) == 'number' and type(y) == 'number') then
		assert(math.abs(x) == 1, 'x argument must be -1 or 1.')
		assert(math.abs(y) == 1, 'y argument must be -1 or 1.')
	elseif(type(x) == 'string' and type(y) == 'string') then
		assert(x == 'LEFT' or x == 'RIGHT', 'x argument must be \'LEFT\' or \'RIGHT\'.')
		assert(y == 'UP' or y == 'DOWN', 'y argument must be \'UP\' or \'DOWN\'.')
	else
		error('x or y argument is invalid.')
	end

	self.slotGrowX = x == 'LEFT' and -1 or x == 'RIGHT' and 1
	self.slotGrowY = y == 'UP' and 1 or y == 'DOWN' and -1
end

--[[ Container:GetSlotGrowDirection()
Returns the horizontal and vertical integers for the directions the Slots should grow.
--]]
function containerMixin:GetSlotGrowDirection()
	return self.slotGrowX or 1, self.slotGrowY or -1
end

--[[ Container:SetMaxHeight(amount)
Sets the maximum height the rows of containers can grow.

If the amount is between 0 and 1, it'll be a percentage of the screen height.  
E.g:  
If the amount is 0.3 the containers can grow up to 30% of the screen height.  
If the amount is 500 the contaiers can grow up to 500 pixels.

* amount - amount of pixels or percentage decimal (number, default = 1)
--]]
function containerMixin:SetMaxHeight(amount)
	assert(type(amount) == 'number', 'amount argument must be a number.')
	assert(amount > 0.1 and amount < 1e4, 'amount argument must be a valid number.')

	self.maxHeight = amount
end

--[[ Container:GetMaxHeight()
Gets the maximum height the rows of containers can grow.
--]]
function containerMixin:GetMaxHeight()
	return self.maxHeight or 1
end

--[[ Parent:UpdateContainerPositions()
Updates all (visible) container positions for the Parent.
--]]
function parentMixin:UpdateContainerPositions()
	self:Fire('PreUpdateContainerPositions', self)
	local visibleContainers = {}
	for categoryIndex, Container in next, self.containers do
		if(Container:IsShown()) then
			table.insert(visibleContainers, categoryIndex)
		end
	end

	table.sort(visibleContainers, self.SortContainers)

	local parentContainer = self:GetContainer(1) -- Inventory container is always parent
	local spacingX, spacingY = parentContainer:GetSpacing()
	local growX, growY = parentContainer:GetGrowDirection()
	local relPoint = parentContainer:GetRelPoint()

	-- set the position of the parent container first
	parentContainer:ClearAllPoints()
	parentContainer:SetPoint(relPoint)

	local parentTop = parentContainer:GetTop()
	local parentBottom = parentContainer:GetBottom()
	local cols = 1

	local maxHeight = parentContainer:GetMaxHeight()
	if(maxHeight <= 1) then
		maxHeight = maxHeight * (select(2, GetPhysicalScreenSize()))
	end

	for index = 1, #visibleContainers do
		local Container = self:GetContainer(visibleContainers[index])
		if(Container ~= parentContainer) then
			local prevContainer = self:GetContainer(visibleContainers[index - 1]) or parentContainer
			local prevTop = prevContainer:GetTop()
			local prevBottom = prevContainer:GetBottom()

			if(growY > 0) then
				if((prevTop + Container:GetHeight() + spacingY) > maxHeight) then
					cols = cols + 1
					y = 0
				else
					y = prevTop - parentBottom + spacingY
				end
			else
				if((prevBottom - Container:GetHeight() - spacingY) < 0) then
					cols = cols + 1
					y = 0
				else
					y = prevBottom - parentTop - spacingY
				end
			end

			x = (Container:GetWidth() + spacingX) * (cols - 1) * growX

			Container:ClearAllPoints()
			Container:SetPoint(relPoint, x, y)
		end
	end
	self:Fire('PostUpdateContainerPositions', self)
end

--[[ Parent:UpdateContainers()
Initializes a update chain for all "dirty" Containers.
--]]
function parentMixin:UpdateContainers()
	for categoryIndex, Container in next, self:GetContainers() do
		if(Container:IsDirty() or categoryIndex == 1 or categoryIndex == 999) then
			Container:UpdateSize()
			Container:SetDirty(false)
		end
	end
end

--[[ Parent:GetContainer(categoryIndex)
Returns the Container object for the given category.

* categoryIndex - index of the category the container represents (integer)
--]]
function parentMixin:GetContainer(categoryIndex)
	return self.containers[categoryIndex]
end

--[[ Parent:GetContainers()
Returns a table of all Containers.  
The table is indexed by the category index and valued with the Container object.
--]]
function parentMixin:GetContainers()
	return self.containers
end

--[[ Parent:CreateContainers()
Creates containers for all registered categories for the Parent.
--]]
function parentMixin:CreateContainers()
	self.containers = {}

	local isBank = self:GetType() == 'bank'
	for categoryIndex, info in next, self:GetCategories() do
		if(not (not isBank and categoryIndex == 999)) then -- no reagent bank for bags
			local Container = Mixin(CreateFrame('Frame', '$parentContainer' .. info.name, self), callbackMixin, containerMixin)
			Container:SetID(categoryIndex)
			Container:Hide()
			Container.slots = {}
			Container.widgets = {}

			self:Fire('PostCreateContainer', Container)

			self.containers[categoryIndex] = Container
		end
	end
end

LibContainer.mixins.container = containerMixin
