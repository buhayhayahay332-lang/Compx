run_on_actor(getactors()[1], [==[
    local rs = game:GetService("ReplicatedStorage")
    local input = game:GetService("UserInputService")
    local world = game:GetService("Workspace")

    local gunClass = require(rs.Modules.Items.Item.Gun)
    local oldLook = gunClass.get_shoot_look

    local radius = 150
    local radius_sq = radius * radius
    local targetMode = "custom_parts" -- ("head_only" | "custom_parts") --u can use these modes

    local customParts = {
        "head", "torso",
        "shoulder1", "shoulder2",
        "arm1", "arm2",
        "hip1", "hip2",
        "leg1", "leg2"
    }

    local function getPartList()
        if targetMode == "head_only" then
            return { "head" }
        end
        return customParts
    end

    local function pickAimPart()
        local best, best_d2 = nil, math.huge
        local mouse = input:GetMouseLocation()
        local cam = world.CurrentCamera

        local function consider(p)
            if not p or not p:IsA("BasePart") then
                return
            end

            local v2, ok = cam:WorldToViewportPoint(p.Position)
            if not ok then
                return
            end

            local dx = v2.X - mouse.X
            local dy = v2.Y - mouse.Y
            local d2 = dx * dx + dy * dy
            if d2 <= radius_sq and d2 < best_d2 then
                best = p
                best_d2 = d2
            end
        end

        local viewmodels = world:FindFirstChild("Viewmodels")
        if viewmodels then
            for _, vm in ipairs(viewmodels:GetChildren()) do
                if vm.Name == "LocalViewmodel" then
                    continue
                end
                if vm.Name ~= "Viewmodel" then
                    continue
                end

                local torso = vm:FindFirstChild("torso")
                if torso and torso.Transparency == 1 then
                    continue
                end

                for _, name in ipairs(getPartList()) do
                    consider(vm:FindFirstChild(name))
                end
            end
        end

        for _, model in ipairs(world:GetChildren()) do
            if not model:IsA("Model") then
                continue
            end

            if model.Name == "Drone" then
                consider(model:FindFirstChild("HumanoidRootPart"))
            elseif model.Name == "Claymore" then
                local laser = model:FindFirstChild("Laser")
                if laser then
                    consider(laser)
                else
                    for _, child in ipairs(model:GetChildren()) do
                        if child:IsA("BasePart") and child.Name == "Laser" then
                            consider(child)
                        end
                    end
                end
            end
        end

        return best
    end

    gunClass.get_shoot_look = function(self)
        local look = oldLook(self)
        local target = pickAimPart()
        if not target then
            return look
        end

        local origin = look.Position
        local dir = (target.Position - origin).Unit
        return CFrame.lookAt(origin, origin + dir)
    end
]==])
