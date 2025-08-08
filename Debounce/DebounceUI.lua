﻿local _, DebouncePrivate     = ...;
DebouncePrivate.DebounceUI   = {};

local NUM_SPECS              = GetNumSpecializationsForClassID(select(3, UnitClass("player")));
local Constants              = DebouncePrivate.Constants;
local LLL                    = DebouncePrivate.L;
local DebounceUI             = DebouncePrivate.DebounceUI;

local MACRO_NAME_CHAR_LIMIT  = 32;
local MACRO_CHAR_LIMIT       = 1000;
local DISABLED_FONT_COLOR    = _G.DISABLED_FONT_COLOR;
local ERROR_COLOR            = _G.ERROR_COLOR;
local WARNING_FONT_COLOR     = CreateColor(1, 0.5, 0, 1);
local INACTIVE_COLOR         = _G.INACTIVE_COLOR;
local FILTERED_ALPHA         = 0.3;

local luatype                = type;
local dump                   = DebouncePrivate.dump;
local GetBindingIssue        = DebouncePrivate.GetBindingIssue;
local IsKeyInvalidForAction  = DebouncePrivate.IsKeyInvalidForAction
local GetSpellNameAndIconID  = DebouncePrivate.GetSpellNameAndIconID;
local GetSpellTabNameAndIcon = DebouncePrivate.GetSpellTabNameAndIcon;
local InCombatLockdown       = InCombatLockdown;
local QUESTION_MARK_ICON_NUM = 134400;
local TEMP_MACRO_NAME        = "zzDbncTmpMcr"

local _selectedTab           = 1;
local _selectedSideTab       = 1;
local _placeholder;
local _draggingElement;
local _pickedupInfo;
local _newlyInsertedActions  = {};

DebounceUI.ActionMenuRootTag = "DEBOUNCE_ACTION_ROOT";

local _macrotextIconCache    = {};
local function GetMacrotextIcon(macrotext)
	if (macrotext == nil or macrotext == "") then
		return QUESTION_MARK_ICON_NUM;
	end

	-- for line in string.gmatch(macrotext, "[^\r\n]+") do
	-- 	-- Trim trailing whitespace from each line
	-- 	line = string.gsub(line, "%s+$", "")

	-- 	local val = SecureCmdOptionParse(line);
	-- 	-- if (string.sub(line, 1, 12):lower() == "#showtooltip") then
	-- 	-- 	val = string.sub(line, 13):gsub("%s+", ""):match("%s*(.*)");
	-- 	-- elseif (string.sub(line, 1, 1) == "/") then
	-- 	-- 	val = string.match(line, "%s+(.*)")
	-- 	-- end
	-- 	if (val and val:len() > 0) then
	-- 		local _, icon = GetSpellNameAndIconID(val);
	-- 		if (icon == nil) then
	-- 			_, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(val);
	-- 		end
	-- 		return icon;
	-- 	end
	-- end

	if (_macrotextIconCache[macrotext]) then
		return _macrotextIconCache[macrotext];
	end
	if (InCombatLockdown()) then
		return nil;
	end
	if (MacroFrame and MacroFrame:IsShown()) then
		return nil;
	end

	local ret;
	if (not GetMacroInfo(TEMP_MACRO_NAME)) then
		local cnt1, cnt2 = GetNumMacros();
		local isCharacterSpecific;
		if (cnt1 >= MAX_ACCOUNT_MACROS) then
			if (cnt2 >= MAX_CHARACTER_MACROS) then
				return nil;
			end
			isCharacterSpecific = true;
		end
		CreateMacro(TEMP_MACRO_NAME, QUESTION_MARK_ICON_NUM, macrotext, isCharacterSpecific);
	else
		EditMacro(TEMP_MACRO_NAME, nil, nil, macrotext);
	end

	_, ret = GetMacroInfo(TEMP_MACRO_NAME);
	DeleteMacro(TEMP_MACRO_NAME);
	_macrotextIconCache[macrotext] = ret;
	return ret;
end

local function ClearMacrotextIconCache()
	if (DebounceFrame:IsShown()) then
		return;
	end
	if (DebounceOverviewFrame:IsShown()) then
		return;
	end
	wipe(_macrotextIconCache);
end

local BINDING_TYPE_NAMES   = {
	[Constants.SPELL] = LLL["TYPE_SPELL"],
	[Constants.ITEM] = LLL["TYPE_ITEM"],
	[Constants.MACRO] = LLL["TYPE_MACRO"],
	[Constants.MACROTEXT] = LLL["TYPE_MACROTEXT"],
	[Constants.MOUNT] = LLL["TYPE_MOUNT"],
	[Constants.TARGET] = LLL["TYPE_TARGET"],
	[Constants.FOCUS] = LLL["TYPE_FOCUS"],
	[Constants.TOGGLEMENU] = LLL["TYPE_TOGGLEMENU"],
	[Constants.COMMAND] = LLL["TYPE_COMMAND"],
	[Constants.WORLDMARKER] = LLL["TYPE_WORLDMARKER"],
	[Constants.SETCUSTOM] = LLL["TYPE_SETCUSTOM"],
	[Constants.SETSTATE] = LLL["TYPE_SETSTATE"],
	[Constants.UNUSED] = LLL["TYPE_UNUSED"],
};

local UNIT_FRAME_REACTIONS = {
	"HELP",
	"HARM",
	"OTHER",
};

local UNIT_FRAME_TYPES     = {
	"PLAYER",
	"PET",
	"GROUP",
	"TARGET",
	"BOSS",
	"ARENA",
	"UNKNOWN",
};

