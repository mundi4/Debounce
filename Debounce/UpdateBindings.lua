local _, DebouncePrivate      = ...;
local Constants               = DebouncePrivate.Constants;
local BindingDriver           = DebouncePrivate.BindingDriver;
local DefaultClickFrame       = DebouncePrivate.DefaultClickFrame;

local L                       = DebouncePrivate.L;
local DEBUG                   = DebouncePrivate.DEBUG;
local SPECIAL_UNITS           = Constants.SPECIAL_UNITS;
local BASIC_UNITS             = Constants.BASIC_UNITS;
local NIL                     = Constants.NIL;
local ALLOW_COMBINE_CLICK     = Constants.ALLOW_COMBINE_CLICK;
local ALLOW_COMBINE_NON_CLICK = Constants.ALLOW_COMBINE_NON_CLICK;
local CUSTOM_STATE_MODES      = Constants.CUSTOM_STATE_MODES;



local dump                               = DebouncePrivate.dump;
local luatype                            = type;
local format, tostring, select           = format, tostring, select;
local wipe, ipairs, pairs, tinsert, sort = wipe, ipairs, pairs, tinsert, sort;
local band, bor, bnot                    = bit.band, bit.bor, bit.bnot;
local InCombatLockdown                   = InCombatLockdown;
local FindBaseSpellByID                  = FindBaseSpellByID;
local GetSpellNameAndIconID              = DebouncePrivate.GetSpellNameAndIconID;
local GetSpellSubtext                    = C_Spell.GetSpellSubtext;
local IsPressHoldReleaseSpell            = C_Spell.IsPressHoldReleaseSpell;
local GetMountInfoByID                   = C_MountJournal.GetMountInfoByID;

local BindingAttrsCache                  = {};

local STATE_EVAL_STRING_FORMAT           = [[SecureCmdOptionParse(%q) and true or false]];

local STATE_EVAL_EXPRESSIONS             = {
    group = format([[(UnitPlayerOrPetInRaid("player") and %d) or (UnitPlayerOrPetInParty("player") and %d) or %d]],
        Constants.GROUP_RAID,
        Constants.GROUP_PARTY,
        Constants.GROUP_NONE),
    combat = "PlayerInCombat()",
    stealth = "IsStealthed()",
    form = "GetShapeshiftForm()",
    bonusbar = "GetBonusBarOffset()",
    specialbar = "HasVehicleActionBar() or HasOverrideActionBar() or HasTempShapeshiftActionBar() or false",
    extrabar = "HasExtraActionBar()",
    pet = "PlayerPetSummary() and true or false",
    petbattle = format(STATE_EVAL_STRING_FORMAT, "[petbattle]"),
};

-- not used
-- local HOVER_CHECK_SNIPPET = format([[
-- if (hovercheck and value ~= "unitframe") then
--     local unitframe = States.unitframe
--     local clear = not unitframe.frame:IsVisible()

--     if (not clear) then
--         if (unitframe.l) then
--             local x, y = unitframe.frame:GetMousePosition()
--             if (not x or (x < unitframe.l or x > unitframe.r or y < unitframe.b or y > unitframe.t)) then
--                 clear = true
--             end
--         end
--     end

--     if (clear) then
--         States.unitframe = nil
--         hovercheck = false
--         if (self:RunAttribute("SetUnit", "hover", nil)) then
--             DirtyFlags.unitframe = true
--         end
--     else
--         local unit = unitframe.frame:GetEffectiveAttribute("unit");
--         if (UnitExists(unit)) then
--             local reaction
--             if (PlayerCanAssist(unit)) then
--                 reaction = %d
--             elseif (PlayerCanAttack(unit)) then
--                 reaction = %d
--             else
--                 reaction = %d
--             end

--             if (unitframe.unit ~= unit or unitframe.reaction ~= reaction) then
--                 unitframe.unit = unit
--                 unitframe.reaction = reaction
--                 self:RunAttribute("SetUnit", "hover", unit)
--                 DirtyFlags.unitframe = true
--             end
--         end
--     end
-- end
-- ]], Constants.REACTION_HELP, Constants.REACTION_HARM, Constants.REACTION_NONE);


local NextButtonName;
do
    local _nextId = 100;
    function NextButtonName()
        _nextId = _nextId + 1;
        return "deb" .. _nextId;
    end
end

local ACTION_BUTTON_USE_KEY_DOWN; -- GetCVarBool("ActionButtonUseKeyDown")

local SetBindingAttributes;
local UpdateBindingsMap;
local UpdateMacroTextsMap;
local UpdateAttrChangedHandler;

local addCustomState;
local addMacrotext;
local addMacrotextBinding;

