local _, DebouncePrivate                                  = ...;
DebouncePrivate.Constants                                 = {};
DebouncePrivate.callbacks                                 = LibStub("CallbackHandler-1.0"):New(DebouncePrivate);

local L                                                   = DebouncePrivate.L;
local DEBUG                                               = false;
local PLAYER_CLASS                                        = select(2, UnitClass("player"));
local NUM_SPECS                                           = GetNumSpecializationsForClassID(select(3, UnitClass("player")));

local Constants                                           = DebouncePrivate.Constants;
Constants.MAX_NUM_ACTIONS_PER_LAYER                       = 1000;

Constants.SPELL                                           = "spell";
Constants.ITEM                                            = "item";
Constants.MACRO                                           = "macro";
Constants.MACROTEXT                                       = "macrotext";
Constants.MOUNT                                           = "mount";
Constants.TARGET                                          = "target";
Constants.FOCUS                                           = "focus";
Constants.TOGGLEMENU                                      = "togglemenu";
Constants.COMMAND                                         = "command";
Constants.WORLDMARKER                                     = "worldmarker";
Constants.SETCUSTOM                                       = "setcustom";
Constants.UNUSED                                          = "unused";

Constants.DEFAULT_PRIORITY                                = 3;

-- 보스 프레임은 5개 뿐이지만 보스 유닛은 8까지 있는 것 같다. https://wowpedia.fandom.com/wiki/UnitId
Constants.MAX_BOSSES                                      = 8;

Constants.HOVER_HELP                                      = 2 ^ 0;
Constants.HOVER_HARM                                      = 2 ^ 1;
Constants.HOVER_OTHER                                     = 2 ^ 2;
Constants.HOVER_NONE                                      = 2 ^ 3;
Constants.HOVER_ALL                                       = Constants.HOVER_HELP + Constants.HOVER_HARM + Constants.HOVER_OTHER;

Constants.FRAMETYPE_UNKNOWN                               = 2 ^ 0;
Constants.FRAMETYPE_PLAYER                                = 2 ^ 1;
Constants.FRAMETYPE_PET                                   = 2 ^ 2;
Constants.FRAMETYPE_GROUP                                 = 2 ^ 3;
Constants.FRAMETYPE_TARGET                                = 2 ^ 4;
Constants.FRAMETYPE_BOSS                                  = 2 ^ 5;
Constants.FRAMETYPE_ARENA                                 = 2 ^ 6;
Constants.FRAMETYPE_ALL                                   = bit.bor(
	Constants.FRAMETYPE_UNKNOWN,
	Constants.FRAMETYPE_PLAYER,
	Constants.FRAMETYPE_PET,
	Constants.FRAMETYPE_GROUP,
	Constants.FRAMETYPE_TARGET,
	Constants.FRAMETYPE_BOSS,
	Constants.FRAMETYPE_ARENA);

Constants.GROUP_NONE                                      = 2 ^ 0;
Constants.GROUP_PARTY                                     = 2 ^ 1;
Constants.GROUP_RAID                                      = 2 ^ 2;
Constants.GROUP_ALL                                       = Constants.GROUP_NONE + Constants.GROUP_PARTY + Constants.GROUP_RAID;

Constants.FORM_ALL                                        = 2 ^ 11 - 1;

Constants.BONUSBAR_ALL                                    = 2 ^ 15 - 1;

Constants.BINDING_ISSUE_NOT_SUPPORTED_GAMEMENU_KEY        = "NOT_SUPPORTED_GAMEMENU_KEY";
Constants.BINDING_ISSUE_NOT_SUPPORTED_MOUSE_BUTTON        = "NOT_SUPPORTED_MOUSE_BUTTON";
Constants.BINDING_ISSUE_NOT_SUPPORTED_HOVER_CLICK_COMMAND = "NOT_SUPPORTED_HOVER_CLICK_COMMAND";
Constants.BINDING_ISSUE_CONDITIONS_NEVER                  = "CONDITIONS_NEVER";
Constants.BINDING_ISSUE_UNREACHABLE                       = "UNREACHABLE";
Constants.BINDING_ISSUE_CLIQUE_DETECTED                   = "CLIQUE_DETECTED";
Constants.BINDING_ISSUE_BONUSBARS_NONE                    = "BONUSBARS_NONE";
Constants.BINDING_ISSUE_FORMS_NONE                        = "FORMS_NONE";
Constants.BINDING_ISSUE_GROUPS_NONE                       = "GROUP_NONE";
Constants.BINDING_ISSUE_HOVER_NONE_SELECTED               = "HOVER_NONE_SELECTED";
Constants.BINDING_ISSUE_CANNOT_USE_HOVER_WITH_CLIQUE      = "CANNOT_USE_HOVER_WITH_CLIQUE";


local SPECIAL_UNITS                                       = {
	tank = 1,
	healer = 2,
	maintank = 3,
	mainassist = 4,
	custom1 = 5,
	custom2 = 6,
	hover = 7,
};

local CHECK_EXISTS_UNITS                                  = {
	target = 8,
	focus = 9,
	pet = 10,
	mouseover = 11,
};

DebouncePrivate.CUSTOM_TARGET_VALID_UNIT_TOKENS           = {};
DebouncePrivate.CUSTOM_TARGET_VALID_UNIT_TOKENS["player"] = "player";
DebouncePrivate.CUSTOM_TARGET_VALID_UNIT_TOKENS["pet"]    = "pet";
for i = 1, MAX_PARTY_MEMBERS do
	DebouncePrivate.CUSTOM_TARGET_VALID_UNIT_TOKENS["party" .. i] = "group"
end
for i = 1, MAX_RAID_MEMBERS do
	DebouncePrivate.CUSTOM_TARGET_VALID_UNIT_TOKENS["raid" .. i] = "group"
end
for i = 1, DebouncePrivate.Constants.MAX_BOSSES do
	DebouncePrivate.CUSTOM_TARGET_VALID_UNIT_TOKENS["boss" .. i] = "boss"
end
for i = 1, MAX_ARENA_ENEMIES do
	DebouncePrivate.CUSTOM_TARGET_VALID_UNIT_TOKENS["arena" .. i] = "arena"
end

-- 행동단축바 끌어다 놓은 탈것을 클릭하면 필요한 경우 자동으로 변신이 해제되지만 C_MountJournal.SummonByID를 사용하는 경우 자동으로 변신이 해제되지 않음.
-- 'autounshift'가 켜져있어도 마찬가지!
local SUMMON_MOUNT_MACROTEXT = SLASH_SCRIPT1 .. " C_MountJournal.SummonByID(%d)";
if (PLAYER_CLASS == "DRUID") then
	SUMMON_MOUNT_MACROTEXT = SLASH_CANCELFORM1 .. " [form:1/2/5/6,nocombat]\n" .. SUMMON_MOUNT_MACROTEXT;
end
local dump;
if (DEBUG and ViragDevTool_AddData) then
	function dump(strName, tData)
		if (DEBUG and ViragDevTool_AddData) then
			ViragDevTool_AddData(tData, "[" .. GetTime() .. "] " .. (strName or ""));
		end
	end

	dump("DebouncePrivate", DebouncePrivate);
else
	function dump() end
end

DebouncePrivate.DEBUG                    = DEBUG;
DebouncePrivate.dump                     = dump;
DebouncePrivate.CliqueDetected           = C_AddOns.IsAddOnLoaded("Clique");

local luatype                            = type;
local format, tostring                   = format, tostring;
local wipe, ipairs, pairs, tinsert, sort = wipe, ipairs, pairs, tinsert, sort;
local band, bnot                         = bit.band, bit.bnot;
local GetBindingKey                      = GetBindingKey;
local InCombatLockdown                   = InCombatLockdown;
local GetSpecialization                  = GetSpecialization;
local GetSpellInfo, GetMacroInfo         = GetSpellInfo, GetMacroInfo;
local GetSpellSubtext                    = GetSpellSubtext;
local C_MountJournal_GetMountInfoByID    = C_MountJournal.GetMountInfoByID;