local UNIT_INFO            = {
	player = {
		name = LLL["UNIT_PLAYER"],
		unitexists = false,
	},
	pet = {
		name = LLL["UNIT_PET"],
		checkedUnit = false,
	},
	target = {
		name = LLL["UNIT_TARGET"],
		--spell = false,
		--item = false,
		--target = false,
	},
	focus = {
		name = LLL["UNIT_FOCUS"],
		focus = false,
	},
	mouseover = {
		name = LLL["UNIT_MOUSEOVER"],
		togglemenu = false, -- doesn't work!
	},
	tank = {
		name = LLL["UNIT_TANK"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
		type = "role",
	},
	healer = {
		name = LLL["UNIT_HEALER"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
		type = "role",
	},
	maintank = {
		name = LLL["UNIT_MAINTANK"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
		type = "role",
	},
	mainassist = {
		name = LLL["UNIT_MAINASSIST"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
		type = "role",
	},
	custom1 = {
		name = LLL["UNIT_CUSTOM1"],
		type = "custom",
	},
	custom2 = {
		name = LLL["UNIT_CUSTOM2"],
		type = "custom",
	},
	hover = {
		name = LLL["UNIT_HOVER"],
		-- spell = false,
		-- item = false,
		tooltipTitle = LLL["UNIT_HOVER_DESC"],
		tooltipWarning = DebouncePrivate.CliqueDetected and ERROR_COLOR:WrapTextInColorCode(LLL["BINDING_ERROR_CANNOT_USE_HOVER_WITH_CLIQUE"]) or nil,
		unitexists = false,
	},
	none = {
		name = LLL["UNIT_NONE"],
		tooltipTitle = LLL["UNIT_NONE_DESC"],
		target = false,
		focus = false,
		togglemenu = false,
		unitexists = false,
	},
};

local _keyInfoCache        = {};
local _mods                = {
	LALT = true,
	RALT = true,
	ALT = true,
	LCTRL = true,
	RCTRL = true,
	CTRL = true,
	LSHIFT = true,
	RSHIFT = true,
	SHIFT = true,
	META = true,
}
local function _GetKeyInfo(key)
	if (_keyInfoCache[key]) then
		return _keyInfoCache[key];
	end
	local sa = { strsplit("-", key) };
	local keyInfo = {};
	keyInfo.key = key;
	if (#sa > 0 and not _mods[sa[#sa]]) then
		keyInfo.lastKey = GetConvertedKeyOrButton(tremove(sa, #sa));
	end
	keyInfo.mods = sa;

	_keyInfoCache[key] = keyInfo;
	return keyInfo;
end

local function _CreateKeyChordStringUsingMetaKeyState(key, useLeftRight)
	local chord = {};
	-- 순서: ALT-CTRL-SHIFT

	if useLeftRight and IsLeftAltKeyDown() then
		table.insert(chord, "LALT");
	elseif useLeftRight and IsRightAltKeyDown() then
		table.insert(chord, "RALT");
	elseif IsAltKeyDown() then
		table.insert(chord, "ALT");
	end

	if useLeftRight and IsLeftControlKeyDown() then
		table.insert(chord, "LCTRL");
	elseif useLeftRight and IsRightControlKeyDown() then
		table.insert(chord, "RCTRL");
	elseif IsControlKeyDown() then
		table.insert(chord, "CTRL");
	end

	if useLeftRight and IsLeftShiftKeyDown() then
		table.insert(chord, "LSHIFT");
	elseif useLeftRight and IsRightShiftKeyDown() then
		table.insert(chord, "RSHIFT");
	elseif IsShiftKeyDown() then
		table.insert(chord, "SHIFT");
	end

	if IsMetaKeyDown() then
		table.insert(chord, "META");
	end

	if not IsMetaKey(key) then
		table.insert(chord, key);
	end

	local preventSort = true;
	return CreateKeyChordStringFromTable(chord, preventSort);
end

local GetActionBarTypeLabel;
do
	local _bonusbarLabels;
	function GetActionBarTypeLabel(index)
		if (_bonusbarLabels == nil) then
			_bonusbarLabels = {
				[0] = LLL["DEFAULT"],
				[5] = GetFlyoutInfo(229),
			};
			if (Constants.PLAYER_CLASS == "DRUID") then
				_bonusbarLabels[1] = GetSpellNameAndIconID(768);
				_bonusbarLabels[3] = GetSpellNameAndIconID(5487);
				_bonusbarLabels[4] = GetSpellNameAndIconID(24858);
			elseif (Constants.PLAYER_CLASS == "ROGUE") then
				_bonusbarLabels[1] = GetSpellNameAndIconID(1784);
			end
			for i = 0, Constants.MAX_BONUS_ACTIONBAR_OFFSET do
				local text = _bonusbarLabels[i];
				_bonusbarLabels[i] = format("[bonusbar:%d]", i);
				if (text) then
					_bonusbarLabels[i] = format("%s (%s)", _bonusbarLabels[i], text);
				end
			end
		end
		return _bonusbarLabels[index];
	end
end

local function GetLayerID(tab, sideTab)
	tab = tab or _selectedTab;
	sideTab = sideTab or _selectedSideTab;
	local isCharacterSpecific = tab == 2;
	local spec = sideTab >= 2 and sideTab - 2 or nil;
	return DebouncePrivate.GetLayerID(spec, isCharacterSpecific);
end

local function GetTabLabel(tabID)
	if (tabID == 1) then
		return LLL["SHARED_BINDINGS"];
	else
		return format(LLL["CHARACTER_SPECIFIC_BINDINGS"], UnitName("player"));
	end
end

local function GetSideTabaLabel(sideTabID)
	if (sideTabID == 1) then
		return LLL["GENERAL"];
	elseif (sideTabID == 2) then
		return UnitClass("player");
	else
		local _, specName = GetSpecializationInfo(sideTabID - 2);
		return specName;
	end
end

local function DoesAncestryIncludeMouseFocus(ancestry)
	local mouseFoci = GetMouseFoci();
	for _, mouseFocus in ipairs(mouseFoci) do
		if (DoesAncestryInclude(ancestry, mouseFocus)) then -- and (mouseFocus:GetObjectType() ~= "Button")
			return true;
		end
	end
	return false;
end

local function TryCloseAnyDialog()
	if (DebounceIconSelectorFrame:Close() and DebounceMacroFrame:Close() and DebounceKeybindFrame:Close()) then
		return true;
	end
	return false;
end

local function IsEditingMacro(elementData)
	if (DebounceMacroFrame:IsShown() and (elementData == nil or DebounceMacroFrame.elementData == elementData)) then
		return true;
	elseif (DebounceIconSelectorFrame:IsShown() and (elementData == nil or DebounceIconSelectorFrame.elementData == elementData)) then
		return true;
	else
		return false;
	end
end

local function IsEditDropdownShown(elementData)
	if (DebounceFrame.contextMenu) then
		if (elementData == nil or DebounceFrame.contextMenuData == elementData) then
			return true;
		end
	end
	return false;
end

local function IsKeybindFrameShown(elementData)
	if (DebounceKeybindFrame and DebounceKeybindFrame:IsShown() and (elementData == nil or DebounceKeybindFrame.elementData == elementData)) then
		return true;
	end
	return false;
end

local function IsDraggingElement(elementData)
	if (elementData ~= nil) then
		return _draggingElement == elementData;
	else
		return _draggingElement ~= nil;
	end
end

local function GetDraggingElement()
	return _draggingElement;
end

local function GetActionTypeAndValueFromCursorInfo()
	local type, value;
	local cursorType, cursorInfo1, _, cursorInfo3 = GetCursorInfo();

	if (cursorType) then
		if (cursorType == "spell") then
			type, value = Constants.SPELL, cursorInfo3;
		elseif (cursorType == "macro") then
			---@diagnostic disable-next-line: param-type-mismatch
			local macroName = GetMacroInfo(cursorInfo1);
			type, value = Constants.MACRO, macroName;
		elseif (cursorType == "item") then
			type, value = Constants.ITEM, cursorInfo1;
		elseif (cursorType == "mount") then
			if (cursorInfo1 == 268435455) then
				cursorInfo1 = 0;
			end
			type, value = Constants.MOUNT, cursorInfo1;
		end
		return type, value;
	end
end

local function NameAndIconFromElementData(elementData)
	local action;
	local type;
	local value;
	local skipTypeName;
	if (elementData.action) then
		action = elementData.action;
		type = action.type;
		value = action.value;
	else
		action = elementData;
		type = action.type;
		value = action.value;
	end

	local actionName, actionIcon;
	if (type == Constants.SPELL) then
		local baseSpellID = FindBaseSpellByID(value) or value;
		local overrideID = FindSpellOverrideByID(baseSpellID);
		actionName, actionIcon = GetSpellNameAndIconID(overrideID);
	elseif (type == Constants.MACRO) then
		local macroName;
		macroName, actionIcon = GetMacroInfo(value);
		if (not macroName) then
			macroName = value;
			actionIcon = QUESTION_MARK_ICON_NUM;
		end
		actionName = macroName;
	elseif (type == Constants.MACROTEXT) then
		actionName = action.name;
		actionIcon = action.icon
		if (actionIcon == QUESTION_MARK_ICON_NUM) then
			actionIcon = GetMacrotextIcon(action.value) or actionIcon;
		end
	elseif (type == Constants.ITEM) then
		local name = C_Item.GetItemNameByID(value);
		local icon = C_Item.GetItemIconByID(value);
		actionName = name;
		actionIcon = icon;
	elseif (type == Constants.MOUNT) then
		local name, icon;
		if (value == 0 or value == 268435455) then
			name, icon = GetSpellNameAndIconID(150544);
		elseif (value) then
			name, _, icon = C_MountJournal.GetMountInfoByID(value);
		end
		actionName = name;
		actionIcon = icon;
	elseif (type == Constants.SETCUSTOM) then
		actionName = LLL["TYPE_SETCUSTOM" .. value];
		actionIcon = 1505950;
		skipTypeName = true;
	elseif (type == Constants.SETSTATE) then
		local mode, stateIndex = DebouncePrivate.GetSetCustomStateModeAndIndex(value);

		if (mode == "on") then
			actionName = format(LLL["TYPE_SETSTATE_ON_NUM"], stateIndex);
		elseif (mode == "off") then
			actionName = format(LLL["TYPE_SETSTATE_OFF_NUM"], stateIndex);
		elseif (mode == "toggle") then
			actionName = format(LLL["TYPE_SETSTATE_TOGGLE_NUM"], stateIndex);
		end
		actionIcon = 254885;
		skipTypeName = true;
	elseif (type == Constants.COMMAND) then
		actionName = _G["BINDING_NAME_" .. value] or value;
		actionIcon = "A:NPE_Icon"
	elseif (type == Constants.TARGET) then
		actionName = BINDING_TYPE_NAMES[Constants.TARGET];
		actionIcon = 132212;
		skipTypeName = true;
	elseif (type == Constants.FOCUS) then
		actionName = LLL["TYPE_FOCUS"];
		actionIcon = 132212;
		skipTypeName = true;
	elseif (type == Constants.TOGGLEMENU) then
		actionName = LLL["TYPE_TOGGLEMENU"];
		actionIcon = 134331;
		skipTypeName = true;
	elseif (type == Constants.WORLDMARKER) then
		actionName = _G["WORLD_MARKER" .. value];
		actionIcon = 4238933;
		skipTypeName = true;
	elseif (type == Constants.UNUSED) then
		actionName = BINDING_TYPE_NAMES[Constants.UNUSED];
		actionIcon = "INTERFACE\\RAIDFRAME\\ReadyCheck-NotReady";
		skipTypeName = true;
	else
		actionName = action.name or LLL["UNNAMED_ACTION"];
		actionIcon = action.icon or QUESTION_MARK_ICON_NUM;
	end

	if (not skipTypeName) then
		local typeName = BINDING_TYPE_NAMES[action.type]; -- rawget(LLL, action.type);
		if (typeName) then
			actionName = format(LLL["BINDING_TITLE"], typeName or "?", actionName or "?");
		end
	end
	actionName = actionName or "?";
	return actionName, actionIcon or QUESTION_MARK_ICON_NUM;
end

local function ColoredNameAndIconFromElementData(elementData)
	local name, icon = NameAndIconFromElementData(elementData);
	local action = elementData.action;
	if (action.key == nil or DebouncePrivate.IsInactiveAction(action)) then
		name = DISABLED_FONT_COLOR:WrapTextInColorCode(name);
	elseif (GetBindingIssue(action)) then
		name = ERROR_COLOR:WrapTextInColorCode(name);
	end
	return name, icon;
end



local function DeleteElementData(elementData)
	if (IsEditingMacro(elementData)) then
		DebounceMacroFrame:Hide();
	end

	if (IsKeybindFrameShown(elementData)) then
		DebounceKeybindFrame:Hide();
	end

	DebounceFrame.dataProvider:Remove(elementData);
	for i, elem in DebounceFrame.dataProvider:Enumerate() do
		elem.index = i;
	end

	local layer = DebouncePrivate.GetProfileLayer(elementData.layer);
	layer:Remove(elementData.action);
	DebouncePrivate.UpdateBindings();
end

local ShowDeleteConfirmationPopup, HideDeleteConfirmationPopup;
do
	local _deletePopupData;
	function ShowDeleteConfirmationPopup(elementData)
		HideDeleteConfirmationPopup();

		local function onAccept()
			DeleteElementData(elementData);
		end

		local name = NameAndIconFromElementData(elementData);
		_deletePopupData = {
			text = LLL["DELETE_CONFIRM_MESSAGE"],
			text_arg1 = name or LLL["UNNAMED_ACTION"],
			callback = onAccept,
			acceptText = YES,
			cancelText = NO,
			showAlert = true,
			referenceKey = "DebounceDeleteConfirmation",
		};

		StaticPopup_ShowCustomGenericConfirmation(_deletePopupData);
		DebounceFrame:UpdateButtons();
	end

	function HideDeleteConfirmationPopup()
		if (_deletePopupData) then
			StaticPopup_Hide("GENERIC_CONFIRMATION", _deletePopupData);
			_deletePopupData = nil;
		end
	end
end

local ShowSaveOrDiscardPopup, HideSaveOrDiscardPopup, IsHideOrDiscardPopupShown;
do
	local _saveOrDiscardData;

	function ShowSaveOrDiscardPopup(elementData)
		HideSaveOrDiscardPopup();

		local function onAccept()
			DebounceMacroFrame:OkayButton_OnClick();
		end

		local function onCancel()
			DebounceMacroFrame:CancelButton_OnClick();
		end

		local name = NameAndIconFromElementData(elementData);
		_saveOrDiscardData = {
			text = LLL["SAVE_OR_DISCARD_MESSAGE"],
			text_arg1 = name or LLL["UNNAMED_ACTION"],
			callback = onAccept,
			cancelCallback = onCancel,
			acceptText = LLL["SAVE"],
			cancelText = LLL["DISCARD"],
			showAlert = true,
			referenceKey = "DebounceSaveOrDiscard",
		};

		StaticPopup_ShowCustomGenericConfirmation(_saveOrDiscardData);
	end

	function HideSaveOrDiscardPopup()
		if (_saveOrDiscardData) then
			StaticPopup_Hide("GENERIC_CONFIRMATION", _saveOrDiscardData);
			_saveOrDiscardData = nil;
			DebounceFrame:UpdateButtons();
		end
	end

	function IsHideOrDiscardPopupShown()
		return StaticPopup_FindVisible("GENERIC_CONFIRMATION", _saveOrDiscardData) ~= nil;
	end
end

local ShowInputBox, HideInputBox;
do
	local _shownInputBoxes = {};

	function ShowInputBox(data)
		_shownInputBoxes[data] = true;
		StaticPopup_ShowCustomGenericInputBox(data);
		if (data.currentValue) then
			local popup = StaticPopup_FindVisible("GENERIC_INPUT_BOX", data);
			if (popup) then
				popup.editBox:SetText(data.currentValue);
			end
		end
	end

	function HideInputBox(data)
		_shownInputBoxes[data] = nil;
		StaticPopup_Hide("GENERIC_INPUT_BOX", data);
	end

	function HideAllInputBoxes()
		for data in pairs(_shownInputBoxes) do
			StaticPopup_Hide("GENERIC_INPUT_BOX", data);
		end
		wipe(_shownInputBoxes);
	end
end

local function MoveAction(elementData, destLayerID, copying)
	local fromLayerID = elementData.layer;
	assert(fromLayerID == GetLayerID());

	local action = elementData.action;

	if (fromLayerID == destLayerID) then
		assert(copying, "cannot move to same layer");
	else
		if (not copying) then
			local fromLayer = DebouncePrivate.GetProfileLayer(fromLayerID);
			fromLayer:Remove(action);
			DebounceFrame.dataProvider:Remove(elementData);
		end
	end

	local insertIndex;
	if (copying and fromLayerID == destLayerID) then
		insertIndex = elementData.index + 1;
	end

	action = CopyTable(elementData.action);
	local destLayer = DebouncePrivate.GetProfileLayer(destLayerID);
	destLayer:Insert(action, insertIndex, not copying);

	if (fromLayerID == destLayerID) then
		elementData = { action = action, layer = destLayerID, index = insertIndex - 0.5 };
		DebounceFrame.dataProvider:Insert(elementData);
		for i, elemData in DebounceFrame.dataProvider:Enumerate() do
			elemData.index = i;
		end
		DebounceFrame.ScrollBox:ScrollToElementData(elementData);
	end

	DebouncePrivate.UpdateBindings();
end

local ShowLineTooltip;
do
	local _lines = {};
	local GameTooltip = GameTooltip;
	local LEFT_OFFSET = 10;
	local action;

	local function addErrorLine(message, wrap, leftOffset)
		GameTooltip_AddErrorLine(GameTooltip, message, wrap or false, leftOffset or LEFT_OFFSET);
	end

	local function addLabelLine(label, hasError)
		GameTooltip_AddBlankLineToTooltip(GameTooltip);
		if (hasError) then
			GameTooltip_AddErrorLine(GameTooltip, format(LLL["LINE_TOOLTIP_CONDITION_LABEL"], label));
		else
			GameTooltip_AddHighlightLine(GameTooltip, format(LLL["LINE_TOOLTIP_CONDITION_LABEL"], label));
		end
	end

	local function addValueLine(value, error, wrap, leftOffset)
		if (error) then
			GameTooltip_AddErrorLine(GameTooltip, value, wrap or false, leftOffset or LEFT_OFFSET);
		else
			GameTooltip_AddNormalLine(GameTooltip, value, wrap or false, leftOffset or LEFT_OFFSET);
		end
		if (type(error) == "string") then
			GameTooltip_AddErrorLine(GameTooltip, "(" .. LLL["BINDING_ERROR_" .. error] .. ")", wrap or false, leftOffset or LEFT_OFFSET);
		end
	end

	local function addValueLines(lines, error, wrap, leftOffset)
		local fn = error and GameTooltip_AddErrorLine or GameTooltip_AddNormalLine;
		for i = 1, #lines do
			fn(GameTooltip, lines[i], wrap or false, leftOffset or LEFT_OFFSET);
		end
		if (type(error) == "string") then
			GameTooltip_AddErrorLine(GameTooltip, "(" .. LLL["BINDING_ERROR_" .. error] .. ")", wrap or false, leftOffset or LEFT_OFFSET);
		end
	end

	function ShowLineTooltip(owner, anchor, elementData, isOverview)
		GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT");
		---@diagnostic disable-next-line: redundant-parameter
		GameTooltip:SetMinimumWidth(140, true);

		action = elementData.action;
		action._dirty = true;

		local isInactive = not isOverview and DebouncePrivate.IsInactiveAction(action);
		local hasIssues = GetBindingIssue(action) ~= nil;

		local name = ColoredNameAndIconFromElementData(elementData);
		GameTooltip_SetTitle(GameTooltip, name);

		do
			addLabelLine(LLL["KEY"]);

			if (action.key) then
				local keyText = GetBindingText(action.key);
				local error;
				if (isInactive) then
					keyText = INACTIVE_COLOR:WrapTextInColorCode(keyText);
				else
					error = hasIssues and GetBindingIssue(action, "key") or nil;
				end
				addValueLine(keyText, error);
			else
				addValueLine(INACTIVE_COLOR:WrapTextInColorCode(LLL["NOT_BOUND"]));
			end
		end

		if (action.unit ~= nil) then
			addLabelLine(LLL["TARGET_UNIT"]);
			local error = hasIssues and GetBindingIssue(action, "unit");
			local unitStr = UNIT_INFO[action.unit] and UNIT_INFO[action.unit].name or LLL[action.unit];
			addValueLine(unitStr, error);
		end

		if (action.hover ~= nil) then
			addLabelLine(LLL["CONDITION_HOVER"]);
			local error = hasIssues and GetBindingIssue(action, "hover");
			if (action.hover) then
				wipe(_lines);
				local reactions = action.reactions or Constants.REACTION_ALL;
				local frameTypes = action.frameTypes or Constants.FRAMETYPE_ALL;

				local s;
				if (reactions == Constants.REACTION_ALL) then
					s = LLL["ALL"];
				elseif (reactions == 0) then
					s = LLL["NOT_SELECTED"];
				else
					s = "";
					for i = 1, #UNIT_FRAME_REACTIONS do
						local flag = Constants["REACTION_" .. UNIT_FRAME_REACTIONS[i]];
						if (bit.band(reactions, flag) == flag) then
							if (s ~= "") then
								s = s .. ", ";
							end
							s = s .. LLL["REACTION_" .. UNIT_FRAME_REACTIONS[i]];
						end
					end
				end
				s = format("|cnWHITE_FONT_COLOR:%s:|r %s", LLL["CONDITION_REACTIONS"], s);
				addValueLine(s, hasIssues and GetBindingIssue(action, "reactions") and true or false, true);

				s = nil;
				if (frameTypes == Constants.FRAMETYPE_ALL) then
					s = LLL["ALL"];
				elseif (frameTypes == 0) then
					s = LLL["NOT_SELECTED"];
				else
					s = "";
					for i = 1, #UNIT_FRAME_TYPES do
						local flag = Constants["FRAMETYPE_" .. UNIT_FRAME_TYPES[i]];
						if (bit.band(frameTypes, flag) == flag) then
							if (s ~= "") then
								s = s .. ", ";
							end
							s = s .. LLL["FRAMETYPE_" .. UNIT_FRAME_TYPES[i]];
						end
					end
				end
				s = format("|cnWHITE_FONT_COLOR:%s:|r %s", LLL["CONDITION_FRAMETYPES"], s);
				addValueLine(s, hasIssues and GetBindingIssue(action, "frameTypes") and true or false, true);

				if (action.ignoreHoverUnit) then
					addValueLine(LLL["IGNORE_HOVER_UNIT"]);
				end
			else
				addValueLine(LLL["CONDITION_HOVER_NO"], error);
			end
			if (error) then
				addErrorLine(LLL["BINDING_ERROR_" .. error]);
			end
		end

		if (action.checkedUnits) then
			local first = true;
			for checkedUnit, value in pairs(action.checkedUnits) do
				if (checkedUnit ~= "@" or (action.unit and action.unit ~= "none")) then
					if (first) then
						addLabelLine(LLL["CONDITION_UNITS"]);
						first = false;
					end

					local error = hasIssues and GetBindingIssue(action, "checkedUnits");
					local unitStr;
					if (checkedUnit == "@") then
						unitStr = format(LLL["SELECTED_TARGET_UNIT"], UNIT_INFO[action.unit].name);
					else
						unitStr = UNIT_INFO[checkedUnit].name;
					end
					--addValueLine(unitStr);
					if (value == true) then
						addValueLine(unitStr .. " - " .. LLL["CONDITION_UNIT_EXISTS"], error);
					elseif (value == "help") then
						addValueLine(unitStr .. " - " .. LLL["CONDITION_UNIT_HELP"], error);
					elseif (value == "harm") then
						addValueLine(unitStr .. " - " .. LLL["CONDITION_UNIT_HARM"], error);
					else
						addValueLine(unitStr .. " - " .. LLL["CONDITION_UNIT_DOES_NOT_EXIST"], error);
					end
				end
			end
		end

		if (action.groups ~= nil) then
			addLabelLine(LLL["CONDITION_GROUP"]);

			if (action.groups == 0) then
				addValueLine(LLL["BINDING_ERROR_GROUPS_NONE_SELECTED"], true);
			else
				wipe(_lines);
				for _, groupType in ipairs({ "NONE", "PARTY", "RAID" }) do
					local flag = Constants["GROUP_" .. groupType];
					if (bit.band(action.groups, flag) == flag) then
						tinsert(_lines, LLL["GROUP_" .. groupType]);
					end
				end
				local error = hasIssues and GetBindingIssue(action, "groups");
				addValueLines(_lines, error);
			end
		end

		if (action.combat ~= nil) then
			addLabelLine(LLL["CONDITION_COMBAT"]);
			local error = hasIssues and GetBindingIssue(action, "combat");
			addValueLine(action.combat == true and LLL["CONDITION_COMBAT_YES"] or LLL["CONDITION_COMBAT_NO"], error);
		end

		if (action.stealth ~= nil) then
			local error = hasIssues and GetBindingIssue(action, "stealth");
			addLabelLine(LLL["CONDITION_STEALTH"]);
			addValueLine(action.stealth == true and LLL["CONDITION_STEALTH_YES"] or LLL["CONDITION_STEALTH_NO"], error);
		end

		if (action.known ~= nil) then
			local error = hasIssues and GetBindingIssue(action, "known");
			addLabelLine(LLL["CONDITION_KNOWN"]);
			if (action.known == true) then
				addValueLine(LLL["CONDITION_KNOWN_YES"], error);
			else
				addValueLine(LLL["CONDITION_KNOWN_UNKNOWN"], error);
			end
		end

		if (action.forms ~= nil) then
			addLabelLine(LLL["CONDITION_SHAPESHIFT"]);
			if (action.forms == 0) then
				addValueLine(LLL["BINDING_ERROR_FORMS_NONE_SELECTED"], true);
			else
				wipe(_lines);
				local error = hasIssues and GetBindingIssue(action, "forms");
				for i = 0, 10 do
					local flag = 2 ^ i;
					if (bit.band(action.forms, flag) ~= 0) then
						if (i == 0) then
							tinsert(_lines, format("[form:%d] (%s)", i, LLL["NO_SHAPESHIFT"]));
						else
							local _, _, _, spellID = GetShapeshiftFormInfo(i);
							local spellName = spellID and GetSpellNameAndIconID(spellID);
							if (spellName) then
								tinsert(_lines, format("[form:%d] (%s)", i, spellName));
							else
								tinsert(_lines, format("[form:%d]", i));
							end
						end
					end
				end
				addValueLines(_lines, error);
			end
		end

		if (action.bonusbars ~= nil) then
			addLabelLine(LLL["CONDITION_BONUSBAR"]);
			if (action.bonusbars == 0) then
				addValueLine(LLL["BINDING_ERROR_BONUSBARS_NONE_SELECTED"], true);
			else
				wipe(_lines);
				local error = hasIssues and GetBindingIssue(action, "bonusbars");
				for i = 0, Constants.MAX_BONUS_ACTIONBAR_OFFSET do
					local flag = 2 ^ i;
					if (bit.band(action.bonusbars, flag) ~= 0) then
						local label = GetActionBarTypeLabel(i);
						if (label) then
							tinsert(_lines, label);
						end
					end
				end
				addValueLines(_lines, error);
			end
		end

		if (action.specialbar ~= nil) then
			local error = hasIssues and GetBindingIssue(action, "specialbar");
			addLabelLine(LLL["CONDITION_SPECIALBAR"]);
			addValueLine(action.specialbar == true and LLL["CONDITION_SPECIALBAR_YES"] or LLL["CONDITION_SPECIALBAR_NO"], error);
		end

		if (action.extrabar ~= nil) then
			local error = hasIssues and GetBindingIssue(action, "extrabar");
			addLabelLine(LLL["CONDITION_EXTRABAR"]);
			addValueLine(action.extrabar == true and LLL["CONDITION_EXTRABAR_YES"] or LLL["CONDITION_EXTRABAR_NO"], error);
		end

		if (action.pet ~= nil) then
			local error = hasIssues and GetBindingIssue(action, "pet");
			addLabelLine(LLL["CONDITION_PET"]);
			addValueLine(action.pet == true and LLL["CONDITION_PET_YES"] or LLL["CONDITION_PET_NO"], error);
		end

		if (action.petbattle ~= nil) then
			local error = hasIssues and GetBindingIssue(action, "petbattle");
			addLabelLine(LLL["CONDITION_PETBATTLE"]);
			addValueLine(action.petbattle == true and LLL["CONDITION_PETBATTLE_YES"] or LLL["CONDITION_PETBATTLE_NO"], error);
		end

		for stateIndex = 1, Constants.MAX_NUM_CUSTOM_STATES do
			local state = "$state" .. stateIndex;
			if (action[state] ~= nil) then
				addLabelLine(format(LLL["CUSTOM_STATE_NUM"], stateIndex));
				addValueLine(action[state] == true and LLL["CONDITION_CUSTOM_STATE_YES"] or LLL["CONDITION_CUSTOM_STATE_NO"]);
			end
		end

		if (action.priority and action.priority ~= Constants.DEFAULT_PRIORITY) then
			addLabelLine(LLL["PRIORITY"]);
			addValueLine(LLL["PRIORITY" .. action.priority]);
		end

		if (not isOverview) then
			GameTooltip_AddBlankLineToTooltip(GameTooltip);
			GameTooltip_AddInstructionLine(GameTooltip, LLL["LINE_TOOLTIP_INSTRUCTION_MESSAGE1"]);
			GameTooltip_AddInstructionLine(GameTooltip, LLL["LINE_TOOLTIP_INSTRUCTION_MESSAGE2"]);
			GameTooltip_AddInstructionLine(GameTooltip, LLL["LINE_TOOLTIP_INSTRUCTION_MESSAGE3"]);
		else
			GameTooltip_AddBlankLineToTooltip(GameTooltip);
			GameTooltip_AddInstructionLine(GameTooltip, LLL["OVERVIEW_LINE_TOOLTIP_INSTRUCTION_MESSAGE1"]);
		end

		GameTooltip:Show();
	end
end

local function DoesActionMatchFilter(action)
	if (not DebounceFrame.SearchBox.filterText) then
		return true;
	end

	local filters = DebounceFrame.SearchBox.filters;
	if (not filters or #filters == 0) then
		return true;
	end

	local name, icon = NameAndIconFromElementData(action);
	for _, filterText in ipairs(filters) do
		local match;
		if (name and strfind(name:lower(), filterText, 1, true)) then
			match = true;
		end

		if (not match) then
			if (strfind(action.type:lower(), filterText, 1, true)) then
				match = true;
			end
		end

		if (not match) then
			if (action.type == Constants.MACROTEXT) then
				if (action.value and strfind(action.value:lower(), filterText, 1, true)) then
					match = true;
				end
			end
		end

		if (not match) then
			if (filterText:sub(1, 1) == "@") then
				local unit = filterText:sub(2);
				if (action.unit and strfind(action.unit, unit, 1, true)) then
					match = true;
				elseif (action.checkedUnits) then
					for checkedUnit, _ in pairs(action.checkedUnits) do
						if (strfind(checkedUnit, unit, 1, true)) then
							match = true;
						end
					end
				end
			end
		end

		if (not match) then
			if (action.key) then
				local keyText = GetBindingText(action.key);
				if (strfind(keyText:lower(), filterText, 1, true)) then
					match = true;
				end
			end
		end

		if (not match) then
			return false;
		end
	end

	return true;
end


DebounceLineMixin = {};

function DebounceLineMixin:Init(elementData)
	self:RegisterForClicks("AnyUp");
	self:RegisterForDrag("LeftButton");
	--self:EnableMouseWheel(true);
	self:Update();
end

function DebounceLineMixin:Update()
	local elementData = self:GetElementData();
	local action = elementData.action;
	action._dirty = true;

	local isInactive = DebouncePrivate.IsInactiveAction(action);
	local issue = not isInactive and GetBindingIssue(action) or nil;

	local name, icon = ColoredNameAndIconFromElementData(elementData);
	if (DebouncePrivate.DEBUG) then
		name = format("%s (%d)", name, elementData.index)
	end
	self.Name:SetText(name);

	if (luatype(icon) == "string" and icon:sub(1, 2) == "A:") then
		self.Icon:SetAtlas(icon:sub(3));
	else
		self.Icon:SetTexture(icon);
	end

	if (action.key) then
		local s = GetBindingText(action.key);
		local color;
		if (isInactive) then
			color = INACTIVE_COLOR;
		elseif (issue and GetBindingIssue(action, "key")) then
			color = ERROR_COLOR;
		end
		if (color) then
			s = color:WrapTextInColorCode(s);
		end
		self.BindingText:SetText(s);
	else
		self.BindingText:SetText("");
	end

	if (action.unit) then
		local s = format("@%s", UNIT_INFO[action.unit] and UNIT_INFO[action.unit].name or LLL[action.unit]);
		local color;
		if (isInactive) then
			color = INACTIVE_COLOR;
		elseif (issue and GetBindingIssue(action, "unit")) then
			color = ERROR_COLOR;
		end
		if (color) then
			s = color:WrapTextInColorCode(s);
		end
		self.InfoText:SetText(s);
	else
		self.InfoText:SetText("");
	end

	if (DebouncePrivate.IsConditionalAction(action)) then
		if (isInactive) then
			self.QuestionMark:SetVertexColor(INACTIVE_COLOR:GetRGBA());
			self.QuestionMark:SetDesaturated(true);
		elseif (issue and (GetBindingIssue(action, "hover")
				or GetBindingIssue(action, "groups")
				or GetBindingIssue(action, "forms")
				or GetBindingIssue(action, "bonusbars")
				or GetBindingIssue(action, "specialbar")
				or GetBindingIssue(action, "combat")
				or GetBindingIssue(action, "known")
				or GetBindingIssue(action, "stealth")
				or GetBindingIssue(action, "pet")
				or GetBindingIssue(action, "petbattle"))
			) then
			self.QuestionMark:SetVertexColor(ERROR_COLOR:GetRGBA());
			self.QuestionMark:SetDesaturated(false);
		else
			self.QuestionMark:SetVertexColor(1, 1, 1);
			self.QuestionMark:SetDesaturated(false);
		end
		self.QuestionMark:Show();
	else
		self.QuestionMark:Hide();
	end

	local professionQuality = action.type == Constants.ITEM and C_TradeSkillUI.GetItemReagentQualityByItemInfo(action.value);
	if (professionQuality) then
		if (not self.ProfessionQualityOverlay) then
			self.ProfessionQualityOverlay = self:CreateTexture(nil, "Overlay");
			self.ProfessionQualityOverlay:SetPoint("TOPLEFT", self.Icon, "TOPLEFT", -3, 2);
			self.ProfessionQualityOverlay:SetDrawLayer("OVERLAY", 7);
		end
		local atlas = ("Professions-Icon-Quality-Tier%d-Inv"):format(professionQuality);
		self.ProfessionQualityOverlay:SetAtlas(atlas, TextureKitConstants.UseAtlasSize);
		self.ProfessionQualityOverlay:Show();
	elseif (self.ProfessionQualityOverlay) then
		self.ProfessionQualityOverlay:Hide();
	end

	if (elementData == _placeholder or IsEditingMacro(elementData) or IsEditDropdownShown(elementData) or IsKeybindFrameShown(elementData)) then
		self.SelectedHighlight:Show();
	elseif (DebounceOverviewFrame:IsShown() and DebounceOverviewFrame.hoveredAction == action) then
		self.SelectedHighlight:Show();
	elseif (IsEditingMacro() or IsEditDropdownShown() or IsKeybindFrameShown()) then
		self.SelectedHighlight:Hide();
	else
		self.Icon:SetDesaturated(false);
		if (IsDraggingElement(elementData)) then
			self.SelectedHighlight:Show();
		else
			self.SelectedHighlight:Hide();
		end
	end

	if (GameTooltip:GetOwner() == self) then
		self:OnEnter();
	end

	if (DoesActionMatchFilter(action)) then
		self:SetAlpha(1);
	else
		self:SetAlpha(FILTERED_ALPHA);
	end
end

function DebounceLineMixin:OnEnter()
	ShowLineTooltip(self, "ANCHOR_RIGHT", self:GetElementData(), false);
end

function DebounceLineMixin:OnLeave()
	---@diagnostic disable-next-line: redundant-parameter
	GameTooltip:SetMinimumWidth(0, false);
	GameTooltip:Hide();
end

function DebounceLineMixin:OnClick(buttonName)
	if (buttonName == "LeftButton" and GetActionTypeAndValueFromCursorInfo()) then
		DebounceFrame.ScrollBox:OnClick();
		return;
	end

	local elementData = self:GetElementData();
	if (IsDraggingElement(elementData) and buttonName == "LeftButton") then
		DebounceFrame:OnReceiveDrag();
		return;
	end

	if (buttonName == "RightButton") then
		if (false and DebouncePrivate.DEBUG and IsControlKeyDown()) then
			if (IsEditingMacro(elementData)) then
				return;
			end
			if (IsKeybindFrameShown(elementData)) then
				return;
			end
			if (IsEditDropdownShown(elementData)) then
				securecall("CloseMenus");
			end
			if (IsAltKeyDown() or IsShiftKeyDown()) then
				DeleteElementData(elementData);
			else
				ShowDeleteConfirmationPopup(elementData);
			end
		else
			if (IsControlKeyDown() and elementData.action.type == "macrotext") then
				if (IsEditingMacro(elementData)) then
					-- already editing this item
					return;
				end

				if (not TryCloseAnyDialog()) then
					return;
				end

				DebounceMacroFrame:ShowEdit(elementData);
				return;
			end

			if (not TryCloseAnyDialog()) then
				return;
			end

			DebounceFrame:ShowEditDropdown(self);
		end
		return;
	end

	if (IsEditingMacro()) then
		return;
	end

	if (IsKeybindFrameShown(elementData)) then
		return;
	end

	if (DebounceKeybindFrame:HasUnsavedChanges()) then
		DebouncePrivate.DisplayMessage(LLL["CONFIRM_CURRENT_CHANGE_FIRST"]);
		return;
	end

	DebounceKeybindFrame:Open(elementData);
end

function DebounceLineMixin:OnDragStart()
	if (not TryCloseAnyDialog()) then
		return;
	end

	DebounceFrame:StartDragging(self:GetElementData());
end

function DebounceLineMixin:OnDragStop()
end

function DebounceLineMixin:OnReceiveDrag()
	DebounceFrame:OnReceiveDrag();
end

DebounceTabMixin = {};

function DebounceTabMixin:OnLoad()
end

function DebounceTabMixin:OnClick()
	if (not TryCloseAnyDialog()) then
		return;
	end

	local id = self:GetID();
	if (_selectedTab ~= id) then
		DebounceKeybindFrame:Hide();
		DebounceIconSelectorFrame:Hide();
		DebounceMacroFrame:Hide();

		PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN);
		self:GetParent():SetTab(id);
	end
end

function DebounceTabMixin:OnEnter()
	local id = self:GetID();
	local text = GetTabLabel(id);
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(text);

	-- TODO add instruction line. "you can drop here to add/move into this tab"

	GameTooltip:Show();
end

function DebounceTabMixin:OnLeave()
	GameTooltip:Hide();
end

function DebounceTabMixin:OnReceiveDrag()
	local layerID = GetLayerID(self:GetID(), _selectedSideTab);
	DebounceFrame:OnReceiveDrag(layerID);
end

function DebounceTabMixin:IsActive()
	return _selectedTab == self:GetID();
end

DebounceSideTabMixin = {};

function DebounceSideTabMixin:OnClick()
	if (not TryCloseAnyDialog()) then
		return;
	end

	local id = self:GetID();
	if (_selectedSideTab ~= id) then
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN);

		_selectedSideTab = id;

		DebounceFrame:UpdateSideTabs();
		DebounceFrame:Refresh();
	else
		self:SetChecked(true);
	end
end

function DebounceSideTabMixin:OnEnter()
	local id = self:GetID();
	local text = GetSideTabaLabel(id);
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if (self.isOffSpec) then
		GameTooltip:SetText(format(LLL["INACTIVE_SPEC_LABEL"], text));
	else
		GameTooltip:SetText(text);
	end

	-- TODO add instruction line. "you can drop here to add/move into this tab"

	GameTooltip:Show();
end

function DebounceSideTabMixin:OnLeave()
	GameTooltip:Hide();
end

function DebounceSideTabMixin:OnDisable()
	self:GetNormalTexture():SetDesaturated(true);
end

function DebounceSideTabMixin:OnEnable()
	self:GetNormalTexture():SetDesaturated(self.isOffSpec);
end

function DebounceSideTabMixin:OnReceiveDrag()
	local layerID = GetLayerID(_selectedTab, self:GetID());
	DebounceFrame:OnReceiveDrag(layerID);
end

function DebounceSideTabMixin:IsActive()
	return _selectedSideTab == self:GetID();
end

DebouncePortraitMixin = {};

function DebouncePortraitMixin:SetSelectedState(isSelected)
	self.Frame:SetDesaturated(not isSelected);
	self.UnselectedFrame:SetShown(not isSelected);
end

function DebouncePortraitMixin:OnLoad()
	self:SetSelectedState(false);
	self.Portrait:SetTexture(self.PortraitTexture);
	if (self.TooltipTitle) then
		self.TooltipTitle = rawget(LLL, self.TooltipTitle) or _G[self.TooltipTitle] or self.TooltipTitle;
		self.TooltipText = rawget(LLL, self.TooltipText);
	end
	if (self.MenuFunc) then
		self:SetupMenu(DebounceUI[self.MenuFunc]);
	end
end

function DebouncePortraitMixin:OnMenuOpened(menu)
	DropdownButtonMixin.OnMenuOpened(self, menu);
	self:SetSelectedState(true);
end

function DebouncePortraitMixin:OnMenuClosed(menu)
	DropdownButtonMixin.OnMenuOpened(self, menu);
	self:SetSelectedState(false);
end

function DebouncePortraitMixin:OnShow()
	if (not self.initialized) then
		self:OnLoad();
		self.initialized = true;
	end
end

function DebouncePortraitMixin:OnEnter()
	if (self.TooltipTitle) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip_SetTitle(GameTooltip, self.TooltipTitle);
		if (self.TooltipText) then
			GameTooltip_AddNormalLine(GameTooltip, self.TooltipText);
		end
		GameTooltip:Show();
	end
end

function DebouncePortraitMixin:OnLeave()
	GameTooltip:Hide();
end

function DebouncePortraitMixin:OnEnable()
	self.Portrait:SetDesaturated(false);
end

function DebouncePortraitMixin:OnDisable()
	self.Portrait:SetDesaturated(true);
end

DebounceFrameMixin = {};

function DebounceFrameMixin:UpdateTabs()
	for i = 1, #self.Tabs do
		local tab = self.Tabs[i];
		tab:SetEnabled(_placeholder == nil);
	end
end

function DebounceFrameMixin:InitializeSideTabs()
	self.SideTabs = self.SideTabsFrame.Tabs;
	for i, tab in ipairs(self.SideTabs) do
		local name, icon;
		if (i == 1) then
			name, icon = GetSpellTabNameAndIcon(1);
			tab.spec = nil;
		elseif (i == 2) then
			name, icon = GetSpellTabNameAndIcon(2);
			tab.spec = 0;
		else
			local spec = i - 2;
			tab.spec = spec;
			if (spec > NUM_SPECS) then
				tab.notUsed = true;
				tab:Hide();
				break;
			end
			_, name, _, icon = GetSpecializationInfo(spec);
		end
		tab:SetNormalTexture(icon);
		tab.tooltip = name;
		tab:Show();
	end
end

function DebounceFrameMixin:UpdateSideTabs()
	local currentSpec = GetSpecialization();
	self.currentSpec = currentSpec;

	local tabOrders = { 1, 2 };
	if (currentSpec and currentSpec <= NUM_SPECS) then
		tinsert(tabOrders, currentSpec + 2);
	end

	for i = 1, NUM_SPECS do
		if (i ~= currentSpec) then
			tinsert(tabOrders, i + 2);
		end
	end

	local prevTab;
	for i = 1, #tabOrders do
		local tabID = tabOrders[i];
		local tab = self.SideTabs[tabID];

		if (tabID == 2 and _selectedTab == 2) then
			tab:Hide();
		else
			tab.isOffSpec = tabID > 2 and currentSpec ~= (tabID - 2);
			tab:GetNormalTexture():SetDesaturated(tab.isOffSpec);
			tab:SetChecked(_selectedSideTab == tabID);

			if (prevTab) then
				if (tab.isOffSpec and not prevTab.isOffSpec) then
					tab:SetPoint("TOP", prevTab, "BOTTOM", 0, -40);
				else
					tab:SetPoint("TOP", prevTab, "BOTTOM", 0, -17);
				end
			end

			tab:Show();
			prevTab = tab;
		end
	end
end

function DebounceFrameMixin:UpdateEmptyText()
	if (self.dataProvider:GetSize() == 0) then
		-- if (self.SearchBox.filters) then
		-- 	self.ScrollBox.EmptyText:SetText(LLL["NO_ACTIONS_MATCHING_FILTER"]);
		-- else
		-- 	self.ScrollBox.EmptyText:SetText(LLL["NO_ACTIONS_IN_THIS_TAB"]);
		-- end
		self.ScrollBox.EmptyText:SetText(LLL["NO_ACTIONS_IN_THIS_TAB"]);
		self.ScrollBox.EmptyText:Show();
	else
		self.ScrollBox.EmptyText:Hide();
	end
end

function DebounceFrameMixin:UpdateActionCounts()
	for tabId, tab in ipairs(self.Tabs) do
		local sum = 0;

		for sideTabId, sideTab in ipairs(self.SideTabs) do
			if (sideTab:IsShown()) then
				local layerId = GetLayerID(tabId, sideTabId);
				local layer = DebouncePrivate.GetProfileLayer(layerId);
				local count;
				if (self.SearchBox.filters) then
					count = 0;
					for i, action in layer:Enumerate() do
						if (DoesActionMatchFilter(action)) then
							count = count + 1;
						end
					end
				else
					count = layer:GetNumActions();
				end
				if (tabId == _selectedTab) then
					sideTab.Count:SetText(count);
					if (count > 0 and self.SearchBox.filters) then
						sideTab.Count:SetTextColor(GREEN_FONT_COLOR:GetRGB());
					else
						sideTab.Count:SetTextColor(1, 1, 1);
					end
				end
				sum = sum + count;
			end
		end

		local label;
		if (sum > 0 and self.SearchBox.filters) then
			label = GetTabLabel(tabId) .. " |cnGREEN_FONT_COLOR:(" .. sum .. ")|r";
		else
			label = GetTabLabel(tabId) .. " (" .. sum .. ")";
		end

		tab:SetText(label);
		PanelTemplates_TabResize(tab, 0)
	end
end

function DebounceFrameMixin:GetPlaceholder()
	return _placeholder;
end

do
	local SCROLL_DELAY = 0.1;
	local ELEMENT_PADDING = 40;
	local _lastScrollTime = 0;
	local _lastCursorY = 0;

	function DebounceFrameMixin:UpdatePlaceholderPosition(forceNow)
		local _, cursorY = GetScaledCursorPosition();
		if (forceNow or (GetTime() - _lastScrollTime) > SCROLL_DELAY or abs(cursorY - _lastCursorY) > ELEMENT_PADDING) then
			_lastCursorY = cursorY;
			local frames = self.ScrollBox:GetFrames();
			local pos = 1;
			for i = 1, #frames do
				local frame = frames[i];
				if (frame:IsVisible()) then
					local frameElementData = frame:GetElementData();
					local _, b, _, h = frame:GetRect();
					if (cursorY >= b) then
						if (frameElementData == _placeholder) then
							return;
						end

						if (frameElementData ~= _placeholder) then
							if (_placeholder.sortIndex < frameElementData.index) then
								pos = frameElementData.index + 0.5;
							else
								pos = frameElementData.index - 0.5;
							end
							break;
						end
					else
						if (frameElementData ~= _placeholder) then
							pos = frameElementData.index + 0.5;
						end
					end
				end
			end

			if (not _placeholder.sortIndex or _placeholder.sortIndex ~= pos) then
				_placeholder.sortIndex = pos;
				self.dataProvider:Sort();

				-- i dont remember what these are for, but they seem to be working fine, so i'll leave them for now
				local dataIndex = self.ScrollBox:FindIndex(_placeholder);
				local elementExtent = self.ScrollBox:GetElementExtent(dataIndex);
				local elementOffset = self.ScrollBox:GetExtentUntil(dataIndex);
				local visibleExtent = self.ScrollBox:GetVisibleExtent();
				local scrollOffset = self.ScrollBox:GetDerivedScrollOffset();

				local offsetInView = elementOffset - scrollOffset;
				if (offsetInView + elementExtent + ELEMENT_PADDING > visibleExtent) then
					self.ScrollBox:ScrollToElementData(_placeholder, ScrollBoxConstants.AlignEnd, -ELEMENT_PADDING, true);
					_lastScrollTime = GetTime();
				elseif (offsetInView < ELEMENT_PADDING) then
					self.ScrollBox:ScrollToElementData(_placeholder, ScrollBoxConstants.AlignBegin, ELEMENT_PADDING, true);
					_lastScrollTime = GetTime();
				end
			end
		end
	end
end

function DebounceFrameMixin:OnUpdate(elapsed)
	if (not (IsDraggingElement() or GetActionTypeAndValueFromCursorInfo())) then
		return;
	end

	local scrollBox = self.ScrollBox;
	local isMouseOverScrollBox = scrollBox:IsMouseOver();
	local draggingElement = GetDraggingElement();
	local placeholderCreated;

	if (isMouseOverScrollBox) then
		if (not _placeholder) then
			if (draggingElement) then
				_placeholder = draggingElement;
				_placeholder.sortIndex = _placeholder.sortIndex or _placeholder.index;
			else
				local type, value = GetActionTypeAndValueFromCursorInfo();
				_placeholder = { action = { type = type, value = value }, sortIndex = scrollBox:GetDataIndexBegin() };
			end
			if (not self.dataProvider:FindIndex(_placeholder)) then
				self.dataProvider:Insert(_placeholder);
				self:Update();
			end
			placeholderCreated = true;
		end
	else
		if (_placeholder) then
			if (_placeholder.layer == GetLayerID()) then
				if (not self.dataProvider:FindIndex(_placeholder)) then
					self.dataProvider:Insert(_placeholder);
					self:Update();
				end
			else
				self.dataProvider:Remove(_placeholder);
				_placeholder.sortIndex = nil;
				_placeholder = nil;
				self:Update();
			end
		end
	end

	if (_placeholder and isMouseOverScrollBox) then
		self:UpdatePlaceholderPosition(placeholderCreated);
	end

	if (_placeholder and isMouseOverScrollBox) then
		self:UpdatePlaceholderPosition();
	end
end

local function ScrollBox_OnClick(self)
	if (_placeholder) then
		self:OnReceiveDrag();
	end
end

local function ScrollBox_OnReceiveDrag(self)
	DebounceFrame:OnReceiveDrag();
end

function DebounceFrameMixin:InitializeScrollBox()
	local padding = 7;
	local bottomPadding = 40;
	local spacing = 4;
	local view = CreateScrollBoxListLinearView(padding, bottomPadding, padding, padding, spacing);

	view:SetElementInitializer("DebounceLineTemplate", function(button, elementData)
		button:Init(elementData);
	end);

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);

	self.ScrollBox.OnClick = ScrollBox_OnClick;
	self.ScrollBox.OnReceiveDrag = ScrollBox_OnReceiveDrag;

	self.ScrollBox:RegisterForClicks("AnyUp");
	self.ScrollBox:SetScript("OnClick", self.ScrollBox.OnClick);
	self.ScrollBox:SetScript("OnReceiveDrag", self.ScrollBox.OnReceiveDrag);
end

function DebounceFrameMixin:InitializeButtons()
	self.OverviewPortrait:SetScript("OnClick", function()
		DebounceOverviewFrame:Toggle();
	end)
end

function DebounceFrameMixin:OnLoad()
	self.initialized = true;

	self:SetPortraitToAsset(133015);
	self:SetPropagateKeyboardInput(true);

	for i, tab in ipairs(self.Tabs) do
		tab:SetText(GetTabLabel(i));
		PanelTemplates_TabResize(tab, 0)
	end
	PanelTemplates_SetNumTabs(self, #self.Tabs);
	PanelTemplates_SetTab(self, _selectedTab);

	self:InitializeScrollBox();
	self:InitializeSideTabs();
	self:InitializeButtons();

	self:RegisterForDrag("LeftButton");
	self:SetScript("OnDragStart", function()
		self:StartMoving();
	end);
	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing();
		self:SetUserPlaced(false);
		local x, y = self:GetCenter();
		DebouncePrivate.db.global.ui.pos = { x = x, y = y };
	end);

	self.keyFilter = "";
	self.SearchBox:SetScript("OnTextChanged", self.SearchBox_OnTextChanged);
	self.SearchBox:SetScript("OnEditFocusLost", self.SearchBox_OnFocusLost);

	DebouncePrivate.db.global.ui = DebouncePrivate.db.global.ui or {};
	self:ClearAllPoints();
	local pos = DebouncePrivate.db.global.ui.pos;
	if (pos) then
		self:SetPoint("CENTER", "UIParent", "BOTTOMLEFT", pos.x, pos.y);
	else
		self:SetPoint("CENTER", "UIParent", 0, 0);
	end
end

function DebounceFrameMixin:OnShow()
	if (not self.initialized) then
		self:OnLoad();
	end

	self:Refresh();
	self:UpdateSideTabs();
	self:RegisterEvent("PLAYER_REGEN_DISABLED");
	self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
	self:RegisterEvent("CURSOR_CHANGED");

	DebouncePrivate.RegisterCallback(self, "OnBindingsUpdated");

	local type, value = GetActionTypeAndValueFromCursorInfo();
	if (type) then
		_pickedupInfo = { type = type, value = value };
		self:OnPickup();
	end
end

function DebounceFrameMixin:OnHide()
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
	self.SearchBox:SetText("");

	HideSaveOrDiscardPopup();
	HideDeleteConfirmationPopup();

	if (self.iconDataProvider) ~= nil then
		self.iconDataProvider:Release();
		self.iconDataProvider = nil;
	end

	self:UnregisterEvent("PLAYER_REGEN_DISABLED");
	self:UnregisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
	self:UnregisterEvent("CURSOR_CHANGED");
	self:UnregisterEvent("GLOBAL_MOUSE_UP");
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN");

	DebouncePrivate.UnregisterCallback(self, "OnBindingsUpdated");

	if (IsDraggingElement()) then
		_draggingElement = nil;
		DebounceActionPlacerFrame:Hide();
	end
	_pickedupInfo = nil;
	ClearMacrotextIconCache();
end

function DebounceFrameMixin:OnEvent(event, arg1)
	if (event == "GLOBAL_MOUSE_UP") then
		if (arg1 == "LeftButton" and IsDraggingElement()) then
			if (_placeholder and DoesAncestryIncludeMouseFocus(self.ScrollBox)) then
				self:OnReceiveDrag();
			else
				self:ClearPlaceHolder();
				self:ClearMouse();
			end
		end
	elseif (event == "GLOBAL_MOUSE_DOWN") then
		if (arg1 == "RightButton") then
			if (IsDraggingElement() or GetActionTypeAndValueFromCursorInfo()) then
				self:ClearPlaceHolder();
				self:ClearMouse();
				return;
			end
		end
	elseif (event == "CURSOR_CHANGED") then
		local type, value = GetActionTypeAndValueFromCursorInfo();
		if (type) then
			_pickedupInfo = { type = type, value = value };
			self:OnPickup();
		elseif (_pickedupInfo) then
			_pickedupInfo = nil;
			self:ClearPlaceHolder();
			self:ClearMouse();
		end
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self:OnEnterCombat();
	elseif (event == "PLAYER_REGEN_ENABLED") then
		self:OnLeaveCombat();
	elseif (event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED") then
		self:Update();
		self:UpdateSideTabs();
	end
end

function DebounceFrameMixin:OnKeyDown(input)
	if (input == "ESCAPE") then
		self:SetPropagateKeyboardInput(false);

		if (Menu.GetManager():HandleESC()) then
			return;
		end

		if (IsDraggingElement() or GetActionTypeAndValueFromCursorInfo()) then
			self:ClearPlaceHolder();
			self:ClearMouse();
			return;
		end

		self:Hide();
		return;
	end

	self:SetPropagateKeyboardInput(true);
end

function DebounceFrameMixin:OnEnterCombat()
	if (DebounceKeybindFrame:IsShown()) then
		DebounceKeybindFrame:CancelButton_OnClick();
	end

	if (DebounceIconSelectorFrame:IsShown()) then
		DebounceIconSelectorFrame:CancelButton_OnClick();
	end

	-- if (DebounceMacroFrame:IsShown()) then
	-- 	DebounceMacroFrame:CancelButton_OnClick();
	-- end

	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	self:Hide();
end

function DebounceFrameMixin:OnLeaveCombat()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED");
	self:Show();
end

function DebounceFrameMixin:OnBindingsUpdated(_, skipped)
	self:Update();
end

local function ElementSortComparator(lhs, rhs)
	local lv = lhs.sortIndex or lhs.index;
	local rv = rhs.sortIndex or rhs.index;
	return lv < rv;
end

function DebounceFrameMixin:Refresh(retainScrollPosition)
	HideDeleteConfirmationPopup();

	if (_placeholder) then
		_placeholder.sortIndex = nil;
		_placeholder = nil;
	end

	local dataProvider = CreateDataProvider();
	local layerID = GetLayerID();
	local layer = DebouncePrivate.GetProfileLayer(layerID);

	for i, action in layer:Enumerate() do
		local elementData;
		local draggingElement = GetDraggingElement();
		if (draggingElement and draggingElement.layer == layerID and draggingElement.action == action) then
			elementData = draggingElement;
			elementData.index = i;
			elementData.sortIndex = i;
		else
			elementData = { action = action, layer = layerID, index = i, };
		end
		dataProvider:Insert(elementData);
	end
	dataProvider:SetSortComparator(ElementSortComparator, false);

	self.dataProvider = dataProvider;
	self.ScrollBox:SetDataProvider(dataProvider, retainScrollPosition and ScrollBoxConstants.RetainScrollPosition or ScrollBoxConstants.DiscardScrollPosition);

	local title = format(LLL["DEBOUNCE_TITLE_FORMAT"], GetTabLabel(_selectedTab), GetSideTabaLabel(_selectedSideTab));
	self:SetTitle(title);
	self:UpdateActionCounts();
	self:UpdateEmptyText();
end

function DebounceFrameMixin:FindElementDataByActionInfo(action)
	local index, elementData = self.dataProvider:FindByPredicate(function(e) return e.action == action; end);
	return elementData, index;
end

function DebounceFrameMixin:AddNewAction(type, value, name, icon, props)
	PlaySound(SOUNDKIT.IG_ABILITY_ICON_DROP);

	local layerID = GetLayerID();
	local layer = DebouncePrivate.GetProfileLayer(layerID);
	local action = {
		type = type,
		value = value,
		name = name,
		icon = icon,
	};
	if (props) then
		for k, v in pairs(props) do
			action[k] = v;
		end
	end
	layer:Insert(action);

	local lastElem = self.dataProvider:Find(self.dataProvider:GetSize());
	local elementData = { action = action, layer = GetLayerID(), index = lastElem and lastElem.index + 1 or 1 };
	self.dataProvider:Insert(elementData);
	for i, other in self.dataProvider:Enumerate() do
		other.index = i;
	end
	self.ScrollBox:ScrollToEnd();
	self:Update();

	return elementData;
end

function DebounceFrameMixin:Update()
	self:UpdateButtons();

	self.ScrollBox:ForEachFrame(function(button)
		button:Update();
	end);

	self:UpdateEmptyText();

	self.ScrollBoxBackground.Highlight:SetShown(_pickedupInfo or _draggingElement)
end

function DebounceFrameMixin:UpdateButtons()
	local enableButtons = not (IsEditingMacro() or IsKeybindFrameShown());

	for i = 1, #self.Tabs do
		PanelTemplates_SetTabEnabled(self, i, enableButtons);
	end

	for _, tab in ipairs(self.SideTabs) do
		tab:SetEnabled(enableButtons);
	end

	self.AddPortrait:SetEnabled(enableButtons);
	self.CustomStatesPortrait:SetEnabled(enableButtons);
	self.OptionsPortrait:SetEnabled(enableButtons);
	self.SearchBox:SetEnabled(enableButtons);
end

function DebounceFrameMixin:SetTab(id)
	PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN);
	_selectedTab = id;
	PanelTemplates_SetTab(self, _selectedTab);
	self:UpdateSideTabs();

	if (not self.SideTabs[_selectedSideTab]:IsShown()) then
		_selectedSideTab = 1;
		self:UpdateSideTabs();
	end

	self:Refresh();
end

function DebounceFrameMixin:ShowEditDropdown(button, atButton)
	local elementData = button:GetElementData();
	local menu = MenuUtil.CreateContextMenu(button, DebounceUI.SetupEditDropdownMenu, elementData);
	self.contextMenu = menu;
	if (menu) then
		self.contextMenuData = elementData;
		menu:SetClosedCallback(function()
			self.contextMenu = nil;
			self.contextMenuData = nil;
		end);
	end
	self:Update();
end

function DebounceFrameMixin:OnPickup()
	self:ClearMouse(true);
	self:RegisterEvent("GLOBAL_MOUSE_UP");
	self:RegisterEvent("GLOBAL_MOUSE_DOWN");
	self:SetScript("OnUpdate", self.OnUpdate);
	self:Update();
end

function DebounceFrameMixin:ClearMouse(pickingUp)
	if (_draggingElement) then
		_draggingElement = nil;
		DebounceActionPlacerFrame:Hide();
	end
	if (not pickingUp and _pickedupInfo) then
		_pickedupInfo = nil;
		ClearCursor();
	end

	self:UnregisterEvent("GLOBAL_MOUSE_UP");
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	self:SetScript("OnUpdate", nil);
	if (not pickingUp) then
		self:Update();
	end
end

function DebounceFrameMixin:StartDragging(elementData)
	assert(_placeholder == nil);

	elementData.sortIndex = elementData.index;
	_draggingElement = elementData;

	local name, icon = ColoredNameAndIconFromElementData(elementData);
	DebounceActionPlacerFrame.Name:SetText(name);
	DebounceActionPlacerFrame.Icon:SetTexture(icon);
	DebounceActionPlacerFrame:Show();

	self:RegisterEvent("GLOBAL_MOUSE_UP");
	self:RegisterEvent("GLOBAL_MOUSE_DOWN");
	self:SetScript("OnUpdate", self.OnUpdate);
	self:Update();
end

function DebounceFrameMixin:ClearPlaceHolder()
	if (_placeholder) then
		_placeholder.sortIndex = nil;
		if (_placeholder.layer ~= GetLayerID()) then
			self.dataProvider:Remove(_placeholder);
		else
			self.dataProvider:Sort();
		end
		_placeholder = nil;
	end
end

function DebounceFrameMixin:CancelDragging(pickingUp)
	self:ClearPlaceHolder();
	if (_draggingElement) then
		_draggingElement = nil;
		DebounceActionPlacerFrame:Hide();
	end

	if (not pickingUp) then
		ClearCursor();
	end

	self:UnregisterEvent("GLOBAL_MOUSE_UP");
	self:UnregisterEvent("GLOBAL_MOUSE_DOWN");
	self:SetScript("OnUpdate", nil);
end

function DebounceFrameMixin:CanReceiveDrag()
	return IsDraggingElement() or GetActionTypeAndValueFromCursorInfo();
end

function DebounceFrameMixin:OnReceiveDrag(destLayerID)
	if (not self:CanReceiveDrag()) then
		return;
	end

	local action, prevLayerID;
	local draggingElement = GetDraggingElement();
	if (draggingElement) then
		action = draggingElement.action;
		prevLayerID = draggingElement.layer;
	else
		local type, value = GetActionTypeAndValueFromCursorInfo();
		action = { type = type, value = value };
	end

	local placeholder = _placeholder;
	_placeholder = nil;

	local currentLayerID = GetLayerID();
	destLayerID = destLayerID or GetLayerID();
	local destLayer = DebouncePrivate.GetProfileLayer(destLayerID);

	if (prevLayerID) then
		DebouncePrivate.GetProfileLayer(prevLayerID):Remove(action);
	end

	-- Inserting into the current ScrollBox.
	if (destLayerID == currentLayerID and placeholder) then
		for i, elementData in self.dataProvider:Enumerate() do
			elementData.index = i;
			if (placeholder == elementData) then
				destLayer:Insert(action, i);
			end
		end
	else
		destLayer:Insert(action, nil);
		if (_newlyInsertedActions[destLayerID] == nil) then
			_newlyInsertedActions[destLayerID] = action;
		end
	end
	self:ClearMouse();
	DebouncePrivate.UpdateBindings();
	self:Refresh(true);
end

function DebounceFrameMixin:RefreshIconDataProvider()
	if (self.iconDataProvider == nil) then
		self.iconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook);
	end
	return self.iconDataProvider;
end

function DebounceFrameMixin:SearchBox_OnTextChanged(userInput)
	InputBoxInstructions_OnTextChanged(self);

	local filterText = string.match(self:GetText(), "^%s*(.-)%s*$"):lower();
	if (filterText == "") then
		filterText = nil;
	end

	if (self.filterText ~= filterText) then
		self.filterText = filterText;

		if (filterText) then
			local words = {}
			for word in string.gmatch(filterText, "%S+") do
				table.insert(words, word)
			end
			self.filters = words;
		else
			self.filters = nil;
		end
		DebounceFrame:Refresh();
	end
end

function DebounceFrameMixin:SearchBox_OnFocusLost()
	SearchBoxTemplate_OnEditFocusLost(self);
	local rawText = self:GetText();
	local trimmedText = string.match(rawText, "^%s*(.-)%s*$"):lower();
	if (rawText ~= trimmedText) then
		self:SetText(trimmedText);
	end
end

function DebounceFrameMixin:SearchBoxClearButton_OnClick()
	DebounceFrame.keyFilter = "";
	SearchBoxTemplateClearButton_OnClick(self);
end

DebounceKeybindFrameMixin = {};

function DebounceKeybindFrameMixin:OnLoad()
end

function DebounceKeybindFrameMixin:Open(elementData)
	self.elementData = elementData;
	if (self:IsShown()) then
		self:OnShow();
	else
		self:Show();
	end
end

function DebounceKeybindFrameMixin:OnShow()
	if (not self.initialized) then
		self.initialized = true;
		self:RegisterForClicks("AnyUp");
		self.InstructionText:SetText(LLL["KEYBIND_INSTRUCTION_TEXT"]);
	end

	local action = self.elementData.action;
	self.prevKey = action.key;
	self.newKey = nil;
	self.gotInput = nil;
	self:Update();
	DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:OnHide()
	self.elementData = nil;
	self.prevKey = nil;
	self.newKey = nil;
	self.gotInput = nil;
	--DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:OnKeyDown(key)
	if (key == "ESCAPE") then
		self:SetPropagateKeyboardInput(false);
		self:CancelButton_OnClick();
		return;
	end

	if (DoesAncestryIncludeMouseFocus(self)) then
		self:SetPropagateKeyboardInput(false);
		self:ProcessInput(key);
	else
		self:SetPropagateKeyboardInput(true);
	end

	-- if (self:IsMouseOver()) then
	-- 	self:SetPropagateKeyboardInput(false);
	-- 	self:ProcessInput(key);
	-- else
	-- 	self:SetPropagateKeyboardInput(true);
	-- end
end

function DebounceKeybindFrameMixin:OnClick(button)
	self:ProcessInput(button);
end

function DebounceKeybindFrameMixin:OnMouseWheel(delta)
	self:OnKeyDown(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN");
end

function DebounceKeybindFrameMixin:OnGamePadButtonDown(key)
	self:ProcessInput(key);
end

function DebounceKeybindFrameMixin:ProcessInput(input)
	if (IsMetaKey(input) or input == "UNKNOWN") then
		return;
	end

	local key = GetConvertedKeyOrButton(input);
	key = _CreateKeyChordStringUsingMetaKeyState(key);
	self.gotInput = true;
	if (self.newKey ~= key) then
		self.newKey = key;
		self:Update();
	end
end

function DebounceKeybindFrameMixin:OkayButton_OnClick()
	self.elementData.action.key = self.newKey;
	self:Hide();
	DebouncePrivate.UpdateBindings();
end

function DebounceKeybindFrameMixin:CancelButton_OnClick()
	self:Hide();
	DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:UnbindButton_OnClick()
	self.newKey = nil;
	self.gotInput = true;
	self.NewKeyText:SetFormattedText(LLL["NEW_KEY_TEXT"], LLL["NOT_BOUND"]);
	self.UnbindButton:SetEnabled(false);
	DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:Update()
	local name, icon = NameAndIconFromElementData(self.elementData);
	if (luatype(icon) == "string" and icon:sub(1, 2) == "A:") then
		self.ActionNameText:SetText(format("|A:%2$s:16:16|a |cffffd200%1$s|r", name, icon:sub(3)));
	else
		self.ActionNameText:SetText(format("|T%2$s:16|t |cffffd200%1$s|r", name, icon));
	end

	self.PreviousKeyText:SetFormattedText(LLL["PREVIOUS_KEY_TEXT"], self.prevKey and GetBindingText(self.prevKey) or LLL["NOT_BOUND"]);
	if (self.gotInput) then
		if (self.newKey) then
			self.NewKeyText:SetFormattedText(LLL["NEW_KEY_TEXT"], GetBindingText(self.newKey));
			self.UnbindButton:SetEnabled(true);
		else
			self.NewKeyText:SetText(LLL["NOT_BOUND"]);
			self.UnbindButton:SetEnabled(false);
		end
	else
		self.NewKeyText:SetText("");
		self.UnbindButton:SetEnabled(self.elementData.action.key ~= nil);
	end

	local warningText;
	local key = self.newKey or self.prevKey;

	if (key) then
		local issue = IsKeyInvalidForAction(self.elementData.action, key);
		if (issue) then
			warningText = LLL["BINDING_ERROR_" .. issue];
		elseif (issue) then
			warningText = WARNING_FONT_COLOR:WrapTextInColorCode(LLL[issue]);
		end
	end

	self.WarningText:SetText(warningText or "");
end

function DebounceKeybindFrameMixin:HasUnsavedChanges()
	if (self:IsShown() and self.gotInput and self.newKey ~= self.prevKey) then
		return true;
	end
end

function DebounceKeybindFrameMixin:Close(force)
	if (self:IsShown()) then
		if (not force and self:HasUnsavedChanges()) then
			DebouncePrivate.DisplayMessage(LLL["CONFIRM_CURRENT_CHANGE_FIRST"]);
			return false;
		end
		self:CancelButton_OnClick();
	end
	return true;
end

DebounceIconSelectorFrameMixin = {};

function DebounceIconSelectorFrameMixin:OnLoad()
end

function DebounceIconSelectorFrameMixin:OnShow()
	if (self.mode == IconSelectorPopupFrameModes.Edit) then
		if (not self.elementData) then
			self:Hide();
			return;
		end

		self.elementData = DebounceFrame:FindElementDataByActionInfo(self.elementData.action);
		if (not self.elementData) then
			self.elementData = nil;
			self:Hide();
			return;
		end
	end

	if (not self.initialized) then
		self.initialized = true;
		IconSelectorPopupFrameTemplateMixin.OnLoad(self);
		self.BorderBox.EditBoxHeaderText:SetText(format(LLL["MACRO_POPUP_TEXT"], MACRO_NAME_CHAR_LIMIT));
		self.BorderBox.IconSelectorEditBox:SetMaxLetters(MACRO_NAME_CHAR_LIMIT);
	end
	IconSelectorPopupFrameTemplateMixin.OnShow(self);
	self.BorderBox.IconSelectorEditBox:SetFocus();

	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
	self.iconDataProvider = DebounceFrame:RefreshIconDataProvider();
	self:SetIconFilter(IconSelectorPopupFrameIconFilterTypes.All);
	self:Update();
	self.BorderBox.IconSelectorEditBox:OnTextChanged();

	local function OnIconSelected(selectionIndex, icon)
		self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon);

		-- Index is not yet set, but we know if an icon in IconSelector was selected it was in the list, so set directly.
		self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription:SetText(ICON_SELECTION_CLICK);
		self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription:SetFontObject(GameFontHighlightSmall);
	end
	self.IconSelector:SetSelectedCallback(OnIconSelected);

	DebounceFrame:Update();
end

function DebounceIconSelectorFrameMixin:OnHide()
	IconSelectorPopupFrameTemplateMixin.OnHide(self);
	self.elementData = nil;
	DebounceFrame:Update();
end

function DebounceIconSelectorFrameMixin:Update()
	-- Determine whether we're creating a new macro or editing an existing one
	if (self.mode == IconSelectorPopupFrameModes.New) then
		self.BorderBox.IconSelectorEditBox:SetText("");
		local initialIndex = 1;
		self.IconSelector:SetSelectedIndex(initialIndex);
		self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(self:GetIconByIndex(initialIndex));
	elseif (self.mode == IconSelectorPopupFrameModes.Edit) then
		local action = self.elementData.action;
		local name, icon = action.name, action.icon;
		self.BorderBox.IconSelectorEditBox:SetText(name);
		self.BorderBox.IconSelectorEditBox:HighlightText();
		self.IconSelector:SetSelectedIndex(self:GetIndexOfIcon(icon));
		self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon);
	end

	local getSelection = GenerateClosure(self.GetIconByIndex, self);
	local getNumSelections = GenerateClosure(self.GetNumIcons, self);
	self.IconSelector:SetSelectionsDataProvider(getSelection, getNumSelections);
	self.IconSelector:ScrollToSelectedIndex();

	self:SetSelectedIconText();
end

function DebounceIconSelectorFrameMixin:CancelButton_OnClick()
	if (self.mode == IconSelectorPopupFrameModes.Edit) then
		DebounceMacroFrame:ShowEdit(self.elementData);
	end
	IconSelectorPopupFrameTemplateMixin.CancelButton_OnClick(self);
end

function DebounceIconSelectorFrameMixin:OkayButton_OnClick()
	local iconTexture = self.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture();
	local text = self.BorderBox.IconSelectorEditBox:GetText();
	text = string.gsub(text, "\"", "");

	local elementData;
	if (self.mode == IconSelectorPopupFrameModes.New) then
		elementData = DebounceFrame:AddNewAction(Constants.MACROTEXT, "", text, iconTexture);
	else
		elementData = self.elementData;
		elementData.action.name = text;
		elementData.action.icon = iconTexture;
	end

	DebounceFrame:Update();
	DebounceMacroFrame:ShowEdit(elementData);
	IconSelectorPopupFrameTemplateMixin.OkayButton_OnClick(self);
end

function DebounceIconSelectorFrameMixin:HasUnsavedChanges()
	if (self:IsShown() and self.mode == IconSelectorPopupFrameModes.Edit) then
		local newName = string.gsub(self.BorderBox.IconSelectorEditBox:GetText(), "\"", "");
		local newIcon = self.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture();
		if (self.elementData.action.name ~= newName or self.elementData.action.icon ~= newIcon) then
			return true;
		end
	end
	return false;
end

function DebounceIconSelectorFrameMixin:Close(force)
	if (self:IsShown()) then
		if (not force and self:HasUnsavedChanges()) then
			DebouncePrivate.DisplayMessage(LLL["CONFIRM_CURRENT_CHANGE_FIRST"]);
			return false;
		end
		self:CancelButton_OnClick();
	end
	return true;
end

DebounceMacroFrameMixin = {}

function DebounceMacroFrameMixin:OnLoad()
	self.BorderBox.ScrollFrame.EditBox:SetMaxLetters(MACRO_CHAR_LIMIT);

	self.OkayButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);
		self:OkayButton_OnClick();
	end);

	self.CancelButton:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK);
		self:CancelButton_OnClick();
	end);

	self.initialized = true;
