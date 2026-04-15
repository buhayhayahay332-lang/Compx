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
		-- upvalues: (copy) v_u_17, (copy) v_u_2
		return v_u_17[p19] or v_u_2.anim[p19]
	end
})
v_u_3.sound = setmetatable({}, {
	["__index"] = function(_, p20)
		-- upvalues: (copy) v_u_18, (copy) v_u_2
		return v_u_18[p20] or v_u_2.sound[p20]
	end
})
function v_u_3.init(p_u_21)
	-- upvalues: (copy) v_u_8, (copy) v_u_6
	p_u_21.auto_shoot_dt = os.clock()
	p_u_21.last_shot = os.clock()
	p_u_21.shot = p_u_21:setup_shot(p_u_21.instance.Root:FindFirstChild("Shoot", true))
	p_u_21.reload_thread = v_u_8.ov(p_u_21.reload_begin)
	p_u_21.reload_thread:done(p_u_21.reload_done)
	p_u_21.reload_thread:cancelled(p_u_21.reload_cancel)
	p_u_21.cock_thread = v_u_8.ov(p_u_21.cock_begin)
	p_u_21.cock_thread:done(p_u_21.cock_done)
	p_u_21.cock_thread:cancelled(p_u_21.cock_cancel)
	p_u_21.recoil = v_u_8.ov(p_u_21.recoil_function)
	p_u_21.sights = v_u_8.ov(p_u_21.sights)
	p_u_21.sights:cancelled(function()
		-- upvalues: (copy) p_u_21
		p_u_21.owner.values.cframes:get("arm1"):remove_offset("sights")
		p_u_21.owner.values.cframes:get("arm2"):remove_offset("sights")
		p_u_21.cframes:get(p_u_21.instance.Root):remove_offset("sights")
	end)
	p_u_21.flash = v_u_8.ov(p_u_21.flash)
	p_u_21.safety_function = v_u_8.ov(p_u_21.safety_function)
	p_u_21.safety = v_u_6.new(nil)
	p_u_21:load_instance()
end
function v_u_3.flash(p22)
	p22.shot.Flash:Emit(3)
	p22.shot.Light.Enabled = true
	task.wait(0.05)
	p22.shot.Light.Enabled = false
end
function v_u_3.set_part_pivots(p_u_23)
	-- upvalues: (copy) v_u_8
	p_u_23.slide = p_u_23.instance:FindFirstChild("Slide")
	if p_u_23.slide then
		local v24 = p_u_23.cframes:get(p_u_23.slide, true)
		local v_u_25 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.slide:GetPivot())
		v24:set_pivot("general", function()
			-- upvalues: (copy) p_u_23, (copy) v_u_25
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
			-- upvalues: (copy) p_u_23, (copy) v_u_27
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
			-- upvalues: (copy) p_u_23, (copy) v_u_29
			return p_u_23.instance.Root.CFrame * v_u_29
		end)
	end
	p_u_23.feed_cover = p_u_23.instance:FindFirstChild("FeedCover")
	if p_u_23.feed_cover then
		local v30 = p_u_23.cframes:get(p_u_23.feed_cover, true)
		local v_u_31 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.feed_cover:GetPivot())
		v30:set_pivot("general", function()
			-- upvalues: (copy) p_u_23, (copy) v_u_31
			return p_u_23.instance.Root.CFrame * v_u_31
		end)
		v30:set_offset("reload")
	end
	p_u_23.end_bullet = p_u_23.instance:FindFirstChild("EndBullet")
	if p_u_23.end_bullet then
		local v32 = p_u_23.cframes:get(p_u_23.end_bullet, true)
		local v_u_33 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.end_bullet:GetPivot())
		v32:set_pivot("general", function()
			-- upvalues: (copy) p_u_23, (copy) v_u_33
			return p_u_23.instance.Root.CFrame * v_u_33
		end)
		v32:create_pivot("unloaded", function()
			-- upvalues: (copy) p_u_23
			return p_u_23.instance.Magazine.CFrame
		end)
	end
	p_u_23.cylinder = p_u_23.instance:FindFirstChild("Cylinder")
	if p_u_23.cylinder then
		local v34 = p_u_23.cframes:get(p_u_23.cylinder, true)
		local v_u_35 = p_u_23.instance.Root.CFrame:ToObjectSpace(p_u_23.cylinder:GetPivot())
		v34:set_pivot("general", function()
			-- upvalues: (copy) p_u_23, (copy) v_u_35
			return p_u_23.instance.Root.CFrame * v_u_35
		end)
		v34:set_offset("reload")
		if p_u_23.cylinder_loader then
			p_u_23.loader = p_u_23.cylinder_loader:Clone()
			p_u_23.cframes:get(p_u_23.loader.Case):set_pivot("general", function(_)
				-- upvalues: (copy) p_u_23
				return p_u_23.owner.values.viewmodels.arm2.CFrame * CFrame.new(0.2, -0.7, -0.4) * CFrame.Angles(-1.5707963267948966, 0.5235987755982988, 0) * CFrame.Angles(0, 0, -0.5235987755982988)
			end)
			p_u_23.cframes:get(p_u_23.loader.Case):create_pivot("reload", function(_)
				-- upvalues: (copy) p_u_23
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
			-- upvalues: (copy) p_u_23, (copy) v_u_37
			return p_u_23.instance.Root.CFrame * v_u_37
		end)
		v36:create_pivot("reload", function(_)
			-- upvalues: (copy) p_u_23
			return p_u_23.owner.values.viewmodels.arm2:GetPivot() * p_u_23.magazine_hold_offset
		end)
	end
end
function v_u_3.update_sight_lens(p38, p39)
	-- upvalues: (copy) v_u_8, (copy) v_u_9
	local v40 = p38.states.ads:get()
	if p39 then
		local v41 = workspace.CurrentCamera
		v_u_8.tween(v41, TweenInfo.new(v40, Enum.EasingStyle.Linear), {
			["FieldOfView"] = v41:GetAttribute("OriginalFOV") / p38.states.zoom:get()
		})
		v_u_8.tween(v_u_9.get("RedDot").UIStroke, TweenInfo.new(0.3), {
			["Transparency"] = 1
		})
		local v42 = p38.instance:FindFirstChild("ScopePart", true)
		if v42 then
			v42:SetAttribute("OriginalMaterial", v42.Material.Name)
			if v42.Material ~= Enum.Material.Neon then
				v42.Material = Enum.Material.Glass
			end
			v42:SetAttribute("PreviousScopeTransparency", v42.Transparency)
			local v43 = v42.Transparency
			v42.Transparency = math.max(0.011, v43)
		end
		local v44 = p38.instance:FindFirstChild("ScopeTint", true)
		if v44 then
			v44.Transparency = v42 == nil and 0.8 or 0.3
		end
		v_u_9.hook_world_billboards("sights", function(p45)
			-- upvalues: (ref) v_u_8
			v_u_8.tween(p45, TweenInfo.new(0.1), {
				["GroupTransparency"] = 0.7,
				["Size"] = UDim2.fromScale(0.9, 0.9)
			})
		end)
	else
		local v46 = workspace.CurrentCamera
		v_u_8.tween(v46, TweenInfo.new(v40, Enum.EasingStyle.Linear), {
			["FieldOfView"] = v46:GetAttribute("OriginalFOV")
		})
		v_u_8.tween(v_u_9.get("RedDot").UIStroke, TweenInfo.new(0.3), {
			["Transparency"] = 0.5
		})
		local v47 = p38.instance:FindFirstChild("ScopePart", true)
		if v47 and v47:GetAttribute("OriginalMaterial") then
			v47.Material = Enum.Material[v47:GetAttribute("OriginalMaterial")]
			v47.Transparency = v47:GetAttribute("PreviousScopeTransparency") or 0
		end
		local v48 = p38.instance:FindFirstChild("ScopeTint", true)
		if v48 then
			v48.Transparency = 1
		end
		v_u_9.unhook_world_billboards("sights")
		for _, v49 in v_u_9.get_world_billboards() do
			v_u_8.tween(v49, TweenInfo.new(0.1), {
				["GroupTransparency"] = 0,
				["Size"] = UDim2.fromScale(1, 1)
			})
		end
	end
