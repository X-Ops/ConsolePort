---------------------------------------------------------------
-- Utility.lua: Radial 8 button action bar  
---------------------------------------------------------------
-- Creates an 8 button action bar that can be populated with
-- items, spells, mounts, macros, etc. The user may manually
-- assign items from container buttons inside bag frames.
-- Action buttons can grab info from cursor.

---------------------------------------------------------------
local addOn, db = ...
---------------------------------------------------------------
local ConsolePort = ConsolePort
---------------------------------------------------------------
local FadeIn, FadeOut = db.UIFrameFadeIn, db.UIFrameFadeOut
local GetItemCooldown = GetItemCooldown
local InCombatLockdown = InCombatLockdown
---------------------------------------------------------------
local Utility = CreateFrame("Frame", addOn.."UtilityFrame", UIParent, "SecureHandlerBaseTemplate")
---------------------------------------------------------------
local Tooltip = CreateFrame("GameTooltip", "$parentTooltip", Utility, "GameTooltipTemplate")
---------------------------------------------------------------
local Animation = CreateFrame("Frame", addOn.."UtilityAnimation", UIParent)
---------------------------------------------------------------
local Watches = {}
---------------------------------------------------------------
local ActionButtons = {}
---------------------------------------------------------------
local OldIndex = 0
---------------------------------------------------------------
local red, green, blue = db.Atlas.GetCC()
---------------------------------------------------------------
local QUEST_STRING = select(10, GetAuctionItemClasses())
---------------------------------------------------------------

local function AnimateNewAction(self, actionButton)
	local x, y = actionButton:GetCenter()
	SetPortraitToTexture(self.Icon, actionButton.icon.texture)
	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
	self:SetSize(120, 120)
	self.Icon:SetSize(90, 90)
	self:Show()
	self.Group:Play()
end

local function AnimateOnFinished(self)
	self:GetParent():SetSize(76, 76)
	self:GetParent():Hide()
end

---------------------------------------------------------------
Animation:SetSize(76, 76)
Animation:SetFrameStrata("TOOLTIP")
Animation.Group = Animation:CreateAnimationGroup()
Animation.Icon = Animation:CreateTexture(nil, "ARTWORK")
Animation.Border = Animation:CreateTexture(nil, "OVERLAY")
Animation.Fade = Animation.Group:CreateAnimation("Alpha")
Animation.Scale = Animation.Group:CreateAnimation("Scale")
Animation.Scale:SetScale(76/120, 76/120)
Animation.Scale:SetDuration(0.5)
Animation.Scale:SetSmoothing("IN")
Animation.Scale:SetOrder(1)
Animation.Fade:SetChange(-1)
Animation.Fade:SetSmoothing("OUT")
Animation.Fade:SetOrder(2)
Animation.Fade:SetStartDelay(3)
Animation.Fade:SetDuration(0.2)
---------------------------------------------------------------
Animation.Border:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\UtilityBorder")
Animation.Border:SetAllPoints(Animation)
Animation.Icon:SetSize(62, 62)
Animation.Icon:SetPoint("CENTER", 0, 0)
---------------------------------------------------------------
Animation.Gradient = Animation:CreateTexture(nil, "BACKGROUND")
Animation.Gradient:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Window\\Circle")
Animation.Gradient:SetBlendMode("ADD")
Animation.Gradient:SetVertexColor(red, green, blue, 1)
Animation.Gradient:SetPoint("CENTER", 0, 0)
Animation.Gradient:SetSize(512, 512)
---------------------------------------------------------------
Animation.ShowNewAction = AnimateNewAction
Animation.Group:SetScript("OnFinished", AnimateOnFinished)
---------------------------------------------------------------

local function AddAction(actionType, ID)
	local currentType
	for i, ActionButton in pairs(ActionButtons) do
		currentType = ActionButton:GetAttribute("type")
		if not currentType or (currentType == actionType and (ActionButton:GetAttribute("cursorID") == ID or ActionButton:GetAttribute(actionType) == ID)) then
			if actionType == "item" then
				ActionButton:SetAttribute("cursorID", ID)
			end
			ActionButton:SetAttribute("type", actionType)
			ActionButton:SetAttribute(actionType, ID)
			ActionButton:Show()
			Animation:ShowNewAction(ActionButton)
			break
		end 
	end
end