end

function DebounceMacroFrameMixin:ShowEdit(elementData, cancelFunc)
	self:Hide();

	if (self.elementData ~= elementData) then
		self.tempText = nil;
	end
	self.elementData = elementData;
	self.cancelFunc = cancelFunc;
	self.orginalText = elementData.action.value;

	local action = elementData.action;
	local name, icon = action.name, action.icon;
	self.BorderBox.SelectedMacroName:SetText(name);
	self.BorderBox.SelectedMacroButton.Icon:SetTexture(icon);

	local text = self.tempText or action.value;
	self.BorderBox.ScrollFrame.EditBox:SetText(text);

	self:Show();
end

function DebounceMacroFrameMixin:UpdateButtons()
	self.OkayButton:SetEnabled(self.cancelFunc ~= nil or self:HasUnsavedChanges());
end

function DebounceMacroFrameMixin:OnShow()
	if (not self.initialized) then
		self:OnLoad();
	end

	self:UpdateButtons();
	DebounceFrame:Update();
end

function DebounceMacroFrameMixin:OnHide()
	DebounceFrame:Update();
	HideSaveOrDiscardPopup();
end

function DebounceMacroFrameMixin:OnKeyDown(key)
	if (key == "ESCAPE") then
		self:SetPropagateKeyboardInput(false);
		if (self:HasUnsavedChanges()) then
			ShowSaveOrDiscardPopup(self.elementData);
		else
			self:CancelButton_OnClick();
			return;
		end
	else
		self:SetPropagateKeyboardInput(true);
	end