end
function v_u_3.hook_states(p_u_50)
	-- upvalues: (copy) v_u_10, (copy) v_u_12, (copy) v_u_15, (copy) v_u_8, (copy) v_u_9
	p_u_50.offsets = {}
	p_u_50.states.mag:hook(function(_)
		-- upvalues: (copy) p_u_50
		p_u_50:update_ui()
	end)
	p_u_50.states.bullets:hook(function(_)
		-- upvalues: (copy) p_u_50
		p_u_50:update_ui()
	end)
	p_u_50.accuracy = Instance.new("NumberValue")
	p_u_50.states.sights:hook(function(p51, p52)
		-- upvalues: (copy) p_u_50
		if p51 ~= p52 then
			if p_u_50.owner then
				p_u_50:sights(p_u_50.owner, p51)
			end
		end
	end)
	p_u_50.states.sights:hook(function(p53, p54)
		-- upvalues: (copy) p_u_50
		if p53 ~= p54 then
			if p_u_50.owner.values.camera:get() then
				p_u_50:update_sight_lens(p53)
			end
		end
	end)
	p_u_50.states.reload:hook_paused(function(p55, p56)
		-- upvalues: (copy) p_u_50
		if p55 ~= p56 then
			if p_u_50.owner then
				p_u_50:reload(p_u_50.owner, false)
			end
		end
	end)
	p_u_50.states.reload:hook(function()
		-- upvalues: (copy) p_u_50
		if p_u_50.owner then
			p_u_50:reload(p_u_50.owner, true)
		end
	end)
	p_u_50.states.accuracy:hook(function(_)
		-- upvalues: (copy) p_u_50
		if p_u_50.accuracy then
			p_u_50.accuracy.Value = p_u_50.states.accuracy:get() - 1
		end
	end)
	p_u_50.states.cock:hook(function()
		-- upvalues: (copy) p_u_50
		if p_u_50.owner then
			p_u_50:cock(p_u_50.owner, true)
		end
	end)
	p_u_50.states.melee:hook(function()
		-- upvalues: (copy) p_u_50
		if p_u_50.owner then
			p_u_50:melee(p_u_50.owner)
		end
	end)
	p_u_50.states.shoot:hook(function(p57, p58)
		-- upvalues: (copy) p_u_50
		if p_u_50.owner then
			p_u_50:shoot(p_u_50.owner, p57, p58)
		end
	end)
	p_u_50.states.hit:hook(function(p59, p60)
		-- upvalues: (copy) p_u_50
		if p_u_50.owner then
			p_u_50:hit(p_u_50.owner, p59, p60)
		end
	end)
	p_u_50.states.loaded:hook(function(p61, p62)
		-- upvalues: (copy) p_u_50
		if p61 == p62 or not p_u_50.owner then
			return
		elseif p61 and (p62 == false and not p_u_50.states.single_load:get()) then
			local v63 = p_u_50.states.mag_size:get()
			local v64 = p_u_50.states.bullets
			local v_u_65 = math.min(v63, v64:get())
			p_u_50.states.mag:update(function(p66)
				-- upvalues: (copy) v_u_65
				return p66 + v_u_65
			end)
			p_u_50.states.bullets:update(function(p67)
				-- upvalues: (copy) v_u_65
				return p67 - v_u_65
			end)
		elseif p62 then
			local v68 = p_u_50.states.mag:get() - (p_u_50.instance:FindFirstChild("BulletEject", true) and 1 or 0)
			local v_u_69 = math.max(0, v68)
			p_u_50.states.mag:update(function(p70)
				-- upvalues: (copy) v_u_69
				return p70 - v_u_69
			end)
			p_u_50.states.bullets:update(function(p71)
				-- upvalues: (copy) v_u_69
				return p71 + v_u_69
			end)
		end
	end)
	p_u_50.states.load_bullet:hook(function()
		-- upvalues: (copy) p_u_50
		if p_u_50.owner and p_u_50.states.single_load:get() then
			p_u_50.states.mag:update(function(p72)
				return p72 + 1
			end)
			p_u_50.states.bullets:update(function(p73)
				return p73 - 1
			end)
		end
	end)
	p_u_50.states.chambered:hook(function(p74, p75)
		-- upvalues: (copy) p_u_50
		if p74 ~= p75 then
			if p_u_50.owner then
				p_u_50:chamber(p_u_50.owner, p74)
			end
		end
	end)
	for _, v76 in v_u_10.attachment_types do
		p_u_50.states[v76 .. "_att"]:hook(function(p77, p78)
			-- upvalues: (ref) v_u_12, (copy) p_u_50
			if p78 and (p78 ~= "" and p77 ~= p78) then
				v_u_12.get_item_class(p78):remove(p_u_50)
			end
			if p77 and p77 ~= "" then
				v_u_12.get_item_class(p77):apply(p_u_50)
			end
		end)
	end
	p_u_50.safety:hook(function(p79, p80)
		-- upvalues: (copy) p_u_50
		if p_u_50.owner then
			p_u_50:safety_function(p_u_50.owner, p79, p80)
		end
	end)
	local v_u_81 = v_u_15.new()
	p_u_50.object:destroying(function()
		-- upvalues: (copy) v_u_81
		v_u_81:clean()
	end)
	v_u_81:add(p_u_50.owner.values.camera:hook(function(p82, p83)
		-- upvalues: (copy) p_u_50
		if p_u_50.states.sights:get() then
			if p82 then
				p_u_50:update_sight_lens(true)
			elseif p83 then
				p_u_50:update_sight_lens(false)
			end
		else
			return
		end
	end).unhook)
	v_u_81:add(p_u_50.owner.values.camera:hook(function(p84, p85)
		-- upvalues: (copy) p_u_50, (ref) v_u_8, (ref) v_u_9
		if p_u_50.states.sights:get() then
			if p84 == game.Workspace.CurrentCamera then
				v_u_8.tween(v_u_9.get("RedDot").UIStroke, TweenInfo.new(0), {
					["Transparency"] = 1
				})
				local v86 = workspace.CurrentCamera
				v_u_8.tween(v86, TweenInfo.new(0, Enum.EasingStyle.Linear), {
					["FieldOfView"] = v86:GetAttribute("OriginalFOV") / p_u_50.states.zoom:get()
				})
				return
			end
			if p84 == nil and p85 == game.Workspace.CurrentCamera then
				local v87 = workspace.CurrentCamera
				v_u_8.tween(v87, TweenInfo.new(0, Enum.EasingStyle.Linear), {
					["FieldOfView"] = v87:GetAttribute("OriginalFOV")
				})
			end
		end
	end))
end
function v_u_3.running(p88, p89, p90)
	local v91 = p89.values.cframes:get("arms"):get_offset("run")
	if p90 then
		p88:running_pivots(p89, true)
		p88.states.sights:set(false)
		p88:reload(p89, false)
		p89.values.cframes:get("arms"):set_offset("run")
		p88.anim.Run.run_offset(v91)
	else
		p88:running_pivots(p89, false)
		p88.anim.Run.base(v91).Completed:Wait()
		p89.values.cframes:get("arms"):remove_offset("run")
	end
end
function v_u_3.walk_state(p92, p93, p94, p95)
	if p94 == "prone" or p95 == "prone" then
		p92:reload(p93, false)
		p92:cock(p93, false)
	end
end
function v_u_3.vault(p96, p97, p98)
	if p98 > 0 then
		p96:reload(p97, false)
		p96:cock(p97, false)
	end
