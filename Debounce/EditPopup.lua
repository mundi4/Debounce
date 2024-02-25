local _, DebouncePrivate = ...;
local LibDD              = LibStub:GetLibrary("LibUIDropDownMenu-4.0");
local Constants          = DebouncePrivate.Constants;
local LLL                = DebouncePrivate.L;
local DebounceUI         = DebouncePrivate.DebounceUI;


local MAX_BONUS_ACTIONBAR_OFFSET              = 5;
local dump                                    = DebouncePrivate.dump

local DROPDOWNLIST1                           = "L_DropDownList1";
local DROPDOWNLIST2                           = "L_DropDownList2";
local UIDropDownMenu_GetCurrentDropDown       = GenerateClosure(LibDD.UIDropDownMenu_GetCurrentDropDown, LibDD);
local UIDropDownMenu_Initialize               = GenerateClosure(LibDD.UIDropDownMenu_Initialize, LibDD);
local UIDropDownMenu_CreateInfo               = GenerateClosure(LibDD.UIDropDownMenu_CreateInfo, LibDD);
local UIDropDownMenu_AddButton                = GenerateClosure(LibDD.UIDropDownMenu_AddButton, LibDD);
local UIDropDownMenu_AddSeparator             = GenerateClosure(LibDD.UIDropDownMenu_AddSeparator, LibDD);
local UIDropDownMenu_GetSelectedValue         = GenerateClosure(LibDD.UIDropDownMenu_GetSelectedValue, LibDD);
local UIDropDownMenu_SetSelectedValue         = GenerateClosure(LibDD.UIDropDownMenu_SetSelectedValue, LibDD);
local UIDropDownMenu_Refresh                  = GenerateClosure(LibDD.UIDropDownMenu_Refresh, LibDD);
local UIDropDownMenu_RefreshAll               = GenerateClosure(LibDD.UIDropDownMenu_RefreshAll, LibDD);
local ToggleDropDownMenu                      = GenerateClosure(LibDD.ToggleDropDownMenu, LibDD);
local CloseDropDownMenus                      = GenerateClosure(LibDD.CloseDropDownMenus, LibDD);
local HideDropDownMenu                        = GenerateClosure(LibDD.HideDropDownMenu, LibDD);
local UIDropDownMenu_SetDropdownButtonEnabled = GenerateClosure(LibDD.UIDropDownMenu_SetDropdownButtonEnabled, LibDD);

local SEPARATOR                               = { isSeparator = true, };

local BINDING_TYPE_NAMES                      = DebounceUI.BINDING_TYPE_NAMES;

