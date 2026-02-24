pcall(function() setthreadidentity(8) end)
pcall(function() game:GetService("WebViewService"):Destroy() end)
run_on_actor(getactors()[1], [==[

    pcall(function() setthreadidentity(8) end)
-- ═══════════════════════════════════════════════════════════
-- SERVICES (with cloneref)
-- ═══════════════════════════════════════════════════════════
local cloneref = cloneref or function(obj) return obj end
local clonefunction = clonefunction or function(fn) return fn end

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local Workspace         = cloneref(game:GetService("Workspace"))
local RunService        = cloneref(game:GetService("RunService"))

-- ═══════════════════════════════════════════════════════════
-- MODULE
-- ═══════════════════════════════════════════════════════════

-- Clone original BEFORE replacing

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════
local CONFIG = {
    enabled = true,
    fov_radius = 70,
    target_players = true,
    target_gadgets = true,
    target_cameras = true,
    smoothness = 1,  -- 1 = instant, 0.1 = smooth
    debug = false,
}

local FOV_RADIUS_SQ = CONFIG.fov_radius * CONFIG.fov_radius

local TARGET_PARTS = {
    "head", "torso", "shoulder1", "shoulder2",
    "arm1", "arm2", "hip1", "hip2",
    "leg1", "leg2", "Sleeve", "Glove", "Boot"
}

-- ═══════════════════════════════════════════════════════════
-- CACHED REFERENCES
-- ═══════════════════════════════════════════════════════════
local viewmodelsFolder = nil
local camera = Workspace.CurrentCamera
local fovCircle = nil

-- FOV circle (Drawing API)
do
    if Drawing and Drawing.new then
        local env = (getgenv and getgenv()) or _G
        if env.__op1_silent_fov_circle then
            pcall(function()
                env.__op1_silent_fov_circle:Remove()
            end)
        end

        local circle = Drawing.new("Circle")
        circle.Visible = CONFIG.enabled
        circle.Filled = false
        circle.Thickness = 1.5
        circle.NumSides = 72
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Transparency = 1
        circle.Radius = CONFIG.fov_radius

        env.__op1_silent_fov_circle = circle
        fovCircle = circle

        RunService.RenderStepped:Connect(function()
            if not fovCircle then
                return
            end
            local mousePos = UserInputService:GetMouseLocation()
            fovCircle.Visible = CONFIG.enabled
            fovCircle.Radius = CONFIG.fov_radius
            fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function checkPart(part, mousePos, closestPart, closestDistSq)
    if not part or not part:IsA("BasePart") then 
        return closestPart, closestDistSq 
    end

    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
    if not onScreen then 
        return closestPart, closestDistSq 
    end

    local dx = screenPos.X - mousePos.X
    local dy = screenPos.Y - mousePos.Y
    local distSq = dx * dx + dy * dy

    if distSq <= FOV_RADIUS_SQ and distSq < closestDistSq then
        return part, distSq
    end

    return closestPart, closestDistSq
end

local function getClosestTargetToCursor()
    local closestPart, closestDistSq = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()

    if not viewmodelsFolder then
        viewmodelsFolder = Workspace:FindFirstChild("Viewmodels")
    end

    -- Players
    if CONFIG.target_players and viewmodelsFolder then
        for _, vm in ipairs(viewmodelsFolder:GetChildren()) do
            if vm.Name == "LocalViewmodel" or vm.Name ~= "Viewmodel" then continue end
            
            local torso = vm:FindFirstChild("torso")
            if torso and torso.Transparency == 1 then continue end

            for _, partName in ipairs(TARGET_PARTS) do
                local part = vm:FindFirstChild(partName)
                closestPart, closestDistSq = checkPart(part, mousePos, closestPart, closestDistSq)
            end
        end
    end

    -- Gadgets
    if CONFIG.target_gadgets then
        for _, model in ipairs(Workspace:GetChildren()) do
            if not model:IsA("Model") then continue end
            local modelName = model.Name
            local targetChild = nil

            if modelName == "Drone" then
                targetChild = model:FindFirstChild("HumanoidRootPart")
            elseif modelName == "Claymore" then
                targetChild = model:FindFirstChild("Laser")
            elseif modelName == "ProximityAlarm" then
                targetChild = model:FindFirstChild("RedDot")
            elseif modelName == "StickyCamera" then
                targetChild = model:FindFirstChild("Cam")
            elseif modelName == "SignalDisruptor" then
                targetChild = model:FindFirstChild("Screen")
            end

            if targetChild then
                closestPart, closestDistSq = checkPart(targetChild, mousePos, closestPart, closestDistSq)
            end
        end
    end

    -- Cameras
    if CONFIG.target_cameras then
        for _, model in ipairs(Workspace:GetChildren()) do
            if not model:IsA("Model") then continue end
            local folder = model:FindFirstChildWhichIsA("Folder")
            if not folder then continue end
            local defaultCameras = folder:FindFirstChild("DefaultCameras")
            if not defaultCameras then continue end
            
            for _, defaultCam in ipairs(defaultCameras:GetChildren()) do
                if not defaultCam:IsA("Model") then continue end
                local cam = defaultCam:FindFirstChild("Dot")
                if cam then
                    closestPart, closestDistSq = checkPart(cam, mousePos, closestPart, closestDistSq)
                end
            end
        end
    end

    return closestPart
end


local oldCF = clonefunction(CFrame.new)
hookfunction(CFrame.new, newcclosure(function(...)
    if not CONFIG.enabled then
        return oldCF(...)
    end

    local stack_level = nil
    if debug.info(2, "n") == "send_shoot" then
        stack_level = 2
    elseif debug.info(3, "n") == "send_shoot" then
        stack_level = 3
    end

    if stack_level then
        local target = getClosestTargetToCursor()
        if target then
            local origin = debug.getstack(stack_level, 3)
            if origin and origin.Position then
                debug.setstack(stack_level, 6, CFrame.lookAt(origin.Position, target.Position))
                if CONFIG.debug then
                    print("[Silent] stack redirected:", target:GetFullName())
                end
            end
        end
    end

    return oldCF(...)
end))
print('tite')

]==])

