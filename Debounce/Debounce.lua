local _, DebouncePrivate                 = ...;
local Constants                          = DebouncePrivate.Constants;
DebouncePrivate.DEBUG                    = Constants.DEBUG;
DebouncePrivate.callbacks                = LibStub("CallbackHandler-1.0"):New(DebouncePrivate);
DebouncePrivate.CliqueDetected           = C_AddOns.IsAddOnLoaded("Clique");
DebouncePrivate.Units                    = {};

local L                                  = DebouncePrivate.L;
local DEBUG                              = DebouncePrivate.DEBUG;
local SPECIAL_UNITS                      = Constants.SPECIAL_UNITS;
local BASIC_UNITS                        = Constants.BASIC_UNITS;

local dump                               = DebouncePrivate.dump;
local luatype                            = type;
local format, tostring                   = format, tostring;
local wipe, ipairs, pairs, tinsert, sort = wipe, ipairs, pairs, tinsert, sort;
local band, bor, bnot                    = bit.band, bit.bor, bit.bnot;
local InCombatLockdown                   = InCombatLockdown;
local GetSpellInfo                       = GetSpellInfo;
local GetSpellSubtext                    = C_Spell.GetSpellSubtext;
local GetMountInfoByID                   = C_MountJournal.GetMountInfoByID;
local IsConditionalAction                = DebouncePrivate.IsConditionalAction;

local BindingDriver                      = CreateFrame("Frame", DEBUG and "DebounceBindingDriver" or nil, nil, "SecureHandlerBaseTemplate,SecureHandlerAttributeTemplate");
BindingDriver:SetAttribute("unit", "target");
RegisterUnitWatch(BindingDriver, true);
SecureHandlerExecute(BindingDriver, [[
	DelegateFrames = newtable()
	DelegateFrameNames = newtable()
]]);
DebouncePrivate.BindingDriver = BindingDriver;

DebouncePrivate.ClickDelegateFrames = {};

local DefaultClickFrameName         = "DebounceClickButton"
local DefaultClickFrame             = CreateFrame("Button", DefaultClickFrameName, nil, "SecureActionButtonTemplate");
DefaultClickFrame:RegisterForClicks("AnyUp", "AnyDown");
DefaultClickFrame:SetAttribute("checkselfcast", true);
DefaultClickFrame:SetAttribute("checkfocuscast", true);
DefaultClickFrame:SetAttribute("checkmouseovercast", true);
DebouncePrivate.DefaultClickFrame = DefaultClickFrame;


do
	local _attrsSet = {};
	local setAttributeHook = function(self, name, value)
		local frameName = self:GetName() or tostring(self);
		_attrsSet[frameName] = _attrsSet[frameName] or {};
		_attrsSet[frameName][name] = value;
	end

	if (DEBUG) then
		hooksecurefunc(DefaultClickFrame, "SetAttribute", setAttributeHook);
		dump("Binding Attributes", _attrsSet);
	end

	function DebouncePrivate.GetDelegateFrame(key)
		local delegateFrame = DebouncePrivate.ClickDelegateFrames[key];
		if (delegateFrame == nil) then
			if (key == Constants.COMBINED or SPECIAL_UNITS[key] or BASIC_UNITS[key]) then
				local delegateName = key == Constants.COMBINED and "DebounceKey" or "DebounceClickButton_" .. key;
				delegateFrame = CreateFrame("Button", delegateName, DefaultClickFrame, "SecureActionButtonTemplate");
				if (key == Constants.COMBINED) then
				else
					delegateFrame.unit = key;
					if (SPECIAL_UNITS[key]) then
						delegateFrame:SetAttribute("alias", key);
						delegateFrame:SetAttribute("unit", "raid41");
					else
						delegateFrame:SetAttribute("unit", key);
					end
				end
				delegateFrame:SetAttribute("useparent*", true);
				delegateFrame:SetAttribute("useparent-unit", false);
				delegateFrame:RegisterForClicks("AnyUp", "AnyDown");
				SecureHandlerSetFrameRef(BindingDriver, "clickFrame", delegateFrame);
				SecureHandlerExecute(BindingDriver, [[
local frame = self:GetFrameRef("clickFrame")
local unit = frame:GetAttribute("alias") or frame:GetAttribute("unit")
if (unit) then
	DelegateFrames[unit] = frame
end
DelegateFrames[frame:GetName()] = frame
DelegateFrameNames[frame] = frame:GetName()
]]);
				DebouncePrivate.ClickDelegateFrames[key] = delegateFrame;

				if (DEBUG) then
					hooksecurefunc(delegateFrame, "SetAttribute", setAttributeHook);
				end
			elseif (DEBUG) then
				print("No delegate frame:", key);
			end
		end
		return delegateFrame;
	end
