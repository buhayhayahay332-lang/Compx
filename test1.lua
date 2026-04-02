-- Object ESP (Drone / Claymore) - standalone, box only
-- Optimized for low overhead: event-driven tracking + lightweight periodic reconcile

local STATE_KEY = "__OP1_OBJECT_BOX_STATE"

local DEFAULT_OBJECTS = {
    drone = { Enabled = true, Color = Color3.fromRGB(80, 220, 255) },
    claymore = { Enabled = true, Color = Color3.fromRGB(255, 160, 80) },
    proximityalarm = { Enabled = true, Color = Color3.fromRGB(255, 230, 90) },
    stickycamera = { Enabled = true, Color = Color3.fromRGB(120, 255, 150) },
    signaldisruptor = { Enabled = true, Color = Color3.fromRGB(255, 110, 200) },
}
local DEFAULT_PLAYERS = {
    Enabled = true,
    Color = Color3.fromRGB(255, 255, 255),
    TeamCheck = false,
    FolderName = "Viewmodels",
    IgnoreModelName = "LocalViewmodel",
    TeamCacheInterval = 0.5,
    MaxTorsoTransparency = 1,
    MinWidthRatio = 0.24,
    MaxWidthRatio = 0.58,
    DepthScale = 0.85,
}
local DEFAULT_BOX_COLOR = Color3.fromRGB(255, 255, 255)

local type = type
local typeof = typeof
local pcall = pcall
local pairs = pairs
local ipairs = ipairs
local tick = tick
local string_lower = string.lower
local string_find = string.find
local math_huge = math.huge
local math_max = math.max
local math_clamp = math.clamp
local Vector2_new = Vector2.new
local Vector3_new = Vector3.new

local function applyConfigDefaults(config)
    local cfg = type(config) == "table" and config or {}

    if cfg.Enabled == nil then cfg.Enabled = true end
    if type(cfg.MaxDistance) ~= "number" then cfg.MaxDistance = 5000 end
    if type(cfg.ReconcileInterval) ~= "number" then cfg.ReconcileInterval = 1.0 end
    if type(cfg.Thickness) ~= "number" then cfg.Thickness = 1 end
    if type(cfg.Transparency) ~= "number" then cfg.Transparency = 1 end
    if typeof(cfg.OutlineColor) ~= "Color3" then cfg.OutlineColor = Color3.fromRGB(0, 0, 0) end
    if typeof(cfg.DefaultColor) ~= "Color3" then cfg.DefaultColor = DEFAULT_BOX_COLOR end
    if type(cfg.Objects) ~= "table" then cfg.Objects = {} end
    if type(cfg.Players) ~= "table" then cfg.Players = {} end

    for key, defaults in pairs(DEFAULT_OBJECTS) do
        local objCfg = cfg.Objects[key]
        if type(objCfg) ~= "table" then
            cfg.Objects[key] = {
                Enabled = defaults.Enabled,
                Color = defaults.Color,
            }
        else
            if objCfg.Enabled == nil then objCfg.Enabled = defaults.Enabled end
            if typeof(objCfg.Color) ~= "Color3" then objCfg.Color = defaults.Color end
        end
    end

    local playersCfg = cfg.Players
    if playersCfg.Enabled == nil then playersCfg.Enabled = DEFAULT_PLAYERS.Enabled end
    if typeof(playersCfg.Color) ~= "Color3" then playersCfg.Color = DEFAULT_PLAYERS.Color end
    if playersCfg.TeamCheck == nil then playersCfg.TeamCheck = DEFAULT_PLAYERS.TeamCheck end
    if type(playersCfg.FolderName) ~= "string" or playersCfg.FolderName == "" then
        playersCfg.FolderName = DEFAULT_PLAYERS.FolderName
    end
    if type(playersCfg.IgnoreModelName) ~= "string" then
        playersCfg.IgnoreModelName = DEFAULT_PLAYERS.IgnoreModelName
    end
    if type(playersCfg.TeamCacheInterval) ~= "number" then
        playersCfg.TeamCacheInterval = DEFAULT_PLAYERS.TeamCacheInterval
    end
    if type(playersCfg.MaxTorsoTransparency) ~= "number" then
        playersCfg.MaxTorsoTransparency = DEFAULT_PLAYERS.MaxTorsoTransparency
    end
    if playersCfg.MaxTorsoTransparency < 0 then
        playersCfg.MaxTorsoTransparency = 0
    elseif playersCfg.MaxTorsoTransparency > 1 then
        playersCfg.MaxTorsoTransparency = 1
    end
    if type(playersCfg.MinWidthRatio) ~= "number" then
        playersCfg.MinWidthRatio = DEFAULT_PLAYERS.MinWidthRatio
    end
    if type(playersCfg.MaxWidthRatio) ~= "number" then
        playersCfg.MaxWidthRatio = DEFAULT_PLAYERS.MaxWidthRatio
    end
    if playersCfg.MinWidthRatio < 0.1 then
        playersCfg.MinWidthRatio = 0.1
    end
    if playersCfg.MaxWidthRatio > 1 then
        playersCfg.MaxWidthRatio = 1
    end
    if playersCfg.MaxWidthRatio < playersCfg.MinWidthRatio then
        playersCfg.MaxWidthRatio = playersCfg.MinWidthRatio
    end
    if type(playersCfg.DepthScale) ~= "number" then
        playersCfg.DepthScale = DEFAULT_PLAYERS.DepthScale
    end
    if playersCfg.DepthScale < 0.3 then
        playersCfg.DepthScale = 0.3
    elseif playersCfg.DepthScale > 1.4 then
        playersCfg.DepthScale = 1.4
    end

    return cfg
