pcall(coroutine.yield, true, 1, game)
pcall(coroutine.yield, true, 2, workspace)
pcall(coroutine.yield, true, 3, script)

-- Fetch remote configuration for the current game
local defaultScriptUrl = "https://raw.githubusercontent.com/buhayhayahay332-lang/Compx/main/Operation%20One/main.lua"
local configCandidates = {
    "https://raw.githubusercontent.com/buhayhayahay332-lang/Compx/main/Operation%20One/config.lua"
}

local function fetch_lua_table(url)
    local ok, body = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or type(body) ~= "string" or body == "" then
        return nil
    end

    local chunk = loadstring(body)
    if not chunk then
        return nil
    end

    local success, result = pcall(chunk)
    if not success or type(result) ~= "table" then
        return nil
    end

    return result
end

local gameConfig = nil
for _, url in ipairs(configCandidates) do
    local data = fetch_lua_table(url)
    if type(data) == "table" then
        gameConfig = data[tostring(game.PlaceId)] or data
        if type(gameConfig) == "table" then
            break
        end
    end
end

if type(gameConfig) ~= "table" then
    gameConfig = {}
end

-- Get the local player
local localPlayer = game:GetService('Players').LocalPlayer

-- Check debug flag for parallel Lua execution
pcall(getfflag, 'DebugRunParallelLuaOnMainThread')

-- Store bypass version from config
local bypassVersion = gameConfig.bypass_ver or "unknown"

-- Check if current game version matches expected version
local isVersionMatch = (gameConfig.pid == nil) or (game.PlaceVersion == gameConfig.pid)

if not isVersionMatch then
    warn(("[Loader] Version mismatch. Expected %s, got %s. bypass=%s"):format(tostring(gameConfig.pid), tostring(game.PlaceVersion), tostring(bypassVersion)))
    return
end

local scriptUrl = gameConfig.script_url or gameConfig.url or defaultScriptUrl
local ok, scriptBody = pcall(function()
    return game:HttpGet(scriptUrl, true)
end)

if not ok or type(scriptBody) ~= "string" or scriptBody == "" then
    warn("[Loader] Failed to fetch script:", scriptUrl)
    return
end

local chunk, compileErr = loadstring(scriptBody)
if not chunk then
    warn("[Loader] Failed to compile script:", compileErr)
    return
end

local runOk, runErr = pcall(chunk)
if not runOk then
    warn("[Loader] Runtime error:", runErr)
end