end
DebouncePrivate.GetDelegateFrame(Constants.COMBINED);


DebouncePrivate.KeyMap                 = {};
DebouncePrivate.ActiveActions          = {};
DebouncePrivate.BindingInfoToActionMap = {};
DebouncePrivate.CombinedKeys           = {};

do
	local KeyMap = DebouncePrivate.KeyMap;
	local ActiveActions = DebouncePrivate.ActiveActions;
	local BindingInfoToActionMap = DebouncePrivate.BindingInfoToActionMap;

	dump("KeyMap", KeyMap);
	dump("ActiveActions", ActiveActions);
	dump("BindingInfoToActionMap", BindingInfoToActionMap);

	local function BindingSortComparison(lhs, rhs)
		if ((lhs.priority or 3) ~= (rhs.priority or 3)) then
			return (lhs.priority or 3) < (rhs.priority or 3);
		end

		if (lhs.hover ~= nil and rhs.hover == nil) then
			return true;
		elseif (lhs.hover == nil and rhs.hover ~= nil) then
			return false;
		end

		if (lhs.isConditional and not rhs.isConditional) then
			return true;
		elseif (not lhs.isConditional and rhs.isConditional) then
			return false;
		end

		return lhs.ordinal < rhs.ordinal;
	end

	function DebouncePrivate.BuildKeyMap()
		wipe(KeyMap);
		wipe(ActiveActions);
		wipe(BindingInfoToActionMap);
		DebouncePrivate.ClearUnreachableBindingCache();

		for ordinal, action in DebouncePrivate.EnumerateActionsInActiveLayers() do
			if (action.key) then
				local binding = DebouncePrivate.GetBindingInfoForAction(action, true);
				BindingInfoToActionMap[binding] = action;

				binding.ordinal = ordinal;
				binding.isConditional = IsConditionalAction(action);

				local key = action.key;
				local issue = DebouncePrivate.GetBindingIssue(action);
				if (not issue) then
					if (not KeyMap[key]) then
						KeyMap[key] = {};
						local button, buttonPrefix = DebouncePrivate.GetMouseButtonAndPrefix(key);
						if (button) then
							KeyMap[key].button, KeyMap[key].buttonPrefix = button, buttonPrefix;
						end
					end
					tinsert(KeyMap[key], binding);
				end

				ActiveActions[action] = ordinal;
			end
		end

		for _, bindings in pairs(KeyMap) do
			if (#bindings > 1) then
				sort(bindings, BindingSortComparison);
				DebouncePrivate.CheckUnreachableBindings(bindings);
			end
		end
	end

	function DebouncePrivate.GetKeyMap()
		local ret = {};
		for key, bindingArr in pairs(KeyMap) do
			local actionArr = {};
			for i = 1, #bindingArr do
				actionArr[i] = BindingInfoToActionMap[bindingArr[i]];
			end
			ret[key] = actionArr;
		end
		return ret;
	end
end

local function UpdateBindingsTimerCallback()
	DebouncePrivate.updateBindingsQueued = nil;
	DebouncePrivate.UpdateBindings();
end

function DebouncePrivate.QueueUpdateBindings()
	if (not DebouncePrivate.updateBindingsQueued) then
		DebouncePrivate.updateBindingsQueued = true;
		C_Timer.After(0, UpdateBindingsTimerCallback);
	end
end

if (DEBUG) then
	_G.DebouncePrivate = DebouncePrivate;
end