end

local CONFIG = applyConfigDefaults(getgenv().ObjectESPConfig)
getgenv().ObjectESPConfig = CONFIG

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CAMERA = Workspace.CurrentCamera
if not CAMERA then
    warn("[test.lua] No current camera.")
    return
end

if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
    warn("[test.lua] Drawing API is not available on this executor.")
    return
end

local function isA(obj, className)
    local ok, result = pcall(function()
        return obj:IsA(className)
    end)
    return ok and result == true
end

local function isDescendantOf(obj, parent)
    local ok, result = pcall(function()
        return obj:IsDescendantOf(parent)
    end)
    return ok and result == true
end

local function getBoundingBoxSafe(model)
    local ok, cf, size = pcall(model.GetBoundingBox, model)
    if ok and cf and size then
        return cf, size
    end
    return nil
end

local function worldToViewportSafe(camera, worldPos)
    local ok, screenPos, onScreen = pcall(camera.WorldToViewportPoint, camera, worldPos)
    if ok then
        return screenPos, onScreen
    end
    return nil, false
end

local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function safeRemove(drawObj)
    if drawObj then
        pcall(function()
            drawObj.Visible = false
            drawObj:Remove()
        end)
    end
end

local previousState = getgenv()[STATE_KEY]
if type(previousState) == "table" and type(previousState.shutdown) == "function" then
    pcall(previousState.shutdown)
end

local OFFSETS = {
    Vector3.new(-0.5, -0.5, -0.5),
    Vector3.new(-0.5, -0.5,  0.5),
    Vector3.new(-0.5,  0.5, -0.5),
    Vector3.new(-0.5,  0.5,  0.5),
    Vector3.new( 0.5, -0.5, -0.5),
    Vector3.new( 0.5, -0.5,  0.5),
    Vector3.new( 0.5,  0.5, -0.5),
    Vector3.new( 0.5,  0.5,  0.5),
}

local state = {
    entries = {}, -- [container] = entry
    connections = {},
    viewmodelConnections = {},
    viewmodelsFolder = nil,
    teamHighlightCache = {},
    lastTeamCacheUpdate = 0,
    lastReconcile = 0,
}

local function clearConnectionList(list)
    for i = 1, #list do
        safeDisconnect(list[i])
    end
    for i = #list, 1, -1 do
        list[i] = nil
    end
end

local function getObjectType(name)
    if type(name) ~= "string" then
        return nil
    end

    local lowered = string_lower(name)
    for keyword, objCfg in pairs(CONFIG.Objects) do
        if lowered == keyword or string_find(lowered, keyword, 1, true) then
            return keyword, objCfg
        end
    end
    return nil
end