local _strArr            = {};
local _macrotexts        = {};
local _macrotextBindings = {};
local _customStates      = {};
local _states            = {};
local _unitStates        = {};
local _unitsSeen         = {};
local _updateFlags       = {};

local function ResetContext()
    wipe(_macrotexts);
    wipe(_macrotextBindings);
    wipe(_customStates);
    wipe(_states);
    wipe(_unitStates);
    wipe(_unitsSeen);
end

function addCustomState(stateName)
    local info = _customStates[stateName];
    if (info == nil) then
        if (Constants.CUSTOM_STATE_INDICES[stateName]) then
            local options = DebouncePrivate.GetCustomStateOptions(stateName);
            if (options) then
                info = {
                    index = Constants.CUSTOM_STATE_INDICES[stateName],
                    name = stateName,
                    mode = options.mode,
                    value = options.value,
                };
                if (options.mode == CUSTOM_STATE_MODES.MACRO_CONDITIONAL) then
                    info.expr = options.expr or "";
                    addMacrotextBinding(info.name, info.expr);
                end
            end
        end
        info = info or false;
        _customStates[stateName] = info;
    end
    return info;
end

function addMacrotext(macrotext)
    local ret = _macrotexts[macrotext];
    if (ret == nil) then
        local fragments, args, isComplex, normalized = DebouncePrivate.ParseMacroText(macrotext);
        if (args) then
            ret = {
                fragments = fragments,
                args = args,
                isComplex = isComplex,
                normalized = normalized,
            };
            _macrotexts[macrotext] = ret;

            for _, arg in ipairs(args) do
                if (arg.type == Constants.MACROTEXT_ARG_CUSTOM_STATE) then
                    addCustomState(arg.name);
                elseif (arg.type == Constants.MACROTEXT_ARG_UNIT) then
                    _unitsSeen[arg.name] = true;
                end
            end
        else
            ret = false;
        end
        _macrotexts[macrotext] = ret;
    end
    return ret;
end

function addMacrotextBinding(buttonOrStateName, macrotext)
    _macrotextBindings[buttonOrStateName] = addMacrotext(macrotext)
end

local function formatValue(value)
    if (value == nil) then
        return "nil";
    elseif (value == true) then
        return "true";
    elseif (value == false) then
        return "false";
    elseif (luatype(value) == "string") then
        return format("%q", value);
    else
        return tostring(value);
    end
end

