if getgenv()._aurorasigma then
    pcall(function()
        if _G.hyperion_unload then _G.hyperion_unload() end
    end)
    getgenv()._aurorasigma = nil
    task.wait(0.1)
end

getgenv()._aurorasigma = true

local ContentProvider = game:GetService("ContentProvider")
local LogService = game:GetService("LogService")

local hook = hookfunction or detour_function or (replaceclosure and function(old, new)
    return replaceclosure(old, new)
end)

local cclosure = newcclosure or function(f)
    return f
end

local renv = getrenv and getrenv() or _G

local set_readonly = setreadonly or (make_writeable and function(t, v)
    if v then
        make_writeable(t)
    else
        make_readonly(t)
    end
end)

local function isRelevantCaller()
    for i = 3, 6 do
        local src = debug.info(i, "s")
        if src and (
            src:find("RemoveLoadingScreen") or
            src:find("Loading") or
            src:find("Detection")
        ) then
            return true
        end
    end

    if getcallingscript then
        local ok, script = pcall(getcallingscript)
        if ok and script then
            local name = tostring(script)
            if name:find("RemoveLoadingScreen") or name:find("Loading") then
                return true
            end
        end
    end

    return false
end

local originalRandom
originalRandom = hook(renv.math.random, cclosure(function(...)
    if isRelevantCaller() then
        return 0
    end
    return originalRandom(...)
end))

local originalPreloadAsync
originalPreloadAsync = hook(ContentProvider.PreloadAsync, cclosure(function(self, assets, callback)
    if self ~= ContentProvider then
        return originalPreloadAsync(self, assets, callback)
    end

    if isRelevantCaller() and type(assets) == "table" then
        if callback then
            for _, asset in ipairs(assets) do
                task.spawn(pcall, callback, asset, Enum.AssetFetchStatus.Success)
            end
        end
        return
    end

    return originalPreloadAsync(self, assets, callback)
end))

local mt = getrawmetatable(game)
if mt and set_readonly then
    local originalNamecall = mt.__namecall

    set_readonly(mt, false)

    mt.__namecall = cclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }

        if method == "PreloadAsync" and self == ContentProvider and isRelevantCaller() then
            pcall(function()
                local assets, callback = args[1], args[2]
                if type(assets) == "table" and callback then
                    for _, asset in ipairs(assets) do
                        task.spawn(pcall, callback, asset, Enum.AssetFetchStatus.Success)
                    end
                end
            end)
            return
        end

        return originalNamecall(self, ...)
    end)

    set_readonly(mt, true)
end

if queue_on_teleport then
    local scriptSource = nil


    if getgenv()._hyperion_source then
        scriptSource = getgenv()._hyperion_source
    else


        local success, source = pcall(function()
            if readfile and isfile and isfile("hyperion/hyperion_source.lua") then
                return readfile("hyperion/hyperion_source.lua")
            end
            return nil
        end)

        if success and source then
            scriptSource = source
        end
    end


    if scriptSource then
        getgenv()._hyperion_source = scriptSource
        queue_on_teleport(scriptSource)
    else

        queue_on_teleport([[
            getgenv()._aurorasigma = nil -- Reset so bypass runs again

            local ContentProvider = game:GetService("ContentProvider")
            local hook = hookfunction or detour_function or (replaceclosure and function(old, new)
                return replaceclosure(old, new)
            end)
            local cclosure = newcclosure or function(f) return f end
            local renv = getrenv and getrenv() or _G
            local set_readonly = setreadonly or (make_writeable and function(t, v)
                if v then make_writeable(t) else make_readonly(t) end
            end)

            local function isRelevantCaller()
                for i = 3, 6 do
                    local src = debug.info(i, "s")
                    if src and (src:find("RemoveLoadingScreen") or src:find("Loading") or src:find("Detection")) then
                        return true
                    end
                end
                if getcallingscript then
                    local ok, script = pcall(getcallingscript)
                    if ok and script then
                        local name = tostring(script)
                        if name:find("RemoveLoadingScreen") or name:find("Loading") then return true end
                    end
                end
                return false
            end

            local originalRandom
            originalRandom = hook(renv.math.random, cclosure(function(...)
                if isRelevantCaller() then return 0 end
                return originalRandom(...)
            end))

            local originalPreloadAsync
            originalPreloadAsync = hook(ContentProvider.PreloadAsync, cclosure(function(self, assets, callback)
                if self ~= ContentProvider then return originalPreloadAsync(self, assets, callback) end
                if isRelevantCaller() and type(assets) == "table" then
                    if callback then
                        for _, asset in ipairs(assets) do
                            task.spawn(pcall, callback, asset, Enum.AssetFetchStatus.Success)
                        end
                    end
                    return
                end
                return originalPreloadAsync(self, assets, callback)
            end))

            local mt = getrawmetatable(game)
            if mt and set_readonly then
                local originalNamecall = mt.__namecall
                set_readonly(mt, false)
                mt.__namecall = cclosure(function(self, ...)
                    local method = getnamecallmethod()
                    local args = { ... }
                    if method == "PreloadAsync" and self == ContentProvider and isRelevantCaller() then
                        pcall(function()
                            local assets, callback = args[1], args[2]
                            if type(assets) == "table" and callback then
                                for _, asset in ipairs(assets) do
                                    task.spawn(pcall, callback, asset, Enum.AssetFetchStatus.Success)
                                end
                            end
                        end)
                        return
                    end
                    return originalNamecall(self, ...)
                end)
                set_readonly(mt, true)
            end
        ]])
    end
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

local SelectedLanguage = GG.Language

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        tablein(result, trimmedValue)
    end

    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local PlayerGui = cloneref(game:GetService('PlayerGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_hyperion = PlayerGui and PlayerGui:FindFirstChild('hyperion')

if old_hyperion then
    Debris:AddItem(old_hyperion, 0)
end

if not isfolder("hyperion") then
    makefolder("hyperion")
end

local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end

        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end

            value:Disconnect()
        end
    end
}, Connections)

local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)

        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self: any)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y

        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)

local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)

    self:setup()

    return self
end

function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')

    if old_folder then
        Debris:AddItem(old_folder, 0)
    end

    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera

    self._folder = folder
end

function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting

    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end

        if object == depth_of_fields then
            continue
        end

        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)

        object.FarIntensity = 0
    end
end

function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object

    self._frame = frame
end

function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder


    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)
    specialMesh.Parent = part

    self._root = part
end

function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()

    self:create_frame()
    self:render(0.001)

    self:check_quality_level()
end

function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        local mesh = self._root:FindFirstChildOfClass('SpecialMesh')
        if mesh then mesh.Scale = Vector3.new(width, height, 0) end
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)

    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)

    task.spawn(update)
end

function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end

