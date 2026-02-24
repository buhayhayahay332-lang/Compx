local v1 = game:GetService("RunService")
local v_u_2 = require(script.Parent)
local v_u_3 = {}
v_u_3.__index = v_u_3
setmetatable(v_u_3, v_u_2)
v_u_3.tag = script.Name
v_u_3.holster_offset = CFrame.new(0, 0, 1) * CFrame.Angles(0, 0, 1.5707963267948966)
v_u_3.holster_part = "torso"
v_u_3.magazine_hold_offset = CFrame.new(0.2, -2.225, 0) * CFrame.Angles(-1.5707963267948966, 0, 0)
if v1:IsServer() then
    return v_u_3
end
local v_u_4 = require(game.ReplicatedStorage.Modules.Input)
local v_u_5 = require(game.ReplicatedStorage.Modules.StateObject)
local v_u_6 = require(game.ReplicatedStorage.Modules.State)
local v_u_7 = require(game.ReplicatedStorage.Modules.Event)
local v_u_8 = require(game.ReplicatedStorage.Modules.Util)
local v_u_9 = require(game.ReplicatedStorage.Modules.UI)
local v_u_10 = require(game.ReplicatedStorage.Modules.Globals)
require(game.ReplicatedStorage.Modules.Net)
local v_u_11 = require(game.ReplicatedStorage.Modules.Data)
local v_u_12 = require(game.ReplicatedStorage.Modules.Items)
local v_u_13 = require(game.ReplicatedStorage.Modules.FirstPersonInterface)
local v_u_14 = require(game.ReplicatedStorage.Modules.FlagManager)
local v_u_15 = require(game.ReplicatedStorage.Modules.Maid)
local v_u_16 = require(game.ReplicatedStorage.Modules.Effects)
game:GetService("UserInputService")
local v_u_17 = require(script.Animations)
local v_u_18 = require(script.Sounds)
v_u_3.anim = setmetatable({}, {
    ["__index"] = function(_, p19)
        return v_u_17[p19] or v_u_2.anim[p19]
    end
})
v_u_3.sound = setmetatable({}, {
    ["__index"] = function(_, p20)
        return v_u_18[p20] or v_u_2.sound[p20]
    end
})
function v_u_3.init(p21)
    p21.auto_shoot_dt = os.clock()
    p21.last_shot = os.clock()
    p21.shot = p21:setup_shot(p21.instance.Root:FindFirstChild("Shoot", true))
    p21.reload_thread = v_u_8.ov(p21.reload_begin)
    p21.reload_thread:done(p21.reload_done)
    p21.reload_thread:cancelled(p21.reload_cancel)
    p21.cock_thread = v_u_8.ov(p21.cock_begin)
    p21.cock_thread:done(p21.cock_done)
    p21.cock_thread:cancelled(p21.cock_cancel)
    p21.recoil = v_u_8.ov(p21.recoil_function)
    p21.sights = v_u_8.ov(p21.sights)
    p21.flash = v_u_8.ov(p21.flash)
    p21.safety_function = v_u_8.ov(p21.safety_function)
    p21.safety = v_u_6.new(nil)
    p21:load_instance()
end
function v_u_3.flash(p22)
    p22.shot.Flash:Emit(3)
    p22.shot.Light.Enabled = true
    task.wait(0.05)
    p22.shot.Light.Enabled = false
end
function v_u_3.set_part_pivots(p_u_23)
    p_u_23.slide = p_u_23.instance:FindFirstChild("Slide")
    if p_u_23.slide then
        local v24 = p_u_23.cframes:get(p_u_23.slide, true)
        local v_u_25 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.slide:GetPivot())
        v24:set_pivot("general", function()
            return p_u_23.instance.Root.CFrame * v_u_25
        end)
        if p_u_23.shoot_slide then
            p_u_23.cframes:get(p_u_23.slide):set_offset("shoot")
        end
    end
    p_u_23.load_slide = p_u_23.instance:FindFirstChild("LoadSlide") or p_u_23.instance:FindFirstChild("Pump")
    if p_u_23.load_slide then
        local v26 = p_u_23.cframes:get(p_u_23.load_slide, true)
        local v_u_27 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.load_slide:GetPivot())
        v26:set_pivot("general", function()
            return p_u_23.instance.Root.CFrame * v_u_27
        end)
        if p_u_23.shoot_slide then
            p_u_23.cframes:get(p_u_23.load_slide):set_offset("shoot")
        end
    end
    p_u_23.hammer = p_u_23.instance:FindFirstChild("Hammer")
    if p_u_23.hammer then
        local v28 = p_u_23.cframes:get(p_u_23.hammer, true)
        local v_u_29 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.hammer.CFrame)
        v28:set_pivot("general", function()
            return p_u_23.instance.Root.CFrame * v_u_29
        end)
    end
    p_u_23.feed_cover = p_u_23.instance:FindFirstChild("FeedCover")
    if p_u_23.feed_cover then
        local v30 = p_u_23.cframes:get(p_u_23.feed_cover, true)
        local v_u_31 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.feed_cover:GetPivot())
        v30:set_pivot("general", function()
            return p_u_23.instance.Root.CFrame * v_u_31
        end)
        v30:set_offset("reload")
    end
    p_u_23.end_bullet = p_u_23.instance:FindFirstChild("EndBullet")
    if p_u_23.end_bullet then
        local v32 = p_u_23.cframes:get(p_u_23.end_bullet, true)
        local v_u_33 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.end_bullet:GetPivot())
        v32:set_pivot("general", function()
            return p_u_23.instance.Root.CFrame * v_u_33
        end)
        v32:create_pivot("unloaded", function()
            return p_u_23.instance.Magazine.CFrame
        end)
    end
    p_u_23.cylinder = p_u_23.instance:FindFirstChild("Cylinder")
    if p_u_23.cylinder then
        local v34 = p_u_23.cframes:get(p_u_23.cylinder, true)
        local v_u_35 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.cylinder:GetPivot())
        v34:set_pivot("general", function()
            return p_u_23.instance.Root.CFrame * v_u_35
        end)
        v34:set_offset("reload")
        if p_u_23.cylinder_loader then
            p_u_23.loader = p_u_23.cylinder_loader:Clone()
            p_u_23.cframes:get(p_u_23.loader.Case):set_pivot("general", function(_)
                return p_u_23.owner.values.viewmodels.arm2.CFrame * CFrame.new(0.25, -0.75, -0.5) * CFrame.Angles(-1.5707963267948966, 0.5235987755982988, 0)
            end)
            p_u_23.cframes:get(p_u_23.loader.Case):create_pivot("reload", function(_)
                return p_u_23.instance.Cylinder:GetPivot() * CFrame.new(0, 0, 0.2)
            end)
        end
    end
    v_u_8.weld_c(p_u_23.instance.Trigger, p_u_23.instance.Root)
    p_u_23.magazine = p_u_23.instance:FindFirstChild("Magazine")
    if p_u_23.magazine then
        local v36 = p_u_23.cframes:get(p_u_23.magazine)
        local v_u_37 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.magazine:GetPivot())
        v36:set_pivot("general", function()
            return p_u_23.instance.Root.CFrame * v_u_37
        end)
        v36:create_pivot("reload", function(_)
            return p_u_23.owner.values.viewmodels.arm2:GetPivot() * p_u_23.magazine_hold_offset
        end)
    end
