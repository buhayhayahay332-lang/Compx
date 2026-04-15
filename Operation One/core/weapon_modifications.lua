-- ─────────────────────────────────────────────
-- CONFIG
-- ─────────────────────────────────────────────
local weapon_modifications = {}
local initialized = false

local CONFIG = {
    recoil_reduction = 0,
    horizontal_recoil = 0,
    no_spread = true,
    accuracy_multiplier = 1,
    custom_firerate = 1200,
    reload_speed = 0.1,
    force_auto = true,
    instant_ads = true,
    custom_zoom = 1.5,
}

local UI_SETTINGS = {
    recoil_x = CONFIG.recoil_reduction,
    recoil_y = CONFIG.horizontal_recoil,
    no_spread = CONFIG.no_spread,
    fast_reload = CONFIG.reload_speed < 1,
    reload_speed = CONFIG.reload_speed,
    firerate_bypass = CONFIG.custom_firerate ~= 0,
    firerate_step = 0.01,
    force_auto = CONFIG.force_auto,
    instant_ads = CONFIG.instant_ads,
    instant_ads_speed = 0.30,
    custom_zoom = CONFIG.custom_zoom,
}

local weapon_modifications_settings = setmetatable({}, {
    __index = function(_, key)
        return UI_SETTINGS[key]
    end,
    __newindex = function(_, key, value)
        UI_SETTINGS[key] = value

        if key == "recoil_x" then
            CONFIG.recoil_reduction = value
        elseif key == "recoil_y" then
            CONFIG.horizontal_recoil = value
        elseif key == "no_spread" then
            CONFIG.no_spread = value
        elseif key == "fast_reload" then
            -- gate handled in reload_speed_get
        elseif key == "reload_speed" then
            -- value stored in UI_SETTINGS; gate handled in reload_speed_get
        elseif key == "firerate_bypass" then
            -- gate handled in firerate_get
        elseif key == "firerate_step" then
            -- value stored in UI_SETTINGS; gate handled in firerate_get
        elseif key == "force_auto" then
            CONFIG.force_auto = value
        elseif key == "instant_ads" then
            CONFIG.instant_ads = value
        elseif key == "instant_ads_speed" then
            -- value stored in UI_SETTINGS; gate handled in ads_get
        elseif key == "custom_zoom" then
            CONFIG.custom_zoom = value
        else
            CONFIG[key] = value
        end
    end,
})

-- CLONE CORE FUNCTIONS (localized once)
local cloneref = cloneref
local clonefunction = clonefunction
local newcclosure = newcclosure
local pcall = clonefunction(pcall)
local setmetatable = clonefunction(setmetatable)
local typeof = clonefunction(typeof)
local rawget = clonefunction(rawget)
local rawset = clonefunction(rawset)

-- SERVICES (cloned references)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local Workspace         = cloneref(game:GetService("Workspace"))

-- MODULE
local GunModule = require(ReplicatedStorage.Modules.Items.Item.Gun)

-- CLONE ORIGINAL FUNCTIONS
local original_recoil_function = clonefunction(GunModule.recoil_function)
local original_send_shoot       = clonefunction(GunModule.send_shoot)
local original_input_render     = clonefunction(GunModule.input_render)
local original_reload_begin     = clonefunction(GunModule.reload_begin)
local original_sights           = clonefunction(GunModule.sights)
local original_update_sight_lens = clonefunction(GunModule.update_sight_lens)

-- ─────────────────────────────────────────────
-- PRE-CREATE ALL CACHED FUNCTIONS (ONCE!)
-- ─────────────────────────────────────────────

-- Recoil get functions (cached, wrapped)
local recoil_up_get = newcclosure(function(original_state)
    local val = original_state:get()
    return (typeof(val) == "number" and val * CONFIG.recoil_reduction) or 0
end)

local recoil_side_get = newcclosure(function()
    return CONFIG.horizontal_recoil
end)

-- Spread/firerate get functions (cached, wrapped)
local spread_get = newcclosure(function()
    return CONFIG.no_spread and 0 or 1
end)

local firerate_get = newcclosure(function()
    if not UI_SETTINGS.firerate_bypass then
        return 0
    end

    local step = tonumber(UI_SETTINGS.firerate_step) or 0.01
    if step <= 0 then
        step = 0.01
    end

    return math.max(1, math.floor(1 / step))
end)

-- Reload speed get function (cached, wrapped)
local reload_speed_get = newcclosure(function()
    if not UI_SETTINGS.fast_reload then
        return 1
    end

    return tonumber(UI_SETTINGS.reload_speed) or CONFIG.reload_speed
end)

-- ADS/Zoom get functions (cached, wrapped)
local ads_get = newcclosure(function()
    if not UI_SETTINGS.instant_ads then
        return 0.3
    end

    return math.max(tonumber(UI_SETTINGS.instant_ads_speed) or 0.30, 0.001)
end)

local zoom_get = newcclosure(function()
    return CONFIG.custom_zoom
end)

rawset(weapon_modifications, "weapon_modifications_settings", weapon_modifications_settings)

-- Pre-create accuracy table (reuse)
local perfect_accuracy = { Value = CONFIG.accuracy_multiplier }

-- ─────────────────────────────────────────────
-- OPTIMIZED METATABLES (CACHED RETURNS)
-- ─────────────────────────────────────────────

