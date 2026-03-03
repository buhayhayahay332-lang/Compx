local fullbright = {}
local lighting = game:GetService("Lighting")

local settings = {
    enabled = false,
    brightness = 1,
    clock_time = 12,
    fog_end = 786543,
    global_shadows = false,
    ambient = Color3.fromRGB(178, 178, 178)
}

local normal_lighting = {}
local initialized = false

local function snapshot_normal_lighting()
    normal_lighting.Brightness = lighting.Brightness
    normal_lighting.ClockTime = lighting.ClockTime
    normal_lighting.FogEnd = lighting.FogEnd
    normal_lighting.GlobalShadows = lighting.GlobalShadows
    normal_lighting.Ambient = lighting.Ambient
end

local function apply_normal_lighting()
    if next(normal_lighting) == nil then
        snapshot_normal_lighting()
    end

    lighting.Brightness = normal_lighting.Brightness
    lighting.ClockTime = normal_lighting.ClockTime
    lighting.FogEnd = normal_lighting.FogEnd
    lighting.GlobalShadows = normal_lighting.GlobalShadows
    lighting.Ambient = normal_lighting.Ambient
end

local function apply_fullbright_lighting()
    lighting.Brightness = settings.brightness
    lighting.ClockTime = settings.clock_time
    lighting.FogEnd = settings.fog_end
    lighting.GlobalShadows = settings.global_shadows
    lighting.Ambient = settings.ambient
end

local function refresh_state()
    if settings.enabled then
        apply_fullbright_lighting()
    else
        apply_normal_lighting()
    end
end

local function setup_property_monitors()
    local function monitor(property_name, target_getter)
        lighting:GetPropertyChangedSignal(property_name):Connect(function()
            if settings.enabled then
                local expected = target_getter()
                if lighting[property_name] ~= expected then
                    lighting[property_name] = expected
                end
            else
                normal_lighting[property_name] = lighting[property_name]
            end
        end)
    end

    monitor("Brightness", function() return settings.brightness end)
    monitor("ClockTime", function() return settings.clock_time end)
    monitor("FogEnd", function() return settings.fog_end end)
    monitor("GlobalShadows", function() return settings.global_shadows end)
    monitor("Ambient", function() return settings.ambient end)
end

rawset(fullbright, "fullbright_settings", settings)

rawset(fullbright, "set_fullbright", newcclosure(function(value)
    if type(value) == "boolean" then
        settings.enabled = value
    else
        settings.enabled = not settings.enabled
    end

    refresh_state()
end))

rawset(fullbright, "refresh_fullbright", newcclosure(function()
    if settings.enabled then
        apply_fullbright_lighting()
    end
end))

fullbright.init = function()
    if initialized then
        return
    end

    snapshot_normal_lighting()
    setup_property_monitors()
    refresh_state()
    initialized = true
end

return fullbright