end

function DebounceMacroFrameMixin:EditButton_OnClick()
	local text = self.BorderBox.ScrollFrame.EditBox:GetText();
	self.tempText = text;
	DebounceIconSelectorFrame.mode = IconSelectorPopupFrameModes.Edit;
	DebounceIconSelectorFrame.elementData = self.elementData;
	DebounceIconSelectorFrame:Show();
	self:Hide();
end

function DebounceMacroFrameMixin:OkayButton_OnClick()
	if (self:HasUnsavedChanges()) then
		local text = self.BorderBox.ScrollFrame.EditBox:GetText();
		self.elementData.action.value = text;
		self.orginalText = text;
		DebouncePrivate.UpdateBindings();
	end
	self:Hide();
	self.elementData = nil;
	self.tempText = nil;
	self.cancelFunc = nil;
end

function DebounceMacroFrameMixin:CancelButton_OnClick()
	if (self.cancelFunc) then
		self.cancelFunc();
	end
	self:Hide();
	self.elementData = nil;
	self.tempText = nil;
	self.cancelFunc = nil;
end

function DebounceMacroFrameMixin:OnTextChanged(editBox)
	ScrollingEdit_OnTextChanged(editBox, editBox:GetParent());
	self.BorderBox.CharLimitText:SetFormattedText(LLL["MACROFRAME_CHAR_LIMIT"], editBox:GetNumLetters(), MACRO_CHAR_LIMIT);
	self:UpdateButtons();
