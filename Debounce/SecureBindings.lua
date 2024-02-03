local _, DebouncePrivate = ...;
local BindingDriver      = DebouncePrivate.BindingDriver;

local function applyConstants(str)
    return str:gsub("CONSTANTS%.([_A-Za-z0-9]+)", function(m)
        local value = DebouncePrivate.Constants[m];
        assert(value ~= nil, m);
        if (type(value) == "string") then
            return format("%q", value);
        else
            return tostring(value);
        end
    end);
end

function BindingDriver:print(...)
    if (DebouncePrivate.DEBUG) then
        print(GetTime(), ...)
    end
end

function BindingDriver:dump(name, ...)
    DebouncePrivate.dump(name, { ... })
end

SecureHandlerSetFrameRef(BindingDriver, "clickDelegate", DebouncePrivate.ClickDelegate);
SecureHandlerExecute(BindingDriver, [[
	debounce_driver = self
	ccframes = newtable()
	
	ClickAttrDefaultValues = newtable()
	ClickButton = self:GetFrameRef("clickDelegate")
	ClickButtonName = ClickButton:GetName()
	ClickDelegates = newtable()
	BindingsMap = newtable()
	UnitBindingsMap = newtable()
	UnitMap = newtable()
	DirtyFlags = newtable()
	States = newtable()
	UnitStates = newtable()

	deferUpdate = false
]]);

for _, frame in pairs(DebouncePrivate.SpecialUnitClickDelegateFrames) do
    SecureHandlerSetFrameRef(BindingDriver, "clickDelegate", frame);
    SecureHandlerExecute(BindingDriver, [[
		local frame = self:GetFrameRef("clickDelegate")
		local alias = frame:GetAttribute("alias")
		ClickDelegates[alias] = frame
		ClickDelegates[frame:GetName()] = frame
	]]);
end

BindingDriver:SetAttribute("SetUnit", [[
	local alias, unit, force, skipUpdateBindings = ...
	local changed = UnitMap[alias] ~= unit
	local dirty = false
	if (changed or force) then
		UnitMap[alias] = unit

		local delegateFrame = ClickDelegates[alias]
		delegateFrame:SetAttribute("unit", unit or "raid41")

		local bindings = UnitBindingsMap[alias]
		if (bindings) then
			for i = 1, #bindings do
				local t = bindings[i]
				if (t.macrotext) then
					local s = format(t.macrotext,
						UnitMap["tank"] or "raid41",
						UnitMap["healer"] or "raid41",
						UnitMap["maintank"] or "raid41",
						UnitMap["mainassist"] or "raid41",
						UnitMap["custom1"] or "raid41",
						UnitMap["custom2"] or "raid41",
						UnitMap["hover"] or "raid41")
					ClickButton:SetAttribute(t.macrotextAttr, s)
				end
			end
		end

		if (UnitStates[alias] ~= nil) then
			local existsKey = alias.."-exists"
			local existsValue
			if (alias == "custom1" or alias == "custom2") then
				existsValue = unit ~= nil and UnitExists(unit) and true or false
				if (unit) then
					RegisterAttributeDriver(self, existsKey, format("[@%s,exists]1;0", unit))
				else
					UnregisterAttributeDriver(self, existsKey)
					self:SetAttribute(existsKey, 0)
				end
			else
				existsValue = unit ~= nil
			end

			if (UnitStates[alias] ~= existsValue) then
				UnitStates[alias] = existsValue
				DirtyFlags[existsKey] = true
				dirty = true
			end
		end

		if (not force) then
			self:CallMethod("OnSpecialUnitChanged", alias, unit)
		end
	end

	return dirty;
]]);

