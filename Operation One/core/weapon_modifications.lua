--// the gun mods should go here u know the vibe transfer, keep the code structe. 
local weapon_modifications = {};
local settings = {
    recoil_x = 1,
    recoil_y = 1,
    no_spread = false,
    fast_reload = false,
    reload_speed = 0.7,
    firerate_bypass = false,
    firerate_step = 0.01,
    force_auto = false,
    instant_ads = false
};
local initialized = false

rawset(weapon_modifications, "weapon_modifications_settings", settings);

weapon_modifications.init = function()
    if initialized then
        return
    end
    initialized = true

    local old_tweenInfo_new = clonefunction(TweenInfo.new);
    local old_math_random = clonefunction(math.random);
    local old_os_clock = clonefunction(os.clock);
    local fire_clock_boost = 0
    local force_auto_applied = false

    hook_function(TweenInfo.new, newcclosure(function(...)
        local caller3 = debug.info(3, "n")
        local caller4 = debug.info(4, "n")

        if caller3 == "recoil_function" then
            local recoilX = debug.getstack(3, 5)
            local recoilY = debug.getstack(3, 6)
            if type(recoilX) == "number" then
                debug.setstack(3, 5, recoilX * settings.recoil_x)
            end
            if type(recoilY) == "number" then
                debug.setstack(3, 6, recoilY * settings.recoil_y)
            end
        elseif caller4 == "recoil_function" then
            local recoilX = debug.getstack(4, 5)
            local recoilY = debug.getstack(4, 6)
            if type(recoilX) == "number" then
                debug.setstack(4, 5, recoilX * settings.recoil_x)
            end
            if type(recoilY) == "number" then
                debug.setstack(4, 6, recoilY * settings.recoil_y)
            end
        end

        if settings.instant_ads then
            if caller3 == "update_sight_lens" or caller3 == "sights" then
                local t = debug.getstack(3, 3)
                if type(t) == "number" then
                    debug.setstack(3, 3, 0.001)
                end
            end
            if caller4 == "update_sight_lens" or caller4 == "sights" then
                local t = debug.getstack(4, 3)
                if type(t) == "number" then
                    debug.setstack(4, 3, 0.001)
                end
            end
        end

        if settings.fast_reload then
            if caller3 == "reload_begin" then
                local reloadTime = debug.getstack(3, 6)
                if type(reloadTime) == "number" then
                    debug.setstack(3, 6, math.max(settings.reload_speed, 0.001))
                end
            elseif caller4 == "reload_begin" then
                local reloadTime = debug.getstack(4, 6)
                if type(reloadTime) == "number" then
                    debug.setstack(4, 6, math.max(settings.reload_speed, 0.001))
                end
            end
        end

        return old_tweenInfo_new(...);
    end));

    hook_function(math.random, newcclosure(function(...)
        if settings.no_spread then
            if debug.info(2, "n") == "get_circular_spread" then
                local current = debug.getstack(2, 2)
                if type(current) == "number" then
                    debug.setstack(2, 2, 0)
                end
                return 0
            elseif debug.info(3, "n") == "get_circular_spread" then
                local current = debug.getstack(3, 2)
                if type(current) == "number" then
                    debug.setstack(3, 2, 0)
                end
                return 0
            end
        end

        return old_math_random(...);
    end));

    hook_function(os.clock, newcclosure(function()
        if settings.firerate_bypass then
            if debug.info(3, "n") == "input_render" or debug.info(3, "n") == "input_shoot" then
                fire_clock_boost = fire_clock_boost + settings.firerate_step
                return old_os_clock() + fire_clock_boost
            end
            if debug.info(4, "n") == "input_render" or debug.info(4, "n") == "input_shoot" then
                fire_clock_boost = fire_clock_boost + settings.firerate_step
                return old_os_clock() + fire_clock_boost
            end
        end
        return old_os_clock()
    end))

    task.spawn(function()
        while task.wait(1.5) do
            if settings.force_auto and not force_auto_applied then
                pcall(function()
                    local replicated_storage = get_service and get_service("ReplicatedStorage") or game:GetService("ReplicatedStorage")
                    local gun_module = require(replicated_storage.Modules.Items.Item.Gun)
                    rawset(gun_module, "automatic", true)
                    force_auto_applied = true
                end)
            elseif not settings.force_auto then
                force_auto_applied = false
            end
        end
    end)

end;

return weapon_modifications;