local function loadConfig(file_name)
    local success, result = pcall(function()
        if not isfile('hyperion/'..file_name..'.json') then
            return { _flags = {}, _keybinds = {}, _library = {} }
        end
        local flags = readfile('hyperion/'..file_name..'.json')
        if not flags then
            return { _flags = {}, _keybinds = {}, _library = {} }
        end
        return HttpService:JSONDecode(flags)
    end)
    if not success or not result then
        return { _flags = {}, _keybinds = {}, _library = {} }
    end
    return result
end

local function saveConfig(file_name, config)
    pcall(function()
        writefile('hyperion/'..file_name..'.json', HttpService:JSONEncode(config))
    end)
end

local Library = {
    _config = loadConfig(game.GameId),

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil
}
Library.__index = Library

function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)

    self:create_ui()

    return self
end

function Library.SendNotification(settings)
    if _G.ShowNotification then
        local opts = type(settings) == "table" and settings or {}
        _G.ShowNotification(opts.text or "", opts.duration or 3, {
            title = opts.title or "Notification",
            type = opts.type or "info"
        })
    end
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end

function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end

function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end

if type(Junkie) ~= "table" then
    local ok, junkieResult = pcall(function()
        return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
    end)
    if ok and type(junkieResult) == "table" then
        Junkie = junkieResult
        Junkie.service = "Main"
        Junkie.identifier = "1141790"
        Junkie.provider = "Main"
    end
end

function Library:RunJunkieKeyValidation()
    local key = nil
    local keyPath = "SakuraUI/Hyperionkey.txt"
    if type(isfile) == "function" and isfile(keyPath) then
        local ok, raw = pcall(readfile, keyPath)
        if ok and type(raw) == "string" then
            key = raw:match("^%s*(.-)%s*$")
        end
    end

    if not key then
        return { valid = false, status = "none", expiresAt = nil, remainingText = "Key: None" }
    end

    if type(Junkie) ~= "table" or type(Junkie.check_key) ~= "function" then
        return { valid = false, status = "none", expiresAt = nil, remainingText = "Key: None" }
    end

    local ok, result = pcall(function()
        return Junkie.check_key(key)
    end)

    if not ok or type(result) ~= "table" then
        return { valid = false, status = "invalid", expiresAt = nil, remainingText = "Key: Invalid" }
    end

    if result.valid == true then
        getgenv().SCRIPT_KEY = key

        local expiresAt = result.expiresAt or getgenv().JD_EXPIRES_AT
        local remainingText = "Lifetime"

        if expiresAt and tonumber(expiresAt) then
            local remaining = math.max(0, tonumber(expiresAt) - os.time())
            local days = math.floor(remaining / 86400)
            local hours = math.floor((remaining % 86400) / 3600)
            local minutes = math.floor((remaining % 3600) / 60)
            local seconds = math.floor(remaining % 60)
            remainingText = string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
        end

        return { valid = true, status = "valid", expiresAt = expiresAt, remainingText = remainingText }
    end

    return { valid = false, status = "invalid", expiresAt = nil, remainingText = result.error or result.message or "Key: Invalid" }
end