local function updateTeamHighlightCache()
    state.teamHighlightCache = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if isA(obj, "Highlight") and obj.Adornee and not obj:GetAttribute("__op1_esp_chams") then
            state.teamHighlightCache[obj.Adornee] = true
        end
    end
    state.lastTeamCacheUpdate = tick()
end

local function getViewmodelsFolder()
    local playersCfg = CONFIG.Players
    local folderName = playersCfg and playersCfg.FolderName or DEFAULT_PLAYERS.FolderName
    local folder = state.viewmodelsFolder

    if folder and folder.Parent == Workspace and folder.Name == folderName then
        return folder
    end

    folder = Workspace:FindFirstChild(folderName)
    if folder and (isA(folder, "Folder") or isA(folder, "Model")) then
        state.viewmodelsFolder = folder
        return folder
    end

    state.viewmodelsFolder = nil
    return nil
end

local function isTrackablePlayerModel(model)
    local playersCfg = CONFIG.Players
    if not playersCfg or playersCfg.Enabled == false then
        return false
    end

    if not model or not isA(model, "Model") then
        return false
    end

    if playersCfg.IgnoreModelName and model.Name == playersCfg.IgnoreModelName then
        return false
    end

    local torso = model:FindFirstChild("torso")
    local head = model:FindFirstChild("head")
    if not torso or not head or not isA(torso, "BasePart") then
        return false
    end

    local torsoTransparency = torso.Transparency
    local okLocal, localModifier = pcall(function()
        return torso.LocalTransparencyModifier
    end)
    if okLocal and type(localModifier) == "number" and localModifier > torsoTransparency then
        torsoTransparency = localModifier
    end

    if torsoTransparency >= playersCfg.MaxTorsoTransparency then
        return false
    end

    return true
end

local function getContainerProfile(obj)
    if not CONFIG.Enabled then
        return nil
    end

    if not obj then
        return nil
    end

    if obj.Parent == Workspace then
        local key, objCfg = getObjectType(obj.Name)
        if key and objCfg and objCfg.Enabled ~= false and (isA(obj, "BasePart") or isA(obj, "Model")) then
            return {
                kind = "object",
                key = key,
                color = objCfg.Color or CONFIG.DefaultColor,
            }
        end
    end

    local playersCfg = CONFIG.Players
    if playersCfg and playersCfg.Enabled ~= false then
        local viewmodels = getViewmodelsFolder()
        if viewmodels and obj.Parent == viewmodels and isTrackablePlayerModel(obj) then
            if playersCfg.TeamCheck then
                local now = tick()
                if now - state.lastTeamCacheUpdate >= playersCfg.TeamCacheInterval then
                    updateTeamHighlightCache()
                end

                if state.teamHighlightCache[obj] == true then
                    return nil
                end
            end

            return {
                kind = "player",
                key = "player",
                color = playersCfg.Color or CONFIG.DefaultColor,
            }
        end
    end

    return nil
end

local function isTargetObject(obj)
    return getContainerProfile(obj) ~= nil
end

local function createBox(color)
    local outline = Drawing.new("Square")
    outline.Visible = false
    outline.Filled = false
    outline.Color = CONFIG.OutlineColor
    outline.Thickness = CONFIG.Thickness + 2
    outline.Transparency = CONFIG.Transparency

    local box = Drawing.new("Square")
    box.Visible = false
    box.Filled = false
    box.Color = color or CONFIG.DefaultColor
    box.Thickness = CONFIG.Thickness
    box.Transparency = CONFIG.Transparency

    return box, outline
end

local function hideEntry(entry)
    if entry and entry.box and entry.outline then
        entry.box.Visible = false
        entry.outline.Visible = false
    end
end

local function unregisterContainer(container)
    local entry = state.entries[container]
    if not entry then
        return
    end

    safeRemove(entry.box)
    safeRemove(entry.outline)
    state.entries[container] = nil
end

local function ensureContainer(container)
    if not container or state.entries[container] then
        return
    end

    local profile = getContainerProfile(container)
    if not profile then
        return
    end

    local box, outline = createBox(profile.color)
    state.entries[container] = {
        container = container,
        kind = profile.kind,
        key = profile.key,
        color = profile.color,
        box = box,
        outline = outline,
    }
end

