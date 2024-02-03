local DebouncePublic = DebouncePublic;

_G.Clique = DebouncePublic;

_G.ClickCastHeader = DebouncePublic.header;

_G.ClickCastFrames = setmetatable({}, {
    __newindex = function(t, k, v)
        if v == nil or v == false then
            DebouncePublic:UnregisterFrame(k);
        else
            DebouncePublic:RegisterFrame(k);
        end
    end
});