end

function DebounceMacroFrameMixin:HasUnsavedChanges()
	local text = self.BorderBox.ScrollFrame.EditBox:GetText();
	return text ~= self.orginalText;
end

function DebounceMacroFrameMixin:Close(force)
	if (self:IsShown()) then
		if (not force and self:HasUnsavedChanges()) then
			DebouncePrivate.DisplayMessage(LLL["CONFIRM_CURRENT_CHANGE_FIRST"]);
			return false;
		end
		self:CancelButton_OnClick();
	end
	return true;
end

DebounceOverviewFrameMixin = {}

function DebounceOverviewFrameMixin:OnLoad()
	self.initialized = true;

	local title = format(LLL["DEBOUNCE_OVERVIEW_TITLE"]);
	self:SetTitle(title);
	self:SetPortraitToAsset(133015);

	DebouncePrivate.db.global.overviewui = DebouncePrivate.db.global.overviewui or {};
	self:ClearAllPoints();
	local pos = DebouncePrivate.db.global.overviewui.pos;
	if (pos) then
		self:SetPoint("CENTER", "UIParent", "BOTTOMLEFT", pos.x, pos.y);
	else
		self:SetPoint("CENTER", "UIParent", 0, 0);
	end

	self:RegisterForDrag("LeftButton");
	self:SetScript("OnDragStart", function()
		self:StartMoving();
	end);

	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing();
		self:SetUserPlaced(false);
		local x, y = self:GetCenter();
		DebouncePrivate.db.global.overviewui.pos = { x = x, y = y };
	end);

	self:RegisterEvent("PLAYER_REGEN_ENABLED");

	self:InitializeScrollBox();