end
function v_u_3.update_sight_lens(p38, p39)
    local v40 = p38.states.ads:get()
    if p39 then
        v_u_8.tween(workspace.CurrentCamera, TweenInfo.new(v40, Enum.EasingStyle.Linear), {
            ["FieldOfView"] = v_u_11.settings.field_of_view / p38.states.zoom:get()
        })
        v_u_8.tween(v_u_9.get("RedDot").UIStroke, TweenInfo.new(0.3), {
            ["Transparency"] = 1
        })
        local v41 = p38.instance:FindFirstChild("ScopePart", true)
        if v41 then
            v41:SetAttribute("OriginalMaterial", v41.Material.Name)
            if v41.Material ~= Enum.Material.Neon then
                v41.Material = Enum.Material.Glass
            end
            v41:SetAttribute("PreviousScopeTransparency", v41.Transparency)
            local v42 = v41.Transparency
            v41.Transparency = math.max(0.011, v42)
        end
        local v43 = p38.instance:FindFirstChild("ScopeTint", true)
        if v43 then
            v43.Transparency = v41 == nil and 0.8 or 0.3
        end
        v_u_9.hook_world_billboards("sights", function(p44)
            v_u_8.tween(p44, TweenInfo.new(0.1), {
                ["GroupTransparency"] = 0.7,
                ["Size"] = UDim2.fromScale(0.9, 0.9)
            })
        end)
    else
        v_u_8.tween(workspace.CurrentCamera, TweenInfo.new(v40, Enum.EasingStyle.Linear), {
            ["FieldOfView"] = v_u_11.settings.field_of_view
        })
        v_u_8.tween(v_u_9.get("RedDot").UIStroke, TweenInfo.new(0.3), {
            ["Transparency"] = 0.5
        })
        local v45 = p38.instance:FindFirstChild("ScopePart", true)
        if v45 and v45:GetAttribute("OriginalMaterial") then
            v45.Material = Enum.Material[v45:GetAttribute("OriginalMaterial")]
            v45.Transparency = v45:GetAttribute("PreviousScopeTransparency") or 0
        end
        local v46 = p38.instance:FindFirstChild("ScopeTint", true)
        if v46 then
            v46.Transparency = 1
        end
        v_u_9.unhook_world_billboards("sights")
        for _, v47 in v_u_9.get_world_billboards() do
            v_u_8.tween(v47, TweenInfo.new(0.1), {
                ["GroupTransparency"] = 0,
                ["Size"] = UDim2.fromScale(1, 1)
            })
        end
    end
end
function v_u_3.hook_states(p_u_48)
    p_u_48.offsets = {}
    p_u_48.states.mag:hook(function(_)
        p_u_48:update_ui()
    end)
    p_u_48.states.bullets:hook(function(_)
        p_u_48:update_ui()
    end)
    p_u_48.accuracy = Instance.new("NumberValue")
    p_u_48.states.sights:hook(function(p49, p50)
        if p49 ~= p50 then
            if p_u_48.owner then
                p_u_48:sights(p_u_48.owner, p49)
            end
        end
    end)
    p_u_48.states.sights:hook(function(p51, p52)
        if p51 ~= p52 then
            if p_u_48.owner.values.camera:get() then
                p_u_48:update_sight_lens(p51)
            end
        end
    end)
    p_u_48.states.reload:hook_paused(function(p53, p54)
        if p53 ~= p54 then
            if p_u_48.owner then
                p_u_48:reload(p_u_48.owner, false)
            end
        end
    end)
    p_u_48.states.reload:hook(function()
        if p_u_48.owner then
            p_u_48:reload(p_u_48.owner, true)
        end
    end)
    p_u_48.states.accuracy:hook(function(_)
        if p_u_48.accuracy then
            p_u_48.accuracy.Value = p_u_48.states.accuracy:get() - 1
        end
    end)
    p_u_48.states.cock:hook(function()
        if p_u_48.owner then
            p_u_48:cock(p_u_48.owner, true)
        end
    end)
    p_u_48.states.melee:hook(function()
        if p_u_48.owner then
            p_u_48:melee(p_u_48.owner)
        end
    end)
    p_u_48.states.shoot:hook(function(p55, p56)
        if p_u_48.owner then
            p_u_48:shoot(p_u_48.owner, p55, p56)
        end
    end)
    p_u_48.states.hit:hook(function(p57, p58)
        if p_u_48.owner then
            p_u_48:hit(p_u_48.owner, p57, p58)
        end
    end)
    p_u_48.states.loaded:hook(function(p59, p60)
        if p59 == p60 or not p_u_48.owner then
            return
        elseif p59 and (p60 == false and not p_u_48.states.single_load:get()) then
            local v61 = p_u_48.states.mag_size:get()
            local v62 = p_u_48.states.bullets
            local v_u_63 = math.min(v61, v62:get())
            p_u_48.states.mag:update(function(p64)
                return p64 + v_u_63
            end)
            p_u_48.states.bullets:update(function(p65)
                return p65 - v_u_63
            end)
        elseif p60 then
            local v66 = p_u_48.states.mag:get() - (p_u_48.instance:FindFirstChild("BulletEject", true) and 1 or 0)
            local v_u_67 = math.max(0, v66)
            p_u_48.states.mag:update(function(p68)
                return p68 - v_u_67
            end)
            p_u_48.states.bullets:update(function(p69)
                return p69 + v_u_67
            end)
        end
    end)
    p_u_48.states.load_bullet:hook(function()
        if p_u_48.owner and p_u_48.states.single_load:get() then
            p_u_48.states.mag:update(function(p70)
                return p70 + 1
            end)
            p_u_48.states.bullets:update(function(p71)
                return p71 - 1
            end)
        end
    end)
    p_u_48.states.chambered:hook(function(p72, p73)
        if p72 ~= p73 then
            if p_u_48.owner then
                p_u_48:chamber(p_u_48.owner, p72)
            end
        end
    end)
    for _, v74 in v_u_10.attachment_types do
        p_u_48.states[v74 .. "_att"]:hook(function(p75, p76)
            if p76 and (p76 ~= "" and p75 ~= p76) then
                v_u_12.get_item_class(p76):remove(p_u_48)
            end
            if p75 and p75 ~= "" then
                v_u_12.get_item_class(p75):apply(p_u_48)
            end
        end)
    end
    p_u_48.safety:hook(function(p77, p78)
        if p_u_48.owner then
            p_u_48:safety_function(p_u_48.owner, p77, p78)
        end
    end)
    local v_u_79 = v_u_15.new()
    p_u_48.object:destroying(function()
        v_u_79:clean()
    end)
    v_u_79:add(p_u_48.owner.values.camera:hook(function(p80, p81)
        if p_u_48.states.sights:get() then
            if p80 then
                p_u_48:update_sight_lens(true)
            elseif p81 then
                p_u_48:update_sight_lens(false)
            end
        else
            return
        end
    end).unhook)
    v_u_79:add(p_u_48.owner.values.camera:hook(function(p82, p83)
        if p_u_48.states.sights:get() then
            if p82 == game.Workspace.CurrentCamera then
                v_u_8.tween(v_u_9.get("RedDot").UIStroke, TweenInfo.new(0), {
                    ["Transparency"] = 1
                })
                v_u_8.tween(workspace.CurrentCamera, TweenInfo.new(0, Enum.EasingStyle.Linear), {
                    ["FieldOfView"] = v_u_11.settings.field_of_view / p_u_48.states.zoom:get()
                })
                return
            end
            if p82 == nil and p83 == game.Workspace.CurrentCamera then
                v_u_8.tween(workspace.CurrentCamera, TweenInfo.new(0, Enum.EasingStyle.Linear), {
                    ["FieldOfView"] = v_u_11.settings.field_of_view
                })
            end
        end
    end))
end
function v_u_3.running(p84, p85, p86)
    local v87 = p85.values.cframes:get("arms"):get_offset("run")
    if p86 then
        p84:running_pivots(p85, true)
        p84.states.sights:set(false)
        p84:reload(p85, false)
        p85.values.cframes:get("arms"):set_offset("run")
        p84.anim.Run.run_offset(v87)
    else
        p84:running_pivots(p85, false)
        p84.anim.Run.base(v87).Completed:Wait()
        p85.values.cframes:get("arms"):remove_offset("run")
    end
end
function v_u_3.walk_state(p88, p89, p90, p91)
    if p90 == "prone" or p91 == "prone" then
        p88:reload(p89, false)
        p88:cock(p89, false)
    end
end
function v_u_3.vault(p92, p93, p94)
    if p94 > 0 then
        p92:reload(p93, false)
        p92:cock(p93, false)
    end
