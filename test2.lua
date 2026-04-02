pcall(function() setthreadidentity(8) end)
pcall(function() game:GetService("WebViewService"):Destroy() end)

run_on_actor(getactors()[1], [==[
pcall(function() setthreadidentity(8) end)

local USE_PROPERTY_SPOOFING = true  

--services
local cloneref = cloneref or function(obj) return obj end
local clonefunction = clonefunction or function(fn) return fn end
local Workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local task_delay = clonefunction(task.delay)
local table_insert = clonefunction(table.insert)
local tick = clonefunction(tick)
local pairs = clonefunction(pairs)
local ipairs = clonefunction(ipairs)
local print = clonefunction(print)
local Vector3_new = clonefunction(Vector3.new)
local Color3_fromRGB = clonefunction(Color3.fromRGB)
local Instance_new = clonefunction(Instance.new)
local newcclosure = newcclosure or function(f) return f end

--viewmodels folder
local ViewmodelsFolder = Workspace:WaitForChild("Viewmodels")

--settings
local HITBOX_SIZE = 5
local HITBOX_TRANSPARENCY = 0.5
local HITBOX_COLOR = Color3_fromRGB(255, 0, 0)
local TOGGLE_KEY = Enum.KeyCode.H

local ENABLED = true
local globalConnections = {}
local modifiedHeads = {}
local originalData = {}
local viewmodelConnections = {}  



--hooks
local hookfunction = hookfunction or function(f, r) return f end

local old_GetPropertyChangedSignal = hookfunction(game.GetPropertyChangedSignal, newcclosure(function(self, property)
    if originalData[self] and (property == "Size" or property == "Transparency" or property == "Color") then
        return Instance_new("BindableEvent").Event
    end
    return old_GetPropertyChangedSignal(self, property)
end))

if USE_PROPERTY_SPOOFING then
    local hookmetamethod = hookmetamethod or function() end
    local getrawmetatable = getrawmetatable or function() return {} end
    local setreadonly = setreadonly or function() end
    
    local mt = getrawmetatable(game)
    local old_index = mt.__index
    setreadonly(mt, false)
    
    mt.__index = newcclosure(function(self, key)
        if originalData[self] then
            if key == "Size" then
                return originalData[self].Size
            elseif key == "Transparency" then
                return originalData[self].Transparency
            elseif key == "Color" then
                return originalData[self].Color
            end
        end
        return old_index(self, key)
    end)
    
    setreadonly(mt, true)
    print("✅ Property spoofing: ENABLED")
else
    print("⚠️ Property spoofing: DISABLED")
end


--team filtering
local teamCache = {}
local lastCacheUpdate = 0

local updateTeamCache = newcclosure(function()
    teamCache = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Highlight") and obj.Adornee then
            teamCache[obj.Adornee] = true
        end
    end
end)

local isTeammate = newcclosure(function(vm)
    if tick() - lastCacheUpdate > 0.5 then
        updateTeamCache()
        lastCacheUpdate = tick()
    end
    return teamCache[vm] == true
end)


--hitboxes
local shouldModify = newcclosure(function(vm)
    if vm.Name == "LocalViewmodel" then return false end
    local torso = vm:FindFirstChild("torso")
    if not torso or torso.Transparency == 1 then return false end
    return not isTeammate(vm)
end)

local applyHitbox = newcclosure(function(head)
    if not ENABLED or not head or head.Name ~= "head" then return end
    
    if not originalData[head] then
        originalData[head] = {
            Size = head.Size,
            Transparency = head.Transparency,
            Color = head.Color
        }
    end
    
    head.Size = Vector3_new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
    head.Transparency = HITBOX_TRANSPARENCY
    head.Color = HITBOX_COLOR
    modifiedHeads[head] = true
end)

local resetHead = newcclosure(function(head)
    if head and originalData[head] then
        head.Size = originalData[head].Size
        head.Transparency = originalData[head].Transparency
        head.Color = originalData[head].Color
        
        originalData[head] = nil
        modifiedHeads[head] = nil
    end
end)



--clean ups
local cleanupViewmodel = newcclosure(function(vm)
    if viewmodelConnections[vm] then
        for _, conn in ipairs(viewmodelConnections[vm]) do
            pcall(function() conn:Disconnect() end)
        end
        viewmodelConnections[vm] = nil
    end
    
    for head in pairs(modifiedHeads) do
        if head:IsDescendantOf(vm) or head.Parent == nil then
            resetHead(head)
        end
    end
end)


--init
local processViewmodel = newcclosure(function(vm)
    if not vm or not vm:IsA("Model") then return end
    if vm.Name == "LocalViewmodel" then return end
    if viewmodelConnections[vm] then return end
    
    viewmodelConnections[vm] = {}

    local function tryApply()
        if not vm or vm.Parent == nil then
            return
        end

        local head = vm:FindFirstChild("head")
        if shouldModify(vm) then
            if head then applyHitbox(head) end
        else
            if head and modifiedHeads[head] then
                resetHead(head)
            end
        end
    end
    
    task_delay(0.05, newcclosure(tryApply))
    for i = 1, 12 do
        task_delay(0.1 * i, newcclosure(tryApply))
    end

    local function hookTorsoTransparency(torso)
        if not torso or not torso:IsA("BasePart") then return end
        local conn = torso:GetPropertyChangedSignal("Transparency"):Connect(newcclosure(function()
            tryApply()
        end))
        table_insert(viewmodelConnections[vm], conn)
    end

    hookTorsoTransparency(vm:FindFirstChild("torso"))
    
    local childAddedConn = vm.ChildAdded:Connect(newcclosure(function(child)
        if child.Name == "head" or child.Name == "torso" then
            if child.Name == "torso" then
                hookTorsoTransparency(child)
            end
            task_delay(0.05, newcclosure(function()
                tryApply()
            end))
        end
    end))
    table_insert(viewmodelConnections[vm], childAddedConn)
    
    local ancestryConn = vm.AncestryChanged:Connect(newcclosure(function(_, parent)
        if not parent then
            cleanupViewmodel(vm)
        else
            tryApply()
        end
    end))
    table_insert(viewmodelConnections[vm], ancestryConn)
end)


--toggles
local toggle = newcclosure(function()
    ENABLED = not ENABLED
    print(ENABLED and "✅ Hitbox Expander: ENABLED" or "❌ Hitbox Expander: DISABLED")
    
    if ENABLED then
        updateTeamCache()
        for _, vm in ipairs(ViewmodelsFolder:GetChildren()) do
            if vm:IsA("Model") then processViewmodel(vm) end
        end
    else
        for vm in pairs(viewmodelConnections) do
            cleanupViewmodel(vm)
        end
    end
end)


--playes hitbox init
updateTeamCache()

table_insert(globalConnections, ViewmodelsFolder.ChildAdded:Connect(newcclosure(function(vm)
    if vm:IsA("Model") then 
        processViewmodel(vm)
    end
end)))

table_insert(globalConnections, ViewmodelsFolder.ChildRemoved:Connect(newcclosure(function(vm)
    if vm:IsA("Model") then 
        cleanupViewmodel(vm)
    end
end)))

for _, vm in ipairs(ViewmodelsFolder:GetChildren()) do
    if vm:IsA("Model") then processViewmodel(vm) end
end

-- periodic reconcile so late-ready models still auto-apply
do
    local lastSweep = 0
    table_insert(globalConnections, RunService.Heartbeat:Connect(newcclosure(function()
        if not ENABLED then return end

        local now = tick()
        if now - lastSweep < 0.25 then return end
        lastSweep = now

        for _, vm in ipairs(ViewmodelsFolder:GetChildren()) do
            if vm:IsA("Model") and vm.Name ~= "LocalViewmodel" then
                if not viewmodelConnections[vm] then
                    processViewmodel(vm)
                end

                local head = vm:FindFirstChild("head")
                if head then
                    if shouldModify(vm) then
                        applyHitbox(head)
                    elseif modifiedHeads[head] then
                        resetHead(head)
                    end
                end
            end
        end
    end)))
end

table_insert(globalConnections, Workspace.CurrentCamera.ChildAdded:Connect(newcclosure(function(part)
    if part:IsA("BasePart") and part.Name == "head" then 
        resetHead(part)
    end
end)))

local localViewmodel = ViewmodelsFolder:FindFirstChild("LocalViewmodel")
if localViewmodel then
    local conn = localViewmodel.ChildAdded:Connect(newcclosure(function(child)
        if child.Name == "head" then
            resetHead(child)
        end
    end))
    table_insert(globalConnections, conn)
end

-- Toggle keybind
table_insert(globalConnections, UserInputService.InputBegan:Connect(newcclosure(function(input, processed)
    if not processed and input.KeyCode == TOGGLE_KEY then 
        toggle()
    end
end)))

print("═══════════════════════════════════════════════")
print("✅ FINAL CLEAN Hitbox Expander ACTIVE")
print("═══════════════════════════════════════════════")
print("✅ Auto-apply on spawn: ENABLED")
print("✅ Auto-cleanup on despawn: ENABLED")
print("✅ Bypass layers:")
print("   • cloneref (service masking)")
print("   • clonefunction (function masking)")
print("   • hookfunction (method hooks)")
if USE_PROPERTY_SPOOFING then
    print("   • hookmetamethod (property spoofing)")
end
print("═══════════════════════════════════════════════")
print("Press [H] to toggle ON/OFF")
]==])