DebouncePrivate.ccframes                 = {};
DebouncePrivate.blizzardFrames           = {};
DebouncePrivate.RegisterQueue            = {};
DebouncePrivate.UnregisterQueue          = {};
DebouncePrivate.RegisterClickQueue       = {};


local BindingDriver           = CreateFrame("Frame", DEBUG and "DebounceBindingDriver" or nil, nil, "SecureHandlerBaseTemplate,SecureHandlerAttributeTemplate");
DebouncePrivate.BindingDriver = BindingDriver;
BindingDriver:SetAttribute("unit", "player");
RegisterUnitWatch(BindingDriver, true);

local ClickButtonName         = "DebounceClickButton"
local ClickButton             = CreateFrame("Button", ClickButtonName, nil, "SecureActionButtonTemplate");
DebouncePrivate.ClickDelegate = ClickButton;
ClickButton:RegisterForClicks("AnyUp", "AnyDown");
ClickButton:SetAttribute("checkselfcast", "true");
ClickButton:SetAttribute("checkfocuscast", "true");
ClickButton:SetAttribute("checkmouseovercast", "true");

DebouncePrivate.SpecialUnitClickDelegateFrames = {};
for unit, _ in pairs(SPECIAL_UNITS) do
	local delegateName  = "DebounceClickButton_" .. unit;
	local delegateFrame = CreateFrame("Button", delegateName, ClickButton, "SecureActionButtonTemplate");
	delegateFrame.alias = unit;
	delegateFrame:SetAttribute("alias", unit);
	delegateFrame:SetAttribute("useparent*", "true");
	delegateFrame:RegisterForClicks("AnyUp", "AnyDown");
	DebouncePrivate.SpecialUnitClickDelegateFrames[unit] = delegateFrame;
end

DebouncePrivate.Units = {};
dump("Constants", Constants)
dump("Units", DebouncePrivate.Units);

local FULL_PLAYER_NAME = FULL_PLAYER_NAME;
function DebouncePrivate.GetUnitFullName(unit)
	local name, realm = UnitName(unit);
	if (realm and realm ~= "") then
		name = FULL_PLAYER_NAME:format(name, realm);
	end
	return name;
end

local eventFrame              = CreateFrame("Frame");
local Events                  = {};
local OrderedLayerIndices     = {};
local KeyMap                  = {};
local ActiveActions           = {};
local UnreachableActionsCache = {};
dump("KeyMap", KeyMap);
dump("ActiveActions", ActiveActions);
dump("UnreachableActionsCache", UnreachableActionsCache);

local _currentSpec;
local _bindingsDirty;
local _gmkey1, _gmkey2;

function DebouncePrivate.DisplayMessage(message, r, g, b)
	if (b == nil) then
		local info = ChatTypeInfo["SYSTEM"];
		r, g, b = info.r, info.g, info.b;
	end
	DEFAULT_CHAT_FRAME:AddMessage(L["_MESSAGE_PREFIX"] .. message, r, g, b);
end

function DebouncePrivate.IsConditionalAction(action)
	if (action.hover ~= nil) then
		return true;
	end

	if (action.groups ~= nil) then
		return true;
	end

	if (action.bonusbars ~= nil) then
		return true;
	end

	if (action.forms ~= nil) then
		return true;
	end

	if (action.combat ~= nil) then
		return true;
	end

	if (action.stealth ~= nil) then
		return true;
	end

	if (action.petbattle ~= nil) then
		return true;
	end

	local unit = action.unit;
	if (action.type ~= Constants.SPELL and action.type ~= Constants.ITEM and action.type ~= Constants.TARGET and action.type ~= Constants.FOCUS and action.type ~= Constants.TOGGLEMENU) then
		unit = nil;
	end

	if (unit and unit ~= "none" and unit ~= "" and action.checkUnitExists) then
		return true;
	end

	return false;
end

do
	local MOUSE_BUTTONS = {};
	for i = 1, 5 do
		MOUSE_BUTTONS["BUTTON" .. i] = i;
	end

	local _cache = {};
	function DebouncePrivate.GetMouseButtonAndPrefix(key)
		local cached = _cache[key];
		if (cached == nil) then
			if (MOUSE_BUTTONS[key]) then
				cached = { MOUSE_BUTTONS[key], nil };
				_cache[key] = cached;
			else
				local idx = key:match(".*%-()");
				if (idx) then
					local button = MOUSE_BUTTONS[key:sub(idx)];
					if (button) then
						local prefix = key:sub(1, idx - 1);
						cached = { button, prefix };
						_cache[key] = cached;
					else
						_cache[key] = false;
					end
				end
			end
		end
		if (cached) then
			return cached[1], cached[2];
		else
			return nil, nil;
		end
	end
end

local ParseMacroText, ClearMacroTextCache;
do
	local _parsedMacrotextCache = {};
	local _macrotextSeen = {};
	local _unitSuffixes = {
		target = true,
		targettarget = true,
		targettargettarget = true,
		targettargettargettarget = true,
		pet = true,
		pettarget = true,
		pettargettarget = true,
		pettargettargettarget = true,
	};

	function ParseMacroText(str)
		local cached = _parsedMacrotextCache[str];
		if (cached == nil) then
			local args;
			local unitSeen;
			local newstr = str:gsub("(%[[^%[%]]*@)(%w+)([^%[%]]*%])", function(pre, token, post)
				if (SPECIAL_UNITS[token]) then
					if (not args) then
						args = {};
						unitSeen = {};
					end
					if (not unitSeen[token]) then
						unitSeen[token] = true;
						tinsert(args, token);
					end
					return format("%s%%%d$s%s", pre, SPECIAL_UNITS[token], post);
				else
					for k, v in pairs(SPECIAL_UNITS) do
						if (strsub(token, 1, k:len()) == k) then
							local suffix = strsub(token, k:len() + 1);
							if (_unitSuffixes[suffix]) then
								--if (suffix == "pet" or suffix == "target") then
								if (not args) then
									args = {};
									unitSeen = {};
								end
								if (not unitSeen[k]) then
									unitSeen[k] = true;
									tinsert(args, k);
								end
								return format("%s%%%d$s%s%s", pre, v, suffix, post);
							end
						end
					end
				end
			end);
			if (args) then
				cached = { newstr, args };
			else
				cached = false;
			end
			_parsedMacrotextCache[str] = cached;
		end
		_macrotextSeen[str] = true;
		if (cached) then
			return cached[1], cached[2];
		else
			return str;
		end
	end

	function ClearMacroTextCache()
		for k in pairs(_parsedMacrotextCache) do
			if (not _macrotextSeen[k]) then
				_parsedMacrotextCache[k] = nil;
			end
		end
		wipe(_macrotextSeen);
	end
end