function Library:create_ui()
    local old_hyperion = PlayerGui and PlayerGui:FindFirstChild('hyperion')

    if old_hyperion then
        Debris:AddItem(old_hyperion, 0)
    end

    local hyperion = Instance.new('ScreenGui')
    hyperion.ResetOnSpawn = false
    hyperion.Name = 'hyperion'
    hyperion.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    hyperion.Parent = PlayerGui and PlayerGui or nil
    if not PlayerGui then
        hyperion.Parent = workspace
    end

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05000000074505806
    Container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self._container = Container

    local ContainerGradient = Instance.new('UIGradient')
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 15, 15)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 3, 3))
    }
    ContainerGradient.Rotation = 45
    ContainerGradient.Parent = Container

    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = hyperion

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(120, 40, 40)
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 680, 0, 460)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container

    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026097271591424942, 0, 0.1111111119389534, 0)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(15, 3, 3)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    self._tabs = Tabs

    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs

    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(200, 200, 200)
    ClientName.TextTransparency = 0.20000000298023224
    ClientName.Text = 'Hyperion'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 45, 0, 18)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.07, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 16
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler

    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 8, 8)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 45, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 8, 8))
    }
    UIGradient.Parent = ClientName

    task.spawn(function()
        local cycleRed = Color3.fromRGB(255, 45, 45)
        local cycleWhite = Color3.fromRGB(245, 245, 245)
        local cycleBlack = Color3.fromRGB(12, 12, 12)

        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, cycleRed),
            ColorSequenceKeypoint.new(0.333, cycleRed),
            ColorSequenceKeypoint.new(0.333, cycleWhite),
            ColorSequenceKeypoint.new(0.666, cycleWhite),
            ColorSequenceKeypoint.new(0.666, cycleBlack),
            ColorSequenceKeypoint.new(1, cycleBlack)
        }

        while task.wait() do
            if not ClientName or not ClientName.Parent then break end
            local width = math.max(ClientName.AbsoluteSize.X, 45)
            local shift = (os.clock() * 60) % width
            UIGradient.Offset = Vector2.new(shift, 0)
        end
    end)

    local function RunJunkieKeyValidation()
        local key = nil
        local keyPath = "SakuraUI/Hyperionkey.txt"
        if type(isfile) == "function" and isfile(keyPath) then
            local ok, raw = pcall(readfile, keyPath)
            if ok and type(raw) == "string" then
                key = raw:match("^%s*(.-)%s*$")
            end
        end

        if not key then
            return { valid = false, status = "none", expiresAt = nil, remainingText = "Key: None" }
        end

        if type(Junkie) ~= "table" or type(Junkie.check_key) ~= "function" then
            return { valid = false, status = "none", expiresAt = nil, remainingText = "Key: None" }
        end

        local ok, result = pcall(function()
            return Junkie.check_key(key)
        end)

        if not ok or type(result) ~= "table" then
            return { valid = false, status = "invalid", expiresAt = nil, remainingText = "Key: Invalid" }
        end

        if result.valid == true then
            getgenv().SCRIPT_KEY = key

            local expiresAt = result.expiresAt or getgenv().JD_EXPIRES_AT
            local remainingText = "Lifetime"

            if expiresAt and tonumber(expiresAt) then
                local remaining = math.max(0, tonumber(expiresAt) - os.time())
                local days = math.floor(remaining / 86400)
                local hours = math.floor((remaining % 86400) / 3600)
                local minutes = math.floor((remaining % 3600) / 60)
                local seconds = math.floor(remaining % 60)
                remainingText = string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
            end

            return { valid = true, status = "valid", expiresAt = expiresAt, remainingText = remainingText }
        end

        return { valid = false, status = "invalid", expiresAt = nil, remainingText = result.error or result.message or "Key: Invalid" }
    end

    local TopDivider = Instance.new('Frame')
    TopDivider.Name = 'TopDivider'
    TopDivider.Size = UDim2.new(0.85, 0, 0, 1)
    TopDivider.Position = UDim2.new(0.5, 0, 0, 36)
    TopDivider.AnchorPoint = Vector2.new(0.5, 0)
    TopDivider.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    TopDivider.BorderSizePixel = 0
    TopDivider.Parent = Handler

    local TopDividerGradient = Instance.new('UIGradient')
    TopDividerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    TopDividerGradient.Parent = TopDivider

    local SideDivider = Instance.new('Frame')
    SideDivider.Name = 'SideDivider'
    SideDivider.Size = UDim2.new(0, 2, 0, 340)
    SideDivider.Position = UDim2.new(0.235, 0, 0.5, 0)
    SideDivider.AnchorPoint = Vector2.new(0.5, 0.5)
    SideDivider.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    SideDivider.BorderSizePixel = 0
    SideDivider.Parent = Handler

    local SideDividerCorner = Instance.new('UICorner')
    SideDividerCorner.CornerRadius = UDim.new(1, 0)
    SideDividerCorner.Parent = SideDivider

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    self._sections = Sections

    local Icon = Instance.new('ImageButton')
    Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://72109545964414'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.025, 0, 0.055, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 24, 0, 24)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.AutoButtonColor = false
    Icon.Parent = Handler

    local IconGradient = Instance.new('UIGradient')
    IconGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 45, 55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 80))
    }
    IconGradient.Parent = Icon

    Icon.Image = 'rbxassetid://72109545964414'

    Icon.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    self._ui = hyperion

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05000000074505806;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        hyperion.Enabled = not hyperion.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(680, 460)
            }):Play()
            ClientName.Size = UDim2.new(0, 45, 0, 18)
        else
            TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(150, 52)
            }):Play()
            ClientName.Size = UDim2.new(0, 80, 0, 18)
        end
    end


    function self:load()
        local content = {}

        for _, object in hyperion:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end

            table.insert(content, object)
        end

        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale

            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end

        TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(680, 460)
        }):Play()

        AcrylicBlur.new(self._container)
        self._ui_loaded = true

        local keyResult = self:RunJunkieKeyValidation()
        local username = Players.LocalPlayer.Name
        local statusText = "Unavailable"
        if keyResult then
            if keyResult.valid then
                statusText = keyResult.remainingText or "Valid"
            elseif keyResult.status == "invalid" then
                statusText = "Invalid"
            else
                statusText = keyResult.remainingText or "Unavailable"
            end
        end
        self:SetProfile(username, statusText)
    end

    function self:UIName(text)
        ClientName.Text = tostring(text or "")
    end

    function self:UIAccent(enabled, color)
        self._accent_color = color
    end

    function self:IconAsset(assetId)
        Icon.Image = tostring(assetId or "")
    end

    function self:CustomIcon(assetId)
        Icon.Image = tostring(assetId or "")
    end

    function self:IconAnimated(animated)
        _icon_animated = animated ~= false
    end

    function self:SetProfile(username, status)
        if not ProfileContainer then
            ProfileContainer = Instance.new('Frame')
            ProfileContainer.Name = 'ProfileContainer'
            ProfileContainer.Size = UDim2.new(0, 129, 0, 36)
            ProfileContainer.BackgroundTransparency = 1
            ProfileContainer.Position = UDim2.new(0, 0, 1, -38)
            ProfileContainer.Parent = Handler
            ProfileContainer.LayoutOrder = 9999

            local ProfileCorner = Instance.new('UICorner')
            ProfileCorner.CornerRadius = UDim.new(0, 6)
            ProfileCorner.Parent = ProfileContainer

            local ProfileIcon = Instance.new('ImageLabel')
            ProfileIcon.Name = 'ProfileIcon'
            ProfileIcon.Size = UDim2.new(0, 22, 0, 22)
            ProfileIcon.Position = UDim2.new(0, 8, 0, 2)
            ProfileIcon.BackgroundTransparency = 1
            ProfileIcon.Image = 'rbxassetid://16024557158'
            ProfileIcon.ScaleType = Enum.ScaleType.Fit
            task.spawn(function()
                local ok, avatarUrl = pcall(function()
                    return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and avatarUrl then
                    ProfileIcon.Image = avatarUrl
                end
            end)
            ProfileIcon.Parent = ProfileContainer

            local ProfileName = Instance.new('TextLabel')
            ProfileName.Name = 'ProfileName'
            ProfileName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ProfileName.TextColor3 = Color3.fromRGB(220, 150, 150)
            ProfileName.TextTransparency = 0.2
            ProfileName.Size = UDim2.new(0, 90, 0, 12)
            ProfileName.Position = UDim2.new(0, 34, 0, 2)
            ProfileName.BackgroundTransparency = 1
            ProfileName.TextXAlignment = Enum.TextXAlignment.Left
            ProfileName.TextSize = 11
            ProfileName.Parent = ProfileContainer

            local ProfileStatus = Instance.new('TextLabel')
            ProfileStatus.Name = 'ProfileStatus'
            ProfileStatus.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ProfileStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            ProfileStatus.TextTransparency = 0.2
            ProfileStatus.Size = UDim2.new(0, 90, 0, 12)
            ProfileStatus.Position = UDim2.new(0, 34, 0, 16)
            ProfileStatus.BackgroundTransparency = 1
            ProfileStatus.TextXAlignment = Enum.TextXAlignment.Left
            ProfileStatus.TextSize = 10
            ProfileStatus.Parent = ProfileContainer

            ProfileContainer.MouseEnter:Connect(function()
                TweenService:Create(ProfileContainer, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.85
                }):Play()
            end)

            ProfileContainer.MouseLeave:Connect(function()
                TweenService:Create(ProfileContainer, TweenInfo.new(0.2), {
                    BackgroundTransparency = 1
                }):Play()
            end)
        end

        if ProfileContainer then
            ProfileContainer.ProfileName.Text = tostring(username or "User")
            ProfileContainer.ProfileStatus.Text = tostring(status or "Unavailable")
        end
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = Color3.fromRGB(255, 150, 150)
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Color3.fromRGB(255, 150, 150)
                    }):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()

                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string, visible: boolean)
        if visible == nil then visible = true end
        local TabManager = {}

        local LayoutOrder = 0;

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        Tab.Parent = Tabs
        Tab.Visible = visible
        Tab.LayoutOrder = self._tab

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Tab

        local TabGradient = Instance.new('UIGradient')
        TabGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 5, 5))
        }
        TabGradient.Rotation = 90
        TabGradient.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextTransparency = 0.7
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab

        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(200, 60, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 20, 20))
        }
        UIGradient.Parent = TextLabel

        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab

        Tab.MouseEnter:Connect(function()
            if Tab.BackgroundTransparency ~= 0.5 then
                TweenService:Create(TextLabel, TweenInfo.new(0.3), {TextTransparency = 0.4}):Play()
                TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0.4}):Play()
            end
        end)

        Tab.MouseLeave:Connect(function()
            if Tab.BackgroundTransparency ~= 0.5 then
                TweenService:Create(TextLabel, TweenInfo.new(0.3), {TextTransparency = 0.7}):Play()
                TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0.8}):Play()
            end
        end)

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 374)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(15, 3, 3)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections

        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection

        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 374)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6290000081062317, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(15, 3, 3)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections

        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection

        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        TabManager._tab_button = Tab
        TabManager._left_section = LeftSection
        TabManager._right_section = RightSection

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:SetVisible(state: boolean)
            Tab.Visible = state
        end

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _locked = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(30, 8, 8)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = Module

            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(120, 40, 40)
            UIStroke.Transparency = 0.7
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module

            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module


