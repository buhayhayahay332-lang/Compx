local RunService = game:GetService("RunService")
local v1 = require(script.Parent)
local t = {}
t.__index = t
setmetatable(t, v1)
t.tag = script.Name
t.holster_offset = CFrame.new(0, 0, 1) * CFrame.Angles(0, 0, 1.5707963267948966)
t.holster_part = "torso"
t.magazine_hold_offset = CFrame.new(0.2, -2.225, 0) * CFrame.Angles(-1.5707963267948966, 0, 0)
if not RunService:IsServer() then
	local Input = require(game.ReplicatedStorage.Modules.Input)
	local StateObject = require(game.ReplicatedStorage.Modules.StateObject)
	local State = require(game.ReplicatedStorage.Modules.State)
	local v2 = require(game.ReplicatedStorage.Modules.Event)
	local Util = require(game.ReplicatedStorage.Modules.Util)
	local UI = require(game.ReplicatedStorage.Modules.UI)
	local Globals = require(game.ReplicatedStorage.Modules.Globals)
	require(game.ReplicatedStorage.Modules.Net)
	local Data = require(game.ReplicatedStorage.Modules.Data)
	local Items = require(game.ReplicatedStorage.Modules.Items)
	local FirstPersonInterface = require(game.ReplicatedStorage.Modules.FirstPersonInterface)
	local FlagManager = require(game.ReplicatedStorage.Modules.FlagManager)
	local Maid = require(game.ReplicatedStorage.Modules.Maid)
	local Effects = require(game.ReplicatedStorage.Modules.Effects)
	game:GetService("UserInputService")
	local Animations = require(script.Animations)
	local Sounds = require(script.Sounds)
	t.anim = setmetatable({}, {
		__index = function(p1, p2) --[[ Line: 36 | Upvalues: Animations (copy), v1 (copy) ]]
			return Animations[p2] or v1.anim[p2]
		end
	})
	t.sound = setmetatable({}, {
		__index = function(p1, p2) --[[ Line: 41 | Upvalues: Sounds (copy), v1 (copy) ]]
			return Sounds[p2] or v1.sound[p2]
		end
	})
	function t.init(p1) --[[ Line: 46 | Upvalues: Util (copy), State (copy) ]]
		p1.auto_shoot_dt = os.clock()
		p1.last_shot = os.clock()
		p1.shot = p1:setup_shot(p1.instance.Root:FindFirstChild("Shoot", true))
		p1.reload_thread = Util.ov(p1.reload_begin)
		p1.reload_thread:done(p1.reload_done)
		p1.reload_thread:cancelled(p1.reload_cancel)
		p1.cock_thread = Util.ov(p1.cock_begin)
		p1.cock_thread:done(p1.cock_done)
		p1.cock_thread:cancelled(p1.cock_cancel)
		p1.recoil = Util.ov(p1.recoil_function)
		p1.sights = Util.ov(p1.sights)
		p1.sights:cancelled(function() --[[ Line: 58 | Upvalues: p1 (copy) ]]
			p1.owner.values.cframes:get("arm1"):remove_offset("sights")
			p1.owner.values.cframes:get("arm2"):remove_offset("sights")
			p1.cframes:get(p1.instance.Root):remove_offset("sights")
		end)
		p1.flash = Util.ov(p1.flash)
		p1.safety_function = Util.ov(p1.safety_function)
		p1.safety = State.new(nil)
		p1:load_instance()
	end
	function t.flash(p1) --[[ Line: 74 ]]
		p1.shot.Flash:Emit(3)
		p1.shot.Light.Enabled = true
		task.wait(0.05)
		p1.shot.Light.Enabled = false
	end
	function t.set_part_pivots(p1) --[[ Line: 81 | Upvalues: Util (copy) ]]
		p1.slide = p1.instance:FindFirstChild("Slide")
		if p1.slide then
			local v1 = p1.cframes:get(p1.slide, true)
			local v2 = p1.instance.Root.CFrame:ToObjectSpace(p1.slide:GetPivot())
			v1:set_pivot("general", function() --[[ Line: 86 | Upvalues: p1 (copy), v2 (copy) ]]
				return p1.instance.Root.CFrame * v2
			end)
			if p1.shoot_slide then
				p1.cframes:get(p1.slide):set_offset("shoot")
			end
		end
		p1.load_slide = p1.instance:FindFirstChild("LoadSlide") or p1.instance:FindFirstChild("Pump")
		if p1.load_slide then
			local v4 = p1.cframes:get(p1.load_slide, true)
			local v5 = p1.instance.Root.CFrame:ToObjectSpace(p1.load_slide:GetPivot())
			v4:set_pivot("general", function() --[[ Line: 98 | Upvalues: p1 (copy), v5 (copy) ]]
				return p1.instance.Root.CFrame * v5
			end)
			if p1.shoot_slide then
				p1.cframes:get(p1.load_slide):set_offset("shoot")
			end
		end
		p1.hammer = p1.instance:FindFirstChild("Hammer")
		if p1.hammer then
			local v6 = p1.cframes:get(p1.hammer, true)
			local v7 = p1.instance.Root.CFrame:ToObjectSpace(p1.hammer.CFrame)
			v6:set_pivot("general", function() --[[ Line: 110 | Upvalues: p1 (copy), v7 (copy) ]]
				return p1.instance.Root.CFrame * v7
			end)
		end
		p1.feed_cover = p1.instance:FindFirstChild("FeedCover")
		if p1.feed_cover then
			local v8 = p1.cframes:get(p1.feed_cover, true)
			local v9 = p1.instance.Root.CFrame:ToObjectSpace(p1.feed_cover:GetPivot())
			v8:set_pivot("general", function() --[[ Line: 119 | Upvalues: p1 (copy), v9 (copy) ]]
				return p1.instance.Root.CFrame * v9
			end)
			v8:set_offset("reload")
		end
		p1.end_bullet = p1.instance:FindFirstChild("EndBullet")
		if p1.end_bullet then
			local v10 = p1.cframes:get(p1.end_bullet, true)
			local v11 = p1.instance.Root.CFrame:ToObjectSpace(p1.end_bullet:GetPivot())
			v10:set_pivot("general", function() --[[ Line: 129 | Upvalues: p1 (copy), v11 (copy) ]]
				return p1.instance.Root.CFrame * v11
			end)
			v10:create_pivot("unloaded", function() --[[ Line: 132 | Upvalues: p1 (copy) ]]
				return p1.instance.Magazine.CFrame
			end)
		end
		p1.cylinder = p1.instance:FindFirstChild("Cylinder")
		if p1.cylinder then
			local v12 = p1.cframes:get(p1.cylinder, true)
			local v13 = p1.instance.Root.CFrame:ToObjectSpace(p1.cylinder:GetPivot())
			v12:set_pivot("general", function() --[[ Line: 141 | Upvalues: p1 (copy), v13 (copy) ]]
				return p1.instance.Root.CFrame * v13
			end)
			v12:set_offset("reload")
			if p1.cylinder_loader then
				p1.loader = p1.cylinder_loader:Clone()
				p1.cframes:get(p1.loader.Case):set_pivot("general", function(p12) --[[ Line: 148 | Upvalues: p1 (copy) ]]
					return p1.owner.values.viewmodels.arm2.CFrame * CFrame.new(0.2, -0.7, -0.4) * CFrame.Angles(-1.5707963267948966, 0.5235987755982988, 0) * CFrame.Angles(0, 0, -0.5235987755982988)
				end)
				p1.cframes:get(p1.loader.Case):create_pivot("reload", function(p12) --[[ Line: 151 | Upvalues: p1 (copy) ]]
					return p1.instance.Cylinder:GetPivot() * CFrame.new(0, 0, 0.2)
				end)
			end
		end
		Util.weld_c(p1.instance.Trigger, p1.instance.Root)
		p1.magazine = p1.instance:FindFirstChild("Magazine")
		if p1.magazine then
			local v14 = p1.cframes:get(p1.magazine)
			local v15 = p1.instance.Root.CFrame:ToObjectSpace(p1.magazine:GetPivot())
			v14:set_pivot("general", function() --[[ Line: 168 | Upvalues: p1 (copy), v15 (copy) ]]
				return p1.instance.Root.CFrame * v15
			end)
			v14:create_pivot("reload", function(p12) --[[ Line: 171 | Upvalues: p1 (copy) ]]
				return p1.owner.values.viewmodels.arm2:GetPivot() * p1.magazine_hold_offset
			end)
		end
	end
	function t.update_sight_lens(p1, p2) --[[ Line: 177 | Upvalues: Util (copy), Data (copy), UI (copy) ]]
		local v1 = p1.states.ads:get()
		if p2 then
			Util.tween(workspace.CurrentCamera, TweenInfo.new(v1, Enum.EasingStyle.Linear), {
				FieldOfView = Data.settings.field_of_view / p1.states.zoom:get()
			})
			Util.tween(UI.get("RedDot").UIStroke, TweenInfo.new(0.3), {
				Transparency = 1
			})
			local ScopePart = p1.instance:FindFirstChild("ScopePart", true)
			if ScopePart then
				ScopePart:SetAttribute("OriginalMaterial", ScopePart.Material.Name)
				if ScopePart.Material ~= Enum.Material.Neon then
					ScopePart.Material = Enum.Material.Glass
				end
				ScopePart:SetAttribute("PreviousScopeTransparency", ScopePart.Transparency)
				ScopePart.Transparency = math.max(0.011, ScopePart.Transparency)
			end
			local ScopeTint = p1.instance:FindFirstChild("ScopeTint", true)
			if ScopeTint then
				local v2
				if ScopePart == nil then
					v2 = 0.8
				else
					v2 = 0.3
				end
				ScopeTint.Transparency = v2
			end
			UI.hook_world_billboards("sights", function(p1) --[[ Line: 198 | Upvalues: Util (ref) ]]
				Util.tween(p1, TweenInfo.new(0.1), {
					GroupTransparency = 0.7,
					Size = UDim2.fromScale(0.9, 0.9)
				})
			end)
		else
			Util.tween(workspace.CurrentCamera, TweenInfo.new(v1, Enum.EasingStyle.Linear), {
				FieldOfView = Data.settings.field_of_view
			})
			Util.tween(UI.get("RedDot").UIStroke, TweenInfo.new(0.3), {
				Transparency = 0.5
			})
			local ScopePart = p1.instance:FindFirstChild("ScopePart", true)
			if ScopePart and ScopePart:GetAttribute("OriginalMaterial") then
				ScopePart.Material = Enum.Material[ScopePart:GetAttribute("OriginalMaterial")]
				ScopePart.Transparency = ScopePart:GetAttribute("PreviousScopeTransparency") or 0
			end
			local ScopeTint = p1.instance:FindFirstChild("ScopeTint", true)
			if ScopeTint then
				ScopeTint.Transparency = 1
			end
			UI.unhook_world_billboards("sights")
			for v3, v4 in UI.get_world_billboards() do
				Util.tween(v4, TweenInfo.new(0.1), {
					GroupTransparency = 0,
					Size = UDim2.fromScale(1, 1)
				})
			end
		end
	end
	function t.hook_states(p1) --[[ Line: 223 | Upvalues: Globals (copy), Items (copy), Maid (copy), Util (copy), UI (copy), Data (copy) ]]
		p1.offsets = {}
		p1.states.mag:hook(function(p12) --[[ Line: 226 | Upvalues: p1 (copy) ]]
			p1:update_ui()
		end)
		p1.states.bullets:hook(function(p12) --[[ Line: 230 | Upvalues: p1 (copy) ]]
			p1:update_ui()
		end)
		p1.accuracy = Instance.new("NumberValue")
		p1.states.sights:hook(function(p12, p2) --[[ Line: 236 | Upvalues: p1 (copy) ]]
			if p12 ~= p2 and p1.owner then
				p1:sights(p1.owner, p12)
			end
		end)
		p1.states.sights:hook(function(p12, p2) --[[ Line: 243 | Upvalues: p1 (copy) ]]
			if p12 ~= p2 and p1.owner.values.camera:get() then
				p1:update_sight_lens(p12)
			end
		end)
		p1.states.reload:hook_paused(function(p12, p2) --[[ Line: 250 | Upvalues: p1 (copy) ]]
			if p12 ~= p2 and p1.owner then
				p1:reload(p1.owner, false)
			end
		end)
		p1.states.reload:hook(function() --[[ Line: 257 | Upvalues: p1 (copy) ]]
			if p1.owner then
				p1:reload(p1.owner, true)
			end
		end)
		p1.states.accuracy:hook(function(p12) --[[ Line: 263 | Upvalues: p1 (copy) ]]
			if p1.accuracy then
				p1.accuracy.Value = p1.states.accuracy:get() - 1
			end
		end)
		p1.states.cock:hook(function() --[[ Line: 269 | Upvalues: p1 (copy) ]]
			if p1.owner then
				p1:cock(p1.owner, true)
			end
		end)
		p1.states.melee:hook(function() --[[ Line: 275 | Upvalues: p1 (copy) ]]
			if p1.owner then
				p1:melee(p1.owner)
			end
		end)
		p1.states.shoot:hook(function(p12, p2) --[[ Line: 281 | Upvalues: p1 (copy) ]]
			if p1.owner then
				p1:shoot(p1.owner, p12, p2)
			end
		end)
		p1.states.hit:hook(function(p12, p2) --[[ Line: 287 | Upvalues: p1 (copy) ]]
			if p1.owner then
				p1:hit(p1.owner, p12, p2)
			end
		end)
		p1.states.loaded:hook(function(p12, p2) --[[ Line: 293 | Upvalues: p1 (copy) ]]
			if p12 == p2 or not p1.owner then
			elseif p12 and (p2 == false and not p1.states.single_load:get()) then
				local v2 = math.min(p1.states.mag_size:get(), p1.states.bullets:get())
				p1.states.mag:update(function(p1) --[[ Line: 297 | Upvalues: v2 (copy) ]]
					return p1 + v2
				end)
				p1.states.bullets:update(function(p1) --[[ Line: 300 | Upvalues: v2 (copy) ]]
					return p1 - v2
				end)
			elseif p2 then
				local v4 = p1.states.mag:get()
				local v5
				if p1.instance:FindFirstChild("BulletEject", true) then
					v5 = 1
				else
					v5 = 0
				end
				local v6 = math.max(0, v4 - v5)
				p1.states.mag:update(function(p1) --[[ Line: 305 | Upvalues: v6 (copy) ]]
					return p1 - v6
				end)
				p1.states.bullets:update(function(p1) --[[ Line: 308 | Upvalues: v6 (copy) ]]
					return p1 + v6
				end)
			end
		end)
		p1.states.load_bullet:hook(function() --[[ Line: 314 | Upvalues: p1 (copy) ]]
			if p1.owner and p1.states.single_load:get() then
				p1.states.mag:update(function(p1) --[[ Line: 317 ]]
					return p1 + 1
				end)
				p1.states.bullets:update(function(p1) --[[ Line: 320 ]]
					return p1 - 1
				end)
			end
		end)
		p1.states.chambered:hook(function(p12, p2) --[[ Line: 326 | Upvalues: p1 (copy) ]]
			if p12 ~= p2 and p1.owner then
				p1:chamber(p1.owner, p12)
			end
		end)
		for v1, v2 in Globals.attachment_types do
			p1.states[v2 .. "_att"]:hook(function(p12, p2) --[[ Line: 334 | Upvalues: Items (ref), p1 (copy) ]]
				if p2 and (p2 ~= "" and p12 ~= p2) then
					Items.get_item_class(p2):remove(p1)
				end
				if p12 and p12 ~= "" then
					Items.get_item_class(p12):apply(p1)
				end
			end)
		end
		p1.safety:hook(function(p12, p2) --[[ Line: 346 | Upvalues: p1 (copy) ]]
			if p1.owner then
				p1:safety_function(p1.owner, p12, p2)
			end
		end)
		local v3 = Maid.new()
		p1.object:destroying(function() --[[ Line: 354 | Upvalues: v3 (copy) ]]
			v3:clean()
		end)
		v3:add(p1.owner.values.camera:hook(function(p12, p2) --[[ Line: 358 | Upvalues: p1 (copy) ]]
			if p1.states.sights:get() then
				if p12 then
					p1:update_sight_lens(true)
				elseif p2 then
					p1:update_sight_lens(false)
				end
			end
		end).unhook)
		v3:add(p1.owner.values.camera:hook(function(p12, p2) --[[ Line: 367 | Upvalues: p1 (copy), Util (ref), UI (ref), Data (ref) ]]
			if p1.states.sights:get() then
				if p12 == game.Workspace.CurrentCamera then
					Util.tween(UI.get("RedDot").UIStroke, TweenInfo.new(0), {
						Transparency = 1
					})
					Util.tween(workspace.CurrentCamera, TweenInfo.new(0, Enum.EasingStyle.Linear), {
						FieldOfView = Data.settings.field_of_view / p1.states.zoom:get()
					})
				elseif p12 == nil and p2 == game.Workspace.CurrentCamera then
					Util.tween(workspace.CurrentCamera, TweenInfo.new(0, Enum.EasingStyle.Linear), {
						FieldOfView = Data.settings.field_of_view
					})
				end
			end
		end))
	end
	function t.running(p1, p2, p3) --[[ Line: 381 ]]
		local v1 = p2.values.cframes:get("arms"):get_offset("run")
		if p3 then
			p1:running_pivots(p2, true)
			p1.states.sights:set(false)
			p1:reload(p2, false)
			p2.values.cframes:get("arms"):set_offset("run")
			p1.anim.Run.run_offset(v1)
		else
			p1:running_pivots(p2, false)
			p1.anim.Run.base(v1).Completed:Wait()
			p2.values.cframes:get("arms"):remove_offset("run")
		end
	end
	function t.walk_state(p1, p2, p3, p4) --[[ Line: 397 ]]
		if p3 == "prone" or p4 == "prone" then
			p1:reload(p2, false)
			p1:cock(p2, false)
		end
	end
	function t.vault(p1, p2, p3) --[[ Line: 404 ]]
		if p3 > 0 then
			p1:reload(p2, false)
			p1:cock(p2, false)
		end
	end
	function t.sights(p1, p2, p3) --[[ Line: 411 | Upvalues: Data (copy), Input (copy), Util (copy), UI (copy) ]]
		p1.sound.Handle(p1.instance.Root)
		local v1 = p2.values.cframes:get("arm1"):get_offset("sights")
		local v2 = p2.values.cframes:get("arm2"):get_offset("sights")
		local v3 = p1.cframes:get(p1.instance.Root):get_offset("sights")
		local sum = p1.states.ads:get()
		if p3 then
			local v4 = false
			if p2.values.holding and p2.values.holding.safety then
				if p2.values.holding.states.ads then
					sum = sum + p2.values.holding.states.ads:get()
				end
				if p2.states.holding:get() == p2.values.holding.instance then
					p2.values.holding.safety:set(true)
					v4 = true
				end
			end
			p1:reload(p2, false)
			p2.values.cframes:get("arm1"):set_offset("sights")
			if not v4 then
				p2.values.cframes:get("arm2"):set_offset("sights")
			end
			p1.anim.Equip.arm1_hold(p2.values.cframes:get("arm1"):set_absolute("sights", true), p1, sum)
			p1.cframes:get(p1.instance.Root):set_offset("sights")
			p1.anim.Sight.arm1(v1, p1.instance, sum)
			p1.anim.Sight.arm2(v2, p1.instance, sum)
			p1.anim.Sight.gun(v3, p1.instance, sum)
			if p2.values.camera:get() then
				if p1.inputs and p1.inputs.enabled:get() then
					local v5 = ("camera_sensitivity_%*"):format((string.gsub(tostring(p1.states.zoom:get()), "[.]", "_")))
					if Data.settings[v5] then
						Input.mouse_base_sensitivity:set(Util.map_sensitivity(Data.settings[v5]))
						local v6 = nil
						v6 = p1.states.sights:hook(function(p1) --[[ Line: 475 | Upvalues: Input (ref), Util (ref), Data (ref), v6 (ref) ]]
							if not p1 then
								Input.mouse_base_sensitivity:set(Util.map_sensitivity(Data.settings.camera_sensitivity))
								v6.unhook()
							end
						end)
					end
				end
				Util.tween(p1.accuracy, TweenInfo.new(sum, Enum.EasingStyle.Linear), {
					Value = 1
				})
			end
		else
			p2.values.cframes:get("arm1"):remove_absolute("sights")
			if p2.values.holding and (p2.values.holding.safety and not p2.values.equip_debounce:get()) then
				p2.values.holding.safety:set(false)
				if p2.values.holding.states.ads then
					sum = sum + p2.values.holding.states.ads:get()
				end
			end
			if p2.values.camera:get() then
				Util.tween(p1.accuracy, TweenInfo.new(sum, Enum.EasingStyle.Linear), {
					Value = p1.states.accuracy:get() - 1
				})
			end
			if p1.inputs and p1.inputs.enabled:get() then
				UI.get("CancelScope").Visible = false
			end
			p1.anim.Sight.base(v1, p1.instance, sum)
			p1.anim.Sight.base(v2, p1.instance, sum)
			p1.anim.Sight.base(v3, p1.instance, sum).Completed:Wait()
			p2.values.cframes:get("arm1"):remove_offset("sights")
			p2.values.cframes:get("arm2"):remove_offset("sights")
			p1.cframes:get(p1.instance.Root):remove_offset("sights")
		end
	end
	function t.reload(p1, p2, p3) --[[ Line: 526 ]]
		if p3 then
			p1.reload_thread(p1, p2, p3)
		else
			p1.reload_thread:cancel(p1, p2, p3)
		end
	end
	function t.cock(p1, p2, p3) --[[ Line: 534 ]]
		if p3 then
			p1:reload(p2, false)
			p1.cock_thread(p1, p2, p3)
		else
			p1.cock_thread:cancel(p1, p2, p3)
		end
	end
	function t.chamber(p1, p2, p3) --[[ Line: 543 ]]
		if p1.slide then
			local v1 = p1.cframes:get(p1.slide):get_offset("shoot")
			if p3 then
				p1.anim.Gun.slide_off(v1)
			else
				p1.anim.Gun.slide_on(v1).Completed:Wait()
			end
		end
		if not p1.states.single_load:get() then
			if p3 then
				p1.sound.Reload4(p1.instance.Root)
				return
			end
			p1.sound.Empty(p1.instance.Root)
		end
	end
	function t.render(p1, p2, p3) --[[ Line: 561 ]]
		p1.instance.Root:PivotTo(p1.cframes:get(p1.instance.Root):render(p3))
		if p1.hammer then
			p1.hammer:PivotTo(p1.cframes:get(p1.hammer):render(p3))
		end
		if p1.feed_cover then
			p1.feed_cover:PivotTo(p1.cframes:get(p1.feed_cover):render(p3))
		end
		if p1.slide then
			p1.slide:PivotTo(p1.cframes:get(p1.slide):render(p3))
		end
		if p1.load_slide then
			p1.load_slide:PivotTo(p1.cframes:get(p1.load_slide):render(p3))
		end
		if p1.magazine then
			p1.magazine:PivotTo(p1.cframes:get(p1.magazine):render(p3))
		elseif p1.cylinder then
			p1.cylinder:PivotTo(p1.cframes:get(p1.cylinder):render(p3))
			if p1.loader and p1.loader.Parent == p2.values.viewmodels then
				p1.loader.Case:PivotTo(p1.cframes:get(p1.loader.Case):render(p3))
			end
		end
		if p1.end_bullet then
			p1.end_bullet:PivotTo(p1.cframes:get(p1.end_bullet):render(p3))
		end
		if p1.charm_model and p1.charm_model.PrimaryPart then
			p1.charm_model.PrimaryPart:PivotTo(p1.cframes:get(p1.charm_model.PrimaryPart):render(p3))
		end
		if p1.inputs and p1.inputs.enabled:get() then
			p1:input_render(p3)
		end
	end
	function t.auto_shoot_check(p1, p2) --[[ Line: 604 | Upvalues: UI (copy), Util (copy), StateObject (copy) ]]
		local v1 = os.clock()
		if v1 - p1.auto_shoot_dt > 0.25 then
			p1.auto_shoot_dt = v1
			if UI.get("Flash").Frame.BackgroundTransparency == 0 then
				return
			end
			local owner = p1.owner
			local v2 = p1:get_shoot_look()
			local v3 = CFrame.new(Util.validate_position(game.Workspace.CurrentCamera.CFrame.Position, v2.Position, owner.values.ray_params)) * v2.Rotation
			for v4, v5 in p1:ray_damage(v3.Position, v3.LookVector * 500, { owner.values.viewmodels, owner.instance }, nil, true) do
				local v6 = v5.Instance
				if v5.HitHum then
					p1:input_shoot(true)
					return
				end
				if v6 and v6.Transparency < 1 then
					local v7 = Util.get_breakable_instance(v6)
					if v7 and Util.ownership(StateObject.get("Breakable", v7).owner:get()) == 0 then
						p1:input_shoot(true)
						return
					end
				end
			end
			if p1.shoot_hold and not (p1.inputs:get("shoot"):holding() or p1.inputs:get("shoot_joystick"):holding()) then
				p1:input_shoot(false)
			end
		end
	end
	function t.input_render(p1, p2) --[[ Line: 643 | Upvalues: Data (copy) ]]
		local owner = p1.owner
		if owner.values.prone_debounce or owner.values.equip_debounce:get() then
			p1:reload(owner, false)
			p1:cock(owner, false)
		elseif not p1.cock_thread.running and (not p1.reload_thread.running and (not p1.states.chambered:get() and (not owner.values.equip_debounce:get() and (not p1.states.reload:get() and (owner.states.vault:get() == 0 and (p1.states.loaded:get() and p1.states.mag:get() > 0)))))) then
			p1.states.cock:fire_instant()
		end
		local head = owner.values.viewmodels.head
		if not Data.settings.toggle_aim then
			if p1.ads_hold and not (p1.reload_thread.running or (p1.meleeing or (owner.states.running:get() or (owner.values.prone_debounce or owner.values.equip_debounce:get())))) then
				p1.states.sights:set(true)
			else
				p1.states.sights:set(false)
			end
		end
		if p1.automatic and (p1.shoot_hold and (not p1.safety:get() or p1.accuracy.Value >= 1)) and not (owner.values.equip_debounce:get() or owner.states.running:get()) then
			local v1 = os.clock()
			local v2 = p1.states.firerate:get()
			if (v2 == 0 or 1 / (v2 / 60) < v1 - p1.last_shot) and (p1.states.mag:get() > 0 and p1.states.chambered:get()) then
				p1.last_shot = v1
				p1:send_shoot()
			end
		end
		if p1.states.reload:get() and owner.values.equip_debounce:get() then
			p1:reload(owner, false)
		end
	end
	function t.kickback(p1, p2) --[[ Line: 687 ]]
		local v1 = p2.values.cframes:get("arms"):set_offset("shoot")
		p1.anim.Shoot.key1(v1).Completed:Wait()
		p1.anim.Shoot.key2(v1).Completed:Wait()
		p1.anim.Shoot.key3(v1).Completed:Wait()
		p2.values.cframes:get("arms"):remove_offset("shoot")
	end
	function t.recoil_function(p1, p2) --[[ Line: 695 | Upvalues: Input (copy), Util (copy) ]]
		p2.values.cframes:get("camera"):remove_offset("shoot")
		local v1 = p2.values.cframes:get("camera"):set_offset("shoot")
		local v2 = v1.Value
		if p2.values.camera:get() then
			local values = p2.values
			values.old_cam_render = values.old_cam_render * v2:Inverse()
		end
		local v3 = p1.states.recoil_up:get()
		local v4 = p1.states.recoil_side:get()
		if Input.current_device:get() ~= "pc" then
			v3 = v3 * 0.7
			v4 = v4 * 0.7
		end
		if p1.prone_recoil and p2.states.walk_state:get() == "prone" then
			v3 = v3 * p1.prone_recoil
			v4 = v4 * p1.prone_recoil
		end
		Util.tween(v1, TweenInfo.new(0), {
			Value = CFrame.new()
		})
		v1.Value = CFrame.new()
		if p2.values.cframes:get("arm2"):current_pivot() == "equipped" then
			v3 = v3 * 0.8
		end
		local v8 = CFrame.Angles(math.rad(math.random() * v3 + v3), math.rad(math.random() * (v4 * 2) - v4), 0)
		local v9 = math.exp((v3 * 2 + v4) / 40)
		Util.tween(v1, TweenInfo.new(v9 * 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Value = v8
		}).Completed:Wait()
		Util.tween(v1, TweenInfo.new(v9 * 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Value = CFrame.new()
		}).Completed:Wait()
	end
	function t.shoot(p1, p2, p3, p4) --[[ Line: 724 ]]
		p1.states.mag:update(function(p1) --[[ Line: 725 ]]
			return math.max(0, p1 - 1)
		end)
		if p1.states.firerate:get() == 0 then
			p1.states.chambered:set(false)
		else
			local BulletEject = p1.instance:FindFirstChild("BulletEject", true)
			if BulletEject then
				p1:eject_bullet(BulletEject, p1.bullet_type)
			end
		end
		if p1.supressed then
			p1.sound.SilencedShoot(p1.shot)
		else
			p1.sound.Shoot(p1.shot)
		end
		p1:reload(p2, false)
		local v1 = p1.states.pellets:get() > 1
		if p1.owner.values.camera:get() == nil and (not v1 and (p4 and #p4 > 0)) then
			for v2, v3 in p4 do
				if #v3 > 0 then
					p1:trail(p1.shot.CFrame.Position, v3[#v3].Position)
				end
			end
		end
		task.spawn(function() --[[ Line: 751 | Upvalues: p1 (copy), p2 (copy) ]]
			p1:kickback(p2)
		end)
		if p2.values.camera:get() then
			p1.recoil(p1, p2)
		end
		task.spawn(function() --[[ Line: 757 | Upvalues: p1 (copy) ]]
			local Smoke = p1.shot:FindFirstChild("Smoke")
			if Smoke then
				for i = 1, 3 do
					Smoke:Emit(1)
					task.wait(0.1)
				end
			end
		end)
		if p1.shot:FindFirstChild("Flash") then
			p1:flash()
		end
		if p1.states.firerate:get() > 0 then
			task.spawn(p1.slide_shoot, p1)
		end
		if p1.hammer then
			task.spawn(function() --[[ Line: 773 | Upvalues: p1 (copy) ]]
				local v1 = p1.cframes:get(p1.hammer):set_offset("shoot")
				p1.anim.Gun.hammer_on(v1).Completed:Wait()
				p1.anim.Gun.hammer_off(v1).Completed:Wait()
				p1.cframes:get(p1.hammer):remove_offset("shoot")
			end)
		end
		if p4 then
			p1:bullet_hit(p2, p4)
		end
	end
	function t.bullet_hit(p1, p2, p3) --[[ Line: 792 | Upvalues: Util (copy), Effects (copy), Maid (copy), StateObject (copy) ]]
		for v1, v2 in p3 do
			if #v2 ~= 0 then
				local t = {}
				for v3, v4 in v2 do
					local v5 = v4.Instance
					if v5 ~= nil and (v5:HasTag("Water") and not v5.CanCollide) then
						local Position = v4.Position
						local Attachment = Instance.new("Attachment")
						Util.debris(Attachment, 2)
						Attachment.WorldCFrame = CFrame.new(Position.X, v5.CFrame.Y + math.min(v5.Size.X, v5.Size.Y, v5.Size.Z) * 0.5, Position.Z)
						Attachment.Parent = game.Workspace.Terrain
						Effects.Ring(Attachment)
						Effects.Splash(Attachment, 3, v5)
						Effects.WaterSplash(Attachment)
					elseif v5 ~= nil and (v4.HitHum and not t[v5.Parent]) then
						t[v5.Parent] = true
						local Attachment = Instance.new("Attachment")
						Attachment.Parent = game.Workspace.Terrain
						Attachment.WorldCFrame = CFrame.new(v4.Position) * CFrame.lookAt(Vector3.new(0, 0, 0), v4.Normal)
						Util.debris(Attachment, 1)
						p1:emit_blood(Attachment)
						p1.sound.BulletHit(Attachment)
					end
				end
				local v7 = v2[#v2]
				if v7 then
					local v8 = v7.Instance
					local Normal = v7.Normal
					local Position = v7.Position
					if not v7.HitHum and (v8 and (v8.Transparency < 1 and v8.Anchored)) then
						local v9 = Effects.create_point(Position, Normal, math.random(8, 12))
						local v10 = Util.get_breakable_instance(v8)
						if v10 then
							local v11 = Maid.new()
							v11:add(StateObject.get("Breakable", v10).states.destroyed:hook(function(p1) --[[ Line: 834 | Upvalues: v9 (copy) ]]
								if p1 then
									task.defer(function() --[[ Line: 836 | Upvalues: v9 (ref) ]]
										v9:Destroy()
									end)
								end
							end).unhook)
							v11:add(v10.AncestryChanged:Connect(function() --[[ Line: 842 | Upvalues: v10 (copy), v9 (copy) ]]
								if v10.Parent == nil or v10.Parent == game.ReplicatedStorage.Garbage then
									task.defer(function() --[[ Line: 844 | Upvalues: v9 (ref) ]]
										v9:Destroy()
									end)
								end
							end))
							v9.Destroying:Connect(function() --[[ Line: 850 | Upvalues: v11 (copy) ]]
								v11:clean()
							end)
						end
						local v12 = script.BulletHoles.Normal:Clone()
						v12.Parent = v9
						v12.Color = ColorSequence.new(v8.Color)
						v12:Emit(2)
					end
				end
			end
		end
	end
	function t.slide_shoot(p1) --[[ Line: 864 ]]
		if p1.slide then
			local v1 = p1.cframes:get(p1.slide):get_offset("shoot")
			p1.anim.Gun.slide_on(v1).Completed:Wait()
			if p1.states.mag:get() > 0 then
				p1.anim.Gun.slide_off(v1).Completed:Wait()
			end
			if p1.states.mag:get() == 0 then
				p1.states.chambered:set(false)
			end
		elseif p1.load_slide then
			local v2 = p1.cframes:get(p1.load_slide):get_offset("shoot")
			p1.anim.Gun.slide_on(v2).Completed:Wait()
			p1.anim.Gun.slide_off(v2).Completed:Wait()
			if p1.states.mag:get() == 0 then
				p1.states.chambered:set(false)
			end
		end
	end
	function t.melee(p1, p2, p3) --[[ Line: 884 ]]
		p1:reload(p2, false)
		p1:cock(p2, false)
		p1.meleeing = true
		local v1 = p2.values.cframes:get("arm1"):set_absolute("melee", true)
		local v2 = nil
		if p1.anim.Melee.arm2_hold then
			p1.anim.Melee.arm2_hold((p2.values.cframes:get("arm2"):set_absolute("melee", true)))
		else
			p2.values.cframes:get("arm2"):set_absolute("melee", CFrame.new())
			p2.values.cframes:get("arm2"):set_pivot("base")
		end
		if p1.anim.Melee.gun_hold then
			local v4 = p1.cframes:get(p1.instance.Root):set_absolute("melee", true)
			p1.anim.Melee.gun_hold(v4)
			v2 = v4
		end
		p1.sound.Handle(p1.instance.Root)
		p1.anim.Melee.arm1_hold(v1).Completed:Wait()
		p2.values.cframes:get("arm1"):remove_absolute("melee")
		p2.values.cframes:get("arm2"):remove_absolute("melee")
		if not p1.anim.Melee.arm2_hold then
			p2.values.cframes:get("arm2"):remove_pivot("base")
		end
		if v2 then
			p1.cframes:get(p1.instance.Root):remove_absolute("melee")
		end
	end
	function t.hit(p1, p2, p3, p4) --[[ Line: 913 ]]
		local v1 = p2.values.cframes:get("arm1"):set_absolute("melee")
		local v2 = nil
		local v3
		if p1.anim.Melee.arm2_hit then
			v3 = p2.values.cframes:get("arm2"):set_absolute("melee")
		else
			v3 = nil
		end
		if p1.anim.Melee.gun_hit then
			v2 = p1.cframes:get(p1.instance.Root):set_absolute("melee")
		end
		if p1:process_hit_results(p3, p4) then
			p1.sound.Swing(p1.instance.Root)
			if v2 then
				p1.anim.Melee.gun_miss(v2)
			end
			if v3 then
				p1.anim.Melee.arm2_miss(v3)
			end
			p1.anim.Melee.arm1_miss(v1).Completed:Wait()
		else
			if v2 then
				p1.anim.Melee.gun_hit(v2)
			end
			if v3 then
				p1.anim.Melee.arm2_hit(v3)
			end
			p1.anim.Melee.arm1_hit(v1).Completed:Wait()
		end
		p2.values.cframes:get("arm1"):remove_absolute("melee")
		if v3 then
			p2.values.cframes:get("arm2"):remove_absolute("melee")
		end
		if v2 then
			p1.cframes:get(p1.instance.Root):remove_absolute("melee")
		end
		p1.meleeing = false
	end
	function t.safety_function(p1, p2, p3, p4) --[[ Line: 954 ]]
		local v1 = p2.values.cframes:get("arm1"):get_absolute("equipped")
		local v2 = p2.values.cframes:get("arm2"):get_absolute("equipped")
		if p3 == true then
			p1.anim.Equip.arm1_hold_safety(v1)
			if p4 == false then
				p2.values.cframes:get("arm2"):remove_pivot("equipped")
				p2.values.cframes:get("arm2"):remove_absolute("equipped")
			end
		elseif p3 == false then
			p2.values.cframes:get("arm2"):set_absolute("equipped", true)
			p2.values.cframes:get("arm2"):set_pivot("equipped")
			p1.anim.Equip.arm2_hold(v2, p1)
			p1.anim.Equip.arm1_hold(v1, p1).Completed:Wait()
		end
	end
	function t.equip(p1, p2, p3) --[[ Line: 973 ]]
		local v1 = p2.values.cframes:get("arm1"):get_absolute("equipped")
		p2.values.cframes:get("arm2"):get_absolute("equipped")
		local Root = p1.instance:FindFirstChild("Root")
		if Root == nil then
		elseif p3 == true then
			p1:unholster(p2)
			p2.values.cframes:get("arm1"):set_absolute("equipped", true)
			p1.anim.Equip.arm1_grab(v1).Completed:Wait()
			p1.sound.Equip(Root)
			p1.cframes:get(Root):set_pivot("equipped")
			p1.cframes:get(Root).pivot_time = 0.2
			p2.values.cframes:get("arm1"):set_pivot("equipped")
			local holding = p2.values.holding
			if holding and p2.states.holding:get() == p2.values.holding.instance then
				holding = p2.values.holding.loadout_type == "primary"
			elseif holding then
				holding = false
			end
			p1.safety:set_instant(holding)
		else
			p1.states.sights:set(false)
			p1:reload(p2, false)
			p1:cock(p2, false)
			p1.sound.Handle(Root)
			p2.values.cframes:get("arm1"):remove_pivot("equipped")
			if p1.safety:get() == false then
				p2.values.cframes:get("arm2"):remove_pivot("equipped")
				p2.values.cframes:get("arm2"):remove_absolute("equipped")
			end
			p1.safety:set_instant(nil)
			if p2.values.holding and p2.values.holding.safety then
				p2.values.holding.safety:set(false)
			end
			p1.anim.Equip.arm1_grab(v1).Completed:Wait()
			p1.cframes:get(Root).pivot_time = 0.2
			p1.cframes:get(Root):remove_pivot("equipped")
			p2.values.cframes:get("arm1"):remove_absolute("equipped")
			p1:holster(p2)
		end
	end
	function t.trail(p1, p2, p3, p4) --[[ Line: 1025 | Upvalues: Util (copy) ]]
		local Attachment = Instance.new("Attachment")
		local Attachment_2 = Instance.new("Attachment")
		Util.debris(Attachment, 0.5)
		Util.debris(Attachment_2, 0.5)
		Attachment.Parent = workspace.Terrain
		Attachment_2.Parent = workspace.Terrain
		Attachment.Position = p2
		Attachment_2.Position = p3
		local Beam = Instance.new("Beam", game.Workspace)
		Util.debris(Beam, 0.5)
		Beam.Width0 = p1.states.trail_size:get() or 0.1
		Beam.Width1 = p1.states.trail_size:get() or 0.1
		Beam.Attachment0 = Attachment
		Beam.Attachment1 = Attachment_2
		if p1.supressed then
			Beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.95) })
		else
			Beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.75) })
		end
		Util.tween(Beam, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0), {
			Width0 = 0,
			Width1 = 0
		})
		if p1.owner.values.camera:get() == nil then
			local Attachment_3 = Instance.new("Attachment")
			Util.debris(Attachment_3, 0.5)
			Attachment_3.Parent = workspace.Terrain
			Attachment_3.WorldCFrame = CFrame.new(Util.closest_point_on_segment(game.Workspace.CurrentCamera.CFrame.Position, Attachment.WorldCFrame.Position, Attachment_2.WorldCFrame.Position))
			p1.sound.BulletWoosh(Attachment_3).Volume = math.min(1, (p2 - p3).Magnitude / 50) * 0.5
		end
	end
	function t.eject_bullet(p1, p2, p3) --[[ Line: 1070 | Upvalues: Effects (copy) ]]
		local v1 = script.Bullets[p3]:Clone()
		v1.Parent = workspace
		v1.CanCollide = true
		v1:PivotTo(p2.WorldCFrame)
		v1:ApplyImpulse(p2.WorldCFrame.RightVector * (math.random(8, 12) * v1.Mass) + p2.WorldCFrame.UpVector * (math.random(8, 12) * v1.Mass))
		Effects.mark_prop(v1)
		return v1
	end
	function t.setup_shot(p1, p2) --[[ Line: 1096 | Upvalues: Util (copy) ]]
		local v1 = script.Shot:Clone()
		v1.Flash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.3) })
		v1.Parent = p2.Parent
		v1.CFrame = p2.WorldCFrame
		Util.weld_c(v1, p2.Parent)
		return v1
	end
	function t.reload_begin(p1, p2) --[[ Line: 1108 | Upvalues: Util (copy) ]]
		p1.sound.Handle(p1.instance.Root)
		p1.safety:set(false)
		local v1 = p2.values.cframes:get("arm1"):set_absolute("reload", true)
		local v2 = p2.values.cframes:get("arm2"):set_absolute("reload", true)
		local v3 = p1.cframes:get(p1.instance.Root):set_absolute("reload", true)
		local v4 = p1.states.reload_speed:get()
		if p1.feed_cover then
			p1.anim.Reload.arm2_empty1(v2, v4)
			p1.anim.Reload.gun_empty1(v3, v4)
			p1.anim.Reload.arm1_empty1(v1, v4).Completed:Wait()
			local v5 = p1.cframes:get(p1.feed_cover):get_offset("reload")
			p1.sound.FeedOpen(p1.instance.Root)
			Util.tween(v5, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Value = CFrame.Angles(0, -0.5235987755982988, 0)
			})
			p1.anim.Reload.arm2_empty2(v2, v4).Completed:Wait()
			if p1.states.loaded:get() and not p1.states.single_load:get() then
				p1.anim.Reload.arm1_start(v1, v4)
				p1.anim.Reload.gun(v3, v4)
				p1.anim.Reload.arm2_start(v2, v4).Completed:Wait()
				if p1.magazine then
					if p1.end_bullet then
						p1.cframes:get(p1.end_bullet):set_pivot("unloaded")
					end
					p1.cframes:get(p1.magazine):set_pivot("reload")
					p1.sound.Reload1(p1.instance.Root)
					p1.states.loaded:set(false)
				end
			else
				p1.anim.Reload.gun(v3, v4)
			end
		elseif p1.cylinder then
			p1.anim.Reload.arm1_start(v1, v4)
			p1.anim.Reload.gun(v3, v4)
			p1.anim.Reload.arm2_start(v2, v4).Completed:Wait()
			local v6 = p1.cframes:get(p1.cylinder):get_offset("reload")
			p1.sound.Reload1(p1.instance.Root)
			p1.anim.Reload.cylinder_open(v6, v4)
			if p1.states.loaded:get() then
				if p1.anim.Reload.arm1_empty1 then
					p1.anim.Reload.arm2_empty1(v2, v4)
					p1.anim.Reload.arm1_empty1(v1, v4).Completed:Wait()
				end
				local v7 = false
				for i = 1, p1.states.mag_size:get() do
					v7 = p1:eject_bullet(p1.cylinder.Eject, p1.bullet_type, CFrame.Angles(0, 1.5707963267948966, 1.5707963267948966)) ~= nil
				end
				if v7 then
					p1.sound.Cases(p1.instance.Root)
				end
				p1.states.loaded:set(false)
				if p1.anim.Reload.arm1_empty2 then
					p1.anim.Reload.arm2_empty2(v2, v4)
					p1.anim.Reload.arm1_empty2(v1, v4).Completed:Wait()
				end
			end
		elseif p1.states.loaded:get() and not p1.states.single_load:get() then
			p1:cock(p2, false)
			p1.anim.Reload.arm1_start(v1, v4)
			p1.anim.Reload.gun(v3, v4)
			p1.anim.Reload.arm2_start(v2, v4).Completed:Wait()
			if p1.magazine then
				if p1.end_bullet then
					p1.cframes:get(p1.end_bullet):set_pivot("unloaded")
				end
				p1.cframes:get(p1.magazine):set_pivot("reload")
				p1.sound.Reload1(p1.instance.Root)
				p1.states.loaded:set(false)
			end
		else
			p1.anim.Reload.gun(v3, v4)
		end
		local v8 = p1.states.mag_size:get() - p1.states.mag:get()
		local v9
		if p1.states.chambered:get() and not p1.cylinder then
			v9 = 1
		else
			v9 = 0
		end
		local v11 = math.min(v8 + v9, p1.states.bullets:get())
		if v11 > 0 then
			p1:cock(p2, false)
		end
		for j = 1, v11 do
			local v12
			p1.anim.Reload.arm1_idle1(v1, v4)
			if p1.anim.Reload.arm2_start2 then
				p1.anim.Reload.arm2_start2(v2, v4).Completed:Wait()
			end
			p2.values.cframes:get("arm2"):set_pivot("reload")
			p1.anim.Reload.base(v2, v4)
			if p1.anim.Reload.gun_idle then
				p1.anim.Reload.gun_idle(v3, v4)
			end
			if p1.states.single_load:get() then
				task.wait(0.15 * v4)
				local Bullets = script.Bullets
				p1.single_bullet = Bullets[p1.bullet_load_type or p1.bullet_type]:Clone()
				p1.single_bullet.Parent = p2.values.viewmodels
				p1.single_bullet.CanCollide = false
				p1.single_bullet:PivotTo(p2.values.viewmodels.arm2.CFrame * p1.hold_bullet_offset)
				Util.weld_c(p1.single_bullet, p2.values.viewmodels.arm2)
			else
				task.wait(0.5 * v4)
				if p1.cylinder and p1.loader then
					p1.loader.Bullets.Transparency = 0
					p1.loader.Parent = p2.values.viewmodels
					p1.loader.Case:PivotTo(p1.cframes:get(p1.loader.Case):render(1 / 60))
				end
			end
			p2.values.cframes:get("arm2"):remove_pivot("reload")
			p1.anim.Reload.arm1_idle2(v1, v4)
			p1.anim.Reload.arm2_idle(v2, v4).Completed:Wait()
			if p1.magazine then
				p1.cframes:get(p1.magazine):remove_pivot("reload")
				p1.magazine.Transparency = 0
				p1.sound.Reload2(p1.instance.Root)
				if p1.feed_cover then
					p1.anim.Reload.arm2_finish(v2, v4)
					p1.anim.Reload.arm1_finish(v1, v4).Completed:Wait()
					p1.sound.Chains(p1.instance.Root)
					if p1.end_bullet then
						p1.cframes:get(p1.end_bullet):remove_pivot("unloaded")
						p1.end_bullet.Transparency = 0
						for v14, v15 in p1.end_bullet:GetChildren() do
							if v15:IsA("BasePart") then
								v15.Transparency = 0
							end
						end
					end
					p1.anim.Reload.arm2_empty1_2(v2, v4)
					p1.anim.Reload.arm1_empty1(v1, v4).Completed:Wait()
					p1.states.loaded:set(true)
					p1.anim.Reload.gun_empty1(v3, v4)
					p1.anim.Reload.arm2_empty2(v2, v4).Completed:Wait()
					local v16 = p1.cframes:get(p1.feed_cover):get_offset("reload")
					p1.sound.FeedClose(p1.instance.Root)
					Util.tween(v16, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
						Value = CFrame.Angles(0, 0, 0)
					})
					p1.anim.Reload.arm2_empty1_3(v2, v4).Completed:Wait()
				else
					p1.states.loaded:set(true)
					p1.anim.Reload.arm2_finish(v2, v4)
					p1.anim.Reload.arm1_finish(v1, v4).Completed:Wait()
				end
			elseif p1.states.single_load:get() then
				p1.sound.Reload2(p1.instance.Root)
				p1.single_bullet:Destroy()
				if not p1.cylinder then
					p1.states.loaded:set(true)
					p1.states.load_bullet:fire()
				end
				p1.anim.Reload.arm2_finish(v2, v4)
				p1.anim.Reload.arm1_finish(v1, v4).Completed:Wait()
				if p1.cylinder then
					p1.states.loaded:set(true)
					p1.states.load_bullet:fire()
				end
				if p1.cylinder and (j == v11 or (p1.states.mag:get() >= p1.states.mag_size:get() or p1.states.bullets:get() <= 0)) then
					if p1.loader then
						p1.anim.Reload.arm1_start(v1, v4)
						p1.anim.Reload.gun(v3, v4)
						p1.anim.Reload.arm2_start(v2, v4).Completed:Wait()
						p1.sound.Reload1(p1.instance.Root)
						p1.anim.Reload.cylinder_close(p1.cframes:get(p1.cylinder):get_offset("reload"), v4)
					else
						p1.anim.Reload.gun(v3, v4)
						if p1.anim.Reload.arm1_empty2 then
							p1.anim.Reload.arm2_empty2(v2, v4)
							p1.anim.Reload.arm1_empty2(v1, v4).Completed:Wait()
						end
						if p1.anim.Reload.arm1_empty1 then
							p1.anim.Reload.arm2_empty1(v2, v4)
							p1.anim.Reload.arm1_empty1(v1, v4).Completed:Wait()
						end
						p1.sound.Reload1(p1.instance.Root)
						p1.anim.Reload.cylinder_close(p1.cframes:get(p1.cylinder):get_offset("reload"), v4)
					end
				end
			elseif p1.cylinder and p1.loader then
				p1.sound.Reload2(p1.instance.Root)
				p1.cframes:get(p1.loader.Case):set_pivot("reload")
				p1.anim.Reload.arm2_finish(v2, v4)
				p1.anim.Reload.arm1_finish(v1, v4).Completed:Wait()
				p1.cframes:get(p1.loader.Case):remove_pivot("reload")
				p1.loader.Bullets.Transparency = 1
				p1.states.loaded:set(true)
				p2.values.cframes:get("arm2"):set_pivot("reload")
				local v19 = p1.anim.Reload.base(v2, v4)
				v19.Completed:Connect(function() --[[ Line: 1331 | Upvalues: p1 (copy), p2 (copy) ]]
					if p1.loader then
						p1.loader.Parent = nil
						p1.cframes:get(p1.loader.Case):remove_pivot("reload")
					end
					p2.values.cframes:get("arm2"):remove_pivot("reload")
				end)
				if p1.anim.Reload.arm1_end1 then
					p1.anim.Reload.gun(v3, v4)
					p1.anim.Reload.arm1_end1(v1, v4).Completed:Wait()
					p1.sound.Reload1(p1.instance.Root)
					p1.anim.Reload.cylinder_close(p1.cframes:get(p1.cylinder):get_offset("reload"), v4)
					p1.anim.Reload.arm1_end2(v1, v4).Completed:Wait()
				else
					p1.anim.Reload.arm1_idle2(v1, v4)
					v19.Completed:Wait()
					p1.anim.Reload.arm1_start(v1, v4)
					p1.anim.Reload.gun(v3, v4)
					p1.anim.Reload.arm2_start(v2, v4).Completed:Wait()
					p1.sound.Reload1(p1.instance.Root)
					p1.anim.Reload.cylinder_close(p1.cframes:get(p1.cylinder):get_offset("reload"), v4)
				end
			end
			if p1.states.bullets:get() <= 0 or not p1.states.single_load:get() then
				break
			end
			local v22 = p1.states.mag:get()
			local v23 = p1.states.mag_size:get()
			if p1.states.chambered:get() then
				v12 = 1
			else
				v12 = 0
			end
			if v23 + v12 <= v22 then
				break
			end
		end
	end
	function t.reload_done(p1, p2) --[[ Line: 1369 ]]
		p2.values.cframes:get("arm1"):get_absolute("reload")
		p2.values.cframes:get("arm2"):get_absolute("reload")
		p1.cframes:get(p1.instance.Root):get_absolute("reload")
		p1.sound.Handle(p1.instance.Root)
		p2.values.cframes:get("arm1"):remove_absolute("reload")
		p2.values.cframes:get("arm2"):remove_absolute("reload")
		p1.cframes:get(p1.instance.Root):remove_absolute("reload")
		p1.safety:set(p2.values.holding and p2.values.holding.loadout_type == "primary")
	end
	function t.reload_cancel(p1, p2) --[[ Line: 1380 | Upvalues: Util (copy) ]]
		if p1 ~= nil then
			p2.values.cframes:get("arm1"):get_absolute("reload")
			p2.values.cframes:get("arm2"):get_absolute("reload")
			p1.cframes:get(p1.instance.Root):get_absolute("reload")
			if p1.single_bullet then
				p1.single_bullet:Destroy()
				p1.single_bullet = nil
			end
			if p1.loader then
				p1.loader.Parent = nil
				p1.cframes:get(p1.loader.Case):remove_pivot("reload")
			end
			p2.values.cframes:get("arm2"):remove_pivot("reload")
			if p1.end_bullet then
				if p1.states.loaded:get() then
					p1.cframes:get(p1.end_bullet):remove_pivot("unloaded")
				else
					if p1.cframes:get(p1.end_bullet):current_pivot() ~= "unloaded" then
						p1.cframes:get(p1.end_bullet):set_pivot("unloaded")
					end
					p1.end_bullet.Transparency = 1
					for v1, v2 in p1.end_bullet:GetChildren() do
						if v2:IsA("BasePart") then
							v2.Transparency = 1
						end
					end
				end
			end
			if p1.magazine then
				p1.cframes:get(p1.magazine):remove_pivot("reload")
				if not p1.states.loaded:get() then
					p1.magazine.Transparency = 1
				end
				if p1.feed_cover then
					Util.tween(p1.cframes:get(p1.feed_cover):get_offset("reload"), TweenInfo.new(0.1), {
						Value = CFrame.new(0, 0, 0)
					})
				end
			elseif p1.cylinder then
				Util.tween(p1.cframes:get(p1.cylinder):get_offset("reload"), TweenInfo.new(0.1), {
					Value = CFrame.new(0, 0, 0)
				})
			end
			p1.sound.Handle(p1.instance.Root)
			p2.values.cframes:get("arm1"):remove_absolute("reload")
			p2.values.cframes:get("arm2"):remove_absolute("reload")
			p1.cframes:get(p1.instance.Root):remove_absolute("reload")
			p1.safety:set(p2.values.holding and p2.values.holding.loadout_type == "primary")
		end
	end
	function t.cock_begin(p1, p2) --[[ Line: 1432 ]]
		local v1 = not p1.states.single_load:get()
		p1.sound.Handle(p1.instance.Root)
		local v2 = p1.states.reload_speed:get()
		if p1.right_hand_hold then
			p1.cframes:get(p1.instance.Root).pivot_time = 0.1
			p1.cframes:get(p1.instance.Root):set_pivot("equipped2")
		end
		local v3 = p2.values.cframes:get("arm1"):set_absolute("cock", true)
		local v4 = p2.values.cframes:get("arm2"):set_absolute("cock", true)
		local v5
		if p1.load_slide then
			local v6 = p1.cframes:get(p1.load_slide):set_offset("cock")
			p1.anim.Reload.slide_cock(v6, v2)
			if not v1 then
				p1.sound.Reload3(p1.instance.Root)
			end
			v5 = v6
		else
			v5 = nil
		end
		p1.anim.Reload.arm1_cock(v3, v2, p1)
		p1.anim.Reload.arm2_cock(v4, v2, p1).Completed:Wait()
		if v5 then
			p1.anim.Reload.slide_cocked(v5, v2)
			if v1 then
				p1.sound.Reload3(p1.instance.Root)
			else
				p1.sound.Reload4(p1.instance.Root)
				local BulletEject = p1.instance:FindFirstChild("BulletEject", true)
				if BulletEject then
					p1:eject_bullet(BulletEject, p1.bullet_type)
				end
			end
		else
			p1.states.chambered:set(true)
		end
		p1.anim.Reload.arm1_cocked(v3, v2, p1)
		p1.anim.Reload.arm2_cocked(v4, v2, p1).Completed:Wait()
		if v5 then
			p1.states.chambered:set(true)
		end
	end
	function t.cock_done(p1, p2) --[[ Line: 1479 ]]
		p2.values.cframes:get("arm1"):get_absolute("cock")
		p2.values.cframes:get("arm2"):get_absolute("cock")
		local v1
		if p1.load_slide then
			local v2 = p1.cframes:get(p1.load_slide):get_offset("cock")
			p1.anim.Reload.base(v2, 1)
			v1 = v2
		else
			v1 = nil
		end
		p1.sound.Handle(p1.instance.Root)
		if v1 then
			p1.cframes:get(v1):remove_offset("cock")
		end
		p2.values.cframes:get("arm1"):remove_absolute("cock")
		p2.values.cframes:get("arm2"):remove_absolute("cock")
		if p1.right_hand_hold then
			p1.cframes:get(p1.instance.Root):remove_pivot("equipped2")
		end
	end
	function t.cock_cancel(p1, p2) --[[ Line: 1498 ]]
		if p1 ~= nil then
			p2.values.cframes:get("arm1"):get_absolute("cock")
			p2.values.cframes:get("arm2"):get_absolute("cock")
			local v1
			if p1.load_slide then
				local v2 = p1.cframes:get(p1.load_slide):get_offset("cock")
				p1.anim.Reload.base(v2, 1)
				v1 = v2
			else
				v1 = nil
			end
			p1.sound.Handle(p1.instance.Root)
			if v1 then
				p1.cframes:get(v1):remove_offset("cock")
			end
			p2.values.cframes:get("arm1"):remove_absolute("cock")
			p2.values.cframes:get("arm2"):remove_absolute("cock")
			if p1.right_hand_hold then
				p1.cframes:get(p1.instance.Root):remove_pivot("equipped2")
			end
		end
	end
	function t.get_shoot_look(p1) --[[ Line: 1518 | Upvalues: FlagManager (copy) ]]
		shared.extras.ResetEnv()
		local owner = p1.owner
		if FlagManager.FLAG_ADS_CAMERA_BULLETS then
			local _ = owner.values.cframes:get("camera"):get_offset("shoot").Value
			return p1.shot.CFrame:Lerp((p1.reticule or p1.instance.Root.FrontSight).WorldCFrame, p1.accuracy.Value)
		else
			return p1.shot.CFrame
		end
	end
	function get_circular_spread(p1, p2) --[[ Line: 1532 ]]
		local v1 = math.random() * 2 * math.pi
		local v2 = math.random() ^ 0.35 * p2
		return (p1.RightVector * math.cos(v1) + p1.UpVector * math.sin(v1)) * v2
	end
	function t.send_shoot(p1) --[[ Line: 1539 | Upvalues: Util (copy) ]]
		local owner = p1.owner
		local v1 = p1:get_shoot_look()
		if p1.client_sided_hitscan then
			local v2 = p1.states.pellets:get() > 1
			local v3 = CFrame.new(Util.validate_position(game.Workspace.CurrentCamera.CFrame.Position, v1.Position, owner.values.ray_params)) * v1.Rotation
			local v4 = p1.states.pellets:get()
			local t = {}
			for i = 1, v4 do
				local v5
				local v7 = p1.states.spread:get() * 100
				if p1.red_dot and p1.red_dot.Transparency == 1 then
					v5 = 0.5
				else
					v5 = 1
				end
				local sum = v3.LookVector * 1000 + (1 - p1.accuracy.Value * v5 * math.map(i, 1, math.max(2, v4), 1, 0)) * get_circular_spread(v3, v7)
				if v2 then
					sum = sum - sum * 0.75
				end
				table.insert(t, (p1:ray_damage(v3.Position, sum, { owner.values.viewmodels, owner.instance }, nil)))
			end
			p1.states.shoot:fire(v1, t)
		else
			p1.states.shoot:fire(v1)
		end
	end
	function t.send_melee(p1) --[[ Line: 1582 ]]
		p1.states.melee:fire_instant()
		local v1 = p1.owner.values.camera:get().CFrame
		if p1.client_sided_hitscan then
			local owner = p1.owner
			p1.states.hit:fire(v1, (p1:ray_damage(v1.Position - v1.LookVector * 0.2, v1.LookVector * 2.95, { owner.values.viewmodels, owner.instance }, 0.2)))
		else
			p1.states.hit:fire(v1)
		end
	end
	function t.input_ads(p1, p2, p3) --[[ Line: 1601 | Upvalues: Data (copy), UI (copy) ]]
		p1.ads_hold = p2
		local owner = p1.owner
		if not (p2 and owner.values.prone_debounce) and (owner and (owner.values.equipped == p1 and not p1.meleeing)) then
			p1.owner.states.running:set(false)
			if Data.settings.toggle_aim and not p3 then
				if p2 then
					p1.states.sights:update(function(p1) --[[ Line: 1609 ]]
						return not p1
					end)
					UI.get("CancelScope").Visible = p1.states.sights:get()
				end
			else
				p1.states.sights:set(p2)
			end
		end
	end
	function t.input_shoot(p1, p2, p3) --[[ Line: 1620 | Upvalues: Data (copy), UI (copy) ]]
		local owner = p1.owner
		if owner and (owner.values.equipped == p1 and (not p1.safety:get() or p1.accuracy.Value >= 1)) and not (owner.states.running:get() or owner.values.equip_debounce:get()) then
			local v1 = os.clock()
			local v2 = p1.states.firerate:get()
			if (p2 and (not p3 or p1.automatic) or not p2 and (p3 and (not p1.automatic and p1.shoot_hold))) and (v2 == 0 or 1 / (v2 / 60) < v1 - p1.last_shot) then
				if p1.states.mag:get() > 0 and p1.states.chambered:get() then
					p1.last_shot = v1
					p1:send_shoot()
				else
					p1:reload(owner, false)
				end
			end
		end
		if Data.settings.auto_ads and (p3 or not UI.get("ShootJoystickFrame").Visible) then
			if p2 and not p1.states.sights:get() then
				p1:input_ads(true, not Data.settings.lock_auto_ads)
			elseif not (p2 or (UI.get("CancelScope").Visible or Data.settings.lock_auto_ads)) then
				p1:input_ads(false, true)
			end
		end
		p1.shoot_hold = p2
	end
	function t.hook_inputs(p1) --[[ Line: 1644 | Upvalues: UI (copy), Input (copy), FirstPersonInterface (copy) ]]
		local inputs = p1.inputs
		p1.owner.states.equipped:hook(function(p12) --[[ Line: 1647 | Upvalues: p1 (copy), inputs (copy) ]]
			if p12 == p1.instance then
				inputs.enabled:set(true)
			else
				inputs.enabled:set(false)
			end
		end)
		p1.owner.values.equip_debounce:hook(function(p12) --[[ Line: 1655 | Upvalues: p1 (copy) ]]
			if p12 then
				p1.states.sights:set(false)
			end
		end)
		inputs.enabled:hook(function(p1) --[[ Line: 1661 | Upvalues: UI (ref) ]]
			if p1 then
				UI.get("CancelScope").Visible = false
				UI.get("CancelShoot").Visible = false
			end
		end)
		inputs:get("shoot"):press(function(p12) --[[ Line: 1668 | Upvalues: UI (ref), p1 (copy) ]]
			if p12 and UI.get("CancelShoot").Visible then
				p1.shoot_hold = false
				p1:input_shoot(false)
				UI.get("CancelShoot").Visible = false
			else
				p1:input_shoot(p12)
			end
		end)
		inputs:get("shoot_joystick"):press(function(p12) --[[ Line: 1678 | Upvalues: p1 (copy), UI (ref) ]]
			p1:input_shoot(p12, true)
			UI.get("CancelShoot").Visible = not p1.automatic and (p12 and true or false)
		end)
		inputs:get("aim"):press(function(p12) --[[ Line: 1683 | Upvalues: p1 (copy), Input (ref) ]]
			p1:input_ads(p12)
			if p1.owner and (not p12 and Input.current_device:get() == "console") then
				p1.owner.states.lean:set(0)
			end
		end)
		inputs:get("reload"):press(function(p12) --[[ Line: 1690 | Upvalues: p1 (copy) ]]
			local owner = p1.owner
			if p12 and (owner and (not p1.reload_thread.running and (not owner.values.equip_debounce:get() and (not owner.values.prone_debounce and (owner.values.equipped == p1 and (owner.states.vault:get() == 0 and (not owner.states.running:get() and p1.states.bullets:get() > 0))))))) then
				local v1 = p1.states.mag:get()
				local v2
				if p1.cylinder then
					v2 = 0
				else
					v2 = 1
				end
				if v1 - v2 < p1.states.mag_size:get() then
					p1.states.sights:set(false)
					p1.ads_hold = false
					local holding = owner.values.holding
					if holding and holding.can_reload == false then
						owner.states.holding:set(owner.values.hands)
						while owner.values.equip_debounce:get() or owner.values.holding == holding do
							owner.values.equip_debounce:wait()
						end
					end
					p1.states.reload:fire()
				end
			end
		end)
		FirstPersonInterface.setup_action(inputs, function() --[[ Line: 1709 | Upvalues: p1 (copy) ]]
			local v1 = not p1.reload_thread.running
			if v1 then
				v1 = not p1.cock_thread.running
				if v1 and p1.states.mag:get() < p1.states.mag_size:get() * 0.2 then
					v1 = p1.states.bullets:get() > 0
				elseif v1 then
					v1 = false
				end
			end
			return v1
		end, "Reload", "reload")
	end
	function t.update_ui(p1) --[[ Line: 1721 ]]
		local v2 = ("%*/%*"):format(p1.states.mag:get(), (p1.states.bullets:get()))
		for v3, v4 in p1.hooked_labels do
			v4.Text = v2
		end
	end
	function t.load() --[[ Line: 1728 | Upvalues: StateObject (copy), t (copy), State (copy), v2 (copy), Globals (copy) ]]
		StateObject.class(t.tag, function() --[[ Line: 1729 | Upvalues: State (ref), v2 (ref), Globals (ref) ]]
			local t = {
				loaded = State.new(true),
				mag_size = State.new(0),
				bullets = State.new(0),
				speed = State.new(1),
				sights = State.new(false),
				reload = v2.new(),
				cock = v2.new(),
				melee = v2.new(),
				firerate = State.new(0),
				ads = State.new(0),
				reload_speed = State.new(1),
				recoil_up = State.new(1),
				recoil_side = State.new(0),
				trail_size = State.new(0),
				single_load = State.new(false),
				zoom = State.new(1),
				load_bullet = v2.new(),
				shoot = v2.new(),
				hit = v2.new(),
				spread = State.new(1),
				pellets = State.new(1),
				accuracy = State.new(1),
				mag = State.new(0),
				chambered = State.new(true)
			}
			for v1, v22 in Globals.attachment_types do
				t[v22 .. "_att"] = State.new("")
			end
			return t, {}
		end):hook(function(p1) --[[ Line: 1768 ]] end)
	end
end
return t