local BuildKeyMap
do
	local CheckUnreachableBindings;

	do
		local _currentConditionsList = { {}, n = 0 };
		local _conditionsMap = {};
		local _tempFlags = {};

		local function copyConditions(src, dest, overrideCol, overrideVal)
			for i = 1, #src do
				dest[i] = (i == overrideCol) and overrideVal or src[i];
			end
			return dest;
		end

		local function setConditions(tbl, pos, conditions, overrideCol, overrideVal)
			if (tbl[pos] == nil) then
				tbl[pos] = {};
			end
			copyConditions(conditions, tbl[pos], overrideCol, overrideVal);
		end


		local function flagsToConditionFlags(value, max)
			if (value) then
				return value;
			else
				return (2 ^ (max + 1)) - 1;
			end
		end

		local function boolToConditionFlags(value)
			if (value) then
				return 1;
			elseif (value == false) then
				return 2;
			else
				return 3;
			end
		end

		local CONDITION_FLAGS_INFOS = {
			{
				name = "hover",
				make = function(action)
					local flags;
					if (action.hover) then
						flags = action.reactions;
					elseif (action.hover == false) then
						flags = Constants.HOVER_NONE;
					else
						if (action.key and DebouncePrivate.GetMouseButtonAndPrefix(action.key)) then
							flags = Constants.HOVER_NONE;
						else
							flags = Constants.HOVER_ALL + Constants.HOVER_NONE;
						end
					end
					return flags;
				end
			},
			{
				name = "frameTypes",
				make = function(action)
					return flagsToConditionFlags(action.frameTypes, 6);
				end
			},
			{
				name = "groups",
				make = function(action)
					return flagsToConditionFlags(action.groups, 2);
				end
			},
			{
				name = "bonusbars",
				make = function(action)
					return flagsToConditionFlags(action.bonusbars, 14);
				end
			},
			{
				name = "forms",
				make = function(action)
					return flagsToConditionFlags(action.forms, 10);
				end
			},
			{
				name = "combat",
				make = function(action)
					return boolToConditionFlags(action.combat);
				end
			},
			{
				name = "stealth",
				make = function(action)
					return boolToConditionFlags(action.stealth);
				end
			},
			{
				name = "pet",
				make = function(action)
					return boolToConditionFlags(action.pet);
				end
			},
			{
				name = "petbattle",
				make = function(action)
					return boolToConditionFlags(action.petbattle);
				end
			},
			{
				name = "unit",
				make = function(action)
					if (action.checkUnitExists) then
						local unit = action.unit;
						if (action.type ~= Constants.SPELL and action.type ~= Constants.ITEM and action.type ~= Constants.TARGET and action.type ~= Constants.FOCUS and action.type ~= Constants.TOGGLEMENU) then
							unit = nil;
						end
						if (unit and unit ~= "none" and unit ~= "") then
							local unitIndex = SPECIAL_UNITS[unit] or CHECK_EXISTS_UNITS[unit];
							if (unitIndex) then
								return 2 ^ unitIndex;
							end
						end
					end
					return 0xffff;
				end
			}
		};

		local function buildConditionSet(action)
			local conditions = {};
			for i = 1, #CONDITION_FLAGS_INFOS do
				conditions[i] = CONDITION_FLAGS_INFOS[i].make(action);
			end
			return conditions;
		end

		local function removeConditions(other)
			if (_currentConditionsList.n > 0) then
				local newRows;

				for row = _currentConditionsList.n, 1, -1 do
					local conditions = _currentConditionsList[row];
					local overlaps = true;
					local isSubset = true;
					local nonZeroCount = 0;
					wipe(_tempFlags);

					for col = 1, #conditions do
						_tempFlags[col] = band(conditions[col], bnot(other[col]));
						if (_tempFlags[col] == conditions[col]) then
							overlaps = false;
							break;
						end

						if (_tempFlags[col] ~= 0) then
							nonZeroCount = nonZeroCount + 1;
							isSubset = false;
						end
					end

					if (overlaps) then
						_currentConditionsList.n = _currentConditionsList.n - 1;
						if (not isSubset) then
							if (newRows == nil) then
								newRows = {};
							end
							for col = 1, #_tempFlags do
								if (_tempFlags[col] ~= 0) then
									setConditions(newRows, #newRows + 1, conditions, col, _tempFlags[col]);
								end
							end
						end
					end
				end

				if (newRows) then
					for i = 1, #newRows do
						_currentConditionsList.n = _currentConditionsList.n + 1;
						_currentConditionsList[_currentConditionsList.n] = newRows[i];
					end
				end
			end
		end

		function CheckUnreachableBindings(actions)
			local i = 1;
			while (i <= #actions) do
				local action = actions[i];
				_conditionsMap[action] = buildConditionSet(action);
				setConditions(_currentConditionsList, 1, _conditionsMap[action]);
				_currentConditionsList.n = 1;
				if (i > 1) then
					for j = 1, i - 1 do
						local other = actions[j];
						if (not UnreachableActionsCache[other]) then
							removeConditions(_conditionsMap[other]);
							if (_currentConditionsList.n == 0) then
								UnreachableActionsCache[action] = true;
								break;
							end
						end
					end
				end

				if (UnreachableActionsCache[action]) then
					tremove(actions, i);
				else
					i = i + 1;
				end
			end
			wipe(_conditionsMap);
		end
	end

	local IsConditionalAction = DebouncePrivate.IsConditionalAction;

	local function ActionSortComparison(a, b)
		if ((a.priority or 3) ~= (b.priority or 3)) then
			return (a.priority or 3) < (b.priority or 3);
		end

		if (a.hover ~= nil and b.hover == nil) then
			return true;
		elseif (a.hover == nil and b.hover ~= nil) then
			return false;
		end

		local ac = IsConditionalAction(a);
		local bc = IsConditionalAction(b);

		if (ac and not bc) then
			return true;
		elseif (not ac and bc) then
			return false;
		end

		return ActiveActions[a] < ActiveActions[b];
	end

	function BuildKeyMap()
		wipe(KeyMap);
		wipe(ActiveActions);
		wipe(UnreachableActionsCache);

		_gmkey1, _gmkey2 = GetBindingKey("TOGGLEGAMEMENU");

		for layerOrder, layerID in ipairs(OrderedLayerIndices) do
			local layer = DebouncePrivate.GetProfileLayer(layerID);
			for i, action in layer:Enumerate() do
				local key = action.key;
				if (key) then
					local ordinal = layerOrder * Constants.MAX_NUM_ACTIONS_PER_LAYER + i;
					ActiveActions[action] = ordinal;

					if (action.forms) then
						action.forms = band(action.forms, Constants.FORM_ALL);
					end
					if (action.bonusbars) then
						action.bonusbars = band(action.bonusbars, Constants.BONUSBAR_ALL);
					end
					if (action.groups) then
						action.groups = band(action.groups, Constants.GROUP_ALL);
					end

					if (action.hover) then
						action.reactions = action.reactions and band(action.reactions, Constants.HOVER_ALL) or Constants.HOVER_ALL;
						action.frameTypes = action.frameTypes and band(action.frameTypes, Constants.FRAMETYPE_ALL) or Constants.FRAMETYPE_ALL;
					end

					local issue = DebouncePrivate.GetBindingIssue(action);
					if (not issue) then
						if (not KeyMap[key]) then
							KeyMap[key] = {};
							local button, buttonPrefix = DebouncePrivate.GetMouseButtonAndPrefix(key);
							if (button) then
								KeyMap[key].button, KeyMap[key].buttonPrefix = button, buttonPrefix;
							end
						end
						tinsert(KeyMap[key], action);
					end
				end
			end
		end

		for _, actions in pairs(KeyMap) do
			if (#actions > 1) then
				sort(actions, ActionSortComparison);
				CheckUnreachableBindings(actions);
			end
		end

		DebouncePrivate.callbacks:Fire("OnKeyMapBuilt", KeyMap);
		return true;
	end

	function DebouncePrivate.GetKeyMap()
		return KeyMap;
	end
end

do
	local ATTRIBUTE_DRIVERS = {
		combat = "[combat]1;0",
		stealth = "[stealth]1;0",
		petbattle = "[petbattle]1;0",
		pet = "[pet]1;0",
		form = "[form:1]1;[form:2]2;[form:3]3;[form:4]4;[form:5]5;[form:6]6;[form:7]7;[form:8]8;[form:9]9;[form:10]10;0",
		bonusbar = "[possessbar]11;[vehicleui]12;[shapeshift]13;[overridebar]14;[bonusbar:1]1;[bonusbar:2]2;[bonusbar:3]3;[bonusbar:4]4;[bonusbar:5]5;0",
		hovercheck = "[@mouseover,harm]harm;[@mouseover,help]help;[@mouseover,exists]1;0",
		group = "[group:raid]raid;[group:party]party;",
	};
	local UNIT_EXISTS_ATTR_FORMAT = "[@%s,exists]1;0";

	local _strArr = {};
	local _unitBindingsMap = {};
	local _states = {};
	local _unitStates = {};
	local _updateFlags = {};
	local _unitsSeen = {};

	local _button, _buttonPrefix;
	local _action, _id, _type, _value;
	local _hover, _reactions, _frameTypes, _ignoreHoverUnit;
	local _groups, _combat, _stealth, _forms, _bonusbars;
	local _pet, _petbattle;
	local _unit, _checkUnitExists;
	local _macrotext, _units;
	local _delegate;

	local function appendKeyValue(key, value)
		if (value == nil) then
			return;
		elseif (value == true) then
			_strArr[#_strArr + 1] = format("t.%s=true", key);
		elseif (value == false) then
			_strArr[#_strArr + 1] = format("t.%s=false", key);
		elseif (luatype(value) == "string") then
			_strArr[#_strArr + 1] = format("t.%s=%q", key, value);
		else
			_strArr[#_strArr + 1] = format("t.%s=%d", key, value);
		end
	end

	local function SetBindingAttributes()
		_delegate = DebouncePrivate.SpecialUnitClickDelegateFrames[_unit];
		local clickbutton = _delegate or ClickButton;

		if (_type == Constants.SPELL) then
			-- id는 다르지만 이름은 같은 주문들이 있다.
			-- 예: 조화 전문화의 달빛야수 변신과 회복 전문화의 달빛야수 변신
			-- id로 바인딩하는 경우 다른 전문화의 주문은 실행되지 않음.
			clickbutton:SetAttribute("*type-" .. _id, "spell");
			local spellID = FindBaseSpellByID(_value) or _value;
			local spellName = GetSpellInfo(spellID);
			if (spellName) then
				local subSpellName = GetSpellSubtext(spellID);
				if (subSpellName and subSpellName ~= "") then
					spellName = spellName .. "(" .. subSpellName .. ")";
				end
				clickbutton:SetAttribute("*spell-" .. _id, spellName);
			else
				clickbutton:SetAttribute("*spell-" .. _id, spellID);
			end
		elseif (_type == Constants.ITEM) then
			_value = format("item:%d", _value);
			clickbutton:SetAttribute("*type-" .. _id, "item");
			clickbutton:SetAttribute("*item-" .. _id, _value);
		elseif (_type == Constants.MACRO) then
			clickbutton:SetAttribute("*type-" .. _id, "macro");
			clickbutton:SetAttribute("*macro-" .. _id, _value);
			clickbutton:SetAttribute("*macrotext-" .. _id, nil);
		elseif (_type == Constants.MACROTEXT) then
			clickbutton:SetAttribute("*type-" .. _id, "macro");
			clickbutton:SetAttribute("*macro-" .. _id, nil);
			clickbutton:SetAttribute("*macrotext-" .. _id, _value);
		elseif (_type == Constants.MOUNT) then
			local _, spellID = C_MountJournal_GetMountInfoByID(_value);
			if (spellID) then
				_value = GetSpellInfo(spellID);
				clickbutton:SetAttribute("*type-" .. _id, "spell");
				clickbutton:SetAttribute("*spell-" .. _id, _value);
			else
				if (_value == 268435455) then
					_value = 0;
				end
				_value = SUMMON_MOUNT_MACROTEXT:format(_value);
				clickbutton:SetAttribute("*type-" .. _id, "macro");
				clickbutton:SetAttribute("*macro-" .. _id, nil);
				clickbutton:SetAttribute("*macrotext-" .. _id, _value);
			end
		elseif (_type == Constants.TARGET) then
			clickbutton:SetAttribute("*type-" .. _id, "target");
		elseif (_type == Constants.FOCUS) then
			clickbutton:SetAttribute("*type-" .. _id, "focus");
		elseif (_type == Constants.TOGGLEMENU) then
			clickbutton:SetAttribute("*type-" .. _id, "togglemenu");
		elseif (_type == Constants.SETCUSTOM) then
			clickbutton:SetAttribute("*type-" .. _id, "attribute");
			clickbutton:SetAttribute("*attribute-frame-" .. _id, DebouncePrivate.UnitWatch);
			clickbutton:SetAttribute("*attribute-name-" .. _id, "custom" .. _value);
			clickbutton:SetAttribute("*attribute-value-" .. _id, "hover");
		elseif (_type == Constants.WORLDMARKER) then
			clickbutton:SetAttribute("*type-" .. _id, "worldmarker");
			clickbutton:SetAttribute("*marker-" .. _id, _value);
		elseif (_type == Constants.COMMAND) then
			clickbutton:SetAttribute("*type-" .. _id, nil);
		elseif (_type == Constants.UNUSED) then
			clickbutton:SetAttribute("*type-" .. _id, nil);
		else
			clickbutton:SetAttribute("*type-" .. _id, nil);
		end

		if (not _delegate) then
			clickbutton:SetAttribute("*unit-" .. _id, _unit);
		end

		if (_delegate) then
			ClickButton:SetAttribute("*type-" .. _id, "macro");
			ClickButton:SetAttribute("*macro-" .. _id, nil);
			ClickButton:SetAttribute("*macrotext-" .. _id, format("/click %s %d true", _delegate:GetName(), _id));
		end
	end

	local _updateBindingsQueued;
	local function UpdateBindingsTimerCallback()
		DebouncePrivate.UpdateBindings();
		_updateBindingsQueued = nil;
	end

	function DebouncePrivate.QueueUpdateBindings()
		if (not _updateBindingsQueued) then
			_updateBindingsQueued = true;
			C_Timer.After(0, UpdateBindingsTimerCallback);
		end
	end

	function DebouncePrivate.UpdateBindings()
		if (InCombatLockdown()) then
			_bindingsDirty = true;
			DebouncePrivate.callbacks:Fire("OnUpdateBindingsSuspended");
			return;
		end

		BuildKeyMap()
		wipe(_strArr);

		SecureHandlerExecute(DebouncePrivate.BindingDriver, [[
self:ClearBindings()
self:RunAttribute("ClearClickBindings")
self:RunAttribute("ClearUnitAttributes")

wipe(BindingsMap)
wipe(UnitBindingsMap)
wipe(UnitStates)
wipe(States)
deferUpdate = true
]]);

		for attr, _ in pairs(_states) do
			UnregisterAttributeDriver(BindingDriver, attr);
			BindingDriver:SetAttribute(attr, nil);
		end

		for unit, _ in pairs(_unitStates) do
			local attr = unit .. "-exists";
			UnregisterAttributeDriver(BindingDriver, attr);
			BindingDriver:SetAttribute(attr, nil);
			_strArr[#_strArr + 1] = format("UnitStates[%q]=nil", unit);
		end
		wipe(_states);
		wipe(_unitStates);
		wipe(_unitBindingsMap);
		wipe(_unitsSeen);

		_strArr[#_strArr + 1] = "local bindings,t";
		for key, actionArray in pairs(KeyMap) do
			wipe(_updateFlags);

			_button, _buttonPrefix = actionArray.button, actionArray.buttonPrefix;
			local hasClick;
			local hasNonClick;
			local first = true;

			for i = 1, #actionArray do
				_action = actionArray[i];
				_id, _type, _value = _action.id, _action.type, _action.value;
				_hover, _reactions, _frameTypes, _ignoreHoverUnit = _action.hover, _action.reactions, _action.frameTypes, _action.ignoreHoverUnit;
				_groups, _combat, _stealth, _forms, _bonusbars = _action.groups, _action.combat, _action.stealth, _action.forms, _action.bonusbars;
				_pet, _petbattle = _action.pet, _action.petbattle;
				_unit, _checkUnitExists = _action.unit, _action.checkUnitExists;
				_macrotext, _units = nil, nil;

				if (not _hover) then
					_reactions = nil;
					_frameTypes = nil;
				end

				if (_type == Constants.TARGET
						or _type == Constants.FOCUS
						or _type == Constants.TOGGLEMENU) then
					assert(_unit and _unit ~= "" and _unit ~= "none");
				end

				if (not _unit or _unit == "" or _unit == "none") then
					_checkUnitExists = nil;
				elseif (_checkUnitExists == true) then
					_checkUnitExists = _unit;
				end

				if (_type ~= Constants.SPELL
						and _type ~= Constants.ITEM
						and _type ~= Constants.TARGET
						and _type ~= Constants.FOCUS
						and _type ~= Constants.TOGGLEMENU) then
					_unit = nil;
				end

				if (_hover) then
					if (_ignoreHoverUnit and _unit == nil) then
						_unit = "";
					elseif (_unit == nil and (_type == Constants.SPELL or _type == Constants.ITEM)) then
						_unit = "hover";
					end
				end

				local isClick = _button ~= nil and (_hover or _type == Constants.SETCUSTOM) and _type ~= Constants.COMMAND;
				local isNonClick = _button == nil or not _hover;

				if (isClick or isNonClick) then
					if (_type == Constants.MACROTEXT) then
						_macrotext, _units = ParseMacroText(_value);
						if (not _units) then
							_macrotext = nil;
							_units = nil;
						end
					end

					SetBindingAttributes();

					if (first) then
						if (DEBUG) then
							_strArr[#_strArr + 1] = format("-- %s", key);
						end
						first = false;
						_strArr[#_strArr + 1] = format("bindings=newtable();BindingsMap[%q]=bindings", key);
					end

					_strArr[#_strArr + 1] = "t=newtable();tinsert(bindings,t)";
					appendKeyValue("id", _id);

					if (_type == Constants.UNUSED) then
						appendKeyValue("type", Constants.UNUSED);
					elseif (_type == Constants.COMMAND) then
						appendKeyValue("command", _value);
					elseif (isNonClick) then
						appendKeyValue("buttonname", "deb" .. _id);
					end

					if (_hover ~= nil) then
						appendKeyValue("hover", _hover);
						if (_reactions and _reactions ~= Constants.HOVER_ALL) then
							appendKeyValue("reactions", _reactions);
						end
						if (_frameTypes and _frameTypes ~= Constants.FRAMETYPE_ALL) then
							appendKeyValue("frameTypes", _frameTypes);
						end
						_updateFlags.hover = true;
					end

					if (_groups ~= nil) then
						appendKeyValue("groups", _groups);
						_updateFlags.group = true;
					end

					if (_combat ~= nil) then
						appendKeyValue("combat", _combat);
						_updateFlags.combat = true;
					end

					if (_stealth ~= nil) then
						appendKeyValue("stealth", _stealth);
						_updateFlags.stealth = true;
					end

					if (_forms ~= nil) then
						appendKeyValue("forms", _forms);
						_updateFlags.form = true;
					end

					if (_bonusbars ~= nil) then
						appendKeyValue("bonusbars", _bonusbars);
						_updateFlags.bonusbar = true;
					end

					if (_pet ~= nil) then
						appendKeyValue("pet", _pet);
						_updateFlags.pet = true;
					end

					if (_petbattle ~= nil) then
						appendKeyValue("petbattle", _petbattle);
						_updateFlags.petbattle = true;
					end

					if (_macrotext) then
						appendKeyValue("macrotextAttr", "*macrotext-" .. _id);
						appendKeyValue("macrotext", _macrotext);
						for _, unit in ipairs(_units) do
							if (not _unitBindingsMap[unit]) then
								_unitBindingsMap[unit] = {};
								_strArr[#_strArr + 1] = format("UnitBindingsMap[%q]=newtable()", unit);
							end
							_strArr[#_strArr + 1] = format("tinsert(UnitBindingsMap[%q],t)", unit);
							_unitsSeen[unit] = true;
						end
					elseif (_unit) then
						_unitsSeen[_unit] = true;
					end

					if (_checkUnitExists) then
						_strArr[#_strArr + 1] = format("t.checkUnitExists=%q", _checkUnitExists);
						local existsKey = _checkUnitExists .. "-exists";
						_updateFlags[existsKey] = true;
						_unitStates[_checkUnitExists] = true;
					end


					if (isClick) then
						hasClick = true;
						_strArr[#_strArr + 1] = "t.isClick,t.clickAttrs=true,newtable()";
						if (_type == Constants.UNUSED) then
							_strArr[#_strArr + 1] = format([[t.clickAttrs["%1$stype%2$d"]="\0"
t.clickAttrs["%1$smacro%2$d"]="\0"
t.clickAttrs["%1$smacrotext%2$d"]="\0"]],
								_buttonPrefix or "",
								_button);
						else
							_strArr[#_strArr + 1] = format([[t.clickAttrs["%1$stype%2$d"]="macro"
t.clickAttrs["%1$smacro%2$d"]=""
t.clickAttrs["%1$smacrotext%2$d"]="/click %3$s %4$d true"]],
								_buttonPrefix or "",
								_button,
								(_delegate or ClickButton):GetName(),
								_id);
						end
						_updateFlags.hover = true;
					end

					if (isNonClick) then
						hasNonClick = true;
						_strArr[#_strArr + 1] = "t.isNonClick=true";
					end
				end
			end

			if (_updateFlags.hover) then
				_states.hovercheck = true;
			end
			if (_updateFlags.group) then
				_states.group = true;
			end
			if (_updateFlags.combat) then
				_states.combat = true;
			end
			if (_updateFlags.stealth) then
				_states.stealth = true;
			end
			if (_updateFlags.form) then
				_states.form = true;
			end
			if (_updateFlags.bonusbar) then
				_states.bonusbar = true;
			end
			if (_updateFlags.pet) then
				_states.pet = true;
			end
			if (_updateFlags.petbattle) then
				_states.petbattle = true;
			end

			if (next(_updateFlags)) then
				_strArr[#_strArr + 1] = "bindings.updateFlags=newtable()";
				for flag in pairs(_updateFlags) do
					_strArr[#_strArr + 1] = format("bindings.updateFlags[%q]=true", flag);
				end
			end

			if (hasClick) then
				_strArr[#_strArr + 1] = "bindings.hasClick=true";
			end
			if (hasNonClick) then
				_strArr[#_strArr + 1] = "bindings.hasNonClick=true";
			end
		end

		_strArr[#_strArr + 1] = format("_hasHoverBinding=%s", tostring(_states.hovercheck and true or false));

		for attr, _ in pairs(_states) do
			local value = ATTRIBUTE_DRIVERS[attr];
			if (value) then
				RegisterAttributeDriver(BindingDriver, attr, value);
			elseif (DEBUG) then
				print("no attr value for state: ", attr);
			end
		end

		for unit, _ in pairs(_unitStates) do
			local attr = unit .. "-exists";
			_strArr[#_strArr + 1] = format("UnitStates[%q]=false", unit);
			RegisterAttributeDriver(BindingDriver, attr, format(UNIT_EXISTS_ATTR_FORMAT, unit));
		end

		for unit in pairs(SPECIAL_UNITS) do
			if (unit ~= "custom1" and unit ~= "custom2" and not _unitsSeen[unit]) then
				DebouncePrivate.DisableUnitWatch(unit);
			end
			if (unit ~= "custom1" and unit ~= "custom2") then
				if (_unitsSeen[unit]) then
					DebouncePrivate.EnableUnitWatch(unit);
				else
					DebouncePrivate.DisableUnitWatch(unit);
				end
			end
		end

		local snippet = table.concat(_strArr, "\n");
		if (DEBUG) then
			dump("UpdateBindings", {
				snippet = { _strArr, snippet:len() },
				states = _states,
				unitExistsMap = _unitStates,
				unitBindingsMap = _unitBindingsMap,
				unitsSeen = _unitsSeen,
			});
		end
		SecureHandlerExecute(DebouncePrivate.BindingDriver, snippet);
		SecureHandlerExecute(DebouncePrivate.BindingDriver, [[
			deferUpdate = false
			self:RunAttribute("UpdateAllUnits")
			self:RunAttribute("UpdateBindings", true)
		]]);

		ClearMacroTextCache();
		DebouncePrivate.callbacks:Fire("OnBindingsUpdated");
		return true
	end
end

function Events.UPDATE_BINDINGS()
	DebouncePrivate.QueueUpdateBindings();
end

do
	local _queued;
	function Events.ACTIVE_PLAYER_SPECIALIZATION_CHANGED()
		local spec = GetSpecialization()
		if (not spec) then
			if (not _queued) then
				_queued = true
				C_Timer.After(0.05, function()
					_queued = nil
					Events.ACTIVE_PLAYER_SPECIALIZATION_CHANGED();
				end)
			end
			return;
		end

		if (_currentSpec ~= spec) then
			_currentSpec = spec;
			wipe(OrderedLayerIndices);

			if (spec > 0 and spec <= NUM_SPECS) then
				tinsert(OrderedLayerIndices, DebouncePrivate.GetLayerID(spec, true));
			end

			tinsert(OrderedLayerIndices, DebouncePrivate.GetLayerID(0, true));

			if (spec > 0 and spec <= NUM_SPECS) then
				tinsert(OrderedLayerIndices, DebouncePrivate.GetLayerID(spec, false));
			end

			tinsert(OrderedLayerIndices, DebouncePrivate.GetLayerID(0, false));

			tinsert(OrderedLayerIndices, DebouncePrivate.GetLayerID(nil, false));
		end

		DebouncePrivate.UpdateBindings();
	end
end

function Events.TRAIT_CONFIG_UPDATED(_, configID)
	if (configID == C_ClassTalents.GetActiveConfigID()) then
		DebouncePrivate.QueueUpdateBindings();
	end
end

function Events.PLAYER_PVP_TALENT_UPDATE()
	DebouncePrivate.QueueUpdateBindings();
end

function Events.PLAYER_REGEN_ENABLED()
	if (#DebouncePrivate.RegisterQueue > 0) then
		for i = 1, #DebouncePrivate.RegisterQueue do
			DebouncePrivate.RegisterFrame(DebouncePrivate.RegisterQueue[i][1], DebouncePrivate.RegisterQueue[i][2]);
		end
		wipe(DebouncePrivate.RegisterQueue);
	end
	if (#DebouncePrivate.UnregisterQueue > 0) then
		for i = 1, #DebouncePrivate.UnregisterQueue do
			DebouncePrivate.UnregisterFrame(DebouncePrivate.UnregisterQueue[i]);
		end
		wipe(DebouncePrivate.UnregisterQueue);
	end
	if (#DebouncePrivate.RegisterClickQueue > 0) then
		for i = 1, #DebouncePrivate.RegisterClickQueue do
			DebouncePrivate.UpdateRegisteredClicks(DebouncePrivate.RegisterClickQueue[i]);
		end
		wipe(DebouncePrivate.RegisterClickQueue);
	end

	if (_bindingsDirty) then
		_bindingsDirty = nil;
		DebouncePrivate.UpdateBindings();
	end
end

function DebouncePrivate.CanConvertToMacroText(action)
	return action.type == Constants.SPELL
		or action.type == Constants.ITEM
		or action.type == Constants.MACRO
		or action.type == Constants.MOUNT
		or action.type == Constants.SETCUSTOM
		or action.type == Constants.WORLDMARKER;
end

function DebouncePrivate.ConvertToMacroText(action)
	local macrotext, name, icon;

	if (action.type == Constants.SPELL or action.type == Constants.ITEM) then
		local slashCommand, spellOrItemName;
		if (action.type == Constants.SPELL) then
			slashCommand = SLASH_CAST1;
			local spellID = FindBaseSpellByID(action.value) or action.value;
			spellOrItemName, _, icon = GetSpellInfo(spellID);
			if (spellOrItemName) then
				local subSpellName = GetSpellSubtext(spellID);
				if (subSpellName and subSpellName ~= "") then
					spellOrItemName = spellOrItemName .. "(" .. subSpellName .. ")";
				end
			end
			name = spellOrItemName;
		else
			slashCommand = SLASH_USE1;
			spellOrItemName = format("item:%d", action.value);
			name = C_Item.GetItemNameByID(action.value);
			icon = C_Item.GetItemIconByID(action.value);
		end

		if (spellOrItemName) then
			if (action.unit) then
				if (action.checkUnitExists) then
					macrotext = format("%s [@%s,exists] %s", slashCommand, action.unit, spellOrItemName);
				else
					macrotext = format("%s [@%s] %s", slashCommand, action.unit, spellOrItemName);
				end
			else
				macrotext = format("%1$s %3$s", slashCommand, action.unit, spellOrItemName);
			end
		end
	elseif (action.type == Constants.MACRO) then
		name, icon, macrotext = GetMacroInfo(action.value);
	elseif (action.type == Constants.MOUNT) then
		local spellID;
		name, spellID, icon = C_MountJournal_GetMountInfoByID(action.value);
		if (spellID) then
			local spellName = GetSpellInfo(spellID);
			if (spellName) then
				macrotext = SLASH_CAST1 .. " " .. name;
			end
		end

		if (not macrotext) then
			local value = action.value;
			if (value == 0 or value == 268435455) then
				value = 0;
				name, _, icon = GetSpellInfo(150544);
			end
			macrotext = SUMMON_MOUNT_MACROTEXT:format(value);
		end
	elseif (action.type == Constants.SETCUSTOM) then
		macrotext = format("/click DebounceCustom%d hover", action.value);
		name = L["TYPE_SETCUSTOM" .. action.value];
		icon = 1505950;
	elseif (action.type == Constants.WORLDMARKER) then
		macrotext = format("/wm %d", action.value);
		name = _G["WORLD_MARKER" .. action.value];
		icon = 4238933;
	end

	if (macrotext) then
		action.type = Constants.MACROTEXT;
		action.value = macrotext;
		action.name = name;
		action.icon = icon;
		action.unit = nil;
		return true;
	end
end

function DebouncePrivate.IsInactiveAction(action)
	return not ActiveActions[action];
end

function DebouncePrivate.IsKeyInvalidForAction(action, key)
	if (key == _gmkey1 or key == _gmkey2) then
		return Constants.BINDING_ISSUE_NOT_SUPPORTED_GAMEMENU_KEY;
	elseif ((key == "BUTTON1" or key == "BUTTON2") and not action.hover) then
		return Constants.BINDING_ISSUE_NOT_SUPPORTED_MOUSE_BUTTON;
	end
	if (action.hover and action.type == Constants.COMMAND and DebouncePrivate.GetMouseButtonAndPrefix(key)) then
		return Constants.BINDING_ISSUE_NOT_SUPPORTED_HOVER_CLICK_COMMAND;
	end
end

function DebouncePrivate.GetBindingIssue(action, category, ...)
	local issue;

	if (not issue and (not category or category == "key")) then
		local key = action.key;
		if (key) then
			issue = DebouncePrivate.IsKeyInvalidForAction(action, key);
			if (not issue) then
				if (UnreachableActionsCache[action]) then
					issue = Constants.BINDING_ISSUE_UNREACHABLE;
				end
			end
		end
	end

	if (not issue and (not category or category == "hover")) then
		if (action.hover ~= nil) then
			if (DebouncePrivate.CliqueDetected) then
				issue = Constants.BINDING_ISSUE_CANNOT_USE_HOVER_WITH_CLIQUE;
			elseif (action.hover and (action.reactions == 0 or action.frameTypes == 0)) then
				issue = Constants.BINDING_ISSUE_HOVER_NONE_SELECTED;
			end
		end
	end

	if (not issue and (not category or category == "groups")) then
		if (action.groups == 0) then
			issue = Constants.BINDING_ISSUE_GROUPS_NONE;
		end
	end

	if (not issue and (not category or category == "forms")) then
		if (action.forms == 0) then
			issue = Constants.BINDING_ISSUE_FORMS_NONE;
		end
	end

	if (not issue and (not category or category == "bonusbars")) then
		if (action.bonusbars == 0) then
			issue = Constants.BINDING_ISSUE_BONUSBARS_NONE;
		end
	end

	if (not issue and (not category or category == "unit")) then
		if (action.type == Constants.SPELL
				or action.type == Constants.ITEM
				or action.type == Constants.TARGET
				or action.type == Constants.FOCUS
				or action.type == Constants.TOGGLEMENU) then
			if (action.unit == "hover" and DebouncePrivate.CliqueDetected) then
				issue = Constants.BINDING_ISSUE_CANNOT_USE_HOVER_WITH_CLIQUE;
			end
		end
	end

	if (not issue) then
		local n = select("#", ...);
		if (n > 0) then
			for i = 1, n do
				local cat = select(i, ...);
				if (cat) then
					issue = DebouncePrivate.GetBindingIssue(action, cat);
					if (issue) then
						break;
					end
				end
			end
		end
	end

	return issue;
end

do
	local _nextId = 100;
	local function NextId()
		_nextId = _nextId + 1;
		return _nextId;
	end

	local LAYER_INFOS = {
		[1] = { key = "GENERAL" },
		[2] = { key = PLAYER_CLASS, spec = 0 },
		[3] = { key = PLAYER_CLASS, spec = 1 },
		[4] = { key = PLAYER_CLASS, spec = 2 },
		[5] = { key = PLAYER_CLASS, spec = 3 },
		[6] = { key = PLAYER_CLASS, spec = 4 },
		[7] = { isCharacterSpecific = true, spec = 0 },
		[8] = { isCharacterSpecific = true, spec = 1 },
		[9] = { isCharacterSpecific = true, spec = 2 },
		[10] = { isCharacterSpecific = true, spec = 3 },
		[11] = { isCharacterSpecific = true, spec = 4 },
	};

	local ProfileLayerProto = {};

	function ProfileLayerProto:Insert(action, insertIndex, keepId)
		if (luatype(insertIndex) == "table") then
			local before = insertIndex;
			insertIndex = nil;
			for i = 1, #self.actions do
				if (self.actions[i] == before) then
					insertIndex = i;
					break;
				end
			end
		end

		if (insertIndex == nil) then
			insertIndex = #self.actions + 1;
		end

		if (keepId) then
			assert(action.id ~= nil);
		else
			action.id = NextId();
		end
		tinsert(self.actions, insertIndex, action);
	end

	function ProfileLayerProto:Remove(action)
		local removed = false;
		for i = 1, #self.actions do
			if (self.actions[i] == action) then
				tremove(self.actions, i);
				removed = true;
				break;
			end
		end
		return removed;
	end

	function ProfileLayerProto:GetAction(index)
		return self.actions[index];
	end

	-- function ProfileLayerProto:GetActions()
	-- 	return self.actions;
	-- end

	-- function ProfileLayerProto:SetActions(actions)
	-- 	self.actions = actions;
	-- end

	function ProfileLayerProto:GetNumActions()
		return #self.actions;
	end

	function ProfileLayerProto:Enumerate(indexBegin, indexEnd)
		return CreateTableEnumerator(self.actions, indexBegin, indexEnd);
	end

	local function LoadLayer(layerID)
		local layerInfo = assert(LAYER_INFOS[layerID]);
		if (layerInfo.spec and layerInfo.spec > NUM_SPECS) then
			return nil;
		end

		local tbl;
		if (layerInfo.isCharacterSpecific) then
			tbl = DebouncePrivate.db.char
		else
			assert(layerInfo.key);
			tbl = DebouncePrivate.db.global[layerInfo.key];
			if (not tbl) then
				tbl = {};
				DebouncePrivate.db.global[layerInfo.key] = tbl;
			end
		end

		if (layerInfo.spec) then
			if (not tbl[layerInfo.spec]) then
				tbl[layerInfo.spec] = {};
			end
			tbl = tbl[layerInfo.spec];
		end

		for i = 1, #tbl do
			tbl[i].id = NextId();
		end

		local layer = setmetatable({ layerID = layerID, actions = tbl, }, { __index = ProfileLayerProto });
		return layer;
	end

	local LayerArray;
	function DebouncePrivate.LoadProfile()
		LayerArray = {};

		for layerID = 1, #LAYER_INFOS do
			LayerArray[layerID] = LoadLayer(layerID);
		end

		dump("LayerArray", LayerArray);
		DebouncePrivate.callbacks:Fire("OnProfileLoaded");
	end

	function DebouncePrivate.GetProfileLayer(layerID)
		return LayerArray[layerID];
	end

	local KEYS_TO_SAVE = {
		type = true,
		value = true,
		key = true,
		name = true,
		icon = true,
		unit = true,
		hover = true,
		reactions = true,
		frameTypes = true,
		groups = true,
		combat = true,
		stealth = true,
		forms = true,
		bonusbars = true,
		pet = true,
		petbattle = true,
		priority = true,
		checkUnitExists = true,
		ignoreHoverUnit = true,
	};

	function DebouncePrivate.CleanUpDB()
		for _, layer in pairs(LayerArray) do
			for _, action in layer:Enumerate() do
				for k in pairs(action) do
					if (not KEYS_TO_SAVE[k]) then
						action[k] = nil;
					end
				end
				if (action.priority == Constants.DEFAULT_PRIORITY) then
					action.priority = nil;
				end
			end
		end
	end
end

function DebouncePrivate.GetLayerID(spec, isCharacterSpecific)
	if (isCharacterSpecific) then
		if (not spec or spec == 0) then
			return 7
		else
			assert(spec > 0 and spec <= NUM_SPECS);
			return 7 + spec;
		end
	else
		if (not spec) then
			return 1;
		elseif (spec == 0) then
			return 2;
		else
			assert(spec > 0 and spec <= NUM_SPECS);
			return 2 + spec;
		end
	end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	if (Events[event]) then
		Events[event](event, ...);
	end
end);



local BLIZZARD_UNITFRAME_OPTIONS = {
	player = { type = "player" },
	pet = { type = "pet" },
	target = { type = "target" },
	targettarget = { type = "targettarget" },
	focus = { type = "focus" },
	focustarget = { type = "focustarget" },
	boss = {
		type = "boss",
	},
	party = {
		type = "group",
	},
	raid = {
		type = "group",
	},
	arena = {
		type = "arena",
	},
};

local UNITFRAME_TYPES = {
	player = Constants.FRAMETYPE_PLAYER,
	pet = Constants.FRAMETYPE_PET,
	group = Constants.FRAMETYPE_GROUP,
	target = Constants.FRAMETYPE_TARGET,
	targettarget = Constants.FRAMETYPE_TARGET, --Constants.FRAMETYPE_TARGETTARGET,
	focus = Constants.FRAMETYPE_TARGET,     --Constants.FRAMETYPE_FOCUS,
	focustarget = Constants.FRAMETYPE_TARGET, --Constants.FRAMETYPE_FOCUSTARGET,
	boss = Constants.FRAMETYPE_BOSS,
	arena = Constants.FRAMETYPE_ARENA,
	unknown = Constants.FRAMETYPE_UNKNOWN,
};

function DebouncePrivate.RegisterFrame(button, type)
	if (DebouncePrivate.CliqueDetected) then
		return;
	end

	if (DebouncePrivate.ccframes[button] == false) then
		return;
	end

	if (DebouncePrivate.ccframes[button] and (DebouncePrivate.ccframes.hd or DebouncePrivate.ccframes[button].type == type)) then
		return;
	end

	if (button.IsForbidden and button:IsForbidden()) then
		DebouncePrivate.ccframes[button] = false;
		return;
	end

	if (not button.IsProtected or not button:IsProtected()) then
		DebouncePrivate.ccframes[button] = false;
		return;
	end

	if (button.IsAnchoringRestricted and button:IsAnchoringRestricted()) then
		DebouncePrivate.ccframes[button] = false;
		return;
	end

	if (not button.RegisterForClicks) then
		DebouncePrivate.ccframes[button] = false;
		return;
	end

	if (InCombatLockdown()) then
		tinsert(DebouncePrivate.RegisterQueue, { button, type });
		if (#DebouncePrivate.RegisterQueue == 1) then
			DebouncePrivate.DisplayMessage(L["UNABLE_TO_REGISTER_UNIT_FRAME_IN_COMBAT"]);
		end
		return;
	end

	if (DebouncePrivate.ccframes[button]) then
		DebouncePrivate.UnregisterFrame(button);
	end

	local frameType = UNITFRAME_TYPES[type] or UNITFRAME_TYPES.unknown;
	button:SetAttribute("debounce_frametype", frameType);
	if (DebouncePrivate.blizzardFrames[button]) then
		local insetL, insetR, insetT, insetB = button:GetHitRectInsets();
		insetL = floor(insetL + 0.5);
		insetR = floor(insetR + 0.5);
		insetT = floor(insetT + 0.5);
		insetB = floor(insetB + 0.5);
		button:SetAttribute("debounce_insets", format("%d,%d,%d,%d", insetL, insetR, insetT, insetB));
	end

	SecureHandlerSetFrameRef(DebouncePrivate.BindingDriver, "clickcast_button", button);
	SecureHandlerExecute(DebouncePrivate.BindingDriver, [=[
		local button = self:GetFrameRef("clickcast_button")
		self:RunFor(button, self:GetAttribute("InitFrame"))
		ccframes[button].frameType = button:GetAttribute("debounce_frametype")
		local insets = button:GetAttribute("debounce_insets")
		if (insets) then
			local l, r, t, b = strsplit(",", insets)
			ccframes[button].insetL, ccframes[button].insetR, ccframes[button].insetT, ccframes[button].insetB = tonumber(l), tonumber(r), tonumber(t), tonumber(b)
		end
	]=]);

	if (not DebouncePrivate.CliqueDetected) then
		SecureHandlerWrapScript(button, "OnEnter", BindingDriver, BindingDriver:GetAttribute("setup_onenter"));
		SecureHandlerWrapScript(button, "OnLeave", BindingDriver, BindingDriver:GetAttribute("setup_onleave"));
	end

	DebouncePrivate.ccframes[button] = { type = type, frameType = frameType };
	DebouncePrivate.UpdateRegisteredClicks(button);
end

function DebouncePrivate.UnregisterFrame(button)
	if (DebouncePrivate.CliqueDetected) then
		return;
	end

	if (DebouncePrivate.ccframes[button] and not DebouncePrivate.ccframes[button].hd) then
		if (InCombatLockdown()) then
			tinsert(DebouncePrivate.UnregisterQueue, button)
			return
		end

		SecureHandlerSetFrameRef(DebouncePrivate.BindingDriver, "clickcast_button", button);
		SecureHandlerExecute(DebouncePrivate.BindingDriver, [=[
			local button = self:GetFrameRef("clickcast_button")
			self:RunFor(button, self:GetAttribute("DeinitFrame"))
		]=]);
		DebouncePrivate.ccframes[button] = nil;

		if (not DebouncePrivate.CliqueDetected) then
			SecureHandlerUnwrapScript(button, "OnEnter");
			SecureHandlerUnwrapScript(button, "OnLeave");
		end
	end
end

function DebouncePrivate.UpdateRegisteredClicks(button)
	if (DebouncePrivate.CliqueDetected) then
		return;
	end

	if (InCombatLockdown()) then
		tinsert(DebouncePrivate.RegisterClickQueue, button)
		return
	end

	button:RegisterForClicks("AnyUp");
	button:EnableMouseWheel(true);
end

-- ChatFrame_DisplaySystemMessageInPrimary?

local function registerBlizzardFrame(frame, category)
	if (DebouncePrivate.Options.blizzframes[category] ~= false) then
		local options = BLIZZARD_UNITFRAME_OPTIONS[category];
		DebouncePrivate.RegisterFrame(frame, options and options.type);
	else
		DebouncePrivate.UnregisterFrame(frame);
	end
end

function DebouncePrivate.UpdateBlizzardFrames(firstTime)
	if (DebouncePrivate.CliqueDetected) then
		return;
	end

	if (firstTime) then
		local function addFrame(frame, frameType)
			if (frame) then
				DebouncePrivate.blizzardFrames[frame] = frameType;
			end
		end

		addFrame(PlayerFrame, "player");
		addFrame(PetFrame, "pet");
		addFrame(TargetFrame, "target");
		addFrame(TargetFrameToT, "target");
		addFrame(FocusFrame, "target");
		addFrame(FocusFrameToT, "target");

		for i = 1, MAX_PARTY_MEMBERS do
			addFrame(PartyFrame["MemberFrame" .. i], "party");
		end

		for i = 1, MAX_BOSS_FRAMES do
			addFrame(_G["Boss" .. i .. "TargetFrame"], "boss");
		end
	end

	for frame, category in pairs(DebouncePrivate.blizzardFrames) do
		if (category) then
			registerBlizzardFrame(frame, category);
		end
	end
end

if (not DebouncePrivate.CliqueDetected) then
	-- CompactPartyFrameMember5 -> party
	-- CompactPartyFramePet5 -> party
	-- CompactRaidGroup8Member5 -> raid
	-- CompactRaidFrame41 -> raid
	-- CompactArenaFrameMember5 -> arena
	-- CompactArenaFramePet5 -> arena
	hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame)
		local category = DebouncePrivate.blizzardFrames[frame];
		if (category == nil) then
			local name = frame:GetName();
			if (name) then
				local m1 = name:match("^Compact([A-Za-z]+)Frame[A-Za-z]*%d+$");
				if (m1 == "Party" or m1 == "Raid" or m1 == "Arena") then
					category = strlower(m1);
				elseif (name:match("^CompactRaidGroup%d+Member%d+$")) then
					category = "raid";
				end
			end

			DebouncePrivate.blizzardFrames[frame] = category or false;

			if (category) then
				if (DebouncePrivate.Options) then
					registerBlizzardFrame(frame, category);
				end
			end
		end
	end);
end

function Events.PLAYER_LOGIN()
	local function initDB(dbKey)
		local dbTbl = _G[dbKey];
		if (not dbTbl) then
			dbTbl = {};
			_G[dbKey] = dbTbl;
		end
		dump(dbKey, dbTbl);
		return dbTbl;
	end

	DebouncePrivate.db = {
		global = initDB("DebounceVars"),
		char = initDB("DebounceVarsPerChar"),
	};

	DebouncePrivate.db.global.options = DebouncePrivate.db.global.options or {};
	DebouncePrivate.db.global.options.blizzframes = DebouncePrivate.db.global.options.blizzframes or {};
	DebouncePrivate.Options = DebouncePrivate.db.global.options;
	DebouncePrivate.LoadProfile();

	eventFrame:RegisterEvent("PLAYER_LOGOUT");
	eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED");
	eventFrame:RegisterEvent("UPDATE_BINDINGS");
	eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED");
	DebouncePrivate.UpdateBlizzardFrames(true);
	Events.ACTIVE_PLAYER_SPECIALIZATION_CHANGED();

	DebouncePrivate.DisplayMessage(L["LOGIN_MESSAGE"]);
	if (DebouncePrivate.CliqueDetected) then
		DebouncePrivate.DisplayMessage(L["WARNING_MESSAGE_CLIQUE_DETECTED"], WARNING_FONT_COLOR:GetRGBA());
	end
end

function Events.PLAYER_LOGOUT()
	DebouncePrivate.CleanUpDB();
end

eventFrame:RegisterEvent("PLAYER_LOGIN");


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function DebouncePrivate.OnSpecialUnitChanged(alias, value)
	local unit = value or nil;
	local prev = DebouncePrivate.Units[alias];
	DebouncePrivate.Units[alias] = unit;

	if (prev ~= unit) then
		DebouncePrivate.callbacks:Fire("UNIT_CHANGED", alias, unit);
	end
end

if (DEBUG) then
	_G.DebouncePrivate = DebouncePrivate;
end