local BellButton = Instance.new('ImageButton')
BellButton.AutoButtonColor = false
BellButton.Name = 'BellButton'
BellButton.Size = UDim2.new(0, 16, 0, 16)
BellButton.AnchorPoint = Vector2.new(1, 0)
BellButton.Position = UDim2.new(1, -6, 0, 6)
BellButton.BackgroundTransparency = 1
BellButton.Image = 'rbxassetid://10709775704'
BellButton.ImageColor3 = Color3.fromRGB(120, 120, 120)
BellButton.ImageTransparency = 0.4
BellButton.ZIndex = 10
BellButton.Parent = Header

    ModuleManager._locked = false
    ModuleManager._bell_enabled = false

local function updateBellVisual()
    local bellOn = _G.HyperionBellEnabled ~= false
    ModuleManager._bell_enabled = bellOn
    if bellOn then
        BellButton.ImageColor3 = Color3.fromRGB(255, 45, 45)
        BellButton.ImageTransparency = 0
    else
        BellButton.ImageColor3 = Color3.fromRGB(120, 120, 120)
        BellButton.ImageTransparency = 0.4
    end
end

local function setModuleInteractable(state: boolean)
    for _, desc in ipairs(Module:GetDescendants()) do
        if desc == BellButton then continue end

        if desc:IsA("TextButton") or desc:IsA("ImageButton") or desc:IsA("TextBox") then
            desc.Active = state
            desc.Selectable = state

            if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                desc.AutoButtonColor = state
            end

            if desc.Name == "Circle" or desc.Name == "Swatch" or desc.Name == "HueStrip" or desc.Name == "SvSquare" then
                desc.Active = state
            end
        end
    end
end

BellButton.MouseButton1Click:Connect(function()
    if Library._choosing_keybind then return end

    _G.HyperionBellEnabled = not _G.HyperionBellEnabled
    updateBellVisual()

    if _G.ShowNotification then
        _G.ShowNotification(_G.HyperionBellEnabled and "Notifications enabled" or "Notifications disabled", 1.5, { title = settings.title or "Bell", type = "info" })
    end
end)

BellButton.MouseEnter:Connect(function()
    local bellOn = _G.HyperionBellEnabled ~= false
    TweenService:Create(BellButton, TweenInfo.new(0.15), {
        ImageColor3 = bellOn and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(160, 160, 160),
        ImageTransparency = bellOn and 0 or 0.2
    }):Play()
end)

BellButton.MouseLeave:Connect(function()
    updateBellVisual()
end)

updateBellVisual()

            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Icon.Parent = Header

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(220, 150, 150)
            ModuleName.TextTransparency = 0.20000000298023224
            if not settings.rich then
                ModuleName.Text = settings.title or "Skibidi"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or settings.title or "Module"
            end;
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.Parent = Header

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(180, 150, 150)
            Description.TextTransparency = 0.699999988079071
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Description.Parent = Header

            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.699999988079071
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Parent = Header

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle

            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.20000000298023224
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Parent = Toggle

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle

            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.699999988079071
            Keybind.Position = UDim2.new(0.15000000596046448, 0, 0.7350000143051147, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
            Keybind.Parent = Header

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind

            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.Parent = Keybind

            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Divider.Parent = Header

            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Divider.Parent = Header

            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 0, 93)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            function ModuleManager:change_state(state: boolean)
                self._state = state

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)

                settings.callback(self._state)
            end

            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                if ModuleManager._locked then return end
                    if process then
                        return
                    end

                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end

                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty: boolean)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')

                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000

                    local font_size = TextService:GetTextBoundsAsync(font_params)

                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    TextLabel.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    TextLabel.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)

                Toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                Circle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                Circle.Position = UDim2.fromScale(0.53, 0.5)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                    return
                end

                Library._choosing_keybind = true

                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                if ModuleManager._locked then return end
                    if process then
                        return
                    end

                    if input == Enum.UserInputState or input == Enum.UserInputType then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)

                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)

                        TextLabel.Text = 'None'

                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end

                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil

                        Library._choosing_keybind = false

                        return
                    end

                    Connections['keybind_choose_start']:Disconnect()
                    Connections['keybind_choose_start'] = nil

                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Config:save(game.GameId, Library._config)

                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()

                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;

                local ParagraphManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += settings.customScale or 70

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)


                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30)
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule;

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph


                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(210, 210, 210)
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.Parent = Paragraph


                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)

                if not settings.rich then
                    Body.Text = settings.text or "Skibidi"
                else
                    Body.RichText = true