end

function DebounceOverviewFrameMixin:OnShow()
	if (not self.initialized) then
		self:OnLoad();
	end

	self:Refresh();

	DebouncePrivate.RegisterCallback(self, "OnBindingsUpdated");

	DebounceFrame.OverviewPortrait:SetSelectedState(true);
end

function DebounceOverviewFrameMixin:OnHide()
	DebounceFrame.OverviewPortrait:SetSelectedState(false);
	ClearMacrotextIconCache();
end

function DebounceOverviewFrameMixin:OnEvent(event)
	-- if (event == "PLAYER_REGEN_ENABLED") then
	-- end
	if (not InCombatLockdown()) then
		self:SetPropagateKeyboardInput(true);
	end
end

function DebounceOverviewFrameMixin:OnBindingsUpdated(...)
	self:Refresh(true);
end

DebounceOverviewHeaderMixin = {};

function DebounceOverviewHeaderMixin:Init()
	local elementData = self:GetElementData();
	self.Name:SetText(GetBindingText(elementData.key), false);
end

DebounceOverviewLineMixin = {};

function DebounceOverviewLineMixin:Init()
	self:Update();
end

function DebounceOverviewLineMixin:OnEnter()
	ShowLineTooltip(self, "ANCHOR_CURSOR_RIGHT", self:GetElementData(), true);
	if (DebounceOverviewFrame.hoveredAction ~= self:GetElementData().action) then
		DebounceOverviewFrame.hoveredAction = self:GetElementData().action;
		DebounceFrame:Update();
	end
