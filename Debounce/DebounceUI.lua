---@diagnostic disable: cast-local-type
local _, DebouncePrivate         = ...;
local NUM_SPECS                  = GetNumSpecializationsForClassID(select(3, UnitClass("player")));
local LibDD                      = LibStub:GetLibrary("LibUIDropDownMenu-4.0");
local Constants                  = DebouncePrivate.Constants;
local LLL                        = DebouncePrivate.L;
local PLAYER_CLASS               = select(2, UnitClass("player"));
local MACRO_NAME_CHAR_LIMIT      = 32;
local MACRO_CHAR_LIMIT           = 1000;
local MAX_BONUS_ACTIONBAR_OFFSET = 5;
local MAX_ACTIONBAR_TYPE_INDEX   = 14;
local luatype                    = type;

local DISABLED_FONT_COLOR        = _G.DISABLED_FONT_COLOR;
local ERROR_COLOR                = _G.ERROR_COLOR;
local WARNING_FONT_COLOR         = CreateColor(1, 0.5, 0, 1);
local INACTIVE_COLOR             = _G.INACTIVE_COLOR;

local dump                       = DebouncePrivate.dump;

local _selectedTab               = 1;
local _selectedSideTab           = 1;
local _placeholder;
local _draggingElement;
local _pickedupInfo;

local UNIT_FRAME_REACTIONS       = {
	"HELP",
	"HARM",
	"OTHER",
};

local UNIT_FRAME_TYPES           = {
	"PLAYER",
	"PET",
	"GROUP",
	"TARGET",
	"BOSS",
	"ARENA",
	"UNKNOWN",
};

local BINDING_TYPE_NAMES         = {
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
	[Constants.UNUSED] = LLL["TYPE_UNUSED"],
};