end
function v_u_3.sights(p99, p100, p101)
	-- upvalues: (copy) v_u_11, (copy) v_u_4, (copy) v_u_8, (copy) v_u_9
	p99.sound.Handle(p99.instance.Root)
	local v102 = p100.values.cframes:get("arm1"):get_offset("sights")
	local v103 = p100.values.cframes:get("arm2"):get_offset("sights")
	local v104 = p99.cframes:get(p99.instance.Root):get_offset("sights")
	local v105 = p99.states.ads:get()
	if p101 then
		local v106 = false
		if p100.values.holding and p100.values.holding.safety then
			if p100.values.holding.states.ads then
				v105 = v105 + p100.values.holding.states.ads:get()
			end
			if p100.states.holding:get() == p100.values.holding.instance then
				p100.values.holding.safety:set(true)
				v106 = true
			end
		end
		p99:reload(p100, false)
		p100.values.cframes:get("arm1"):set_offset("sights")
		if not v106 then
			p100.values.cframes:get("arm2"):set_offset("sights")
		end
		p99.anim.Equip.arm1_hold(p100.values.cframes:get("arm1"):set_absolute("sights", true), p99, v105)
		p99.cframes:get(p99.instance.Root):set_offset("sights")
		p99.anim.Sight.arm1(v102, p99.instance, v105)
		p99.anim.Sight.arm2(v103, p99.instance, v105)
		p99.anim.Sight.gun(v104, p99.instance, v105)
		if p100.values.camera:get() then
			if p99.inputs and p99.inputs.enabled:get() then
				local v107 = string.gsub
				local v108 = p99.states.zoom
				local v109 = ("camera_sensitivity_%*"):format((v107(tostring(v108:get()), "[.]", "_")))
				if v_u_11.settings[v109] then
					v_u_4.mouse_base_sensitivity:set(v_u_8.map_sensitivity(v_u_11.settings[v109]))
					local v_u_110 = nil
					v_u_110 = p99.states.sights:hook(function(p111)
						-- upvalues: (ref) v_u_4, (ref) v_u_8, (ref) v_u_11, (ref) v_u_110
						if not p111 then
							v_u_4.mouse_base_sensitivity:set(v_u_8.map_sensitivity(v_u_11.settings.camera_sensitivity))
							v_u_110.unhook()
						end
					end)
				end
			end
			v_u_8.tween(p99.accuracy, TweenInfo.new(v105, Enum.EasingStyle.Linear), {
				["Value"] = 1
			})
			return
		end
	else
		p100.values.cframes:get("arm1"):remove_absolute("sights")
		if p100.values.holding and (p100.values.holding.safety and not p100.values.equip_debounce:get()) then
			p100.values.holding.safety:set(false)
			if p100.values.holding.states.ads then
				v105 = v105 + p100.values.holding.states.ads:get()
			end
		end
		if p100.values.camera:get() then
			v_u_8.tween(p99.accuracy, TweenInfo.new(v105, Enum.EasingStyle.Linear), {
				["Value"] = p99.states.accuracy:get() - 1
			})
		end
		if p99.inputs and p99.inputs.enabled:get() then
			v_u_9.get("CancelScope").Visible = false
		end
		p99.anim.Sight.base(v102, p99.instance, v105)
		p99.anim.Sight.base(v103, p99.instance, v105)
		p99.anim.Sight.base(v104, p99.instance, v105).Completed:Wait()
		p100.values.cframes:get("arm1"):remove_offset("sights")
		p100.values.cframes:get("arm2"):remove_offset("sights")
		p99.cframes:get(p99.instance.Root):remove_offset("sights")
	end
end
function v_u_3.reload(p112, p113, p114)
	if p114 then
		p112.reload_thread(p112, p113, p114)
	else
		p112.reload_thread:cancel(p112, p113, p114)
	end
end
function v_u_3.cock(p115, p116, p117)
	if p117 then
		p115:reload(p116, false)
		p115.cock_thread(p115, p116, p117)
	else
		p115.cock_thread:cancel(p115, p116, p117)
	end
end
function v_u_3.chamber(p118, _, p119)
	if p118.slide then
		local v120 = p118.cframes:get(p118.slide):get_offset("shoot")
		if p119 then
			p118.anim.Gun.slide_off(v120)
		else
			p118.anim.Gun.slide_on(v120).Completed:Wait()
		end
	end
	if not p118.states.single_load:get() then
		if p119 then
			p118.sound.Reload4(p118.instance.Root)
			return
		end
		p118.sound.Empty(p118.instance.Root)
	end
end
function v_u_3.render(p121, p122, p123)
	p121.instance.Root:PivotTo(p121.cframes:get(p121.instance.Root):render(p123))
	if p121.hammer then
		p121.hammer:PivotTo(p121.cframes:get(p121.hammer):render(p123))
	end
	if p121.feed_cover then
		p121.feed_cover:PivotTo(p121.cframes:get(p121.feed_cover):render(p123))
	end
	if p121.slide then
		p121.slide:PivotTo(p121.cframes:get(p121.slide):render(p123))
	end
	if p121.load_slide then
		p121.load_slide:PivotTo(p121.cframes:get(p121.load_slide):render(p123))
	end
	if p121.magazine then
		p121.magazine:PivotTo(p121.cframes:get(p121.magazine):render(p123))
	elseif p121.cylinder then
		p121.cylinder:PivotTo(p121.cframes:get(p121.cylinder):render(p123))
		if p121.loader and p121.loader.Parent == p122.values.viewmodels then
			p121.loader.Case:PivotTo(p121.cframes:get(p121.loader.Case):render(p123))
		end
	end
	if p121.end_bullet then
		p121.end_bullet:PivotTo(p121.cframes:get(p121.end_bullet):render(p123))
	end
	if p121.charm_model and p121.charm_model.PrimaryPart then
		p121.charm_model.PrimaryPart:PivotTo(p121.cframes:get(p121.charm_model.PrimaryPart):render(p123))
	end
	if p121.inputs and p121.inputs.enabled:get() then
		p121:input_render(p123)
	end
end
function v_u_3.auto_shoot_check(p124, _)
	-- upvalues: (copy) v_u_9, (copy) v_u_8, (copy) v_u_5
	local v125 = os.clock()
	if v125 - p124.auto_shoot_dt > 0.25 then
		p124.auto_shoot_dt = v125
		if v_u_9.get("Flash").Frame.BackgroundTransparency == 0 then
			return
		end
		local v126 = p124.owner
		local v127 = p124:get_shoot_look()
		local v128 = CFrame.new(v_u_8.validate_position(game.Workspace.CurrentCamera.CFrame.Position, v127.Position, v126.values.ray_params)) * v127.Rotation
		for _, v129 in p124:ray_damage(v128.Position, v128.LookVector * 500, { v126.values.viewmodels, v126.instance }, nil, true) do
			local v130 = v129.Instance
			if v129.HitHum then
				p124:input_shoot(true)
				return
			end
			if v130 and v130.Transparency < 1 then
				local v131 = v_u_8.get_breakable_instance(v130)
				if v131 and v_u_8.ownership(v_u_5.get("Breakable", v131).owner:get()) == 0 then
					p124:input_shoot(true)
					return
				end
			end
		end
		if p124.shoot_hold and not (p124.inputs:get("shoot"):holding() or p124.inputs:get("shoot_joystick"):holding()) then
			p124:input_shoot(false)
		end
	end
end
function v_u_3.input_render(p132, _)
	-- upvalues: (copy) v_u_11
	local v133 = p132.owner
	if v133.values.prone_debounce or v133.values.equip_debounce:get() then
		p132:reload(v133, false)
		p132:cock(v133, false)
	elseif not p132.cock_thread.running and (not p132.reload_thread.running and (not p132.states.chambered:get() and (not v133.values.equip_debounce:get() and (not p132.states.reload:get() and (v133.states.vault:get() == 0 and (p132.states.loaded:get() and p132.states.mag:get() > 0)))))) then
		p132.states.cock:fire_instant()
	end
	local _ = v133.values.viewmodels.head
	if not v_u_11.settings.toggle_aim then
		if p132.ads_hold and not (p132.reload_thread.running or (p132.meleeing or (v133.states.running:get() or (v133.values.prone_debounce or v133.values.equip_debounce:get())))) then
			p132.states.sights:set(true)
		else
			p132.states.sights:set(false)
		end
	end
	if p132.automatic and (p132.shoot_hold and (not p132.safety:get() or p132.accuracy.Value >= 1)) and not (v133.values.equip_debounce:get() or v133.states.running:get()) then
		local v134 = os.clock()
		local v135 = p132.states.firerate:get()
		if (v135 == 0 or v134 - p132.last_shot > 1 / (v135 / 60)) and (p132.states.mag:get() > 0 and p132.states.chambered:get()) then
			p132.last_shot = v134
			p132:send_shoot()
		end
	end
	if p132.states.reload:get() and v133.values.equip_debounce:get() then
		p132:reload(v133, false)
	end
end
function v_u_3.kickback(p136, p137)
	local v138 = p137.values.cframes:get("arms"):set_offset("shoot")
	p136.anim.Shoot.key1(v138).Completed:Wait()
	p136.anim.Shoot.key2(v138).Completed:Wait()
	p136.anim.Shoot.key3(v138).Completed:Wait()
	p137.values.cframes:get("arms"):remove_offset("shoot")
