
local aimbot = {}
local user_input_service
local run_service
local players
local camera = cloneref(workspace.CurrentCamera)
local render_connection
local initialized = false

local screen_middle = camera.ViewportSize / 2
local viewport_connection

local vec_up = Vector3.new(0, 1, 0)
local visibility_params = nil
local teamHighlightCache = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 0.5

local function get_visibility_params()
    if visibility_params then return visibility_params end
    visibility_params = RaycastParams.new()
    visibility_params.FilterType = Enum.RaycastFilterType.Exclude
    local viewmodelsFolder = workspace:FindFirstChild("Viewmodels")
    local ignore = {camera}
    if viewmodelsFolder then
        local localVM = viewmodelsFolder:FindFirstChild("LocalViewmodel")
        if localVM then ignore[2] = localVM end
    end
    visibility_params.FilterDescendantsInstances = ignore
    return visibility_params
end

local function updateTeamHighlightCache()
    teamHighlightCache = {}
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Highlight") and obj.Adornee then
            teamHighlightCache[obj.Adornee] = true
        end
    end
end

local function hasTeamHighlight(model)
    if not model then return false end

    local currentTime = tick()
    if currentTime - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        updateTeamHighlightCache()
        lastCacheUpdate = currentTime
    end

    return teamHighlightCache[model] == true
end

local settings = {
    enabled = false,
    silent = false,
    visibility = false,
    team_check = false,
    target_players = false,
    target_gadgets = false,
    target_cameras = false,
    debug = false,
    circle = Drawing.new("Circle"),
    screen_middle = screen_middle,
    smoothing = 200,
    pressed = "aiming",
    hitbox_priority = {
        "head", "torso", "shoulder1", "shoulder2",
        "arm1", "arm2", "hip1", "hip2", "leg1", "leg2"
    },
    hitbox_offset = Vector3.new(0, 0, 0)
}
local circle = settings.circle

pcall(function()
    circle.Visible = false
    circle.Radius = 120
    circle.Filled = false
    circle.Thickness = 1
    circle.Color = Color3.new(1,1,1)
    circle.Position = screen_middle
end)

local function update_screen_middle()
    screen_middle = camera.ViewportSize / 2
    settings.screen_middle = screen_middle
    pcall(function()
        if circle.Visible then circle.Position = screen_middle end
    end)
end
if viewport_connection then viewport_connection:Disconnect() end
viewport_connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update_screen_middle)
update_screen_middle()

local function get_useable()
    return (
        settings.pressed == "None" and true
        or settings.pressed == "shooting" and user_input_service:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        or settings.pressed == "aiming"  and user_input_service:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        or settings.pressed == "any"     and (
            user_input_service:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or
            user_input_service:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        )
    ) or false
end

local function is_valid_viewmodel(vm)
    if not vm or vm.Name == "LocalViewmodel" then return false end

    local torso = vm:FindFirstChild("torso")
    if torso and torso:IsA("BasePart") and torso.Transparency == 1 then
        return false
    end

    if settings.team_check and hasTeamHighlight(vm) then
        return false
    end

    return true
end

local gadget_parts = {
    Drone = "HumanoidRootPart",
    Claymore = "Laser",
    ProximityAlarm = "RedDot",
    StickyCamera = "Cam",
    SignalDisruptor = "Screen",
}

local function can_hit_target(part, owner)
    if not settings.visibility then
        return true
    end

    local origin = camera.CFrame.Position
    local toPart = part.Position - origin
    if toPart.Magnitude <= 0 then
        return false
    end

    local rayResult = workspace:Raycast(origin, toPart.Unit * (toPart.Magnitude + 0.1), get_visibility_params())
    if not rayResult then
        return false
    end

    local hit = rayResult.Instance
    return hit == part or hit:IsDescendantOf(owner)
end

local function evaluate_part(owner, part, screen_mid, bestDist, closestVM, closestScr, closestPart)
    if not part or not part:IsA("BasePart") then
        return bestDist, closestVM, closestScr, closestPart
    end

    local aimPos = part.Position + settings.hitbox_offset
    local scrPos, onScreen
    if to_view_point then
        scrPos, onScreen = to_view_point(aimPos)
    else
        local rawPoint
        rawPoint, onScreen = camera:WorldToViewportPoint(aimPos)
        scrPos = Vector2.new(rawPoint.X, rawPoint.Y)
    end
    if not onScreen then
        return bestDist, closestVM, closestScr, closestPart
    end

    local dx = scrPos.X - screen_mid.X
    local dy = scrPos.Y - screen_mid.Y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > settings.circle.Radius then
        return bestDist, closestVM, closestScr, closestPart
    end

    if dist < bestDist and can_hit_target(part, owner) then
        return dist, owner, scrPos, part
    end

    return bestDist, closestVM, closestScr, closestPart
