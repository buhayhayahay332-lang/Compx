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
local viewmodels_added_connection

local settings = {
    health_bar = false,
    health_map_match_distance = 40,
    skelton = false,
    skelton_color = Color3.fromRGB(255, 255, 255),
    skelton_thickness = 1,
    names = false,
    name_color = Color3.fromRGB(255, 255, 255),
    font_size = 13,
    distance = false,
    distance_color = Color3.fromRGB(255, 255, 255),
    distance_position = "Text",
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
    box_animate = false,
    box_rotation_speed = 300,
    box_gradient = false,
    box_gradient_color_1 = Color3.fromRGB(243, 116, 116),
    box_gradient_color_2 = Color3.fromRGB(0, 0, 0),
    box_gradient_fill = false,
    box_gradient_fill_color_1 = Color3.fromRGB(243, 116, 116),
    box_gradient_fill_color_2 = Color3.fromRGB(0, 0, 0),
    chams = false,
    chams_thermal = false,
    chams_fill_color = Color3.fromRGB(243, 116, 166),
    chams_outline_color = Color3.fromRGB(243, 116, 166),
    chams_fill_transparency = 0.5,
    chams_outline_transparency = 0,
    chams_visible_check = false,
    chams_max_distance = 1000,
    fade_on_distance = false,
    fade_on_death = false,
    fade_on_leave = false,
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
local ESP_CHAMS_TAG = "__op1_esp_chams"
local healthCandidatesCache = {}
local lastHealthCandidatesUpdate = 0
local HEALTH_CANDIDATES_UPDATE_INTERVAL = 0.2
local PART_REFRESH_INTERVAL = 0.3
local WEAPON_SCAN_INTERVAL = 0.2
local TRACKED_VIEWMODEL_PARTS = {
    "head",
    "torso",
    "shoulder1",
    "shoulder2",
    "arm1",
    "arm2",
    "hip1",
    "hip2",
    "leg1",
    "leg2",
}

local function updateTeamHighlightCache()
    teamHighlightCache = {}
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Highlight") and obj.Adornee and not obj:GetAttribute(ESP_CHAMS_TAG) then
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

local function set_transparency(drawings, alpha)
    for _, d in ipairs(drawings) do
        if d then
            d.Transparency = alpha
        end
    end
end

local function refresh_viewmodel_parts(character, data, force)
    if not data then
        return {}
    end

    local now = tick()
    if (not force) and data.cached_parts and (now - (data.last_part_refresh or 0) < PART_REFRESH_INTERVAL) then
        return data.cached_parts
    end

    local cached = data.cached_parts or {}
    for _, partName in ipairs(TRACKED_VIEWMODEL_PARTS) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            cached[partName] = part
        else
            cached[partName] = nil
        end
    end

    data.cached_parts = cached
    data.last_part_refresh = now
    return cached
end

local function find_weapon_name(character, data)
    if not character then
        return nil
    end

    if data then
        local now = tick()
        if now - (data.last_weapon_scan or 0) < WEAPON_SCAN_INTERVAL then
            return data.cached_weapon_name
        end

        data.last_weapon_scan = now
        data.cached_weapon_name = nil
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("item_type") then
            if data then
                data.cached_weapon_name = child.Name
            end
            return child.Name
        end
    end

    if data then
        data.cached_weapon_name = nil
    end

    return nil
end

local function project_world_point(worldPoint)
    local projected, onScreen = camera:WorldToViewportPoint(worldPoint)
    if onScreen and projected.Z > 0 then
        return projected
    end
    return nil
end

local function get_bounds_2d(character, data)
    local parts = refresh_viewmodel_parts(character, data)
    local torso = parts.torso
    if not torso or not torso:IsA("BasePart") then
        return nil
    end

    local center2d = project_world_point(torso.Position)
    if not center2d then
        return nil
    end

    local minY = nil
    local maxY = nil
    local minX = nil
    local maxX = nil

    local function push_height_point(worldPoint)
        local screenPos = project_world_point(worldPoint)
        if screenPos then
            if not minY or screenPos.Y < minY then
                minY = screenPos.Y
            end
            if not maxY or screenPos.Y > maxY then
                maxY = screenPos.Y
            end
            return true
        end
        return false
    end

    local function push_width_point(worldPoint)
        local screenPos = project_world_point(worldPoint)
        if screenPos then
            if not minX or screenPos.X < minX then
                minX = screenPos.X
            end
            if not maxX or screenPos.X > maxX then
                maxX = screenPos.X
            end
            return true
        end
        return false
    end

    local torsoUp = torso.CFrame.UpVector
    local torsoRight = torso.CFrame.RightVector

    push_height_point(torso.Position + (torsoUp * (torso.Size.Y * 0.6)))
    push_height_point(torso.Position - (torsoUp * (torso.Size.Y * 0.6)))

    local head = parts.head
    if head and head:IsA("BasePart") then
        push_height_point(head.Position + (head.CFrame.UpVector * (head.Size.Y * 0.6)))
    end

    local leg1 = parts.leg1
    if leg1 and leg1:IsA("BasePart") then
        push_height_point(leg1.Position - (leg1.CFrame.UpVector * (leg1.Size.Y * 0.6)))
    end

    local leg2 = parts.leg2
    if leg2 and leg2:IsA("BasePart") then
        push_height_point(leg2.Position - (leg2.CFrame.UpVector * (leg2.Size.Y * 0.6)))
    end

    local hip1 = parts.hip1
    if hip1 and hip1:IsA("BasePart") then
        push_height_point(hip1.Position - (hip1.CFrame.UpVector * (hip1.Size.Y * 0.6)))
    end

    local hip2 = parts.hip2
    if hip2 and hip2:IsA("BasePart") then
        push_height_point(hip2.Position - (hip2.CFrame.UpVector * (hip2.Size.Y * 0.6)))
    end

    if not minY or not maxY then
        return nil
    end

    local height = maxY - minY
    if height <= 1 then
        return nil
    end

    local torsoHalfWidth = math.max(torso.Size.X * 0.8, 0.35)
    push_width_point(torso.Position + (torsoRight * torsoHalfWidth))
    push_width_point(torso.Position - (torsoRight * torsoHalfWidth))

    local shoulder1 = parts.shoulder1
    if shoulder1 and shoulder1:IsA("BasePart") then
        push_width_point(shoulder1.Position)
    end

    local shoulder2 = parts.shoulder2
    if shoulder2 and shoulder2:IsA("BasePart") then
        push_width_point(shoulder2.Position)
    end

    if hip1 and hip1:IsA("BasePart") then
        push_width_point(hip1.Position)
    end
    if hip2 and hip2:IsA("BasePart") then
        push_width_point(hip2.Position)
    end

    if not minX or not maxX then
        local fallbackHalfWidth = math.max(height * 0.22, 2)
        minX = center2d.X - fallbackHalfWidth
        maxX = center2d.X + fallbackHalfWidth
    end

    local rawWidth = maxX - minX
    local minAllowedWidth = math.max(height * 0.2, 2)
    local maxAllowedWidth = math.max(height * 0.62, 4)
    local clampedWidth = math.clamp(rawWidth, minAllowedWidth, maxAllowedWidth)
    local centerX = (minX + maxX) * 0.5

    minX = centerX - (clampedWidth * 0.5)
    maxX = centerX + (clampedWidth * 0.5)

    local yPadding = math.clamp(height * 0.04, 1, 6)
    minY = minY - yPadding
    maxY = maxY + yPadding

    return minX, minY, maxX, maxY
end

local function get_distance_alpha(distance)
    if not settings.fade_on_distance or settings.max_distance <= 0 then
        return 1
    end
    return math.clamp(1 - (distance / settings.max_distance), 0.1, 1)
end

local function get_animated_lerp_value()
    if not settings.box_animate then
        return 0
    end
    local speed = math.max(settings.box_rotation_speed, 1) / 60
    return (math.sin(tick() * speed) + 1) / 2
end

local function get_character_anchor_position(character)
    if not character then
        return nil
    end

    local anchor = character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("head")
        or character:FindFirstChild("torso")

    if anchor and anchor:IsA("BasePart") then
        return anchor.Position
    end

    return nil
end

local function update_health_candidates()
    if not players then
        healthCandidatesCache = {}
        return
    end

    local localPlayer = players.LocalPlayer
    local candidates = {}

    for _, plr in ipairs(players:GetPlayers()) do
        if plr ~= localPlayer then
            local char = plr.Character
            local anchorPos = get_character_anchor_position(char)
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if anchorPos and hum and hum.MaxHealth > 0 then
                table.insert(candidates, {
                    player = plr,
                    anchor_pos = anchorPos,
                    humanoid = hum,
                })
            end
        end
    end

    healthCandidatesCache = candidates
end

local function get_mapped_humanoid(character, data)
    if not players then
        return nil
    end

    local vmTorso = character:FindFirstChild("torso")
    if not vmTorso or not vmTorso:IsA("BasePart") then
        return nil
    end

    local maxMatchDistance = math.max(settings.health_map_match_distance or 0, 0)

    if data.mapped_player and data.mapped_humanoid and data.mapped_humanoid.Parent and data.mapped_humanoid.MaxHealth > 0 then
        local cachedPos = get_character_anchor_position(data.mapped_player.Character)
        if cachedPos then
            local cachedDistance = (cachedPos - vmTorso.Position).Magnitude
            if maxMatchDistance <= 0 or cachedDistance <= (maxMatchDistance + 10) then
                return data.mapped_humanoid
            end
        end
    end

    local now = tick()
    if now - (data.last_health_map_scan or 0) < 0.35 then
        if data.mapped_humanoid and data.mapped_humanoid.Parent and data.mapped_humanoid.MaxHealth > 0 then
            return data.mapped_humanoid
        end
        return nil
    end
    data.last_health_map_scan = now

    if now - lastHealthCandidatesUpdate > HEALTH_CANDIDATES_UPDATE_INTERVAL then
        update_health_candidates()
        lastHealthCandidatesUpdate = now
    end

    local closestDistance = math.huge
    local closestPlayer = nil
    local closestHumanoid = nil
    local localPlayer = players.LocalPlayer

    for _, candidate in ipairs(healthCandidatesCache) do
        local plr = candidate.player
        local isTeammate = false
        if settings.team_check and localPlayer and plr then
            if localPlayer.Team and plr.Team then
                isTeammate = (plr.Team == localPlayer.Team)
            elseif localPlayer.TeamColor and plr.TeamColor then
                isTeammate = (plr.TeamColor == localPlayer.TeamColor)
            end
        end

        if not isTeammate then
            local d = (candidate.anchor_pos - vmTorso.Position).Magnitude
            if d < closestDistance then
                closestDistance = d
                closestPlayer = plr
                closestHumanoid = candidate.humanoid
            end
        end
    end

    if closestHumanoid and (maxMatchDistance <= 0 or closestDistance <= maxMatchDistance) then
        data.mapped_player = closestPlayer
        data.mapped_humanoid = closestHumanoid
        data.last_health_map_valid = now
        return closestHumanoid
    end

    if data.mapped_humanoid and data.mapped_humanoid.Parent and data.mapped_humanoid.MaxHealth > 0 then
        if now - (data.last_health_map_valid or 0) <= 1.0 then
            return data.mapped_humanoid
        end
    end

    data.mapped_player = nil
    data.mapped_humanoid = nil
    return nil
end

local function get_health_values(character, data)
    if data.humanoid and data.humanoid.Parent and data.humanoid.MaxHealth > 0 then
        return data.humanoid.Health, data.humanoid.MaxHealth
    end

    data.humanoid = character:FindFirstChildOfClass("Humanoid")
    if data.humanoid and data.humanoid.MaxHealth > 0 then
        return data.humanoid.Health, data.humanoid.MaxHealth
    end

    local mappedHumanoid = get_mapped_humanoid(character, data)
    if mappedHumanoid and mappedHumanoid.Parent and mappedHumanoid.MaxHealth > 0 then
        return mappedHumanoid.Health, mappedHumanoid.MaxHealth
    end

    local hp = character:GetAttribute("Health")
        or character:GetAttribute("health")
        or character:GetAttribute("HP")
        or character:GetAttribute("hp")
    local max_hp = character:GetAttribute("MaxHealth")
        or character:GetAttribute("maxHealth")
        or character:GetAttribute("max_health")
        or character:GetAttribute("maxhp")
        or character:GetAttribute("MaxHP")

    if type(hp) == "number" and type(max_hp) == "number" and max_hp > 0 then
        return hp, max_hp
    end

    if (not data.health_value or not data.health_value.Parent or not data.max_health_value or not data.max_health_value.Parent) then
        local now = tick()
        if now - (data.last_health_scan or 0) > 1 then
            data.last_health_scan = now
            data.health_value = nil
            data.max_health_value = nil
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("NumberValue") then
                    local n = string.lower(obj.Name)
                    if (n == "health" or n == "hp") and not data.health_value then
                        data.health_value = obj
                    elseif (n == "maxhealth" or n == "max_hp" or n == "maxhp") and not data.max_health_value then
                        data.max_health_value = obj
                    end
                end
                if data.health_value and data.max_health_value then
                    break
                end
            end
        end
    end

    if data.health_value and data.max_health_value and data.max_health_value.Value > 0 then
        return data.health_value.Value, data.max_health_value.Value
    end

    return nil, nil
end

local function hide_esp_objects(data, hide_chams)
    if not data then
        return
    end

    if hide_chams == nil then
        hide_chams = true
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

    if hide_chams and data.chams then
        data.chams.Enabled = false
    end
end

local function cleanup_esp_entry(character, data)
    if not data then
        return
    end

    if data.render_connection then
        data.render_connection:Disconnect()
        data.render_connection = nil
    end

    if data.ancestry_connection then
        data.ancestry_connection:Disconnect()
        data.ancestry_connection = nil
    end

    remove_drawing(data.health_bar_inner)
    remove_drawing(data.health_bar_outer)
    remove_drawing(data.name_text)
    remove_drawing(data.distance_text)
    remove_drawing(data.weapon_text)
    remove_drawing(data.box_outline)
    remove_drawing(data.box_fill)

    for _, line in ipairs(data.corner_lines or {}) do
        remove_drawing(line)
    end

    for _, line in ipairs(data.skeleton_lines or {}) do
        remove_drawing(line)
    end

    destroy_instance(data.chams)
    has_esp[character] = nil
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

    local data = {
        self = character,
        humanoid = character:FindFirstChildOfClass("Humanoid"),
        health_value = nil,
        max_health_value = nil,
        last_health_scan = 0,
        cached_parts = {},
        last_part_refresh = 0,
        cached_weapon_name = nil,
        last_weapon_scan = 0,
        render_connection = nil,
        ancestry_connection = nil,
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
    data.name_text.Size = settings.font_size
    data.name_text.Font = 2
    data.name_text.ZIndex = 7

    data.distance_text = Drawing.new("Text")
    data.distance_text.Visible = false
    data.distance_text.Center = true
    data.distance_text.Outline = true
    data.distance_text.Size = settings.font_size
    data.distance_text.Font = 2
    data.distance_text.ZIndex = 7

    data.weapon_text = Drawing.new("Text")
    data.weapon_text.Visible = false
    data.weapon_text.Center = true
    data.weapon_text.Outline = true
    data.weapon_text.Size = settings.font_size
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
    data.chams.Name = "op1_esp_chams"
    data.chams:SetAttribute(ESP_CHAMS_TAG, true)
    data.chams.Enabled = false
    data.chams.Adornee = character
    data.chams.Parent = workspace

    data.render_connection = run_service.RenderStepped:Connect(function()
        local liveCamera = workspace.CurrentCamera
        if liveCamera and camera ~= liveCamera then
            camera = cloneref(liveCamera)
        end

        local parts = refresh_viewmodel_parts(character, data)
        local localTorso = parts.torso
        if not localTorso or not localTorso.Parent then
            parts = refresh_viewmodel_parts(character, data, true)
            localTorso = parts.torso
        end
        if not localTorso or not localTorso:IsA("BasePart") or localTorso.Transparency >= 1 then
            hide_esp_objects(data)
            return
        end

        if settings.team_check and hasTeamHighlight(character) then
            hide_esp_objects(data)
            return
        end

        local distance = (camera.CFrame.Position - localTorso.Position).Magnitude / 3.5714285714
        local chams_in_distance = (settings.chams_max_distance <= 0) or (distance <= settings.chams_max_distance)

        if settings.chams and chams_in_distance then
            data.chams.Enabled = true
            data.chams.Adornee = character
            data.chams.FillColor = settings.chams_fill_color
            data.chams.OutlineColor = settings.chams_outline_color

            local baseFill = math.clamp(settings.chams_fill_transparency, 0, 1)
            local baseOutline = math.clamp(settings.chams_outline_transparency, 0, 1)

            if settings.chams_thermal then
                local breathe = (math.atan(math.sin(tick() * 2)) * 2 / math.pi)
                data.chams.FillTransparency = math.clamp(baseFill * (1 - (breathe * 0.1)), 0, 1)
            else
                data.chams.FillTransparency = baseFill
            end

            data.chams.OutlineTransparency = baseOutline
            data.chams.DepthMode = settings.chams_visible_check and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
        else
            data.chams.Enabled = false
        end

        if settings.max_distance > 0 and distance > settings.max_distance then
            hide_esp_objects(data, false)
            return
        end

        local point, on = to_view_point(localTorso.Position)
        if not on then
            hide_esp_objects(data, false)
            return
        end

        for _, callback in next, esp_ran do
            pcall(callback, data, point)
        end

        local minX, minY, maxX, maxY = get_bounds_2d(character, data)
        if not minX then
            hide_esp_objects(data, false)
            return
        end

        local width = maxX - minX
        local height = maxY - minY
        if width <= 1 or height <= 1 then
            hide_esp_objects(data, false)
            return
        end

        local alpha = get_distance_alpha(distance)
        local gradientLerp = get_animated_lerp_value()
        local boxColor = settings.box_color
        local fillColor = settings.box_fill_color

        if settings.box_gradient then
            boxColor = settings.box_gradient_color_1:Lerp(settings.box_gradient_color_2, gradientLerp)
        end

        if settings.box_gradient_fill then
            fillColor = settings.box_gradient_fill_color_1:Lerp(settings.box_gradient_fill_color_2, gradientLerp)
        end

        local nameText = character.Name
        local showDistanceAsText = true
        if type(settings.distance_position) == "string" then
            local mode = string.lower(settings.distance_position)
            showDistanceAsText = mode ~= "name"
        end

        if settings.distance and not showDistanceAsText then
            nameText = string.format("%s [%d]", nameText, math.floor(distance))
        end

        data.name_text.Visible = settings.names
        if settings.names then
            data.name_text.Color = settings.name_color
            data.name_text.Transparency = alpha
            data.name_text.Size = settings.font_size
            data.name_text.Text = nameText
            data.name_text.Position = Vector2.new(minX + (width / 2), minY - 14)
        end

        data.distance_text.Visible = settings.distance and showDistanceAsText
        if settings.distance and showDistanceAsText then
            data.distance_text.Color = settings.distance_color
            data.distance_text.Transparency = alpha
            data.distance_text.Size = settings.font_size
            data.distance_text.Text = string.format("[%d]", math.floor(distance))
            data.distance_text.Position = Vector2.new(minX + (width / 2), minY - 1)
        end

        data.weapon_text.Visible = settings.weapon
        if settings.weapon then
            local weaponName = find_weapon_name(character, data)
            if weaponName then
                data.weapon_text.Color = settings.weapon_color
                data.weapon_text.Transparency = alpha
                data.weapon_text.Size = settings.font_size
                data.weapon_text.Text = weaponName
                data.weapon_text.Position = Vector2.new(minX + (width / 2), maxY + 2)
            else
                data.weapon_text.Visible = false
            end
        end

        data.box_outline.Visible = settings.box
        if settings.box then
            data.box_outline.Color = boxColor
            data.box_outline.Transparency = alpha
            data.box_outline.Size = Vector2.new(width, height)
            data.box_outline.Position = Vector2.new(minX, minY)
        end

        data.box_fill.Visible = settings.box_filled
        if settings.box_filled then
            data.box_fill.Color = fillColor
            data.box_fill.Transparency = math.clamp(settings.box_fill_transparency, 0, 1) * alpha
            data.box_fill.Size = Vector2.new(width, height)
            data.box_fill.Position = Vector2.new(minX, minY)
        end

        if settings.box_corner then
            local cornerColor = settings.box_corner_color
            if settings.box_gradient then
                cornerColor = boxColor
            end

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
                line.Transparency = alpha
            end
        else
            set_visible(data.corner_lines, false)
        end

        if settings.health_bar then
            local hp, max_hp = get_health_values(character, data)
            if hp and max_hp and max_hp > 0 then
                local hpRatio = math.clamp(hp / max_hp, 0, 1)
                if settings.fade_on_death and hpRatio <= 0 then
                    data.health_bar_outer.Visible = false
                    data.health_bar_inner.Visible = false
                else
                    local barWidth = 3
                    local barHeight = height
                    local barX = minX - 6
                    local barY = minY

                    data.health_bar_outer.Visible = true
                    data.health_bar_outer.Transparency = alpha
                    data.health_bar_outer.Size = Vector2.new(barWidth, barHeight)
                    data.health_bar_outer.Position = Vector2.new(barX, barY)

                    data.health_bar_inner.Visible = true
                    data.health_bar_inner.Transparency = alpha
                    data.health_bar_inner.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), hpRatio)
                    data.health_bar_inner.Size = Vector2.new(barWidth - 1, (barHeight - 2) * hpRatio)
                    data.health_bar_inner.Position = Vector2.new(barX + 0.5, barY + (barHeight - 1) - ((barHeight - 2) * hpRatio))
                end
            else
                data.health_bar_outer.Visible = false
                data.health_bar_inner.Visible = false
            end
        else
            data.health_bar_outer.Visible = false
            data.health_bar_inner.Visible = false
        end

        if settings.skelton then
            for i, pair in ipairs(bone_connections) do
                local p1 = parts[pair[1]]
                local p2 = parts[pair[2]]
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
                        line.Transparency = alpha
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

    end)

    data.ancestry_connection = character.AncestryChanged:Connect(function(_, parent)
        if parent ~= nil then
            return
        end

        if settings.fade_on_leave then
            for i = 5, 0, -1 do
                local alpha = i / 5
                data.name_text.Transparency = alpha
                data.distance_text.Transparency = alpha
                data.weapon_text.Transparency = alpha
                data.box_outline.Transparency = alpha
                data.box_fill.Transparency = alpha
                set_transparency(data.corner_lines, alpha)
                set_transparency(data.skeleton_lines, alpha)
                task.wait(0.02)
            end
        end

        cleanup_esp_entry(character, data)
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

local function cleanup_object_esp()
    for obj, state in pairs(object_esp) do
        if state then
            if state.conn then
                state.conn:Disconnect()
            end
            remove_drawing(state.box)
        end
        object_esp[obj] = nil
    end
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

rawset(player_esp, "refresh_esps", newcclosure(function()
    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not viewmodels then
        return
    end

    for character, data in pairs(has_esp) do
        cleanup_esp_entry(character, data)
    end

    for _, vm in ipairs(viewmodels:GetChildren()) do
        if should_track_viewmodel(vm) then
            player_esp.set_player_esp(vm)
        end
    end
end))

rawset(player_esp, "clean_all_esps", newcclosure(function()
    for character, data in pairs(has_esp) do
        cleanup_esp_entry(character, data)
    end
    cleanup_object_esp()
end))

rawset(player_esp, "toggle_skeleton", newcclosure(function(enabled)
    settings.skelton = enabled and true or false
    if not settings.skelton then
        for _, data in pairs(has_esp) do
            set_visible(data.skeleton_lines, false)
        end
    end
end))

rawset(player_esp, "set_skeleton_color", newcclosure(function(color)
    if typeof(color) ~= "Color3" then
        return
    end
    settings.skelton_color = color
end))

rawset(player_esp, "set_skeleton_thickness", newcclosure(function(thickness)
    if type(thickness) ~= "number" or thickness <= 0 then
        return
    end
    settings.skelton_thickness = thickness
end))

rawset(player_esp, "set_corner_color", newcclosure(function(color)
    if typeof(color) ~= "Color3" then
        return
    end
    settings.box_corner_color = color
end))

rawset(player_esp, "set_corner_thickness", newcclosure(function(thickness)
    if type(thickness) ~= "number" or thickness <= 0 then
        return
    end
    settings.box_corner_thickness = thickness
end))

rawset(player_esp, "set_corner_length", newcclosure(function(length)
    if type(length) ~= "number" or length <= 0 then
        return
    end
    settings.box_corner_length = length
end))

rawset(player_esp, "RefreshESPs", rawget(player_esp, "refresh_esps"))
rawset(player_esp, "CleanAllESPs", rawget(player_esp, "clean_all_esps"))
rawset(player_esp, "ToggleSkeleton", rawget(player_esp, "toggle_skeleton"))
rawset(player_esp, "SetSkeletonColor", rawget(player_esp, "set_skeleton_color"))
rawset(player_esp, "SetSkeletonThickness", rawget(player_esp, "set_skeleton_thickness"))
rawset(player_esp, "SetCornerColor", rawget(player_esp, "set_corner_color"))
rawset(player_esp, "SetCornerThickness", rawget(player_esp, "set_corner_thickness"))
rawset(player_esp, "SetCornerLength", rawget(player_esp, "set_corner_length"))

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

    if viewmodels_added_connection then
        viewmodels_added_connection:Disconnect()
    end

    viewmodels_added_connection = viewmodels.ChildAdded:Connect(function(vm)
        if should_track_viewmodel(vm) then
            player_esp.set_player_esp(vm)
        end
    end)

    track_objects()
end

return player_esp