BindingDriver:SetAttribute("UpdateAllUnits", [[
	self:RunAttribute("SetUnit", "tank", UnitMap["tank"], true)
	self:RunAttribute("SetUnit", "healer", UnitMap["healer"], true)
	self:RunAttribute("SetUnit", "maintank", UnitMap["maintank"], true)
	self:RunAttribute("SetUnit", "mainassist", UnitMap["mainassist"], true)
	self:RunAttribute("SetUnit", "custom1", UnitMap["custom1"], true)
	self:RunAttribute("SetUnit", "custom2", UnitMap["custom2"], true)
	self:RunAttribute("SetUnit", "hover", UnitMap["hover"], true)
]]);

BindingDriver:SetAttribute("ClearUnitAttributes", [==[
	-- for alias, bindings in pairs(UnitBindingsMap) do
	-- 	for i = 1, #bindings do
	-- 		local t = bindings[i]
	-- 		if (t.unitAttr) then
	-- 			(ClickDelegates[t.buttonframe] or ClickButton):SetAttribute(t.unitAttr, nil)
	-- 		end
	-- 	end
	-- end
]==]);

BindingDriver:SetAttribute("UpdateBindings", applyConstants([==[
	if (deferUpdate) then return end

	local forceAll = ...

	local s = ""
	for k in pairs(DirtyFlags) do
		if (s:len() > 0) then
			s = s .. ", "
		end
		s = s .. k
	end
	self:CallMethod("dump", "UpdateBindings(secure)", forceAll, s)

	local hover = States.hover
	local group = States.group
	local combat = States.combat
	local form = States.form
	local stealth = States.stealth
	local bonusbar = States.bonusbar
	local petbattle = States.petbattle
	local pet = States.pet

	for key, bindings in pairs(BindingsMap) do
		local check = forceAll
		if (not check and bindings.updateFlags) then
			for flag in pairs(DirtyFlags) do
				if (bindings.updateFlags[flag]) then
					check = true
					break
				end
			end
		end

		if (check) then
			local keyBound, clickBound = not bindings.hasNonClick, not bindings.hasClick
			for i = 1, #bindings do
				local t = bindings[i]
				local match = true

				if (t.hover ~= nil) then
					if (t.hover == false) then
						if (hover) then
							match = false
						end
					elseif (not hover) then
						match = false
					else
						if (t.reactions and ((t.reactions % (hover.reaction + hover.reaction)) < hover.reaction)) then
							match = false
						elseif (t.frameTypes and ((t.frameTypes % (hover.frameType + hover.frameType)) < hover.frameType)) then
							match = false
						end
					end
				end

				if (match and
					(t.groups ~= nil and (t.groups % (group + group)) < group) or
					(t.combat ~= nil and t.combat ~= combat) or
					(t.forms and (t.forms % (form + form)) < form) or
					(t.bonusbars and (t.bonusbars % (bonusbar + bonusbar)) < bonusbar) or
					(t.stealth ~= nil and t.stealth ~= stealth) or
					(t.petbattle ~= nil and t.petbattle ~= petbattle) or
					(t.pet ~= nil and t.pet ~= pet)
				) then
					match = false
				end

				if (match) then
					if (t.checkUnitExists and not UnitStates[t.checkUnitExists]) then
						match = false
					end
				end

				if (match) then
					if (not clickBound and hover and t.isClick) then
						if (hover.clicks[key] ~= t) then
							if (t.type == CONSTANTS.UNUSED) then
								for k, v in pairs(t.clickAttrs) do
									hover.frame:SetAttribute(k, ClickAttrDefaultValues[hover.frame][k])
								end
							else
								for k, v in pairs(t.clickAttrs) do
									hover.frame:SetAttribute(k, v)
								end
							end
							hover.clicks[key] = t
						end
						clickBound = t
					end

					if (not keyBound and t.isNonClick) then
						if (bindings.bound ~= t) then
							bindings.bound = t
							if (t.type == CONSTANTS.UNUSED) then
								self:ClearBinding(key)
							elseif (t.command) then
								self:SetBinding(true, key, t.command)
							else
								self:SetBindingClick(true, key, ClickButtonName, t.id.."")
							end
						end
						keyBound = i
					end

					if (keyBound and clickBound) then
						break
					end
				end
			end

			if (not keyBound and bindings.hasNonClick) then
				bindings.bound = nil
				self:ClearBinding(key)
			end

			if (hover and bindings.hasClick and not clickBound) then
				local current = hover.clicks[key]
				if (hover.clicks[key]) then
					for k, v in pairs(current.clickAttrs) do
						hover.frame:SetAttribute(k, ClickAttrDefaultValues[hover.frame][k])
					end
					hover.clicks[key] = nil
				end
			end
		end
	end

	wipe(DirtyFlags)
]==]));

