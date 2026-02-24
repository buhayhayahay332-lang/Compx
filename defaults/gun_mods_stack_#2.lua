pcall(function() setthreadidentity(8) end)
pcall(function() game:GetService("WebViewService"):Destroy() end)

run_on_actor(getactors()[1], [[
    
pcall(function() setthreadidentity(8) end)

    local CONFIG = {
    recoil_reduction = 0, --WORKING
    horizontal_recoil = 0, --WORKING
    no_spread = true, --WORKING
    firerate_bypass = true, --WORKING
    firerate_step = 0.010, -- increase for faster, decrease for slower
    reload_speed = 0.7, --WORKING
    force_auto = true, --WORKING
    instant_ads = true
}

local clonefunc = clonefunc or clonefunction
local old_tweenInfo_new = clonefunc(TweenInfo.new)
local old_os_clock = clonefunc(os.clock)
local old_math_random = clonefunc(math.random)
local old_math_exp = clonefunc(math.exp)
local fire_clock_boost = 0
local unpack_fn = table.unpack or unpack

hookfunction(TweenInfo.new, newcclosure(function(...)
    local caller3 = debug.info(3, "n")
    local caller4 = debug.info(4, "n")

    -- no recoil (same direct pattern that works)
    if caller3 == "recoil_function" then
        debug.setstack(3, 5, debug.getstack(3, 5) * CONFIG.recoil_reduction)
        debug.setstack(3, 6, debug.getstack(3, 6) * CONFIG.recoil_reduction + CONFIG.horizontal_recoil)
    end

    -- instant ads
    if caller3 == "update_sight_lens" or caller3 == "sights" then
        debug.setstack(3, 3, CONFIG.instant_ads and 0.001 or debug.getstack(3, 3))
    end
    if caller4 == "update_sight_lens" or caller4 == "sights" then
        local v = debug.getstack(4, 3)
        if type(v) == "number" then
            debug.setstack(4, 3, CONFIG.instant_ads and 0.001 or v)
        end
    end
    if CONFIG.instant_ads and (caller3 == "update_sight_lens" or caller3 == "sights" or caller4 == "update_sight_lens" or caller4 == "sights") then
        local args = { ... }
        if type(args[1]) == "number" then
            args[1] = 0.3
        end
        return old_tweenInfo_new(unpack_fn(args))
    end

    -- reload speed
    if caller3 == "reload_begin" then
        local v = debug.getstack(3, 6)
        if type(v) == "number" then
            debug.setstack(3, 6, CONFIG.reload_speed)
        end
    end
    if caller4 == "reload_begin" then
        local v = debug.getstack(4, 6)
        if type(v) == "number" then
            debug.setstack(4, 6, CONFIG.reload_speed)
        end
    end

    return old_tweenInfo_new(...)
end))

hookfunction(math.exp, newcclosure(function(x)
    if debug.info(3, "n") == "recoil_function" then
        return old_math_exp(x * CONFIG.recoil_reduction)
    end
    return old_math_exp(x)
end))

hookfunction(os.clock, newcclosure(function()
    if CONFIG.firerate_bypass then
        if debug.info(3, "n") == "input_render" or debug.info(3, "n") == "input_shoot" then
            fire_clock_boost = fire_clock_boost + CONFIG.firerate_step
            return old_os_clock() + fire_clock_boost
        end
        if debug.info(4, "n") == "input_render" or debug.info(4, "n") == "input_shoot" then
            fire_clock_boost = fire_clock_boost + CONFIG.firerate_step
            return old_os_clock() + fire_clock_boost
        end
    end
    return old_os_clock()
end))

hookfunction(math.random, newcclosure(function(...)
    if debug.info(2, "n") == "get_circular_spread" then
        if CONFIG.no_spread then
            debug.setstack(2, 2, 0)
        end

        return 0
    end

    if debug.info(3, "n") == "get_circular_spread" then
        local v = debug.getstack(3, 2)
        if CONFIG.no_spread and type(v) == "number" then
            debug.setstack(3, 2, 0)
        end

        return 0
    end

    return old_math_random(...)
end))

if CONFIG.force_auto then
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local GunModule = require(ReplicatedStorage.Modules.Items.Item.Gun)
    rawset(GunModule, "automatic", true)
end

print("[GunMod] STACK DIRECT loaded")

]])