local UNIT_INFOS                 = {
	player = {
		name = LLL["UNIT_PLAYER"],
	},
	pet = {
		name = LLL["UNIT_PET"],
	},
	target = {
		name = LLL["UNIT_TARGET"],
		spell = false,
		item = false,
		target = false,
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
		name = LLL["UNIT_ROLE_TANK"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
	},
	healer = {
		name = LLL["UNIT_ROLE_HEALER"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
	},
	maintank = {
		name = LLL["UNIT_ROLE_MAIN_TANK"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
	},
	mainassist = {
		name = LLL["UNIT_ROLE_MAIN_ASSIST"],
		tooltipTitle = LLL["UNIT_ROLE_DESC"],
	},
	custom1 = {
		name = LLL["UNIT_CUSTOM1"],
	},
	custom2 = {
		name = LLL["UNIT_CUSTOM2"],
	},
	hover = {
		name = LLL["UNIT_HOVER"],
		-- spell = false,
		-- item = false,
		tooltipTitle = LLL["UNIT_HOVER_DESC"],
		tooltipWarning = DebouncePrivate.CliqueDetected and ERROR_COLOR:WrapTextInColorCode(LLL["BINDING_ERROR_CANNOT_USE_HOVER_WITH_CLIQUE"]) or nil,
	},
	none = {
		name = LLL["UNIT_NONE"],
		tooltipTitle = LLL["UNIT_NONE_DESC"],
		target = false,
		focus = false,
		togglemenu = false,
	},
};

local SORTED_UNIT_LIST           = {
	"player",
	"pet",
	"target",
	"focus",
	"mouseover",
	"tank",
	"healer",
	"maintank",
	"mainassist",
	"custom1",
	"custom2",
	"hover",
	"none"
};

local BLIZZARD_UNITFRAMES        = {
	"player",
	"pet",
	"target",
	"party",
	"raid",
	"boss",
	"arena",
};


local GetActionBarTypeLabel;
do
	local _ACTION_BAR_LABELS;
	function GetActionBarTypeLabel(index)
		if (_ACTION_BAR_LABELS == nil) then
			_ACTION_BAR_LABELS = {
				[0] = LLL["DEFAULT"],
				[5] = GetFlyoutInfo(229),
				[11] = "[possessbar]",
				[12] = "[vehicleui]",
				[13] = "[shapeshift]",
				[14] = "[overridebar]",
			};
			for i = 0, MAX_BONUS_ACTIONBAR_OFFSET do
				_ACTION_BAR_LABELS[i] = format("[bonusbar:%d]", i);
			end

			if (PLAYER_CLASS == "DRUID") then
				_ACTION_BAR_LABELS[1] = format("%s (%s)", _ACTION_BAR_LABELS[1], GetSpellInfo(768));
				_ACTION_BAR_LABELS[3] = format("%s (%s)", _ACTION_BAR_LABELS[3], GetSpellInfo(5487));
				_ACTION_BAR_LABELS[4] = format("%s (%s)", _ACTION_BAR_LABELS[4], GetSpellInfo(24858));
			elseif (PLAYER_CLASS == "ROGUE") then
				_ACTION_BAR_LABELS[1] = format("%s (%s)", _ACTION_BAR_LABELS[1], GetSpellInfo(1784));
			end
		end
		return _ACTION_BAR_LABELS[index];
	end
end

local DROPDOWNLIST1                     = "L_DropDownList1";
local DROPDOWNLIST2                     = "L_DropDownList2";
local UIDropDownMenu_GetCurrentDropDown = GenerateClosure(LibDD.UIDropDownMenu_GetCurrentDropDown, LibDD);
local UIDropDownMenu_Initialize         = GenerateClosure(LibDD.UIDropDownMenu_Initialize, LibDD);
local UIDropDownMenu_CreateInfo         = GenerateClosure(LibDD.UIDropDownMenu_CreateInfo, LibDD);
local UIDropDownMenu_AddButton          = GenerateClosure(LibDD.UIDropDownMenu_AddButton, LibDD);
local UIDropDownMenu_AddSeparator       = GenerateClosure(LibDD.UIDropDownMenu_AddSeparator, LibDD);
local UIDropDownMenu_GetSelectedValue   = GenerateClosure(LibDD.UIDropDownMenu_GetSelectedValue, LibDD);
local UIDropDownMenu_SetSelectedValue   = GenerateClosure(LibDD.UIDropDownMenu_SetSelectedValue, LibDD);
local UIDropDownMenu_Refresh            = GenerateClosure(LibDD.UIDropDownMenu_Refresh, LibDD);
local UIDropDownMenu_RefreshAll         = GenerateClosure(LibDD.UIDropDownMenu_RefreshAll, LibDD);
local ToggleDropDownMenu                = GenerateClosure(LibDD.ToggleDropDownMenu, LibDD);
local CloseDropDownMenus                = GenerateClosure(LibDD.CloseDropDownMenus, LibDD);
local HideDropDownMenu                  = GenerateClosure(LibDD.HideDropDownMenu, LibDD);

local Create_UIDropDownMenu             = function(name, parent)
	return LibDD:Create_UIDropDownMenu(name, parent);
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

local function HideAnyDropDownMenu()
	local dropDownList = _G[DROPDOWNLIST1];
	if (dropDownList and dropDownList:IsShown()) then
		local dropdown = UIDropDownMenu_GetCurrentDropDown();
		if (dropdown == DebounceFrame.EditDropDown or dropdown == DebounceFrame.AddDropDown or dropdown == DebounceFrame.OptionsDropDown) then
			HideDropDownMenu(1);
			return true;
		end
	end
	return false;
end

local function IsEditingMacro(elementData)
	if (DebounceMacroFrame:IsShown() and (elementData == nil or DebounceMacroFrame.elementData == elementData)) then
		return true;
	elseif (DebounceIconSelectorFrame:IsShown() and (elementData == nil or DebounceIconSelectorFrame.elementData == elementData)) then
		return true;
	else --elseif (DebounceMacroFrame:IsShown() or DebounceIconSelectorFrame:IsShown()) then
		return false;
	end
end

local function IsEditDropdownShown(elementData)
	local dropDownList = _G[DROPDOWNLIST1];
	if (dropDownList and dropDownList:IsShown() and dropDownList.dropdown == DebounceFrame.EditDropDown) then
		if (elementData == nil or DebounceFrame.EditDropDown.elementData == elementData) then
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

local function GetActionTypeAndValueFromCursorInfo()
	local type, value;
	local cursorType, cursorInfo1, _, cursorInfo3 = GetCursorInfo();

	if (cursorType) then
		if (cursorType == "spell") then
			type, value = Constants.SPELL, cursorInfo3;
		elseif (cursorType == "macro") then
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
	local action = elementData.action;
	local type = action.type;
	local value = action.value;
	local skipTypeName;

	local actionName, actionIcon;
	if (type == Constants.SPELL) then
		local baseSpellID = FindBaseSpellByID(value) or value;
		local overrideID = FindSpellOverrideByID(baseSpellID);
		actionName, _, actionIcon = GetSpellInfo(overrideID);
	elseif (type == Constants.MACRO) then
		local macroName;
		macroName, actionIcon = GetMacroInfo(value);
		if (not macroName) then
			macroName = value;
			actionIcon = 134400;
		end
		actionName = macroName;
	elseif (type == Constants.MACROTEXT) then
		actionName = action.name;
		actionIcon = action.icon
	elseif (type == Constants.ITEM) then
		local name = C_Item.GetItemNameByID(value);
		local icon = C_Item.GetItemIconByID(value);
		actionName = name;
		actionIcon = icon;
	elseif (type == Constants.MOUNT) then
		local name, icon;
		if (value == 0 or value == 268435455) then
			name, _, icon = GetSpellInfo(150544);
		elseif (value) then
			name, _, icon = C_MountJournal.GetMountInfoByID(value);
		end
		actionName = name;
		actionIcon = icon;
	elseif (type == Constants.SETCUSTOM) then
		actionName = LLL["TYPE_SETCUSTOM" .. value];
		actionIcon = 1505950;
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
		actionIcon = action.icon or 134400;
	end

	if (not skipTypeName) then
		local typeName = BINDING_TYPE_NAMES[action.type]; -- rawget(LLL, action.type);
		if (typeName) then
			actionName = format(LLL["BINDING_TITLE"], typeName or "?", actionName or "?");
		end
	end
	actionName = actionName or "?";
	return actionName, actionIcon or 134400;
end

local function ColoredNameAndIconFromElementData(elementData, ignoreDisabled)
	local name, icon = NameAndIconFromElementData(elementData);
	local action = elementData.action;
	if (action.key == nil or DebouncePrivate.IsInactiveAction(action)) then
		name = DISABLED_FONT_COLOR:WrapTextInColorCode(name);
	elseif (DebouncePrivate.GetBindingIssue(action)) then
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

local ShowDeleteConfirmationPopup, HideDeleteConfirmationPopup, IsDeleteConfirmationPopupShown;
do
	local _deletePopupData;
	function ShowDeleteConfirmationPopup(elementData, closePopups)
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

	function IsDeleteConfirmationPopupShown()
		return StaticPopup_FindVisible("GENERIC_CONFIRMATION", _deletePopupData) ~= nil;
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
		GameTooltip:SetMinimumWidth(140, true);

		action = elementData.action;
		local isInactive = DebouncePrivate.IsInactiveAction(action);
		local hasIssues = not isInactive and DebouncePrivate.GetBindingIssue(action) ~= nil;

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
					error = hasIssues and DebouncePrivate.GetBindingIssue(action, "key") or nil;
				end
				addValueLine(keyText, error);
			else
				addValueLine(INACTIVE_COLOR:WrapTextInColorCode(LLL["NOT_BOUND"]));
			end
		end

		if (action.unit ~= nil) then
			addLabelLine(LLL["TARGET_UNIT"]);
			local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "unit");
			local unitStr = UNIT_INFOS[action.unit] and UNIT_INFOS[action.unit].name or LLL[action.unit];
			addValueLine(unitStr, error);
			if (action.unit ~= "" and action.unit ~= "none" and action.checkUnitExists) then
				addValueLine(LLL["ONLY_WHEN_UNIT_EXISTS_DESC"]);
			end
		end

		if (action.hover ~= nil) then
			addLabelLine(LLL["UNIT_FRAMES"]);
			local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "hover");
			if (action.hover) then
				wipe(_lines);
				local reactions = action.reactions or Constants.HOVER_ALL;
				local frameTypes = action.frameTypes or Constants.FRAMETYPE_ALL;

				local s;
				if (reactions == Constants.HOVER_ALL) then
					s = LLL["ALL"];
				else
					s = "";
					for i = 1, #UNIT_FRAME_REACTIONS do
						local flag = Constants["HOVER_" .. UNIT_FRAME_REACTIONS[i]];
						if (bit.band(reactions, flag) == flag) then
							if (s ~= "") then
								s = s .. ", ";
							end
							s = s .. LLL["REACTION_" .. UNIT_FRAME_REACTIONS[i]];
						end
					end
				end
				s = format("|cnWHITE_FONT_COLOR:%s:|r %s", LLL["REACTIONS"], s);
				tinsert(_lines, s);

				if (frameTypes == Constants.FRAMETYPE_ALL) then
					s = LLL["ALL"];
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
				s = format("|cnWHITE_FONT_COLOR:%s:|r %s", LLL["FRAME_TYPES"], s);
				tinsert(_lines, s);
				addValueLines(_lines, error, true);
			else
				addValueLine(LLL["WHEN_NOT_HOVERED"], error);
			end
		end

		if (action.groups ~= nil) then
			addLabelLine(LLL["GROUP"]);

			if (action.groups == 0) then
				addValueLine(LLL["NOT_SELECTED"], true);
			else
				wipe(_lines);
				for _, groupType in ipairs({ "NONE", "PARTY", "RAID" }) do
					local flag = Constants["GROUP_" .. groupType];
					if (bit.band(action.groups, flag) == flag) then
						tinsert(_lines, LLL["GROUP_" .. groupType]);
					end
				end
				local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "groups");
				addValueLines(_lines, error);
			end
		end

		if (action.combat ~= nil) then
			addLabelLine(LLL["COMBAT"]);
			local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "combat");
			addValueLine(action.combat == true and LLL["IN_COMBAT"] or LLL["NOT_IN_COMBAT"], error);
		end

		if (action.stealth ~= nil) then
			local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "stealth");
			addLabelLine(LLL["STEALTH"]);
			addValueLine(action.stealth == true and LLL["STEALTHED"] or LLL["NOT_STEALTHED"], error);
		end

		if (action.forms ~= nil) then
			addLabelLine(LLL["SHAPESHIFT"]);
			if (action.forms == 0) then
				addValueLine(LLL["NOT_SELECTED"], true);
			else
				wipe(_lines);
				local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "forms");
				for i = 0, 10 do
					local flag = 2 ^ i;
					if (bit.band(action.forms, flag) ~= 0) then
						if (i == 0) then
							tinsert(_lines, format("[form:%d] (%s)", i, LLL["NO_SHAPESHIFT"]));
						else
							local _, _, _, spellID = GetShapeshiftFormInfo(i);
							local spellName = spellID and GetSpellInfo(spellID);
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
			addLabelLine(LLL["ACTIONBARS"]);
			if (action.bonusbars == 0) then
				addValueLine(LLL["NOT_SELECTED"], true);
			else
				wipe(_lines);
				local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "bonusbars");
				for i = 0, MAX_ACTIONBAR_TYPE_INDEX do
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

		if (action.petbattle ~= nil) then
			local error = hasIssues and DebouncePrivate.GetBindingIssue(action, "petbattle");
			addLabelLine(LLL["PET_BATTLE"]);
			addValueLine(action.petbattle == true and LLL["IN_PET_BATTLE"] or LLL["NOT_IN_PET_BATTLE"], error);
		end

		if (action.priority and action.priority ~= Constants.DEFAULT_PRIORITY) then
			addLabelLine(LLL["PRIORITY"]);
			addValueLine(LLL["PRIORITY" .. action.priority]);
		end

		if (not isOverview) then
			GameTooltip_AddBlankLineToTooltip(GameTooltip);
			GameTooltip_AddInstructionLine(GameTooltip, LLL["TOOLTIP_INSTRUCTION_MESSAGE1"]);
			GameTooltip_AddInstructionLine(GameTooltip, LLL["TOOLTIP_INSTRUCTION_MESSAGE2"]);
			GameTooltip_AddInstructionLine(GameTooltip, LLL["TOOLTIP_INSTRUCTION_MESSAGE3"]);
		end

		GameTooltip:Show();
	end
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

	local isInactive = DebouncePrivate.IsInactiveAction(action);
	local issue = not isInactive and DebouncePrivate.GetBindingIssue(action) or nil;

	local name, icon = ColoredNameAndIconFromElementData(elementData);
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
		elseif (issue and DebouncePrivate.GetBindingIssue(action, "key")) then
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
		local s = format("@%s", UNIT_INFOS[action.unit] and UNIT_INFOS[action.unit].name or LLL[action.unit]);
		local color;
		if (isInactive) then
			color = INACTIVE_COLOR;
		elseif (issue and DebouncePrivate.GetBindingIssue(action, "unit")) then
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
		elseif (issue and DebouncePrivate.GetBindingIssue(action,
				"hover",
				"groups",
				"forms",
				"bonusbars",
				"combat",
				"stealth")
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
end

function DebounceLineMixin:OnEnter()
	ShowLineTooltip(self, "ANCHOR_RIGHT", self:GetElementData(), false);
end

function DebounceLineMixin:OnLeave()
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
		if (DebouncePrivate.DEBUG and IsControlKeyDown()) then
			if (IsEditingMacro(elementData)) then
				return;
			end
			if (IsKeybindFrameShown(elementData)) then
				return;
			end
			if (IsEditDropdownShown(elementData)) then
				HideAnyDropDownMenu();
			end
			if (IsAltKeyDown() or IsShiftKeyDown()) then
				DeleteElementData(elementData);
			else
				ShowDeleteConfirmationPopup(elementData);
			end
		else
			if (DebounceKeybindFrame:HasChanges()) then
				DebouncePrivate.DisplayMessage(LLL["CONFIRM_CURRENT_CHANGE_FIRST"]);
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

	if (DebounceKeybindFrame:HasChanges()) then
		DebouncePrivate.DisplayMessage(LLL["CONFIRM_CURRENT_CHANGE_FIRST"]);
		return;
	end

	DebounceKeybindFrame:Open(elementData);
end

function DebounceLineMixin:OnDragStart()
	DebounceFrame:StartDragging(self:GetElementData());
end

function DebounceLineMixin:OnDragStop()
end

function DebounceLineMixin:OnReceiveDrag()
	DebounceFrame:OnReceiveDrag();
end

DebounceTabMixin = {};

function DebounceTabMixin:OnClick()
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
	local currentTab = _selectedTab;
	local id = self:GetID();
	local text = GetTabLabel(id);

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:SetText(text);
	GameTooltip:Show();

	if (id ~= currentTab and (IsDraggingElement() or GetActionTypeAndValueFromCursorInfo())) then
		self:OnClick();
	end
end

function DebounceTabMixin:OnLeave()
	GameTooltip:Hide();
end

DebounceSideTabMixin = {};

function DebounceSideTabMixin:OnClick()
	if (DebounceKeybindFrame:IsShown() or DebounceIconSelectorFrame:IsShown() or DebounceMacroFrame:IsShown()) then
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
	local currentTab = _selectedSideTab;
	local id = self:GetID();
	local text = GetSideTabaLabel(id);

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	if (self.isOffSpec) then
		GameTooltip:SetText(format(LLL["INACTIVE_SPEC_LABEL"], text));
	else
		GameTooltip:SetText(text);
	end
	GameTooltip:Show();

	if (id ~= currentTab and (IsDraggingElement() or GetActionTypeAndValueFromCursorInfo())) then
		self:OnClick();
	end
end

function DebounceSideTabMixin:OnLeave()
	GameTooltip:Hide();
end

function DebounceSideTabMixin:OnEnable()
	self:GetNormalTexture():SetDesaturated(self.isOffSpec);
end

function DebounceSideTabMixin:OnDisable()
	self:GetNormalTexture():SetDesaturated(true);
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
			name, icon = GetSpellTabInfo(1);
			tab.spec = nil;
		elseif (i == 2) then
			name, icon = GetSpellTabInfo(2);
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

	self.ScrollBox.EmptyText:SetText(LLL["NO_ACTIONS_IN_THIS_TAB"]);
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

		local isOffSpec, shouldHide;
		if (tabID == 2 and _selectedTab == 2) then
			tab:Hide();
		else
			tab.isOffSpec = tabID > 2 and currentSpec ~= (tabID - 2);
			tab:GetNormalTexture():SetDesaturated(tab.isOffSpec);
			tab:SetChecked(_selectedSideTab == tabID);
			if (prevTab) then
				if (tab.isOffSpec and not prevTab.isOffSpec) then
					tab:SetPoint("TOPLEFT", prevTab, "BOTTOMLEFT", 0, -40);
				else
					tab:SetPoint("TOPLEFT", prevTab, "BOTTOMLEFT", 0, -17);
				end
			end
			tab:Show();
			prevTab = tab;
		end
	end
end

do
	local SCROLL_DELAY = 0.1;
	local ELEMENT_PADDING = 40;
	local _lastScrollTime = 0;
	local _lastCursorY = 0;

	function DebounceFrameMixin:UpdatePlaceholderPosition()
		local _, cursorY = GetScaledCursorPosition();
		if ((GetTime() - _lastScrollTime) > SCROLL_DELAY or abs(cursorY - _lastCursorY) > ELEMENT_PADDING) then
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
								pos = frameElementData.index + 1;
							else
								pos = frameElementData.index;
							end
							break;
						end
					else
						if (frameElementData ~= _placeholder) then
							pos = frameElementData.index + 1;
						end
					end
				end
			end


			pos = pos - 0.5;
			if (not _placeholder.sortIndex or _placeholder.sortIndex ~= pos) then
				_placeholder.sortIndex = pos;
				self.dataProvider:Sort();

				local dataIndex = self.ScrollBox:FindIndex(_placeholder);
				local elementExtent = self.ScrollBox:GetElementExtent(dataIndex);
				local elementOffset = self.ScrollBox:GetExtentUntil(dataIndex);
				local visibleExtent = self.ScrollBox:GetVisibleExtent();
				local scrollOffset = self.ScrollBox:GetDerivedScrollOffset();

				local offsetInView = elementOffset - scrollOffset;
				if (offsetInView + elementExtent + ELEMENT_PADDING > visibleExtent) then
					self.ScrollBox:ScrollToOffset(elementOffset, elementExtent + ELEMENT_PADDING, ScrollBoxConstants.AlignEnd);
					_lastScrollTime = GetTime();
				elseif (offsetInView < ELEMENT_PADDING) then
					self.ScrollBox:ScrollToOffset(elementOffset - ELEMENT_PADDING, 0, 0);
					_lastScrollTime = GetTime();
				end
			end
		end
	end
end

function DebounceFrameMixin:OnUpdate(elapsed)
	local scrollBox = self.ScrollBox;
	local isMouseOver = scrollBox:IsMouseOver();

	if (IsDraggingElement()) then
		if (isMouseOver) then
			if (not _placeholder) then
				_placeholder = _draggingElement;
				_placeholder.sortIndex = _placeholder.sortIndex or _placeholder.index;
				if (not self.dataProvider:FindIndex(_placeholder)) then
					self.dataProvider:Insert(_placeholder);
					if (self.dataProvider:GetSize() == 1) then
						self:Update();
					end
				end
			end
		else
			if (_placeholder) then
				if (_placeholder.layer == GetLayerID()) then
					_placeholder.sortIndex = _placeholder.index;
					self.dataProvider:Sort();
				else
					self.dataProvider:Remove(_placeholder);
					if (_placeholder) then
						_placeholder.sortIndex = nil;
						_placeholder = nil;
					end
					if (self.dataProvider:GetSize() == 0) then
						self:Update();
					end
				end
			end
		end
	else
		local type, value = GetActionTypeAndValueFromCursorInfo();
		if (not type) then
			self:SetScript("OnUpdate", nil);
			return;
		end

		if (isMouseOver) then
			if (not _placeholder) then
				_placeholder = { action = { type = type, value = value }, sortIndex = 0 };
				self.dataProvider:Insert(_placeholder);
				if (self.dataProvider:GetSize() == 1) then
					self:Update();
				end
			end
		else
			if (_placeholder) then
				self.dataProvider:Remove(_placeholder);
				_placeholder = nil;
				if (self.dataProvider:GetSize() == 0) then
					self:Update();
				end
			end
		end
	end

	if (_placeholder and isMouseOver) then
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
	local bottomPadding = 53;
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
	self.AddButton:SetScript("OnClick", function(button)
		HideDeleteConfirmationPopup();
		ToggleDropDownMenu(1, "root", self.AddDropDown, "cursor", 20, 15);
	end);

	self.OptionsButton:SetScript("OnClick", function(button)
		HideDeleteConfirmationPopup();
		ToggleDropDownMenu(1, "root", self.OptionsDropDown, "cursor", 20, 15);
	end);

	self.OverviewButton:SetScript("OnClick", function(button)
		DebounceOverviewFrame:Toggle();
	end);
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

	self.AddButton:SetText(LLL["ADD"]);
	self.OverviewButton:SetText(LLL["OVERVIEW"]);
	self.OptionsButton:SetText(LLL["OPTIONS"]);

	self.AddDropDown = Create_UIDropDownMenu("DebounceAddDropDown", self);
	self.EditDropDown = Create_UIDropDownMenu("DebounceEditDropDown", self);
	self.OptionsDropDown = Create_UIDropDownMenu("DebounceOptionsDropDown", self);

	UIDropDownMenu_Initialize(self.AddDropDown, self.AddDropDown_Initialize, "MENU");
	UIDropDownMenu_Initialize(self.OptionsDropDown, self.OptionsDropDown_Initialize, "MENU");

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
end

function DebounceFrameMixin:OnEvent(event, arg1)
	if (event == "GLOBAL_MOUSE_UP") then
		if (arg1 == "LeftButton" and IsDraggingElement()) then
			local mouseFocus = GetMouseFocus();
			if (_placeholder and DoesAncestryInclude(self.ScrollBox, mouseFocus)) then
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

		if (HideAnyDropDownMenu()) then
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

	local dataProvider = CreateDataProvider();
	local layerID = GetLayerID();
	local layer = DebouncePrivate.GetProfileLayer(GetLayerID());
	for i, action in layer:Enumerate() do
		local elementData;
		if (_draggingElement and _draggingElement.layer == layerID and _draggingElement.action == action) then
			elementData = _draggingElement;
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
	self.ScrollBox.EmptyText:SetShown(self.dataProvider:GetSize() == 0);
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

	self.ScrollBox.EmptyText:SetShown(self.dataProvider:GetSize() == 0);
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

	self.AddButton:SetEnabled(enableButtons);
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

local function setEnableDropdownButton(button, enabled)
	if (enabled) then
		button:SetEnabled(true);
		button.Check:SetDesaturated(false);
		button.Check:SetAlpha(1);
		button.UnCheck:SetDesaturated(false);
		button.UnCheck:SetAlpha(1);
	else
		button:SetEnabled(false);
		button.Check:SetDesaturated(true);
		button.Check:SetAlpha(0.5);
		button.UnCheck:SetDesaturated(true);
		button.UnCheck:SetAlpha(0.5);
	end
end

local function updateDropdownButtons()
	if (L_UIDROPDOWNMENU_MENU_VALUE == "hover") then
		local listFrame;
		listFrame = _G[DROPDOWNLIST2];
		if (listFrame:IsShown()) then
			local action = listFrame.dropdown.elementData.action;
			local disabled = not action.hover;
			for index = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
				local button = _G[DROPDOWNLIST2 .. "Button" .. index];
				if (not button or not button:IsShown()) then
					break;
				end
				if (button.value == "reactions" or button.value == "frameTypes" or button.value == "ignoreHoverUnit") then
					setEnableDropdownButton(button, not disabled);
				end
			end
		end
	elseif (L_UIDROPDOWNMENU_MENU_VALUE == "bonusbars") then
	end
end

local BuildCommandDropdownList;
do
	local commandList;
	local function BuildCommandList()
		local bindingsCategories = {};
		local nextOrder = 1;
		local function AddBindingCategory(key)
			if not bindingsCategories[key] then
				bindingsCategories[key] = { order = nextOrder, bindings = {} };
				nextOrder = nextOrder + 1;
			end
		end

		AddBindingCategory(BINDING_HEADER_MOVEMENT);
		AddBindingCategory(BINDING_HEADER_INTERFACE);
		-- AddBindingCategory(BINDING_HEADER_ACTIONBAR);
		-- AddBindingCategory(BINDING_HEADER_MULTIACTIONBAR);
		AddBindingCategory(BINDING_HEADER_CHAT);
		AddBindingCategory(BINDING_HEADER_TARGETING);
		AddBindingCategory(BINDING_HEADER_RAID_TARGET);
		AddBindingCategory(BINDING_HEADER_VEHICLE);
		AddBindingCategory(BINDING_HEADER_CAMERA);
		AddBindingCategory(BINDING_HEADER_MISC);
		AddBindingCategory(BINDING_HEADER_OTHER);

		local ignoredCategories = {
			-- BINDING_HEADER_ACTIONBAR = true,
			-- BINDING_HEADER_ACTIONBAR2 = true,
			-- BINDING_HEADER_ACTIONBAR3 = true,
			-- BINDING_HEADER_ACTIONBAR4 = true,
			-- BINDING_HEADER_ACTIONBAR5 = true,
			-- BINDING_HEADER_ACTIONBAR6 = true,
			-- BINDING_HEADER_ACTIONBAR7 = true,
			-- BINDING_HEADER_ACTIONBAR8 = true,
			-- BINDING_HEADER_MULTIACTIONBAR = true,
		};

		for bindingIndex = 1, GetNumBindings() do
			local action, cat = GetBinding(bindingIndex);
			if not cat then
				tinsert(bindingsCategories[BINDING_HEADER_OTHER].bindings, { bindingIndex, action, _G["BINDING_NAME_" .. action] });
			else
				if (not ignoredCategories[cat] and cat ~= "ADDONS") then
					cat = _G[cat] or cat;
					AddBindingCategory(cat);
					if strsub(action, 1, 6) == "HEADER" then
						--tinsert(bindingsCategories[cat].bindings, KeybindingSpacer);
					else
						tinsert(bindingsCategories[cat].bindings, { bindingIndex, action, _G["BINDING_NAME_" .. action] });
					end
				end
			end
		end

		local sortedCategories = {};
		for cat, bindingCategory in pairs(bindingsCategories) do
			sortedCategories[bindingCategory.order] = { cat = cat, bindings = bindingCategory.bindings };
		end

		commandList = sortedCategories;
		dump("commandList", commandList)
	end

	function BuildCommandDropdownList(level, menuList)
		if (not commandList) then
			BuildCommandList();
		end

		local info = UIDropDownMenu_CreateInfo();
		info.tooltipOnButton = 1;
		info.notCheckable = 1;

		if (level == 2) then
			-- build category list
			info.menuList = "command";
			info.hasArrow = true;
			for categoryIndex = 1, #commandList do
				if (#commandList[categoryIndex].bindings > 0) then
					info.text = commandList[categoryIndex].cat;
					info.value = categoryIndex;
					UIDropDownMenu_AddButton(info, level);
				end
			end
		elseif (level >= 3) then
			local categoryIndex, page = L_UIDROPDOWNMENU_MENU_VALUE, nil;
			if (categoryIndex > 1000) then
				page = categoryIndex % 1000;
				categoryIndex = floor(categoryIndex / 1000);
			end
			local category = commandList[categoryIndex];
			if (page or #category.bindings < 20) then
				local start = ((page or 1) - 1) * 20;
				info.hasArrow = false;
				for i = 1, 20 do
					if (not category.bindings[i + start]) then
						break;
					end
					local command = category.bindings[i + start][2];
					local name = _G["BINDING_NAME_" .. command] or command;
					info.text = name;
					info.func = function()
						DebounceFrame:AddNewAction(Constants.COMMAND, command);
						HideAnyDropDownMenu();
					end
					UIDropDownMenu_AddButton(info, level);
				end
			else
				local n = ceil(#category.bindings / 20);
				for i = 1, n do
					info.text = format(LLL["BINDING_COMMAND_PAGE_FORMAT"], i, n);
					info.menuList = "command";
					info.value = categoryIndex * 1000 + i;
					info.hasArrow = true;
					UIDropDownMenu_AddButton(info, level);
				end
			end
		end
	end
end

function DebounceFrameMixin.AddDropDown_Initialize(self, level, menuList)
	if (menuList == "command") then
		BuildCommandDropdownList(level, menuList);
		return;
	end

	local info = UIDropDownMenu_CreateInfo();
	info.tooltipOnButton = 1;
	info.notCheckable = 1;

	if (level == 1) then
		info.text = BINDING_TYPE_NAMES[Constants.MACROTEXT];
		info.func = function()
			DebounceIconSelectorFrame.mode = IconSelectorPopupFrameModes.New;
			DebounceIconSelectorFrame:Show();
		end
		UIDropDownMenu_AddButton(info, level);

		info.text = BINDING_TYPE_NAMES[Constants.SETCUSTOM];
		info.menuList = "custom";
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, level);

		info.text = BINDING_TYPE_NAMES[Constants.WORLDMARKER];
		info.menuList = "worldmarker";
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, level);

		info.text = BINDING_TYPE_NAMES[Constants.COMMAND];
		info.menuList = "command";
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["MISC"];
		info.menuList = "misc";
		info.hasArrow = true;
		UIDropDownMenu_AddButton(info, level);
	elseif (level == 2) then
		if (menuList == "custom") then
			info.tooltipTitle = LLL["TYPE_SETCUSTOM_DESC"];
			for i = 1, 2 do
				info.text = LLL["TYPE_SETCUSTOM" .. i] .. LLL["_HAS_TOOLTIP_SUFFIX"];
				info.func = function()
					DebounceFrame:AddNewAction(Constants.SETCUSTOM, i);
					HideAnyDropDownMenu();
				end
				UIDropDownMenu_AddButton(info, level);
			end
		elseif (menuList == "worldmarker") then
			for i = 1, NUM_WORLD_RAID_MARKERS do
				local index = WORLD_RAID_MARKER_ORDER[i];
				info.text = _G["WORLD_MARKER" .. index];
				info.func = function()
					DebounceFrame:AddNewAction(Constants.WORLDMARKER, index);
					HideAnyDropDownMenu();
				end;
				UIDropDownMenu_AddButton(info, level);
			end
		elseif (menuList == "misc") then
			info.text = BINDING_TYPE_NAMES[Constants.TARGET];
			info.menuList = "target";
			info.value = Constants.TARGET;
			info.hasArrow = true;
			UIDropDownMenu_AddButton(info, level);

			info.text = BINDING_TYPE_NAMES[Constants.FOCUS];
			info.menuList = "focus";
			info.value = Constants.FOCUS;
			info.hasArrow = true;
			UIDropDownMenu_AddButton(info, level);

			info.text = BINDING_TYPE_NAMES[Constants.TOGGLEMENU];
			info.menuList = "togglemenu";
			info.value = Constants.TOGGLEMENU;
			info.hasArrow = true;
			UIDropDownMenu_AddButton(info, level);

			info.text = BINDING_TYPE_NAMES[Constants.UNUSED] .. LLL["_HAS_TOOLTIP_SUFFIX"];
			info.menuList = nil;
			info.value = nil;
			info.hasArrow = nil;
			info.tooltipTitle = LLL["TYPE_UNUSED_DESC"];
			info.func = function()
				DebounceFrame:AddNewAction(Constants.UNUSED);
				HideAnyDropDownMenu();
			end
			UIDropDownMenu_AddButton(info, level);
			info.tooltipTitle = nil;
		end
	elseif (level == 3) then
		if (menuList == "target" or menuList == "focus" or menuList == "togglemenu") then
			local actionType = L_UIDROPDOWNMENU_MENU_VALUE;
			for _, unit in ipairs(SORTED_UNIT_LIST) do
				local unitInfo = UNIT_INFOS[unit];
				if (unitInfo[menuList] ~= false) then
					info.text = unitInfo.name;
					info.tooltipTitle = unitInfo.tooltipTitle;
					info.tooltipWarning = unitInfo.tooltipWarning;
					if (info.tooltipTitle) then
						info.text = info.text .. LLL["_HAS_TOOLTIP_SUFFIX"];
					end

					info.func = function()
						DebounceFrame:AddNewAction(actionType, nil, nil, nil, { unit = unit });
						HideAnyDropDownMenu();
					end
					UIDropDownMenu_AddButton(info, level);
				end
			end
		end
	end
end

function DebounceFrameMixin.OptionsDropDown_Initialize(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo();
	info.tooltipOnButton = 1;

	if (level == 1) then
		info.text = LLL["BLIZZARD_UNIT_FRAMES"];
		info.menuList = "blizzframes"
		info.notCheckable = 1;
		info.hasArrow = true;
		info.tooltipTitle = "";
		info.tooltipWarning = LLL["BINDING_ERROR_CANNOT_USE_HOVER_WITH_CLIQUE"];
		UIDropDownMenu_AddButton(info, level);
		info.tooltipTitle = nil;
		info.tooltipWarning = nil;
	elseif (level == 2) then
		if (menuList == "blizzframes") then
			info.menuList = nil;
			info.notCheckable = nil;
			info.hasArrow = nil;
			info.isNotRadio = true;
			info.keepShownOnClick = true;

			for i, frameType in ipairs(BLIZZARD_UNITFRAMES) do
				info.text = LLL["BLIZZARD_UNIT_FRAMES_" .. strupper(frameType)];
				info.checked = function()
					return DebouncePrivate.Options.blizzframes[frameType] ~= false
				end
				info.func = function(_, _, _, checked)
					local val;
					if (checked) then
						val = nil;
					else
						val = false;
					end
					DebouncePrivate.Options.blizzframes[frameType] = val;
					DebouncePrivate.UpdateBlizzardFrames();
				end
				UIDropDownMenu_AddButton(info, level);
			end

			-- info.text = "PlayerFrame"
			-- info.checked = function() return DebouncePrivate.Options.blizzframes["PlayerFrame"] ~= false end
			-- info.func = function(_, _, _, checked)
			-- 	if (checked) then
			-- 		DebouncePrivate.Options.blizzframes["PlayerFrame"] = nil;
			-- 		DebouncePrivate.RegisterFrame(PlayerFrame)
			-- 	else
			-- 		DebouncePrivate.Options.blizzframes["PlayerFrame"] = false;
			-- 		DebouncePrivate.UnregisterFrame(PlayerFrame)
			-- 	end
			-- end
		end
	elseif (level == 3) then
		if (menuList == "types") then
			-- print("L_UIDROPDOWNMENU_MENU_VALUE", L_UIDROPDOWNMENU_MENU_VALUE)
			-- local types = SORTED_BLIZZARD_UNITFRAMES[L_UIDROPDOWNMENU_MENU_VALUE][3];
			-- for _, type in ipairs(types) do
			-- 	info.menuList = nil;
			-- 	info.notCheckable = nil;
			-- 	info.hasArrow = nil;
			-- 	info.isNotRadio = nil;
			-- 	info.keepShownOnClick = true;
			-- 	info.text = type;
			-- 	UIDropDownMenu_AddButton(info, level);
			-- end
		end
	end
end

local function EditDropDown_Initialize(dropdown, level, menuList)
	local elementData = dropdown.elementData;
	if (not elementData) then
		return;
	end

	local action = elementData.action;
	local name = NameAndIconFromElementData(elementData);

	local info = UIDropDownMenu_CreateInfo();
	info.arg1 = action;
	info.tooltipOnButton = 1;

	if (level == 1) then
		info.text = name;
		info.isTitle = true;
		info.notCheckable = 1;
		UIDropDownMenu_AddButton(info, level);
		info.isTitle = nil;

		if (action.type == Constants.MACROTEXT) then
			info.text = LLL["EDIT_MACRO"];
			info.notCheckable = 1;
			info.disabled = nil;
			info.func = function()
				DebounceMacroFrame:ShowEdit(elementData);
			end
			UIDropDownMenu_AddButton(info, level);
		end

		if (DebouncePrivate.CanConvertToMacroText(action)) then
			info.text = LLL["CONVERT_TO_MACRO_TEXT"];
			info.notCheckable = 1;
			info.disabled = nil;
			info.func = function()
				local original = CopyTable(action);
				if (DebouncePrivate.ConvertToMacroText(action)) then
					DebouncePrivate.UpdateBindings();
					local cancelFunc = function()
						wipe(elementData.action);
						MergeTable(elementData.action, original);
						DebouncePrivate.UpdateBindings();
						--DebounceFrame:Update();
					end
					DebounceMacroFrame:ShowEdit(elementData, cancelFunc);
				end
			end
			UIDropDownMenu_AddButton(info, level);
		end

		info.text = LLL["UNBIND"];
		info.notCheckable = 1;
		info.disabled = action.key == nil;
		info.func = function()
			action.key = nil;
			DebouncePrivate.UpdateBindings();
			--DebounceFrame:Update();
		end
		UIDropDownMenu_AddButton(info, level);
		info.disabled = nil;

		if (action.type == Constants.SPELL or action.type == Constants.ITEM or action.type == Constants.TARGET or action.type == Constants.FOCUS or action.type == Constants.TOGGLEMENU) then
			info.text = LLL["TARGET_UNIT"] .. LLL["_HAS_TOOLTIP_SUFFIX"];
			--info.disabled = (action.hover and true) or nil;
			info.disabled = nil;
			info.hasArrow = true;
			info.menuList = "unit";
			info.value = "unit";
			info.notCheckable = 1;
			info.tooltipTitle = LLL["TARGET_DESC"];
			UIDropDownMenu_AddButton(info, level);
		end

		info.disabled = nil;
		info.value = nil;
		info.tooltipTitle = nil;
		info.tooltipText = nil;
		info.tooltipInstruction = nil;
		info.tooltipWarning = nil;
		info.tooltipWhileDisabled = nil;

		UIDropDownMenu_AddSeparator(level);

		info.text = LLL["SPECIAL_CONDITIONS"];
		info.isTitle = true;
		info.hasArrow = nil;
		UIDropDownMenu_AddButton(info, level);

		info.isTitle = nil;
		info.notCheckable = nil;
		--info.isUninteractable = nil;
		info.disabled = nil;
		info.notCheckable = 1;

		if (action.type ~= Constants.SETCUSTOM) then
			info.text = LLL["UNIT_FRAMES"] .. LLL["_HAS_TOOLTIP_SUFFIX"];
			info.hasArrow = true;
			info.notCheckable = 1;
			info.menuList = "hover";
			info.value = "hover";
			info.tooltipTitle = LLL["UNIT_FRAMES"]
			info.tooltipText = LLL["HOVER_OVER_UNIT_FRAMES_DESC"];
			if (DebouncePrivate.CliqueDetected) then
				info.tooltipWarning = LLL["HOVER_OVER_UNIT_FRAMES_CLIQUE_WARNING"];
			end
			UIDropDownMenu_AddButton(info, level);
			info.tooltipTitle = nil;
			info.tooltipText = nil;
			info.value = nil;
		end

		info.text = LLL["GROUP"];
		info.hasArrow = true;
		info.menuList = "group";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["COMBAT"];
		info.hasArrow = true;
		info.menuList = "combat";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["STEALTH"];
		info.hasArrow = true;
		info.menuList = "stealth";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["SHAPESHIFT"];
		info.hasArrow = true;
		info.menuList = "shapeshift";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["ACTIONBARS"];
		info.hasArrow = true;
		info.menuList = "actionbars";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["PET"];
		info.hasArrow = true;
		info.menuList = "pet";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["MISC"];
		info.hasArrow = true;
		info.menuList = "misc";
		UIDropDownMenu_AddButton(info, level);

		-- UIDropDownMenu_AddSeparator(level);

		-- info.text = L["TALENT_LOADOUTS"];
		-- info.hasArrow = true;
		-- info.menuList = "loadouts";
		-- UIDropDownMenu_AddButton(info, level);

		-- info.text = "Custom Conditionals";
		-- info.hasArrow = nil;
		-- info.menuList = nil;
		-- info.func = function()
		-- 	print("show edit box")
		-- end
		-- UIDropDownMenu_AddButton(info, level);

		UIDropDownMenu_AddSeparator(level);

		info.text = LLL["PRIORITY"]
		info.hasArrow = true;
		info.menuList = "priority";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["MOVE_TO"]
		info.hasArrow = true;
		info.menuList = "move";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["COPY_TO"]
		info.hasArrow = true;
		info.menuList = "copy";
		UIDropDownMenu_AddButton(info, level);

		info.text = LLL["DELETE"];
		info.hasArrow = nil;
		info.menuList = nil;
		info.func = function()
			ShowDeleteConfirmationPopup(elementData);
		end
		UIDropDownMenu_AddButton(info, level);
	elseif (level == 2) then
		if (menuList == "unit") then
			info.hasArrow = nil;
			info.menuList = nil;
			info.notCheckable = nil;
			if (action.type == Constants.TARGET or action.type == Constants.FOCUS or action.type == Constants.TOGGLEMENU) then

			else
				info.text = LLL["UNIT_DISABLE"];
				info.checked = action.unit == nil;
				info.func = function()
					action.unit = nil;
					DebouncePrivate.UpdateBindings();
					--DebounceFrame:Update();
				end
				UIDropDownMenu_AddButton(info, level);
			end

			for _, unit in ipairs(SORTED_UNIT_LIST) do
				local unitInfo = UNIT_INFOS[unit];
				if (unitInfo[action.type] ~= false) then
					info.text = unitInfo.name .. (unitInfo.tooltipTitle and LLL["_HAS_TOOLTIP_SUFFIX"] or "");
					info.tooltipTitle = unitInfo.tooltipTitle;
					info.checked = action.unit == unit;
					info.func = function()
						action.unit = unit;
						DebouncePrivate.UpdateBindings();
						--DebounceFrame:Update();
					end
					UIDropDownMenu_AddButton(info, level);
				end
			end
			info.tooltipTitle = nil;
			info.tooltipInstruction = nil;
			info.tooltipWarning = nil;
			info.tooltipWhileDisabled = nil;

			UIDropDownMenu_AddSeparator(level);

			info.isNotRadio = true;
			info.keepShownOnClick = true;
			info.disabled = action.unit == nil or action.unit == "none";
			info.text = LLL["ONLY_WHEN_UNIT_EXISTS"];
			info.checked = action.checkUnitExists;
			info.func = function(_, _, _, checked)
				action.checkUnitExists = checked or nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.isNotRadio = nil;
			info.keepShownOnClick = nil;
			info.disabled = nil;
		elseif (menuList == "hover") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;
			info.keepShownOnClick = true;

			local FRAMETYPE_MASK = Constants.FRAMETYPE_ALL;
			info.text = LLL["DISABLE"];
			info.checked = function() return action.hover == nil end;
			info.func = function()
				action.hover = nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
				UIDropDownMenu_Refresh(dropdown);
				updateDropdownButtons();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["WHEN_HOVERED"];
			info.checked = function() return action.hover == true end;
			info.func = function()
				action.hover = true;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
				UIDropDownMenu_Refresh(dropdown);
				updateDropdownButtons();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["WHEN_NOT_HOVERED"];
			info.checked = function() return action.hover == false end;
			info.func = function()
				action.hover = false;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
				UIDropDownMenu_Refresh(dropdown);
				updateDropdownButtons();
			end
			UIDropDownMenu_AddButton(info, level);

			UIDropDownMenu_AddSeparator(level);

			info.isTitle = true;
			info.notCheckable = 1;
			info.notClickable = true;
			info.text = LLL["REACTIONS"];
			UIDropDownMenu_AddButton(info, level);
			info.isTitle = nil;
			info.notCheckable = nil;
			info.notClickable = nil;

			info.isNotRadio = true;
			info.value = "reactions";
			info.disabled = not action.hover;

			for _, reaction in ipairs(UNIT_FRAME_REACTIONS) do
				local flag = Constants["HOVER_" .. reaction];
				info.text = LLL["REACTION_" .. reaction];
				info.checked = function() return bit.band(action.reactions or Constants.HOVER_ALL, flag) == flag end;
				info.func = function(_, _, _, checked)
					if (checked) then
						action.reactions = bit.bor(action.reactions or Constants.HOVER_ALL, flag);
					else
						action.reactions = bit.band(action.reactions or Constants.HOVER_ALL, bit.bnot(flag));
					end
					if (action.reactions == Constants.HOVER_ALL) then
						action.reactions = nil;
					end
					DebouncePrivate.UpdateBindings();
					UIDropDownMenu_Refresh(dropdown);
					updateDropdownButtons();
				end
				UIDropDownMenu_AddButton(info, level);
			end

			-- for _, item in ipairs(REACTIONS) do
			-- 	info.text = item[1];
			-- 	info.checked = function() return bit.band(action.reactions or Constants.HOVER_ALL, item[2]) == item[2] end;
			-- 	info.func = function(_, _, _, checked)
			-- 		if (checked) then
			-- 			action.reactions = bit.bor(action.reactions or Constants.HOVER_ALL, item[2]);
			-- 		else
			-- 			action.reactions = bit.band(action.reactions or Constants.HOVER_ALL, bit.bnot(item[2]));
			-- 		end
			-- 		if (action.reactions == Constants.HOVER_ALL) then
			-- 			action.reactions = nil;
			-- 		end
			-- 		DebouncePrivate.UpdateBindings();
			-- 		UIDropDownMenu_Refresh(dropdown);
			-- 		updateDropdownButtons();
			-- 	end
			-- 	UIDropDownMenu_AddButton(info, level);
			-- end
			info.value = nil;

			-- hover true help harm false nil
			-- frameTypes nil (any)
			--            0 none
			--            flags ...

			UIDropDownMenu_AddSeparator(level);

			info.isTitle = true;
			info.notCheckable = 1;
			info.notClickable = true;
			info.text = LLL["FRAME_TYPES"];
			UIDropDownMenu_AddButton(info, level);
			info.isTitle = nil;
			info.notCheckable = nil;
			info.notClickable = nil;

			info.isNotRadio = nil;
			info.leftPadding = nil;

			info.isNotRadio = true;
			info.disabled = not action.hover;
			info.value = "frameTypes";

			for i = 1, #UNIT_FRAME_TYPES do
				local frameType = UNIT_FRAME_TYPES[i];
				local flag = Constants["FRAMETYPE_" .. frameType];
				info.text = LLL["FRAMETYPE_" .. frameType];
				info.checked = function() return action.frameTypes == nil or bit.band(action.frameTypes, flag) == flag end
				info.func = function(_, _, _, checked)
					if (checked) then
						action.frameTypes = bit.bor(action.frameTypes or FRAMETYPE_MASK, flag);
					else
						action.frameTypes = bit.band(action.frameTypes or FRAMETYPE_MASK, bit.bnot(flag));
					end
					if (action.frameTypes == FRAMETYPE_MASK) then
						action.frameTypes = nil;
					end
					UIDropDownMenu_Refresh(dropdown);
					DebouncePrivate.UpdateBindings();
					--DebounceFrame:Update();
					updateDropdownButtons();
				end
				UIDropDownMenu_AddButton(info, level);
			end
			-- info.disabled = nil;

			UIDropDownMenu_AddSeparator(level);

			info.disabled = not action.hover;
			info.text = LLL["IGNORE_HOVER_UNIT"] .. LLL["_HAS_TOOLTIP_SUFFIX"];
			info.value = "ignoreHoverUnit";
			info.tooltipTitle = LLL["IGNORE_HOVER_UNIT_TIP"]
			info.checked = function() return action.ignoreHoverUnit end
			info.func = function(_, _, _, checked)
				action.ignoreHoverUnit = checked or nil;
				DebouncePrivate.UpdateBindings();
				updateDropdownButtons();
				UIDropDownMenu_Refresh(dropdown);
			end
			UIDropDownMenu_AddButton(info, level);
			info.tooltipTitle = nil;

			info.isNotRadio = nil;
			info.keepShownOnClick = nil;
			info.value = nil;
		elseif (menuList == "group") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;
			info.keepShownOnClick = true;

			info.text = LLL["DISABLE"];
			info.checked = function() return action.groups == nil end
			info.func = function()
				action.groups = nil;
				DebouncePrivate.UpdateBindings();
				UIDropDownMenu_Refresh(dropdown);
				updateDropdownButtons();
			end
			UIDropDownMenu_AddButton(info, level);

			info.isNotRadio = true;
			info.keepShownOnClick = true;

			for _, groupType in ipairs({ "NONE", "PARTY", "RAID" }) do
				local flag = Constants["GROUP_" .. groupType];
				info.text = LLL["GROUP_" .. groupType];
				info.checked = function()
					return action.groups and bit.band(action.groups, flag) == flag;
				end
				info.func = function(_, _, _, checked)
					if (checked) then
						action.groups = bit.bor(action.groups or 0, flag);
					else
						action.groups = bit.band(action.groups or 0, bit.bnot(flag));
					end
					-- if (action.groups == 0) then
					-- 	action.groups = nil;
					-- end
					UIDropDownMenu_Refresh(dropdown);
					DebouncePrivate.UpdateBindings();
				end
				UIDropDownMenu_AddButton(info, level);
			end
		elseif (menuList == "combat") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;

			info.text = LLL["DISABLE"];
			info.checked = action.combat == nil;
			info.func = function()
				action.combat = nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
				updateDropdownButtons();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["IN_COMBAT"];
			info.checked = action.combat == true;
			info.func = function()
				action.combat = true;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
				updateDropdownButtons();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["NOT_IN_COMBAT"];
			info.checked = action.combat == false;
			info.func = function()
				action.combat = false;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
				updateDropdownButtons();
			end
			UIDropDownMenu_AddButton(info, level);
		elseif (menuList == "shapeshift") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;
			info.keepShownOnClick = true;

			info.text = LLL["DISABLE"];
			info.checked = function() return not action.forms; end
			info.func = function()
				action.forms = nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
				updateDropdownButtons();
				UIDropDownMenu_Refresh(dropdown);
			end
			UIDropDownMenu_AddButton(info, level);

			--for i = 0, GetNumShapeshiftForms() do
			info.isNotRadio = true;
			info.keepShownOnClick = true;

			for i = 0, 10 do
				local flag = (2 ^ i);
				local shapeshiftName;
				if (i == 0) then
					shapeshiftName = LLL["NO_SHAPESHIFT"];
				else
					local _, _, _, spellID = GetShapeshiftFormInfo(i);
					shapeshiftName = spellID and GetSpellInfo(spellID) or nil;
				end

				local text = format("[form:%d]", i);
				if (shapeshiftName) then
					text = format("%s (%s)", text, shapeshiftName);
				end

				info.text = text;
				info.checked = function()
					return action.forms and bit.band(action.forms, flag) == flag;
				end
				info.func = function(_, _, _, checked)
					if (checked) then
						action.forms = bit.bor(action.forms or 0, flag);
					else
						action.forms = bit.band(action.forms or 0, bit.bnot(flag));
					end
					UIDropDownMenu_Refresh(dropdown);
					DebouncePrivate.UpdateBindings();
					--DebounceFrame:Update();
				end
				UIDropDownMenu_AddButton(info, level);
			end

			info.isNotRadio = nil;
			info.keepShownOnClick = nil;
		elseif (menuList == "actionbars") then
			info.keepShownOnClick = true;

			info.text = LLL["DISABLE"];
			info.checked = function() return not action.bonusbars; end
			info.func = function()
				action.bonusbars = nil;
				DebouncePrivate.UpdateBindings();
				updateDropdownButtons();
				--DebounceFrame:Update();
				UIDropDownMenu_Refresh(dropdown);
				UIDropDownMenu_RefreshAll(L_UIDROPDOWNMENU_OPEN_MENU);
			end
			UIDropDownMenu_AddButton(info, level);

			info.isNotRadio = true;

			for i = 0, MAX_ACTIONBAR_TYPE_INDEX do
				local flag = (2 ^ i);
				local label = GetActionBarTypeLabel(i);
				if (label) then
					info.text = label;
					info.checked = function() return action.bonusbars and bit.band(action.bonusbars, flag) == flag; end
					info.func = function(_, _, _, checked)
						if (checked) then
							action.bonusbars = bit.bor(action.bonusbars or 0, flag);
						else
							action.bonusbars = bit.band(action.bonusbars or 0, bit.bnot(flag));
						end
						UIDropDownMenu_Refresh(dropdown);
						UIDropDownMenu_RefreshAll(L_UIDROPDOWNMENU_OPEN_MENU);
						DebouncePrivate.UpdateBindings();
						--DebounceFrame:Update();
						updateDropdownButtons();
					end
					UIDropDownMenu_AddButton(info, level);
				end
			end
		elseif (menuList == "stealth") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;

			info.text = LLL["DISABLE"];
			info.checked = action.stealth == nil;
			info.func = function()
				action.stealth = nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["STEALTHED"];
			info.checked = action.stealth == true;
			info.func = function()
				action.stealth = true;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["NOT_STEALTHED"];
			info.checked = action.stealth == false;
			info.func = function()
				action.stealth = false;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);
		elseif (menuList == "pet") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;

			info.text = LLL["DISABLE"];
			info.checked = action.pet == nil;
			info.func = function()
				action.pet = nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["WITH_PET"];
			info.checked = action.pet == true;
			info.func = function()
				action.pet = true;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["WITHOUT_PET"];
			info.checked = action.pet == false;
			info.func = function()
				action.pet = false;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);
		elseif (menuList == "misc") then
			info.text = LLL["PET_BATTLE"];
			info.hasArrow = true;
			info.menuList = "petbattle";
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
		elseif (menuList == "priority") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;

			for i = 1, 5 do
				info.text = LLL["PRIORITY" .. i];
				info.value = i;
				info.checked = (action.priority == nil and i == Constants.DEFAULT_PRIORITY) or action.priority == i;
				info.func = function()
					action.priority = i;
					DebouncePrivate.UpdateBindings();
				end
				UIDropDownMenu_AddButton(info, level);
			end
		elseif (menuList == "loadouts") then
			--/DUMP C_ClassTalents.GetConfigIDsBySpecID(102)
			info.hasArrow = nil;
			info.menuList = nil;

			local function addLoadoutOption(configID, configName, icon)
				info.text = configName;
				info.icon = icon;
				info.value = configID;
				info.checked = function()
					return action.loadouts and action.loadouts[configID];
				end
				info.func = function(_, _, _, checked)
					if (checked) then
						action.loadouts = action.loadouts or {};
						action.loadouts[configID] = true;
					elseif (action.loadouts) then
						action.loadouts[configID] = nil;
					end
					DebouncePrivate.UpdateBindings();
					--DebounceFrame:Update();
					UIDropDownMenu_Refresh(dropdown);
				end
				UIDropDownMenu_AddButton(info, level);
			end

			info.text = LLL["DISABLE"];
			info.checked = function() return action.loadouts == nil; end
			info.func = function()
				action.loadouts = nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.isTitle = nil;
			info.notCheckable = nil;
			info.isNotRadio = true;
			info.keepShownOnClick = true;
			info.disabled = nil

			for spec = 1, NUM_SPECS do
				local specID, specName, _, specIcon = GetSpecializationInfo(spec);
				local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID);
				if (C_ClassTalents.GetHasStarterBuild()) then
					tinsert(configIDs, -spec);
				end

				for _, configID in ipairs(configIDs) do
					local configName;
					if (configID < 0) then
						configName = BLUE_FONT_COLOR:WrapTextInColorCode(TALENT_FRAME_DROP_DOWN_STARTER_BUILD);
					else
						local configInfo = C_Traits.GetConfigInfo(configID);
						configName = configInfo.name;
					end
					configName = format("%s (%s)", configName, specName);
					addLoadoutOption(configID, configName, specIcon);
				end
			end
			info.icon = nil;
			info.value = nil;
			info.checked = nil;
			info.func = nil;

			UIDropDownMenu_AddSeparator(level);

			info.text = LLL["TALENT_LOADOUTS_WHEN_NOT_SELECTED"];
			info.checked = function() return action.excludeLoadouts end
			info.func = function(_, _, _, checked)
				action.excludeLoadouts = checked;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);
			info.isTitle = nil;
			info.notCheckable = nil;
			info.disabled = nil

			-- addLoadoutOptions(true);
			info.keepShownOnClick = nil;
			info.isNotRadio = nil;
			info.icon = nil;
		elseif (menuList == "move" or menuList == "copy") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;

			if (menuList == "copy") then
				info.text = LLL["CURRENT_TAB"];
				info.notCheckable = 1;
				info.func = function()
					local toLayerIndex = GetLayerID();
					MoveAction(elementData, toLayerIndex, true);
					CloseDropDownMenus(1);
				end
				UIDropDownMenu_AddButton(info, level);
			end

			for i = 1, #DebounceFrame.Tabs do
				for j = 1, #DebounceFrame.SideTabs do
					if (i ~= _selectedTab or j ~= _selectedSideTab) then
						local label1 = GetTabLabel(i);
						local label2 = GetSideTabaLabel(j);

						if (label1 and label2) then
							info.text = format("%s - %s", label1, label2);
							info.notCheckable = 1;
							info.func = function()
								local toLayerIndex = GetLayerID(i, j);
								MoveAction(elementData, toLayerIndex, menuList == "copy");
								CloseDropDownMenus(1);
							end
							UIDropDownMenu_AddButton(info, level);
						end
					end
				end
			end
		end
	elseif (level == 3) then
		if (menuList == "petbattle") then
			info.hasArrow = nil;
			info.notCheckable = nil;
			info.menuList = nil;

			info.text = LLL["DISABLE"];
			info.checked = action.petbattle == nil;
			info.func = function()
				action.petbattle = nil;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["IN_PET_BATTLE"];
			info.checked = action.petbattle == true;
			info.func = function()
				action.petbattle = true;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);

			info.text = LLL["NOT_IN_PET_BATTLE"];
			info.checked = action.petbattle == false;
			info.func = function()
				action.petbattle = false;
				DebouncePrivate.UpdateBindings();
				--DebounceFrame:Update();
			end
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