local function collectContainers()
    local found = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if getContainerProfile(obj) then
            found[obj] = true
        end
    end

    local viewmodels = getViewmodelsFolder()
    if viewmodels then
        for _, obj in ipairs(viewmodels:GetChildren()) do
            if getContainerProfile(obj) then
                found[obj] = true
            end
        end
    end
    return found
end

local function getContainerRenderInfo(container)
    if isA(container, "Model") then
        local torso = container:FindFirstChild("torso")
        local head = container:FindFirstChild("head")
        if torso and head and isA(torso, "BasePart") then
            local playersCfg = CONFIG.Players
            local minX, minY, minZ = math_huge, math_huge, math_huge
            local maxX, maxY, maxZ = -math_huge, -math_huge, -math_huge
            local hasAnyPart = false

            local function scanPart(part)
                if not part or not isA(part, "BasePart") then
                    return
                end
                hasAnyPart = true

                for i = 1, 8 do
                    local offset = OFFSETS[i]
                    local worldPos = part.CFrame * Vector3_new(
                        offset.X * part.Size.X,
                        offset.Y * part.Size.Y,
                        offset.Z * part.Size.Z
                    )
                    local localPos = torso.CFrame:PointToObjectSpace(worldPos)

                    if localPos.X < minX then minX = localPos.X end
                    if localPos.Y < minY then minY = localPos.Y end
                    if localPos.Z < minZ then minZ = localPos.Z end
                    if localPos.X > maxX then maxX = localPos.X end
                    if localPos.Y > maxY then maxY = localPos.Y end
                    if localPos.Z > maxZ then maxZ = localPos.Z end
                end
            end

            scanPart(torso)
            scanPart(head)
            scanPart(container:FindFirstChild("shoulder1"))
            scanPart(container:FindFirstChild("shoulder2"))
            scanPart(container:FindFirstChild("arm1"))
            scanPart(container:FindFirstChild("arm2"))
            scanPart(container:FindFirstChild("hip1"))
            scanPart(container:FindFirstChild("hip2"))
            scanPart(container:FindFirstChild("leg1"))
            scanPart(container:FindFirstChild("leg2"))

            if hasAnyPart then
                local sizeY = maxY - minY
                if sizeY > 0.05 then
                    local sizeX = maxX - minX
                    local sizeZ = maxZ - minZ
                    local width = math_clamp(math_max(sizeX, sizeZ), sizeY * playersCfg.MinWidthRatio, sizeY * playersCfg.MaxWidthRatio)
                    local depth = math_max(width * playersCfg.DepthScale, 0.1)

                    local centerLocal = Vector3_new(
                        (minX + maxX) * 0.5,
                        (minY + maxY) * 0.5,
                        (minZ + maxZ) * 0.5
                    )
                    local cframe = torso.CFrame * CFrame.new(centerLocal)
                    return cframe, Vector3_new(width, sizeY, depth), cframe.Position
                end
            end
        end
    end

    if isA(container, "BasePart") then
        return container.CFrame, container.Size, container.Position
    end

    if isA(container, "Model") then
        local cf, size = getBoundingBoxSafe(container)
        if cf and size and size.Magnitude > 0.05 then
            return cf, size, cf.Position
        end
    end

    return nil
end

local function projectBox(cframe, size)
    local half = size * 0.5

    local minX, minY = math_huge, math_huge
    local maxX, maxY = -math_huge, -math_huge
    local visibleCount = 0

    for i = 1, 8 do
        local offset = OFFSETS[i]
        local worldPos = cframe * Vector3_new(
            offset.X * half.X * 2,
            offset.Y * half.Y * 2,
            offset.Z * half.Z * 2
        )

        local screenPos, onScreen = worldToViewportSafe(CAMERA, worldPos)
        if onScreen and screenPos.Z > 0 then
            visibleCount = visibleCount + 1
            if screenPos.X < minX then minX = screenPos.X end
            if screenPos.Y < minY then minY = screenPos.Y end
            if screenPos.X > maxX then maxX = screenPos.X end
            if screenPos.Y > maxY then maxY = screenPos.Y end
        end
    end

    if visibleCount == 0 then
        return nil
    end

    local width = maxX - minX
    local height = maxY - minY
    if width < 2 or height < 2 then
        return nil
    end

    return minX, minY, width, height
end

