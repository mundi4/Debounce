local _, DebouncePrivate         = ...;
local LibDD                      = LibStub:GetLibrary("LibUIDropDownMenu-4.0");
local Constants                  = DebouncePrivate.Constants;
local LLL                        = DebouncePrivate.L;
local UIHelper                   = DebouncePrivate.UIHelper;

local MAX_BONUS_ACTIONBAR_OFFSET = 5;


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

local SEPARATOR                         = { isSeparator = true, };
local EditPopupMenuInfos;
local dump                              = DebouncePrivate.dump
local menuItemArray                     = {};
local elementData, action;
local listFrameOnShow;


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
                _bonusbarLabels[1] = GetSpellInfo(768);
                _bonusbarLabels[3] = GetSpellInfo(5487);
                _bonusbarLabels[4] = GetSpellInfo(24858);
            elseif (Constants.PLAYER_CLASS == "ROGUE") then
                _bonusbarLabels[1] = GetSpellInfo(1784);
            end
            for i = 0, MAX_BONUS_ACTIONBAR_OFFSET do
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

local function hasBit(button)
    local currVal = action[button.arg1] or 0;
    return bit.band(currVal, button.arg2) == button.arg2;
end

local function setBit(_, key, flag, checked)
    local currVal = action[key] or 0;
    if (checked) then
        action[key] = bit.bor(currVal, flag);
    else
        action[key] = bit.band(currVal, bit.bnot(flag));
    end
    action._dirty = true;
    DebouncePrivate.UpdateBindings();
    UIDropDownMenu_Refresh(L_UIDROPDOWNMENU_OPEN_MENU);
    listFrameOnShow();
end

local function compareValue(button)
    return action[button.arg1] == button.arg2;
end

local function setValue(_, key, value)
    action[key] = value;
    action._dirty = true;
    DebouncePrivate.UpdateBindings();
    UIDropDownMenu_Refresh(L_UIDROPDOWNMENU_OPEN_MENU);
    listFrameOnShow();
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

local function with(left, right)
    MergeTable(left, right);
    return left;
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
        highlight = { property },
        error = function() return DebouncePrivate.GetBindingIssue(action, property) end,
        menuItems = {
            unpack(BooleanConditionSubMenuItems(label, property, noTitle)),
        }
    };
    return ret;
end

local function BuildBitsConditionSubMenuItems(label, property, options, noTitle, noDisable)
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

    if (type(options) == "function") then
        options = options(label, property);
    end
    for _, option in ipairs(options) do
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
        highlight = { property },
        error = function() return DebouncePrivate.GetBindingIssue(action, property) end,
        menuItems = {
            unpack(BuildBitsConditionSubMenuItems(label, property, options, noTitle, noDisable)),
        }
    };
    return ret;
end

local function BuildMoveCopyMenuItems(isCopy)
    local ret = {};

    local func = function(_, tabID, sideTabID)
        tabID = tabID or UIHelper.GetSelectedTab();
        sideTabID = sideTabID or UIHelper.GetSelectedSideTab();
        local toLayerIndex = UIHelper.GetLayerID(tabID, sideTabID);
        UIHelper.MoveAction(elementData, toLayerIndex, isCopy);
        --CloseDropDownMenus(1);
    end
    local canShow;
    if (not isCopy) then
        canShow = function(self)
            return self.arg1 ~= UIHelper.GetSelectedTab() or self.arg2 ~= UIHelper.GetSelectedSideTab();
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
        local tabLabel = UIHelper.GetTabLabel(tabID);
        if (tabLabel) then
            for sideTabID = 1, #DebounceFrame.SideTabs do
                local sideTabLabel = UIHelper.GetSideTabaLabel(sideTabID);
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
                local menuItem = menuItemArray[button.value];
                if (menuItem) then
                    if (type(menuItem.disabled) == "function") then
                        local shouldEnable = not menuItem.disabled();
                        if (button:IsEnabled() ~= shouldEnable) then
                            setEnableDropdownButton(button, shouldEnable);
                        end
                    end

                    if (not button.colorCode and (menuItem.error or menuItem.highlight)) then
                        local color;
                        if (menuItem.error) then
                            local errorMessage;
                            local error = menuItem.error();
                            if (error) then
                                color = ERROR_COLOR;
                                errorMessage = rawget(LLL, error) or rawget(LLL, "BINDING_ERROR_" .. error);
                            end

                            if (errorMessage) then
                                button.tooltipTitle = button.tooltipTitle or "";
                                button.tooltipWarning = LLL["BINDING_ERROR_" .. error];
                            else
                                button.tooltipWarning = nil;
                            end
                        end

                        if (not color and menuItem.highlight) then
                            local highlight
                            if (type(menuItem.highlight) == "table") then
                                for _, prop in ipairs(menuItem.highlight) do
                                    if (action[prop] ~= nil) then
                                        highlight = true;
                                        break;
                                    end
                                end
                            elseif (type(menuItem.highlight) == "string") then
                                highlight = action[menuItem.highlight] ~= nil;
                            elseif (type(menuItem.highlight) == "function") then
                                highlight = menuItem.highlight();
                            end
                            if (highlight) then
                                color = menuItem.highlightColor or BLUE_FONT_COLOR;
                            end
                        end

                        if (color) then
                            local text = color:WrapTextInColorCode(menuItem.text);
                            button:SetText(text);
                        else
                            button:SetText(menuItem.text);
                        end
                    end
                end
            end
        end
        level = level - 1;
    until (level == 0);