end
function v_u_3.recoil_function(p139, p140)
	-- upvalues: (copy) v_u_4, (copy) v_u_8
	p140.values.cframes:get("camera"):remove_offset("shoot")
	local v141 = p140.values.cframes:get("camera"):set_offset("shoot")
	local v142 = v141.Value
	if p140.values.camera:get() then
		local v143 = p140.values
		v143.old_cam_render = v143.old_cam_render * v142:Inverse()
	end
	local v144 = p139.states.recoil_up:get()
	local v145 = p139.states.recoil_side:get()
	if v_u_4.current_device:get() ~= "pc" then
		v144 = v144 * 0.7
		v145 = v145 * 0.7
	end
	if p139.prone_recoil and p140.states.walk_state:get() == "prone" then
		v144 = v144 * p139.prone_recoil
		v145 = v145 * p139.prone_recoil
	end
	v_u_8.tween(v141, TweenInfo.new(0), {
		["Value"] = CFrame.new()
	})
	v141.Value = CFrame.new()
	if p140.values.cframes:get("arm2"):current_pivot() == "equipped" then
		v144 = v144 * 0.8
	end
	local v146 = CFrame.Angles
	local v147 = math.random() * v144 + v144
	local v148 = math.rad(v147)
	local v149 = math.random() * (v145 * 2) - v145
	local v150 = v146(v148, math.rad(v149), 0)
	local v151 = (v144 * 2 + v145) / 40
	local v152 = math.exp(v151)
	v_u_8.tween(v141, TweenInfo.new(v152 * 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		["Value"] = v150
	}).Completed:Wait()
	v_u_8.tween(v141, TweenInfo.new(v152 * 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		["Value"] = CFrame.new()
	}).Completed:Wait()
end
function v_u_3.shoot(p_u_153, p_u_154, _, p155)
	p_u_153.states.mag:update(function(p156)
		local v157 = p156 - 1
		return math.max(0, v157)
	end)
	if p_u_153.states.firerate:get() == 0 then
		p_u_153.states.chambered:set(false)
	else
		local v158 = p_u_153.instance:FindFirstChild("BulletEject", true)
		if v158 then
			p_u_153:eject_bullet(v158, p_u_153.bullet_type)
		end
	end
	if p_u_153.supressed then
		p_u_153.sound.SilencedShoot(p_u_153.shot)
	else
		p_u_153.sound.Shoot(p_u_153.shot)
	end
	p_u_153:reload(p_u_154, false)
	local v159 = p_u_153.states.pellets:get() > 1
	if p_u_153.owner.values.camera:get() == nil and (not v159 and (p155 and #p155 > 0)) then
		for _, v160 in p155 do
			if #v160 > 0 then
				p_u_153:trail(p_u_153.shot.CFrame.Position, v160[#v160].Position)
			end
		end
	end
	task.spawn(function()
		-- upvalues: (copy) p_u_153, (copy) p_u_154
		p_u_153:kickback(p_u_154)
	end)
	if p_u_154.values.camera:get() then
		p_u_153.recoil(p_u_153, p_u_154)
	end
	task.spawn(function()
		-- upvalues: (copy) p_u_153
		local v161 = p_u_153.shot:FindFirstChild("Smoke")
		if v161 then
			for _ = 1, 3 do
				v161:Emit(1)
				task.wait(0.1)
			end
		end
	end)
	if p_u_153.shot:FindFirstChild("Flash") then
		p_u_153:flash()
	end
	if p_u_153.states.firerate:get() > 0 then
		task.spawn(p_u_153.slide_shoot, p_u_153)
	end
	if p_u_153.hammer then
		task.spawn(function()
			-- upvalues: (copy) p_u_153
			local v162 = p_u_153.cframes:get(p_u_153.hammer):set_offset("shoot")
			p_u_153.anim.Gun.hammer_on(v162).Completed:Wait()
			p_u_153.anim.Gun.hammer_off(v162).Completed:Wait()
			p_u_153.cframes:get(p_u_153.hammer):remove_offset("shoot")
		end)
	end
	if p155 then
		p_u_153:bullet_hit(p_u_154, p155)
	end
end
function v_u_3.bullet_hit(p163, _, p164)
	-- upvalues: (copy) v_u_8, (copy) v_u_16, (copy) v_u_15, (copy) v_u_5
	for _, v165 in p164 do
		if #v165 ~= 0 then
			local v166 = {}
			for _, v167 in v165 do
				local v168 = v167.Instance
				if v168 ~= nil then
					if v168:HasTag("Water") and not v168.CanCollide then
						local v169 = v167.Position
						local v170 = Instance.new("Attachment")
						v_u_8.debris(v170, 2)
						local v171 = v168.Size.X
						local v172 = v168.Size.Y
						local v173 = v168.Size.Z
						local v174 = math.min(v171, v172, v173)
						v170.WorldCFrame = CFrame.new(v169.X, v168.CFrame.Y + v174 * 0.5, v169.Z)
						v170.Parent = game.Workspace.Terrain
						v_u_16.Ring(v170)
						v_u_16.Splash(v170, 3, v168)
						v_u_16.WaterSplash(v170)
					elseif v167.HitHum and not v166[v168.Parent] then
						v166[v168.Parent] = true
						local v175 = Instance.new("Attachment")
						v175.Parent = game.Workspace.Terrain
						v175.WorldCFrame = CFrame.new(v167.Position) * CFrame.lookAt(Vector3.new(0, 0, 0), v167.Normal)
						v_u_8.debris(v175, 1)
						p163:emit_blood(v175)
						p163.sound.BulletHit(v175)
					end
				end
			end
			local v176 = v165[#v165]
			if v176 then
				local v177 = v176.Instance
				local v178 = v176.Normal
				local v179 = v176.Position
				if not v176.HitHum and (v177 and (v177.Transparency < 1 and v177.Anchored)) then
					local v_u_180 = v_u_16.create_point(v179, v178, math.random(8, 12))
					local v_u_181 = v_u_8.get_breakable_instance(v177)
					if v_u_181 then
						local v_u_182 = v_u_15.new()
						v_u_182:add(v_u_5.get("Breakable", v_u_181).states.destroyed:hook(function(p183)
							-- upvalues: (copy) v_u_180
							if p183 then
								task.defer(function()
									-- upvalues: (ref) v_u_180
									v_u_180:Destroy()
								end)
							end
						end).unhook)
						v_u_182:add(v_u_181.AncestryChanged:Connect(function()
							-- upvalues: (copy) v_u_181, (copy) v_u_180
							if v_u_181.Parent == nil or v_u_181.Parent == game.ReplicatedStorage.Garbage then
								task.defer(function()
									-- upvalues: (ref) v_u_180
									v_u_180:Destroy()
								end)
							end
						end))
						v_u_180.Destroying:Connect(function()
							-- upvalues: (copy) v_u_182
							v_u_182:clean()
						end)
					end
					local v184 = script.BulletHoles.Normal:Clone()
					v184.Parent = v_u_180
					v184.Color = ColorSequence.new(v177.Color)
					v184:Emit(2)
				end
			end
		end
	end
end
function v_u_3.slide_shoot(p185)
	if p185.slide then
		local v186 = p185.cframes:get(p185.slide):get_offset("shoot")
		p185.anim.Gun.slide_on(v186).Completed:Wait()
		if p185.states.mag:get() > 0 then
			p185.anim.Gun.slide_off(v186).Completed:Wait()
		end
		if p185.states.mag:get() == 0 then
			p185.states.chambered:set(false)
			return
		end
	elseif p185.load_slide then
		local v187 = p185.cframes:get(p185.load_slide):get_offset("shoot")
		p185.anim.Gun.slide_on(v187).Completed:Wait()
		p185.anim.Gun.slide_off(v187).Completed:Wait()
		if p185.states.mag:get() == 0 then
			p185.states.chambered:set(false)
		end
	end
end
function v_u_3.melee(p188, p189, _)
	p188:reload(p189, false)
	p188:cock(p189, false)
	p188.meleeing = true
	local v190 = p189.values.cframes:get("arm1"):set_absolute("melee", true)
	local v191 = nil
	if p188.anim.Melee.arm2_hold then
		local v192 = p189.values.cframes:get("arm2"):set_absolute("melee", true)
		p188.anim.Melee.arm2_hold(v192)
	else
		p189.values.cframes:get("arm2"):set_absolute("melee", CFrame.new())
		p189.values.cframes:get("arm2"):set_pivot("base")
	end
	if p188.anim.Melee.gun_hold then
		v191 = p188.cframes:get(p188.instance.Root):set_absolute("melee", true)
		p188.anim.Melee.gun_hold(v191)
	end
	p188.sound.Handle(p188.instance.Root)
	p188.anim.Melee.arm1_hold(v190).Completed:Wait()
	p189.values.cframes:get("arm1"):remove_absolute("melee")
	p189.values.cframes:get("arm2"):remove_absolute("melee")
	if not p188.anim.Melee.arm2_hold then
		p189.values.cframes:get("arm2"):remove_pivot("base")
	end
	if v191 then
		p188.cframes:get(p188.instance.Root):remove_absolute("melee")
	end
end
function v_u_3.hit(p193, p194, p195, p196)
	local v197 = p194.values.cframes:get("arm1"):set_absolute("melee")
	local v198 = nil
	local v199
	if p193.anim.Melee.arm2_hit then
		v199 = p194.values.cframes:get("arm2"):set_absolute("melee")
	else
		v199 = nil
	end
	if p193.anim.Melee.gun_hit then
		v198 = p193.cframes:get(p193.instance.Root):set_absolute("melee")
	end
	if p193:process_hit_results(p195, p196) then
		p193.sound.Swing(p193.instance.Root)
		if v198 then
			p193.anim.Melee.gun_miss(v198)
		end
		if v199 then
			p193.anim.Melee.arm2_miss(v199)
		end
		p193.anim.Melee.arm1_miss(v197).Completed:Wait()
	else
		if v198 then
			p193.anim.Melee.gun_hit(v198)
		end
		if v199 then
			p193.anim.Melee.arm2_hit(v199)
		end
		p193.anim.Melee.arm1_hit(v197).Completed:Wait()
	end
	p194.values.cframes:get("arm1"):remove_absolute("melee")
	if v199 then
		p194.values.cframes:get("arm2"):remove_absolute("melee")
	end
	if v198 then
		p193.cframes:get(p193.instance.Root):remove_absolute("melee")
	end
	p193.meleeing = false
end
function v_u_3.safety_function(p200, p201, p202, p203)
	local v204 = p201.values.cframes:get("arm1"):get_absolute("equipped")
	local v205 = p201.values.cframes:get("arm2"):get_absolute("equipped")
	if p202 == true then
		p200.anim.Equip.arm1_hold_safety(v204)
		if p203 == false then
			p201.values.cframes:get("arm2"):remove_pivot("equipped")
			p201.values.cframes:get("arm2"):remove_absolute("equipped")
			return
		end
	elseif p202 == false then
		p201.values.cframes:get("arm2"):set_absolute("equipped", true)
		p201.values.cframes:get("arm2"):set_pivot("equipped")
		p200.anim.Equip.arm2_hold(v205, p200)
		p200.anim.Equip.arm1_hold(v204, p200).Completed:Wait()
	end
end
function v_u_3.equip(p206, p207, p208)
	local v209 = p207.values.cframes:get("arm1"):get_absolute("equipped")
	p207.values.cframes:get("arm2"):get_absolute("equipped")
	local v210 = p206.instance:FindFirstChild("Root")
	if v210 == nil then
		return
	elseif p208 == true then
		p206:unholster(p207)
		p207.values.cframes:get("arm1"):set_absolute("equipped", true)
		p206.anim.Equip.arm1_grab(v209).Completed:Wait()
		p206.sound.Equip(v210)
		p206.cframes:get(v210):set_pivot("equipped")
		p206.cframes:get(v210).pivot_time = 0.2
		p207.values.cframes:get("arm1"):set_pivot("equipped")
		local v211 = p206.safety
		local v212 = p207.values.holding
		if v212 then
			if p207.states.holding:get() == p207.values.holding.instance then
				v212 = p207.values.holding.loadout_type == "primary"
			else
				v212 = false
			end
		end
		v211:set_instant(v212)
	else
		p206.states.sights:set(false)
		p206:reload(p207, false)
		p206:cock(p207, false)
		p206.sound.Handle(v210)
		p207.values.cframes:get("arm1"):remove_pivot("equipped")
		if p206.safety:get() == false then
			p207.values.cframes:get("arm2"):remove_pivot("equipped")
			p207.values.cframes:get("arm2"):remove_absolute("equipped")
		end
		p206.safety:set_instant(nil)
		if p207.values.holding and p207.values.holding.safety then
			p207.values.holding.safety:set(false)
		end
		p206.anim.Equip.arm1_grab(v209).Completed:Wait()
		p206.cframes:get(v210).pivot_time = 0.2
		p206.cframes:get(v210):remove_pivot("equipped")
		p207.values.cframes:get("arm1"):remove_absolute("equipped")
		p206:holster(p207)
	end
end
function v_u_3.trail(p213, p214, p215, _)
	-- upvalues: (copy) v_u_8
	local v216 = Instance.new("Attachment")
	local v217 = Instance.new("Attachment")
	v_u_8.debris(v216, 0.5)
	v_u_8.debris(v217, 0.5)
	v216.Parent = workspace.Terrain
	v217.Parent = workspace.Terrain
	v216.Position = p214
	v217.Position = p215
	local v218 = Instance.new("Beam", game.Workspace)
	v_u_8.debris(v218, 0.5)
	v218.Width0 = p213.states.trail_size:get() or 0.1
	v218.Width1 = p213.states.trail_size:get() or 0.1
	v218.Attachment0 = v216
	v218.Attachment1 = v217
	if p213.supressed then
		v218.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.95) })
	else
		v218.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.75) })
	end
	v_u_8.tween(v218, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0), {
		["Width0"] = 0,
		["Width1"] = 0
	})
	if p213.owner.values.camera:get() == nil then
		local v219 = Instance.new("Attachment")
		v_u_8.debris(v219, 0.5)
		v219.Parent = workspace.Terrain
		v219.WorldCFrame = CFrame.new(v_u_8.closest_point_on_segment(game.Workspace.CurrentCamera.CFrame.Position, v216.WorldCFrame.Position, v217.WorldCFrame.Position))
		local v220 = (p214 - p215).Magnitude
		local v221 = p213.sound.BulletWoosh(v219)
		local v222 = v220 / 50
		v221.Volume = math.min(1, v222) * 0.5
	end
