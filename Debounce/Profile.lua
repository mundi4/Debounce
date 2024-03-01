local _, DebouncePrivate = ...;
local NUM_SPECS          = GetNumSpecializationsForClassID(select(3, UnitClass("player")));

local Constants          = DebouncePrivate.Constants;
local luatype            = type;
local dump               = DebouncePrivate.dump;
local LayerArray         = {};

local KEYS_TO_SAVE       = {
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
    specialbar = true,
    extrabar = true,
    pet = true,
    petbattle = true,
    priority = true,
    checkUnitExists = true,
    ignoreHoverUnit = true,
    checkedUnit = true,
    checkedUnitValue = true, -- true, false, help, harm
};


local LAYER_INFOS = {
    [1] = { key = "GENERAL" },
    [2] = { key = Constants.PLAYER_CLASS, spec = 0 },
    [3] = { key = Constants.PLAYER_CLASS, spec = 1 },
    [4] = { key = Constants.PLAYER_CLASS, spec = 2 },
    [5] = { key = Constants.PLAYER_CLASS, spec = 3 },
    [6] = { key = Constants.PLAYER_CLASS, spec = 4 },
    [7] = { isCharacterSpecific = true, spec = 0 },
    [8] = { isCharacterSpecific = true, spec = 1 },
    [9] = { isCharacterSpecific = true, spec = 2 },
    [10] = { isCharacterSpecific = true, spec = 3 },
    [11] = { isCharacterSpecific = true, spec = 4 },
};


local NextId;
do
    local _nextId = 100;
    function NextId()
        _nextId = _nextId + 1;
        return _nextId;
    end
end

local ProfileLayerProto = {};

function ProfileLayerProto:Insert(action, insertIndex, keepId)
    if (insertIndex == nil) then
        insertIndex = #self.actions + 1;
    else
        if (luatype(insertIndex) == "table") then
            local before = insertIndex;
            insertIndex = nil;
            for i = 1, #self.actions do
                if (self.actions[i] == before) then
                    insertIndex = i;
                    break;
                end
            end
        elseif (insertIndex < 1) then
            insertIndex = 1;
        elseif (insertIndex > #self.actions + 1) then
            insertIndex = #self.actions + 1;
        end
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
    local dbver;
    if (layerInfo.isCharacterSpecific) then
        dbver = DebouncePrivate.db.char.dbver;
        tbl = DebouncePrivate.db.char
    else
        assert(layerInfo.key);
        dbver = DebouncePrivate.db.global.dbver;
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

    for _, action in ipairs(tbl) do
        if (action.checkUnitExists and (Constants.BASIC_UNITS[action.unit] or Constants.SPECIAL_UNITS[action.unit])) then
            action.checkedUnit = true;
            action.checkedUnitValue = true;
            action.checkUnitExists = nil;
        end
    end

    local layer = setmetatable({ layerID = layerID, actions = tbl, }, { __index = ProfileLayerProto });
    return layer;
end


function DebouncePrivate.LoadProfile()
    wipe(LayerArray);
    for layerID = 1, #LAYER_INFOS do
        LayerArray[layerID] = LoadLayer(layerID);
    end

    dump("LayerArray", LayerArray);
    DebouncePrivate.callbacks:Fire("OnProfileLoaded");
end

function DebouncePrivate.GetProfileLayer(layerID)
    return LayerArray[layerID];
end

function DebouncePrivate.CleanUpDB()
    for _, layer in pairs(LayerArray) do
        for _, action in layer:Enumerate() do
            for k in pairs(action) do
                if (not KEYS_TO_SAVE[k]) then
                    if (not strsub(k, 1, 1) == "$") then
                        action[k] = nil;
                    end
                end
            end
            if (action.priority == Constants.DEFAULT_PRIORITY) then
                action.priority = nil;
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

function DebouncePrivate.EnumerateProfileLayers()
    local spec = GetSpecialization();
    local indexArray = {};

    if (spec > 0 and spec <= NUM_SPECS) then
        tinsert(indexArray, DebouncePrivate.GetLayerID(spec, true));
    end

    tinsert(indexArray, DebouncePrivate.GetLayerID(0, true));

    if (spec > 0 and spec <= NUM_SPECS) then
        tinsert(indexArray, DebouncePrivate.GetLayerID(spec, false));
    end

    tinsert(indexArray, DebouncePrivate.GetLayerID(0, false));
    tinsert(indexArray, DebouncePrivate.GetLayerID(nil, false));

    local function Enumerator(tbl, index)
        index = index + 1;
        if (index <= #tbl) then
            local layerIndex = tbl[index];
            local layer = DebouncePrivate.GetProfileLayer(layerIndex);
            return index, layer;
        end
    end

    return Enumerator, indexArray, 0;
end

function DebouncePrivate.EnumerateActionsInActiveLayers()
    local spec = GetSpecialization();
    local layerIdArray = {};

    if (spec > 0 and spec <= NUM_SPECS) then
        tinsert(layerIdArray, DebouncePrivate.GetLayerID(spec, true));
    end

    tinsert(layerIdArray, DebouncePrivate.GetLayerID(0, true));

    if (spec > 0 and spec <= NUM_SPECS) then
        tinsert(layerIdArray, DebouncePrivate.GetLayerID(spec, false));
    end

    tinsert(layerIdArray, DebouncePrivate.GetLayerID(0, false));
    tinsert(layerIdArray, DebouncePrivate.GetLayerID(nil, false));

    local layerIndex = 1;
    local actionIndex = 0;
    local layer = DebouncePrivate.GetProfileLayer(layerIdArray[layerIndex]);
    local numActions = layer:GetNumActions();

    local function Enumerator(tbl, index)
        index = index + 1;
        while (actionIndex >= numActions) do
            layerIndex = layerIndex + 1;
            layer = DebouncePrivate.GetProfileLayer(tbl[layerIndex]);
            if (not layer) then
                return nil, nil;
            end
            numActions = layer:GetNumActions();
            actionIndex = 0;
        end
        actionIndex = actionIndex + 1;
        return index, layer:GetAction(actionIndex);
    end

    return Enumerator, layerIdArray, 0;
end
