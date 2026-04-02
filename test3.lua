local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if not Drawing then
    warn("Drawing API not available in this executor.")
    return
end

local Config = {
    espEnabled = true,
    gadgetEspEnabled = true,
    teamCheck = true,
    excludeLocalPlayer = true,
    playerBoxEnabled = true,
    playerNameEnabled = true,
}

local GADGETS = {
    drone = true,
    claymore = true,
    proximityalarm = true,
    stickycamera = true,
    signaldisruptor = true,
}

if _G.MatchedNameDrawingEspCleanup then
    _G.MatchedNameDrawingEspCleanup()
end

_G.MatchedNameDrawingEspConfig = Config

local playerDrawingsByObject = {}
local gadgetDrawingsByObject = {}
local connections = {}
local dirty = true

local lastTeamCheck = Config.teamCheck
local lastExcludeLocalPlayer = Config.excludeLocalPlayer
local lastGadgetEspEnabled = Config.gadgetEspEnabled
local lastPlayerBoxEnabled = Config.playerBoxEnabled
local lastPlayerNameEnabled = Config.playerNameEnabled

local function normalizeName(value)
    return string.lower(tostring(value or ""))
end

local function hide(entry)
    if entry.box then
        entry.box.Visible = false
    end
    if entry.name then
        entry.name.Visible = false
    end
end

local function destroyEntry(entry)
    if entry.box then
        entry.box:Remove()
    end
    if entry.name then
        entry.name:Remove()
    end
end

local function createBox(color)
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = color
    box.Visible = false
    return box
end

local function createPlayerEntry(playerName)
    local name = Drawing.new("Text")
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Text = playerName
    name.Visible = false

    return {
        playerName = playerName,
        box = createBox(Color3.fromRGB(255, 70, 70)),
        name = name,
    }
end

local function createGadgetEntry()
    return {
        box = createBox(Color3.fromRGB(255, 210, 70)),
    }
end

local function getBoundingBoxData(object)
    if object:IsA("BasePart") then
        return object.CFrame, object.Size
    end

    if object:IsA("Model") then
        return object:GetBoundingBox()
    end

    local model = object:FindFirstChildWhichIsA("Model", true)
    if model then
        return model:GetBoundingBox()
    end

    local part = object:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame, part.Size
    end

    return nil, nil
end

