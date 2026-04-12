local Serializer = {};

local METAMETHOD_NAMES = {
    "__index", "__newindex", "__call", "__concat", "__unm", "__add", "__sub",
    "__mul", "__div", "__mod", "__pow", "__tostring", "__eq", "__lt", "__le",
    "__metatable", "__mode", "__len", "__pairs", "__ipairs", "__gc",
};

local METAMETHOD_LOOKUP = {};
for _, name in ipairs(METAMETHOD_NAMES) do
    METAMETHOD_LOOKUP[name] = true;
end;

local function indent(level)
    return string.rep("  ", tonumber(level) or 0);
end

local function escapeString(value)
    return "\"" .. tostring(value)
        :gsub("\\", "\\\\")
        :gsub("\"", "\\\"")
        :gsub("\n", "\\n")
        :gsub("\r", "\\r")
        :gsub("\t", "\\t") .. "\"";
end

local function sortedKeys(tbl)
    local keys = {};
    for key in pairs(tbl) do
        keys[#keys + 1] = key;
    end;

    table.sort(keys, function(a, b)
        local ta, tb = typeof(a), typeof(b);
        if ta == tb then
            if ta == "number" then
                return a < b;
            end;
            return tostring(a) < tostring(b);
        end;
        return ta < tb;
    end);

    return keys;
end

local function recreateFunction(func)
    local ok, info = pcall(debug.getinfo, func, "un");
    if not ok or not info then
        return "function(...) end";
    end;

    local params = {};
    for i = 1, info.numparams or 0 do
        params[#params + 1] = "_" .. i;
    end;

    if info.is_vararg then
        params[#params + 1] = "...";
    end;

    local name = info.name or "function";
    return name .. "(" .. table.concat(params, ", ") .. ")";
end

local function isService(instance)
    if typeof(instance) ~= "Instance" then
        return false;
    end;

    local ok, service = pcall(function()
        return game:GetService(instance.ClassName);
    end);

    return ok and service == instance;
end

local function formatInstance(instance)
    if isService(instance) then
        return ("game:GetService(%q)"):format(instance.ClassName);
    end;

    local ok, fullName = pcall(function()
        return instance:GetFullName();
    end);

    if ok and fullName then
        return "game." .. fullName;
    end;

    return "nil";
end

local function formatCFrame(cf)
    local components = table.pack(cf:GetComponents());
    local out = table.create(components.n);

    for i = 1, components.n do
        out[i] = string.format("%g", components[i]);
    end;

    return "CFrame.new(" .. table.concat(out, ", ") .. ")";
end

local function formatRobloxValue(value)
    local t = typeof(value);

    if t == "Vector3" then
        return string.format("Vector3.new(%g, %g, %g)", value.X, value.Y, value.Z);
    elseif t == "Vector2" then
        return string.format("Vector2.new(%g, %g)", value.X, value.Y);
    elseif t == "CFrame" then
        return formatCFrame(value);
    elseif t == "Color3" then
        return string.format("Color3.new(%g, %g, %g)", value.R, value.G, value.B);
    elseif t == "UDim" then
        return string.format("UDim.new(%g, %g)", value.Scale, value.Offset);
    elseif t == "UDim2" then
        return string.format(
            "UDim2.new(%g, %g, %g, %g)",
            value.X.Scale,
            value.X.Offset,
            value.Y.Scale,
            value.Y.Offset
        );
    elseif t == "BrickColor" then
        return ("BrickColor.new(%q)"):format(tostring(value));
    elseif t == "EnumItem" or t == "Enum" then
        return tostring(value);
    elseif t == "Instance" then
        return formatInstance(value);
    end;

    return nil;
end

local function formatMetamethod(value, level, visited)
    local t = typeof(value);

    if t == "function" then
        return recreateFunction(value);
    elseif t == "table" then
        return Serializer._formatValue(value, level, visited);
    else
        local robloxFormatted = formatRobloxValue(value);
        return robloxFormatted or tostring(value);
    end;
end

function Serializer._formatValue(value, level, visited)
    level = tonumber(level) or 0;
    visited = visited or {};

    local t = typeof(value);

    if t == "string" then
        return escapeString(value);
    elseif t == "number" then
        return string.format("%g", value);
    elseif t == "boolean" then
        return tostring(value);
    elseif t == "nil" then
        return "nil";
    elseif t == "function" then
        return recreateFunction(value);
    elseif t == "thread" then
        return "<thread>";
    end;

    local robloxFormatted = formatRobloxValue(value);
    if robloxFormatted then
        return robloxFormatted;
    end;

    if t ~= "table" then
        return tostring(value);
    end;

    if visited[value] then
        return "\"<Circular Reference>\"";
    end;

    visited[value] = true;

    local currentIndent = indent(level);
    local nextIndent = indent(level + 1);
    local parts = { "{\n" };

    for _, key in ipairs(sortedKeys(value)) do
        local item = value[key];
        local keyStr = "[" .. Serializer._formatValue(key, level + 1, visited) .. "]";
        local valueStr = Serializer._formatValue(item, level + 1, visited);
        parts[#parts + 1] = nextIndent .. keyStr .. " = " .. valueStr .. ",\n";
    end;

    local mt = getmetatable(value);
    if mt then
        parts[#parts + 1] = nextIndent .. "[\"__metatable\"] = {\n";

        for _, metamethodName in ipairs(METAMETHOD_NAMES) do
            local metamethod = mt[metamethodName];
            if metamethod ~= nil then
                parts[#parts + 1] =
                    indent(level + 2)
                    .. "[" .. escapeString(metamethodName) .. "] = "
                    .. formatMetamethod(metamethod, level + 2, visited)
                    .. ",\n";
            end;
        end;

        for key, item in pairs(mt) do
            if type(key) == "string" and key:match("^__") and not METAMETHOD_LOOKUP[key] then
                parts[#parts + 1] =
                    indent(level + 2)
                    .. "[" .. escapeString(key) .. "] = "
                    .. formatMetamethod(item, level + 2, visited)
                    .. ",\n";
            end;
        end;

        parts[#parts + 1] = nextIndent .. "},\n";
    end;

    parts[#parts + 1] = currentIndent .. "}";
    visited[value] = nil;

    return table.concat(parts);
end

function Serializer:Serialize(tbl, level)
    assert(typeof(tbl) == "table", "Serialize expects a table");
    return self._formatValue(tbl, level or 0, {});
end

getgenv().serializer = Serializer;
return Serializer;
