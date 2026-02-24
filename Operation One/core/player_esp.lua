local player_esp = {}

local has_esp = {}
local esp_ran = {}
local object_esp = {}
local core_gui
local players
local run_service
local camera = cloneref(workspace.CurrentCamera)
local initialized = false
local object_added_connection

local settings = {
    health_bar = false,
    skelton = false,
    skelton_color = Color3.fromRGB(255, 255, 255),
    skelton_thickness = 1,
    names = false,
    name_color = Color3.fromRGB(255, 255, 255),
    distance = false,
    distance_color = Color3.fromRGB(255, 255, 255),
    weapon = false,
    weapon_color = Color3.fromRGB(255, 255, 255),
    box = false,
    box_color = Color3.fromRGB(255, 255, 255),
    box_filled = false,
    box_fill_color = Color3.fromRGB(0, 0, 0),
    box_fill_transparency = 0.85,
    box_corner = false,
    box_corner_color = Color3.fromRGB(255, 255, 255),
    box_corner_thickness = 1,
    box_corner_length = 14,
    chams = false,
    chams_fill_color = Color3.fromRGB(243, 116, 166),
    chams_outline_color = Color3.fromRGB(243, 116, 166),
    chams_fill_transparency = 0.5,
    chams_outline_transparency = 0,
    chams_visible_check = false,
    show_claymores = false,
    show_drones = false,
    claymore_color = Color3.fromRGB(255, 0, 0),
    drone_color = Color3.fromRGB(0, 255, 255),
    team_check = false,
    max_distance = 1000,
}

local bone_connections = {
    { "torso", "head" },
    { "torso", "shoulder1" },
    { "torso", "shoulder2" },
    { "shoulder1", "arm1" },
    { "shoulder2", "arm2" },
    { "torso", "hip1" },
    { "torso", "hip2" },
    { "hip1", "leg1" },
    { "hip2", "leg2" },
}

local teamHighlightCache = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 0.5

local function updateTeamHighlightCache()
    teamHighlightCache = {}
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Highlight") and obj.Adornee then
            teamHighlightCache[obj.Adornee] = true
        end
    end
end

local function hasTeamHighlight(model)
    if not model then
        return false
    end

    local currentTime = tick()
    if currentTime - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        updateTeamHighlightCache()
        lastCacheUpdate = currentTime
    end

    return teamHighlightCache[model] == true
end

local function should_track_viewmodel(vm)
    if not vm or not vm:IsA("Model") then
        return false
    end
    if vm.Name == "LocalViewmodel" then
        return false
    end

    local head = vm:FindFirstChild("head")
    local torso = vm:FindFirstChild("torso")
    if not head or not torso or not torso:IsA("BasePart") then
        return false
    end

    return true
end

local function remove_drawing(obj)
    if obj then
        pcall(function()
            obj:Remove()
        end)
    end
end

local function destroy_instance(obj)
    if obj then
        pcall(function()
            obj:Destroy()
        end)
    end
end

local function set_visible(drawings, visible)
    for _, d in ipairs(drawings) do
        if d then
            d.Visible = visible
        end
    end
end

local function find_weapon_name(character)
    if not character then
        return nil
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("item_type") then
            return child.Name
        end
    end

    return nil
end