end

function DebounceOverviewLineMixin:OnLeave()
	if (DebounceOverviewFrame.hoveredAction ~= nil) then
		DebounceOverviewFrame.hoveredAction = nil;
		DebounceFrame:Update();
	end
	---@diagnostic disable-next-line: redundant-parameter
	GameTooltip:SetMinimumWidth(0, false);
	GameTooltip:Hide();
end

function DebounceOverviewLineMixin:OnClick()
	if (InCombatLockdown()) then
		return;
	end

	local matchedLayer;
	local elementData = self:GetElementData();
	for _, layer in DebouncePrivate.EnumerateProfileLayers() do
		for _, action in layer:Enumerate() do
			if (action == elementData.action) then
				matchedLayer = layer;
				break;
			end
		end
	end

	if (matchedLayer) then
		DebounceFrame:Show();
		if (matchedLayer.isCharacterSpecific) then
			DebounceFrame:SetTab(2);
		else
			DebounceFrame:SetTab(1);
		end
		if (matchedLayer.spec) then
			DebounceFrame.SideTabs[matchedLayer.spec + 2]:Click();
		else
			DebounceFrame.SideTabs[1]:Click();
		end

		local index, elementDataFound = DebounceFrame.dataProvider:FindByPredicate(function(elementData2)
			return elementData2.action == elementData.action;
		end)

		DebounceFrame.ScrollBox:ScrollToNearest(index);
	end