end
function v_u_3.eject_bullet(_, p223, p224)
	-- upvalues: (copy) v_u_16
	local v225 = script.Bullets[p224]:Clone()
	v225.Parent = workspace
	v225.CanCollide = true
	v225:PivotTo(p223.WorldCFrame)
	v225:ApplyImpulse(p223.WorldCFrame.RightVector * (math.random(8, 12) * v225.Mass) + p223.WorldCFrame.UpVector * (math.random(8, 12) * v225.Mass))
	v_u_16.mark_prop(v225)
	return v225
end
function v_u_3.setup_shot(_, p226)
	-- upvalues: (copy) v_u_8
	local v227 = script.Shot:Clone()
	v227.Flash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.3) })
	v227.Parent = p226.Parent
	v227.CFrame = p226.WorldCFrame
	v_u_8.weld_c(v227, p226.Parent)
	return v227
end
function v_u_3.reload_begin(p_u_228, p_u_229)
	-- upvalues: (copy) v_u_8
	p_u_228.sound.Handle(p_u_228.instance.Root)
	p_u_228.safety:set(false)
	local v230 = p_u_229.values.cframes:get("arm1"):set_absolute("reload", true)
	local v231 = p_u_229.values.cframes:get("arm2"):set_absolute("reload", true)
	local v232 = p_u_228.cframes:get(p_u_228.instance.Root):set_absolute("reload", true)
	local v233 = p_u_228.states.reload_speed:get()
	if p_u_228.feed_cover then
		p_u_228.anim.Reload.arm2_empty1(v231, v233)
		p_u_228.anim.Reload.gun_empty1(v232, v233)
		p_u_228.anim.Reload.arm1_empty1(v230, v233).Completed:Wait()
		local v234 = p_u_228.cframes:get(p_u_228.feed_cover):get_offset("reload")
		p_u_228.sound.FeedOpen(p_u_228.instance.Root)
		v_u_8.tween(v234, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			["Value"] = CFrame.Angles(0, -0.5235987755982988, 0)
		})
		p_u_228.anim.Reload.arm2_empty2(v231, v233).Completed:Wait()
		if p_u_228.states.loaded:get() and not p_u_228.states.single_load:get() then
			p_u_228.anim.Reload.arm1_start(v230, v233)
			p_u_228.anim.Reload.gun(v232, v233)
			p_u_228.anim.Reload.arm2_start(v231, v233).Completed:Wait()
			if p_u_228.magazine then
				if p_u_228.end_bullet then
					p_u_228.cframes:get(p_u_228.end_bullet):set_pivot("unloaded")
				end
				p_u_228.cframes:get(p_u_228.magazine):set_pivot("reload")
				p_u_228.sound.Reload1(p_u_228.instance.Root)
				p_u_228.states.loaded:set(false)
			end
		else
			p_u_228.anim.Reload.gun(v232, v233)
		end
	elseif p_u_228.cylinder then
		p_u_228.anim.Reload.arm1_start(v230, v233)
		p_u_228.anim.Reload.gun(v232, v233)
		p_u_228.anim.Reload.arm2_start(v231, v233).Completed:Wait()
		local v235 = p_u_228.cframes:get(p_u_228.cylinder):get_offset("reload")
		p_u_228.sound.Reload1(p_u_228.instance.Root)
		p_u_228.anim.Reload.cylinder_open(v235, v233)
		if p_u_228.states.loaded:get() then
			if p_u_228.anim.Reload.arm1_empty1 then
				p_u_228.anim.Reload.arm2_empty1(v231, v233)
				p_u_228.anim.Reload.arm1_empty1(v230, v233).Completed:Wait()
			end
			local v236 = false
			for _ = 1, p_u_228.states.mag_size:get() do
				if p_u_228:eject_bullet(p_u_228.cylinder.Eject, p_u_228.bullet_type, CFrame.Angles(0, 1.5707963267948966, 1.5707963267948966)) == nil then
					v236 = false
				else
					v236 = true
				end
			end
			if v236 then
				p_u_228.sound.Cases(p_u_228.instance.Root)
			end
			p_u_228.states.loaded:set(false)
			if p_u_228.anim.Reload.arm1_empty2 then
				p_u_228.anim.Reload.arm2_empty2(v231, v233)
				p_u_228.anim.Reload.arm1_empty2(v230, v233).Completed:Wait()
			end
		end
	elseif p_u_228.states.loaded:get() and not p_u_228.states.single_load:get() then
		p_u_228:cock(p_u_229, false)
		p_u_228.anim.Reload.arm1_start(v230, v233)
		p_u_228.anim.Reload.gun(v232, v233)
		p_u_228.anim.Reload.arm2_start(v231, v233).Completed:Wait()
		if p_u_228.magazine then
			if p_u_228.end_bullet then
				p_u_228.cframes:get(p_u_228.end_bullet):set_pivot("unloaded")
			end
			p_u_228.cframes:get(p_u_228.magazine):set_pivot("reload")
			p_u_228.sound.Reload1(p_u_228.instance.Root)
			p_u_228.states.loaded:set(false)
		end
	else
		p_u_228.anim.Reload.gun(v232, v233)
	end
	local v237 = p_u_228.states.mag_size:get() - p_u_228.states.mag:get() + (p_u_228.states.chambered:get() and not p_u_228.cylinder and 1 or 0)
	local v238 = p_u_228.states.bullets
	local v239 = math.min(v237, v238:get())
	if v239 > 0 then
		p_u_228:cock(p_u_229, false)
	end
	for v240 = 1, v239 do
		p_u_228.anim.Reload.arm1_idle1(v230, v233)
		if p_u_228.anim.Reload.arm2_start2 then
			p_u_228.anim.Reload.arm2_start2(v231, v233).Completed:Wait()
		end
		p_u_229.values.cframes:get("arm2"):set_pivot("reload")
		p_u_228.anim.Reload.base(v231, v233)
		if p_u_228.anim.Reload.gun_idle then
			p_u_228.anim.Reload.gun_idle(v232, v233)
		end
		if p_u_228.states.single_load:get() then
			task.wait(0.15 * v233)
			p_u_228.single_bullet = script.Bullets[p_u_228.bullet_load_type or p_u_228.bullet_type]:Clone()
			p_u_228.single_bullet.Parent = p_u_229.values.viewmodels
			p_u_228.single_bullet.CanCollide = false
			p_u_228.single_bullet:PivotTo(p_u_229.values.viewmodels.arm2.CFrame * p_u_228.hold_bullet_offset)
			v_u_8.weld_c(p_u_228.single_bullet, p_u_229.values.viewmodels.arm2)
		else
			task.wait(0.5 * v233)
			if p_u_228.cylinder and p_u_228.loader then
				p_u_228.loader.Bullets.Transparency = 0
				p_u_228.loader.Parent = p_u_229.values.viewmodels
				p_u_228.loader.Case:PivotTo(p_u_228.cframes:get(p_u_228.loader.Case):render(0.016666666666666666))
			end
		end
		p_u_229.values.cframes:get("arm2"):remove_pivot("reload")
		p_u_228.anim.Reload.arm1_idle2(v230, v233)
		p_u_228.anim.Reload.arm2_idle(v231, v233).Completed:Wait()
		if p_u_228.magazine then
			p_u_228.cframes:get(p_u_228.magazine):remove_pivot("reload")
			p_u_228.magazine.Transparency = 0
			p_u_228.sound.Reload2(p_u_228.instance.Root)
			if p_u_228.feed_cover then
				p_u_228.anim.Reload.arm2_finish(v231, v233)
				p_u_228.anim.Reload.arm1_finish(v230, v233).Completed:Wait()
				p_u_228.sound.Chains(p_u_228.instance.Root)
				if p_u_228.end_bullet then
					p_u_228.cframes:get(p_u_228.end_bullet):remove_pivot("unloaded")
					p_u_228.end_bullet.Transparency = 0
					for _, v241 in p_u_228.end_bullet:GetChildren() do
						if v241:IsA("BasePart") then
							v241.Transparency = 0
						end
					end
				end
				p_u_228.anim.Reload.arm2_empty1_2(v231, v233)
				p_u_228.anim.Reload.arm1_empty1(v230, v233).Completed:Wait()
				p_u_228.states.loaded:set(true)
				p_u_228.anim.Reload.gun_empty1(v232, v233)
				p_u_228.anim.Reload.arm2_empty2(v231, v233).Completed:Wait()
				local v242 = p_u_228.cframes:get(p_u_228.feed_cover):get_offset("reload")
				p_u_228.sound.FeedClose(p_u_228.instance.Root)
				v_u_8.tween(v242, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					["Value"] = CFrame.Angles(0, 0, 0)
				})
				p_u_228.anim.Reload.arm2_empty1_3(v231, v233).Completed:Wait()
			else
				p_u_228.states.loaded:set(true)
				p_u_228.anim.Reload.arm2_finish(v231, v233)
				p_u_228.anim.Reload.arm1_finish(v230, v233).Completed:Wait()
			end
		elseif p_u_228.states.single_load:get() then
			p_u_228.sound.Reload2(p_u_228.instance.Root)
			p_u_228.single_bullet:Destroy()
			if not p_u_228.cylinder then
				p_u_228.states.loaded:set(true)
				p_u_228.states.load_bullet:fire()
			end
			p_u_228.anim.Reload.arm2_finish(v231, v233)
			p_u_228.anim.Reload.arm1_finish(v230, v233).Completed:Wait()
			if p_u_228.cylinder then
				p_u_228.states.loaded:set(true)
				p_u_228.states.load_bullet:fire()
			end
			if p_u_228.cylinder and (v240 == v239 or (p_u_228.states.mag:get() >= p_u_228.states.mag_size:get() or p_u_228.states.bullets:get() <= 0)) then
				if p_u_228.loader then
					p_u_228.anim.Reload.arm1_start(v230, v233)
					p_u_228.anim.Reload.gun(v232, v233)
					p_u_228.anim.Reload.arm2_start(v231, v233).Completed:Wait()
					p_u_228.sound.Reload1(p_u_228.instance.Root)
					local v243 = p_u_228.cframes:get(p_u_228.cylinder):get_offset("reload")
					p_u_228.anim.Reload.cylinder_close(v243, v233)
				else
					p_u_228.anim.Reload.gun(v232, v233)
					if p_u_228.anim.Reload.arm1_empty2 then
						p_u_228.anim.Reload.arm2_empty2(v231, v233)
						p_u_228.anim.Reload.arm1_empty2(v230, v233).Completed:Wait()
					end
					if p_u_228.anim.Reload.arm1_empty1 then
						p_u_228.anim.Reload.arm2_empty1(v231, v233)
						p_u_228.anim.Reload.arm1_empty1(v230, v233).Completed:Wait()
					end
					p_u_228.sound.Reload1(p_u_228.instance.Root)
					local v244 = p_u_228.cframes:get(p_u_228.cylinder):get_offset("reload")
					p_u_228.anim.Reload.cylinder_close(v244, v233)
				end
			end
		elseif p_u_228.cylinder and p_u_228.loader then
			p_u_228.sound.Reload2(p_u_228.instance.Root)
			p_u_228.cframes:get(p_u_228.loader.Case):set_pivot("reload")
			p_u_228.anim.Reload.arm2_finish(v231, v233)
			p_u_228.anim.Reload.arm1_finish(v230, v233).Completed:Wait()
			p_u_228.cframes:get(p_u_228.loader.Case):remove_pivot("reload")
			p_u_228.loader.Bullets.Transparency = 1
			p_u_228.states.loaded:set(true)
			p_u_229.values.cframes:get("arm2"):set_pivot("reload")
			local v245 = p_u_228.anim.Reload.base(v231, v233)
			v245.Completed:Connect(function()
				-- upvalues: (copy) p_u_228, (copy) p_u_229
				if p_u_228.loader then
					p_u_228.loader.Parent = nil
					p_u_228.cframes:get(p_u_228.loader.Case):remove_pivot("reload")
				end
				p_u_229.values.cframes:get("arm2"):remove_pivot("reload")
			end)
			if p_u_228.anim.Reload.arm1_end1 then
				p_u_228.anim.Reload.gun(v232, v233)
				p_u_228.anim.Reload.arm1_end1(v230, v233).Completed:Wait()
				p_u_228.sound.Reload1(p_u_228.instance.Root)
				local v246 = p_u_228.cframes:get(p_u_228.cylinder):get_offset("reload")
				p_u_228.anim.Reload.cylinder_close(v246, v233)
				p_u_228.anim.Reload.arm1_end2(v230, v233).Completed:Wait()
			else
				p_u_228.anim.Reload.arm1_idle2(v230, v233)
				v245.Completed:Wait()
				p_u_228.anim.Reload.arm1_start(v230, v233)
				p_u_228.anim.Reload.gun(v232, v233)
				p_u_228.anim.Reload.arm2_start(v231, v233).Completed:Wait()
				p_u_228.sound.Reload1(p_u_228.instance.Root)
				local v247 = p_u_228.cframes:get(p_u_228.cylinder):get_offset("reload")
				p_u_228.anim.Reload.cylinder_close(v247, v233)
			end
		end
		if p_u_228.states.bullets:get() <= 0 or not p_u_228.states.single_load:get() or p_u_228.states.mag:get() >= p_u_228.states.mag_size:get() + (p_u_228.states.chambered:get() and 1 or 0) then
			break
		end
	end