local function appendLine(str, ...)
    if (select("#", ...)) then
        _strArr[#_strArr + 1] = format(str, ...);
    else
        _strArr[#_strArr + 1] = str or "";
    end
end

local function appendKeyValue(key, value)
    if (value == nil) then
        return;
    elseif (value == true) then
        appendLine("t[%q]=true", key);
    elseif (value == false) then
        appendLine("t[%q]=false", key);
    elseif (luatype(value) == "string") then
        appendLine("t[%q]=%q", key, value);
    else
        appendLine("t[%q]=%d", key, value);
    end
end


function DebouncePrivate.UpdateBindings()
    if (InCombatLockdown()) then
        DebouncePrivate.updateBindingsSuspended = true;
        return;
    end

    ACTION_BUTTON_USE_KEY_DOWN = GetCVarBool("ActionButtonUseKeyDown");

    SecureHandlerExecute(DebouncePrivate.BindingDriver, [[
wipe(OldStates)
for k, v in pairs(States) do
    OldStates[k] = v
end
self:RunAttribute("ClearClickBindings")
self:RunAttribute("ClearUnitAttributes")
wipe(BindingsMap)
wipe(MacroTextsMap)
wipe(UnitStates)
wipe(CustomStateExpressions)
wipe(States)
]]);

    ClearOverrideBindings(BindingDriver);
    DebouncePrivate.BindingDriver:SetAttribute("_onattributechanged", nil);

    for key, _ in pairs(DebouncePrivate.CombinedKeys) do
        DefaultClickFrame:SetAttribute("*type-" .. key, nil);
        DefaultClickFrame:SetAttribute("*macrotext-" .. key, nil);
    end
    wipe(DebouncePrivate.CombinedKeys);

    ResetContext();

    DebouncePrivate.BuildKeyMap();

    UpdateBindingsMap();

    UpdateMacroTextsMap();

    UpdateAttrChangedHandler();

    for state, stateInfo in pairs(_customStates) do
        if (stateInfo) then
            -- previous state value
            if (stateInfo.value ~= nil) then
                -- States 맵에 직접 입력하면 변경 이벤트가 발생하지 않아서 상태 변경 메시지가 출력 안됨.
                --appendLine([[States[%1$q]=%s]], state, tostring(stateInfo.value));
                appendLine([[self:RunAttribute("SetCustomState", %1$q, %s, true)]], state, tostring(stateInfo.value));
            end

            -- fixed macro conditional
            if (stateInfo.mode == CUSTOM_STATE_MODES.MACRO_CONDITIONAL and not addMacrotext(stateInfo.expr)) then
                appendLine([[CustomStateExpressions[%q]=%q]], state, stateInfo.expr);
            end
        end
    end

    if (#_strArr > 0) then
        local snippet = table.concat(_strArr, "\n");
        SecureHandlerExecute(DebouncePrivate.BindingDriver, snippet);
        if (DEBUG) then
            dump("CustomStateExpressions snippet", { CopyTable(_strArr), snippet:len() });
        end
        wipe(_strArr);
    end

    if (_unitsSeen.hover) then
        _states.unitframe = true;
    end

    for unit in pairs(SPECIAL_UNITS) do
        if (unit ~= "custom1" and unit ~= "custom2") then
            if (_unitsSeen[unit]) then
                DebouncePrivate.EnableUnitWatch(unit);
            else
                DebouncePrivate.DisableUnitWatch(unit);
                SecureHandlerExecute(DebouncePrivate.BindingDriver, format([[self:RunAttribute("SetUnit", %q, nil)]], unit));
            end
        end
    end

    SecureHandlerExecute(DebouncePrivate.BindingDriver, format("HoverBindings=%s", tostring(_states.unitframe and true or false)));

    if (_states.unitframe or _states.reaction or _unitStates.mouseover) then
        SecureStateDriverManager:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
        local updatetime = DebouncePrivate.Options.updatetime;
        if (not updatetime or updatetime < 0 or updatetime > Constants.STATE_DRIVER_UPDATETIME_DEFAULT) then
            updatetime = Constants.STATE_DRIVER_UPDATETIME_DEFAULT;
        end
        SecureStateDriverManager:SetAttribute("updatetime", updatetime);
    else
        SecureStateDriverManager:UnregisterEvent("UPDATE_MOUSEOVER_UNIT");
        SecureStateDriverManager:SetAttribute("updatetime", Constants.STATE_DRIVER_UPDATETIME_DEFAULT);
    end

    if (_states.reaction) then
        SecureStateDriverManager:RegisterEvent("UNIT_FACTION");
    else
        SecureStateDriverManager:UnregisterEvent("UNIT_FACTION");
    end

    -- execute UpdateBindings with forceAll set
    SecureHandlerExecute(DebouncePrivate.BindingDriver, [[
        DirtyFlags.forceAll = true
        self:RunAttribute("UpdateAllUnits")
        self:RunAttribute("UpdateMacroTexts", true)
        self:SetAttribute("state-unitexists", 1)
    ]]);

    DebouncePrivate.ClearMacroTextCache(_macrotexts);

    DebouncePrivate.ApplyOptions("stateDriverUpdateThrottle");

    DebouncePrivate.callbacks:Fire("OnBindingsUpdated");

    if (DEBUG) then
        dump("UpdateBindings", {
            states = _states,
            unitStates = _unitStates,
            unitsSeen = _unitsSeen,
            bindingAttrsCache = BindingAttrsCache,
            macrotexts = _macrotexts,
            macrotextBindings = _macrotextBindings,
            combinedKeys = DebouncePrivate.CombinedKeys,
            customStates = _customStates,
        });
    end

    return true
end

function SetBindingAttributes(type, value, unit, buttonname)
    if (type == Constants.UNUSED or type == Constants.COMMAND) then
        return;
    end

    local clickframe, delegate, skipCache;
    if (type == Constants.COMBINED) then
        clickframe = DefaultClickFrame;
        delegate = DebouncePrivate.GetDelegateFrame(Constants.COMBINED);
        skipCache = true;
    else
        assert(buttonname == nil);
        buttonname = BindingAttrsCache[type] and BindingAttrsCache[type][value or NIL];
        clickframe = DefaultClickFrame;
        delegate = unit and unit ~= "" and DebouncePrivate.GetDelegateFrame(unit) or nil;
    end

    if (not buttonname or skipCache) then
        buttonname = buttonname or NextButtonName();
        if (type == Constants.SPELL) then
            -- id는 다르지만 이름은 같은 주문들이 있다.
            -- 예: 조화 전문화의 달빛야수 변신과 회복 전문화의 달빛야수 변신
            -- id로 바인딩하는 경우 다른 전문화의 주문은 실행되지 않음.


            clickframe:SetAttribute("*type-" .. buttonname, "spell");
            local spellID = FindBaseSpellByID(value) or value;
            local spellName = GetSpellNameAndIconID(spellID);
            if (spellName) then
                local subSpellName = GetSpellSubtext(spellID);
                if (subSpellName and subSpellName ~= "") then
                    spellName = spellName .. "(" .. subSpellName .. ")";
                end
                clickframe:SetAttribute("*spell-" .. buttonname, spellName);
            else
                clickframe:SetAttribute("*spell-" .. buttonname, spellID);
            end

            -- what if 'IsPressHoldReleaseSpell' value is changed by a talent or something? is there a such situation?
            local isPressAndHold = IsPressHoldReleaseSpell(value);
            if (isPressAndHold) then
                clickframe:SetAttribute("*typerelease-" .. buttonname, "spell");
                clickframe:SetAttribute("*pressAndHoldAction-" .. buttonname, true);
            end
        elseif (type == Constants.ITEM) then
            value = format("item:%d", value);
            clickframe:SetAttribute("*type-" .. buttonname, "item");
            clickframe:SetAttribute("*item-" .. buttonname, value);
        elseif (type == Constants.MACRO) then
            clickframe:SetAttribute("*type-" .. buttonname, "macro");
            clickframe:SetAttribute("*macro-" .. buttonname, value);
            clickframe:SetAttribute("*macrotext-" .. buttonname, nil);
        elseif (type == Constants.MACROTEXT or type == Constants.COMBINED) then
            clickframe:SetAttribute("*type-" .. buttonname, "macro");
            clickframe:SetAttribute("*macro-" .. buttonname, nil);
            clickframe:SetAttribute("*macrotext-" .. buttonname, value);
        elseif (type == Constants.MOUNT) then
            local _, spellID = GetMountInfoByID(value);
            if (spellID) then
                local spellName = GetSpellNameAndIconID(spellID);
                clickframe:SetAttribute("*type-" .. buttonname, "spell");
                clickframe:SetAttribute("*spell-" .. buttonname, spellName);
            else
                local macrotext = DebouncePrivate.GetMountMacroText(value);
                clickframe:SetAttribute("*type-" .. buttonname, "macro");
                clickframe:SetAttribute("*macro-" .. buttonname, nil);
                clickframe:SetAttribute("*macrotext-" .. buttonname, macrotext);
            end
        elseif (type == Constants.TARGET) then
            clickframe:SetAttribute("*type-" .. buttonname, "target");
        elseif (type == Constants.FOCUS) then
            clickframe:SetAttribute("*type-" .. buttonname, "focus");
        elseif (type == Constants.TOGGLEMENU) then
            clickframe:SetAttribute("*type-" .. buttonname, "togglemenu");
        elseif (type == Constants.SETCUSTOM) then
            clickframe:SetAttribute("*type-" .. buttonname, "attribute");
            clickframe:SetAttribute("*attribute-frame-" .. buttonname, DebouncePrivate.UnitWatch);
            clickframe:SetAttribute("*attribute-name-" .. buttonname, "custom" .. value);
            clickframe:SetAttribute("*attribute-value-" .. buttonname, "hover");
        elseif (type == Constants.SETSTATE) then
            local mode, stateIndex = DebouncePrivate.GetSetCustomStateModeAndIndex(value);
            if (not mode) then
                if (DEBUG) then
                    print("Invalid value:", type, value);
                end
                return;
            end
            clickframe:SetAttribute("*type-" .. buttonname, "attribute");
            clickframe:SetAttribute("*attribute-frame-" .. buttonname, DebouncePrivate.CustomStatesUpdaterFrame);
            clickframe:SetAttribute("*attribute-name-" .. buttonname, "$state" .. stateIndex);
            clickframe:SetAttribute("*attribute-value-" .. buttonname, mode);
        elseif (type == Constants.WORLDMARKER) then
            clickframe:SetAttribute("*type-" .. buttonname, "worldmarker");
            clickframe:SetAttribute("*marker-" .. buttonname, value);
        else
            if (DEBUG) then
                print("Unhandled type:", type);
            end
            return;
        end

        if (unit and unit ~= "" and not delegate) then
            if (DEBUG) then
                print("No delegate frame for:", unit);
            end
        end

        if (not skipCache) then
            BindingAttrsCache[type] = BindingAttrsCache[type] or {};
            BindingAttrsCache[type][value or NIL] = buttonname;
        end
    end

    if (type == Constants.MACROTEXT or type == Constants.COMBINED) then
        addMacrotextBinding(buttonname, value);
    end

    return delegate or clickframe, buttonname;
end

local UnitStateFlags = {
    [true] = 1,
    [false] = 1,
    ["help"] = 2,
    ["harm"] = 4,
};

function UpdateBindingsMap()
    appendLine("local bindings,t");
    for key, bindingArray in pairs(DebouncePrivate.KeyMap) do
        wipe(_updateFlags);

        local button, buttonPrefix = bindingArray.button, bindingArray.buttonPrefix;
        local hasClick;
        local hasNonClick;
        local combinedClickData;

        for i = 1, #bindingArray do
            local binding = bindingArray[i];
            binding.isClick = button ~= nil and binding.type ~= Constants.COMMAND and (binding.hover or binding.type == Constants.SETCUSTOM or binding.unit == "hover");
            binding.isNonClick = button == nil or not binding.hover;
            binding.clickframe, binding.clickbutton = SetBindingAttributes(binding.type, binding.value, binding.unit);
            hasClick = hasClick or binding.isClick;
            hasNonClick = hasNonClick or binding.isNonClick;
        end

        if (ALLOW_COMBINE_CLICK) then
            local macrotext = DebouncePrivate.CombineIfPossible(bindingArray, true);
            if (macrotext) then
                local clickframe, clickbutton = SetBindingAttributes(Constants.COMBINED, macrotext, nil, "^" .. key);
                combinedClickData = { clickframe, clickbutton };
                hasClick = false;
                DebouncePrivate.CombinedKeys["^" .. key] = true;
            end
        end

        if (ALLOW_COMBINE_NON_CLICK) then
            local macrotext = DebouncePrivate.CombineIfPossible(bindingArray);
            if (macrotext) then
                local clickframe, clickbutton = SetBindingAttributes(Constants.COMBINED, macrotext, nil, key);
                SetOverrideBindingClick(BindingDriver, true, key, clickframe:GetName(), clickbutton);
                hasNonClick = false;
                DebouncePrivate.CombinedKeys[key] = true;
            end
        end

        local first = true;
        if (combinedClickData) then
            if (first) then
                first = false;
                if (DEBUG) then
                    appendLine("-- %s", key);
                end
                appendLine("bindings=newtable();BindingsMap[%q]=bindings", key);
            end
            appendLine("t=newtable();tinsert(bindings,t)");
            appendLine("t.isClick,t.clickAttrs=true,newtable()");
            appendLine([[
t.clickAttrs["%1$stype%2$d"]="macro"
t.clickAttrs["%1$smacro%2$d"]=""
t.clickAttrs["%1$smacrotext%2$d"]="/click %3$s %4$s %5$s"
]],
                buttonPrefix or Constants.CLICKBINDING_NON_MOD_PREFIX,
                button,
                combinedClickData[1]:GetName(),
                combinedClickData[2],
                ACTION_BUTTON_USE_KEY_DOWN and "true" or "");
            _updateFlags.unitframe = true;
        end

        if (hasClick or hasNonClick) then
            for i = 1, #bindingArray do
                local binding = bindingArray[i];
                local isClick = hasClick and binding.isClick;
                local isNonClick = hasNonClick and binding.isNonClick;
                local clickframe, clickbutton = binding.clickframe, binding.clickbutton;

                if (isClick or isNonClick) then
                    if (first) then
                        first = false;
                        if (DEBUG) then
                            appendLine("-- %s", key);
                        end
                        appendLine("bindings=newtable();BindingsMap[%q]=bindings", key);
                    end
                    appendLine("t=newtable();tinsert(bindings,t)");

                    if (isClick or isNonClick) then
                        if (binding.type == Constants.UNUSED) then
                            appendKeyValue("type", Constants.UNUSED);
                        elseif (binding.type == Constants.COMMAND) then
                            appendKeyValue("command", binding.value);
                        end

                        if (clickframe and clickbutton) then
                            if (clickframe ~= DefaultClickFrame) then
                                appendKeyValue("clickframe", clickframe:GetName());
                            end
                            if (clickbutton) then
                                appendKeyValue("clickbutton", clickbutton);
                            end
                        end


                        if (binding.hover ~= nil) then
                            appendKeyValue("hover", binding.hover);
                            if (binding.reactions and binding.reactions ~= Constants.REACTION_ALL) then
                                appendKeyValue("reactions", binding.reactions);
                                _updateFlags.reaction = true;
                            end
                            if (binding.frameTypes and binding.frameTypes ~= Constants.FRAMETYPE_ALL) then
                                appendKeyValue("frameTypes", binding.frameTypes);
                                _updateFlags.frameType = true;
                            end
                            _updateFlags.unitframe = true;
                        end

                        if (binding.groups ~= nil and binding.groups ~= Constants.GROUP_ALL) then
                            appendKeyValue("groups", binding.groups);
                            _updateFlags.group = true;
                        end

                        if (binding.combat ~= nil) then
                            appendKeyValue("combat", binding.combat);
                            _updateFlags.combat = true;
                        end

                        if (binding.stealth ~= nil) then
                            appendKeyValue("stealth", binding.stealth);
                            _updateFlags.stealth = true;
                        end

                        if (binding.known ~= nil) then
                            appendKeyValue("known", binding.known);
                            appendKeyValue("spellName", binding.spellName or "");
                            _updateFlags.known = true;
                        end

                        if (binding.forms ~= nil and binding.forms ~= Constants.FORM_ALL) then
                            appendKeyValue("forms", binding.forms);
                            _updateFlags.form = true;
                        end

                        if (binding.bonusbars ~= nil and binding.bonusbars ~= Constants.BONUSBAR_ALL) then
                            appendKeyValue("bonusbars", binding.bonusbars);
                            _updateFlags.bonusbar = true;
                        end

                        if (binding.specialbar ~= nil) then
                            appendKeyValue("specialbar", binding.specialbar);
                            _updateFlags.specialbar = true;
                        end

                        if (binding.extrabar ~= nil) then
                            appendKeyValue("extrabar", binding.extrabar);
                            _updateFlags.extrabar = true;
                        end

                        if (binding.pet ~= nil) then
                            appendKeyValue("pet", binding.pet);
                            _updateFlags.pet = true;
                        end

                        if (binding.petbattle ~= nil) then
                            appendKeyValue("petbattle", binding.petbattle);
                            _updateFlags.petbattle = true;
                        end

                        -- if (binding.checkUnitExists) then
                        --     appendKeyValue("checkUnitExists", binding.checkUnitExists);
                        --     local existsKey = binding.checkUnitExists .. "-exists";
                        --     _updateFlags[existsKey] = true;
                        --     _unitStates[binding.checkUnitExists] = true;
                        -- end

                        if (binding.checkedUnits) then
                            appendLine("t.checkedUnits=newtable()");
                            for k, v in pairs(binding.checkedUnits) do
                                if (k == "@") then
                                    k = binding.unit;
                                end
                                appendLine("t.checkedUnits[%q]=%s", k, formatValue(v));
                                _unitsSeen[k] = true;
                                _unitStates[k] = bor(_unitStates[k] or 0, UnitStateFlags[v]);    
                                _updateFlags[k .. "-exists"] = true;
                            end
                        end

                        local customStatesTblCreated;
                        for stateIndex = 1, Constants.MAX_NUM_CUSTOM_STATES do
                            local state = "$state" .. stateIndex;
                            local v = binding[state];
                            if (v ~= nil) then
                                if (addCustomState(state)) then
                                    if (not customStatesTblCreated) then
                                        appendLine([[t.customStates=newtable()]])
                                        customStatesTblCreated = true;
                                    end
                                    appendLine([[t.customStates[%q]=%s]], state, v and "true" or "false");
                                    _updateFlags[state] = true;
                                end
                            end
                        end

                        if (binding.customStates) then
                            local tblCreated;
                            for state, v in pairs(binding.customStates) do
                                local stateInfo = addCustomState(state);
                                if (stateInfo) then
                                    if (not tblCreated) then
                                        appendLine([[t.customStates=newtable()]])
                                        tblCreated = true;
                                    end
                                    appendLine([[t.customStates[%q]=%s]], state, v and "true" or "false");
                                    _updateFlags[state] = true;
                                end
                            end
                        end

                        if (binding.unit) then
                            _unitsSeen[binding.unit] = true;
                        end

                        if (isClick) then
                            appendLine("t.isClick,t.clickAttrs=true,newtable()");
                            if (clickframe and clickbutton) then
                                appendLine([[
t.clickAttrs["%1$stype%2$d"]="macro"
t.clickAttrs["%1$smacro%2$d"]=""
t.clickAttrs["%1$smacrotext%2$d"]="/click %3$s %4$s %5$s"
]],
                                    buttonPrefix or Constants.CLICKBINDING_NON_MOD_PREFIX,
                                    button,
                                    clickframe:GetName(),
                                    clickbutton,
                                    ACTION_BUTTON_USE_KEY_DOWN and "true" or "");
                            else --if (_type == Constants.UNUSED) then
                                appendLine([[
t.clickAttrs["%1$stype%2$d"]=false
t.clickAttrs["%1$smacro%2$d"]=false
t.clickAttrs["%1$smacrotext%2$d"]=false
]],
                                    buttonPrefix or Constants.CLICKBINDING_NON_MOD_PREFIX,
                                    button);
                            end
                            _updateFlags.unitframe = true;
                        end

                        if (isNonClick) then
                            appendLine("t.isNonClick=true");
                        end
                    end
                end
            end
        end

        for k, _ in pairs(_updateFlags) do
            if (strsub(k, -7) ~= "-exists") then
                _states[k] = true;
            end
        end

        if (next(_updateFlags)) then
            appendLine("bindings.updateFlags=newtable()");
            for flag in pairs(_updateFlags) do
                appendLine("bindings.updateFlags[%q]=true", flag);
            end
        end

        if (hasClick or combinedClickData) then
            appendLine("bindings.hasClick=true");
        end
        if (hasNonClick) then
            appendLine("bindings.hasNonClick=true");
        end
    end

    local snippet = table.concat(_strArr, "\n");
    SecureHandlerExecute(DebouncePrivate.BindingDriver, snippet);
    if (DEBUG) then
        dump("UpdateBindingsMap", {
            CopyTable(_strArr),
            snippet:len(),
        });
    end
    wipe(_strArr);
end

function UpdateMacroTextsMap()
    appendLine("local tempArray, t = newtable()");

    local index = 0;

    for buttonOrStateName, data in pairs(_macrotextBindings) do
        if (data) then
            index = index + 1;
            data.index = index;
            appendLine("t=newtable()");
            appendLine("t.id=%d", index);
            local isState = false;
            if (strsub(buttonOrStateName, 1, 1) == "$") then
                appendLine("t.state=%q", buttonOrStateName);
                isState = true;
            else
                appendLine("t.attr=%q", "*macrotext-" .. buttonOrStateName);
            end

            if (data.isComplex) then
                appendLine("t.fragments,t.args=newtable(),newtable()");
                for i = 1, #data.fragments do
                    appendLine([[t.fragments[%d]=%q]], i, data.fragments[i]);
                end
                for i = 1, #data.args do
                    local arg = data.args[i];
                    appendLine([[t.args[%d]=newtable()]], i);
                    if (arg.type == Constants.MACROTEXT_ARG_UNIT) then
                        appendLine([[t.args[%d].unit=%q]], i, arg.name);
                    elseif (arg.type == Constants.MACROTEXT_ARG_CUSTOM_STATE) then
                        if ((isState and arg.name == buttonOrStateName) or not addCustomState(arg.name)) then
                            if (arg.reverse) then
                                appendLine([[t.args[%d].fixed=%q]], i, "known:0");
                            else
                                appendLine([[t.args[%d].fixed=%q]], i, "");
                            end
                        else
                            appendLine([[t.args[%d].state=%q]], i, arg.name);
                            if (arg.reverse) then
                                appendLine([[t.args[%d].reverse=true]], i);
                            end
                        end
                    end
                end
            else
                appendLine("t.formatString=%q", data.fragments);
            end
            appendLine("tempArray[%d]=t", index);
        end
    end

    -- dependents
    local keysSeen = {};
    for _, data in pairs(_macrotexts) do
        if (data) then
            assert(data.index);
            for _, arg in ipairs(data.args) do
                local key = arg.name;
                if (not keysSeen[key]) then
                    keysSeen[key] = true;
                    appendLine("MacroTextsMap[%q]=newtable()", key);
                end
                appendLine("tinsert(MacroTextsMap[%q], tempArray[%d])", key, data.index);
            end
        end
    end
    appendLine("tempArray = nil")

    local snippet = table.concat(_strArr, "\n");
    SecureHandlerExecute(DebouncePrivate.BindingDriver, snippet);
    if (DEBUG) then
        dump("UpdateMacroTextsMap", {
            CopyTable(_strArr),
            snippet:len(),
        });
    end
    wipe(_strArr);
end

local function compareStates(lhs, rhs)
    if (lhs == "petbattle") then
        return true;
    end
    if (rhs == "petbattle") then
        return false;
    end

    return lhs < rhs;
end

-- 'state-unitexists' attribute 값이 변경될 때 상태 업데이트 후 UpdateBindings 실행함.
-- 블리자드 StateDriverManager는 기존 값과 새로운 값(true or false)이 다른 경우에만 _onattributechanged를 호출하므로
-- 'state-unitexists'은 true/false가 아닌 값을 넣어둔다.
function UpdateAttrChangedHandler()
    appendLine([[
if (name == "state-unitexists") then
    if (value == 0) then return end
    self:SetAttribute("state-unitexists", 0)
]]);

    appendLine([[
if (States.unitframe) then
    local unitframe = States.unitframe
    local unit = unitframe.frame:GetEffectiveAttribute("unit");
    if (UnitExists(unit)) then
        local reaction
        if (PlayerCanAssist(unit)) then
            reaction = %d
        elseif (PlayerCanAttack(unit)) then
            reaction = %d
        else
            reaction = %d
        end

        if (unitframe.unit ~= unit or unitframe.reaction ~= reaction) then
            unitframe.unit = unit
            unitframe.reaction = reaction
            self:RunAttribute("SetUnit", "hover", unit)
            DirtyFlags.unitframe = true
        end
    end
end
]], Constants.REACTION_HELP, Constants.REACTION_HARM, Constants.REACTION_NONE);

    -- Update States
    appendLine("local stateValue")

    -- Update Basic States
    local stateArray = {};
    for state in pairs(_states) do
        tinsert(stateArray, state);
    end
    sort(stateArray, compareStates);

    for _, state in ipairs(stateArray) do
        if (STATE_EVAL_EXPRESSIONS[state]) then
            if (state == "specialbar") then
                if (_states.petbattle) then
                    appendLine("stateValue=(%s) or States.petbattle", STATE_EVAL_EXPRESSIONS.specialbar);
                else
                    appendLine([[stateValue=(%s) or (SecureCmdOptionParse("[petbattle]") and true or false)]], STATE_EVAL_EXPRESSIONS.specialbar);
                end
            else
                appendLine("stateValue=%s", STATE_EVAL_EXPRESSIONS[state]);
            end
            appendLine("if (States[%1$q] ~= stateValue) then States[%1$q]=stateValue;DirtyFlags[%1$q]=true; end", state);
        elseif (state == "unitframe" or state == "reaction" or state == "frameType" or state == "known") then
            -- ignore these states
        elseif (_customStates[state]) then
            -- handle later
        elseif (DEBUG) then
            print("Unhandled State: " .. state);
        end
    end

    -- Update Unit States
    for unit, flags in pairs(_unitStates) do
        if (unit == "custom1" or unit == "custom2") then
            appendLine("stateValue=UnitMap[%1$q] and UnitExists(UnitMap[%1$q]) and (", unit);
            local tmp = {};
            if (band(flags, UnitStateFlags.help) == UnitStateFlags.help) then
                tinsert(tmp, format([[(PlayerCanAssist(UnitMap[%1$q]) and "help")]], unit));
            end
            if (band(flags, UnitStateFlags.harm) == UnitStateFlags.harm) then
                tinsert(tmp, format([[(PlayerCanAttack(UnitMap[%1$q]) and "harm")]], unit));
            end
            tinsert(tmp, format([[true]], unit));
            appendLine(table.concat(tmp, " or ") .. ") or false");
        elseif (SPECIAL_UNITS[unit]) then
            appendLine("stateValue=UnitMap[%1$q] and (", unit);
            local tmp = {};
            if (band(flags, UnitStateFlags.help) == UnitStateFlags.help) then
                tinsert(tmp, format([[(PlayerCanAssist(UnitMap[%1$q]) and "help")]], unit));
            end
            if (band(flags, UnitStateFlags.harm) == UnitStateFlags.harm) then
                tinsert(tmp, format([[(PlayerCanAttack(UnitMap[%1$q]) and "harm")]], unit));
            end
            tinsert(tmp, format([[true]], unit));
            appendLine(table.concat(tmp, " or ") .. ") or false");
        else
            appendLine("stateValue=UnitExists(%q) and (", unit);
            local tmp = {};
            if (band(flags, UnitStateFlags.help) == UnitStateFlags.help) then
                tinsert(tmp, format([[(PlayerCanAssist(%1$q) and "help")]], unit));
            end
            if (band(flags, UnitStateFlags.harm) == UnitStateFlags.harm) then
                tinsert(tmp, format([[(PlayerCanAttack(%1$q) and "harm")]], unit));
            end
            tinsert(tmp, format([[true]], unit));
            appendLine(table.concat(tmp, " or ") .. ") or false");
        end
        --appendLine([[print(%1$q, stateValue, UnitMap[%1$q])]], unit)
        appendLine([[if (UnitStates[%1$q] ~= stateValue) then UnitStates[%1$q]=stateValue;DirtyFlags["%1$s-exists"]=true; end]], unit);
    end

    -- Update Custom States
    for state, stateInfo in pairs(_customStates) do
        if (stateInfo) then
            if (stateInfo.mode == CUSTOM_STATE_MODES.MACRO_CONDITIONAL) then
                appendLine([[stateValue=SecureCmdOptionParse(CustomStateExpressions[%q] or "") and true or false]], stateInfo.name);
                appendLine([[if (States[%1$q] ~= stateValue) then self:RunAttribute("SetCustomState", %1$q, stateValue, true) end]], stateInfo.name);
            end
        end
    end

    appendLine([[
local shouldUpdate
for flag in pairs(DirtyFlags) do
    shouldUpdate = true
    if (MacroTextsMap[flag]) then
        self:RunAttribute("UpdateMacroTexts")
        break
    end
end

if (shouldUpdate) then
    --self:CallMethod("print", "Call UpdateBindings()")
    self:RunAttribute("UpdateBindings")
end
]]);

    appendLine([[end]]);

    local snippet = table.concat(_strArr, "\n");
    DebouncePrivate.BindingDriver:SetAttribute("_onattributechanged", snippet);

    if (DEBUG) then
        dump("_onattributechanged", { CopyTable(_strArr), snippet:len() });
    end
    wipe(_strArr);
end