end
function v_u_3.sights(p95, p96, p97)
    p95.sound.Handle(p95.instance.Root)
    local v98 = p96.values.cframes:get("arm1"):get_offset("sights")
    local v99 = p96.values.cframes:get("arm2"):get_offset("sights")
    local v100 = p95.cframes:get(p95.instance.Root):get_offset("sights")
    local v101 = p95.states.ads:get()
    if p97 then
        if p96.values.holding and p96.values.holding.safety then
            if p96.values.holding.states.ads then
                v101 = v101 + p96.values.holding.states.ads:get()
            end
            if p96.states.holding:get() == p96.values.holding.instance then
                p96.values.holding.safety:set(true)
            end
        end
        p95:reload(p96, false)
        p96.values.cframes:get("arm1"):set_offset("sights")
        p96.values.cframes:get("arm2"):set_offset("sights")
        p95.anim.Equip.arm1_hold(p96.values.cframes:get("arm1"):set_absolute("sights", true), p95, v101)
        p95.cframes:get(p95.instance.Root):set_offset("sights")
        p95.anim.Sight.arm1(v98, p95.instance, v101)
        p95.anim.Sight.arm2(v99, p95.instance, v101)
        p95.anim.Sight.gun(v100, p95.instance, v101)
        if p96.values.camera:get() then
            if p95.inputs and p95.inputs.enabled:get() then
                local v102 = string.gsub
                local v103 = p95.states.zoom
                local v104 = ("camera_sensitivity_%*"):format((v102(tostring(v103:get()), "[.]", "_")))
                if v_u_11.settings[v104] then
                    v_u_4.mouse_base_sensitivity:set(v_u_8.map_sensitivity(v_u_11.settings[v104]))
                    local v_u_105 = nil
                    v_u_105 = p95.states.sights:hook(function(p106)
                        if not p106 then
                            v_u_4.mouse_base_sensitivity:set(v_u_8.map_sensitivity(v_u_11.settings.camera_sensitivity))
                            v_u_105.unhook()
                        end
                    end)
                end
            end
            v_u_8.tween(p95.accuracy, TweenInfo.new(v101, Enum.EasingStyle.Linear), {
                ["Value"] = 1
            })
            return
        end
    else
        p96.values.cframes:get("arm1"):remove_absolute("sights")
        if p96.values.holding and (p96.values.holding.safety and not p96.values.equip_debounce:get()) then
            p96.values.holding.safety:set(false)
            v101 = v101 + p96.values.holding.states.ads:get()
        end
        if p96.values.camera:get() then
            v_u_8.tween(p95.accuracy, TweenInfo.new(v101, Enum.EasingStyle.Linear), {
                ["Value"] = p95.states.accuracy:get() - 1
            })
        end
        if p95.inputs and p95.inputs.enabled:get() then
            v_u_9.get("CancelScope").Visible = false
        end
        p95.anim.Sight.base(v98, p95.instance, v101)
        p95.anim.Sight.base(v99, p95.instance, v101)
        p95.anim.Sight.base(v100, p95.instance, v101).Completed:Wait()
        p96.values.cframes:get("arm1"):remove_offset("sights")
        p96.values.cframes:get("arm2"):remove_offset("sights")
        p95.cframes:get(p95.instance.Root):remove_offset("sights")
    end
end
function v_u_3.reload(p107, p108, p109)
    if p109 then
        p107.reload_thread(p107, p108, p109)
    else
        p107.reload_thread:cancel(p107, p108, p109)
    end
end
function v_u_3.cock(p110, p111, p112)
    if p112 then
        p110:reload(p111, false)
        p110.cock_thread(p110, p111, p112)
    else
        p110.cock_thread:cancel(p110, p111, p112)
    end
end
function v_u_3.chamber(p113, _, p114)
    if p113.slide then
        local v115 = p113.cframes:get(p113.slide):get_offset("shoot")
        if p114 then
            p113.anim.Gun.slide_off(v115)
        else
            p113.anim.Gun.slide_on(v115).Completed:Wait()
        end
    end
    if not p113.states.single_load:get() then
        if p114 then
            p113.sound.Reload4(p113.instance.Root)
            return
        end
        p113.sound.Empty(p113.instance.Root)
    end
end
function v_u_3.render(p116, p117, p118)
    p116.instance.Root:PivotTo(p116.cframes:get(p116.instance.Root):render(p118))
    if p116.hammer then
        p116.hammer:PivotTo(p116.cframes:get(p116.hammer):render(p118))
    end
    if p116.feed_cover then
        p116.feed_cover:PivotTo(p116.cframes:get(p116.feed_cover):render(p118))
    end
    if p116.slide then
        p116.slide:PivotTo(p116.cframes:get(p116.slide):render(p118))
    end
    if p116.load_slide then
        p116.load_slide:PivotTo(p116.cframes:get(p116.load_slide):render(p118))
    end
    if p116.magazine then
        p116.magazine:PivotTo(p116.cframes:get(p116.magazine):render(p118))
    elseif p116.cylinder then
        p116.cylinder:PivotTo(p116.cframes:get(p116.cylinder):render(p118))
        if p116.loader and p116.loader.Parent == p117.values.viewmodels then
            p116.loader.Case:PivotTo(p116.cframes:get(p116.loader.Case):render(p118))
        end
    end
    if p116.end_bullet then
        p116.end_bullet:PivotTo(p116.cframes:get(p116.end_bullet):render(p118))
    end
    if p116.charm_model and p116.charm_model.PrimaryPart then
        p116.charm_model.PrimaryPart:PivotTo(p116.cframes:get(p116.charm_model.PrimaryPart):render(p118))
    end
    if p116.inputs and p116.inputs.enabled:get() then
        p116:input_render(p118)
    end
end
function v_u_3.auto_shoot_check(p119, _)
    local v120 = os.clock()
    if v120 - p119.auto_shoot_dt > 0.25 then
        p119.auto_shoot_dt = v120
        if v_u_9.get("Flash").Frame.BackgroundTransparency == 0 then
            return
        end
        local v121 = p119.owner
        local v122 = p119:get_shoot_look()
        local v123 = CFrame.new(v_u_8.validate_position(game.Workspace.CurrentCamera.CFrame.Position, v122.Position, v121.values.ray_params)) * v122.Rotation
        local v124 = v123.Position
        local v125 = v123.LookVector * 500
        for _, v126 in v_u_8.ray_damage(v124, v125, { v121.values.viewmodels, v121.instance }, nil, true) do
            local v127 = v126.Instance
            if v126.HitHum then
                p119:input_shoot(true)
                return
            end
            if v127 and v127.Transparency < 1 then
                local v128 = v_u_8.get_breakable_instance(v127)
                if v128 and v_u_8.ownership(v_u_5.get("Breakable", v128).owner:get()) == 0 then
                    p119:input_shoot(true)
                    return
                end
            end
        end
        if p119.shoot_hold and not (p119.inputs:get("shoot"):holding() or p119.inputs:get("shoot_joystick"):holding()) then
            p119:input_shoot(false)
        end
    end
end
function v_u_3.input_render(p129, _)
    local v130 = p129.owner
    if v130.values.prone_debounce or v130.values.equip_debounce:get() then
        p129:reload(v130, false)
        p129:cock(v130, false)
    elseif not p129.cock_thread.running and (not p129.reload_thread.running and (not p129.states.chambered:get() and (not v130.values.equip_debounce:get() and (not p129.states.reload:get() and (v130.states.vault:get() == 0 and (p129.states.loaded:get() and p129.states.mag:get() > 0)))))) then
        p129.states.cock:fire_instant()
    end
    local _ = v130.values.viewmodels.head
    if not v_u_11.settings.toggle_aim then
        if p129.ads_hold and not (p129.reload_thread.running or (p129.meleeing or (v130.states.running:get() or (v130.values.prone_debounce or v130.values.equip_debounce:get())))) then
            p129.states.sights:set(true)
        else
            p129.states.sights:set(false)
        end
    end
    if p129.automatic and (p129.shoot_hold and (not p129.safety:get() or p129.accuracy.Value >= 1)) and not (v130.values.equip_debounce:get() or v130.states.running:get()) then
        local v131 = os.clock()
        local v132 = p129.states.firerate:get()
        if (v132 == 0 or v131 - p129.last_shot > 1 / (v132 / 60)) and (p129.states.mag:get() > 0 and p129.states.chambered:get()) then
            p129.last_shot = v131
            p129:send_shoot()
        end
    end
    if p129.states.reload:get() and v130.values.equip_debounce:get() then
        p129:reload(v130, false)
    end