end
function v_u_3.reload_done(p248, p249)
	p249.values.cframes:get("arm1"):get_absolute("reload")
	p249.values.cframes:get("arm2"):get_absolute("reload")
	p248.cframes:get(p248.instance.Root):get_absolute("reload")
	p248.sound.Handle(p248.instance.Root)
	p249.values.cframes:get("arm1"):remove_all_absolutes("reload")
	p249.values.cframes:get("arm2"):remove_all_absolutes("reload")
	p248.cframes:get(p248.instance.Root):remove_all_absolutes("reload")
	local v250 = p248.safety
	local v251 = p249.values.holding
	if v251 then
		v251 = p249.values.holding.loadout_type == "primary"
	end
	v250:set(v251)
end
function v_u_3.reload_cancel(p252, p253)
	-- upvalues: (copy) v_u_8
	if p252 ~= nil then
		p253.values.cframes:get("arm1"):get_absolute("reload")
		p253.values.cframes:get("arm2"):get_absolute("reload")
		p252.cframes:get(p252.instance.Root):get_absolute("reload")
		if p252.single_bullet then
			p252.single_bullet:Destroy()
			p252.single_bullet = nil
		end
		if p252.loader then
			p252.loader.Parent = nil
			p252.cframes:get(p252.loader.Case):remove_pivot("reload")
		end
		p253.values.cframes:get("arm2"):remove_pivot("reload")
		if p252.end_bullet then
			if p252.states.loaded:get() then
				p252.cframes:get(p252.end_bullet):remove_pivot("unloaded")
			else
				if p252.cframes:get(p252.end_bullet):current_pivot() ~= "unloaded" then
					p252.cframes:get(p252.end_bullet):set_pivot("unloaded")
				end
				p252.end_bullet.Transparency = 1
				for _, v254 in p252.end_bullet:GetChildren() do
					if v254:IsA("BasePart") then
						v254.Transparency = 1
					end
				end
			end
		end
		if p252.magazine then
			p252.cframes:get(p252.magazine):remove_pivot("reload")
			if not p252.states.loaded:get() then
				p252.magazine.Transparency = 1
			end
			if p252.feed_cover then
				local v255 = p252.cframes:get(p252.feed_cover):get_offset("reload")
				v_u_8.tween(v255, TweenInfo.new(0.1), {
					["Value"] = CFrame.new(0, 0, 0)
				})
			end
		elseif p252.cylinder then
			local v256 = p252.cframes:get(p252.cylinder):get_offset("reload")
			v_u_8.tween(v256, TweenInfo.new(0.1), {
				["Value"] = CFrame.new(0, 0, 0)
			})
		end
		p252.sound.Handle(p252.instance.Root)
		p253.values.cframes:get("arm1"):remove_all_absolutes("reload")
		p253.values.cframes:get("arm2"):remove_all_absolutes("reload")
		p252.cframes:get(p252.instance.Root):remove_all_absolutes("reload")
		local v257 = p252.safety
		local v258 = p253.values.holding
		if v258 then
			v258 = p253.values.holding.loadout_type == "primary"
		end
		v257:set(v258)
	end