function DebounceFrameMixin:ShowEditDropdown(button, atButton)
	DebounceKeybindFrame:Hide();
	HideDeleteConfirmationPopup();
	HideDropDownMenu(1);

	local dropdown = self.EditDropDown;
	dropdown.button = button;
	dropdown.elementData = button:GetElementData();
	dropdown.action = dropdown.elementData.action;
	dropdown.initialize = EditDropDown_Initialize;
	dropdown.displayMode = "MENU";
	dropdown.listFrameOnShow = function()
		button:Update();
	end;

	dropdown.onHide = function(id)
		DebounceFrame:Update();
	end;

	if (atButton) then
		dropdown.point = "TOPLEFT";
		dropdown.relativePoint = "BOTTOMLEFT";
		dropdown.relativeTo = button;
		dropdown.xOffset = 72;
		dropdown.yOffset = 6;
		ToggleDropDownMenu(1, nil, dropdown);
	else
		ToggleDropDownMenu(1, nil, dropdown, "cursor", 20, 15);
	end
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

function DebounceFrameMixin:OnReceiveDrag()
	if (_placeholder) then
		local newLayerID = GetLayerID();
		if (_placeholder.layer) then
			DebouncePrivate.GetProfileLayer(_placeholder.layer):Remove(_placeholder.action);
		end
		_placeholder.layer = newLayerID;
		_placeholder.sortIndex = nil;

		local layer = DebouncePrivate.GetProfileLayer(newLayerID);
		for i, elementData in self.dataProvider:Enumerate() do
			elementData.index = i;
			if (elementData == _placeholder) then
				layer:Insert(elementData.action, i);
			end
		end
		_placeholder = nil;
		DebouncePrivate.UpdateBindings();

		self:ClearMouse();
		-- self:Update();
	else
		-- print("no _placeholder",GetCursorInfo())
		-- if (GetCursorInfo()) then
		-- 	self:ClearMouse();
		-- end
	end