local function CheckQuestWatches(self)
	if not InCombatLockdown() then
		wipe(Watches)
		for i=1, GetNumQuestWatches() do
			Watches[GetQuestIndexForWatch(i)] = true
		end
		for questID in pairs(Watches) do
			if GetQuestLogSpecialItemInfo(questID) then
				local name, link, _, _, _, class, sub, _, _, texture = GetItemInfo(GetQuestLogSpecialItemInfo(questID))
				local _, itemID = strsplit(":", strmatch(link, "item[%-?%d:]+"))
				AddAction("item", itemID)
			end
		end
		self:RemoveUpdateSnippet(CheckQuestWatches)
	end
end

---------------------------------------------------------------
Utility:SetPoint("CENTER", 0, 0)
Utility:Hide()
---------------------------------------------------------------
Utility.Gradient = Utility:CreateTexture(nil, "BACKGROUND")
Utility.Gradient:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Window\\Circle")
Utility.Gradient:SetBlendMode("ADD")
Utility.Gradient:SetVertexColor(red, green, blue, 1)
Utility.Gradient:SetPoint("CENTER", 0, 0)
Utility.Gradient:SetSize(512, 512)
---------------------------------------------------------------
Utility.Tooltip = Tooltip

function Tooltip:OnShow()
	-- edge file fractioned pixel fix, pretty unncessary
	local width, height = self:GetSize()
	width, height = floor(width + 0.5) + 4, floor(height + 0.5) + 4
	local point, anchor, relative, x, y = self:GetPoint()
	self:ClearAllPoints()
	self:SetPoint(point, anchor, relative, floor(x + 0.5), floor(y + 0.5))
	self:SetSize(width - (width % 2), height - (height % 2))
	-- set CC backdrop
	self:SetBackdropColor(red*0.15, green*0.15, blue*0.15,  0.75)
	FadeIn(self, 0.2, 0, 1)
end

Tooltip:SetBackdrop(db.Atlas.Backdrops.Tooltip)
Tooltip:SetScript("OnShow", Tooltip.OnShow)
Tooltip:SetPoint("CENTER", 0, 0)
Tooltip:SetOwner(Utility)
---------------------------------------------------------------
Utility:HookScript("OnEvent", function(self, event, ...)
	if event == "QUEST_WATCH_LIST_CHANGED" then
		ConsolePort:AddUpdateSnippet(CheckQuestWatches)
	elseif event == "BAG_UPDATE" then
		for i, ActionButton in pairs(ActionButtons) do
			ActionButton:Update(0.25)
		end
	end
end)
Utility:HookScript("OnAttributeChanged", function(self, attribute, detail)
	if attribute == "index" then
		if ActionButtons[OldIndex] then
			ActionButtons[OldIndex]:Leave()
		end
		if ActionButtons[detail] then
			ActionButtons[detail]:Enter()
		end
		OldIndex = detail
	end
end)
Utility:HookScript("OnHide", function(self)
	for i, ActionButton in pairs(ActionButtons) do
		ActionButton:Leave()
	end
end)
Utility:Execute([[
	---------------------------------------------------------------
	KEYS = newtable()
	---------------------------------------------------------------
	INDEX = 0
	---------------------------------------------------------------
	KEYS.UP 	= false
	KEYS.LEFT 	= false
	KEYS.DOWN 	= false
	KEYS.RIGHT 	= false
	---------------------------------------------------------------
	KEYS.W 		= false
	KEYS.A 		= false
	KEYS.S 		= false
	KEYS.D 		= false
	---------------------------------------------------------------
	OnKey = [=[
		local key, down = ...
		if down then
			if key == "UP" then
				KEYS.DOWN = false
				KEYS.UP = true
			elseif key == "DOWN" then
				KEYS.UP = false
				KEYS.DOWN = true
			elseif key == "LEFT" then
				KEYS.RIGHT = false
				KEYS.LEFT = true
			elseif key == "RIGHT" then
				KEYS.LEFT = false
				KEYS.RIGHT = true
			end
		else
			KEYS[key] = false
		end
		INDEX = ( KEYS.UP and KEYS.RIGHT 	) and 2 or
				( KEYS.DOWN and KEYS.RIGHT 	) and 4 or
				( KEYS.DOWN and KEYS.LEFT 	) and 6 or
				( KEYS.UP and KEYS.LEFT 	) and 8 or
				( KEYS.UP 					) and 1 or
				( KEYS.RIGHT 				) and 3 or
				( KEYS.DOWN 				) and 5 or
				( KEYS.LEFT 				) and 7 or 0
		self:SetAttribute("index", INDEX)
	]=]

	CursorUpdate = [=[
		local hasItem = ...
		local children = newtable(self:GetChildren())
		if hasItem then
			self:Show()
			for _, child in pairs(children) do
				if not child:GetAttribute("type") then
					child:Show()
					child:SetAlpha(0.5)
				end
			end
		elseif not hasItem and not TOGGLED then
			self:Hide() 
			for _, child in pairs(children) do
				if not child:GetAttribute("type") then
					child:Hide()
				end
			end
		end
	]=]

	UseUtility = [=[
		local enabled = ...
		if enabled then
			TOGGLED = true
			INDEX = 0
			self:Show()
			for key in pairs(KEYS) do
				self:SetBindingClick(true, key, "ConsolePortUtilityButton"..key)
				self:SetBindingClick(true, "CTRL-"..key, "ConsolePortUtilityButton"..key)
				self:SetBindingClick(true, "SHIFT-"..key, "ConsolePortUtilityButton"..key)
				self:SetBindingClick(true, "CTRL-SHIFT-"..key, "ConsolePortUtilityButton"..key)
			end
		else
			TOGGLED = false
			for key in pairs(KEYS) do
				KEYS[key] = false
			end
			self:ClearBindings()
			self:Hide()
		end
	]=]
]])