end
function v_u_3.cock_begin(p259, p260)
	local v261 = not p259.states.single_load:get()
	p259.sound.Handle(p259.instance.Root)
	local v262 = p259.states.reload_speed:get()
	if p259.right_hand_hold then
		p259.cframes:get(p259.instance.Root).pivot_time = 0.1
		p259.cframes:get(p259.instance.Root):set_pivot("equipped2")
	end
	local v263 = p260.values.cframes:get("arm1"):set_absolute("cock", true)
	local v264 = p260.values.cframes:get("arm2"):set_absolute("cock", true)
	local v265
	if p259.load_slide then
		v265 = p259.cframes:get(p259.load_slide):set_offset("cock")
		p259.anim.Reload.slide_cock(v265, v262)
		if not v261 then
			p259.sound.Reload3(p259.instance.Root)
		end
	else
		v265 = nil
	end
	p259.anim.Reload.arm1_cock(v263, v262, p259)
	p259.anim.Reload.arm2_cock(v264, v262, p259).Completed:Wait()
	if v265 then
		p259.anim.Reload.slide_cocked(v265, v262)
		if v261 then
			p259.sound.Reload3(p259.instance.Root)
		else
			p259.sound.Reload4(p259.instance.Root)
			local v266 = p259.instance:FindFirstChild("BulletEject", true)
			if v266 then
				p259:eject_bullet(v266, p259.bullet_type)
			end
		end
	else
		p259.states.chambered:set(true)
	end
	p259.anim.Reload.arm1_cocked(v263, v262, p259)
	p259.anim.Reload.arm2_cocked(v264, v262, p259).Completed:Wait()
	if v265 then
		p259.states.chambered:set(true)
	end
end
function v_u_3.cock_done(p267, p268)
	p268.values.cframes:get("arm1"):get_absolute("cock")
	p268.values.cframes:get("arm2"):get_absolute("cock")
	local v269
	if p267.load_slide then
		v269 = p267.cframes:get(p267.load_slide):get_offset("cock")
		p267.anim.Reload.base(v269, 1)
	else
		v269 = nil
	end
	p267.sound.Handle(p267.instance.Root)
	if v269 then
		p267.cframes:get(v269):remove_offset("cock")
	end
	p268.values.cframes:get("arm1"):remove_all_absolutes("cock")
	p268.values.cframes:get("arm2"):remove_all_absolutes("cock")
	if p267.right_hand_hold then
		p267.cframes:get(p267.instance.Root):remove_pivot("equipped2")
	end
end
function v_u_3.cock_cancel(p270, p271)
	if p270 ~= nil then
		p271.values.cframes:get("arm1"):get_absolute("cock")
		p271.values.cframes:get("arm2"):get_absolute("cock")
		local v272
		if p270.load_slide then
			v272 = p270.cframes:get(p270.load_slide):get_offset("cock")
			p270.anim.Reload.base(v272, 1)
		else
			v272 = nil
		end
		p270.sound.Handle(p270.instance.Root)
		if v272 then
			p270.cframes:get(v272):remove_offset("cock")
		end
		p271.values.cframes:get("arm1"):remove_all_absolutes("cock")
		p271.values.cframes:get("arm2"):remove_all_absolutes("cock")
		if p270.right_hand_hold then
			p270.cframes:get(p270.instance.Root):remove_pivot("equipped2")
		end
	end