end
function v_u_3.kickback(p133, p134)
    local v135 = p134.values.cframes:get("arms"):set_offset("shoot")
    p133.anim.Shoot.key1(v135).Completed:Wait()
    p133.anim.Shoot.key2(v135).Completed:Wait()
    p133.anim.Shoot.key3(v135).Completed:Wait()
    p134.values.cframes:get("arms"):remove_offset("shoot")
end
function v_u_3.recoil_function(p136, p137)
    p137.values.cframes:get("camera"):remove_offset("shoot")
    local v138 = p137.values.cframes:get("camera"):set_offset("shoot")
    local v139 = v138.Value
    if p137.values.camera:get() then
        local v140 = p137.values
        v140.old_cam_render = v140.old_cam_render * v139:Inverse()
    end
    local v141 = p136.states.recoil_up:get()
    local v142 = p136.states.recoil_side:get()
    if v_u_4.current_device:get() ~= "pc" then
        v141 = v141 * 0.7
        v142 = v142 * 0.7
    end
    if p136.prone_recoil and p137.states.walk_state:get() == "prone" then
        v141 = v141 * p136.prone_recoil
        v142 = v142 * p136.prone_recoil
    end
    v_u_8.tween(v138, TweenInfo.new(0), {
        ["Value"] = CFrame.new()
    })
    v138.Value = CFrame.new()
    if p137.values.cframes:get("arm2"):current_pivot() == "equipped" then
        v141 = v141 * 0.8
    end
    local v143 = CFrame.Angles
    local v144 = math.random() * v141 + v141
    local v145 = math.rad(v144)
    local v146 = math.random() * (v142 * 2) - v142
    local v147 = v143(v145, math.rad(v146), 0)
    local v148 = (v141 * 2 + v142) / 40
    local v149 = math.exp(v148)
    v_u_8.tween(v138, TweenInfo.new(v149 * 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Value"] = v147
    }).Completed:Wait()
    v_u_8.tween(v138, TweenInfo.new(v149 * 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ["Value"] = CFrame.new()
    }).Completed:Wait()