local function get_bounds_2d(character)
    local cf, size = character:GetBoundingBox()
    local corners = {
        cf * Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
        cf * Vector3.new(-size.X / 2, -size.Y / 2, size.Z / 2),
        cf * Vector3.new(-size.X / 2, size.Y / 2, -size.Z / 2),
        cf * Vector3.new(-size.X / 2, size.Y / 2, size.Z / 2),
        cf * Vector3.new(size.X / 2, -size.Y / 2, -size.Z / 2),
        cf * Vector3.new(size.X / 2, -size.Y / 2, size.Z / 2),
        cf * Vector3.new(size.X / 2, size.Y / 2, -size.Z / 2),
        cf * Vector3.new(size.X / 2, size.Y / 2, size.Z / 2),
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local visible = false

    for _, corner in ipairs(corners) do
        local sp, on = camera:WorldToViewportPoint(corner)
        if on and sp.Z > 0 then
            visible = true
            minX = math.min(minX, sp.X)
            minY = math.min(minY, sp.Y)
            maxX = math.max(maxX, sp.X)
            maxY = math.max(maxY, sp.Y)
        end
    end

    if not visible then
        return nil
    end

    return minX, minY, maxX, maxY
end

local function hide_esp_objects(data)
    if not data then
        return
    end

    set_visible(data.corner_lines, false)
    set_visible(data.skeleton_lines, false)

    data.health_bar_outer.Visible = false
    data.health_bar_inner.Visible = false
    data.name_text.Visible = false
    data.distance_text.Visible = false
    data.weapon_text.Visible = false
    data.box_outline.Visible = false
    data.box_fill.Visible = false

    if data.chams then
        data.chams.Enabled = false
    end
end

rawset(player_esp, "set_player_esp", newcclosure(function(character: Model)
    task.wait(0.1)

    if not character:IsA("Model") or has_esp[character] or not should_track_viewmodel(character) then
        return
    end

    local torso = character:FindFirstChild("torso")
    if not torso or not torso:IsA("BasePart") then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    local data = {
        self = character,
        humanoid = humanoid,
    }

    data.health_bar_inner = Drawing.new("Square")
    data.health_bar_inner.Visible = false
    data.health_bar_inner.Thickness = 0
    data.health_bar_inner.Filled = true
    data.health_bar_inner.ZIndex = 6

    data.health_bar_outer = Drawing.new("Square")
    data.health_bar_outer.Visible = false
    data.health_bar_outer.Color = Color3.new(0.152941, 0.152941, 0.152941)
    data.health_bar_outer.Transparency = 0.7
    data.health_bar_outer.Thickness = 0
    data.health_bar_outer.Filled = true
    data.health_bar_outer.ZIndex = 5

    data.name_text = Drawing.new("Text")
    data.name_text.Visible = false
    data.name_text.Center = true
    data.name_text.Outline = true
    data.name_text.Size = 13
    data.name_text.Font = 2
    data.name_text.ZIndex = 7

    data.distance_text = Drawing.new("Text")
    data.distance_text.Visible = false
    data.distance_text.Center = true
    data.distance_text.Outline = true
    data.distance_text.Size = 13
    data.distance_text.Font = 2
    data.distance_text.ZIndex = 7

    data.weapon_text = Drawing.new("Text")
    data.weapon_text.Visible = false
    data.weapon_text.Center = true
    data.weapon_text.Outline = true
    data.weapon_text.Size = 13
    data.weapon_text.Font = 2
    data.weapon_text.ZIndex = 7

    data.box_outline = Drawing.new("Square")
    data.box_outline.Visible = false
    data.box_outline.Thickness = 1
    data.box_outline.Filled = false
    data.box_outline.ZIndex = 4

    data.box_fill = Drawing.new("Square")
    data.box_fill.Visible = false
    data.box_fill.Thickness = 0
    data.box_fill.Filled = true
    data.box_fill.ZIndex = 3

    data.corner_lines = {}
    for _ = 1, 8 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1
        line.ZIndex = 6
        table.insert(data.corner_lines, line)
    end

    data.skeleton_lines = {}
    for _ = 1, #bone_connections do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1
        line.ZIndex = 7
        table.insert(data.skeleton_lines, line)
    end

    data.chams = Instance.new("Highlight")
    data.chams.Enabled = false
    data.chams.Adornee = character
    data.chams.Parent = core_gui

    local c1
    local c2

    c1 = run_service.RenderStepped:Connect(function()
        camera = cloneref(workspace.CurrentCamera)

        local localTorso = character:FindFirstChild("torso")
        if not localTorso or not localTorso:IsA("BasePart") or localTorso.Transparency >= 1 then
            hide_esp_objects(data)
            return
        end

        if settings.team_check and hasTeamHighlight(character) then
            hide_esp_objects(data)
            return
        end

        local distance = (camera.CFrame.Position - localTorso.Position).Magnitude / 3.5714285714
        if settings.max_distance > 0 and distance > settings.max_distance then
            hide_esp_objects(data)
            return
        end

        local point, on = to_view_point(localTorso.Position)
        if not on then
            hide_esp_objects(data)
            return
        end

        for _, callback in next, esp_ran do
            pcall(callback, data, point)
        end

        local minX, minY, maxX, maxY = get_bounds_2d(character)
        if not minX then
            hide_esp_objects(data)
            return
        end

        local width = maxX - minX
        local height = maxY - minY
        if width <= 1 or height <= 1 then
            hide_esp_objects(data)
            return
        end

        data.name_text.Visible = settings.names
        if settings.names then
            data.name_text.Color = settings.name_color
            data.name_text.Text = character.Name
            data.name_text.Position = Vector2.new(minX + (width / 2), minY - 14)
        end

        data.distance_text.Visible = settings.distance
        if settings.distance then
            data.distance_text.Color = settings.distance_color
            data.distance_text.Text = string.format("[%d]", math.floor(distance))
            data.distance_text.Position = Vector2.new(minX + (width / 2), minY - 1)
        end

        data.weapon_text.Visible = settings.weapon
        if settings.weapon then
            local weaponName = find_weapon_name(character)
            if weaponName then
                data.weapon_text.Color = settings.weapon_color
                data.weapon_text.Text = weaponName
                data.weapon_text.Position = Vector2.new(minX + (width / 2), maxY + 2)
            else
                data.weapon_text.Visible = false
            end
        end

        data.box_outline.Visible = settings.box
        if settings.box then
            data.box_outline.Color = settings.box_color
            data.box_outline.Size = Vector2.new(width, height)
            data.box_outline.Position = Vector2.new(minX, minY)
        end

        data.box_fill.Visible = settings.box_filled
        if settings.box_filled then
            data.box_fill.Color = settings.box_fill_color
            data.box_fill.Transparency = math.clamp(settings.box_fill_transparency, 0, 1)
            data.box_fill.Size = Vector2.new(width, height)
            data.box_fill.Position = Vector2.new(minX, minY)
        end

        if settings.box_corner then
            local cornerColor = settings.box_corner_color
            local cornerThickness = settings.box_corner_thickness
            local cornerLength = math.min(settings.box_corner_length, width * 0.4, height * 0.4)

            local x1, y1 = minX, minY
            local x2, y2 = maxX, maxY

            local lines = data.corner_lines

            lines[1].From = Vector2.new(x1, y1)
            lines[1].To = Vector2.new(x1 + cornerLength, y1)
            lines[2].From = Vector2.new(x1, y1)
            lines[2].To = Vector2.new(x1, y1 + cornerLength)

            lines[3].From = Vector2.new(x2, y1)
            lines[3].To = Vector2.new(x2 - cornerLength, y1)
            lines[4].From = Vector2.new(x2, y1)
            lines[4].To = Vector2.new(x2, y1 + cornerLength)

            lines[5].From = Vector2.new(x1, y2)
            lines[5].To = Vector2.new(x1 + cornerLength, y2)
            lines[6].From = Vector2.new(x1, y2)
            lines[6].To = Vector2.new(x1, y2 - cornerLength)

            lines[7].From = Vector2.new(x2, y2)
            lines[7].To = Vector2.new(x2 - cornerLength, y2)
            lines[8].From = Vector2.new(x2, y2)
            lines[8].To = Vector2.new(x2, y2 - cornerLength)

            for _, line in ipairs(lines) do
                line.Visible = true
                line.Color = cornerColor
                line.Thickness = cornerThickness
            end
        else
            set_visible(data.corner_lines, false)
        end

        if settings.health_bar and data.humanoid and data.humanoid.MaxHealth > 0 then
            local hp = math.clamp(data.humanoid.Health / data.humanoid.MaxHealth, 0, 1)
            local barWidth = 3
            local barHeight = height
            local barX = minX - 6
            local barY = minY

            data.health_bar_outer.Visible = true
            data.health_bar_outer.Size = Vector2.new(barWidth, barHeight)
            data.health_bar_outer.Position = Vector2.new(barX, barY)

            data.health_bar_inner.Visible = true
            data.health_bar_inner.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), hp)
            data.health_bar_inner.Size = Vector2.new(barWidth - 1, (barHeight - 2) * hp)
            data.health_bar_inner.Position = Vector2.new(barX + 0.5, barY + (barHeight - 1) - ((barHeight - 2) * hp))
        else
            data.health_bar_outer.Visible = false
            data.health_bar_inner.Visible = false
        end

        if settings.skelton then
            for i, pair in ipairs(bone_connections) do
                local p1 = character:FindFirstChild(pair[1])
                local p2 = character:FindFirstChild(pair[2])
                local line = data.skeleton_lines[i]

                if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                    local s1, on1 = camera:WorldToViewportPoint(p1.Position)
                    local s2, on2 = camera:WorldToViewportPoint(p2.Position)
                    if on1 and on2 and s1.Z > 0 and s2.Z > 0 then
                        line.From = Vector2.new(s1.X, s1.Y)
                        line.To = Vector2.new(s2.X, s2.Y)
                        line.Visible = true
                        line.Color = settings.skelton_color
                        line.Thickness = settings.skelton_thickness
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            set_visible(data.skeleton_lines, false)
        end

        if settings.chams then
            data.chams.Enabled = true
            data.chams.Adornee = character
            data.chams.FillColor = settings.chams_fill_color
            data.chams.OutlineColor = settings.chams_outline_color
            data.chams.FillTransparency = math.clamp(settings.chams_fill_transparency, 0, 1)
            data.chams.OutlineTransparency = math.clamp(settings.chams_outline_transparency, 0, 1)
            data.chams.DepthMode = settings.chams_visible_check and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
        else
            data.chams.Enabled = false
        end
    end)

    c2 = character.AncestryChanged:Connect(function(_, parent)
        if parent ~= nil then
            return
        end

        if c1 then
            c1:Disconnect()
        end

        if c2 then
            c2:Disconnect()
        end

        remove_drawing(data.health_bar_inner)
        remove_drawing(data.health_bar_outer)
        remove_drawing(data.name_text)
        remove_drawing(data.distance_text)
        remove_drawing(data.weapon_text)
        remove_drawing(data.box_outline)
        remove_drawing(data.box_fill)

        for _, line in ipairs(data.corner_lines) do
            remove_drawing(line)
        end

        for _, line in ipairs(data.skeleton_lines) do
            remove_drawing(line)
        end

        destroy_instance(data.chams)
        has_esp[character] = nil
    end)

    has_esp[character] = data
end))