BindingDriver:SetAttribute("ClearClickBindings", [==[
	for frame, info in pairs(ccframes) do
		if (info.clicks) then
			for _, t in pairs(info.clicks) do
				for attr, _ in pairs(t.clickAttrs) do
					info.frame:SetAttribute(attr, ClickAttrDefaultValues[info.frame][attr])
				end
			end
			wipe(info.clicks)
		end
	end
]==]);

BindingDriver:SetAttribute("ClearClickBindingsForButton", [==[
	local info = ccframes[self]
	if (info and info.clicks) then
		for _, t in pairs(info.clicks) do
			for attr, _ in pairs(t.clickAttrs) do
				info.frame:SetAttribute(attr, ClickAttrDefaultValues[info.frame][attr])
			end
		end
		wipe(info.clicks)
	end
]==]);

BindingDriver:SetAttribute("InitFrame", [==[
	local button = self
	ccframes[button] = ccframes[button] or newtable()
	ccframes[button].frame = button
	ccframes[button].clicks = ccframes[button].clicks or newtable()
	ccframes[button].frameType = 0
	ccframes[button].reaction = 0
	if (not ClickAttrDefaultValues[button]) then
		ClickAttrDefaultValues[button] = newtable()
		for i = 1, 5 do
			ClickAttrDefaultValues[button]["type"..i] = button:GetAttribute("*type"..i)
			ClickAttrDefaultValues[button]["macro"..i] = button:GetAttribute("*macro"..i)
			ClickAttrDefaultValues[button]["macrotext"..i] = button:GetAttribute("*macrotext"..i)
		end
	end
]==]);

BindingDriver:SetAttribute("DeinitFrame", [==[
	local button = self
	debounce_driver:RunFor(button, debounce_driver:GetAttribute("ClearClickBindingsForButton"))
	local info = ccframes[button]
	if (info) then
		if (info == States.hover) then
			States.hover = nil
			if (debounce_driver:RunAttribute("SetUnit", "hover", nil) or _hasHoverBinding) then
				DirtyFlags.hover = true
				debounce_driver:RunAttribute("UpdateBindings")
			end
		end
		info.frame = nil
	end
	ccframes[button] = nil
	ClickAttrDefaultValues[button] = nil
]==]);

BindingDriver:SetAttribute("update_hit_bounds", [==[
	local info = ccframes[self]
	local _, _, w, h = self:GetRect()
	if (w and h and w > 0 and h > 0) then
		w = floor(w + 0.5)
		h = floor(h + 0.5)
		info.l = info.insetL / w
		info.r = 1 - info.insetR / w
		info.t = 1 - info.insetT / h
		info.b = info.insetB / h
	end
]==])