local SORTED_UNIT_LIST                        = {
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

local function AddDropDownButton(info, menuItem)
    if (menuItem.isSeparator) then
        UIDropDownMenu_AddSeparator(L_UIDROPDOWNMENU_MENU_LEVEL);
        return;
    end

    if (menuItem.initFunc) then
        menuItem.initFunc(menuItem);
        menuItem.initFunc = nil;
    end

    if (menuItem.onShow) then
        menuItem.onShow(menuItem);
    end

    info.text = menuItem.text;
    info.value = menuItem;
    info.menuList = menuItem;
    info.isTitle = menuItem.isTitle;
    if (not info.isTitle) then
        info.disabled = nil;
    end
    if (type(menuItem.disabled) == "function") then
        info.disabled = menuItem.disabled() and true or false;
        info.disabledFunc = menuItem.disabled;
    else
        info.disabled = menuItem.disabled and true or false;
        info.disabledFunc = nil;
    end
    info.notCheckable = menuItem.notCheckable;
    info.isNotRadio = menuItem.isNotRadio;
    --info.hasArrow = menuItem.hasArrow;
    info.hasArrow = menuItem.menuItems and #menuItem.menuItems > 0;
    if (menuItem.keepShownOnClick ~= nil) then
        info.keepShownOnClick = true;
    else
        if (menuItem.notCheckable) then
            info.keepShownOnClick = false;
        else
            info.keepShownOnClick = true;
        end
    end
    info.checked = menuItem.checked;
    info.func = menuItem.func;
    info.arg1 = menuItem.arg1;
    info.arg2 = menuItem.arg2;
    info.tooltipTitle = menuItem.tooltipTitle;
    info.tooltipText = menuItem.tooltipText;
    info.tooltipWarning = menuItem.tooltipWarning;
    info.tooltipInstruction = menuItem.tooltipInstruction;
    if (not info.tooltipTitle and (info.tooltipText or info.tooltipInstruction or info.tooltipWarning)) then
        info.tooltipTitle = info.text;
        menuItem.tooltipTitle = info.tooltipTitle;
    end
    info.tooltipBackdropStyle = menuItem.tooltipBackdropStyle;
    info.tooltipOnButton = true;

    if (info.tooltipTitle and strsub(info.text, -strlen(LLL["_HAS_TOOLTIP_SUFFIX"])) ~= LLL["_HAS_TOOLTIP_SUFFIX"]) then
        info.text = info.text .. LLL["_HAS_TOOLTIP_SUFFIX"];
        menuItem.text = info.text;
    end

    local addedButton = UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
    menuItem.currentButton = addedButton;
end

local function SetDropdownButtonEnabled(button, enabled)
    UIDropDownMenu_SetDropdownButtonEnabled(button, enabled);
    if (enabled) then
        button.Check:SetDesaturated(false);
        button.Check:SetAlpha(1);
        button.UnCheck:SetDesaturated(false);
        button.UnCheck:SetAlpha(1);
    else
        button.Check:SetDesaturated(true);
        button.Check:SetAlpha(0.5);
        button.UnCheck:SetDesaturated(true);
        button.UnCheck:SetAlpha(0.5);
    end
end

local function with(left, right)
    MergeTable(left, right);
    return left;
end

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
    return arr;
end

local function transform(tbl, op)
    local result = {};
    for k, v in ipairs(tbl) do
        local t, eof = op(v);
        if (t ~= nil) then
            table.insert(result, t);
        end
        if (eof) then
            break;
        end
    end
    return result;
end

local function append(table, element)
    tinsert(table, element);
    return table;
end

local function appendAll(table, addedArray)
    for i, element in ipairs(addedArray) do
        tinsert(table, element);
    end
    return table;
end

-- AddDropDown_Initialize
do
    local TopLevelMenuItems = {
        {
            text = BINDING_TYPE_NAMES[Constants.MACROTEXT],
            notCheckable = true,
            func = function()
                DebounceIconSelectorFrame.mode = IconSelectorPopupFrameModes.New;
                DebounceIconSelectorFrame:Show();
            end,
        },
        {
            text = BINDING_TYPE_NAMES[Constants.SETCUSTOM],
            notCheckable = true,
            menuItems = range(1, 2, function(i)
                return {
                    text = LLL["TYPE_SETCUSTOM" .. i],
                    notCheckable = true,
                    func = function()
                        DebounceFrame:AddNewAction(Constants.SETCUSTOM, i);
                    end,

                }
            end),
            tooltipText = LLL["TYPE_SETCUSTOM_DESC"]
        },
        {
            text = BINDING_TYPE_NAMES[Constants.SETSTATE],
            notCheckable = true,
            menuItems = range(1, Constants.MAX_NUM_CUSTOM_STATES, function(stateIndex)
                local callback = function(_, mode)
                    local value = bit.bor(mode, stateIndex);
                    DebounceFrame:AddNewAction(Constants.SETSTATE, value);
                end

                local label = format(LLL["CUSTOM_STATE_NUM"], stateIndex);
                return {
                    text = label,
                    notCheckable = true,
                    menuItems = {
                        {
                            text = label,
                            isTitle = true,
                            notCheckable = true,
                        },
                        {
                            text = LLL["CUSTOM_STATE_TURN_ON"],
                            notCheckable = true,
                            func = callback,
                            arg1 = Constants.SETCUSTOM_MODE_ON,
                        },
                        {
                            text = LLL["CUSTOM_STATE_TURN_OFF"],
                            notCheckable = true,
                            func = callback,
                            arg1 = Constants.SETCUSTOM_MODE_OFF,
                        },
                        {
                            text = LLL["CUSTOM_STATE_TOGGLE"],
                            notCheckable = true,
                            func = callback,
                            arg1 = Constants.SETCUSTOM_MODE_TOGGLE,
                        },
                    }
                };
            end),
            tooltipText = LLL["TYPE_SETSTATE_DESC"],
        },
        {
            text = BINDING_TYPE_NAMES[Constants.COMMAND],
            notCheckable = true,
            menuItems = {

            },
            initFunc = function(self)
                local PAGE_SIZE = 15;

                local commandList;
                do
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

                    commandList = {};
                    for cat, bindingCategory in pairs(bindingsCategories) do
                        commandList[bindingCategory.order] = { cat = cat, bindings = bindingCategory.bindings };
                    end
                end

                local makeBindingList = function(parent, category, page)
                    local start = (page - 1) * PAGE_SIZE + 1;
                    appendAll(parent.menuItems, range(start, start + PAGE_SIZE - 1, function(i)
                        local binding = category.bindings[i];
                        if (not binding) then
                            return nil, true;
                        end
                        local command = binding[2];
                        local name = _G["BINDING_NAME_" .. command] or command;
                        return {
                            text = name,
                            notCheckable = true,
                            func = function()
                                DebounceFrame:AddNewAction(Constants.COMMAND, command);
                            end,
                        };
                    end));
                end

                appendAll(self.menuItems, transform(commandList, function(category)
                    if (#category.bindings > 0) then
                        local t = {
                            text = category.cat,
                            notCheckable = true,
                            menuItems = {},
                            initFunc = function(self)
                                local numPages = ceil(#category.bindings / PAGE_SIZE);
                                if (numPages > 1) then
                                    appendAll(self.menuItems, range(1, numPages, function(page)
                                        return {
                                            text = format(LLL["BINDING_COMMAND_PAGE_FORMAT"], page, numPages),
                                            notCheckable = true,
                                            menuItems = {},
                                            initFunc = function(self)
                                                makeBindingList(self, category, page);
                                            end
                                        }
                                    end));
                                else
                                    makeBindingList(self, category, 1);
                                end
                            end
                        };

                        return t;
                    end
                end));
            end
        },
        {
            text = LLL["MISC"],
            notCheckable = true,
            menuItems = {
                [4] = {
                    text = BINDING_TYPE_NAMES[Constants.WORLDMARKER],
                    notCheckable = true,
                    menuItems = range(1, NUM_WORLD_RAID_MARKERS, function(i)
                        local index = WORLD_RAID_MARKER_ORDER[i];
                        return {
                            text = _G["WORLD_MARKER" .. index],
                            notCheckable = true,
                            func = function()
                                DebounceFrame:AddNewAction(Constants.WORLDMARKER, index);
                            end
                        };
                    end),
                },
                [5] = {
                    text = BINDING_TYPE_NAMES[Constants.UNUSED],
                    notCheckable = true,
                    func = function()
                        DebounceFrame:AddNewAction(Constants.UNUSED);
                    end,
                    tooltipText = LLL["TYPE_UNUSED_DESC"],
                },
                unpack(transform({ Constants.TARGET, Constants.FOCUS, Constants.TOGGLEMENU }, function(type)
                    return {
                        text = BINDING_TYPE_NAMES[type],
                        notCheckable = true,
                        menuItems = transform(SORTED_UNIT_LIST, function(unit)
                            local unitInfo = DebounceUI.UNIT_INFOS[unit];
                            if (unitInfo[type] ~= false) then
                                return {
                                    text = unitInfo.name,
                                    notCheckable = true,
                                    func = function()
                                        DebounceFrame:AddNewAction(type, nil, nil, nil, { unit = unit });
                                    end,
                                    tooltipText = unitInfo.tooltipTitle,
                                    tooltipWarning = unitInfo.tooltipWarning,
                                };
                            end
                        end)
                    }
                end)),
            },
        },
    };

    function DebounceUI.AddDropDown_Initialize(dropdown, level, menuList)
        local info = UIDropDownMenu_CreateInfo();

        -- if (level == 1) then
        --     info.text = DebounceUI.NameAndIconFromElementData(_elementData);
        --     info.isTitle = true;
        --     info.notCheckable = true;
        --     UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
        -- end

        local menuItems;
        if (menuList) then
            menuItems = menuList.menuItems;
        else
            menuItems = TopLevelMenuItems;
        end

        if (menuItems) then
            for index, menuItem in ipairs(menuItems) do
                if (not menuItem.canShow or menuItem.canShow(menuItem)) then
                    AddDropDownButton(info, menuItem, index);
                end
            end
        end
    end

    dump("AddDropDownMenu", TopLevelMenuItems);
end

-- EditDropDown_Initialize
do
    local _dropdown, _elementData, _action;
    local listFrameOnShow, listFrameOnHide;

    local ACTION_DEFAULT_VALUES = {
        priority = Constants.DEFAULT_PRIORITY
    };

    local function hasBit(button)
        local currVal = _action[button.arg1] or 0;
        return bit.band(currVal, button.arg2) == button.arg2;
    end

    local function setBit(_, key, flag, checked)
        local currVal = _action[key] or 0;
        if (checked) then
            _action[key] = bit.bor(currVal, flag);
        else
            _action[key] = bit.band(currVal, bit.bnot(flag));
        end
        _action._dirty = true;
        DebouncePrivate.UpdateBindings();
        UIDropDownMenu_Refresh(L_UIDROPDOWNMENU_OPEN_MENU);
        listFrameOnShow();
    end

    local function compareValue(button)
        return _action[button.arg1] == button.arg2;
    end

    local function setValue(_, key, value)
        _action[key] = value;
        _action._dirty = true;
        DebouncePrivate.UpdateBindings();
        UIDropDownMenu_Refresh(L_UIDROPDOWNMENU_OPEN_MENU);
        listFrameOnShow();
    end



    local function BooleanConditionSubMenuItems(label, property, noTitle)
        local retArray = {};
        if (not noTitle) then
            tinsert(retArray, {
                text = LLL["CONDITION_" .. label],
                isTitle = true,
                notCheckable = true,
            });
        end
        tinsert(retArray, {
            text = LLL["DISABLE"],
            checked = compareValue,
            func = setValue,
            arg1 = property,
            arg2 = nil,
        });
        tinsert(retArray, {
            text = LLL["CONDITION_" .. label .. "_YES"],
            checked = compareValue,
            func = setValue,
            arg1 = property,
            arg2 = true,
        });
        tinsert(retArray, {
            text = LLL["CONDITION_" .. label .. "_NO"],
            checked = compareValue,
            func = setValue,
            arg1 = property,
            arg2 = false,
        });
        return retArray;
    end

    local function BuildBoolConditionMenuItem(label, property, noTitle)
        --local text = rawget(LLL, LLL["CONDITION_" .. label]) or label
        local ret = {
            text = rawget(LLL, "CONDITION_" .. label) or label,
            hasArrow = true,
            notCheckable = true,
            properties = { property },
            error = function() return DebouncePrivate.GetBindingIssue(_action, property) end,
            menuItems = {
                unpack(BooleanConditionSubMenuItems(label, property, noTitle)),
            }
        };
        return ret;
    end

    local function BuildBitsConditionSubMenuItems(label, property, optionsList, noTitle, noDisable)
        local retArray = {};
        if (not noTitle) then
            tinsert(retArray, {
                text = LLL["CONDITION_" .. label],
                isTitle = true,
                notCheckable = true,
                colorCode = nil,
                func = nil,
            });
        end
        if (not noDisable) then
            tinsert(retArray, {
                text = LLL["DISABLE"],
                checked = compareValue,
                func = setValue,
                arg1 = property,
                arg2 = nil,
            });
        end

        if (type(optionsList) == "function") then
            optionsList = optionsList(label, property);
        end
        for _, option in ipairs(optionsList) do
            tinsert(retArray, {
                text = option.label,
                checked = hasBit,
                isNotRadio = true,
                func = setBit,
                arg1 = property,
                arg2 = option.value,
            });
        end

        return retArray;
    end

    local function BuildBitConditionMenuItem(label, property, options, noTitle, noDisable)
        local ret = {
            text = LLL["CONDITION_" .. label],
            hasArrow = true,
            notCheckable = true,
            properties = { property },
            error = function() return DebouncePrivate.GetBindingIssue(_action, property) end,
            menuItems = {
                unpack(BuildBitsConditionSubMenuItems(label, property, options, noTitle, noDisable)),
            }
        };
        return ret;
    end

    local function BuildMoveCopyMenuItems(isCopy)
        local ret = {};

        local func = function(_, tabID, sideTabID)
            tabID = tabID or DebounceUI.GetSelectedTab();
            sideTabID = sideTabID or DebounceUI.GetSelectedSideTab();
            local toLayerIndex = DebounceUI.GetLayerID(tabID, sideTabID);
            DebounceUI.MoveAction(_elementData, toLayerIndex, isCopy);
        end

        local canShow;
        if (not isCopy) then
            canShow = function(self)
                return self.arg1 ~= DebounceUI.GetSelectedTab() or self.arg2 ~= DebounceUI.GetSelectedSideTab();
            end
        end

        if (isCopy) then
            tinsert(ret, {
                text = LLL["CURRENT_TAB"],
                notCheckable = true,
                func = func,
            });
        end

        for tabID = 1, #DebounceFrame.Tabs do
            local tabLabel = DebounceUI.GetTabLabel(tabID);
            if (tabLabel) then
                for sideTabID = 1, #DebounceFrame.SideTabs do
                    local sideTabLabel = DebounceUI.GetSideTabaLabel(sideTabID);
                    if (sideTabLabel) then
                        local t = {
                            canShow = canShow,
                            text = format("%s - %s", tabLabel, sideTabLabel),
                            notCheckable = true,
                            func = func,
                            arg1 = tabID,
                            arg2 = sideTabID,
                        };
                        tinsert(ret, t);
                    end
                end
            end
        end
        return ret;
    end

    function listFrameOnShow()
        local level = L_UIDROPDOWNMENU_MENU_LEVEL;
        repeat
            local listFrame = _G["L_DropDownList" .. level];
            if (listFrame and listFrame:IsShown()) then
                for index = 1, L_UIDROPDOWNMENU_MAXBUTTONS do
                    local button = _G["L_DropDownList" .. level .. "Button" .. index];
                    if (not button or not button:IsShown()) then
                        break;
                    end

                    local menuItem = button.value;
                    if (menuItem) then
                        if (type(menuItem.disabled) == "function") then
                            local shouldEnable = not menuItem.disabled();
                            if (button:IsEnabled() ~= shouldEnable) then
                                SetDropdownButtonEnabled(button, shouldEnable);
                            end
                        end

                        if (menuItem.properties) then
                            if (button:IsEnabled()) then
                                local properties = menuItem.properties;
                                if (type(properties) == "string") then
                                    properties = { properties };
                                end

                                local color;
                                local error, errorMessage;

                                for _, prop in ipairs(properties) do
                                    error = DebouncePrivate.GetBindingIssue(_action, prop);
                                    if (error) then
                                        break;
                                    end
                                end

                                if (error) then
                                    color = ERROR_COLOR;
                                    errorMessage = rawget(LLL, error) or rawget(LLL, "BINDING_ERROR_" .. error);
                                end

                                if (not menuItem.tooltipWarning) then
                                    if (errorMessage) then
                                        button.tooltipTitle = menuItem.tooltipTitle or menuItem.text;
                                        button.tooltipWarning = LLL["BINDING_ERROR_" .. error];
                                    else
                                        button.tooltipTitle = menuItem.tooltipTitle;
                                        button.tooltipWarning = nil;
                                    end
                                end

                                if (not color) then
                                    for _, prop in ipairs(properties) do
                                        if (_action[prop] ~= nil and _action[prop] ~= ACTION_DEFAULT_VALUES[prop]) then
                                            color = menuItem.highlightColor or BLUE_FONT_COLOR;
                                            break;
                                        end
                                    end
                                end

                                if (color) then
                                    local text = menuItem.text;
                                    text = color:WrapTextInColorCode(text);
                                    button:SetText(text);
                                else
                                    button:SetText(menuItem.text);
                                end
                            else
                                button.tooltipTitle = menuItem.tooltipTitle;
                                button.tooltipWarning = menuItem.tooltipWarning;
                                button:SetText(menuItem.text);
                            end
                        end



                        -- if (not button.colorCode and (menuItem.error or menuItem.highlight)) then
                        --     local color;
                        --     if (menuItem.error) then
                        --         local errorMessage;
                        --         local error = menuItem.error();
                        --         if (error) then
                        --             color = ERROR_COLOR;
                        --             errorMessage = rawget(LLL, error) or rawget(LLL, "BINDING_ERROR_" .. error);
                        --         end

                        --         if (errorMessage) then
                        --             button.tooltipTitle = button.tooltipTitle or menuItem.text;
                        --             button.tooltipWarning = LLL["BINDING_ERROR_" .. error];
                        --         else
                        --             button.tooltipWarning = nil;
                        --         end
                        --     end

                        --     if (not color and menuItem.highlight) then
                        --         local highlight
                        --         if (type(menuItem.highlight) == "table") then
                        --             for _, prop in ipairs(menuItem.highlight) do
                        --                 if (_action[prop] ~= nil and _action[prop] ~= ACTION_DEFAULT_VALUES[prop]) then
                        --                     highlight = true;
                        --                     break;
                        --                 end
                        --             end
                        --         elseif (type(menuItem.highlight) == "string") then
                        --             highlight = _action[menuItem.highlight] ~= nil;
                        --         elseif (type(menuItem.highlight) == "function") then
                        --             highlight = menuItem.highlight();
                        --         end
                        --         if (highlight) then
                        --             color = menuItem.highlightColor or BLUE_FONT_COLOR;
                        --         end
                        --     end

                        --     if (color) then
                        --         local text = menuItem.text;
                        --         text = color:WrapTextInColorCode(text);
                        --         button:SetText(text);
                        --     else
                        --         button:SetText(menuItem.text);
                        --     end
                        -- end
                    end
                end
            end
            level = level - 1;
        until (level == 0);

        --_dropdown.button:Update();
    end

    function listFrameOnHide()
        DebounceFrame:Update();
    end

    local TopLevelMenuItems = {
        {
            text = LLL["CONVERT_TO_MACRO_TEXT"],
            notCheckable = true,
            canShow = function()
                return DebouncePrivate.CanConvertToMacroText(_action)
            end,
            func = function()
                local original = CopyTable(_action);
                if (DebouncePrivate.ConvertToMacroText(_action)) then
                    _action._dirty = true;
                    DebouncePrivate.UpdateBindings();
                    local cancelFunc = function()
                        wipe(_elementData.action);
                        MergeTable(_elementData.action, original);
                        _action._dirty = true;
                        DebouncePrivate.UpdateBindings();
                    end
                    DebounceMacroFrame:ShowEdit(_elementData, cancelFunc);
                end
            end
        },
        {
            text = LLL["EDIT_MACRO"],
            notCheckable = true,
            canShow = function()
                return _action.type == Constants.MACROTEXT;
            end,
            func = function()
                DebounceMacroFrame:ShowEdit(_elementData);
            end
        },
        {
            text = LLL["UNBIND"],
            notCheckable = true,
            disabled = function() return _action.key == nil; end,
            func = function()
                _action.key = nil;
                _action._dirty = true;
                DebouncePrivate.UpdateBindings();
                listFrameOnShow();
            end
        },
        {
            text = LLL["TARGET_UNIT"],
            canShow = function()
                return _action.type == Constants.SPELL or _action.type == Constants.ITEM or _action.type == Constants.TARGET or _action.type == Constants.FOCUS or _action.type == Constants.TOGGLEMENU;
            end,
            notCheckable = true,
            tooltipText = LLL["TARGET_DESC"],
            menuItems = {
                {
                    text = LLL["UNIT_DISABLE"],
                    canShow = function()
                        return not (_action.type == Constants.TARGET or _action.type == Constants.FOCUS or _action.type == Constants.TOGGLEMENU);
                    end,
                    checked = compareValue,
                    func = setValue,
                    arg1 = "unit",
                    arg2 = nil,
                },
            },
            initFunc = function(self)
                for _, unit in ipairs(SORTED_UNIT_LIST) do
                    local unitInfo = DebounceUI.UNIT_INFOS[unit];
                    local t = {
                        canShow = function() return unitInfo[_action.type] ~= false; end,
                        text = unitInfo.name,
                        tooltipText = unitInfo.tooltipTitle,
                        checked = compareValue,
                        func = setValue,
                        arg1 = "unit",
                        arg2 = unit,
                    };
                    tinsert(self.menuItems, t);
                end
            end,
        },
        SEPARATOR,
        {
            text = LLL["SPECIAL_CONDITIONS"],
            isTitle = true,
            notCheckable = true,
        },
        with(BuildBoolConditionMenuItem("HOVER", "hover", true), {
            --tooltipTitle = LLL["UNIT_FRAMES"],
            tooltipText = LLL["HOVER_OVER_UNIT_FRAMES_DESC"],
            tooltipWarning = DebouncePrivate.CliqueDetected and LLL["HOVER_OVER_UNIT_FRAMES_CLIQUE_WARNING"] or nil,
            initFunc = function(self)
                local items;
                local disabledFunc = function()
                    return _action.hover ~= true;
                end

                tinsert(self.menuItems, SEPARATOR);

                local reactionOptions = transform({ "HELP", "HARM", "OTHER" }, function(reaction)
                    return { value = Constants["REACTION_" .. reaction], label = LLL["REACTION_" .. reaction] };
                end);

                items = BuildBitsConditionSubMenuItems("REACTIONS", "reactions", reactionOptions, false, true);
                for _, item in ipairs(items) do
                    item.disabled = disabledFunc;
                    tinsert(self.menuItems, item)
                end

                tinsert(self.menuItems, SEPARATOR);

                local frametypeOptions = transform({ "PLAYER", "PET", "GROUP", "TARGET", "BOSS", "ARENA", "UNKNOWN", }, function(frameType)
                    local flag = Constants["FRAMETYPE_" .. frameType];
                    local label = LLL["FRAMETYPE_" .. frameType];
                    return { value = flag, label = label };
                end);

                items = BuildBitsConditionSubMenuItems("FRAMETYPES", "frameTypes", frametypeOptions, false, true);
                for _, item in ipairs(items) do
                    item.disabled = disabledFunc;
                    tinsert(self.menuItems, item)
                end
            end
        }),
        BuildBitConditionMenuItem("GROUP", "groups", {
            { value = Constants.GROUP_NONE,  label = LLL["GROUP_NONE"] },
            { value = Constants.GROUP_PARTY, label = LLL["GROUP_PARTY"] },
            { value = Constants.GROUP_RAID,  label = LLL["GROUP_RAID"] },
        }, true),
        BuildBoolConditionMenuItem("COMBAT", "combat", true),
        BuildBitConditionMenuItem("SHAPESHIFT", "forms", range(0, 10, function(formId)
            local shapeshiftName;
            if (formId == 0) then
                shapeshiftName = LLL["NO_SHAPESHIFT"];
            else
                local _, _, _, spellID = GetShapeshiftFormInfo(formId);
                shapeshiftName = spellID and GetSpellInfo(spellID) or nil;
            end
            local label = format("[form:%d]", formId);
            if (shapeshiftName) then
                label = format("%s (%s)", label, shapeshiftName);
            end
            return { value = 2 ^ formId, label = label };
        end), true),
        BuildBoolConditionMenuItem("STEALTH", "stealth", true),
        BuildBoolConditionMenuItem("PET", "pet", true),
        BuildBoolConditionMenuItem("PETBATTLE", "petbattle", true),
        {
            text = LLL["ACTIONBARS"],
            hasArrow = true,
            notCheckable = true,
            menuItems = {
                {
                    text = LLL["BONUSBAR"],
                    hasArrow = true,
                    notCheckable = true,
                    menuItems = {
                    },
                    initFunc = function(self)
                        local bonusbarNames = {
                            [0] = LLL["DEFAULT"],
                            [5] = GetFlyoutInfo(229)
                        };

                        if (Constants.PLAYER_CLASS == "DRUID") then
                            bonusbarNames[1] = GetSpellInfo(768);
                            bonusbarNames[3] = GetSpellInfo(5487);
                            bonusbarNames[4] = GetSpellInfo(24858);
                        elseif (Constants.PLAYER_CLASS == "ROGUE") then
                            bonusbarNames[1] = GetSpellInfo(1784);
                        end

                        local options = range(0, 5, function(offset)
                            local name = bonusbarNames[offset];
                            local label;
                            if (name) then
                                label = format("[bonusbar:%d] (%s)", offset, name);
                            else
                                label = format("[bonusbar:%d]", offset);
                            end
                            return { value = 2 ^ offset, label = label };
                        end);

                        local items = BuildBitsConditionSubMenuItems("BONUSBAR", "bonusbars", options, true);
                        for _, item in ipairs(items) do
                            tinsert(self.menuItems, item)
                        end
                    end
                },
                BuildBoolConditionMenuItem("SPECIALBAR", "specialbar", true),
                BuildBoolConditionMenuItem("EXTRABAR", "extrabar", true),
            },
            properties = { "bonusbars", "specialbar", "extrabar" },
        },
        {
            text = LLL["CUSTOM_STATES"],
            hasArrow = true,
            notCheckable = true,
            menuItems = {},
            initFunc = function(self)
                self.properties = {};
                for i = 1, Constants.MAX_NUM_CUSTOM_STATES do
                    local t = BuildBoolConditionMenuItem(LLL["CUSTOMSTATE"], "$state" .. i);
                    t.text = format(LLL["CUSTOM_STATE_NUM"], i);
                    t.menuItems[1].text = t.text;
                    tinsert(self.menuItems, t);
                    tinsert(self.properties, "$state" .. i);
                end
            end
        },
        SEPARATOR,
        {
            text = LLL["OTHER_OPTIONS"],
            isTitle = true,
            notCheckable = true,
        },
        {
            text = LLL["PRIORITY"],
            hasArrow = true,
            notCheckable = true,
            menuItems = {},
            initFunc = function(self)
                for i = 1, 5 do
                    local value = i;
                    if (value == Constants.DEFAULT_PRIORITY) then
                        value = nil;
                    end
                    tinsert(self.menuItems, {
                        text = LLL["PRIORITY" .. i],
                        checked = function(button)
                            return _action.priority == button.arg2 or _action.priority == i;
                        end,
                        func = setValue,
                        arg1 = "priority",
                        arg2 = value,
                    });
                end
            end,
            properties = { "priority" }
        },
        {
            text = LLL["MOVE_TO"],
            notCheckable = true,
            menuItems = {},
            initFunc = function(self)
                appendAll(self.menuItems, BuildMoveCopyMenuItems(false));
            end
        },
        {
            text = LLL["COPY_TO"],
            notCheckable = true,
            menuItems = {},
            initFunc = function(self)
                appendAll(self.menuItems, BuildMoveCopyMenuItems(true));
            end
        },
        {
            text = LLL["DELETE"],
            notCheckable = true,
            func = function()
                DebounceUI.ShowDeleteConfirmationPopup(_elementData);
            end
        }
    };

    function DebounceUI.EditDropDown_Initialize(dropdown, level, menuList)
        _dropdown = dropdown;
        _elementData = dropdown.elementData;
        _action = dropdown.elementData.action;

        dropdown.listFrameOnShow = listFrameOnShow;
        dropdown.onHide = listFrameOnHide;

        local info = UIDropDownMenu_CreateInfo();
        if (level == 1) then
            info.text = DebounceUI.NameAndIconFromElementData(_elementData);
            info.isTitle = true;
            info.notCheckable = true;
            UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
        end

        local menuItems;
        if (menuList) then
            menuItems = menuList.menuItems;
        else
            menuItems = TopLevelMenuItems;
        end
        if (menuItems) then
            for _, menuItem in ipairs(menuItems) do
                if (menuItem and (not menuItem.canShow or menuItem.canShow(menuItem))) then
                    AddDropDownButton(info, menuItem);
                end
            end
        end
    end

    dump("EditDropDownMenu", TopLevelMenuItems);
end
