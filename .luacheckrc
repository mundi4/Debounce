std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
	"BlizzardInterfaceCode/**",
	"DebounceTest/**",
}
ignore = {
	"212/self",
	"1/[A-Z][A-Z][A-Z0-9_]+", -- three letter+ uppercase constants (WoW convention)
	"211", -- unused local variable
	"212", -- unused argument
	"213", -- unused loop variable
}
globals = {
	-- Lua standard (exposed as WoW globals)
	"bit",
	"format",
	"sort",
	"strlower",
	"strmatch",
	"strsplit",
	"strsub",
	"strtrim",
	"strupper",
	"tinsert",
	"tremove",
	"wipe",
	"hooksecurefunc",

	-- WoW core API
	"C_AddOns",
	"C_ClassTalents",
	"C_CreatureInfo",
	"C_Item",
	"C_MountJournal",
	"C_Spell",
	"C_SpellBook",
	"C_SpecializationInfo",
	"C_Timer",
	"C_TradeSkillUI",

	-- Frame / Secure handler
	"CreateFrame",
	"RegisterUnitWatch",
	"SecureHandlerSetFrameRef",
	"SecureHandlerExecute",
	"SecureHandlerWrapScript",
	"SecureHandlerUnwrapScript",
	"ClearOverrideBindings",
	"SetOverrideBindingClick",

	-- Unit functions
	"UnitClass",
	"UnitName",
	"UnitGUID",
	"UnitExists",
	"UnitIsUnit",
	"UnitIsPlayer",
	"UnitInRaid",
	"UnitInParty",
	"UnitSelectionColor",
	"InCombatLockdown",
	"IsInRaid",
	"IsInGroup",

	-- Spell / macro / binding
	"GetShapeshiftFormInfo",
	"GetFlyoutInfo",
	"GetMacroInfo",
	"GetNumMacros",
	"CreateMacro",
	"EditMacro",
	"DeleteMacro",
	"GetNumBindings",
	"GetBinding",
	"GetBindingText",
	"GetConvertedKeyOrButton",
	"CreateKeyChordStringFromTable",
	"IsMetaKey",
	"GetCVarBool",
	"GetTime",

	-- Cursor / Input
	"GetCursorInfo",
	"ClearCursor",
	"GetMouseFoci",
	"DoesAncestryInclude",
	"IsAltKeyDown",
	"IsControlKeyDown",
	"IsShiftKeyDown",
	"IsMetaKeyDown",
	"IsLeftAltKeyDown",
	"IsRightAltKeyDown",
	"IsLeftControlKeyDown",
	"IsRightControlKeyDown",
	"IsLeftShiftKeyDown",
	"IsRightShiftKeyDown",
	"PlaySound",

	-- UI utility
	"CreateColor",
	"GetClassColorObj",
	"CopyTable",
	"CreateTableEnumerator",
	"CreateDataProvider",
	"CreateScrollBoxListLinearView",
	"CreateAndInitFromMixin",
	"CreateFromMixins",

	-- FrameXML: panels, tooltips, menus
	"GameTooltip",
	"GameTooltip_SetTitle",
	"GameTooltip_AddErrorLine",
	"GameTooltip_AddNormalLine",
	"GameTooltip_AddHighlightLine",
	"GameTooltip_AddInstructionLine",
	"GameTooltip_AddBlankLineToTooltip",
	"GameTooltip_Hide",
	"StaticPopup_ShowCustomGenericConfirmation",
	"StaticPopup_ShowCustomGenericInputBox",
	"StaticPopup_FindVisible",
	"StaticPopup_Hide",
	"PanelTemplates_TabResize",
	"PanelTemplates_SetNumTabs",
	"PanelTemplates_SetTab",
	"PanelTemplates_SetTabEnabled",
	"ScrollUtil",
	"ScrollBoxConstants",

	-- Menu API
	"Menu",
	"MenuUtil",
	"MenuResponse",
	"IconSelectorPopupFrameModes",
	"IconDataProviderMixin",
	"DropdownButtonMixin",

	-- FrameXML: frames
	"UIParent",
	"MacroFrame",
	"PlayerFrame",
	"PetFrame",
	"TargetFrame",
	"TargetFrameToT",
	"FocusFrame",
	"FocusFrameToT",
	"PartyFrame",
	"SecureStateDriverManager",
	"CompactUnitFrame_SetUpFrame",
	"ScrollingEdit_OnTextChanged",

	-- WoW constants
	"MAX_PARTY_MEMBERS",
	"MAX_RAID_MEMBERS",
	"MAX_ARENA_ENEMIES",
	"MAX_BOSS_FRAMES",
	"MAX_ACCOUNT_MACROS",
	"MAX_CHARACTER_MACROS",
	"NUM_WORLD_RAID_MARKERS",
	"WORLD_RAID_MARKER_ORDER",
	"SOUNDKIT",
	"ChatTypeInfo",
	"DEFAULT_CHAT_FRAME",

	-- Binding headers
	"BINDING_HEADER_MOVEMENT",
	"BINDING_HEADER_INTERFACE",
	"BINDING_HEADER_CHAT",
	"BINDING_HEADER_TARGETING",
	"BINDING_HEADER_RAID_TARGET",
	"BINDING_HEADER_VEHICLE",
	"BINDING_HEADER_CAMERA",
	"BINDING_HEADER_MISC",
	"BINDING_HEADER_OTHER",

	-- Slash command constants
	"SLASH_SCRIPT1",
	"SLASH_CANCELFORM1",
	"SLASH_CAST1",
	"SLASH_USE1",

	-- Color objects
	"GRAY_FONT_COLOR",
	"DISABLED_FONT_COLOR",
	"ERROR_COLOR",
	"INACTIVE_COLOR",
	"HIGHLIGHT_FONT_COLOR",
	"BLUE_FONT_COLOR",
	"WARNING_FONT_COLOR",
	"FULL_PLAYER_NAME",
	"YES",
	"NO",

	-- Libraries
	"LibStub",

	-- Addon globals (set by this addon)
	"DebouncePublic",
	"DebouncePrivate",
	"DebounceVars",
	"DebounceVarsPerChar",
	"Debounce_CompartmentFunc",
	"SlashCmdList",

	-- Mixin globals (for XML templates)
	"DebounceLineMixin",
	"DebounceTabMixin",
	"DebounceSideTabMixin",
	"DebouncePortraitMixin",
	"DebounceFrameMixin",

	-- Named frames
	"DebounceFrame",
	"DebounceOverviewFrame",
	"DebounceKeybindFrame",
	"DebounceMacroFrame",
	"DebounceIconSelectorFrame",

	-- Optional third-party addons
	"Clique",
	"Grid2",
	"DevTool",
	"ViragDevTool_AddData",
}