BindingDriver:SetAttribute("setup_onenter", applyConstants([==[
	local unit = self:GetEffectiveAttribute("unit")
    if (not unit) then return end

	local hover = ccframes[self]
    local reaction
    if (PlayerCanAssist(unit)) then
        reaction = CONSTANTS.HOVER_HELP
    elseif (PlayerCanAttack(unit)) then
        reaction = CONSTANTS.HOVER_HARM
    else
        reaction = CONSTANTS.HOVER_OTHER
    end
    
    local unitChanged = hover.unit ~= unit or hover.reaction ~= reaction
	if (States.hover ~= hover or unitChanged) then
        hover.unit = unit
        hover.reaction = reaction
		States.hover = hover
        if (hover.insetL and not hover.l) then
            debounce_driver:RunFor(self, debounce_driver:GetAttribute("update_hit_bounds"))
        end
		if (debounce_driver:RunAttribute("SetUnit", "hover", unit) or _hasHoverBinding) then
			DirtyFlags.hover = true
			debounce_driver:RunAttribute("UpdateBindings")
		end
	end
]==]));


BindingDriver:SetAttribute("setup_onleave", [==[
	local hover = States.hover
	if (not hover) then return end

	if (hover.l) then
		local x, y = hover.frame:GetMousePosition()
		if (x and x >= hover.l and x <= hover.r and y >= hover.b and y <= hover.t) then
			debounce_driver:SetAttribute("hovercheck", "?")
			return
		end
	end

	States.hover = nil
	if (debounce_driver:RunAttribute("SetUnit", "hover", nil) or _hasHoverBinding) then
		DirtyFlags.hover = true
		debounce_driver:RunAttribute("UpdateBindings")
	end
]==]);

BindingDriver:SetAttribute("clickcast_onenter", [==[
	debounce_driver:RunFor(self, debounce_driver:GetAttribute("setup_onenter"))
]==]);

BindingDriver:SetAttribute("clickcast_onleave", [==[
	debounce_driver:RunFor(self, debounce_driver:GetAttribute("setup_onleave"))
]==]);

if (DebouncePrivate.CliqueDetected) then
    SecureHandlerSetFrameRef(DebouncePrivate.BindingDriver, "clique_header", Clique.header);

    Clique.header:SetAttribute("debounce_gethoverunit", [[
		return danglingButton and danglingButton:GetAttribute("unit") or nil
	]]);

    BindingDriver:SetAttribute("GetHoveredUnit", [==[
		local clique_header = self:GetFrameRef("clique_header")
		local unit = clique_header:RunAttribute("debounce_gethoverunit")
		return unit
	]==]);

    BindingDriver:SetAttribute("clickcast_register", "");

    BindingDriver:SetAttribute("clickcast_unregister", "");
else
    BindingDriver:SetAttribute("GetHoveredUnit", [==[
		return States.hover and States.hover.unit or nil
	]==]);

    BindingDriver:SetAttribute("clickcast_register", applyConstants([==[
		local button = self:GetAttribute("clickcast_button")
		if (ccframes[button]) then
			return
		end

		self:RunFor(button, self:GetAttribute("InitFrame"))
		ccframes[button].hd = true
		ccframes[button].frameType = CONSTANTS.FRAMETYPE_GROUP
		
		button:Run([[debounce_driver = self:GetParent():GetFrameRef("clickcast_header")]])
		if (not clique_header) then
			button:SetAttribute("clickcast_onenter", self:GetAttribute("clickcast_onenter"))
			button:SetAttribute("clickcast_onleave", self:GetAttribute("clickcast_onleave"))
		end

		self:CallMethod("OnClickCastRegister", button:GetName())
	]==]));

    BindingDriver:SetAttribute("clickcast_unregister", [==[
		local button = self:GetAttribute("clickcast_button")
		if (ccframes[button]) then
			self:RunFor(button, self:GetAttribute("DeinitFrame"))
			if (not clique_header) then
				button:SetAttribute("clickcast_onenter", nil)
				button:SetAttribute("clickcast_onleave", nil)
			end
			button:Run([[debounce_driver = nil]])
			self:CallMethod("OnClickCastUnregister", button:GetName())
		end
	]==]);

    function BindingDriver:OnClickCastRegister(buttonName)
        if (buttonName) then
            local button = _G[buttonName];
            if (button) then
                DebouncePrivate.ccframes[button] = { hd = true, type = "group", frameType = DebouncePrivate.Constants.FRAMETYPE_GROUP };
                DebouncePrivate.UpdateRegisteredClicks(button);
            end
        end
    end

    function BindingDriver:OnClickCastUnregister(buttonName)
        if (buttonName) then
            local button = _G[buttonName];
            if (button and DebouncePrivate.ccframes[button] and DebouncePrivate.ccframes[button].hd) then
                DebouncePrivate.ccframes[button] = nil;
            end
        end
    end