local function updateEntry(entry)
    local container = entry.container
    local profile = getContainerProfile(container)
    if not container or not profile then
        unregisterContainer(container)
        return
    end

    entry.kind = profile.kind
    entry.key = profile.key

    local expectedColor = profile.color or CONFIG.DefaultColor
    if entry.color ~= expectedColor then
        entry.color = expectedColor
        entry.box.Color = expectedColor
    end

    entry.box.Thickness = CONFIG.Thickness
    entry.outline.Thickness = CONFIG.Thickness + 2
    entry.box.Transparency = CONFIG.Transparency
    entry.outline.Transparency = CONFIG.Transparency
    entry.outline.Color = CONFIG.OutlineColor

    local cframe, size, position = getContainerRenderInfo(container)
    if not cframe then
        unregisterContainer(container)
        return
    end

    local distance = (CAMERA.CFrame.Position - position).Magnitude
    if distance > CONFIG.MaxDistance then
        hideEntry(entry)
        return
    end

    local minX, minY, width, height = projectBox(cframe, size)
    if not minX then
        hideEntry(entry)
        return
    end

    entry.outline.Position = Vector2_new(minX, minY)
    entry.outline.Size = Vector2_new(width, height)
    entry.outline.Visible = true

    entry.box.Position = Vector2_new(minX, minY)
    entry.box.Size = Vector2_new(width, height)
    entry.box.Visible = true
end

local function reconcile()
    local found = collectContainers()

    for container in pairs(found) do
        ensureContainer(container)
    end

    for container in pairs(state.entries) do
        if not found[container] then
            unregisterContainer(container)
        end
    end
end

local function attachViewmodelConnections(folder)
    clearConnectionList(state.viewmodelConnections)
    state.viewmodelsFolder = folder

    if not folder then
        return
    end

    state.viewmodelConnections[#state.viewmodelConnections + 1] = folder.ChildAdded:Connect(function(obj)
        if getContainerProfile(obj) then
            ensureContainer(obj)
        end
    end)

    state.viewmodelConnections[#state.viewmodelConnections + 1] = folder.ChildRemoved:Connect(function(obj)
        if state.entries[obj] then
            unregisterContainer(obj)
        end
    end)
end

attachViewmodelConnections(getViewmodelsFolder())
reconcile()

state.connections[#state.connections + 1] = Workspace.ChildAdded:Connect(function(obj)
    if getContainerProfile(obj) then
        ensureContainer(obj)
    end

    local playersCfg = CONFIG.Players
    if playersCfg and obj.Name == playersCfg.FolderName and (isA(obj, "Folder") or isA(obj, "Model")) then
        attachViewmodelConnections(obj)
    end

    if playersCfg and playersCfg.TeamCheck and isA(obj, "Highlight") then
        state.lastTeamCacheUpdate = 0
    end
end)

state.connections[#state.connections + 1] = Workspace.ChildRemoved:Connect(function(obj)
    if state.entries[obj] then
        unregisterContainer(obj)
    end

    if obj == state.viewmodelsFolder then
        attachViewmodelConnections(nil)
    end

    local playersCfg = CONFIG.Players
    if playersCfg and playersCfg.TeamCheck and isA(obj, "Highlight") then
        state.lastTeamCacheUpdate = 0
    end
end)

state.connections[#state.connections + 1] = RunService.RenderStepped:Connect(function()
    CAMERA = Workspace.CurrentCamera or CAMERA

    if not CONFIG.Enabled then
        for _, entry in pairs(state.entries) do
            hideEntry(entry)
        end
    end

    for _, entry in pairs(state.entries) do
        updateEntry(entry)
    end

    local now = tick()
    if now - state.lastReconcile >= CONFIG.ReconcileInterval then
        state.lastReconcile = now
        reconcile()
    end
end)

state.shutdown = function()
    clearConnectionList(state.connections)
    clearConnectionList(state.viewmodelConnections)
    state.viewmodelsFolder = nil

    for container in pairs(state.entries) do
        unregisterContainer(container)
    end

    state.entries = {}
end

getgenv()[STATE_KEY] = state
getgenv().StopObjectESP = function()
    local active = getgenv()[STATE_KEY]
    if type(active) == "table" and type(active.shutdown) == "function" then
        active.shutdown()
    end
end