end

function DebounceFrameMixin:RefreshIconDataProvider()
	if (self.iconDataProvider == nil) then
		self.iconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook);
	end
	return self.iconDataProvider;
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
	self.keyAssigned = nil;
	self:Update();
	DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:OnHide()
	DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:OnKeyDown(key)
	if (key == "ESCAPE") then
		self:SetPropagateKeyboardInput(false);
		self:CancelButton_OnClick();
		return;
	end

	local mouseFocus = GetMouseFocus();
	if (DoesAncestryInclude(self, mouseFocus)) then
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

function DebounceKeybindFrameMixin:ProcessInput(input)
	if (IsMetaKey(input) or input == "UNKNOWN") then
		return;
	end

	local key = GetConvertedKeyOrButton(input);
	key = _CreateKeyChordStringUsingMetaKeyState(key);
	if (self.newKey ~= key) then
		self.newKey = key;
		self:Update();
	end
end

function DebounceKeybindFrameMixin:OkayButton_OnClick()
	self.elementData.action.key = self.newKey;
	self.newKey = nil;
	self:Hide();
	DebouncePrivate.UpdateBindings();
	--DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:CancelButton_OnClick()
	--self.elementData.action.key = self.prevKey;
	self.newKey = nil;
	self:Hide();
	DebounceFrame:Update();