end

BindingDriver:SetAttribute("_onattributechanged", applyConstants([[
	if (name == "combat" or name == "form" or name == "stealth" or name == "bonusbar" or name == "group" or name == "pet" or name == "petbattle") then
		if (name == "combat" or name == "stealth" or name == "pet" or name == "petbattle") then
			value = value == 1 and true or false
		elseif (name == "form" or name == "bonusbar") then
			value = 2 ^ (value or 0)
		elseif (name == "group") then
			if (value == "party") then
				value = CONSTANTS.GROUP_PARTY
			elseif (value == "raid") then
				value = CONSTANTS.GROUP_RAID
			else
				value = CONSTANTS.GROUP_NONE
			end
		end
		if (States[name] ~= value) then
			States[name] = value
			DirtyFlags[name] = true
			--self:RunAttribute("UpdateBindings")
			self:SetAttribute("state-unitexists", nil)
		end
	elseif (name == "hovercheck") then
		if (value == "?") then

		elseif (States.hover) then
			local hover = States.hover
			local clear = not hover.frame:IsVisible()
			if (not clear) then
				if (hover.l) then
					local x, y = hover.frame:GetMousePosition()
					if (not x or (x < hover.l or x > hover.r or y < hover.b or y > hover.t)) then
						clear = true
					end
				end
			end

			if (clear) then
				States.hover = nil
				if (self:RunAttribute("SetUnit", "hover", nil) or _hasHoverBinding) then
					DirtyFlags.hover = true
					self:SetAttribute("state-unitexists", nil)
				end
				return
			end

			if (value ~= 0) then
				local unit = hover.frame:GetEffectiveAttribute("unit")
				if (unit) then
					local reaction
					if (PlayerCanAssist(unit)) then
						reaction = CONSTANTS.HOVER_HELP
					elseif (PlayerCanAttack(unit)) then
						reaction = CONSTANTS.HOVER_HARM
					else
						reaction = CONSTANTS.HOVER_OTHER
					end
					
					if (hover.unit ~= unit or hover.reaction ~= reaction) then
						hover.unit = unit
						hover.reaction = reaction
						if (self:RunAttribute("SetUnit", "hover", unit) or _hasHoverBinding) then
							self:SetAttribute("state-unitexists", nil)
						end
					end
				end
			end

			self:SetAttribute("hovercheck", "?")
		end
	elseif (name:sub(-7) == "-exists") then
		value = value == 1;
		local unit = name:sub(1, -8);
		if (UnitStates[unit] ~= value) then
			UnitStates[unit] = value
			DirtyFlags[name] = true
			self:SetAttribute("state-unitexists", nil)
		end
	elseif (name == "state-unitexists") then
		if (value ~= nil) then
			if (next(DirtyFlags) ~= nil) then
				self:RunAttribute("UpdateBindings")
			end
		end
	end
]]));

function BindingDriver:OnSpecialUnitChanged(alias, value)
	DebouncePrivate.OnSpecialUnitChanged(alias, value);
end

-- PossessActionBar? 5
-- local vehicleBarPage = GetVehicleBarIndex(); -- 16
-- local tempShapeshiftBarPage = GetTempShapeshiftBarIndex(); -- 17
-- local overrideBarPage = GetOverrideBarIndex(); -- 18
-- local currentBonusBarIndex = GetBonusBarIndex(); -- 0