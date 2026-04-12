local TableDumper = {};

local function escapeString(value)
    return "\"" .. tostring(value)
        :gsub("\\", "\\\\")
        :gsub("\n", "\\n")
        :gsub("\r", "\\r")
        :gsub("\t", "\\t")
        :gsub("\"", "\\\"") .. "\"";
end

local function isIdentifier(value)
    return type(value) == "string" and value:match("^[%a_][%w_]*$") ~= nil;
end

local function formatInstance(instance)
    local ok, fullName = pcall(function()
        return instance:GetFullName();
    end);

    if ok and fullName then
        return "game." .. fullName;
    end;

    return "Instance";
end

local function robloxSolve(value)
    if not typeof then
        return nil;
    end;

    local ok, valueType = pcall(typeof, value);
    if not ok then
        return nil;
    end;

    if valueType == "Instance" then
        return formatInstance(value);
    elseif valueType == "Vector3" then
        return string.format("Vector3.new(%g, %g, %g)", value.X, value.Y, value.Z);
    elseif valueType == "Vector2" then
        return string.format("Vector2.new(%g, %g)", value.X, value.Y);
    elseif valueType == "CFrame" then
        local components = table.pack(value:GetComponents());
        return ("CFrame.new(%s)"):format(table.concat((function()
            local out = table.create(components.n);
            for i = 1, components.n do
                out[i] = string.format("%g", components[i]);
            end;
            return out;
        end)(), ", "));
    elseif valueType == "Color3" then
        return string.format("Color3.new(%g, %g, %g)", value.R, value.G, value.B);
    elseif valueType == "BrickColor" then
        return string.format("BrickColor.new(%q)", tostring(value));
    elseif valueType == "UDim2" then
        return string.format(
            "UDim2.new(%g, %g, %g, %g)",
            value.X.Scale,
            value.X.Offset,
            value.Y.Scale,
            value.Y.Offset
        );
    elseif valueType == "UDim" then
        return string.format("UDim.new(%g, %g)", value.Scale, value.Offset);
    elseif valueType == "Rect" then
        return string.format(
            "Rect.new(%g, %g, %g, %g)",
            value.Min.X,
            value.Min.Y,
            value.Max.X,
            value.Max.Y
        );
    elseif valueType == "NumberRange" then
        return string.format("NumberRange.new(%g, %g)", value.Min, value.Max);
    elseif valueType == "NumberSequenceKeypoint" then
        return string.format(
            "NumberSequenceKeypoint.new(%g, %g, %g)",
            value.Time,
            value.Value,
            value.Envelope
        );
    elseif valueType == "ColorSequenceKeypoint" then
        return string.format(
            "ColorSequenceKeypoint.new(%g, Color3.new(%g, %g, %g))",
            value.Time,
            value.Value.R,
            value.Value.G,
            value.Value.B
        );
    elseif valueType == "NumberSequence" then
        local parts = {};
        for i, kp in ipairs(value.Keypoints) do
            parts[i] = string.format(
                "NumberSequenceKeypoint.new(%g, %g, %g)",
                kp.Time,
                kp.Value,
                kp.Envelope
            );
        end;
        return "NumberSequence.new({" .. table.concat(parts, ", ") .. "})";
    elseif valueType == "ColorSequence" then
        local parts = {};
        for i, kp in ipairs(value.Keypoints) do
            parts[i] = string.format(
                "ColorSequenceKeypoint.new(%g, Color3.new(%g, %g, %g))",
                kp.Time,
                kp.Value.R,
                kp.Value.G,
                kp.Value.B
            );
        end;
        return "ColorSequence.new({" .. table.concat(parts, ", ") .. "})";
    elseif valueType == "EnumItem" then
        return tostring(value);
    end;

    return nil;
end

function TableDumper.solve(value)
    local luaType = type(value);

    if luaType == "string" then
        return escapeString(value);
    elseif luaType == "number" or luaType == "boolean" or luaType == "nil" then
        return tostring(value);
    elseif luaType == "function" then
        return "function() end";
    elseif luaType == "thread" then
        return "thread";
    elseif luaType == "table" then
        return "table";
    elseif luaType == "userdata" or luaType == "vector" then
        local robloxValue = robloxSolve(value);
        return robloxValue or tostring(value);
    end;

    local robloxValue = robloxSolve(value);
    return robloxValue or tostring(value);
end

local function getSortedKeys(tbl)
    local keys = {};

    for key in pairs(tbl) do
        keys[#keys + 1] = key;
    end;

    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b);

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

local function isArray(tbl)
    local maxIndex = 0;
    local count = 0;

    for key in pairs(tbl) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false, 0;
        end;

        if key > maxIndex then
            maxIndex = key;
        end;

        count += 1;
    end;

    if maxIndex ~= count then
        return false, 0;
    end;

    return true, maxIndex;
end

function TableDumper.dump(tbl, depth)
    depth = depth or 3;

    local function dumpInternal(value, currentDepth, visited)
        if currentDepth > depth then
            return "...";
        end;

        if type(value) ~= "table" then
            return TableDumper.solve(value);
        end;

        if visited[value] then
            return "\"<circular>\"";
        end;

        visited[value] = true;

        local indent = string.rep("    ", currentDepth);
        local nextIndent = string.rep("    ", currentDepth + 1);

        local parts = { "{" };
        local arrayMode, arrayLength = isArray(value);

        if arrayMode then
            for i = 1, arrayLength do
                local item = value[i];
                local itemStr = type(item) == "table"
                    and dumpInternal(item, currentDepth + 1, visited)
                    or TableDumper.solve(item);

                parts[#parts + 1] = nextIndent .. itemStr .. ",";
            end;
        else
            local keys = getSortedKeys(value);

            for _, key in ipairs(keys) do
                local item = value[key];
                local keyStr;

                if isIdentifier(key) then
                    keyStr = key;
                else
                    keyStr = "[" .. TableDumper.solve(key) .. "]";
                end;

                local itemStr = type(item) == "table"
                    and dumpInternal(item, currentDepth + 1, visited)
                    or TableDumper.solve(item);

                parts[#parts + 1] = nextIndent .. keyStr .. " = " .. itemStr .. ",";
            end;
        end;

        parts[#parts + 1] = indent .. "}";
        visited[value] = nil;

        return table.concat(parts, "\n");
    end

    return dumpInternal(tbl, 0, {});
end

return TableDumper;
