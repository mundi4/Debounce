local _, DebouncePrivate    = ...;
local Constants             = DebouncePrivate.Constants;
local LLL                   = DebouncePrivate.L;
local DebounceUI            = DebouncePrivate.DebounceUI;

local dump                  = DebouncePrivate.dump
local GetSpellNameAndIconID = DebouncePrivate.GetSpellNameAndIconID;

local BINDING_TYPE_NAMES    = DebounceUI.BINDING_TYPE_NAMES;
local SEPARATOR             = { isSeparator = true, };
local ARRAY_MARKER          = {};
local SORTED_UNIT_LIST      = {
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
local USE_CHECKED_VALUE     = {};


local BINDING_CATEGORIES;
local BONUSBAR_NAMES;
local TAB_LIST;


local function range(startIndex, endIndex, func)
    local arr = {};
    for i = startIndex, endIndex do
        local t, eof = func(i);
        if (t ~= nil) then
            tinsert(arr, func(i));
        end
        if (eof) then
            break;
        end
    end
    arr[ARRAY_MARKER] = true;
    return arr;
end

local function _isSelected(data)
    local targetObj = data.targetObj;
    local value = data.value;
    if (value == USE_CHECKED_VALUE) then
        return targetObj[data.key] and true or false;
    else
        return targetObj[data.key] == value;
    end
end

local function _setSelected(data)
    local targetObj = data.targetObj;
    local value = data.value;
    if (value == USE_CHECKED_VALUE) then
        targetObj[data.key] = not targetObj[data.key];
    else
        targetObj[data.key] = value;
    end
    DebouncePrivate.UpdateBindings();
    return MenuResponse.Refresh;
end

-- local GenerateMenu;
-- local function GenerateMenuItem(dropdown, rootDescription, menuInfo, targetObj)
--     local shouldShow = menuInfo and (menuInfo.canShow == nil or menuInfo.canShow(menuInfo));
--     if (not shouldShow) then
--         return;
--     end

--     if (menuInfo.initFunc) then
--         menuInfo.initFunc(menuInfo);
--         menuInfo.initFunc = nil;
--     end

--     if (menuInfo == SEPARATOR or menuInfo.type == "divider") then
--         rootDescription:QueueDivider();
--         return;
--     elseif (menuInfo.type == "title") then
--         rootDescription:QueueTitle(menuInfo.text);
--         return;
--     end

--     local data = menuInfo.data or menuInfo;
--     data.targetObj = data.targetObj or targetObj;

--     local description;
--     if (menuInfo == SEPARATOR) then
--         rootDescription:QueueDivider();
--     elseif (menuInfo.type == "title") then
--         rootDescription:QueueTitle(menuInfo.text);
--     elseif (menuInfo.type == "radio") then
--         local isSelected, setSelected = menuInfo.isSelected, menuInfo.setSelected;
--         if (isSelected == nil) then
--             isSelected = _isSelected
--         end
--         if (setSelected == nil) then
--             setSelected = _setSelected
--         end
--         description = rootDescription:CreateRadio(menuInfo.text, isSelected, setSelected, data);
--     elseif (menuInfo.type == "checkbox") then
--         description = rootDescription:CreateCheckbox(menuInfo.text, menuInfo.isSelected, menuInfo.setSelected, menuInfo.args);
--     elseif (menuInfo.type == "bits") then
--         local isSelected, setSelected = menuInfo.isSelected, menuInfo.setSelected;
--         if (isSelected == nil) then
--             isSelected = _hasBit
--         end
--         if (setSelected == nil) then
--             setSelected = _toggleBit
--         end
--         description = rootDescription:CreateCheckbox(menuInfo.text, isSelected, setSelected, data);
--     else
--         description = rootDescription:CreateButton(menuInfo.text, menuInfo.func, menuInfo.args);
--     end

--     if (description) then
--         description:SetData(data);

--         if (menuInfo.isEnabled ~= nil) then
--             description:SetEnabled(menuInfo.isEnabled);
--         end

--         description:AddInitializer(function(button, elementDescription, menu)
--             local error = menuInfo.error;
--             if (type(error) == "function") then
--                 error = error(data);
--             end

--             if (error) then
--                 print("error")
--                 button.fontString:SetTextColor(ERROR_COLOR:GetRGB());
--             else
--                 local isActive = menuInfo.isActive;
--                 if (type(isActive) == "function") then
--                     isActive = isActive(menuInfo);
--                 end

--                 if (isActive) then
--                     button.fontString:SetTextColor(BLUE_FONT_COLOR:GetRGB());
--                 else
--                     button.fontString:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
--                 end
--             end

--             local instruction = menuInfo.tooltip;
--             if (type(instruction) == "function") then
--                 instruction = instruction(menuInfo);
--             end

--             if (instruction) then
--                 local text = elementDescription.text .. LLL["_HAS_TOOLTIP_SUFFIX"];
--                 button.fontString:SetText(text);
--             else
--                 button.fontString:SetText(elementDescription.text);
--                 -- elementDescription:SetTooltip(function(tooltip, elementDescription)
--                 --     GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
--                 --     GameTooltip_AddInstructionLine(tooltip, instruction);
--                 -- end);
--             end
--         end);




--         -- description:SetTooltip(function(tooltip, elementDescription)
--         --     local instruction = menuItem.instruction;
--         --     if (type(instruction) == "function") then
--         --         instruction = instruction(menuItem);
--         --     end

--         --     local error = menuItem.error;
--         --     if (type(error) == "function") then
--         --         error = error(menuItem);
--         --     end

--         --     if (instruction or error) then
--         --         GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
--         --         if (instruction) then
--         --             GameTooltip_AddInstructionLine(tooltip, instruction);
--         --         end
--         --         if (error) then
--         --             GameTooltip_AddErrorLine(tooltip, error);
--         --         end
--         --     end
--         -- end);

--         local children = menuInfo.menuItems;
--         if (children) then
--             if (type(children) == "function") then
--                 children = children(menuInfo);
--             end
--         end
--         if (children and #children > 0) then
--             description:CreateTitle(MenuUtil.GetElementText(description));
--             GenerateMenu(dropdown, description, children, data.targetObj);
--         end
--     end
-- end

-- function GenerateMenu(dropdown, rootDescription, menuInfoArr, targetObj)
--     for _, menuInfo in ipairs(menuInfoArr) do
--         GenerateMenuItem(dropdown, rootDescription, menuInfo, targetObj);
--     end
-- end

local function SetInstrcutionTooltip(description, text)
    description:SetTooltip(function(tooltip, elementDescription)
        GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
        GameTooltip_AddInstructionLine(tooltip, text);
    end);
end

local function SetErrorTooltip(description, text)
    description:SetTooltip(function(tooltip, elementDescription)
        GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
        GameTooltip_AddErrorLine(tooltip, text);
    end);
end

do

end
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------







--------------------------------------------------------------------------------
-- AddDropDown_Initialize
--------------------------------------------------------------------------------
local function BuildBindingCategories()
    if (BINDING_CATEGORIES) then
        return;
    end

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

    BINDING_CATEGORIES = {};
    for cat, bindingCategory in pairs(bindingsCategories) do
        BINDING_CATEGORIES[bindingCategory.order] = { cat = cat, bindings = bindingCategory.bindings };
    end
end

function DebounceUI.SetupAddDropdownMenu(dropdown, rootDescription)
    BuildBindingCategories();

    --GenerateMenu(dropdown, rootDescription, rootMenu);
    local description;

    description = rootDescription:CreateButton(BINDING_TYPE_NAMES[Constants.MACROTEXT], function()
        DebounceIconSelectorFrame.mode = IconSelectorPopupFrameModes.New;
        DebounceIconSelectorFrame:Show();
    end);
    SetInstrcutionTooltip(description, LLL["TYPE_MACROTEXT_DESC"]);

    description = rootDescription:CreateButton(BINDING_TYPE_NAMES[Constants.SETCUSTOM]);
    SetInstrcutionTooltip(description, LLL["TYPE_SETCUSTOM_DESC"]);
    for i = 1, 2 do
        local childDescription = description:CreateButton(LLL["TYPE_SETCUSTOM" .. i], function()
            DebounceFrame:AddNewAction(Constants.SETCUSTOM, i);
        end);
    end

    description = rootDescription:CreateButton(BINDING_TYPE_NAMES[Constants.SETSTATE]);
    SetInstrcutionTooltip(description, LLL["TYPE_SETSTATE_DESC"]);
    for stateIndex = 1, Constants.MAX_NUM_CUSTOM_STATES do
        local childDescription = description:CreateButton(format(LLL["CUSTOM_STATE_NUM"], stateIndex));
        childDescription:CreateButton(LLL["CUSTOM_STATE_TOGGLE"], function()
            DebounceFrame:AddNewAction(Constants.SETSTATE, bit.bor(Constants.SETCUSTOM_MODE_TOGGLE, stateIndex));
        end);
        childDescription:CreateButton(LLL["CUSTOM_STATE_TURN_ON"], function()
            DebounceFrame:AddNewAction(Constants.SETSTATE, bit.bor(Constants.SETCUSTOM_MODE_ON, stateIndex));
        end);
        childDescription:CreateButton(LLL["CUSTOM_STATE_TURN_OFF"], function()
            DebounceFrame:AddNewAction(Constants.SETSTATE, bit.bor(Constants.SETCUSTOM_MODE_OFF, stateIndex));
        end);
    end

    description = rootDescription:CreateButton(BINDING_TYPE_NAMES[Constants.COMMAND]);
    for i = 1, #BINDING_CATEGORIES do
        local bindingCategory = BINDING_CATEGORIES[i];
        local childDescription = description:CreateButton(bindingCategory.cat);
        for j = 1, #bindingCategory.bindings do
            local binding = bindingCategory.bindings[j];
            childDescription:CreateButton(binding[3], function()
                DebounceFrame:AddNewAction(Constants.COMMAND, binding[2]);
            end);
        end
    end

    description = rootDescription:CreateButton(LLL["MISC"]);
    for _, type in ipairs({ Constants.TARGET, Constants.FOCUS, Constants.TOGGLEMENU }) do
        local childDescription = description:CreateButton(BINDING_TYPE_NAMES[type]);
        for _, unit in ipairs(SORTED_UNIT_LIST) do
            local unitInfo = DebounceUI.UNIT_INFO[unit];
            if (unitInfo[type] ~= false) then
                childDescription:CreateButton(unitInfo.name, function()
                    DebounceFrame:AddNewAction(type, nil, nil, nil, { unit = unit });
                end);
            end
        end
    end

    do
        local childDescription = description:CreateButton(BINDING_TYPE_NAMES[Constants.WORLDMARKER]);
        for i = 1, NUM_WORLD_RAID_MARKERS do
            local index = WORLD_RAID_MARKER_ORDER[i];
            childDescription:CreateButton(_G["WORLD_MARKER" .. index], function()
                DebounceFrame:AddNewAction(Constants.WORLDMARKER, index);
            end);
        end
    end

    do
        local childDescription = description:CreateButton(BINDING_TYPE_NAMES[Constants.UNUSED], function()
            DebounceFrame:AddNewAction(Constants.UNUSED);
        end);
        SetInstrcutionTooltip(childDescription, LLL["TYPE_UNUSED_DESC"]);
    end
end

--------------------------------------------------------------------------------
-- CustomStatesDropDown
--------------------------------------------------------------------------------
function DebounceUI.SetupCustomStatesDropdownMenu(dropdown, rootDescription)
    --GenerateMenu(dropdown, rootDescription, rootMenu);

    for stateIndex = 1, Constants.MAX_NUM_CUSTOM_STATES do
        local stateOptions = DebouncePrivate.GetCustomStateOptions(stateIndex);
        local stateDescription = rootDescription:CreateButton(format(LLL["CUSTOM_STATE_NUM"], stateIndex));
        stateDescription:CreateTitle(MenuUtil.GetElementText(stateDescription));

        do
            local manualDescription = stateDescription:CreateRadio(LLL["CUSTOM_STATE_MODE_MANUAL"], _isSelected, _setSelected, { targetObj = stateOptions, key = "mode", value = Constants.CUSTOM_STATE_MODES.MANUAL });
            SetInstrcutionTooltip(manualDescription, LLL["CUSTOM_STATE_MODE_MANUAL_INSTRUCTION"]);

            manualDescription:CreateTitle(MenuUtil.GetElementText(manualDescription));
            manualDescription:CreateRadio(LLL["CUSTOM_STATE_ON"], _isSelected, _setSelected, { targetObj = stateOptions, key = "value", value = true });
            manualDescription:CreateRadio(LLL["CUSTOM_STATE_OFF"], _isSelected, _setSelected, { targetObj = stateOptions, key = "value", value = false });

            manualDescription:CreateDivider();
            manualDescription:CreateTitle(LLL["CUSTOM_STATE_INITIAL_VALUE"]);

            manualDescription:CreateRadio(LLL["CUSTOM_STATE_REMEMBER"], _isSelected, _setSelected, { targetObj = stateOptions, key = "initialValue", value = nil });
            manualDescription:CreateRadio(LLL["CUSTOM_STATE_LOGIN_ON"], _isSelected, _setSelected, { targetObj = stateOptions, key = "initialValue", value = true });
            manualDescription:CreateRadio(LLL["CUSTOM_STATE_LOGIN_OFF"], _isSelected, _setSelected, { targetObj = stateOptions, key = "initialValue", value = false });
        end

        do
            local conditionalDescription = stateDescription:CreateRadio(LLL["CUSTOM_STATE_MODE_MACRO_CONDITIONAL"], _isSelected, _setSelected,
                { targetObj = stateOptions, key = "mode", value = Constants.CUSTOM_STATE_MODES.MACRO_CONDITIONAL });
            SetInstrcutionTooltip(conditionalDescription, LLL["CUSTOM_STATE_MODE_MACRO_CONDITIONAL_DESC"]);

            conditionalDescription:CreateTitle(MenuUtil.GetElementText(conditionalDescription));
            conditionalDescription:CreateButton(LLL["CUSTOM_STATE_EDIT_VALUE"], function()
                DebounceUI.ShowInputBox({
                    text = LLL["CUSTOM_STATE_EDIT_VALUE_DESC"],
                    callback = function(value)
                        value = strtrim(value);
                        if (value == "") then
                            value = nil;
                        end
                        stateOptions.expr = value;
                        if (stateOptions.mode == Constants.CUSTOM_STATE_MODES.MACRO_CONDITIONAL) then
                            DebouncePrivate.UpdateBindings();
                        end
                    end,
                    maxLetters = 100,
                    currentValue = stateOptions.expr,
                });
            end);
        end

        stateDescription:CreateDivider();
        stateDescription:CreateCheckbox(LLL["CUSTOM_STATE_DISPLAY_MESSAGE"], _isSelected, _setSelected, { targetObj = stateOptions, key = "displayMessage", value = USE_CHECKED_VALUE });
    end
end

--------------------------------------------------------------------------------
-- OptionsDropDown
--------------------------------------------------------------------------------
function DebounceUI.SetupOptionsDropdownMenu(dropdown, rootDescription)
    --GenerateMenu(dropdown, rootDescription, rootMenu);

    do
        local unitframeDescription = rootDescription:CreateButton(LLL["UNITFRAME_OPTIONS"]);
        if (DebouncePrivate.CliqueDetected) then
            SetErrorTooltip(unitframeDescription, LLL["BINDING_ERROR_CANNOT_USE_HOVER_WITH_CLIQUE"]);
        end

        local useMouseDownDescription = unitframeDescription:CreateCheckbox(LLL["UNITFRAME_TRIGGER_ON_MOUSE_DOWN"], function()
            return DebouncePrivate.Options.unitframeUseMouseDown;
        end, function()
            DebouncePrivate.Options.unitframeUseMouseDown = not DebouncePrivate.Options.unitframeUseMouseDown;
            DebouncePrivate.ApplyOptions("unitframeUseMouseDown");
            return MenuResponse.Refresh;
        end);
        SetInstrcutionTooltip(useMouseDownDescription, LLL["UNITFRAME_TRIGGER_ON_MOUSE_DOWN_DESC"]);

        unitframeDescription:CreateDivider();

        local framesDescription = unitframeDescription:CreateButton(LLL["BLIZZARD_UNIT_FRAMES"]);
        for _, frameType in ipairs({ "player", "pet", "target", "party", "raid", "boss", "arena" }) do
            framesDescription:CreateCheckbox(LLL["BLIZZARD_UNIT_FRAMES_" .. strupper(frameType)], function()
                return DebouncePrivate.Options.blizzframes[frameType] ~= false;
            end, function()
                DebouncePrivate.Options.blizzframes[frameType] = not (DebouncePrivate.Options.blizzframes[frameType] ~= false);
                DebouncePrivate.UpdateBlizzardFrames();
                return MenuResponse.Refresh;
            end);
        end
    end

    do
        local specialUnitsDescription = rootDescription:CreateButton(LLL["SPECIAL_UNITS"]);
        local excludePlayerDescription = specialUnitsDescription:CreateButton(LLL["EXCLUDE_PLAYER"]);
        SetInstrcutionTooltip(excludePlayerDescription, LLL["EXCLUDE_PLAYER_DESC"]);
        for _, unit in ipairs({ "tank", "healer", "maintank", "mainassist" }) do
            excludePlayerDescription:CreateCheckbox(DebounceUI.UNIT_INFO[unit].name, function()
                return DebouncePrivate.Options.excludePlayer and DebouncePrivate.Options.excludePlayer[unit];
            end, function()
                if (not DebouncePrivate.Options.excludePlayer) then
                    DebouncePrivate.Options.excludePlayer = {};
                end
                DebouncePrivate.Options.excludePlayer[unit] = not DebouncePrivate.Options.excludePlayer[unit];
                local header = DebouncePrivate.GetUnitWatchHeader(unit);
                if (header) then
                    header:SetAttribute("showPlayer", not DebouncePrivate.Options.excludePlayer[unit]);
                end
                return MenuResponse.Refresh;
            end);
        end
    end
end

--------------------------------------------------------------------------------
-- EditDropDown_Initialize
--------------------------------------------------------------------------------
do
    local _dropdown, _elementData, _action;

    local function onActionValueChanged()
        _action._dirty = true;
        DebouncePrivate.UpdateBindings();
        return MenuResponse.Refresh;
    end

    local function actionValueEquals(args)
        local key, value = args.key, args.value;
        if (value == USE_CHECKED_VALUE) then
            return _action[key] and true or false;
        else
            return _action[key] == value;
        end
    end

    local function setActionValue(args)
        local key, value = args.key, args.value;
        if (value == USE_CHECKED_VALUE) then
            _action[key] = not _action[key];
            DebouncePrivate.UpdateBindings();
            return MenuResponse.Refresh;
        elseif (_action[key] ~= value) then
            _action[key] = value;
            onActionValueChanged();
            return MenuResponse.Refresh;
        end
    end

    local function _hasBit(data)
        local targetObj = data.targetObj or _action;
        local current = targetObj[data.key] or 0;
        return bit.band(current, data.value) == data.value;
    end

    local function _toggleBit(data)
        local targetObj = data.targetObj or _action;
        local current = targetObj[data.key] or 0;
        targetObj[data.key] = bit.bxor(current, data.value);
        onActionValueChanged();
        return MenuResponse.Refresh;
    end

    local function AppendDisable(description, prefix, property)
        local text = rawget(LLL, prefix .. "_DISABLE") or LLL["DISABLE"];
        description:CreateRadio(LLL["DISABLE"], actionValueEquals, setActionValue, { key = property, value = nil });
    end

    local function AppendYesNo(description, prefix, property)
        description:CreateRadio(rawget(LLL, prefix .. "_YES") or YES, actionValueEquals, setActionValue, { key = property, value = true });
        description:CreateRadio(rawget(LLL, prefix .. "_NO") or NO, actionValueEquals, setActionValue, { key = property, value = false });
    end

    local function AppendDisableYesNo(description, prefix, property)
        AppendDisable(description, prefix, property);
        AppendYesNo(description, prefix, property);
    end

    local function AppendCheckboxes(parentDescription, key, items, callback)
        for _, item in ipairs(items) do
            local isSelected, setSelected = item.isSelected, item.setSelected;
            if (isSelected == nil) then
                isSelected = _hasBit;
            end
            if (setSelected == nil) then
                setSelected = _toggleBit;
            end
            local description = parentDescription:CreateCheckbox(item.text, isSelected, setSelected, { key = key, value = item.value });
            if (callback) then
                callback(description, item);
            end
        end
    end

    local function CreateActionMenuItemGroup(parentDescription, text, key, isActive, error, instruction, skipTitle)
        local txt = rawget(LLL, text);
        if (txt) then
            if (not instruction) then
                instruction = rawget(LLL, text .. "_DESC");
            end
        else
            txt = text;
        end

        local description = parentDescription:CreateButton(txt);
        description:AddInitializer(function(button, elementDescription, menu)
            local color = HIGHLIGHT_FONT_COLOR;
            local err;
            if (error) then
                if (type(error) == "function") then
                    err = error(key);
                else
                    err = error;
                end
            elseif (key) then
                err = DebouncePrivate.GetBindingIssue(_action, key);
            end

            if (err) then
                color = ERROR_COLOR;
                err = rawget(LLL, err) or rawget(LLL, "BINDING_ERROR_" .. err);
            else
                local active = isActive;
                if (active) then
                    if (type(active) == "function") then
                        active = active(key);
                    end
                elseif (key) then
                    active = _action[key] ~= nil;
                end

                if (active) then
                    color = BLUE_FONT_COLOR;
                end
            end

            button.fontString:SetTextColor(color:GetRGB());

            elementDescription:SetTooltip(function(tooltip, elementDescription)
                local first = true;
                if (instruction) then
                    GameTooltip_AddInstructionLine(tooltip, instruction);
                    first = false;
                end

                if (err) then
                    if (not first) then
                        GameTooltip_AddBlankLineToTooltip(tooltip);
                    end
                    GameTooltip_AddErrorLine(tooltip, err);
                end
            end);
        end);

        if (not skipTitle) then
            description:QueueTitle(MenuUtil.GetElementText(description));
        end

        return description;
    end

    local function CreateTargetUnitSubmenu(parentDescription, label, unit)
        -- local optionsDescription = parentDescription:CreateRadio(label,
        --     function()
        --         return _action.checkedUnit == unit and _action.checkedUnitValue ~= nil;
        --     end,
        --     function()
        --         if (_action.checkedUnit ~= unit) then
        --             _action.checkedUnit = unit;
        --             _action.checkedUnitValue = true;
        --         end
        --         DebouncePrivate.UpdateBindings();
        --         return MenuResponse.Refresh;
        --     end
        -- );
        --local optionsDescription = parentDescription:CreateButton(label);
        local optionsDescription = CreateActionMenuItemGroup(parentDescription, label, "unit", function()
            return _action.checkedUnit == unit and _action.checkedUnitValue ~= nil;
        end, nil, nil, true);

        local titleDescription = optionsDescription:CreateTitle(MenuUtil.GetElementText(optionsDescription));
        if (unit == true) then
            optionsDescription:AddInitializer(function(button, elementDescription, menu)
                if (_action.unit and _action.unit ~= "none") then
                    button.fontString:SetText(format(LLL["SELECTED_TARGET_UNIT"], DebounceUI.UNIT_INFO[_action.unit].name));
                else
                    button.fontString:SetText(LLL["SELECTED_TARGET_UNIT_EMPTY"]);
                end
            end);

            titleDescription:AddInitializer(function(button, elementDescription, menu)
                if (_action.unit and _action.unit ~= "none") then
                    button.fontString:SetText(format(LLL["SELECTED_TARGET_UNIT"], DebounceUI.UNIT_INFO[_action.unit].name));
                else
                    button.fontString:SetText(LLL["SELECTED_TARGET_UNIT_EMPTY"]);
                end
            end);
        end

        optionsDescription:CreateRadio(LLL["CONDITION_UNIT_EXISTS"],
            function()
                return _action.checkedUnit == unit and _action.checkedUnitValue == true;
            end,
            function()
                _action.checkedUnit = unit;
                _action.checkedUnitValue = true;
                onActionValueChanged();
                return MenuResponse.Refresh;
            end
        );

        optionsDescription:CreateRadio(LLL["CONDITION_UNIT_HELP"],
            function()
                return _action.checkedUnit == unit and _action.checkedUnitValue == "help";
            end,
            function()
                _action.checkedUnit = unit;
                _action.checkedUnitValue = "help";
                onActionValueChanged();
                return MenuResponse.Refresh;
            end
        );

        optionsDescription:CreateRadio(LLL["CONDITION_UNIT_HARM"],
            function()
                return _action.checkedUnit == unit and _action.checkedUnitValue == "harm";
            end,
            function()
                _action.checkedUnit = unit;
                _action.checkedUnitValue = "harm";
                onActionValueChanged();
                return MenuResponse.Refresh;
            end
        );

        optionsDescription:CreateRadio(LLL["CONDITION_UNIT_DOES_NOT_EXIST"],
            function()
                return _action.checkedUnit == unit and _action.checkedUnitValue == false;
            end,
            function()
                _action.checkedUnit = unit;
                _action.checkedUnitValue = false;
                onActionValueChanged();
                return MenuResponse.Refresh;
            end
        );

        return optionsDescription;
    end

    local function hoverConditionIsOn()
        return _action.hover and true or false;
    end

    local function CreateConvertToMacroTextMenuItem(parentDescription)
        if (DebouncePrivate.CanConvertToMacroText(_action)) then
            parentDescription:CreateButton(LLL["CONVERT_TO_MACRO_TEXT"], function()
                local original = CopyTable(_action);
                if (DebouncePrivate.ConvertToMacroText(_action)) then
                    onActionValueChanged();
                    local cancelFunc = function()
                        wipe(_elementData.action);
                        MergeTable(_elementData.action, original);
                        onActionValueChanged();
                    end
                    DebounceMacroFrame:ShowEdit(_elementData, cancelFunc);
                end
            end);
        end
    end

    local function EditMacroTextMenuItem(parentDescription)
        if (_action.type == Constants.MACROTEXT) then
            parentDescription:CreateButton(LLL["EDIT_MACRO"], function()
                DebounceMacroFrame:ShowEdit(_elementData);
            end);
        end
    end

    local function CreateUnbindMenuItem(parentDescription)
        local description = parentDescription:CreateButton(LLL["UNBIND"], function()
            _action.key = nil;
            onActionValueChanged();
            return MenuResponse.Refresh;
        end);
        description:SetEnabled(function()
            return _action.key ~= nil;
        end);
    end

    local function CreateTargetUnitMenuItem(parentDescription)
        if not (_action.type == Constants.SPELL or _action.type == Constants.ITEM or _action.type == Constants.TARGET or _action.type == Constants.FOCUS or _action.type == Constants.TOGGLEMENU) then
            return;
        end

        local description = CreateActionMenuItemGroup(parentDescription, "TARGET_UNIT", "unit");

        if (not (_action.type == Constants.TARGET or _action.type == Constants.FOCUS or _action.type == Constants.TOGGLEMENU)) then
            description:CreateRadio(LLL["UNIT_DISABLE"], actionValueEquals, setActionValue, { key = "unit", value = nil });
        end

        for _, unit in ipairs(SORTED_UNIT_LIST) do
            local unitInfo = DebounceUI.UNIT_INFO[unit];
            if (unitInfo[_action.type] ~= false) then
                local unitDescription = description:CreateRadio(unitInfo.name, actionValueEquals, setActionValue, { key = "unit", value = unit });

                -- TODO locale 파일 업데이트 할 것.
                -- local instructionTooltip = rawget(LLL, "TARGET_UNIT_" .. strupper(unit) .. "_DESC") or (unitInfo.type and "TARGET_UNIT_" .. strupper(unitInfo.type) .. "_DESC");
                -- if (instructionTooltip) then
                --     SetInstrcutionTooltip(optionDescription, instructionTooltip);
                -- end

                if (unitInfo.tooltipTitle) then
                    SetInstrcutionTooltip(unitDescription, unitInfo.tooltipTitle);
                end
            end
        end

        return description;
    end

    local function CreateHoverMenu(parentDescription)
        local description = CreateActionMenuItemGroup(parentDescription, "CONDITION_HOVER", "hover");
        AppendDisableYesNo(description, "CONDITION_HOVER", "hover");

        description:CreateDivider();
        description:CreateTitle(LLL["CONDITION_REACTIONS"]);

        AppendCheckboxes(description, "reactions", {
            { text = LLL["REACTION_HELP"],  value = Constants["REACTION_HELP"] },
            { text = LLL["REACTION_HARM"],  value = Constants["REACTION_HARM"] },
            { text = LLL["REACTION_OTHER"], value = Constants["REACTION_OTHER"] },
        }, function(elementDescription)
            elementDescription:SetEnabled(hoverConditionIsOn);
        end);

        description:CreateDivider();
        description:CreateTitle(LLL["CONDITION_FRAMETYPES"]);

        AppendCheckboxes(description, "frameTypes", {
            { text = LLL["FRAMETYPE_PLAYER"],  value = Constants["FRAMETYPE_PLAYER"] },
            { text = LLL["FRAMETYPE_PET"],     value = Constants["FRAMETYPE_PET"] },
            { text = LLL["FRAMETYPE_GROUP"],   value = Constants["FRAMETYPE_GROUP"] },
            { text = LLL["FRAMETYPE_TARGET"],  value = Constants["FRAMETYPE_TARGET"] },
            { text = LLL["FRAMETYPE_BOSS"],    value = Constants["FRAMETYPE_BOSS"] },
            { text = LLL["FRAMETYPE_ARENA"],   value = Constants["FRAMETYPE_ARENA"] },
            { text = LLL["FRAMETYPE_UNKNOWN"], value = Constants["FRAMETYPE_UNKNOWN"] },
        }, function(elementDescription)
            elementDescription:SetEnabled(hoverConditionIsOn);
        end);

        description:CreateDivider();
        local ignoreHoverUnit = description:CreateCheckbox(LLL["IGNORE_HOVER_UNIT"], actionValueEquals, setActionValue, { key = "ignoreHoverUnit", value = USE_CHECKED_VALUE });
        SetInstrcutionTooltip(ignoreHoverUnit, LLL["IGNORE_HOVER_UNIT_DESC"]);
        ignoreHoverUnit:SetEnabled(hoverConditionIsOn);
    end

    local function CreateUnitConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_UNIT", "checkedUnit",
            -- isActive
            function()
                if (not _action.checkedUnit or _action.checkedUnitValue == nil) then
                    return false;
                end
                if (_action.checkedUnit == true and (not _action.unit or _action.unit == "none")) then
                    return false;
                end
                return true;
            end
        );

        description:CreateRadio(LLL["DISABLE"],
            function()
                return _action.checkedUnit == nil or _action.checkedUnitValue == nil;
            end,
            function()
                _action.checkedUnit = nil;
                _action.checkedUnitValue = nil;
                onActionValueChanged();
                return MenuResponse.Refresh;
            end
        );

        if (_action.type == Constants.SPELL or _action.type == Constants.ITEM or _action.type == Constants.TARGET or _action.type == Constants.FOCUS or _action.type == Constants.TOGGLEMENU) then
            CreateTargetUnitSubmenu(description, "SELECTED_TARGET_UNIT_EMPTY", true);
        end

        for _, unit in ipairs(SORTED_UNIT_LIST) do
            local unitInfo = DebounceUI.UNIT_INFO[unit];
            if not (unit == "player" or unit == "none") then
                CreateTargetUnitSubmenu(description, unitInfo.name, unit);
            end
        end
    end

    local function CreateGroupConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_GROUP", "groups");
        AppendDisable(description, "CONDITION_GROUP", "groups");
        AppendCheckboxes(description, "groups", {
            { text = LLL["GROUP_NONE"],  value = Constants.GROUP_NONE },
            { text = LLL["GROUP_PARTY"], value = Constants.GROUP_PARTY },
            { text = LLL["GROUP_RAID"],  value = Constants.GROUP_RAID },
        });
    end

    local function CreateCombatConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_COMBAT", "combat");
        AppendDisableYesNo(description, "CONDITION_COMBAT", "combat");
    end

    local function CreateShapeshiftConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_SHAPESHIFT", "forms");
        AppendDisable(description, "CONDITION_SHAPESHIFT", "forms");
        AppendCheckboxes(description, "forms", range(0, 10, function(formId)
            local shapeshiftName;
            if (formId == 0) then
                shapeshiftName = LLL["NO_SHAPESHIFT"];
            else
                local _, _, _, spellID = GetShapeshiftFormInfo(formId);
                shapeshiftName = spellID and GetSpellNameAndIconID(spellID) or nil;
            end
            local label = format("[form:%d]", formId);
            if (shapeshiftName) then
                label = format("%s (%s)", label, shapeshiftName);
            end
            return { text = label, value = 2 ^ formId };
        end));
    end

    local function CreateStealthConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_STEALTH", "stealth");
        AppendDisableYesNo(description, "CONDITION_STEALTH", "stealth");
    end

    local function CreatePetConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_PET", "pet");
        AppendDisableYesNo(description, "CONDITION_PET", "pet");
    end

    local function CreatePetBattleConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_PETBATTLE", "petbattle");
        AppendDisableYesNo(description, "CONDITION_PETBATTLE", "petbattle");
    end

    local function CreateActionbarConditionMenu(rootDescription)
        if (BONUSBAR_NAMES == nil) then
            BONUSBAR_NAMES = {
                [0] = LLL["DEFAULT"],
                [5] = GetFlyoutInfo(229)
            };
            if (Constants.PLAYER_CLASS == "DRUID") then
                BONUSBAR_NAMES[1] = GetSpellNameAndIconID(768);
                BONUSBAR_NAMES[3] = GetSpellNameAndIconID(5487);
                BONUSBAR_NAMES[4] = GetSpellNameAndIconID(24858);
            elseif (Constants.PLAYER_CLASS == "ROGUE") then
                BONUSBAR_NAMES[1] = GetSpellNameAndIconID(1784);
            end
        end

        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_ACTIONBARS", nil,
            -- isActive
            function()
                return _action.bonusbars ~= nil or _action.bars ~= nil or _action.specialbar ~= nil or _action.extrabar ~= nil;
            end
        );

        local bonusbarDescription = CreateActionMenuItemGroup(description, "CONDITION_BONUSBAR", "bonusbars");
        AppendDisable(bonusbarDescription, "CONDITION_BONUSBAR", "bonusbars");
        AppendCheckboxes(bonusbarDescription, "bonusbars", range(0, Constants.MAX_BONUS_ACTIONBAR_OFFSET, function(offset)
            local name = BONUSBAR_NAMES[offset];
            local label = format("[bonusbar:%d]", offset);
            if (name) then
                label = format("%s (%s)", label, name);
            end
            return { text = label, value = 2 ^ offset };
        end));

        local specialbarDescription = CreateActionMenuItemGroup(description, "CONDITION_SPECIALBAR", "specialbar");
        AppendDisableYesNo(specialbarDescription, "CONDITION_SPECIALBAR", "specialbar");

        local extrabarDescription = CreateActionMenuItemGroup(description, "CONDITION_EXTRABAR", "extrabar");
        AppendDisableYesNo(extrabarDescription, "CONDITION_EXTRABAR", "extrabar");
    end

    local function CreateCustomStateConditionMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "CONDITION_CUSTOM_STATES", nil,
            -- isActive
            function()
                for i = 1, Constants.MAX_NUM_CUSTOM_STATES do
                    if (_action["$state" .. i] ~= nil) then
                        return true;
                    end
                end
                return false;
            end
        );

        for i = 1, Constants.MAX_NUM_CUSTOM_STATES do
            local stateDescription = CreateActionMenuItemGroup(description, format(LLL["CUSTOM_STATE_NUM"], i), "$state" .. i);
            AppendDisableYesNo(stateDescription, "CONDITION_CUSTOM_STATE", "$state" .. i);
        end
    end

    local function CreatePriorityMenu(rootDescription)
        local description = CreateActionMenuItemGroup(rootDescription, "PRIORITY", "priority",
            -- isActive
            function()
                return _action.priority ~= nil and _action.priority ~= Constants.DEFAULT_PRIORITY;
            end
        );

        for i = 1, 5 do
            local value = i;
            if (value == Constants.DEFAULT_PRIORITY) then
                value = nil;
            end
            description:CreateRadio(LLL["PRIORITY" .. i],
                function()
                    return _action.priority == value or _action.priority == i;
                end,
                function()
                    _action.priority = value;
                    onActionValueChanged();
                    return MenuResponse.Refresh;
                end
            );
        end
    end

    local function CreateMoveCopyMenu(rootDescription, isCopy)
        if (TAB_LIST == nil) then
            TAB_LIST = {};
            for tabID = 1, #DebounceFrame.Tabs do
                local tabLabel = DebounceUI.GetTabLabel(tabID);
                if (tabLabel) then
                    for sideTabID = 1, #DebounceFrame.SideTabs do
                        local sideTabLabel = DebounceUI.GetSideTabaLabel(sideTabID);
                        if (sideTabLabel) then
                            tinsert(TAB_LIST, {
                                tabID = tabID,
                                sideTabID = sideTabID,
                                label = format("%s - %s", tabLabel, sideTabLabel),
                                isCurrentTab = tabID == DebounceUI.GetSelectedTab() and sideTabID == DebounceUI.GetSelectedSideTab(),
                            });
                        end
                    end
                end
            end
        end


        local optionsDescription = rootDescription:CreateButton(isCopy and LLL["COPY_TO"] or LLL["MOVE_TO"]);
        optionsDescription:CreateTitle(MenuUtil.GetElementText(optionsDescription));

        local func = function(args)
            local tabID = args[1];
            local sideTabID = args[2];
            local toLayerIndex = DebounceUI.GetLayerID(tabID, sideTabID);
            DebounceUI.MoveAction(_elementData, toLayerIndex, isCopy);
        end

        for _, tabInfo in ipairs(TAB_LIST) do
            if (isCopy or tabInfo.tabID ~= DebounceUI.GetSelectedTab() or tabInfo.sideTabID ~= DebounceUI.GetSelectedSideTab()) then
                local label = tabInfo.label;
                if (tabInfo.tabID == DebounceUI.GetSelectedTab() and tabInfo.sideTabID == DebounceUI.GetSelectedSideTab()) then
                    label = LLL["CURRENT_TAB"];
                end
                optionsDescription:CreateButton(
                    label,
                    func,
                    { tabInfo.tabID, tabInfo.sideTabID }
                );
            end
        end
    end

    local function CreateDeleteMenu(rootDescription)
        rootDescription:CreateButton(LLL["DELETE"], function()
            DebounceUI.ShowDeleteConfirmationPopup(_elementData);
        end);
    end



    function DebounceUI.SetupEditDropdownMenu(dropdown, rootDescription, elementData)
        _dropdown = dropdown;
        _elementData = elementData;
        _action = elementData.action;

        -- GenerateMenu(dropdown, rootDescription, rootMenu, elementData.action);
        -- if true then
        --     return;
        -- end

        local description;
        local title = DebounceUI.NameAndIconFromElementData(elementData);
        rootDescription:CreateTitle(title);
        rootDescription:SetTag(DebounceUI.ActionMenuRootTag, 1);

        CreateConvertToMacroTextMenuItem(rootDescription);

        EditMacroTextMenuItem(rootDescription);

        CreateUnbindMenuItem(rootDescription);

        CreateTargetUnitMenuItem(rootDescription);

        --
        -- Special Conditions
        --
        rootDescription:CreateDivider();
        rootDescription:CreateTitle(LLL["SPECIAL_CONDITIONS"]);

        CreateHoverMenu(rootDescription);

        CreateUnitConditionMenu(rootDescription);

        CreateGroupConditionMenu(rootDescription);

        CreateCombatConditionMenu(rootDescription);

        CreateShapeshiftConditionMenu(rootDescription);

        CreateStealthConditionMenu(rootDescription);

        CreatePetConditionMenu(rootDescription);

        CreatePetBattleConditionMenu(rootDescription);

        CreateActionbarConditionMenu(rootDescription);

        CreateCustomStateConditionMenu(rootDescription);

        --
        -- Other Options
        --
        rootDescription:CreateDivider();
        rootDescription:CreateTitle(LLL["OTHER_OPTIONS"]);

        CreatePriorityMenu(rootDescription);

        CreateMoveCopyMenu(rootDescription, false);

        CreateMoveCopyMenu(rootDescription, true);

        CreateDeleteMenu(rootDescription);
    end
end

