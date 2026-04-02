run_on_actor(getactors()[1], [==[

local USE_PROPERTY_SPOOF = true

local cloneref = cloneref or function(obj) return obj end
local newcclosure = newcclosure or function(fn) return fn end
local clonefunction = clonefunction or function(fn) return fn end
local hookfunction = hookfunction or function(fn, replacement) return fn end
local hookmetamethod = hookmetamethod or function() end
local getrawmetatable = getrawmetatable or function() return {} end
local setreadonly = setreadonly or function() end

local workspace = cloneref(game:GetService("Workspace"))
local userInput = cloneref(game:GetService("UserInputService"))
local runService = cloneref(game:GetService("RunService"))

local delayTask = clonefunction(task.delay)
local insert = clonefunction(table.insert)
local now = clonefunction(tick)
local vec3 = clonefunction(Vector3.new)
local color3 = clonefunction(Color3.fromRGB)
local createInstance = clonefunction(Instance.new)

local viewmodelsFolder = workspace:WaitForChild("Viewmodels")

local HEAD_SIZE = 5
local HEAD_ALPHA = 0.5
local HEAD_COLOR = color3(255, 0, 0)
local TOGGLE_KEY = Enum.KeyCode.H -- set to nil for always-on (no key toggle)

local isEnabled = true
local allConnections = {}
local vmConnections = setmetatable({}, { __mode = "k" })
local editedHeads = setmetatable({}, { __mode = "k" })
local originalHeadState = setmetatable({}, { __mode = "k" })

local function saveHeadState(head)
    if originalHeadState[head] then
        return
    end
    originalHeadState[head] = {
        Size = head.Size,
        Transparency = head.Transparency,
        Color = head.Color
    }
end

local originalGetPropertyChangedSignal
originalGetPropertyChangedSignal = hookfunction(
    game.GetPropertyChangedSignal,
    newcclosure(function(self, property)
        if originalHeadState[self] and (
            property == "Size" or
            property == "Transparency" or
            property == "Color"
        ) then
            return createInstance("BindableEvent").Event
        end
        return originalGetPropertyChangedSignal(self, property)
    end)
)

if USE_PROPERTY_SPOOF then
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)

    mt.__index = newcclosure(function(self, key)
        local state = originalHeadState[self]
        if state then
            if key == "Size" then
                return state.Size
            elseif key == "Transparency" then
                return state.Transparency
            elseif key == "Color" then
                return state.Color
            end
        end
        return oldIndex(self, key)
    end)

    setreadonly(mt, true)
end

local teammateModels = setmetatable({}, { __mode = "k" })
local lastTeamScan = 0

local function refreshTeamCache()
    teammateModels = setmetatable({}, { __mode = "k" })
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Highlight") and obj.Adornee then
            teammateModels[obj.Adornee] = true
        end
    end
end

local function isTeammateModel(vm)
    local t = now()
    if t - lastTeamScan > 0.5 then
        refreshTeamCache()
        lastTeamScan = t
    end
    return teammateModels[vm] == true
end

local function shouldExpand(vm)
    if vm.Name == "LocalViewmodel" then
        return false
    end
    local torso = vm:FindFirstChild("torso")
    if not torso or torso.Transparency == 1 then
        return false
    end
    return not isTeammateModel(vm)
end

local function applyHead(head)
    if not isEnabled or not head or head.Name ~= "head" then
        return
    end
    saveHeadState(head)
    head.Size = vec3(HEAD_SIZE, HEAD_SIZE, HEAD_SIZE)
    head.Transparency = HEAD_ALPHA
    head.Color = HEAD_COLOR
    editedHeads[head] = true
end

local function restoreHead(head)
    local state = head and originalHeadState[head]
    if not state then
        return
    end
    head.Size = state.Size
    head.Transparency = state.Transparency
    head.Color = state.Color
    originalHeadState[head] = nil
    editedHeads[head] = nil
end

local function cleanupViewmodel(vm)
    local list = vmConnections[vm]
    if list then
        for _, conn in ipairs(list) do
            pcall(function() conn:Disconnect() end)
        end
        vmConnections[vm] = nil
    end

    for head in pairs(editedHeads) do
        if head.Parent == nil or head:IsDescendantOf(vm) then
            restoreHead(head)
        end
    end
end

local function attachViewmodel(vm)
    if not vm or not vm:IsA("Model") or vm.Name == "LocalViewmodel" then
        return
    end
    if vmConnections[vm] then
        return
    end

    vmConnections[vm] = {}

    local function refreshOne()
        if not vm or vm.Parent == nil then
            return
        end

        local head = vm:FindFirstChild("head")
        if shouldExpand(vm) then
            if head then
                applyHead(head)
            end
        elseif head and editedHeads[head] then
            restoreHead(head)
        end
    end

    delayTask(0.05, newcclosure(refreshOne))
    for i = 1, 12 do
        delayTask(0.1 * i, newcclosure(refreshOne))
    end

    local function watchTorso(torso)
        if not torso or not torso:IsA("BasePart") then
            return
        end
        local conn = torso:GetPropertyChangedSignal("Transparency"):Connect(newcclosure(function()
            refreshOne()
        end))
        insert(vmConnections[vm], conn)
    end

    watchTorso(vm:FindFirstChild("torso"))

    insert(vmConnections[vm], vm.ChildAdded:Connect(newcclosure(function(child)
        if child.Name == "torso" then
            watchTorso(child)
            delayTask(0.05, newcclosure(refreshOne))
        elseif child.Name == "head" then
            delayTask(0.05, newcclosure(refreshOne))
        end
    end)))

    insert(vmConnections[vm], vm.AncestryChanged:Connect(newcclosure(function(_, parent)
        if not parent then
            cleanupViewmodel(vm)
        else
            refreshOne()
        end
    end)))
end

local function toggleExpander()
    isEnabled = not isEnabled

    if isEnabled then
        refreshTeamCache()
        for _, vm in ipairs(viewmodelsFolder:GetChildren()) do
            if vm:IsA("Model") then
                attachViewmodel(vm)
            end
        end
    else
        for vm in pairs(vmConnections) do
            cleanupViewmodel(vm)
        end
    end
end

refreshTeamCache()

insert(allConnections, viewmodelsFolder.ChildAdded:Connect(newcclosure(function(vm)
    if vm:IsA("Model") then
        attachViewmodel(vm)
    end
end)))

insert(allConnections, viewmodelsFolder.ChildRemoved:Connect(newcclosure(function(vm)
    if vm:IsA("Model") then
        cleanupViewmodel(vm)
    end
end)))

for _, vm in ipairs(viewmodelsFolder:GetChildren()) do
    if vm:IsA("Model") then
        attachViewmodel(vm)
    end
end

do
    local lastSweep = 0
    insert(allConnections, runService.Heartbeat:Connect(newcclosure(function()
        if not isEnabled then
            return
        end

        local t = now()
        if t - lastSweep < 0.25 then
            return
        end
        lastSweep = t

        for _, vm in ipairs(viewmodelsFolder:GetChildren()) do
            if vm:IsA("Model") and vm.Name ~= "LocalViewmodel" then
                if not vmConnections[vm] then
                    attachViewmodel(vm)
                end

                local head = vm:FindFirstChild("head")
                if head then
                    if shouldExpand(vm) then
                        applyHead(head)
                    elseif editedHeads[head] then
                        restoreHead(head)
                    end
                end
            end
        end
    end)))
end

insert(allConnections, workspace.CurrentCamera.ChildAdded:Connect(newcclosure(function(child)
    if child:IsA("BasePart") and child.Name == "head" then
        restoreHead(child)
    end
end)))

local localViewmodel = viewmodelsFolder:FindFirstChild("LocalViewmodel")
if localViewmodel then
    insert(allConnections, localViewmodel.ChildAdded:Connect(newcclosure(function(child)
        if child.Name == "head" then
            restoreHead(child)
        end
    end)))
end

if TOGGLE_KEY then
    insert(allConnections, userInput.InputBegan:Connect(newcclosure(function(inputObj, processed)
        if not processed and inputObj.KeyCode == TOGGLE_KEY then
            toggleExpander()
        end
    end)))
    print("Toggle key:", tostring(TOGGLE_KEY))
else
    print("Always On")
end
]==])