end

local function find_closest()
    local closestVM, closestScr, closestPart
    local bestDist = math.huge
    local screen_mid = settings.screen_middle
    if user_input_service then
        local mousePos = user_input_service:GetMouseLocation()
        screen_mid = Vector2.new(mousePos.X, mousePos.Y)
        settings.screen_middle = screen_mid
        pcall(function()
            if circle.Visible then
                circle.Position = screen_mid
            end
        end)
    end

    local viewmodels = workspace:FindFirstChild("Viewmodels")

    if settings.target_players and viewmodels then
        for _, vm in ipairs(viewmodels:GetChildren()) do
            if not is_valid_viewmodel(vm) then
                continue
            end

            local torso = vm:FindFirstChild("torso")
            if torso and torso:IsA("BasePart") and torso.Transparency == 1 then
                continue
            end

            for _, partName in ipairs(settings.hitbox_priority) do
                local part = vm:FindFirstChild(partName)
                if part then
                    bestDist, closestVM, closestScr, closestPart = evaluate_part(vm, part, screen_mid, bestDist, closestVM, closestScr, closestPart)
                end
            end
        end
    end

    if settings.target_gadgets then
        for _, model in ipairs(workspace:GetChildren()) do
            if model:IsA("Model") then
                local targetPartName = gadget_parts[model.Name]
                if targetPartName then
                    local part = model:FindFirstChild(targetPartName)
                    if part then
                        bestDist, closestVM, closestScr, closestPart = evaluate_part(model, part, screen_mid, bestDist, closestVM, closestScr, closestPart)
                    end
                end
            end
        end
    end

    if settings.target_cameras then
        for _, model in ipairs(workspace:GetChildren()) do
            if not model:IsA("Model") then
                continue
            end
            local folder = model:FindFirstChildWhichIsA("Folder")
            if not folder then
                continue
            end
            local defaultCameras = folder:FindFirstChild("DefaultCameras")
            if not defaultCameras then
                continue
            end

            for _, defaultCam in ipairs(defaultCameras:GetChildren()) do
                if defaultCam:IsA("Model") then
                    local dot = defaultCam:FindFirstChild("Dot")
                    if dot then
                        bestDist, closestVM, closestScr, closestPart = evaluate_part(defaultCam, dot, screen_mid, bestDist, closestVM, closestScr, closestPart)
                    end
                end
            end
        end
    end

    return nil, closestVM, closestScr, closestPart
end

rawset(aimbot, "aimbot_settings", settings)

aimbot.init = function()
    if initialized then
        return
    end
    initialized = true

    user_input_service = get_service("UserInputService")
    run_service        = get_service("RunService")
    players            = get_service("Players")

    local function renderStep()
        local mousePos = user_input_service:GetMouseLocation()
        settings.screen_middle = Vector2.new(mousePos.X, mousePos.Y)
        pcall(function()
            if circle.Visible then
                circle.Position = settings.screen_middle
            end
        end)

        if not settings.enabled or settings.silent or user_input_service.MouseBehavior == Enum.MouseBehavior.Default or not get_useable() then
            return
        end
        local _, vm, _, part = find_closest()
        if not (vm and part) then
            return
        end

        local targetCF = CFrame.lookAt(camera.CFrame.Position, part.Position, vec_up)
        local smooth = math.max(settings.smoothing, 1)
        local alpha = math.clamp(1 / smooth, 0, 1)
        camera.CFrame = camera.CFrame:Lerp(targetCF, alpha)
    end

    if render_connection then
        render_connection:Disconnect()
    end
    render_connection = run_service.RenderStepped:Connect(renderStep)

    local oldCFnew = clonefunction(CFrame.new)
    hook_function(CFrame.new, function(...)
        if settings.enabled and settings.silent and get_useable() then
            local stack_level
            if debug.info(2, "n") == "send_shoot" then
                stack_level = 2
            elseif debug.info(3, "n") == "send_shoot" then
                stack_level = 3
            end

            if stack_level then
                local _, vm, _, part = find_closest()
                if not (vm and part) then
                    return oldCFnew(...)
                end
                local origin = debug.getstack(stack_level, 3)
                if origin and origin.Position then
                    debug.setstack(stack_level, 6, CFrame.lookAt(origin.Position, part.Position))
                    if settings.debug then
                        print("[Aimbot] redirected ->", part:GetFullName())
                    end
                end
            end
        end
        return oldCFnew(...)
    end)
end

return aimbot