local function add_object_esp(obj: Instance, color: Color3)
    if object_esp[obj] then
        return
    end

    if not obj:IsA("Model") then
        return
    end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = color
    box.Filled = false
    box.Visible = true
    box.ZIndex = 5

    local conn
    conn = run_service.RenderStepped:Connect(function()
        camera = cloneref(workspace.CurrentCamera)

        if not obj or not obj:IsDescendantOf(workspace) then
            remove_drawing(box)
            object_esp[obj] = nil
            if conn then
                conn:Disconnect()
            end
            return
        end

        local enabled = (
            (obj.Name == "Claymore" and settings.show_claymores) or
            (obj.Name == "Drone" and settings.show_drones)
        )

        if not enabled then
            box.Visible = false
            return
        end

        local cf, size = obj:GetBoundingBox()
        local corners = {
            cf * Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
            cf * Vector3.new(-size.X / 2, -size.Y / 2, size.Z / 2),
            cf * Vector3.new(-size.X / 2, size.Y / 2, -size.Z / 2),
            cf * Vector3.new(-size.X / 2, size.Y / 2, size.Z / 2),
            cf * Vector3.new(size.X / 2, -size.Y / 2, -size.Z / 2),
            cf * Vector3.new(size.X / 2, -size.Y / 2, size.Z / 2),
            cf * Vector3.new(size.X / 2, size.Y / 2, -size.Z / 2),
            cf * Vector3.new(size.X / 2, size.Y / 2, size.Z / 2),
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local visible = false

        for _, corner in ipairs(corners) do
            local screenPos, onScreen = camera:WorldToViewportPoint(corner)
            if onScreen then
                visible = true
                minX = math.min(minX, screenPos.X)
                minY = math.min(minY, screenPos.Y)
                maxX = math.max(maxX, screenPos.X)
                maxY = math.max(maxY, screenPos.Y)
            end
        end

        if not visible then
            box.Visible = false
            return
        end

        box.Color = obj.Name == "Claymore" and settings.claymore_color or settings.drone_color
        box.Size = Vector2.new(maxX - minX, maxY - minY)
        box.Position = Vector2.new(minX, minY)
        box.Visible = true
    end)

    object_esp[obj] = { box = box, conn = conn }
end

local function track_objects()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "Claymore" then
            add_object_esp(obj, settings.claymore_color)
        elseif obj.Name == "Drone" then
            add_object_esp(obj, settings.drone_color)
        end
    end

    if object_added_connection then
        object_added_connection:Disconnect()
    end

    object_added_connection = workspace.ChildAdded:Connect(function(obj)
        if obj.Name == "Claymore" then
            add_object_esp(obj, settings.claymore_color)
        elseif obj.Name == "Drone" then
            add_object_esp(obj, settings.drone_color)
        end
    end)
end

rawset(player_esp, "on_esp_ran", newcclosure(function(func)
    table.insert(esp_ran, func)
    return {
        remove = function()
            for i, v in next, esp_ran do
                if v == func then
                    esp_ran[i] = nil
                    break
                end
            end
        end
    }
end))

rawset(player_esp, "get_player_from_has_esp", newcclosure(function(character)
    return has_esp[character]
end))

rawset(player_esp, "esp_player_settings", settings)

player_esp.init = function()
    if initialized then
        return
    end

    initialized = true
    players = get_service("Players")
    run_service = get_service("RunService")
    core_gui = get_service("CoreGui")

    local viewmodels = workspace:WaitForChild("Viewmodels")

    for _, vm in ipairs(viewmodels:GetChildren()) do
        if should_track_viewmodel(vm) then
            player_esp.set_player_esp(vm)
        end
    end

    viewmodels.ChildAdded:Connect(function(vm)
        if should_track_viewmodel(vm) then
            player_esp.set_player_esp(vm)
        end
    end)

    track_objects()
end

return player_esp