local recoil_proxy_mt = {
    __index = newcclosure(function(t, key)
        local real_states = rawget(t, "__real_states")
        if not real_states then return nil end
        
        local state = real_states[key]
        if typeof(state) == "table" and state.get then
            if key == "recoil_up" then
                return { get = newcclosure(function()
                    return recoil_up_get(state)
                end) }
            elseif key == "recoil_side" then
                return { get = recoil_side_get }
            end
        end
        return state
    end),
    __metatable = "locked"
}

local spread_firerate_proxy_mt = {
    __index = newcclosure(function(t, key)
        local real_states = rawget(t, "__real_states")
        if not real_states then return nil end
        
        local state = real_states[key]
        if typeof(state) == "table" and state.get then
            if key == "spread" then
                return { get = spread_get }
            elseif key == "firerate" then
                return { get = firerate_get }
            end
        end
        return state
    end),
    __metatable = "locked"
}

local firerate_proxy_mt = {
    __index = newcclosure(function(t, key)
        local real_states = rawget(t, "__real_states")
        if not real_states then return nil end
        
        local state = real_states[key]
        if typeof(state) == "table" and state.get and key == "firerate" then
            return { get = firerate_get }
        end
        return state
    end),
    __metatable = "locked"
}

local reload_proxy_mt = {
    __index = newcclosure(function(t, key)
        local real_states = rawget(t, "__real_states")
        if not real_states then return nil end
        
        local state = real_states[key]
        if typeof(state) == "table" and state.get and key == "reload_speed" then
            return { get = reload_speed_get }
        end
        return state
    end),
    __metatable = "locked"
}

local sights_proxy_mt = {
    __index = newcclosure(function(t, key)
        local real_states = rawget(t, "__real_states")
        if not real_states then return nil end
        
        local state = real_states[key]
        if typeof(state) == "table" and state.get then
            if key == "ads" then
                return { get = ads_get }
            elseif key == "zoom" then
                return { get = zoom_get }
            end
        end
        return state
    end),
    __metatable = "locked"
}

-- ─────────────────────────────────────────────
-- HOOK IMPLEMENTATIONS
-- ─────────────────────────────────────────────

local recoil_impl = newcclosure(function(self, owner)
    if not self or not self.states then 
        return original_recoil_function(self, owner)
    end
    
    local real_states = self.states
    local proxy_states = { __real_states = real_states }
    setmetatable(proxy_states, recoil_proxy_mt)
    
    self.states = proxy_states
    local success, err = pcall(original_recoil_function, self, owner)
    self.states = real_states
    
    if not success then
        warn("Recoil error:", err)
    end
end)

local send_shoot_impl = newcclosure(function(self)
    if not self or not self.states then
        return original_send_shoot(self)
    end
    
    local real_states = self.states
    local real_accuracy = self.accuracy
    
    local proxy_states = { __real_states = real_states }
    setmetatable(proxy_states, spread_firerate_proxy_mt)
    
    self.states = proxy_states
    self.accuracy = perfect_accuracy
    
    local success, err = pcall(original_send_shoot, self)
    
    self.states = real_states
    self.accuracy = real_accuracy
    
    if not success then
        warn("Shoot error:", err)
    end
end)

local input_render_impl = newcclosure(function(self, ...)
    if not self or not self.states then
        return original_input_render(self, ...)
    end
    
    local real_states = self.states
    local proxy_states = { __real_states = real_states }
    setmetatable(proxy_states, firerate_proxy_mt)
    
    self.states = proxy_states
    original_input_render(self, ...)
    self.states = real_states
end)

local reload_begin_impl = newcclosure(function(self, ...)
    if not self or not self.states then
        return original_reload_begin(self, ...)
    end
    
    local real_states = self.states
    local proxy_states = { __real_states = real_states }
    setmetatable(proxy_states, reload_proxy_mt)
    
    self.states = proxy_states
    local success, err = pcall(original_reload_begin, self, ...)
    self.states = real_states
    
    if not success then
        warn("Reload error:", err)
    end
end)

local sights_impl = newcclosure(function(self, ...)
    if not self or not self.states then
        return original_sights(self, ...)
    end
    
    local real_states = self.states
    local proxy_states = { __real_states = real_states }
    setmetatable(proxy_states, sights_proxy_mt)
    
    self.states = proxy_states
    original_sights(self, ...)
    self.states = real_states
end)

local update_sight_lens_impl = newcclosure(function(self, ...)
    if not self or not self.states then
        return original_update_sight_lens(self, ...)
    end
    
    local real_states = self.states
    local proxy_states = { __real_states = real_states }
    setmetatable(proxy_states, sights_proxy_mt)
    
    self.states = proxy_states
    original_update_sight_lens(self, ...)
    self.states = real_states
end)

-- ─────────────────────────────────────────────
-- APPLY HOOKS USING RAWSET
-- ─────────────────────────────────────────────

weapon_modifications.init = function()
    if initialized then
        return
    end
    initialized = true

    rawset(GunModule, "recoil_function", recoil_impl)
    rawset(GunModule, "send_shoot", send_shoot_impl)
    rawset(GunModule, "input_render", input_render_impl)
    rawset(GunModule, "reload_begin", reload_begin_impl)
    rawset(GunModule, "sights", sights_impl)
    rawset(GunModule, "update_sight_lens", update_sight_lens_impl)

    if CONFIG.force_auto then
        rawset(GunModule, "automatic", true)
    end
end

return weapon_modifications