Body.Text = settings.richtext or "<font color='rgb(200,200,200)'>Hyperion</font> user"
                end

                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph


                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(60, 20, 20)
                    }):Play()
                end)

                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(30, 8, 8)
                    }):Play()
                end)

                return ParagraphManager
            end

            function ModuleManager:create_colorpicker(settings: any)
    LayoutOrderModule = LayoutOrderModule + 1

    local ColorpickerManager = {
        _color = settings.default or Color3.fromRGB(255, 0, 0),
        _h = 0, _s = 1, _v = 1
    }


    do
        local c = ColorpickerManager._color
        local h, s, v = Color3.toHSV(c)
        ColorpickerManager._h = h
        ColorpickerManager._s = s
        ColorpickerManager._v = v
    end


    if Library._config._flags[settings.flag] then
        local sv = Library._config._flags[settings.flag]
        if type(sv) == "table" and sv.R then
            local c = Color3.fromRGB(sv.R, sv.G, sv.B)
            ColorpickerManager._color = c
            local h, s, v = Color3.toHSV(c)
            ColorpickerManager._h = h
            ColorpickerManager._s = s
            ColorpickerManager._v = v
        end
    end

    if self._size == 0 then self._size = 11 end
    self._size += 32

    if ModuleManager._state then
        Module.Size = UDim2.fromOffset(241, 93 + self._size)
    end
    Options.Size = UDim2.fromOffset(241, self._size)


    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(0, 207, 0, 22)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = LayoutOrderModule
    Row.Parent = Options

    local Label = Instance.new("TextLabel")
    Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextTransparency = 0.2
    Label.Text = settings.title or "Color"
    Label.Size = UDim2.new(1, -30, 1, 0)
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextSize = 11
    Label.Parent = Row

    local Swatch = Instance.new("TextButton")
    Swatch.Size = UDim2.new(0, 22, 0, 22)
    Swatch.Position = UDim2.new(1, -22, 0, 0)
    Swatch.BackgroundColor3 = ColorpickerManager._color
    Swatch.BorderSizePixel = 0
    Swatch.Text = ""
    Swatch.AutoButtonColor = false
    Swatch.Parent = Row
    Instance.new("UICorner", Swatch).CornerRadius = UDim.new(0, 5)
    local SwatchStroke = Instance.new("UIStroke", Swatch)
    SwatchStroke.Color = Color3.fromRGB(120, 40, 40)
    SwatchStroke.Transparency = 0.5


    local POPUP_H = 180
    local popupOpen = false

    local Popup = Instance.new("Frame")
    Popup.Size = UDim2.new(0, 207, 0, 0)
    Popup.BackgroundColor3 = Color3.fromRGB(20, 8, 8)
    Popup.BorderSizePixel = 0
    Popup.ClipsDescendants = true
    Popup.LayoutOrder = LayoutOrderModule
    Popup.Parent = Options
    Instance.new("UICorner", Popup).CornerRadius = UDim.new(0, 7)
    local PopupStroke = Instance.new("UIStroke", Popup)
    PopupStroke.Color = Color3.fromRGB(120, 40, 40)
    PopupStroke.Transparency = 0.4


    local Inner = Instance.new("Frame")
    Inner.Size = UDim2.new(1, 0, 0, POPUP_H)
    Inner.BackgroundTransparency = 1
    Inner.Parent = Popup


    local SQ = 145
    local SvSquare = Instance.new("TextButton")
    SvSquare.Size = UDim2.new(0, SQ, 0, SQ)
    SvSquare.Position = UDim2.new(0, 8, 0, 10)
    SvSquare.BackgroundColor3 = Color3.fromHSV(ColorpickerManager._h, 1, 1)
    SvSquare.BorderSizePixel = 0
    SvSquare.Text = ""
    SvSquare.AutoButtonColor = false
    SvSquare.Parent = Inner
    Instance.new("UICorner", SvSquare).CornerRadius = UDim.new(0, 5)


    local WhiteGrad = Instance.new("Frame")
    WhiteGrad.Size = UDim2.new(1, 0, 1, 0)
    WhiteGrad.BackgroundTransparency = 0
    WhiteGrad.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WhiteGrad.BorderSizePixel = 0
    WhiteGrad.Parent = SvSquare
    Instance.new("UICorner", WhiteGrad).CornerRadius = UDim.new(0, 5)
    local WG = Instance.new("UIGradient", WhiteGrad)
    WG.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
    }
    WG.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    WG.Rotation = 0


    local BlackGrad = Instance.new("Frame")
    BlackGrad.Size = UDim2.new(1, 0, 1, 0)
    BlackGrad.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BlackGrad.BackgroundTransparency = 0
    BlackGrad.BorderSizePixel = 0
    BlackGrad.Parent = SvSquare
    Instance.new("UICorner", BlackGrad).CornerRadius = UDim.new(0, 5)
    local BG = Instance.new("UIGradient", BlackGrad)
    BG.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
    }
    BG.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    }
    BG.Rotation = 90


    local Picker = Instance.new("Frame")
    Picker.Size = UDim2.new(0, 10, 0, 10)
    Picker.AnchorPoint = Vector2.new(0.5, 0.5)
    Picker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Picker.BorderSizePixel = 0
    Picker.ZIndex = 5
    Picker.Position = UDim2.new(
        ColorpickerManager._s,
        0,
        1 - ColorpickerManager._v,
        0
    )
    Picker.Parent = SvSquare
    Instance.new("UICorner", Picker).CornerRadius = UDim.new(1, 0)
    local PickerStroke = Instance.new("UIStroke", Picker)
    PickerStroke.Color = Color3.fromRGB(120, 40, 40)
    PickerStroke.Thickness = 1.5
    PickerStroke.Transparency = 0.3


    local HueStrip = Instance.new("TextButton")
    HueStrip.Size = UDim2.new(0, 14, 0, SQ)
    HueStrip.Position = UDim2.new(0, 8 + SQ + 6, 0, 10)
    HueStrip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueStrip.BorderSizePixel = 0
    HueStrip.Text = ""
    HueStrip.AutoButtonColor = false
    HueStrip.Parent = Inner
    Instance.new("UICorner", HueStrip).CornerRadius = UDim.new(0, 4)


    local HueGrad = Instance.new("UIGradient", HueStrip)
    HueGrad.Rotation = 90
    local hueKP = {}
    for i = 0, 6 do
        hueKP[i+1] = ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6, 1, 1))
    end
    HueGrad.Color = ColorSequence.new(hueKP)


    local HueCursor = Instance.new("Frame")
    HueCursor.Size = UDim2.new(1, 4, 0, 3)
    HueCursor.Position = UDim2.new(0, -2, ColorpickerManager._h, -1)
    HueCursor.AnchorPoint = Vector2.new(0, 0.5)
    HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    HueCursor.BorderSizePixel = 0
    HueCursor.ZIndex = 5
    HueCursor.Parent = HueStrip
    Instance.new("UICorner", HueCursor).CornerRadius = UDim.new(1, 0)
    local HueCursorStroke = Instance.new("UIStroke", HueCursor)
    HueCursorStroke.Color = Color3.fromRGB(120, 40, 40)
    HueCursorStroke.Thickness = 1
    HueCursorStroke.Transparency = 0.4


    local BottomRow = Instance.new("Frame")
    BottomRow.Size = UDim2.new(1, -16, 0, 22)
    BottomRow.Position = UDim2.new(0, 8, 0, 10 + SQ + 8)
    BottomRow.BackgroundTransparency = 1
    BottomRow.Parent = Inner

    local PreviewSwatch = Instance.new("Frame")
    PreviewSwatch.Size = UDim2.new(0, 22, 0, 22)
    PreviewSwatch.BackgroundColor3 = ColorpickerManager._color
    PreviewSwatch.BorderSizePixel = 0
    PreviewSwatch.Parent = BottomRow
    Instance.new("UICorner", PreviewSwatch).CornerRadius = UDim.new(0, 5)

    local HexLabel = Instance.new("TextLabel")
    HexLabel.Text = "#"
    HexLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    HexLabel.TextSize = 10
    HexLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    HexLabel.Size = UDim2.new(0, 12, 1, 0)
    HexLabel.Position = UDim2.new(0, 28, 0, 0)
    HexLabel.BackgroundTransparency = 1
    HexLabel.TextXAlignment = Enum.TextXAlignment.Center
    HexLabel.Parent = BottomRow

    local HexBox = Instance.new("TextBox")
    HexBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    HexBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    HexBox.PlaceholderText = "FF0000"
    HexBox.Text = ""
    HexBox.TextSize = 10
    HexBox.Size = UDim2.new(1, -46, 1, 0)
    HexBox.Position = UDim2.new(0, 42, 0, 0)
    HexBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    HexBox.BackgroundTransparency = 0.3
    HexBox.BorderSizePixel = 0
    HexBox.ClearTextOnFocus = false
    HexBox.Parent = BottomRow
    Instance.new("UICorner", HexBox).CornerRadius = UDim.new(0, 4)


    local function colorToHex(c)
        return string.format("%02X%02X%02X",
            math.round(c.R * 255),
            math.round(c.G * 255),
            math.round(c.B * 255))
    end

    local function hexToColor(hex)
        hex = hex:gsub("#","")
        if #hex ~= 6 then return nil end
        local r = tonumber(hex:sub(1,2), 16)
        local g = tonumber(hex:sub(3,4), 16)
        local b = tonumber(hex:sub(5,6), 16)
        if not (r and g and b) then return nil end
        return Color3.fromRGB(r, g, b)
    end

    local function applyColor(h, s, v, skipHex)
        ColorpickerManager._h = h
        ColorpickerManager._s = s
        ColorpickerManager._v = v
        local color = Color3.fromHSV(h, s, v)
        ColorpickerManager._color = color


        SvSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)


        Picker.Position = UDim2.new(math.clamp(s, 0, 1), 0, math.clamp(1 - v, 0, 1), 0)


        HueCursor.Position = UDim2.new(0, -2, math.clamp(h, 0, 0.9999), -1)


        Swatch.BackgroundColor3 = color
        PreviewSwatch.BackgroundColor3 = color


        if not skipHex then
            HexBox.Text = colorToHex(color)
        end


        Library._config._flags[settings.flag] = {
            R = math.round(color.R * 255),
            G = math.round(color.G * 255),
            B = math.round(color.B * 255)
        }
        Config:save(game.GameId, Library._config)
        if settings.callback then settings.callback(color) end
    end

    function ColorpickerManager:set_color(color)
        local h, s, v = Color3.toHSV(color)
        applyColor(h, s, v)
    end


    applyColor(ColorpickerManager._h, ColorpickerManager._s, ColorpickerManager._v)


    local svDragging = false

    local function updateSV()
        local rx = math.clamp((mouse.X - SvSquare.AbsolutePosition.X) / SvSquare.AbsoluteSize.X, 0, 1)
        local ry = math.clamp((mouse.Y - SvSquare.AbsolutePosition.Y) / SvSquare.AbsoluteSize.Y, 0, 1)
        applyColor(ColorpickerManager._h, rx, 1 - ry)
    end

    SvSquare.MouseButton1Down:Connect(function()
        if ModuleManager._locked then return end
        svDragging = true
        updateSV()
    end)

    Connections["sv_move_"..settings.flag] = UserInputService.InputChanged:Connect(function(inp)
        if svDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateSV()
        end
    end)

    Connections["sv_end_"..settings.flag] = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
        end
    end)


    local hueDragging = false

    local function updateHue()
        local ry = math.clamp((mouse.Y - HueStrip.AbsolutePosition.Y) / HueStrip.AbsoluteSize.Y, 0, 0.9999)
        applyColor(ry, ColorpickerManager._s, ColorpickerManager._v)
    end

    HueStrip.MouseButton1Down:Connect(function()
        if ModuleManager._locked then return end
        hueDragging = true
        updateHue()
    end)

    Connections["hue_move_"..settings.flag] = UserInputService.InputChanged:Connect(function(inp)
        if hueDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateHue()
        end
    end)

    Connections["hue_end_"..settings.flag] = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            hueDragging = false
        end
    end)


    HexBox.FocusLost:Connect(function()
        if ModuleManager._locked then
            HexBox.Text = colorToHex(ColorpickerManager._color)
            return
        end
        local color = hexToColor(HexBox.Text)
        if color then
            local h, s, v = Color3.toHSV(color)
            applyColor(h, s, v, true)
        else
            HexBox.Text = colorToHex(ColorpickerManager._color)
        end
    end)


    Swatch.MouseButton1Click:Connect(function()
        if ModuleManager._locked then return end
        popupOpen = not popupOpen

        if popupOpen then
            self._size += POPUP_H
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            TweenService:Create(Popup, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(207, POPUP_H)
            }):Play()
        else
            self._size -= POPUP_H
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            TweenService:Create(Popup, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(207, 0)
            }):Play()
        end
    end)

    return ColorpickerManager