end
function v_u_3.shoot(p_u_150, p_u_151, _, p152)
    p_u_150.states.mag:update(function(p153)
        local v154 = p153 - 1
        return math.max(0, v154)
    end)
    if p_u_150.states.firerate:get() == 0 then
        p_u_150.states.chambered:set(false)
    else
        local v155 = p_u_150.instance:FindFirstChild("BulletEject", true)
        if v155 then
            p_u_150:eject_bullet(v155, p_u_150.bullet_type)
        end
    end
    if p_u_150.supressed then
        p_u_150.sound.SilencedShoot(p_u_150.shot)
    else
        p_u_150.sound.Shoot(p_u_150.shot)
    end
    p_u_150:reload(p_u_151, false)
    local v156 = p_u_150.states.pellets:get() > 1
    if p_u_150.owner.values.camera:get() == nil and (not v156 and (p152 and #p152 > 0)) then
        for _, v157 in p152 do
            if #v157 > 0 then
                p_u_150:trail(p_u_150.shot.CFrame.Position, v157[#v157].Position)
            end
        end
    end
    task.spawn(function()
        p_u_150:kickback(p_u_151)
    end)
    if p_u_151.values.camera:get() then
        p_u_150.recoil(p_u_150, p_u_151)
    end
    task.spawn(function()
        local v158 = p_u_150.shot:FindFirstChild("Smoke")
        if v158 then
            for _ = 1, 3 do
                v158:Emit(1)
                task.wait(0.1)
            end
        end
    end)
    if p_u_150.shot:FindFirstChild("Flash") then
        p_u_150:flash()
    end
    if p_u_150.states.firerate:get() > 0 then
        task.spawn(p_u_150.slide_shoot, p_u_150)
    end
    if p_u_150.hammer then
        task.spawn(function()
            local v159 = p_u_150.cframes:get(p_u_150.hammer):set_offset("shoot")
            p_u_150.anim.Gun.hammer_on(v159).Completed:Wait()
            p_u_150.anim.Gun.hammer_off(v159).Completed:Wait()
            p_u_150.cframes:get(p_u_150.hammer):remove_offset("shoot")
        end)
    end
    if p152 then
        p_u_150:bullet_hit(p_u_151, p152)
    end
end
function v_u_3.bullet_hit(p160, _, p161)
    for _, v162 in p161 do
        if #v162 ~= 0 then
            for _, v163 in v162 do
                local v164 = v163.Instance
                if v164 and (v164:HasTag("Water") and not v164.CanCollide) then
                    local v165 = v163.Position
                    local v166 = Instance.new("Attachment")
                    v_u_8.debris(v166, 2)
                    local v167 = v164.Size.X
                    local v168 = v164.Size.Y
                    local v169 = v164.Size.Z
                    local v170 = math.min(v167, v168, v169)
                    v166.WorldCFrame = CFrame.new(v165.X, v164.CFrame.Y + v170 * 0.5, v165.Z)
                    v166.Parent = game.Workspace.Terrain
                    v_u_16.Ring(v166)
                    v_u_16.Splash(v166, 3, v164)
                    v_u_16.WaterSplash(v166)
                end
            end
            local v171 = v162[#v162]
            if v171 then
                local v172 = v171.Instance
                local v173 = v171.Normal
                local v174 = v171.Position
                if v171.HitHum then
                    local v175 = Instance.new("Attachment")
                    v175.Parent = game.Workspace.Terrain
                    v175.WorldCFrame = CFrame.new(v174) * CFrame.lookAt(Vector3.new(0, 0, 0), v173)
                    v_u_8.debris(v175, 1)
                    p160:emit_blood(v175)
                    p160.sound.BulletHit(v175)
                elseif v172 and (v172.Transparency < 1 and v172.Anchored) then
                    local v_u_176 = v_u_16.create_point(v174, v173, math.random(8, 12))
                    local v_u_177 = v_u_8.get_breakable_instance(v172)
                    if v_u_177 then
                        local v_u_178 = v_u_15.new()
                        v_u_178:add(v_u_5.get("Breakable", v_u_177).states.destroyed:hook(function(p179)
                            if p179 then
                                task.defer(function()
                                    v_u_176:Destroy()
                                end)
                            end
                        end).unhook)
                        v_u_178:add(v_u_177.AncestryChanged:Connect(function()
                            if v_u_177.Parent == nil or v_u_177.Parent == game.ReplicatedStorage.Garbage then
                                task.defer(function()
                                    v_u_176:Destroy()
                                end)
                            end
                        end))
                        v_u_176.Destroying:Connect(function()
                            v_u_178:clean()
                        end)
                    end
                    local v180 = script.BulletHoles.Normal:Clone()
                    v180.Parent = v_u_176
                    v180.Color = ColorSequence.new(v172.Color)
                    v180:Emit(2)
                end
            end
        end
    end
end
function v_u_3.slide_shoot(p181)
    if p181.slide then
        local v182 = p181.cframes:get(p181.slide):get_offset("shoot")
        p181.anim.Gun.slide_on(v182).Completed:Wait()
        if p181.states.mag:get() > 0 then
            p181.anim.Gun.slide_off(v182).Completed:Wait()
        end
        if p181.states.mag:get() == 0 then
            p181.states.chambered:set(false)
            return
        end
    elseif p181.load_slide then
        local v183 = p181.cframes:get(p181.load_slide):get_offset("shoot")
        p181.anim.Gun.slide_on(v183).Completed:Wait()
        p181.anim.Gun.slide_off(v183).Completed:Wait()
        if p181.states.mag:get() == 0 then
            p181.states.chambered:set(false)
        end
    end
end
function v_u_3.melee(p184, p185, _)
    p184:reload(p185, false)
    p184:cock(p185, false)
    p184.meleeing = true
    local v186 = p185.values.cframes:get("arm1"):set_absolute("melee", true)
    local v187 = nil
    if p184.anim.Melee.arm2_hold then
        local v188 = p185.values.cframes:get("arm2"):set_absolute("melee", true)
        p184.anim.Melee.arm2_hold(v188)
    else
        p185.values.cframes:get("arm2"):set_absolute("melee", CFrame.new())
        p185.values.cframes:get("arm2"):set_pivot("base")
    end
    if p184.anim.Melee.gun_hold then
        v187 = p184.cframes:get(p184.instance.Root):set_absolute("melee", true)
        p184.anim.Melee.gun_hold(v187)
    end
    p184.sound.Handle(p184.instance.Root)
    p184.anim.Melee.arm1_hold(v186).Completed:Wait()
    p185.values.cframes:get("arm1"):remove_absolute("melee")
    p185.values.cframes:get("arm2"):remove_absolute("melee")
    if not p184.anim.Melee.arm2_hold then
        p185.values.cframes:get("arm2"):remove_pivot("base")
    end
    if v187 then
        p184.cframes:get(p184.instance.Root):remove_absolute("melee")
    end
end
function v_u_3.hit(p189, p190, p191, p192)
    local v193 = p190.values.cframes:get("arm1"):set_absolute("melee")
    local v194 = nil
    local v195
    if p189.anim.Melee.arm2_hit then
        v195 = p190.values.cframes:get("arm2"):set_absolute("melee")
    else
        v195 = nil
    end
    if p189.anim.Melee.gun_hit then
        v194 = p189.cframes:get(p189.instance.Root):set_absolute("melee")
    end
    if p189:process_hit_results(p191, p192) then
        p189.sound.Swing(p189.instance.Root)
        if v194 then
            p189.anim.Melee.gun_miss(v194)
        end
        if v195 then
            p189.anim.Melee.arm2_miss(v195)
        end
        p189.anim.Melee.arm1_miss(v193).Completed:Wait()
    else
        if v194 then
            p189.anim.Melee.gun_hit(v194)
        end
        if v195 then
            p189.anim.Melee.arm2_hit(v195)
        end
        p189.anim.Melee.arm1_hit(v193).Completed:Wait()
    end
    p190.values.cframes:get("arm1"):remove_absolute("melee")
    if v195 then
        p190.values.cframes:get("arm2"):remove_absolute("melee")
    end
    if v194 then
        p189.cframes:get(p189.instance.Root):remove_absolute("melee")
    end
    p189.meleeing = false
end
function v_u_3.safety_function(p196, p197, p198, p199)
    local v200 = p197.values.cframes:get("arm1"):get_absolute("equipped")
    local v201 = p197.values.cframes:get("arm2"):get_absolute("equipped")
    if p198 == true then
        p196.anim.Equip.arm1_hold_safety(v200)
        if p199 == false then
            p197.values.cframes:get("arm2"):remove_pivot("equipped")
            p197.values.cframes:get("arm2"):remove_absolute("equipped")
            return
        end
    elseif p198 == false then
        p197.values.cframes:get("arm2"):set_absolute("equipped", true)
        p197.values.cframes:get("arm2"):set_pivot("equipped")
        p196.anim.Equip.arm2_hold(v201, p196)
        p196.anim.Equip.arm1_hold(v200, p196).Completed:Wait()
    end
end
function v_u_3.equip(p202, p203, p204)
    local v205 = p203.values.cframes:get("arm1"):get_absolute("equipped")
    p203.values.cframes:get("arm2"):get_absolute("equipped")
    local v206 = p202.instance:FindFirstChild("Root")
    if v206 == nil then
        return
    elseif p204 == true then
        p202.instance.Parent = p203.values.viewmodels
        p203.values.cframes:get("arm1"):set_absolute("equipped", true)
        p202.anim.Equip.arm1_grab(v205).Completed:Wait()
        p202.sound.Equip(v206)
        p202.cframes:get(v206):set_pivot("equipped")
        p202.cframes:get(v206).pivot_time = 0.2
        p203.values.cframes:get("arm1"):set_pivot("equipped")
        local v207 = p202.safety
        local v208 = p203.values.holding
        if v208 then
            if p203.states.holding:get() == p203.values.holding.instance then
                v208 = p203.values.holding.loadout_type == "primary"
            else
                v208 = false
            end
        end
        v207:set_instant(v208)
    else
        p202.states.sights:set(false)
        p202:reload(p203, false)
        p202:cock(p203, false)
        p202.sound.Handle(v206)
        p203.values.cframes:get("arm1"):remove_pivot("equipped")
        if p202.safety:get() == false then
            p203.values.cframes:get("arm2"):remove_pivot("equipped")
            p203.values.cframes:get("arm2"):remove_absolute("equipped")
        end
        p202.safety:set_instant(nil)
        if p203.values.holding and p203.values.holding.safety then
            p203.values.holding.safety:set(false)
        end
        p202.anim.Equip.arm1_grab(v205).Completed:Wait()
        p202.cframes:get(v206).pivot_time = 0.2
        p202.cframes:get(v206):remove_pivot("equipped")
        p203.values.cframes:get("arm1"):remove_absolute("equipped")
        p202.instance.Parent = p203.values.Items
    end
end
function v_u_3.trail(p209, p210, p211, _)
    local v212 = Instance.new("Attachment")
    local v213 = Instance.new("Attachment")
    v_u_8.debris(v212, 0.5)
    v_u_8.debris(v213, 0.5)
    v212.Parent = workspace.Terrain
    v213.Parent = workspace.Terrain
    v212.Position = p210
    v213.Position = p211
    local v214 = Instance.new("Beam", game.Workspace)
    v_u_8.debris(v214, 0.5)
    v214.Width0 = p209.states.trail_size:get() or 0.1
    v214.Width1 = p209.states.trail_size:get() or 0.1
    v214.Attachment0 = v212
    v214.Attachment1 = v213
    if p209.supressed then
        v214.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.95) })
    else
        v214.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.75) })
    end
    v_u_8.tween(v214, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0), {
        ["Width0"] = 0,
        ["Width1"] = 0
    })
    if p209.owner.values.camera:get() == nil then
        local v215 = Instance.new("Attachment")
        v_u_8.debris(v215, 0.5)
        v215.Parent = workspace.Terrain
        v215.WorldCFrame = CFrame.new(v_u_8.closest_point_on_segment(game.Workspace.CurrentCamera.CFrame.Position, v212.WorldCFrame.Position, v213.WorldCFrame.Position))
        local v216 = (p210 - p211).Magnitude
        local v217 = p209.sound.BulletWoosh(v215)
        local v218 = v216 / 50
        v217.Volume = math.min(1, v218) * 0.5
    end
end
function v_u_3.eject_bullet(_, p219, p220)
    local v221 = script.Bullets[p220]:Clone()
    v221.Parent = workspace
    v221.CanCollide = true
    v221:PivotTo(p219.WorldCFrame)
    v221:ApplyImpulse(p219.WorldCFrame.RightVector * (math.random(8, 12) * v221.Mass) + p219.WorldCFrame.UpVector * (math.random(8, 12) * v221.Mass))
    v_u_16.mark_prop(v221)
    return v221
end
function v_u_3.setup_shot(_, p222)
    local v223 = script.Shot:Clone()
    v223.Flash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.3) })
    v223.Parent = p222.Parent
    v223.CFrame = p222.WorldCFrame
    v_u_8.weld_c(v223, p222.Parent)
    return v223