------------------------------------------------------------------------------------------------------------------------------
local UseUtility = CreateFrame("Button", addOn.."UtilityToggle", nil, "SecureActionButtonTemplate, SecureHandlerBaseTemplate")
------------------------------------------------------------------------------------------------------------------------------
local Timer = 0
local CursorItem
---------------------------------------------------------------
UseUtility:HookScript("OnUpdate", function(self, elapsed)
	Timer = Timer + elapsed
	while Timer > 0.1 do
		if not CursorItem and GetCursorInfo() and not InCombatLockdown() then
			Utility:Execute([[ self:Run(CursorUpdate, true) ]])
			CursorItem = true
		elseif CursorItem and not GetCursorInfo() and not InCombatLockdown() then
			Utility:Execute([[ self:Run(CursorUpdate, nil)  ]])
			CursorItem = nil
		end
		Timer = Timer - 0.1
	end
end)
---------------------------------------------------------------
UseUtility:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
UseUtility:SetFrameRef("Utility", Utility)
UseUtility:SetAttribute("type", "macro")
Utility:WrapScript(UseUtility, "OnClick", [[
	local Utility = self:GetFrameRef("Utility")
	Utility:Run(UseUtility, down)
	if down then
		self:SetAttribute("macrotext", nil)
	else
		local button = Utility:GetFrameRef(tostring(INDEX))
		if button then
			self:SetAttribute("macrotext", "/click "..button:GetName().." LeftButton")
		else
			self:SetAttribute("macrotext", nil)
		end
	end
]])
Utility:WrapScript(UseUtility, "OnDoubleClick", [[
	local Utility = self:GetFrameRef("Utility")
	Utility:Run(UseUtility, true)
]])
GameMenuButtonController:SetFrameRef("Utility", Utility)
Utility:WrapScript(GameMenuButtonController, "OnClick", [[
	local Utility = self:GetFrameRef("Utility")
	Utility:Run(UseUtility, nil)
]])
---------------------------------------------------------------
local buttons = {
	["UP"] 		= {"W", "UP"},
	["LEFT"] 	= {"A", "LEFT"},
	["DOWN"] 	= {"S", "DOWN"},
	["RIGHT"] 	= {"D", "RIGHT"},
}
---------------------------------------------------------------
local dropTypes = {
	item = true,
	spell = true,
	macro = true,
	mount = true,
}
---------------------------------------------------------------
for direction, keys in pairs(buttons) do
	for _, key in pairs(keys) do
		local button = CreateFrame("Button", addOn.."UtilityButton"..key, nil, "SecureActionButtonTemplate, SecureHandlerBaseTemplate")
		button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
		button:SetFrameRef("Utility", Utility)
		Utility:WrapScript(button, "OnClick", format([[
			local Utility = self:GetFrameRef("Utility")
			Utility:Run(OnKey, "%s", down)
		]], direction, direction))
	end
end
---------------------------------------------------------------

local function ActionButtonPreClick(self, button)
	if not InCombatLockdown() then
		if button == "RightButton" then
			self:SetAttribute("type", nil)
			Utility:Execute([[ self:Run(CursorUpdate, nil)  ]])
			self:Hide()
			self.cooldown:SetCooldown(0, 0)
			ClearCursor()
		elseif dropTypes[GetCursorInfo()] then
			self:SetAttribute("type", nil)
		end
	end
end