end

function DebounceOverviewLineMixin:Update()
	local elementData = self:GetElementData();
	local action = elementData.action;

	local name, icon = ColoredNameAndIconFromElementData(elementData);

	self.Name:SetText(name);
	if (luatype(icon) == "string" and icon:sub(1, 2) == "A:") then
		self.Icon:SetAtlas(icon:sub(3));
	else
		self.Icon:SetTexture(icon);
	end

	local professionQuality = action.type == Constants.ITEM and C_TradeSkillUI.GetItemReagentQualityByItemInfo(action.value);
	if (professionQuality) then
		if (not self.ProfessionQualityOverlay) then
			self.ProfessionQualityOverlay = self:CreateTexture(nil, "Overlay");
			self.ProfessionQualityOverlay:SetPoint("TOPLEFT", self.Icon, "TOPLEFT", -3, 2);
			self.ProfessionQualityOverlay:SetDrawLayer("OVERLAY", 7);
		end
		local atlas = ("Professions-Icon-Quality-Tier%d-Inv"):format(professionQuality);
		self.ProfessionQualityOverlay:SetAtlas(atlas, TextureKitConstants.UseAtlasSize);
		self.ProfessionQualityOverlay:Show();
	elseif (self.ProfessionQualityOverlay) then
		self.ProfessionQualityOverlay:Hide();
	end

	local bindingText = GetBindingText(action.key);
	self.BindingText:SetText(bindingText or "");

	if (action.unit) then
		self.UnitText:SetText(UNIT_INFO[action.unit] and UNIT_INFO[action.unit].name or LLL[action.unit]);
		self.UnitText:Show();
	else
		self.UnitText:Hide();
	end


	if (DebouncePrivate.IsConditionalAction(action)) then
		self.QuestionMark:Show();
	else
		self.QuestionMark:Hide();
	end
end

local SORT_KEYS = {
	LALT = 1,
	RALT = 2,
	LCTRL = 3,
	RCTRL = 4,
	LSHIFT = 5,
	RSHIFT = 6,
	LMETA = 7,
	RMETA = 8,
	ALT = 9,
	CTRL = 10,
	SHIFT = 11,
	META = 12,

	BUTTON1 = 21,
	BUTTON2 = 22,
	BUTTON3 = 23,
	BUTTON4 = 24,
	BUTTON5 = 25,
	MOUSEWHEELUP = 26,
	MOUSEWHEELDOWN = 27,

	UP = 61,
	DOWN = 62,
	LEFT = 63,
	RIGHT = 64,
	PAGEUP = 65,
	PAGEDOWN = 66,
	BACKSPACE = 67,
	TAB = 68,
	SPACE = 69,
	ENTER = 70,
	ESCAPE = 71,
	INSERT = 72,
	DELETE = 73,
	HOME = 74,
	END = 75,
	PRINTSCREEN = 76,
	PAUSE = 77,
	CAPSLOCK = 78,
	SCROLLLOCK = 79,

	NUMPAD1 = 91,
	NUMPAD2 = 92,
	NUMPAD3 = 93,
	NUMPAD4 = 94,
	NUMPAD5 = 95,
	NUMPAD6 = 96,
	NUMPAD7 = 97,
	NUMPAD8 = 98,
	NUMPAD9 = 99,
	NUMPAD0 = 100,
	NUMPADDECIMAL = 101,
	NUMLOCK = 102,
	NUMPADDIVIDE = 103,
	NUMPADMULTIPLY = 104,
	NUMPADMINUS = 105,
	NUMPADPLUS = 106,

	F1 = 121,
	F2 = 122,
	F3 = 123,
	F4 = 124,
	F5 = 125,
	F6 = 126,
	F7 = 127,
	F8 = 128,
	F9 = 129,
	F10 = 130,
	F11 = 131,
	F12 = 132,
};

local function keyCompare(lhs, rhs)
	if (lhs.lastKey ~= rhs.lastKey) then
		local l = SORT_KEYS[lhs.lastKey];
		local r = SORT_KEYS[rhs.lastKey];

		if (l and r) then
			return l < r;
		elseif (l) then
			return true;
		elseif (r) then
			return false;
		else
			return lhs.lastKey < rhs.lastKey;
		end
	end

	if (#lhs.mods ~= #rhs.mods) then
		return #lhs.mods < #rhs.mods;
	end

	for i = 1, #lhs.mods do
		local a = SORT_KEYS[lhs.mods[i]];
		local b = SORT_KEYS[rhs.mods[i]];
		if (a ~= b) then
			return a < b;
		end
	end
end

function DebounceOverviewFrameMixin:Refresh(retainScrollPosition)
	local dataProvider = CreateDataProvider();
	local keyMap = DebouncePrivate.GetKeyMap();

	local keyArr = {};
	for key, _ in pairs(keyMap) do
		local sa = { strsplit("-", key) };
		local keyInfo = {};
		keyInfo.key = key;
		keyInfo.lastKey = tremove(sa, #sa);
		keyInfo.mods = sa;
		keyArr[#keyArr + 1] = keyInfo;
	end

	sort(keyArr, keyCompare);

	for _, keyInfo in ipairs(keyArr) do
		local actionArray = keyMap[keyInfo.key];
		for i = 1, #actionArray do
			local action = actionArray[i];
			local elementData = { action = action, keyInfo = keyInfo };
			dataProvider:Insert(elementData);
		end
	end

	self.dataProvider = dataProvider;
	self.ScrollBox:SetDataProvider(dataProvider, retainScrollPosition and ScrollBoxConstants.RetainScrollPosition or ScrollBoxConstants.DiscardScrollPosition);
end

function DebounceOverviewFrameMixin:InitializeScrollBox()
	local padding = 7;
	local spacing = 2;
	local view = CreateScrollBoxListLinearView(padding, padding, padding, padding, spacing);

	view:SetElementInitializer("DebounceOverviewLineTemplate", function(button, elementData)
		button:Init(elementData);
	end);

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);
end

-- Taint warning!
-- 전투 중에 SetPropagateKeyboardInput을 호출하면 taint 발생함. 적절한 방법을 찾을 수가 없다.
function DebounceOverviewFrameMixin:OnKeyDown(input)
	if (input == "ESCAPE") then
		self:Hide();
		if (not InCombatLockdown()) then
			self:SetPropagateKeyboardInput(false);
		end
	else
		if (not InCombatLockdown()) then
			self:SetPropagateKeyboardInput(true);
		end
	end
end

function DebounceOverviewFrameMixin:Toggle()
	if (self:IsShown()) then
		self:Hide();
	else
		self:Show();
	end
end

function DebounceUI.GetSelectedTab()
	return _selectedTab;
end

function DebounceUI.GetSelectedSideTab()
	return _selectedSideTab;
end

DebounceStateDriverUpdateThrottleSliderMixin = {};

function DebounceStateDriverUpdateThrottleSliderMixin:OnLoad()
	self.Slider:SetAccessorFunction(function()
		return DebouncePrivate.Options.stateDriverUpdateThrottle or 0.2;
	end);

	self.Slider:SetMutatorFunction(function(value)
		value = floor(value * 1000 + 1) / 1000;
		DebouncePrivate.Options.stateDriverUpdateThrottle = value;
		DebouncePrivate.ApplyOptions("stateDriverUpdateThrottle");
	end);

	self.Slider:RegisterPropertyChangeHandler("OnValueChanged", function(slider, value, isMouse)
		self.ValueText.Text:SetText(format("%.2f", value):gsub("%.?0+$", ""));
	end);

	self.Slider:UpdateVisibleState();
end

function DebounceStateDriverUpdateThrottleSliderMixin:UpdateVisibleState()
	self.Slider:UpdateVisibleState();
end

-- temp
DebounceUI.UNIT_INFO = UNIT_INFO;
DebounceUI.BINDING_TYPE_NAMES = BINDING_TYPE_NAMES;
DebounceUI.GetLayerID = GetLayerID;
DebounceUI.GetTabLabel = GetTabLabel;
DebounceUI.GetSideTabaLabel = GetSideTabaLabel;
DebounceUI.MoveAction = MoveAction;
DebounceUI.ShowDeleteConfirmationPopup = ShowDeleteConfirmationPopup;
DebounceUI.NameAndIconFromElementData = NameAndIconFromElementData;
DebounceUI.ShowInputBox = ShowInputBox