end

function DebounceKeybindFrameMixin:UnbindButton_OnClick()
	local action = self.elementData.action;
	self.newKey = nil;
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

	self.PreviousKeyText:SetFormattedText(LLL["PREVIOUS_KEY_TEXT"], self.prevKey and GetBindingText(self.prevKey, false) or LLL["NOT_BOUND"]);
	if (self.newKey) then
		self.NewKeyText:SetFormattedText(LLL["NEW_KEY_TEXT"], GetBindingText(self.newKey, false) or LLL["NOT_BOUND"]);
	else
		self.NewKeyText:SetText("");
	end
	self.UnbindButton:SetEnabled(self.newKey ~= nil or self.elementData.action.key ~= nil);

	local warningText;
	local key = self.newKey or self.prevKey;

	if (key) then
		local issue = DebouncePrivate.IsKeyInvalidForAction(self.elementData.action, key);
		if (issue) then
			warningText = LLL["BINDING_ERROR_" .. issue];
		elseif (issue) then
			warningText = WARNING_FONT_COLOR:WrapTextInColorCode(LLL[issue]);
		end
	end

	self.WarningText:SetText(warningText or "");
end

function DebounceKeybindFrameMixin:HasChanges()
	if (self:IsShown() and self.newKey ~= self.prevKey) then
		return true;
	end
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
	self.BorderBox.IconTypeDropDown:SetSelectedValue(IconSelectorPopupFrameIconFilterTypes.All);
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

	self:InitializeScrollBox();
end

function DebounceOverviewFrameMixin:OnShow()
	if (not self.initialized) then
		self:OnLoad();
	end

	self:Refresh();

	DebouncePrivate.RegisterCallback(self, "OnBindingsUpdated");
end

function DebounceOverviewFrameMixin:OnHide()
end

function DebounceOverviewFrameMixin:OnEvent()
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
end

function DebounceOverviewLineMixin:OnLeave()
	GameTooltip:Hide();
end

function DebounceOverviewLineMixin:Update()
	local elementData = self:GetElementData();
	local action = elementData.action;

	local name, icon = ColoredNameAndIconFromElementData(elementData, true);

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

	local bindingText = GetBindingText(action.key, false);
	self.BindingText:SetText(bindingText or "");

	if (action.unit) then
		self.UnitText:SetText(UNIT_INFOS[action.unit] and UNIT_INFOS[action.unit].name or LLL[action.unit]);
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
		self:SetPropagateKeyboardInput(false);
	else
		self:SetPropagateKeyboardInput(true);
	end
end

function DebounceOverviewFrameMixin:Toggle()
	if (self:IsShown()) then
		self:Hide();
	else
		self:Show();
	end
end