end
function v_u_3.reload_begin(p224, p225)
    p224.sound.Handle(p224.instance.Root)
    p224.safety:set(false)
    local v226 = p225.values.cframes:get("arm1"):set_absolute("reload", true)
    local v227 = p225.values.cframes:get("arm2"):set_absolute("reload", true)
    local v228 = p224.cframes:get(p224.instance.Root):set_absolute("reload", true)
    local v229 = p224.states.reload_speed:get()
    if p224.feed_cover then
        p224.anim.Reload.arm2_empty1(v227, v229)
        p224.anim.Reload.gun_empty1(v228, v229)
        p224.anim.Reload.arm1_empty1(v226, v229).Completed:Wait()
        local v230 = p224.cframes:get(p224.feed_cover):get_offset("reload")
        p224.sound.FeedOpen(p224.instance.Root)
        v_u_8.tween(v230, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            ["Value"] = CFrame.Angles(0, -0.5235987755982988, 0)
        })
        p224.anim.Reload.arm2_empty2(v227, v229).Completed:Wait()
        if p224.states.loaded:get() and not p224.states.single_load:get() then
            p224.anim.Reload.arm1_start(v226, v229)
            p224.anim.Reload.gun(v228, v229)
            p224.anim.Reload.arm2_start(v227, v229).Completed:Wait()
            if p224.magazine then
                if p224.end_bullet then
                    p224.cframes:get(p224.end_bullet):set_pivot("unloaded")
                end
                p224.cframes:get(p224.magazine):set_pivot("reload")
                p224.sound.Reload1(p224.instance.Root)
                p224.states.loaded:set(false)
            end
        else
            p224.anim.Reload.gun(v228, v229)
        end
    elseif p224.cylinder then
        p224.anim.Reload.arm1_start(v226, v229)
        p224.anim.Reload.gun(v228, v229)
        p224.anim.Reload.arm2_start(v227, v229).Completed:Wait()
        local v231 = p224.cframes:get(p224.cylinder):get_offset("reload")
        p224.sound.Reload1(p224.instance.Root)
        p224.anim.Reload.cylinder_open(v231, v229)
        if p224.states.loaded:get() then
            if p224.anim.Reload.arm1_empty1 then
                p224.anim.Reload.arm2_empty1(v227, v229)
                p224.anim.Reload.arm1_empty1(v226, v229).Completed:Wait()
            end
            local v232 = false
            for _ = 1, p224.states.mag_size:get() do
                if p224:eject_bullet(p224.cylinder.Eject, p224.bullet_type, CFrame.Angles(0, 1.5707963267948966, 1.5707963267948966)) == nil then
                    v232 = false
                else
                    v232 = true
                end
            end
            if v232 then
                p224.sound.Cases(p224.instance.Root)
            end
            p224.states.loaded:set(false)
            if p224.anim.Reload.arm1_empty2 then
                p224.anim.Reload.arm2_empty2(v227, v229)
                p224.anim.Reload.arm1_empty2(v226, v229).Completed:Wait()
            end
        end
    elseif p224.states.loaded:get() and not p224.states.single_load:get() then
        p224:cock(p225, false)
        p224.anim.Reload.arm1_start(v226, v229)
        p224.anim.Reload.gun(v228, v229)
        p224.anim.Reload.arm2_start(v227, v229).Completed:Wait()
        if p224.magazine then
            if p224.end_bullet then
                p224.cframes:get(p224.end_bullet):set_pivot("unloaded")
            end
            p224.cframes:get(p224.magazine):set_pivot("reload")
            p224.sound.Reload1(p224.instance.Root)
            p224.states.loaded:set(false)
        end
    else
        p224.anim.Reload.gun(v228, v229)
    end
    local v233 = p224.states.mag_size:get() - p224.states.mag:get() + (p224.states.chambered:get() and not p224.cylinder and 1 or 0)
    local v234 = p224.states.bullets
    local v235 = math.min(v233, v234:get())
    if v235 > 0 then
        p224:cock(p225, false)
    end
    for v236 = 1, v235 do
        p224.anim.Reload.arm1_idle1(v226, v229)
        if p224.anim.Reload.arm2_start2 then
            p224.anim.Reload.arm2_start2(v227, v229).Completed:Wait()
        end
        p225.values.cframes:get("arm2"):set_pivot("reload")
        p224.anim.Reload.base(v227, v229)
        if p224.anim.Reload.gun_idle then
            p224.anim.Reload.gun_idle(v228, v229)
        end
        if p224.states.single_load:get() then
            task.wait(0.15 * v229)
            p224.single_bullet = script.Bullets[p224.bullet_load_type or p224.bullet_type]:Clone()
            p224.single_bullet.Parent = p225.values.viewmodels
            p224.single_bullet.CanCollide = false
            p224.single_bullet:PivotTo(p225.values.viewmodels.arm2.CFrame * p224.hold_bullet_offset)
            v_u_8.weld_c(p224.single_bullet, p225.values.viewmodels.arm2)
        else
            task.wait(0.5 * v229)
        end
        if p224.cylinder and p224.loader then
            p224.loader.Parent = p225.values.viewmodels
            p224.loader.Case:PivotTo(p224.cframes:get(p224.loader.Case):render(0.016666666666666666))
        end
        p225.values.cframes:get("arm2"):remove_pivot("reload")
        p224.anim.Reload.arm1_idle2(v226, v229)
        p224.anim.Reload.arm2_idle(v227, v229).Completed:Wait()
        if p224.magazine then
            p224.cframes:get(p224.magazine):remove_pivot("reload")
            p224.magazine.Transparency = 0
            p224.sound.Reload2(p224.instance.Root)
            if p224.feed_cover then
                p224.anim.Reload.arm2_finish(v227, v229)
                p224.anim.Reload.arm1_finish(v226, v229).Completed:Wait()
                p224.sound.Chains(p224.instance.Root)
                if p224.end_bullet then
                    p224.cframes:get(p224.end_bullet):remove_pivot("unloaded")
                    p224.end_bullet.Transparency = 0
                    for _, v237 in p224.end_bullet:GetChildren() do
                        if v237:IsA("BasePart") then
                            v237.Transparency = 0
                        end
                    end
                end
                p224.anim.Reload.arm2_empty1_2(v227, v229)
                p224.anim.Reload.arm1_empty1(v226, v229).Completed:Wait()
                p224.states.loaded:set(true)
                p224.anim.Reload.gun_empty1(v228, v229)
                p224.anim.Reload.arm2_empty2(v227, v229).Completed:Wait()
                local v238 = p224.cframes:get(p224.feed_cover):get_offset("reload")
                p224.sound.FeedClose(p224.instance.Root)
                v_u_8.tween(v238, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    ["Value"] = CFrame.Angles(0, 0, 0)
                })
                p224.anim.Reload.arm2_empty1_3(v227, v229).Completed:Wait()
            else
                p224.states.loaded:set(true)
                p224.anim.Reload.arm2_finish(v227, v229)
                p224.anim.Reload.arm1_finish(v226, v229).Completed:Wait()
            end
        elseif p224.cylinder and p224.loader then
            p224.sound.Reload2(p224.instance.Root)
            p224.cframes:get(p224.loader.Case):set_pivot("reload")
            p224.anim.Reload.arm2_finish(v227, v229)
            p224.anim.Reload.arm1_finish(v226, v229).Completed:Wait()
            if p224.loader then
                p224.loader.Parent = nil
                p224.cframes:get(p224.loader.Case):remove_pivot("reload")
            end
            p224.states.loaded:set(true)
            p224.anim.Reload.arm1_start(v226, v229)
            p224.anim.Reload.gun(v228, v229)
            p224.anim.Reload.arm2_start(v227, v229).Completed:Wait()
            p224.sound.Reload1(p224.instance.Root)
            local v239 = p224.cframes:get(p224.cylinder):get_offset("reload")
            p224.anim.Reload.cylinder_close(v239, v229)
        elseif p224.states.single_load:get() then
            p224.sound.Reload2(p224.instance.Root)
            p224.single_bullet:Destroy()
            if not p224.cylinder then
                p224.states.loaded:set(true)
                p224.states.load_bullet:fire()
            end
            p224.anim.Reload.arm2_finish(v227, v229)
            p224.anim.Reload.arm1_finish(v226, v229).Completed:Wait()
            if p224.cylinder then
                p224.states.loaded:set(true)
                p224.states.load_bullet:fire()
            end
            if p224.cylinder and (v236 == v235 or (p224.states.mag:get() >= p224.states.mag_size:get() or p224.states.bullets:get() <= 0)) then
                p224.anim.Reload.gun(v228, v229)
                if p224.anim.Reload.arm1_empty2 then
                    p224.anim.Reload.arm2_empty2(v227, v229)
                    p224.anim.Reload.arm1_empty2(v226, v229).Completed:Wait()
                end
                if p224.anim.Reload.arm1_empty1 then
                    p224.anim.Reload.arm2_empty1(v227, v229)
                    p224.anim.Reload.arm1_empty1(v226, v229).Completed:Wait()
                end
                p224.sound.Reload1(p224.instance.Root)
                local v240 = p224.cframes:get(p224.cylinder):get_offset("reload")
                p224.anim.Reload.cylinder_close(v240, v229)
                return
            end
        end
        if p224.states.bullets:get() <= 0 or not p224.states.single_load:get() or p224.states.mag:get() >= p224.states.mag_size:get() + (p224.states.chambered:get() and 1 or 0) then
            break
        end
    end