end

EditPopupMenuInfos = {
    {
        text = LLL["CONVERT_TO_MACRO_TEXT"],
        notCheckable = true,
        canShow = function()
            return DebouncePrivate.CanConvertToMacroText(action)
        end,
        func = function()
            local original = CopyTable(action);
            if (DebouncePrivate.ConvertToMacroText(action)) then
                action._dirty = true;
                DebouncePrivate.UpdateBindings();
                local cancelFunc = function()
                    wipe(elementData.action);
                    MergeTable(elementData.action, original);
                    action._dirty = true;
                    DebouncePrivate.UpdateBindings();
                end
                DebounceMacroFrame:ShowEdit(elementData, cancelFunc);
            end
        end
    },
    {
        text = LLL["EDIT_MACRO"],
        notCheckable = true,
        canShow = function()
            return action.type == Constants.MACROTEXT;
        end,
        func = function()
            DebounceMacroFrame:ShowEdit(elementData);
        end
    },
    {
        text = LLL["UNBIND"],
        notCheckable = true,
        disabled = function() return action.key == nil; end,
        func = function()
            action.key = nil;
            action._dirty = true;
            DebouncePrivate.UpdateBindings();
            listFrameOnShow();
        end
    },
    {
        text = LLL["TARGET_UNIT"],
        canShow = function()
            return action.type == Constants.SPELL or action.type == Constants.ITEM or action.type == Constants.TARGET or action.type == Constants.FOCUS or action.type == Constants.TOGGLEMENU;
        end,
        notCheckable = true,
        tooltipTitle = LLL["TARGET_DESC"],
        menuItems = {
            {
                text = LLL["UNIT_DISABLE"],
                canShow = function()
                    return not (action.type == Constants.TARGET or action.type == Constants.FOCUS or action.type == Constants.TOGGLEMENU);
                end,
                checked = compareValue,
                func = setValue,
                arg1 = "unit",
                arg2 = nil,
            },
        },
        initFunc = function(self)
            local SORTED_UNIT_LIST = {
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

            for _, unit in ipairs(SORTED_UNIT_LIST) do
                local unitInfo = UIHelper.UNIT_INFOS[unit];
                local t = {
                    canShow = function() return unitInfo[action.type] ~= false; end,
                    text = unitInfo.name,
                    tooltipTitle = unitInfo.tooltipTitle,
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
        tooltipTitle = LLL["UNIT_FRAMES"],
        tooltipText = LLL["HOVER_OVER_UNIT_FRAMES_DESC"],
        tooltipWarning = DebouncePrivate.CliqueDetected and LLL["HOVER_OVER_UNIT_FRAMES_CLIQUE_WARNING"] or nil,
        initFunc = function(self)
            tinsert(self.menuItems, SEPARATOR);

            local disabledFunc = function()
                return action.hover ~= true;
            end
            local items;

            local REACTIONS = { "HELP", "HARM", "OTHER" };
            local reactionOptions = {};
            for _, reaction in ipairs(REACTIONS) do
                tinsert(reactionOptions, {
                    value = Constants["REACTION_" .. reaction],
                    label = LLL["REACTION_" .. reaction],
                });
            end
            items = BuildBitsConditionSubMenuItems("REACTIONS", "reactions", reactionOptions, false, true);
            for _, item in ipairs(items) do
                item.disabled = disabledFunc;
                tinsert(self.menuItems, item)
            end
            tinsert(self.menuItems, SEPARATOR);
            local UNIT_FRAME_TYPES = {
                "PLAYER",
                "PET",
                "GROUP",
                "TARGET",
                "BOSS",
                "ARENA",
                "UNKNOWN",
            };
            local frametypeOptions = {};
            for i = 1, #UNIT_FRAME_TYPES do
                local frameType = UNIT_FRAME_TYPES[i];
                local flag = Constants["FRAMETYPE_" .. frameType];
                local label = LLL["FRAMETYPE_" .. frameType];
                tinsert(frametypeOptions, { value = flag, label = label });
            end

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
                    local optionsArray = {};
                    for i = 0, MAX_BONUS_ACTIONBAR_OFFSET do
                        local label = GetActionBarTypeLabel(i);
                        if (label) then
                            tinsert(optionsArray, { value = 2 ^ i, label = label });
                        end
                    end

                    local items = BuildBitsConditionSubMenuItems("BONUSBAR", "bonusbars", optionsArray, true);
                    for _, item in ipairs(items) do
                        tinsert(self.menuItems, item)
                    end
                end
            },
            BuildBoolConditionMenuItem("SPECIALBAR", "specialbar", true),
            BuildBoolConditionMenuItem("EXTRABAR", "extrabar", true),
        },
        highlight = { "bonusbars", "specialbar", "extrabar" },
    },
    {
        text = LLL["CUSTOM_STATES"],
        hasArrow = true,
        notCheckable = true,
        menuItems = {},
        initFunc = function(self)
            self.highlight = {};
            for i = 1, Constants.MAX_NUM_CUSTOM_STATES do
                local t = BuildBoolConditionMenuItem(LLL["CUSTOMSTATE"], "$state" .. i);
                t.text = format(LLL["CUSTOM_STATE_NUM"], i);
                t.menuItems[1].text = t.text;
                tinsert(self.menuItems, t);
                tinsert(self.highlight, "$state" .. i);
            end
        end
    },
    SEPARATOR,
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
                        return action.priority == button.arg2 or action.priority == i;
                    end,
                    func = setValue,
                    arg1 = "priority",
                    arg2 = value,
                });
            end
        end,
        highlight = function()
            return action.priority ~= nil and action.priority ~= Constants.DEFAULT_PRIORITY;
        end
    },
    {
        text = LLL["MOVE_TO"],
        notCheckable = true,
        menuItems = {},
        initFunc = function(self)
            tAppendAll(self.menuItems, BuildMoveCopyMenuItems(false));
        end
    },
    {
        text = LLL["COPY_TO"],
        notCheckable = true,
        menuItems = {},
        initFunc = function(self)
            tAppendAll(self.menuItems, BuildMoveCopyMenuItems(true));
        end
    },
    {
        text = LLL["DELETE"],
        notCheckable = true,
        func = function()
            UIHelper.ShowDeleteConfirmationPopup(elementData);
        end
    }
};