end

            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                local TextManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += settings.customScale or 50

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)


                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                TextFrame.BackgroundTransparency = 0.1
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize)
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame


                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)

                if not settings.rich then
                    Body.Text = settings.text or "Skibidi"
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(200,200,200)'>ailon</font> user"
                end

                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame


                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(60, 20, 20)
                    }):Play()
                end)

                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(30, 8, 8)
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Skibidi"
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(200,200,200)'>ailon</font> user"
                    end
                end;

                return TextManager
            end
            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1

                local TextboxManager = {
                    _text = ""
                }

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 32

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)

                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 150, 150)
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.AnchorPoint = Vector2.new(0, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.BorderSizePixel = 0
                Label.Parent = Options
                Label.TextSize = 10;
                Label.LayoutOrder = LayoutOrderModule

                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Color3.fromRGB(255, 150, 150)
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox

                function TextboxManager:update_text(text: string)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._text)
                end

                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end

                Textbox.FocusLost:Connect(function()
                    if ModuleManager._locked then return end
                    TextboxManager:update_text(Textbox.Text)
                end)

                return TextboxManager
            end

            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }

                if self._size == 0 then
                    self._size = 11
                end
                self._size += 20

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                if SelectedLanguage == "th" then
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                else
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 11
                end
                TitleLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Skibidi"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Parent = Checkbox

                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 6)
                KeybindCorner.Parent = KeybindBox

                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                KeybindLabel.TextScaled = false
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[settings.flag]
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                    or "..."
                KeybindLabel.Parent = KeybindBox

                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
                Box.Parent = Checkbox

                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 6)
                BoxCorner.Parent = Box

                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Box

                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill

                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end

                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end

                Checkbox.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)

                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end

                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if ModuleManager._locked then return end
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end

                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            ModuleManager:scale_keybind(true)
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = "..."
                            if Connections[settings.flag .. "_keybind"] then
                                Connections[settings.flag .. "_keybind"]:Disconnect()
                                Connections[settings.flag .. "_keybind"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end

                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag .. "_keybind"] then
                            Connections[settings.flag .. "_keybind"]:Disconnect()
                            Connections[settings.flag .. "_keybind"] = nil
                        end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        Library._choosing_keybind = false

                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)

                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if ModuleManager._locked then return end
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                end)
                Connections[settings.flag .. "_keypress"] = keyPressConnection

                return CheckboxManager
            end

            function ModuleManager:create_divider(settings: any)

                LayoutOrderModule = LayoutOrderModule + 1;

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                local dividerHeight = 1
                local dividerWidth = 207


                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, dividerWidth, 0, 20)
                OuterFrame.BackgroundTransparency = 1
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.TextTransparency = 0
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 110, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextLabel.TextSize = 11
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;

                if not settings or settings and not settings.disableline then

                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2)


                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))
                    })
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    Gradient.Rotation = 0


                    local UICorner = Instance.new('UICorner')
                    UICorner.CornerRadius = UDim.new(0, 2)
                    UICorner.Parent = Divider

                end;

                return true;
            end

            function ModuleManager:create_slider(settings: any)

                LayoutOrderModule = LayoutOrderModule + 1

                local SliderManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 110, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider

                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.8999999761581421
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                Drag.Parent = Slider

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag

                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Drag

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill

                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 30))
                }
                UIGradient.Parent = Fill

                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                Circle.Parent = Fill

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.TextTransparency = 0.20000000298023224
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Value.TextSize = 10
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Value.Parent = Slider

                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0

                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)

                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)

                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = number_threshold

                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()

                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()

                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)

                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end

                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)

                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config);
                        end;
                    end)
                end

                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;

                Slider.MouseButton1Down:Connect(function()
                    if ModuleManager._locked then return end
                    if not ModuleManager._state then return end
                    SliderManager:input()
                end)

                function SliderManager:SetVisible(state: boolean)
                    Slider.Visible = state
                end

                return SliderManager
            end

            function ModuleManager:create_dual_slider(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local SliderManager = { _min = settings.minimum_value, _max = settings.maximum_value }
                if Library._config._flags[settings.flag] then
                    local saved = Library._config._flags[settings.flag]
                    if type(saved) == "table" and #saved >= 2 then
                        SliderManager._min = saved[1]
                        SliderManager._max = saved[2]
                    end
                end

                if self._size == 0 then self._size = 11 end
                self._size += 27
                if ModuleManager._state then Module.Size = UDim2.fromOffset(241, 93 + self._size) end
                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'DualSlider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 110, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.TextSize = 11
                TextLabel.Parent = Slider

                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.9
                Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Drag.Parent = Slider

                local Fill = Instance.new('Frame')
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 0, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.Parent = Drag

                local MinCircle = Instance.new('Frame')
                MinCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                MinCircle.Position = UDim2.new(0, 0, 0.5, 0)
                MinCircle.Size = UDim2.new(0, 6, 0, 6)
                MinCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                MinCircle.Parent = Drag
                Instance.new("UICorner", MinCircle).CornerRadius = UDim.new(1, 0)

                local MaxCircle = Instance.new('Frame')
                MaxCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                MaxCircle.Position = UDim2.new(1, 0, 0.5, 0)
                MaxCircle.Size = UDim2.new(0, 6, 0, 6)
                MaxCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                MaxCircle.Parent = Drag
                Instance.new("UICorner", MaxCircle).CornerRadius = UDim.new(1, 0)

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.Text = '0 - 100'
                Value.Size = UDim2.new(0, 80, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.TextSize = 10
                Value.Parent = Slider

                function SliderManager:update_visuals()
                    local range = settings.maximum_value - settings.minimum_value
                    local minP = (self._min - settings.minimum_value) / range
                    local maxP = (self._max - settings.minimum_value) / range

                    Fill.Position = UDim2.new(minP, 0, 0.5, 0)
                    Fill.Size = UDim2.new(maxP - minP, 0, 1, 0)
                    MinCircle.Position = UDim2.new(minP, 0, 0.5, 0)
                    MaxCircle.Position = UDim2.new(maxP, 0, 0.5, 0)

                    local minV = settings.round_number and math.floor(self._min) or math.floor(self._min * 10) / 10
                    local maxV = settings.round_number and math.floor(self._max) or math.floor(self._max * 10) / 10
                    Value.Text = string.format("%s - %s%s", tostring(minV), tostring(maxV), settings.suffix or "")

                    Library._config._flags[settings.flag] = {minV, maxV}
                    settings.callback({minV, maxV})
                end

                function SliderManager:input(isMin)
                    local connection
                    connection = mouse.Move:Connect(function()
                        local mouse_position = math.clamp((mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset, 0, 1)
                        local val = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                        if isMin then
                            self._min = math.clamp(val, settings.minimum_value, self._max)
                        else
                            self._max = math.clamp(val, self._min, settings.maximum_value)
                        end
                        self:update_visuals()




                        if settings.callback then
                            pcall(settings.callback, {self._min, self._max})
                        end
                    end)

                    Connections['dual_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                        connection:Disconnect()
                        Connections:disconnect('dual_input_'..settings.flag)
                        Config:save(game.GameId, Library._config)
                    end)
                end

                Slider.MouseButton1Down:Connect(function()
                if ModuleManager._locked then return end
                    local mouse_position = math.clamp((mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset, 0, 1)
                    local val = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position
                    local distMin = math.abs(val - SliderManager._min)
                    local distMax = math.abs(val - SliderManager._max)
                    SliderManager:input(distMin < distMax)
                end)

                if Library._config._flags[settings.flag] then
                    local saved = Library._config._flags[settings.flag]
                    if type(saved) == "table" then
                        SliderManager._min, SliderManager._max = (table.unpack or unpack)(saved)
                    else
                        SliderManager._min, SliderManager._max = settings.min_value, settings.max_value
                    end
                else
                    SliderManager._min, SliderManager._max = settings.min_value, settings.max_value
                end
                SliderManager:update_visuals()
                if settings.callback then
                    settings.callback({SliderManager._min, SliderManager._max})
                end

                function SliderManager:SetVisible(state: boolean)
                    Slider.Visible = state
                end

                return SliderManager
            end

            function ModuleManager:create_dropdown(settings: any)

                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1;
                end;

                local DropdownManager = {
                    _state = false,
                    _size = 0
                }

                if not settings.Order then
                    if self._size == 0 then
                        self._size = 11
                    end

                    self._size += 44
                end;

                if not settings.Order then
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 93 + self._size)
                    end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 39)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule;
                else
                    Dropdown.LayoutOrder = settings.OrderValue;
                end;

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {};
                end;

                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Dropdown

                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.8999999761581421
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
                Box.Parent = TextLabel

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 6)
                UICorner.Parent = Box

                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
                Header.Parent = Box

                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(255, 150, 150)
                CurrentOption.TextTransparency = 0.20000000298023224
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 10
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption

                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Arrow.Parent = Header

                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                Options.Active = false
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0)
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box

                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options

                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = Options

                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                function DropdownManager:update(option: string)

                    if settings.multi_dropdown then


                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;

                        local CurrentTargetValue = nil;

                        if #Library._config._flags[settings.flag] > 0 then

                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag]);

                        end;

                        local selected = {}

                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do

                                local trimmedValue = value:match("^%s*(.-)%s*$")


                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do

                                local trimmedValue = value:match("^%s*(.-)%s*$")


                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end;

                        local CurrentTextGet = convertStringToTable(CurrentOption.Text);

                        optionSkibidi = "nil";
                        if typeof(option) ~= 'string' then
                            optionSkibidi = option.Name;
                        else
                            optionSkibidi = option;
                        end;

                        local found = false
                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i);
                                break;
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}

                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text);

                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end;
                        end;

                        CurrentOption.Text = table.concat(selected, ", ");

                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text);
                    else

                        CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then

                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end


                    Config:save(game.GameId, Library._config)


                    settings.callback(option)
                end

                local CurrentDropSizeState = 0;

                function DropdownManager:unfold_settings()
                    self._state = not self._state

                    if self._state then
                        ModuleManager._multiplier += self._size

                        CurrentDropSizeState = self._size;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + self._size)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + self._size)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                    else
                        ModuleManager._multiplier -= self._size

                        CurrentDropSizeState = 0;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                    end
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3

                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = true
                        Option.TextTransparency = 0.6000000238418579
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options

                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {};
                            end;

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)

                        if index > settings.maximum_options then
                            continue
                        end

                        DropdownManager._size += 16
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                function DropdownManager:New(value)
                    Dropdown:Destroy(true);
                    value.OrderValue = Dropdown.LayoutOrder
                    ModuleManager._multiplier -= CurrentDropSizeState
                    return ModuleManager:create_dropdown(value)
                end;

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                else
                    DropdownManager:update(settings.options[1])
                end

                Dropdown.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            function ModuleManager:create_feature(settings)

                local checked = false;

                LayoutOrderModule = LayoutOrderModule + 1

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 20

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size);
                end

                Options.Size = UDim2.fromOffset(241, self._size);

                local FeatureContainer = Instance.new("Frame")
                FeatureContainer.Size = UDim2.new(0, 207, 0, 16)
                FeatureContainer.BackgroundTransparency = 1
                FeatureContainer.Parent = Options
                FeatureContainer.LayoutOrder = LayoutOrderModule

                local UIListLayout = Instance.new("UIListLayout")
                UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = FeatureContainer

                local FeatureButton = Instance.new("TextButton")
                FeatureButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                FeatureButton.TextSize = 11;
                FeatureButton.Size = UDim2.new(1, -35, 0, 16)
                FeatureButton.BackgroundColor3 = Color3.fromRGB(30, 8, 8)
                FeatureButton.TextColor3 = Color3.fromRGB(210, 150, 150)
                FeatureButton.Text = "    " .. settings.title or "    " .. "Feature"
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.Parent = FeatureContainer

                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 45, 0, 16)
                RightContainer.BackgroundTransparency = 1
                RightContainer.Parent = FeatureContainer

                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer

                local KeybindBox = Instance.new("TextLabel")
                KeybindBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                KeybindBox.Size = UDim2.new(0, 15, 0, 15)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.TextSize = 11
                KeybindBox.BackgroundTransparency = 1
                KeybindBox.LayoutOrder = 2;
                KeybindBox.Parent = RightContainer

                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.TextTransparency = 1
                KeybindButton.Parent = KeybindBox

                local CheckboxCorner = Instance.new("UICorner", KeybindBox)
                CheckboxCorner.CornerRadius = UDim.new(0, 3)

                local UIStroke = Instance.new("UIStroke", KeybindBox)
                UIStroke.Color = Color3.fromRGB(180, 50, 50)
                UIStroke.Thickness = 1
                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                if not Library._config._flags then
                    Library._config._flags = {}
                end

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {
                        checked = false,
                        BIND = settings.default or "Unknown"
                    }
                end

                checked = Library._config._flags[settings.flag].checked
                KeybindBox.Text = Library._config._flags[settings.flag].BIND

                if KeybindBox.Text == "Unknown" then
                    KeybindBox.Text = "...";
                end;

                local UseF_Var = nil;

                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 15, 0, 15)
                    Checkbox.BackgroundColor3 = checked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 20, 20)
                    Checkbox.Text = ""
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1;

                    local UIStroke = Instance.new("UIStroke", Checkbox)
                    UIStroke.Color = Color3.fromRGB(180, 50, 50)
                    UIStroke.Thickness = 1
                    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                    local CheckboxCorner = Instance.new("UICorner")
                    CheckboxCorner.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner.Parent = Checkbox

                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(30, 8, 8)
                        Library._config._flags[settings.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if settings.callback then
                            settings.callback(checked)
                        end
                    end

                    UseF_Var = toggleState

                    Checkbox.MouseButton1Click:Connect(toggleState)

                else

                    UseF_Var = function()
                        settings.button_callback();
                    end;

                end;

                KeybindButton.MouseButton1Click:Connect(function()
                    KeybindBox.Text = "..."
                    local inputConnection
                    inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode.Name
                            Library._config._flags[settings.flag].BIND = newKey
                            if newKey ~= "Unknown" then
                                KeybindBox.Text = newKey;
                            end;
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            Library._config._flags[settings.flag].BIND = "Unknown"
                            KeybindBox.Text = "..."
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        end
                    end)
                    Connections["keybind_input_" .. settings.flag] = inputConnection
                end)

                local keyPressConnection
                keyPressConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[settings.flag].BIND then
                            UseF_Var();
                        end
                    end
                end)
                Connections["keybind_press_" .. settings.flag] = keyPressConnection

                FeatureButton.MouseButton1Click:Connect(function()
                    if settings.button_callback then
                        settings.button_callback()
                    end
                end)

                if not settings.disablecheck then
                    settings.callback(checked);
                end;

                return FeatureButton
            end

            function ModuleManager:create_button(settings)
                settings = settings or {}
                return self:create_feature({
                    title = settings.title or settings.text or "Button",
                    flag = settings.flag or ("btn_"..tostring(settings.title or math.random(1000000))),
                    disablecheck = true,
                    button_callback = function()
                        if settings.callback then pcall(settings.callback) end
                    end,
                    callback = function() end
                })
            end

            function ModuleManager:create_keybind(settings)
                settings = settings or {}
                return self:create_feature({
                    title = settings.title or "Keybind",
                    flag = settings.flag or ("key_"..tostring(settings.title or math.random(1000000))),
                    disablecheck = true,
                    default = settings.default or "Unknown",
                    callback = function()
                        if settings.callback then pcall(settings.callback) end
                    end
                })
            end

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        if input.KeyCode ~= Enum.KeyCode.Insert then
            return
        end

        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    return self
end

getgenv().AilonLibrary = Library
return Library