end
function v_u_3.reload_done(p241, p242)
    p242.values.cframes:get("arm1"):get_absolute("reload")
    p242.values.cframes:get("arm2"):get_absolute("reload")
    p241.cframes:get(p241.instance.Root):get_absolute("reload")
    p241.sound.Handle(p241.instance.Root)
    p242.values.cframes:get("arm1"):remove_absolute("reload")
    p242.values.cframes:get("arm2"):remove_absolute("reload")
    p241.cframes:get(p241.instance.Root):remove_absolute("reload")
    local v243 = p241.safety
    local v244 = p242.values.holding
    if v244 then
        v244 = p242.values.holding.loadout_type == "primary"
    end
    v243:set(v244)
end
function v_u_3.reload_cancel(p245, p246)
    if p245 ~= nil then
        p246.values.cframes:get("arm1"):get_absolute("reload")
        p246.values.cframes:get("arm2"):get_absolute("reload")
        p245.cframes:get(p245.instance.Root):get_absolute("reload")
        if p245.single_bullet then
            p245.single_bullet:Destroy()
            p245.single_bullet = nil
        end
        if p245.loader then
            p245.loader.Parent = nil
            p245.cframes:get(p245.loader.Case):remove_pivot("reload")
        end
        p246.values.cframes:get("arm2"):remove_pivot("reload")
        if p245.end_bullet then
            if p245.states.loaded:get() then
                p245.cframes:get(p245.end_bullet):remove_pivot("unloaded")
            else
                if p245.cframes:get(p245.end_bullet):current_pivot() ~= "unloaded" then
                    p245.cframes:get(p245.end_bullet):set_pivot("unloaded")
                end
                p245.end_bullet.Transparency = 1
                for _, v247 in p245.end_bullet:GetChildren() do
                    if v247:IsA("BasePart") then
                        v247.Transparency = 1
                    end
                end
            end
        end
        if p245.magazine then
            p245.cframes:get(p245.magazine):remove_pivot("reload")
            if not p245.states.loaded:get() then
                p245.magazine.Transparency = 1
            end
            if p245.feed_cover then
                local v248 = p245.cframes:get(p245.feed_cover):get_offset("reload")
                v_u_8.tween(v248, TweenInfo.new(0.1), {
                    ["Value"] = CFrame.new(0, 0, 0)
                })
            end
        elseif p245.cylinder then
            local v249 = p245.cframes:get(p245.cylinder):get_offset("reload")
            v_u_8.tween(v249, TweenInfo.new(0.1), {
                ["Value"] = CFrame.new(0, 0, 0)
            })
        end
        p245.sound.Handle(p245.instance.Root)
        p246.values.cframes:get("arm1"):remove_absolute("reload")
        p246.values.cframes:get("arm2"):remove_absolute("reload")
        p245.cframes:get(p245.instance.Root):remove_absolute("reload")
        local v250 = p245.safety
        local v251 = p246.values.holding
        if v251 then
            v251 = p246.values.holding.loadout_type == "primary"
        end
        v250:set(v251)
    end
end
function v_u_3.cock_begin(p252, p253)
    local v254 = not p252.states.single_load:get()
    p252.sound.Handle(p252.instance.Root)
    local v255 = p252.states.reload_speed:get()
    if p252.right_hand_hold then
        p252.cframes:get(p252.instance.Root).pivot_time = 0.1
        p252.cframes:get(p252.instance.Root):set_pivot("equipped2")
    end
    local v256 = p253.values.cframes:get("arm1"):set_absolute("cock", true)
    local v257 = p253.values.cframes:get("arm2"):set_absolute("cock", true)
    local v258
    if p252.load_slide then
        v258 = p252.cframes:get(p252.load_slide):set_offset("cock")
        p252.anim.Reload.slide_cock(v258, v255)
        if not v254 then
            p252.sound.Reload3(p252.instance.Root)
        end
    else
        v258 = nil
    end
    p252.anim.Reload.arm1_cock(v256, v255, p252)
    p252.anim.Reload.arm2_cock(v257, v255, p252).Completed:Wait()
    if v258 then
        p252.anim.Reload.slide_cocked(v258, v255)
        if v254 then
            p252.sound.Reload3(p252.instance.Root)
        else
            p252.sound.Reload4(p252.instance.Root)
            local v259 = p252.instance:FindFirstChild("BulletEject", true)
            if v259 then
                p252:eject_bullet(v259, p252.bullet_type)
            end
        end
    else
        p252.states.chambered:set(true)
    end
    p252.anim.Reload.arm1_cocked(v256, v255, p252)
    p252.anim.Reload.arm2_cocked(v257, v255, p252).Completed:Wait()
    if v258 then
        p252.states.chambered:set(true)
    end
end
function v_u_3.cock_done(p260, p261)
    p261.values.cframes:get("arm1"):get_absolute("cock")
    p261.values.cframes:get("arm2"):get_absolute("cock")
    local v262
    if p260.load_slide then
        v262 = p260.cframes:get(p260.load_slide):get_offset("cock")
        p260.anim.Reload.base(v262, 1)
    else
        v262 = nil
    end
    p260.sound.Handle(p260.instance.Root)
    if v262 then
        p260.cframes:get(v262):remove_offset("cock")
    end
    p261.values.cframes:get("arm1"):remove_absolute("cock")
    p261.values.cframes:get("arm2"):remove_absolute("cock")
    if p260.right_hand_hold then
        p260.cframes:get(p260.instance.Root):remove_pivot("equipped2")
    end
end
function v_u_3.cock_cancel(p263, p264)
    if p263 ~= nil then
        p264.values.cframes:get("arm1"):get_absolute("cock")
        p264.values.cframes:get("arm2"):get_absolute("cock")
        local v265
        if p263.load_slide then
            v265 = p263.cframes:get(p263.load_slide):get_offset("cock")
            p263.anim.Reload.base(v265, 1)
        else
            v265 = nil
        end
        p263.sound.Handle(p263.instance.Root)
        if v265 then
            p263.cframes:get(v265):remove_offset("cock")
        end
        p264.values.cframes:get("arm1"):remove_absolute("cock")
        p264.values.cframes:get("arm2"):remove_absolute("cock")
        if p263.right_hand_hold then
            p263.cframes:get(p263.instance.Root):remove_pivot("equipped2")
        end
    end
end
function v_u_3.get_shoot_look(p266)
    shared.extras.ResetEnv()
    local v267 = p266.owner
    if not v_u_14.FLAG_ADS_CAMERA_BULLETS then
        return p266.shot.CFrame
    end
    local v268 = p266.reticule or p266.instance.Root.FrontSight
    local _ = v267.values.cframes:get("camera"):get_offset("shoot").Value
    local v269 = v268.WorldCFrame
    return p266.shot.CFrame:Lerp(v269, p266.accuracy.Value)
end
function get_circular_spread(p270, p271)
    local v272 = math.random() * 2 * 3.141592653589793
    local v273 = math.random() ^ 0.35 * p271
    return (p270.RightVector * math.cos(v272) + p270.UpVector * math.sin(v272)) * v273