local function ActionButtonPostClick(self, button)
	if dropTypes[GetCursorInfo()] then
		local cursorType, id,  mountID, spellID = GetCursorInfo()
		ClearCursor()

		if InCombatLockdown() then
			return
		end

		self:SetAttribute("type", cursorType)
		self:SetAttribute("cursorID", id)
		self:SetAttribute(cursorType, cursorType == "spell" and spellID or cursorType == "mount" and mountID or id)
	end
end

local function ActionButtonOnAttributeChanged(self, attribute, detail)
	if not InCombatLockdown() then
		local texture, isQuest
		if detail then
			if attribute == "item" then
				if tonumber(detail) then
					local name = GetItemInfo(detail)
					self:SetAttribute("item", name)
					return
				end
				texture = select(10, GetItemInfo(detail))
				isQuest = select(6, GetItemInfo(detail)) == QUEST_STRING
			elseif attribute == "spell" then
				texture = select(3, GetSpellInfo(detail))
			elseif attribute == "macro" then
				texture = select(2, GetMacroInfo(detail))
			elseif attribute == "mount" then
				local spellID = MountJournal_GetMountInfo(detail)
				self:SetAttribute("type", "spell")
				self:SetAttribute("spell", spellID)
				return
			end
			ClearCursor()
		end
		if texture then
			self.icon.texture = texture
			SetPortraitToTexture(self.icon, texture)
			self:SetAlpha(1)
		else
			self.icon.texture = nil
			self.icon:SetTexture(nil)
			self:SetAlpha(0.5)
		end
		if isQuest then
			self.Quest:Show()
		else
			self.Quest:Hide()
		end
	end
	local actionType = self:GetAttribute("type")
	if actionType then
		ConsolePortUtility[self.ID] = {
			action = actionType,
			value = self:GetAttribute(actionType),
			cursorID = self:GetAttribute("cursorID")
		}
	else
		ConsolePortUtility[self.ID] = nil
	end
end

local function ActionButtonOnEnter(self)
	self.HasFocus = true
	FadeIn(self.Pushed, 0.2, self.Pushed:GetAlpha(), 1)
	FadeIn(self.Highlight, 0.2, self.Highlight:GetAlpha(), 0.5)
	FadeOut(self.Quest, 0.2, self.Quest:GetAlpha(), 0)
end

local function ActionButtonOnLeave(self)
	self.HasFocus = nil
	if Tooltip:GetOwner() == self then
		Tooltip:Hide()
	end
	FadeOut(self.Pushed, 0.2, self.Pushed:GetAlpha(), 0)
	FadeOut(self.Highlight, 0.2, self.Highlight:GetAlpha(), 0)
	FadeIn(self.Quest, 0.2, self.Quest:GetAlpha(), 1)
end

local function ActionButtonOnUpdate(self, elapsed)
	self.Timer = self.Timer + elapsed
	while self.Timer > 0.25 do
		local actionType = self:GetAttribute("type")
		if actionType == "item" then
			local count = GetItemCount(self:GetAttribute("item"))
			if count < 1 and not InCombatLockdown() then
				self:SetAttribute("type", nil)
				self:SetAttribute("item", nil)
				self:Hide()
			else
				local time, cooldown = GetItemCooldown(self:GetAttribute("cursorID"))
				self.cooldown:SetCooldown(time, cooldown)
				if count > 1 then
					self.Count:SetText(count)
				else
					self.Count:SetText("")
				end
			end
		elseif actionType == "spell" then
			local spellID = self:GetAttribute("spell")
			local count = GetSpellCharges(spellID)
			local time, cooldown = GetSpellCooldown(spellID)
			self.cooldown:SetCooldown(time, cooldown)
			if count then
				self.Count:SetText(count)
			else
				self.Count:SetText("")
			end
		end
		if self.HasFocus then
			self.Idle = self.Idle + self.Timer
			if self.Idle > 1 then
				if actionType == "item" then
					Tooltip:SetOwner(self, "ANCHOR_BOTTOM")
					Tooltip:SetItemByID(self:GetAttribute("cursorID"))
				elseif actionType == "spell" then
					Tooltip:SetOwner(self, "ANCHOR_BOTTOM")
					Tooltip:SetSpellByID(self:GetAttribute("spell"))
				end
				self.HasFocus = nil
			end
		else
			self.Idle = 0
		end

		self.Timer = self.Timer - 0.25
	end
end