end
function v_u_3.get_shoot_look(p273)
	-- upvalues: (copy) v_u_14
	shared.extras.ResetEnv()
	local v274 = p273.owner
	if not v_u_14.FLAG_ADS_CAMERA_BULLETS then
		return p273.shot.CFrame
	end
	local v275 = p273.reticule or p273.instance.Root.FrontSight
	local _ = v274.values.cframes:get("camera"):get_offset("shoot").Value
	local v276 = v275.WorldCFrame
	return p273.shot.CFrame:Lerp(v276, p273.accuracy.Value)
end
function get_circular_spread(p277, p278)
	local v279 = math.random() * 2 * 3.141592653589793
	local v280 = math.random() ^ 0.35 * p278
	return (p277.RightVector * math.cos(v279) + p277.UpVector * math.sin(v279)) * v280
end
function v_u_3.send_shoot(p281)
	-- upvalues: (copy) v_u_8
	local v282 = p281.owner
	local v283 = p281:get_shoot_look()
	if p281.client_sided_hitscan then
		local v284 = p281.states.pellets:get() > 1
		local v285 = CFrame.new(v_u_8.validate_position(game.Workspace.CurrentCamera.CFrame.Position, v283.Position, v282.values.ray_params)) * v283.Rotation
		local v286 = p281.states.pellets:get()
		local v287 = {}
		for v288 = 1, v286 do
			local v289 = v285.Position
			local v290 = v285.LookVector * 1000
			local v291 = p281.states.spread:get() * 100
			local v292 = v290 + (1 - p281.accuracy.Value * (p281.red_dot and p281.red_dot.Transparency == 1 and 0.5 or 1) * math.map(v288, 1, math.max(2, v286), 1, 0)) * get_circular_spread(v285, v291)
			if v284 then
				v292 = v292 - v292 * 0.75
			end
			local v293 = p281:ray_damage(v289, v292, { v282.values.viewmodels, v282.instance }, nil)
			table.insert(v287, v293)
		end
		p281.states.shoot:fire(v283, v287)
	else
		p281.states.shoot:fire(v283)
	end
end
function v_u_3.send_melee(p294)
	p294.states.melee:fire_instant()
	local v295 = p294.owner.values.camera:get().CFrame
	if p294.client_sided_hitscan then
		local v296 = p294.owner
		local v297 = p294:ray_damage(v295.Position - v295.LookVector * 0.2, v295.LookVector * 2.95, { v296.values.viewmodels, v296.instance }, 0.2)
		p294.states.hit:fire(v295, v297)
	else
		p294.states.hit:fire(v295)
	end
end
function v_u_3.input_ads(p298, p299, p300)
	-- upvalues: (copy) v_u_11, (copy) v_u_9
	p298.ads_hold = p299
	local v301 = p298.owner
	if not (p299 and v301.values.prone_debounce) then
		if v301 and (v301.values.equipped == p298 and not p298.meleeing) then
			p298.owner.states.running:set(false)
			if v_u_11.settings.toggle_aim and not p300 then
				if p299 then
					p298.states.sights:update(function(p302)
						return not p302
					end)
					v_u_9.get("CancelScope").Visible = p298.states.sights:get()
					return
				end
			else
				p298.states.sights:set(p299)
			end
		end
	end
end
function v_u_3.input_shoot(p303, p304, p305)
	-- upvalues: (copy) v_u_11, (copy) v_u_9
	local v306 = p303.owner
	if v306 and (v306.values.equipped == p303 and (not p303.safety:get() or p303.accuracy.Value >= 1)) and not (v306.states.running:get() or v306.values.equip_debounce:get()) then
		local v307 = os.clock()
		local v308 = p303.states.firerate:get()
		if (p304 and (not p305 or p303.automatic) or not p304 and (p305 and (not p303.automatic and p303.shoot_hold))) and (v308 == 0 or v307 - p303.last_shot > 1 / (v308 / 60)) then
			if p303.states.mag:get() > 0 and p303.states.chambered:get() then
				p303.last_shot = v307
				p303:send_shoot()
			else
				p303:reload(v306, false)
			end
		end
	end
	if v_u_11.settings.auto_ads and (p305 or not v_u_9.get("ShootJoystickFrame").Visible) then
		if p304 and not p303.states.sights:get() then
			p303:input_ads(true, not v_u_11.settings.lock_auto_ads)
		elseif not (p304 or (v_u_9.get("CancelScope").Visible or v_u_11.settings.lock_auto_ads)) then
			p303:input_ads(false, true)
		end
	end
	p303.shoot_hold = p304
end
function v_u_3.hook_inputs(p_u_309)
	-- upvalues: (copy) v_u_9, (copy) v_u_4, (copy) v_u_13
	local v_u_310 = p_u_309.inputs
	p_u_309.owner.states.equipped:hook(function(p311)
		-- upvalues: (copy) p_u_309, (copy) v_u_310
		if p311 == p_u_309.instance then
			v_u_310.enabled:set(true)
		else
			v_u_310.enabled:set(false)
		end
	end)
	p_u_309.owner.values.equip_debounce:hook(function(p312)
		-- upvalues: (copy) p_u_309
		if p312 then
			p_u_309.states.sights:set(false)
		end
	end)
	v_u_310.enabled:hook(function(p313)
		-- upvalues: (ref) v_u_9
		if p313 then
			v_u_9.get("CancelScope").Visible = false
			v_u_9.get("CancelShoot").Visible = false
		end
	end)
	v_u_310:get("shoot"):press(function(p314)
		-- upvalues: (ref) v_u_9, (copy) p_u_309
		if p314 and v_u_9.get("CancelShoot").Visible then
			p_u_309.shoot_hold = false
			p_u_309:input_shoot(false)
			v_u_9.get("CancelShoot").Visible = false
		else
			p_u_309:input_shoot(p314)
		end
	end)
	v_u_310:get("shoot_joystick"):press(function(p315)
		-- upvalues: (copy) p_u_309, (ref) v_u_9
		p_u_309:input_shoot(p315, true)
		local v316 = v_u_9.get("CancelShoot")
		local v317 = not p_u_309.automatic
		if v317 then
			v317 = p315 and true or false
		end
		v316.Visible = v317
	end)
	v_u_310:get("aim"):press(function(p318)
		-- upvalues: (copy) p_u_309, (ref) v_u_4
		p_u_309:input_ads(p318)
		if p_u_309.owner and (not p318 and v_u_4.current_device:get() == "console") then
			p_u_309.owner.states.lean:set(0)
		end
	end)
	v_u_310:get("reload"):press(function(p319)
		-- upvalues: (copy) p_u_309
		local v320 = p_u_309.owner
		if p319 and (v320 and (not p_u_309.reload_thread.running and (not v320.values.equip_debounce:get() and (not v320.values.prone_debounce and (v320.values.equipped == p_u_309 and (v320.states.vault:get() == 0 and (not v320.states.running:get() and p_u_309.states.bullets:get() > 0))))))) and p_u_309.states.mag:get() - (p_u_309.cylinder and 0 or 1) < p_u_309.states.mag_size:get() then
			p_u_309.states.sights:set(false)
			p_u_309.ads_hold = false
			local v321 = v320.values.holding
			if v321 and v321.can_reload == false then
				v320.states.holding:set(v320.values.hands)
				while v320.values.equip_debounce:get() or v320.values.holding == v321 do
					v320.values.equip_debounce:wait()
				end
			end
			p_u_309.states.reload:fire()
		end
	end)
	v_u_13.setup_action(v_u_310, function()
		-- upvalues: (copy) p_u_309
		local v322 = not (p_u_309.reload_thread.running or p_u_309.cock_thread.running)
		if v322 then
			if p_u_309.states.mag:get() < p_u_309.states.mag_size:get() * 0.2 then
				v322 = p_u_309.states.bullets:get() > 0
			else
				v322 = false
			end
		end
		return v322
	end, "Reload", "reload")
end
function v_u_3.update_ui(p323)
	local v324 = ("%*/%*"):format(p323.states.mag:get(), (p323.states.bullets:get()))
	for _, v325 in p323.hooked_labels do
		v325.Text = v324
	end
end
function v_u_3.load()
	-- upvalues: (copy) v_u_5, (copy) v_u_3, (copy) v_u_6, (copy) v_u_7, (copy) v_u_10
	v_u_5.class(v_u_3.tag, function()
		-- upvalues: (ref) v_u_6, (ref) v_u_7, (ref) v_u_10
		local v326 = {
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
		for _, v327 in v_u_10.attachment_types do
			v326[v327 .. "_att"] = v_u_6.new("")
		end
		return v326, {}
	end):hook(function(_) end)
end
return v_u_3