end
function v_u_3.send_shoot(p274)
    local v275 = p274.owner
    local v276 = p274:get_shoot_look()
    if p274.client_sided_hitscan then
        local v277 = p274.states.pellets:get() > 1
        local v278
        if p274.red_dot and p274.red_dot.Transparency == 1 then
            if v277 then
                v278 = 1 - p274.accuracy.Value * 0.35 * 0.5
            else
                v278 = 1 - p274.accuracy.Value * 0.5
            end
        elseif v277 then
            v278 = 1 - p274.accuracy.Value * 0.35
        else
            v278 = 1 - p274.accuracy.Value
        end
        local v279 = CFrame.new(v_u_8.validate_position(game.Workspace.CurrentCamera.CFrame.Position, v276.Position, v275.values.ray_params)) * v276.Rotation
        local v280 = v277 and 0.25 or nil
        local v281 = {}
        for _ = 1, p274.states.pellets:get() do
            local v282 = v279.Position
            local v283 = v279.LookVector * 1000
            local v284 = p274.states.spread:get() * 100
            local v285 = v283 + v278 * get_circular_spread(v279, v284)
            if v280 then
                v282 = v282 - v279.LookVector * v280
            end
            if v277 then
                v285 = v285 - v285 * 0.8
            end
            local v286 = v_u_8.ray_damage(v282, v285, { v275.values.viewmodels, v275.instance }, v280)
            table.insert(v281, v286)
        end
        p274.states.shoot:fire(v276, v281)
    else
        p274.states.shoot:fire(v276)
    end
end
function v_u_3.send_melee(p287)
    p287.states.melee:fire_instant()
    local v288 = p287.owner.values.camera:get().CFrame
    if p287.client_sided_hitscan then
        local v289 = p287.owner
        local v290 = v288.Position - v288.LookVector * 0.2
        local v291 = v288.LookVector * 2.95
        local v292 = v_u_8.ray_damage(v290, v291, { v289.values.viewmodels, v289.instance }, 0.2)
        p287.states.hit:fire(v288, v292)
    else
        p287.states.hit:fire(v288)
    end
end
function v_u_3.input_ads(p293, p294, p295)
    p293.ads_hold = p294
    local v296 = p293.owner
    if not (p294 and v296.values.prone_debounce) then
        if v296 and (v296.values.equipped == p293 and not p293.meleeing) then
            p293.owner.states.running:set(false)
            if v_u_11.settings.toggle_aim and not p295 then
                if p294 then
                    p293.states.sights:update(function(p297)
                        return not p297
                    end)
                    v_u_9.get("CancelScope").Visible = p293.states.sights:get()
                    return
                end
            else
                p293.states.sights:set(p294)
            end
        end
    end
end
function v_u_3.input_shoot(p298, p299, p300)
    local v301 = p298.owner
    if v301 and (v301.values.equipped == p298 and (not p298.safety:get() or p298.accuracy.Value >= 1)) and not (v301.states.running:get() or v301.values.equip_debounce:get()) then
        local v302 = os.clock()
        local v303 = p298.states.firerate:get()
        if (p299 and (not p300 or p298.automatic) or not p299 and (p300 and (not p298.automatic and p298.shoot_hold))) and (v303 == 0 or v302 - p298.last_shot > 1 / (v303 / 60)) then
            if p298.states.mag:get() > 0 and p298.states.chambered:get() then
                p298.last_shot = v302
                p298:send_shoot()
            else
                p298:reload(v301, false)
            end
        end
    end
    if v_u_11.settings.auto_ads and (p300 or not v_u_9.get("ShootJoystickFrame").Visible) then
        if p299 and not p298.states.sights:get() then
            p298:input_ads(true, not v_u_11.settings.lock_auto_ads)
        elseif not (p299 or (v_u_9.get("CancelScope").Visible or v_u_11.settings.lock_auto_ads)) then
            p298:input_ads(false, true)
        end
    end
    p298.shoot_hold = p299
end
function v_u_3.hook_inputs(p_u_304)
    local v_u_305 = p_u_304.inputs
    p_u_304.owner.states.equipped:hook(function(p306)
        if p306 == p_u_304.instance then
            v_u_305.enabled:set(true)
        else
            v_u_305.enabled:set(false)
        end
    end)
    v_u_305.enabled:hook(function(p307)
        if p307 then
            v_u_9.get("CancelScope").Visible = false
            v_u_9.get("CancelShoot").Visible = false
        end
    end)
    v_u_305:get("shoot"):press(function(p308)
        if p308 and v_u_9.get("CancelShoot").Visible then
            p_u_304.shoot_hold = false
            p_u_304:input_shoot(false)
            v_u_9.get("CancelShoot").Visible = false
        else
            p_u_304:input_shoot(p308)
        end
    end)
    v_u_305:get("shoot_joystick"):press(function(p309)
        p_u_304:input_shoot(p309, true)
        local v310 = v_u_9.get("CancelShoot")
        local v311 = not p_u_304.automatic
        if v311 then
            v311 = p309 and true or false
        end
        v310.Visible = v311
    end)
    v_u_305:get("aim"):press(function(p312)
        p_u_304:input_ads(p312)
        if p_u_304.owner and (not p312 and v_u_4.current_device:get() == "console") then
            p_u_304.owner.states.lean:set(0)
        end
    end)
    v_u_305:get("reload"):press(function(p313)
        local v314 = p_u_304.owner
        if p313 and (v314 and (not p_u_304.reload_thread.running and (not v314.values.equip_debounce:get() and (not v314.values.prone_debounce and (v314.values.equipped == p_u_304 and (v314.states.vault:get() == 0 and (not v314.states.running:get() and p_u_304.states.bullets:get() > 0))))))) and p_u_304.states.mag:get() - (p_u_304.cylinder and 0 or 1) < p_u_304.states.mag_size:get() then
            p_u_304.states.sights:set(false)
            p_u_304.ads_hold = false
            local v315 = v314.values.holding
            if v315 and v315.can_reload == false then
                v314.states.holding:set(v314.values.hands)
                while v314.values.equip_debounce:get() or v314.values.holding == v315 do
                    v314.values.equip_debounce:wait()
                end
            end
            p_u_304.states.reload:fire()
        end
    end)
    v_u_13.setup_action(v_u_305, function()
        local v316 = not (p_u_304.reload_thread.running or p_u_304.cock_thread.running)
        if v316 then
            if p_u_304.states.mag:get() < p_u_304.states.mag_size:get() * 0.2 then
                v316 = p_u_304.states.bullets:get() > 0
            else
                v316 = false
            end
        end
        return v316
    end, "Reload", "reload")
end
function v_u_3.update_ui(p317)
    local v318 = ("%*/%*"):format(p317.states.mag:get(), (p317.states.bullets:get()))
    for _, v319 in p317.hooked_labels do
        v319.Text = v318
    end
end
function v_u_3.load()
    v_u_5.class(v_u_3.tag, function()
        local v320 = {
            ["loaded"] = v_u_6.new(true),
            ["mag_size"] = v_u_6.new(0),
            ["bullets"] = v_u_6.new(0),
            ["speed"] = v_u_6.new(1),
            ["sights"] = v_u_6.new(false),
            ["reload"] = v_u_7.new(),
            ["cock"] = v_u_7.new(),
            ["melee"] = v_u_7.new(),
            ["firerate"] = v_u_6.new(0),
            ["ads"] = v_u_6.new(0),
            ["reload_speed"] = v_u_6.new(1),
            ["recoil_up"] = v_u_6.new(1),
            ["recoil_side"] = v_u_6.new(0),
            ["trail_size"] = v_u_6.new(0),
            ["single_load"] = v_u_6.new(false),
            ["zoom"] = v_u_6.new(1),
            ["load_bullet"] = v_u_7.new(),
            ["shoot"] = v_u_7.new(),
            ["hit"] = v_u_7.new(),
            ["spread"] = v_u_6.new(1),
            ["pellets"] = v_u_6.new(1),
            ["accuracy"] = v_u_6.new(1),
            ["mag"] = v_u_6.new(0),
            ["chambered"] = v_u_6.new(true)
        }
        for _, v321 in v_u_10.attachment_types do
            v320[v321 .. "_att"] = v_u_6.new("")
        end
        return v320, {}
    end):hook(function(_) end)
end
return v_u_3