---------------------------------------------------------------
for i=1, 8 do
	local x, y, r = 0, 0, 180
	local angle = (i+1) * (360 / 8) * math.pi / 180
	local ptx, pty = x + r * math.cos( angle ), y + r * math.sin( angle )
	local ActionButton = CreateFrame("Button", addOn.."UtilityActionButton"..i, Utility, "ActionButtonTemplate, SecureActionButtonTemplate")

	ActionButton.Timer = 0
	ActionButton.Idle = 0
	ActionButton.ID = i
	ActionButton:Hide()
	ActionButton:SetSize(46, 46)
	ActionButton:SetPoint("CENTER", self, "CENTER", -ptx, pty)
	ActionButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	ActionButton.Border = CreateFrame("Frame", "$parentBorder", ActionButton)
	ActionButton.Border:SetAllPoints(ActionButton)

	ActionButton.NormalTexture:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\UtilityBorder")
	ActionButton.NormalTexture:ClearAllPoints()
	ActionButton.NormalTexture:SetParent(ActionButton.Border)
	ActionButton.NormalTexture:SetPoint("CENTER", 0, 0)
	ActionButton.NormalTexture:SetSize(76, 76)
	ActionButton.NormalTexture:SetDrawLayer("OVERLAY", 4)

	ActionButton.cooldown:ClearAllPoints()
	ActionButton.cooldown:SetPoint("CENTER", ActionButton, 0, 0)
	ActionButton.cooldown:SetSize(46, 46)

	ActionButton.Count:ClearAllPoints()
	ActionButton.Count:SetPoint("BOTTOM", 0, 2)

	ActionButton.icon:ClearAllPoints()
	ActionButton.icon:SetPoint("CENTER", 0, 0)
	ActionButton.icon:SetSize(54, 54)

	ActionButton.Pushed = ActionButton:GetPushedTexture()
	ActionButton.Pushed:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\UtilityBorder")
	ActionButton.Pushed:SetParent(ActionButton.Border)
	ActionButton.Pushed:SetAllPoints(ActionButton.NormalTexture)
	ActionButton.Pushed:SetVertexColor(red, green, blue, 1)
	ActionButton.Pushed:SetDrawLayer("OVERLAY", 5)
	ActionButton.Pushed:SetAlpha(0)

	ActionButton:GetHighlightTexture():SetTexture(nil)

	ActionButton.Highlight = ActionButton.Border:CreateTexture(nil, "OVERLAY", nil, 6)
	ActionButton.Highlight:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\UtilityBorderHighlight")
	ActionButton.Highlight:SetAllPoints(ActionButton.NormalTexture)
	ActionButton.Highlight:SetVertexColor(red, green, blue, 0.5)
	ActionButton.Highlight:SetBlendMode("ADD")
	ActionButton.Highlight:SetAlpha(0)

	ActionButton.Quest = ActionButton.Border:CreateTexture(nil, "OVERLAY", nil, 7)
	ActionButton.Quest:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\QuestButton")
	ActionButton.Quest:SetPoint("CENTER", 0, 0)
	ActionButton.Quest:SetSize(64, 64)

	ActionButton:SetScript("PreClick", ActionButtonPreClick)
	ActionButton:SetScript("PostClick", ActionButtonPostClick)
	ActionButton:SetScript("OnAttributeChanged", ActionButtonOnAttributeChanged)

	ActionButton.Leave = ActionButtonOnLeave
	ActionButton.Enter = ActionButtonOnEnter
	ActionButton.Update = ActionButtonOnUpdate

	ActionButton:HookScript("OnEnter", ActionButtonOnEnter)
	ActionButton:HookScript("OnLeave", ActionButtonOnLeave)
	ActionButton:HookScript("OnUpdate", ActionButtonOnUpdate)

	Utility:SetFrameRef(tostring(i), ActionButton)
	tinsert(ActionButtons, ActionButton)
end

---------------------------------------------------------------
---------------------------------------------------------------
function ConsolePort:AddUtilityAction(actionType, value)
	if actionType and value then
		AddAction(actionType, value)
	end
end

function ConsolePort:SetupUtilityBelt()
	for index, info in pairs(ConsolePortUtility) do
		local actionButton = ActionButtons[index]
		if info.action then
			actionButton:SetAttribute("type", info.action)
			actionButton:SetAttribute("cursorID", info.cursorID)
			actionButton:SetAttribute(info.action, info.value)
			actionButton:Show()
		end
	end

	if ConsolePortSettings.autoExtra then
		self:AddUpdateSnippet(CheckQuestWatches)
		Utility:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
	else
		Utility:UnregisterEvent("QUEST_WATCH_LIST_CHANGED")
	end

	Utility:RegisterEvent("BAG_UPDATE")
end