local function projectBox(cf, size)
    local sx, sy, sz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
    local corners = {
        Vector3.new(-sx, -sy, -sz),
        Vector3.new(-sx, -sy, sz),
        Vector3.new(-sx, sy, -sz),
        Vector3.new(-sx, sy, sz),
        Vector3.new(sx, -sy, -sz),
        Vector3.new(sx, -sy, sz),
        Vector3.new(sx, sy, -sz),
        Vector3.new(sx, sy, sz),
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyInFront = false

    for _, offset in ipairs(corners) do
        local worldPoint = cf:PointToWorldSpace(offset)
        local screenPoint, onScreen = Camera:WorldToViewportPoint(worldPoint)

        if screenPoint.Z > 0 then
            anyInFront = true
            minX = math.min(minX, screenPoint.X)
            minY = math.min(minY, screenPoint.Y)
            maxX = math.max(maxX, screenPoint.X)
            maxY = math.max(maxY, screenPoint.Y)
        end

        if onScreen then
            anyInFront = true
        end
    end

    if not anyInFront then
        return nil
    end

    local width, height = maxX - minX, maxY - minY
    if width <= 1 or height <= 1 then
        return nil
    end

    return minX, minY, width, height
end

local function sameTeam(a, b)
    if not a or not b then
        return false
    end

    if a.Team ~= nil and b.Team ~= nil then
        return a.Team == b.Team
    end

    return a.TeamColor == b.TeamColor
end

local function isPlayerAlive(player)
    if not player then
        return false
    end

    local character = player.Character
    if not character or not character.Parent then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.Health > 0
    end

    return false
end

local function isCharacterVisible(character)
    if not character then
        return false
    end

    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local name = descendant.Name
            local isCorePart = name == "HumanoidRootPart"

            if isCorePart then
                local effectiveTransparency = math.max(descendant.Transparency, descendant.LocalTransparencyModifier)
                if effectiveTransparency < 0.98 then
                    return true
                end
            end
        end
    end

    return false
end

local function shouldIncludePlayer(player)
    if not isPlayerAlive(player) then
        return false
    end

    if not isCharacterVisible(player.Character) then
        return false
    end

    if Config.excludeLocalPlayer and player == LocalPlayer then
        return false
    end

    if Config.teamCheck and sameTeam(player, LocalPlayer) then
        return false
    end

    return true
end

local function syncPlayerEntries(wantedPlayers)
    for object, entry in pairs(playerDrawingsByObject) do
        if not wantedPlayers[object] or not object.Parent then
            destroyEntry(entry)
            playerDrawingsByObject[object] = nil
        end
    end

    for object, player in pairs(wantedPlayers) do
        local entry = playerDrawingsByObject[object]
        if not entry then
            local newEntry = createPlayerEntry(player.Name)
            newEntry.player = player
            playerDrawingsByObject[object] = newEntry
        else
            entry.player = player
            entry.playerName = player.Name
            if entry.name then
                entry.name.Text = player.Name
            end
        end
    end
end

local function syncGadgetEntries(wantedGadgets)
    for object, entry in pairs(gadgetDrawingsByObject) do
        if not wantedGadgets[object] or not object.Parent then
            destroyEntry(entry)
            gadgetDrawingsByObject[object] = nil
        end
    end

    for object in pairs(wantedGadgets) do
        if not gadgetDrawingsByObject[object] then
            gadgetDrawingsByObject[object] = createGadgetEntry()
        end
    end
end

local function rebuildMatches()
    local childrenByName = {}
    local wantedGadgets = {}

    for _, child in ipairs(Workspace:GetChildren()) do
        local childLowerName = normalizeName(child.Name)

        local bucket = childrenByName[childLowerName]
        if not bucket then
            bucket = {}
            childrenByName[childLowerName] = bucket
        end
        table.insert(bucket, child)

        if GADGETS[childLowerName] then
            wantedGadgets[child] = true
        end
    end

    local wantedPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if not shouldIncludePlayer(player) then
            continue
        end

        local namedChildren = childrenByName[normalizeName(player.Name)]
        if namedChildren then
            for _, object in ipairs(namedChildren) do
                wantedPlayers[object] = player
            end
        end
    end

    syncPlayerEntries(wantedPlayers)
    syncGadgetEntries(wantedGadgets)
end

local function renderEntries(entries, withName, showBox, showName)
    for object, entry in pairs(entries) do
        if withName and not shouldIncludePlayer(entry.player) then
            hide(entry)
            continue
        end

        if not object.Parent then
            hide(entry)
            continue
        end

        local cf, size = getBoundingBoxData(object)
        if not cf then
            hide(entry)
            continue
        end

        local x, y, w, h = projectBox(cf, size)
        if not x then
            hide(entry)
            continue
        end

        if entry.box then
            entry.box.Position = Vector2.new(x, y)
            entry.box.Size = Vector2.new(w, h)
            entry.box.Visible = showBox == true
        end

        if withName and entry.name then
            entry.name.Text = entry.playerName or ""
            entry.name.Position = Vector2.new(x + (w * 0.5), y - 14)
            entry.name.Visible = showName == true
        elseif entry.name then
            entry.name.Visible = false
        end
    end
end

local function markDirty()
    dirty = true
end

table.insert(connections, Players.PlayerAdded:Connect(markDirty))
table.insert(connections, Players.PlayerRemoving:Connect(markDirty))
table.insert(connections, Workspace.ChildAdded:Connect(markDirty))
table.insert(connections, Workspace.ChildRemoved:Connect(markDirty))

if LocalPlayer then
    table.insert(connections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(markDirty))
    table.insert(connections, LocalPlayer:GetPropertyChangedSignal("TeamColor"):Connect(markDirty))
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Camera

    if Config.teamCheck ~= lastTeamCheck
        or Config.excludeLocalPlayer ~= lastExcludeLocalPlayer
        or Config.gadgetEspEnabled ~= lastGadgetEspEnabled
        or Config.playerBoxEnabled ~= lastPlayerBoxEnabled
        or Config.playerNameEnabled ~= lastPlayerNameEnabled
    then
        lastTeamCheck = Config.teamCheck
        lastExcludeLocalPlayer = Config.excludeLocalPlayer
        lastGadgetEspEnabled = Config.gadgetEspEnabled
        lastPlayerBoxEnabled = Config.playerBoxEnabled
        lastPlayerNameEnabled = Config.playerNameEnabled
        dirty = true
    end

    if not Config.espEnabled then
        for _, entry in pairs(playerDrawingsByObject) do
            hide(entry)
        end
        for _, entry in pairs(gadgetDrawingsByObject) do
            hide(entry)
        end
        return
    end

    if dirty then
        dirty = false
        rebuildMatches()
    end

    renderEntries(
        playerDrawingsByObject,
        true,
        Config.playerBoxEnabled,
        Config.playerNameEnabled
    )

    if Config.gadgetEspEnabled then
        renderEntries(gadgetDrawingsByObject, false, true, false)
    else
        for _, entry in pairs(gadgetDrawingsByObject) do
            hide(entry)
        end
    end
end))

_G.MatchedNameDrawingEspCleanup = function()
    for _, connection in ipairs(connections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end

    for _, entry in pairs(playerDrawingsByObject) do
        destroyEntry(entry)
    end
    for _, entry in pairs(gadgetDrawingsByObject) do
        destroyEntry(entry)
    end

    table.clear(playerDrawingsByObject)
    table.clear(gadgetDrawingsByObject)
    table.clear(connections)
end