local function AddDropDownButton(info, menuItem, index)
    if (menuItem.isSeparator) then
        UIDropDownMenu_AddSeparator(L_UIDROPDOWNMENU_MENU_LEVEL);
        return;
    end

    if (not menuItem.index) then
        tinsert(menuItemArray, menuItem);
        menuItem.index = #menuItemArray;
        menuItem.parentMenuItem = menuItemArray[L_UIDROPDOWNMENU_MENU_VALUE];
        if (menuItem.initFunc) then
            menuItem.initFunc(menuItem);
            menuItem.initFunc = nil;
        end
    end

    info.text = menuItem.text;
    info.value = menuItem.index;
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
    info.menuList = menuItem;
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
    info.tooltipBackdropStyle = menuItem.tooltipBackdropStyle;
    info.tooltipOnButton = true;

    if (menuItem.tooltipTitle) then
        info.text = info.text .. LLL["_HAS_TOOLTIP_SUFFIX"];
    end
    
    local addedButton = UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
    menuItem.currentButton = addedButton;
end

function DebouncePrivate.ShowEditPopup(dropdown, level, menuList)
    dropdown.listFrameOnShow = listFrameOnShow;
    elementData = dropdown.elementData;
    action = dropdown.action;

    local info = UIDropDownMenu_CreateInfo();
    if (level == 1) then
        info.text = UIHelper.NameAndIconFromElementData(elementData);
        info.isTitle = true;
        info.notCheckable = true;
        UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
    end


    local menuItems;
    if (menuList) then
        menuItems = menuList.menuItems;
    else
        menuItems = EditPopupMenuInfos;
    end
    if (menuItems) then
        for index, menuItem in ipairs(menuItems) do
            if (not menuItem.canShow or menuItem.canShow(menuItem)) then
                AddDropDownButton(info, menuItem, index);
            end
        end
    end
end

dump("EditPopupMenuInfos", EditPopupMenuInfos)
