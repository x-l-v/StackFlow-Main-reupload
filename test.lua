pcall(function() if task and task.synchronize then task.synchronize() end end)

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

local UIName = "Frostware"
local ConfigFolder = UIName
local AccentToggle = false
local AccentColor = Color3.fromRGB(255, 120, 180)
local DefaultAccentColor = Color3.fromRGB(220, 35, 50)
local UIAccentColor = AccentToggle and AccentColor or DefaultAccentColor
local IconAsset = "rbxassetid://74080484918102"
local IconAnimated = true
local IconSpriteWidth = 60
local IconSpriteHeight = 40
local IconSpriteRows = 2
local IconSpriteColumns = 3
local IconSpriteFrames = 5
local IconSpriteFPS = 10
local DefaultBackgroundMedia = nil

tablein = tablein or table.insert

local SelectedLanguage = GG.SelectedLanguage or "en"

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
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Debris = cloneref(game:GetService('Debris'))

local Theme = {
    Font = 'rbxasset://fonts/families/GothamSSm.json',
    FontBold = 'rbxasset://fonts/families/GothamSSm.json',
    FontSemiBold = 'rbxasset://fonts/families/GothamSSm.json',
    FontMono = 'rbxasset://fonts/families/Montserrat.json',

    Background = Color3.fromRGB(8, 8, 10),
    Sidebar = Color3.fromRGB(10, 10, 13),
    Panel = Color3.fromRGB(16, 17, 22),
    PanelHover = Color3.fromRGB(22, 18, 22),
    Border = Color3.fromRGB(42, 42, 48),

    TextPrimary = Color3.fromRGB(225, 226, 232),
    TextSecondary = Color3.fromRGB(145, 146, 156),
    TextDisabled = Color3.fromRGB(95, 96, 104),

    Accent = Color3.fromRGB(220, 35, 50),
    AccentBright = Color3.fromRGB(255, 55, 70),
    AccentDark = Color3.fromRGB(95, 10, 18),

    ToggleOff = Color3.fromRGB(55, 55, 62),
    ToggleOn = Color3.fromRGB(220, 35, 50),

    CornerRadius = 8,
    SmallCornerRadius = 6,
    PanelCornerRadius = 8,
    ThinBorder = 1,

    Padding = 11,
    SmallPadding = 5,
    ItemHeight = 38,
    ModuleHeight = 93,
}

local function UpdateThemeAccent()
    Theme.Accent = UIAccentColor
    Theme.AccentBright = UIAccentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
    Theme.ToggleOn = UIAccentColor
end

local mouse = Players.LocalPlayer:GetMouse()
local old_Frostware = PlayerGui:FindFirstChild(UIName)

if old_Frostware then
    Debris:AddItem(old_Frostware, 0)
end

if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
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
}, { __mode = "k" })

local Config = setmetatable({
    _save_queue = {},
    _save_connection = nil,

    save = function(self: any, file_name: any, config: any)
        if type(writefile) ~= "function" then
            return
        end
        self._save_queue[file_name] = config
        if not self._save_connection then
            self._save_connection = task.delay(0.5, function()
                self._save_connection = nil
                for name, cfg in self._save_queue do
                    local success_save, result = pcall(function()
                        local flags = HttpService:JSONEncode(cfg)
                        writefile(ConfigFolder..'/'..name..'.json', flags)
                    end)
                    if not success_save then
                        warn('failed to save config', result)
                    end
                end
                table.clear(self._save_queue)
            end)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if type(isfile) ~= "function" or type(readfile) ~= "function" then
                self:save(file_name, config)
                return
            end
            if not isfile(ConfigFolder..'/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = readfile(ConfigFolder..'/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success_load then
            warn('failed to load config', result)
        end
        if type(result) ~= "table" then
            result = { _flags = {}, _keybinds = {}, _library = {} }
        end
        if type(result._flags) ~= "table" then
            result._flags = {}
        end
        if type(result._keybinds) ~= "table" then
            result._keybinds = {}
        end
        if type(result._library) ~= "table" then
            result._library = {}
        end
        return result
    end
}, { __mode = "k" })

-- JNKIE ENTITLEMENT INTEGRATION
local Entitlement = {
    valid = false,
    lifetime = false,
    expiresAt = nil,
    status = "No key",
    _revalidationInterval = 300,
    _lastValidation = 0,
    _connections = {},
    _userStatus = nil
}

local function ReadHyperionKey()
    local keyPath = "SakuraUI/Hyperionkey.txt"
    if type(isfile) ~= "function" or not isfile(keyPath) then
        return nil
    end
    local success, raw = pcall(readfile, keyPath)
    if not success or not raw then
        return nil
    end
    local trimmed = tostring(raw):match("^%s*(.-)%s*$")
    if trimmed == "" then
        return nil
    end
    return trimmed
end

local function FormatEntitlementTime(expiresAt)
    if not expiresAt then
        return "Expired"
    end
    local now = os.time()
    local remaining = expiresAt - now
    if remaining <= 0 then
        return "Expired"
    end

    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = math.floor(remaining % 60)

    local parts = {}
    if days > 0 then
        table.insert(parts, days .. "d")
    end
    if hours > 0 or days > 0 then
        table.insert(parts, hours .. "h")
    end
    if minutes > 0 or hours > 0 or days > 0 then
        table.insert(parts, minutes .. "m")
    end
    if seconds > 0 or (#parts == 0) then
        table.insert(parts, seconds .. "s")
    end

    return table.concat(parts, " ")
end

local function ValidateKeyWithJnkie(key)
    if not key then
        return { valid = false, status = "No key" }
    end

    local requestFunction = request or syn and syn.request or http_request
    local httpSuccess, httpResult = false, nil

    if type(requestFunction) == "function" then
        local ok, response = pcall(requestFunction, {
            Url = "https://api.jnkie.com/v1/validate",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({ key = key })
        })
        if ok and type(response) == "table" then
            httpSuccess = true
            httpResult = response
        end
    end

    if not httpSuccess then
        local ok, data = pcall(function()
            return game:HttpPost("https://api.jnkie.com/v1/validate", HttpService:JSONEncode({ key = key }), Enum.HttpContentType.ApplicationJson)
        end)
        if ok and data then
            httpSuccess = true
            httpResult = { Body = data }
        end
    end

    if not httpSuccess then
        return { valid = false, status = "Unavailable" }
    end

    local body = httpResult.Body or httpResult.body or ""
    if body == "" then
        return { valid = false, status = "Unavailable" }
    end

    local decoded = nil
    local decodeOk, decodeResult = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if decodeOk and type(decodeResult) == "table" then
        decoded = decodeResult
    else
        return { valid = false, status = "Unavailable" }
    end

    if decoded.valid == true then
        if decoded.lifetime == true then
            return {
                valid = true,
                lifetime = true,
                expiresAt = nil,
                status = "Lifetime"
            }
        elseif decoded.expiresAt then
            local exp = tonumber(decoded.expiresAt)
            if exp and exp > os.time() then
                return {
                    valid = true,
                    lifetime = false,
                    expiresAt = exp,
                    status = FormatEntitlementTime(exp)
                }
            else
                return { valid = false, status = "Expired" }
            end
        else
            return {
                valid = true,
                lifetime = true,
                expiresAt = nil,
                status = "Lifetime"
            }
        end
    else
        return { valid = false, status = "Invalid" }
    end
end

local function ApplyEntitlementState(result)
    Entitlement.valid = result.valid
    Entitlement.lifetime = result.lifetime
    Entitlement.expiresAt = result.expiresAt
    Entitlement.status = result.status
    Entitlement._lastValidation = os.time()
end

local function UpdateUserStatusUI()
    local target = Entitlement._userStatus
    if not target then
        return
    end

    target.Text = Entitlement.status
    if Entitlement.valid then
        target.TextColor3 = Theme.Accent
        target.TextTransparency = 0
    elseif Entitlement.status == "No key" or Entitlement.status == "Checking..." then
        target.TextColor3 = Theme.TextSecondary
        target.TextTransparency = 0.3
    else
        target.TextColor3 = Color3.fromRGB(255, 70, 70)
        target.TextTransparency = 0
    end
end

local function StartEntitlementCountdown()
    if Entitlement._countdownConnection then
        Entitlement._countdownConnection:Disconnect()
        Entitlement._countdownConnection = nil
    end

    Entitlement._countdownConnection = task.spawn(function()
        while Library._ui and Library._ui.Parent do
            task.wait(1)
            if not Library._ui or not Library._ui.Parent then break end

            if Entitlement.valid and not Entitlement.lifetime and Entitlement.expiresAt then
                local remaining = Entitlement.expiresAt - os.time()
                if remaining <= 0 then
                    ApplyEntitlementState({ valid = false, status = "Expired" })
                    UpdateUserStatusUI()
                    task.delay(2, function()
                        PerformValidation()
                    end)
                else
                    Entitlement.status = FormatEntitlementTime(Entitlement.expiresAt)
                    UpdateUserStatusUI()
                end
            end
        end
    end)
end

local function StartPeriodicRevalidation()
    if Entitlement._revalidationConnection then
        Entitlement._revalidationConnection:Disconnect()
        Entitlement._revalidationConnection = nil
    end

    Entitlement._revalidationConnection = task.spawn(function()
        while Library._ui and Library._ui.Parent do
            task.wait(Entitlement._revalidationInterval)
            if not Library._ui or not Library._ui.Parent then break end
            PerformValidation()
        end
    end)
end

local function PerformValidation()
    Entitlement.status = "Checking..."
    UpdateUserStatusUI()

    local key = ReadHyperionKey()
    local result = ValidateKeyWithJnkie(key)
    ApplyEntitlementState(result)
    UpdateUserStatusUI()

    if Entitlement.valid and not Entitlement.lifetime then
        StartEntitlementCountdown()
    end
end
local Library = {
    _config = Config:load(game.GameId),
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

local function ResolveMethodValue(first, second)
    if first == Library then
        return second
    end
    return first
end

local function ResolveAssetId(asset)
    if typeof(asset) == "number" then
        return "rbxassetid://" .. tostring(asset)
    end
    if typeof(asset) == "string" and asset ~= "" then
        if tonumber(asset) then
            return "rbxassetid://" .. asset
        end
        return asset
    end
    return nil
end

local function Clamp01(value)
    value = tonumber(value)
    if not value then
        return nil
    end
    return math.clamp(value, 0, 1)
end

local function UpdateUIAccentColor()
    UIAccentColor = AccentToggle and AccentColor or DefaultAccentColor
    UpdateThemeAccent()
    return UIAccentColor
end

local function DeserializeColor(value)
    if typeof(value) == "Color3" then
        return value
    end
    if typeof(value) ~= "table" then
        return nil
    end
    local r = tonumber(value.R) or tonumber(value.r) or tonumber(value[1])
    local g = tonumber(value.G) or tonumber(value.g) or tonumber(value[2])
    local b = tonumber(value.B) or tonumber(value.b) or tonumber(value[3])
    if not r or not g or not b then
        return nil
    end
    if r > 1 or g > 1 or b > 1 then
        return Color3.fromRGB(
            math.clamp(math.floor(r + 0.5), 0, 255),
            math.clamp(math.floor(g + 0.5), 0, 255),
            math.clamp(math.floor(b + 0.5), 0, 255)
        )
    end
    return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
end

local function PersistAccentConfig()
    if type(Library._config) == "table" and type(Library._config._library) == "table" then
        Library._config._library.uiColor = {R = AccentColor.R, G = AccentColor.G, B = AccentColor.B}
        Library._config._library.uiColorEnabled = AccentToggle
        Config:save(game.GameId, Library._config)
    end
end

local savedColor = DeserializeColor(Library._config and Library._config._library and Library._config._library.uiColor)
if savedColor then
    AccentColor = savedColor
    AccentToggle = Library._config._library.uiColorEnabled == true
    UpdateUIAccentColor()
end

function Library.UIName(first, second)
    local name = ResolveMethodValue(first, second)
    if typeof(name) == "string" and name ~= "" then
        UIName = name
        ConfigFolder = name
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end
        Library._config = Config:load(game.GameId)
    end
    return UIName
end

function Library.AccentToggle(first, second)
    AccentToggle = ResolveMethodValue(first, second) == true
    UpdateUIAccentColor()
    PersistAccentConfig()
    return UIAccentColor
end

function Library.AccentColor(first, second)
    local color = ResolveMethodValue(first, second)
    if typeof(color) == "Color3" then
        AccentColor = color
    end
    UpdateUIAccentColor()
    PersistAccentConfig()
    return UIAccentColor
end

function Library.UIAccent(first, second, third)
    local enabled = first
    local color = second
    if first == Library then
        enabled = second
        color = third
    end
    AccentToggle = enabled == true
    if typeof(color) == "Color3" then
        AccentColor = color
    end
    UpdateUIAccentColor()
    PersistAccentConfig()
    return UIAccentColor
end

function Library.IconAsset(first, second)
    local asset = ResolveAssetId(ResolveMethodValue(first, second))
    if typeof(asset) == "string" and asset ~= "" then
        IconAsset = asset
        IconAnimated = false
    end
    return IconAsset
end

Library.CustomIcon = Library.IconAsset

function Library.IconAnimated(first, second)
    IconAnimated = ResolveMethodValue(first, second) == true
    return IconAnimated
end

function Library.IconSprite(first, second, third, fourth, fifth, sixth, seventh, eighth)
    local asset = first
    local width = second
    local height = third
    local rows = fourth
    local columns = fifth
    local frames = sixth
    local fps = seventh
    if first == Library then
        asset = second
        width = third
        height = fourth
        rows = fifth
        columns = sixth
        frames = seventh
        fps = eighth
    end
    asset = ResolveAssetId(asset)
    if typeof(asset) == "string" and asset ~= "" then
        IconAsset = asset
    end
    IconSpriteWidth = tonumber(width) or IconSpriteWidth
    IconSpriteHeight = tonumber(height) or IconSpriteHeight
    IconSpriteRows = tonumber(rows) or IconSpriteRows
    IconSpriteColumns = tonumber(columns) or IconSpriteColumns
    IconSpriteFrames = tonumber(frames) or IconSpriteFrames
    IconSpriteFPS = tonumber(fps) or IconSpriteFPS
    IconAnimated = true
    return IconAsset
end

function Library.BackgroundMedia(first, second)
    DefaultBackgroundMedia = ResolveMethodValue(first, second)
    return DefaultBackgroundMedia
end

-- ANIMATION UTILITIES
local function TweenGUISafe(obj, info, props)
    if not TweenService or not obj then
        return nil
    end
    local ok, tween = pcall(TweenService.Create, TweenService, obj, info, props)
    if ok and tween then
        tween:Play()
        return tween
    end
    return nil
end

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        if k == "Parent" then continue end
        pcall(function() instance[k] = v end)
    end
    local parent = properties.Parent
    if parent then
        pcall(function() instance.Parent = parent end)
    end
    return instance
end

local function ApplyCorner(object, radius)
    local corner = CreateInstance("UICorner", { CornerRadius = UDim.new(0, radius) })
    corner.Parent = object
    return corner
end

local function ApplyStroke(object, color, thickness, transparency)
    local stroke = CreateInstance("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.3,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
    stroke.Parent = object
    return stroke
end

-- NOTIFICATION SYSTEM (preserved with visual updates)
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.Parent = PlayerGui:FindFirstChild("RobloxCoreGuis") or Instance.new("ScreenGui", PlayerGui)
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

local _NotificationContainerAlive = true

local NOTIFICATION_THEME = {
    success = Color3.fromRGB(60, 220, 120),
    error   = Color3.fromRGB(255, 70, 70),
    warning = Color3.fromRGB(255, 200, 70),
    info    = UIAccentColor
}

local NOTIFICATION_ICONS = {
    success = "rbxassetid://6035047391",
    error   = "rbxassetid://6035047393",
    warning = "rbxassetid://6035047396",
    info    = "rbxassetid://6035047390"
}

function Library.SendNotification(settings)
    if not _NotificationContainerAlive or not NotificationContainer then
        return
    end
    settings = type(settings) == "table" and settings or {}
    local moduleName = settings.title or settings.module or "Notification"
    local statusText = settings.text or settings.status or ""
    local nType = settings.type or "info"
    local accent = NOTIFICATION_THEME[nType] or UIAccentColor
    local iconAsset = settings.icon ~= false and (NOTIFICATION_ICONS[nType] or NOTIFICATION_ICONS.info) or nil
    local duration = math.clamp(tonumber(settings.duration) or 5, 1.5, 30)
    local showIcon = iconAsset ~= nil

    local Notification = CreateInstance("Frame", {
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = NotificationContainer,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    ApplyCorner(Notification, 8)

    local InnerFrame = CreateInstance("Frame", {
        Name = "InnerFrame",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Parent = Notification,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    ApplyCorner(InnerFrame, 8)
    ApplyStroke(InnerFrame, accent, 1, 0.4)

    local AccentBar = CreateInstance("Frame", {
        Name = "AccentBar",
        Size = UDim2.new(0, 3, 1, -12),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = InnerFrame
    })
    ApplyCorner(AccentBar, 2)

    if showIcon then
        local Icon = CreateInstance("ImageLabel", {
            Name = "Icon",
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            Image = iconAsset,
            ImageColor3 = accent,
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Fit,
            Parent = InnerFrame
        })
    end

    local textOffset = showIcon and 40 or 12
    local Title = CreateInstance("TextLabel", {
        Name = "Title",
        Text = tostring(moduleName),
        TextColor3 = Theme.TextPrimary,
        TextStrokeTransparency = 0.6,
        FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextSize = 13,
        Size = UDim2.new(1, -(textOffset + 8), 0, 20),
        Position = UDim2.fromOffset(textOffset, 10),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        Parent = InnerFrame
    })

    local Body = CreateInstance("TextLabel", {
        Name = "Body",
        Text = tostring(statusText),
        TextColor3 = Theme.TextSecondary,
        TextStrokeTransparency = 0.7,
        FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        TextSize = 10,
        Size = UDim2.new(1, -(textOffset + 8), 0, 18),
        Position = UDim2.fromOffset(textOffset, 30),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = InnerFrame
    })

    local ProgressBar = CreateInstance("Frame", {
        Name = "Bar",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Parent = InnerFrame
    })
    ApplyCorner(ProgressBar, 1)

    local removed = false
    local function RemoveNotification()
        if removed then return end
        removed = true
        local slideOut = TweenGUISafe(InnerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(-1.2, 0, 0, 0),
            BackgroundTransparency = 1
        })
        task.delay(0.32, function()
            if Notification and Notification.Parent then
                Notification:Destroy()
            end
        end)
    end

    InnerFrame.Position = UDim2.new(1.2, 0, 0, 0)
    TweenGUISafe(InnerFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.08
    })

    local progTween = TweenGUISafe(ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 3)
    })
    if progTween then
        progTween.Completed:Connect(RemoveNotification)
    else
        task.delay(duration, RemoveNotification)
    end
end

function Library:DestroyNotifications()
    if not _NotificationContainerAlive or not NotificationContainer then
        return
    end
    if NotificationContainer and NotificationContainer.Parent then
        NotificationContainer:Destroy()
    end
    _NotificationContainerAlive = false
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

function Library:removed(action)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag, flag_type)
    if type(Library._config) ~= "table" then
        Library._config = { _flags = {}, _keybinds = {}, _library = {} }
    end
    if type(Library._config._flags) ~= "table" then
        Library._config._flags = {}
    end
    if not Library._config._flags[flag] then
        return
    end
    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(__table, table_value)
    for index, value in __table do
        if value ~= table_value then
            continue
        end
        table.remove(__table, index)
    end
end

-- VISUAL LAYER: Window, Sidebar, Modules, Controls
function Library:create_ui()
    local old_Frostware = PlayerGui:FindFirstChild(UIName)
    if old_Frostware then
        Debris:AddItem(old_Frostware, 0)
    end

    local Frostware = CreateInstance("ScreenGui", {
        ResetOnSpawn = false,
        Name = UIName,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui
    })

    local Container = CreateInstance("Frame", {
        Name = "Container",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        Active = true,
        Parent = Frostware,
        ClipsDescendants = true
    })
    ApplyCorner(Container, 8)
    ApplyStroke(Container, Theme.Border, 1, 0.3)

    local UIContent = CreateInstance("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 138, 0, 0),
        Size = UDim2.new(1, -138, 1, 0),
        Parent = Container
    })

    -- Sidebar
    local SideBar = CreateInstance("Frame", {
        Name = "SideBar",
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 138, 1, 0),
        Parent = Container
    })

    -- Sidebar separator line
    local SidebarSeparator = CreateInstance("Frame", {
        Name = "SidebarSeparator",
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = SideBar
    })

    -- Tabs container
    local TabsFrame = CreateInstance("ScrollingFrame", {
        Name = "TabsFrame",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.9,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, -80),
        Parent = SideBar
    })

    local TabList = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabsFrame
    })

    local TabPadding = CreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = TabsFrame
    })

    -- User Section (fixed bottom)
    local UserSection = CreateInstance("Frame", {
        Name = "UserSection",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -72),
        Size = UDim2.new(1, 0, 0, 72),
        Parent = SideBar
    })

    local UserSeparator = CreateInstance("Frame", {
        Name = "UserSeparator",
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 0, 1),
        Parent = UserSection
    })

    local Avatar = CreateInstance("Frame", {
        Name = "Avatar",
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 10),
        Size = UDim2.new(0, 26, 0, 26),
        Parent = UserSection
    })
    ApplyCorner(Avatar, 6)
    ApplyStroke(Avatar, Theme.Accent, 1, 0.3)

    local Username = CreateInstance("TextLabel", {
        Name = "Username",
        Text = Players.LocalPlayer.Name,
        TextColor3 = Theme.TextPrimary,
        TextTransparency = 0.1,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextSize = 11,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 42, 0, 12),
        Size = UDim2.new(1, -50, 0, 14),
        Parent = UserSection
    })

    local UserStatus = CreateInstance("TextLabel", {
        Name = "UserStatus",
        Text = "Online",
        TextColor3 = Theme.TextSecondary,
        TextTransparency = 0.2,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        TextSize = 10,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 42, 0, 28),
        Size = UDim2.new(1, -50, 0, 12),
        Parent = UserSection
    })

    -- Jnkie Entitlement Integration
    Entitlement._userStatus = UserStatus
    PerformValidation()
    StartPeriodicRevalidation()

    -- Top Bar
    local TopBar = CreateInstance("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 48),
        Parent = UIContent
    })

    local PageTitle = CreateInstance("TextLabel", {
        Name = "PageTitle",
        Text = "Main",
        TextColor3 = Theme.TextPrimary,
        TextTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextSize = 13,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 14),
        Size = UDim2.new(0.5, -100, 0, 20),
        Parent = TopBar
    })

    local PageDescription = CreateInstance("TextLabel", {
        Name = "PageDescription",
        Text = "",
        TextColor3 = Theme.TextSecondary,
        TextTransparency = 0.3,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        TextSize = 10,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 16, 0, 32),
        Size = UDim2.new(0.5, -100, 0, 12),
        Parent = TopBar
    })

    -- Config Manager
    local ConfigButton = CreateInstance("TextButton", {
        Name = "ConfigButton",
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -48, 0, 12),
        Size = UDim2.new(0, 36, 0, 24),
        Parent = TopBar
    })
    ApplyCorner(ConfigButton, 6)
    ApplyStroke(ConfigButton, Theme.Border, 1, 0.3)

    local ConfigIcon = CreateInstance("ImageLabel", {
        Name = "ConfigIcon",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0.5, -7, 0.5, -7),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6026568198",
        ImageColor3 = Theme.TextSecondary,
        ImageTransparency = 0.2,
        ScaleType = Enum.ScaleType.Fit,
        Parent = ConfigButton
    })

    local ConfigOpen = false
    local ConfigMenu

    local function ToggleConfigMenu()
        ConfigOpen = not ConfigOpen
        if ConfigOpen then
            if not ConfigMenu then
                ConfigMenu = CreateInstance("Frame", {
                    Name = "ConfigMenu",
                    BackgroundColor3 = Theme.Panel,
                    BackgroundTransparency = 0.08,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -120, 0, 42),
                    Size = UDim2.new(0, 110, 0, 0),
                    Parent = TopBar,
                    Visible = true
                })
                ApplyCorner(ConfigMenu, 6)
                ApplyStroke(ConfigMenu, Theme.Border, 1, 0.3)

                local ConfigList = CreateInstance("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = ConfigMenu
                })
                local ConfigPad = CreateInstance("UIPadding", {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    Parent = ConfigMenu
                })

                local function ConfigItem(text, callback)
                    local Item = CreateInstance("TextButton", {
                        Text = text,
                        TextColor3 = Theme.TextPrimary,
                        TextTransparency = 0.2,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextSize = 10,
                        BackgroundColor3 = Theme.Panel,
                        BackgroundTransparency = 0.15,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 24),
                        Parent = ConfigMenu
                    })
                    ApplyCorner(Item, 4)
                    Item.MouseEnter:Connect(function()
                        TweenGUISafe(Item, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.05,
                            TextTransparency = 0
                        })
                    end)
                    Item.MouseLeave:Connect(function()
                        TweenGUISafe(Item, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.15,
                            TextTransparency = 0.2
                        })
                    end)
                    Item.MouseButton1Click:Connect(function()
                        callback()
                        ConfigOpen = false
                        if ConfigMenu then
                            TweenGUISafe(ConfigMenu, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                Size = UDim2.new(0, 110, 0, 0)
                            })
                            task.delay(0.2, function()
                                if ConfigMenu then ConfigMenu.Visible = false end
                            end)
                        end
                    end)
                    return Item
                end

                ConfigItem("Save Config", function()
                    if Library._config then
                        Config:save(game.GameId, Library._config)
                        Library:SendNotification({ title = "Config", text = "Configuration saved.", type = "success", duration = 2 })
                    end
                end)
                ConfigItem("Load Config", function()
                    if Library._config then
                        Library._config = Config:load(game.GameId)
                        Library:SendNotification({ title = "Config", text = "Configuration loaded.", type = "success", duration = 2 })
                    end
                end)
                ConfigItem("Reset Config", function()
                    Library._config = { _flags = {}, _keybinds = {}, _library = {} }
                    Config:save(game.GameId, Library._config)
                    Library:SendNotification({ title = "Config", text = "Configuration reset.", type = "warning", duration = 2 })
                end)

                ConfigMenu.Visible = false
                ConfigMenu.Size = UDim2.new(0, 110, 0, 0)
            else
                ConfigMenu.Visible = true
            end
            TweenGUISafe(ConfigMenu, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 110, 0, 80)
            })
        else
            if ConfigMenu then
                TweenGUISafe(ConfigMenu, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 110, 0, 0)
                })
                task.delay(0.2, function()
                    if ConfigMenu then ConfigMenu.Visible = false end
                end)
            end
        end
    end

    ConfigButton.MouseButton1Click:Connect(ToggleConfigMenu)

    -- Minimize button
    local Minimize = CreateInstance("TextButton", {
        Name = "Minimize",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(0, 20, 0, 20),
        Parent = TopBar
    })
    Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    -- Sections container
    local Sections = CreateInstance("Frame", {
        Name = "Sections",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 48),
        Size = UDim2.new(1, 0, 1, -48),
        Parent = UIContent
    })

    self._ui = Frostware
    self._background_media_holder = nil

    local function on_drag(input, process)
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

    local function update_drag(input)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(
            self._container_position.X.Scale,
            self._container_position.X.Offset + delta.X,
            self._container_position.Y.Scale,
            self._container_position.Y.Offset + delta.Y
        )
        TweenGUISafe(Container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = position
        })
    end

    local function drag(input, process)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a)
            end)
        end
    end

    function self:UIVisiblity()
        Frostware.Enabled = not Frostware.Enabled
    end

    function self:change_visiblity(state)
        if state then
            TweenGUISafe(Container, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(620, 400)
            })
        else
            TweenGUISafe(Container, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            })
        end
    end

    function self:load()
        self._ui_loaded = false
        self:get_device()
        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            local UIScale = Container:FindFirstChild("UIScale")
            if not UIScale then
                UIScale = CreateInstance("UIScale", { Scale = self._ui_scale, Parent = Container })
            else
                UIScale.Scale = self._ui_scale
            end
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                if UIScale then UIScale.Scale = self._ui_scale end
            end)
        end

        TweenGUISafe(Container, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(620, 400)
        })
        self._ui_loaded = true
    end

    function self:removed(action)
        self._ui.AncestryChanged:Once(action)
    end

    function self:update_tabs(tab)
        local tabButtons = {}
        for _, object in TabsFrame:GetChildren() do
            if object.Name == 'Tab' then
                table.insert(tabButtons, object)
            end
        end

        table.sort(tabButtons, function(a, b)
            return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
        end)

        for _, object in tabButtons do
            if object == tab then
                TweenGUISafe(object, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0
                })
                TweenGUISafe(object:FindFirstChild("TextLabel"), TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                    TextColor3 = Theme.TextPrimary
                })
                TweenGUISafe(object:FindFirstChild("Icon"), TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    ImageTransparency = 0,
                    ImageColor3 = Theme.Accent
                })
            else
                TweenGUISafe(object, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                })
                TweenGUISafe(object:FindFirstChild("TextLabel"), TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 0.4,
                    TextColor3 = Theme.TextSecondary
                })
                TweenGUISafe(object:FindFirstChild("Icon"), TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.4,
                    ImageColor3 = Theme.TextSecondary
                })
            end
        end
    end

    function self:update_sections(left_section, right_section)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
            else
                object.Visible = false
            end
        end
    end

    function self:create_tab(title, icon)
        icon = ResolveAssetId(icon)
        local TabManager = {}
        local LayoutOrder = 0

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 12
        font_params.Width = 10000
        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not TabsFrame:FindFirstChild('Tab')

        local Tab = CreateInstance("TextButton", {
            Name = "Tab",
            Text = "",
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Panel,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 122, 0, 36),
            Parent = TabsFrame
        })
        ApplyCorner(Tab, 6)
        Tab.LayoutOrder = self._tab

        local TabText = CreateInstance("TextLabel", {
            Name = "TextLabel",
            Text = title,
            TextColor3 = Theme.TextSecondary,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            TextSize = 12,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, font_size.X + 4, 0, 16),
            Position = UDim2.new(0, 32, 0.5, -8),
            Parent = Tab
        })

        local TabIcon = CreateInstance("ImageLabel", {
            Name = "Icon",
            Image = icon or "",
            ImageColor3 = Theme.TextSecondary,
            ImageTransparency = 0.4,
            ScaleType = Enum.ScaleType.Fit,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 10, 0.5, -7),
            Parent = Tab
        })

        Tab.MouseEnter:Connect(function()
            if Tab.BackgroundTransparency < 0.5 then return end
            TweenGUISafe(Tab, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.85
            })
            TweenGUISafe(Tab, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 2, 0, Tab.Position.Y.Offset)
            })
            TweenGUISafe(TabText, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0.2,
                TextColor3 = Theme.TextPrimary
            })
            TweenGUISafe(TabIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageTransparency = 0.2,
                ImageColor3 = Theme.AccentBright
            })
        end)

        Tab.MouseLeave:Connect(function()
            if Tab.BackgroundTransparency < 0.5 then return end
            TweenGUISafe(Tab, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            })
            TweenGUISafe(Tab, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, Tab.Position.Y.Offset)
            })
            TweenGUISafe(TabText, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0.4,
                TextColor3 = Theme.TextSecondary
            })
            TweenGUISafe(TabIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageTransparency = 0.4,
                ImageColor3 = Theme.TextSecondary
            })
        end)

        local LeftSection = CreateInstance("ScrollingFrame", {
            Name = "LeftSection",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.9,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(0, 218, 0, 316),
            Position = UDim2.new(0, 8, 0, 0),
            Parent = Sections
        })

        local LeftList = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = LeftSection
        })
        local LeftPad = CreateInstance("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 20),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = LeftSection
        })

        local RightSection = CreateInstance("ScrollingFrame", {
            Name = "RightSection",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.9,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(0, 218, 0, 316),
            Position = UDim2.new(0, 248, 0, 0),
            Parent = Sections
        })
        RightSection.Visible = false

        local RightList = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = RightSection
        })
        local RightPad = CreateInstance("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 20),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = RightSection
        })

        self._tab += 1
        Tab.LayoutOrder = self._tab

        local TabCount = 0
        for _, object in TabsFrame:GetChildren() do
            if object.Name == 'Tab' then
                TabCount += 1
            end
        end

        if first_tab then
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end

        Connections['tab_click_'..Tab.Name..'_'..Tab.LayoutOrder] = Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:moduleparagraph(settings)
            local LayoutOrderModule = 0
            local section = (settings.section == 'right') and RightSection or LeftSection

            local Module = CreateInstance("Frame", {
                Name = "ModuleParagraph",
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 218, 0, 70),
                Parent = section
            })
            ApplyCorner(Module, 8)
            ApplyStroke(Module, Theme.Border, 1, 0.3)

            local Header = CreateInstance("Frame", {
                Name = "Header",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 70),
                Parent = Module
            })

            local ModuleName = CreateInstance("TextLabel", {
                Name = "ModuleName",
                Text = settings.title or "Paragraph Title",
                TextColor3 = Theme.Accent,
                TextTransparency = 0.2,
                TextXAlignment = Enum.TextXAlignment.Left,
                FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 12,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -16, 0, 13),
                Position = UDim2.new(0, 8, 0, 8),
                Parent = Header
            })

            local Description = CreateInstance("TextLabel", {
                Name = "Description",
                Text = settings.description or "This is a description paragraph.",
                TextColor3 = Theme.TextSecondary,
                TextTransparency = 0.3,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextSize = 10,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -16, 0, 28),
                Position = UDim2.new(0, 8, 0, 26),
                Parent = Header
            })

            return {}
        end

        function TabManager:create_image(settings)
            local section = (settings.section == 'right') and RightSection or LeftSection
            local Module = CreateInstance("Frame", {
                Name = "ImageModule",
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 218, 0, 140),
                Parent = section
            })
            ApplyCorner(Module, 8)
            ApplyStroke(Module, Theme.Border, 1, 0.3)

            local Image = CreateInstance("ImageLabel", {
                Name = "GameImage",
                Image = settings.image or "rbxassetid://123456789",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 210, 0, 120),
                ScaleType = Enum.ScaleType.Fit,
                Parent = Module
            })
            ApplyCorner(Image, 6)
        end

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = {
                _state = false,
                _size = 0,
                _dropdownRegistry = {}
            }

            local section = (settings.section == 'right') and RightSection or LeftSection

            local Module = CreateInstance("Frame", {
                Name = "Module",
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 218, 0, 93),
                Parent = section
            })
            ApplyCorner(Module, 8)
            ApplyStroke(Module, Theme.Border, 1, 0.3)

            local Options = CreateInstance("Frame", {
                Name = "Options",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(0, 218, 0, 0),
                Parent = Module,
                ClipsDescendants = true
            })

            local OptionList = CreateInstance("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Options
            })
            local OptionPad = CreateInstance("UIPadding", {
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Options
            })

            local Header = CreateInstance("TextButton", {
                Name = "Header",
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 218, 0, 93),
                Parent = Module
            })

            local Icon = CreateInstance("ImageLabel", {
                Name = "Icon",
                Image = settings.icon or 'rbxassetid://79095934438045',
                ImageColor3 = Theme.Accent,
                ImageTransparency = 0.2,
                ScaleType = Enum.ScaleType.Fit,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 8, 0, 10),
                Parent = Header
            })

            local ModuleName = CreateInstance("TextLabel", {
                Name = "ModuleName",
                Text = settings.title or "Module",
                TextColor3 = Theme.Accent,
                TextTransparency = 0.2,
                TextXAlignment = Enum.TextXAlignment.Left,
                FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 12,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 170, 0, 13),
                Position = UDim2.new(0, 28, 0, 10),
                Parent = Header
            })

            local Description = CreateInstance("TextLabel", {
                Name = "Description",
                Text = settings.description or "",
                TextColor3 = Theme.TextSecondary,
                TextTransparency = 0,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextSize = 10,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 170, 0, 12),
                Position = UDim2.new(0, 28, 0, 26),
                Parent = Header
            })

            local Toggle = CreateInstance("Frame", {
                Name = "Toggle",
                BackgroundColor3 = Theme.ToggleOff,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 20, 0, 10),
                Position = UDim2.new(0, 198, 0, 10),
                Parent = Header
            })
            ApplyCorner(Toggle, 10)

            local Circle = CreateInstance("Frame", {
                Name = "Circle",
                BackgroundColor3 = Theme.ToggleOff,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(0, 2, 0.5, -4),
                Parent = Toggle
            })
            ApplyCorner(Circle, 10)

            local Keybind = CreateInstance("Frame", {
                Name = "Keybind",
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.15,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 33, 0, 15),
                Position = UDim2.new(0.15, 0, 0.735, 0),
                Parent = Header,
                Visible = _G.Mobile ~= true
            })
            ApplyCorner(Keybind, 4)

            local KeybindText = CreateInstance("TextLabel", {
                Name = "TextLabel",
                Text = "None",
                TextColor3 = Theme.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                FontFace = Font.new(Theme.FontMono, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                TextSize = 9,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = Keybind
            })

            local function ModuleHeaderHeight()
                local h = Header and Header.AbsoluteSize.Y
                if not h or h <= 0 then
                    h = Header and Header.Size.Y.Offset
                end
                if not h or h <= 0 then
                    h = 93
                end
                return h
            end

            function ModuleManager:_measure_content()
                local total = 0
                local padding = OptionList.Padding.Offset
                local children = {}
                for _, child in Options:GetChildren() do
                    if child:IsA("GuiObject") and child.Visible then
                        table.insert(children, child)
                    end
                end
                table.sort(children, function(a, b)
                    return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
                end)
                for i, child in ipairs(children) do
                    local h = child.AbsoluteSize.Y
                    if h <= 0 then
                        h = child.Size.Y.Offset
                    end
                    if h <= 0 then
                        h = 20
                    end
                    total = total + h
                    if i < #children then
                        total = total + padding
                    end
                end
                total = total + OptionPad.PaddingTop.Offset + OptionPad.PaddingBottom.Offset
                return math.max(total, 8)
            end

            function ModuleManager:refresh_size()
                if Options and Options.Parent then
                    local contentHeight = self:_measure_content()
                    self._size = math.max(contentHeight, 8)
                    if self._state then
                        Options.Size = UDim2.fromOffset(218, self._size)
                        Module.Size = UDim2.fromOffset(218, ModuleHeaderHeight() + self._size)
                    else
                        Options.Size = UDim2.fromOffset(218, 0)
                    end
                end
            end

            function ModuleManager:schedule_refresh()
                if self._refresh_scheduled then
                    return
                end
                self._refresh_scheduled = true
                task.spawn(function()
                    if RunService then
                        RunService.RenderStepped:Wait()
                    else
                        task.wait()
                    end
                    self._refresh_scheduled = false
                    if Options and Options.Parent then
                        self:refresh_size()
                    end
                end)
            end

            function ModuleManager:change_state(state)
                if self._changingState then
                    return
                end
                self._changingState = true
                self._state = state

                if self._state then
                    self:refresh_size()
                    TweenGUISafe(Module, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(218, ModuleHeaderHeight() + self._size)
                    })
                    TweenGUISafe(Options, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(218, self._size)
                    })
                    TweenGUISafe(Toggle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.ToggleOn
                    })
                    TweenGUISafe(Circle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.TextPrimary,
                        Position = UDim2.new(0.5, -4, 0.5, -4)
                    })
                    TweenGUISafe(Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        ImageTransparency = 0,
                        ImageColor3 = Theme.Accent
                    })
                else
                    TweenGUISafe(Module, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(218, ModuleHeaderHeight())
                    })
                    TweenGUISafe(Options, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(218, 0)
                    })
                    TweenGUISafe(Toggle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.ToggleOff
                    })
                    TweenGUISafe(Circle, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.ToggleOff,
                        Position = UDim2.new(0, 2, 0.5, -4)
                    })
                    TweenGUISafe(Icon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Theme.TextSecondary
                    })
                end

                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)

                local cb = settings.callback
                settings.callback = function() end
                pcall(function()
                    cb(self._state)
                end)
                settings.callback = cb

                self._changingState = false
            end

            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end
                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new(Theme.FontMono, Enum.FontWeight.Bold)
                    font_params.Size = 9
                    font_params.Width = 10000
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    KeybindText.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    KeybindText.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)
                Toggle.BackgroundColor3 = Theme.ToggleOn
                Circle.BackgroundColor3 = Theme.TextPrimary
                Circle.Position = UDim2.new(0.5, -4, 0.5, -4)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                KeybindText.Text = keybind_string
                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input)
                if Library._choosing_keybind then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                Library._choosing_keybind = true
                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if input == Enum.UserInputState or input == Enum.UserInputType then return end
                    if input.KeyCode == Enum.KeyCode.Unknown then return end
                    if input.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)
                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)
                        KeybindText.Text = 'None'
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
                    KeybindText.Text = keybind_string
                end)
            end)

            Connections[settings.flag..'_header_click'] = Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local ParagraphManager = {}

                local Paragraph = CreateInstance("Frame", {
                    Name = "Paragraph",
                    BackgroundColor3 = Theme.Panel,
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 30),
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })
                ApplyCorner(Paragraph, 4)

                local Title = CreateInstance("TextLabel", {
                    Name = "Title",
                    Text = settings.title or "Title",
                    TextColor3 = Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 11,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -10, 0, 20),
                    Position = UDim2.new(0, 5, 0, 5),
                    Parent = Paragraph
                })

                local Body = CreateInstance("TextLabel", {
                    Name = "Body",
                    Text = settings.text or settings.richtext or "Skibidi",
                    TextColor3 = Theme.TextSecondary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -10, 0, 20),
                    Position = UDim2.new(0, 5, 0, 30),
                    Parent = Paragraph
                })

                Paragraph.MouseEnter:Connect(function()
                    TweenGUISafe(Paragraph, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.PanelHover
                    })
                end)
                Paragraph.MouseLeave:Connect(function()
                    TweenGUISafe(Paragraph, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Panel
                    })
                end)

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return ParagraphManager
            end

            function ModuleManager:create_text(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local TextManager = {}

                local TextFrame = CreateInstance("Frame", {
                    Name = "Text",
                    BackgroundColor3 = Theme.Panel,
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, settings.CustomYSize or 30),
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })
                ApplyCorner(TextFrame, 4)

                local Body = CreateInstance("TextLabel", {
                    Name = "Body",
                    Text = settings.text or settings.richtext or "Skibidi",
                    TextColor3 = Theme.TextSecondary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -10, 1, 0),
                    Position = UDim2.new(0, 5, 0, 5),
                    Parent = TextFrame
                })

                TextFrame.MouseEnter:Connect(function()
                    TweenGUISafe(TextFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.PanelHover
                    })
                end)
                TextFrame.MouseLeave:Connect(function()
                    TweenGUISafe(TextFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Panel
                    })
                end)

                function TextManager:Set(new_settings)
                    Body.Text = new_settings.text or new_settings.richtext or "Skibidi"
                    ModuleManager:refresh_size()
                    ModuleManager:schedule_refresh()
                end

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return TextManager
            end

            function ModuleManager:create_textbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local TextboxManager = { _text = "" }

                local Label = CreateInstance("TextLabel", {
                    Name = "Label",
                    Text = settings.title or "Enter text",
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 13),
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })

                local Textbox = CreateInstance("TextBox", {
                    Name = "Textbox",
                    Text = Library._config._flags[settings.flag] or "",
                    PlaceholderText = settings.placeholder or "Enter text...",
                    TextColor3 = Theme.TextPrimary,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextSize = 10,
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.9,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 15),
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule,
                    ClearTextOnFocus = false
                })
                ApplyCorner(Textbox, 4)

                function TextboxManager:update_text(text)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._text)
                end

                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end

                Textbox.FocusLost:Connect(function()
                    TextboxManager:update_text(Textbox.Text)
                end)

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return TextboxManager
            end

            function ModuleManager:create_checkbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }

                local Checkbox = CreateInstance("TextButton", {
                    Name = "Checkbox",
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 15),
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })

                local TitleLabel = CreateInstance("TextLabel", {
                    Name = "TitleLabel",
                    Text = settings.title or "Skibidi",
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 11,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 124, 0, 13),
                    Position = UDim2.new(0, 0, 0.5, -6.5),
                    Parent = Checkbox
                })

                local KeybindBox = CreateInstance("Frame", {
                    Name = "KeybindBox",
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(20, 14),
                    Position = UDim2.new(1, -28, 0.5, -7),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = Checkbox,
                    Visible = _G.Mobile ~= true
                })
                ApplyCorner(KeybindBox, 4)

                local KeybindLabel = CreateInstance("TextLabel", {
                    Name = "KeybindLabel",
                    Text = Library._config._keybinds[settings.flag]
                        and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        or "...",
                    TextColor3 = Theme.TextPrimary,
                    FontFace = Font.new(Theme.FontMono, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 9,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    Parent = KeybindBox
                })

                local Box = CreateInstance("Frame", {
                    Name = "Box",
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.9,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 15, 0, 15),
                    Position = UDim2.new(1, -8, 0.5, -7.5),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Parent = Checkbox
                })
                ApplyCorner(Box, 3)

                local Fill = CreateInstance("Frame", {
                    Name = "Fill",
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.2,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 9, 0, 9),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Parent = Box
                })
                ApplyCorner(Fill, 2)

                function CheckboxManager:change_state(state)
                    if self._changingState then return end
                    self._changingState = true
                    self._state = state
                    if self._state then
                        TweenGUISafe(Box, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        })
                        TweenGUISafe(Fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        })
                    else
                        TweenGUISafe(Box, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        })
                        TweenGUISafe(Fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        })
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    local cb = settings.callback
                    settings.callback = function() end
                    pcall(function()
                        cb(self._state)
                    end)
                    settings.callback = cb
                    self._changingState = false
                end

                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end

                Connections[settings.flag..'_checkbox_click'] = Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)

                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = "..."
                            if Connections[settings.flag.."_keybind"] then
                                Connections[settings.flag.."_keybind"]:Disconnect()
                                Connections[settings.flag.."_keybind"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag.."_keybind"] then
                            Connections[settings.flag.."_keybind"]:Disconnect()
                            Connections[settings.flag.."_keybind"] = nil
                        end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        Library._choosing_keybind = false
                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)

                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                end)
                Connections[settings.flag.."_keypress"] = keyPressConnection

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return CheckboxManager
            end

            function ModuleManager:create_button(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local Button = CreateInstance("TextButton", {
                    Name = "Button",
                    Text = settings.title or "Button",
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 11,
                    AutoButtonColor = true,
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 20),
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })
                ApplyCorner(Button, 6)

                Button.MouseEnter:Connect(function()
                    TweenGUISafe(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.05
                    })
                end)
                Button.MouseLeave:Connect(function()
                    TweenGUISafe(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.15
                    })
                end)

                Connections[settings.flag..'_button_click'] = Button.MouseButton1Click:Connect(function()
                    if settings.callback then
                        settings.callback()
                    end
                end)

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return Button
            end

            function ModuleManager:create_divider(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local dividerHeight = 1
                local dividerWidth = 188

                local OuterFrame = CreateInstance("Frame", {
                    Name = "Divider",
                    Size = UDim2.new(0, dividerWidth, 0, 20),
                    BackgroundTransparency = 1,
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })

                if settings and settings.showtopic then
                    local TextLabel = CreateInstance("TextLabel", {
                        Text = settings.title,
                        TextColor3 = Theme.TextSecondary,
                        TextTransparency = 0,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                        TextSize = 10,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 137, 0, 13),
                        Position = UDim2.new(0.5, 0, 0.5, -6.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Parent = OuterFrame
                    })
                end

                if not settings or (settings and not settings.disableline) then
                    local Divider = CreateInstance("Frame", {
                        Name = "DividerLine",
                        BackgroundColor3 = Theme.Border,
                        BackgroundTransparency = 0.3,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, dividerHeight),
                        Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2),
                        Parent = OuterFrame
                    })
                end

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return true
            end

            function ModuleManager:create_slider(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local SliderManager = {}

                local Slider = CreateInstance("TextButton", {
                    Name = "Slider",
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 22),
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })

                local TextLabel = CreateInstance("TextLabel", {
                    Name = "TextLabel",
                    Text = settings.title or "Slider",
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 11,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 137, 0, 13),
                    Position = UDim2.new(0, 0, 0, 0),
                    Parent = Slider
                })

                local Drag = CreateInstance("Frame", {
                    Name = "Drag",
                    BackgroundColor3 = Theme.ToggleOff,
                    BackgroundTransparency = 0.8,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 4),
                    Position = UDim2.new(0.5, 0, 0.95, 0),
                    AnchorPoint = Vector2.new(0.5, 1),
                    Parent = Slider
                })
                ApplyCorner(Drag, 2)

                local Fill = CreateInstance("Frame", {
                    Name = "Fill",
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 103, 0, 4),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = Drag
                })
                ApplyCorner(Fill, 2)

                local Circle = CreateInstance("Frame", {
                    Name = "Circle",
                    BackgroundColor3 = Theme.TextPrimary,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 6, 0, 6),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Parent = Fill
                })
                ApplyCorner(Circle, 10)

                local Value = CreateInstance("TextLabel", {
                    Name = "Value",
                    Text = "50",
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 42, 0, 13),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    Parent = Slider
                })

                function SliderManager:set_percentage(percentage)
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
                    TweenGUISafe(Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    })
                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position
                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
                    Connections['slider_drag_'..settings.flag] = UserInputService.InputChanged:Connect(function(input, process)
                        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
                        SliderManager:update()
                    end)
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input, process)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)
                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config)
                        end
                    end)
                end

                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag])
                    else
                        SliderManager:set_percentage(settings.value)
                    end
                else
                    SliderManager:set_percentage(settings.value)
                end

                Connections[settings.flag..'_slider_down'] = Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return SliderManager
            end

            function ModuleManager:create_dropdown(settings)
                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1
                end

                local DropdownManager = { _state = false, _size = 0 }

                local Dropdown = CreateInstance("TextButton", {
                    Name = "Dropdown",
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Panel,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 30),
                    Parent = Options
                })
                ApplyCorner(Dropdown, 6)

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule
                else
                    Dropdown.LayoutOrder = settings.OrderValue
                end

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {}
                end

                local TextLabel = CreateInstance("TextLabel", {
                    Name = "TextLabel",
                    Text = settings.title,
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 13),
                    Parent = Dropdown
                })

                local Box = CreateInstance("Frame", {
                    Name = "Box",
                    BackgroundColor3 = Theme.Panel,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 22),
                    Position = UDim2.new(0, 0, 0, 30),
                    Parent = Dropdown,
                    ClipsDescendants = true
                })
                ApplyCorner(Box, 6)

                local Header = CreateInstance("TextButton", {
                    Name = "Header",
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 188, 0, 22),
                    Parent = Box
                })

                Header.MouseEnter:Connect(function()
                    TweenGUISafe(Header, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.85
                    })
                end)
                Header.MouseLeave:Connect(function()
                    TweenGUISafe(Header, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    })
                end)

                local CurrentOption = CreateInstance("TextLabel", {
                    Name = "CurrentOption",
                    Text = "Select",
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 10,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 161, 0, 13),
                    Position = UDim2.new(0, 8, 0.5, -6.5),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = Header
                })

                local Arrow = CreateInstance("ImageLabel", {
                    Name = "Arrow",
                    Image = 'rbxassetid://84232453189324',
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 8, 0, 8),
                    Position = UDim2.new(0.91, 0, 0.5, -4),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Parent = Header
                })

                local OptionsList = CreateInstance("ScrollingFrame", {
                    Name = "Options",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 3,
                    ScrollBarImageTransparency = 0.9,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    Size = UDim2.new(0, 188, 0, 0),
                    Position = UDim2.new(0, 0, 22, 0),
                    Parent = Box,
                    Visible = false
                })

                local OptionList = CreateInstance("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = OptionsList
                })
                local OptionPad = CreateInstance("UIPadding", {
                    PaddingTop = UDim.new(0, -1),
                    PaddingLeft = UDim.new(0, 8),
                    Parent = OptionsList
                })

                function DropdownManager:update(option)
                    if settings.multi_dropdown then
                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {}
                        end
                        local CurrentTextGet = convertStringToTable(CurrentOption.Text)
                        local selected = {}
                        for _, v in ipairs(Library._config._flags[settings.flag]) do
                            table.insert(selected, v)
                        end
                        CurrentOption.Text = table.concat(selected, ", ")
                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                object.TextTransparency = table.find(selected, object.Text) and 0.2 or 0.6
                            end
                        end
                    else
                        CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                object.TextTransparency = (object.Text == CurrentOption.Text) and 0.2 or 0.6
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end
                    Config:save(game.GameId, Library._config)
                    settings.callback(option)
                end

                function DropdownManager:unfold_settings()
                    self._state = not self._state
                    ModuleManager:refresh_size()
                    local dropdownHeight = self._state and self._size or 0
                    local targetSize = ModuleManager._size + dropdownHeight

                    TweenGUISafe(Module, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(218, 93 + targetSize)
                    })
                    TweenGUISafe(Options, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(218, targetSize)
                    })
                    TweenGUISafe(Dropdown, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 188, 0, 30 + dropdownHeight)
                    })
                    TweenGUISafe(Box, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 188, 0, 22 + dropdownHeight)
                    })
                    TweenGUISafe(OptionsList, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 188, 0, dropdownHeight)
                    })
                    TweenGUISafe(Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Rotation = self._state and 180 or 0
                    })
                    OptionsList.Visible = self._state
                    ModuleManager:schedule_refresh()
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3
                    for index, value in settings.options do
                        local Option = CreateInstance("TextButton", {
                            Name = "Option",
                            Text = (typeof(value) == "string" and value) or value.Name,
                            TextColor3 = Theme.TextPrimary,
                            TextTransparency = 0.6,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                            TextSize = 10,
                            AutoButtonColor = false,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Size = UDim2.new(0, 172, 0, 16),
                            Position = UDim2.new(0, 8, 0, 0),
                            Parent = OptionsList
                        })

                        Option.MouseEnter:Connect(function()
                            TweenGUISafe(Option, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                TextTransparency = 0.2,
                                BackgroundColor3 = Theme.PanelHover
                            })
                        end)
                        Option.MouseLeave:Connect(function()
                            TweenGUISafe(Option, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                TextTransparency = 0.6,
                                BackgroundColor3 = Theme.Panel
                            })
                        end)

                        Connections[settings.flag..'_option_'..index] = Option.MouseButton1Click:Connect(function()
                            if settings.multi_dropdown then
                                if not Library._config._flags[settings.flag] then
                                    Library._config._flags[settings.flag] = {}
                                end
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
                        OptionsList.Size = UDim2.fromOffset(188, DropdownManager._size)
                    end
                end

                function DropdownManager:New(value)
                    local order = Dropdown.LayoutOrder
                    ModuleManager._dropdownRegistry[Dropdown] = nil
                    OptionsList:Destroy()
                    Dropdown:Destroy()
                    LayoutOrderModule = order - 1
                    local result = ModuleManager:create_dropdown(value)
                    task.defer(function()
                        ModuleManager:refresh_size()
                    end)
                    return result
                end

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                else
                    DropdownManager:update(settings.options[1])
                end

                Connections[settings.flag..'_dropdown_click'] = Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            function ModuleManager:create_feature(settings)
                LayoutOrderModule = LayoutOrderModule + 1

                local FeatureContainer = CreateInstance("Frame", {
                    Name = "FeatureContainer",
                    Size = UDim2.new(0, 188, 0, 16),
                    BackgroundTransparency = 1,
                    Parent = Options,
                    LayoutOrder = LayoutOrderModule
                })

                local FeatureLayout = CreateInstance("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = FeatureContainer
                })

                local FeatureButton = CreateInstance("TextButton", {
                    Name = "FeatureButton",
                    Text = "    " .. (settings.title or "Feature"),
                    TextColor3 = Theme.TextPrimary,
                    TextTransparency = 0.2,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    FontFace = Font.new(Theme.Font, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 11,
                    BackgroundColor3 = Theme.Panel,
                    BackgroundTransparency = 0.9,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -35, 0, 16),
                    Parent = FeatureContainer
                })
                ApplyCorner(FeatureButton, 4)

                FeatureButton.MouseEnter:Connect(function()
                    TweenGUISafe(FeatureButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.7
                    })
                end)
                FeatureButton.MouseLeave:Connect(function()
                    TweenGUISafe(FeatureButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.9
                    })
                end)

                local RightContainer = CreateInstance("Frame", {
                    Name = "RightContainer",
                    Size = UDim2.new(0, 45, 0, 16),
                    BackgroundTransparency = 1,
                    Parent = FeatureContainer
                })

                local RightLayout = CreateInstance("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = RightContainer
                })

                local KeybindBox = CreateInstance("TextLabel", {
                    Name = "KeybindBox",
                    Text = Library._config._flags[settings.flag] and Library._config._flags[settings.flag].BIND or "...",
                    TextColor3 = Theme.TextPrimary,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    FontFace = Font.new(Theme.FontMono, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                    TextSize = 9,
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 20, 14),
                    Parent = RightContainer,
                    LayoutOrder = 2
                })
                ApplyCorner(KeybindBox, 4)

                local KeybindButton = CreateInstance("TextButton", {
                    Name = "KeybindButton",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextTransparency = 1,
                    Parent = KeybindBox
                })

                if not Library._config._flags then
                    Library._config._flags = {}
                end
                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {
                        checked = false,
                        BIND = settings.default or "Unknown"
                    }
                end

                local checked = Library._config._flags[settings.flag].checked
                if KeybindBox.Text == "Unknown" then
                    KeybindBox.Text = "..."
                end

                local UseF_Var = nil
                if not settings.disablecheck then
                    local Checkbox = CreateInstance("TextButton", {
                        Name = "Checkbox",
                        Size = UDim2.new(0, 14, 0, 14),
                        BackgroundColor3 = checked and Theme.Accent or Theme.Panel,
                        BackgroundTransparency = 0.15,
                        BorderSizePixel = 0,
                        Text = "",
                        Parent = RightContainer,
                        LayoutOrder = 1
                    })
                    ApplyCorner(Checkbox, 3)

                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and Theme.Accent or Theme.Panel
                        Checkbox.BackgroundTransparency = checked and 0 or 0.15
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
                        if settings.button_callback then
                            settings.button_callback()
                        end
                    end
                end

                Connections[settings.flag..'_keybind_click'] = KeybindButton.MouseButton1Click:Connect(function()
                    KeybindBox.Text = "..."
                    local inputConnection
                    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode.Name
                            Library._config._flags[settings.flag].BIND = newKey
                            if newKey ~= "Unknown" then
                                KeybindBox.Text = newKey
                            end
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

                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[settings.flag].BIND then
                            UseF_Var()
                        end
                    end
                end)
                Connections["keybind_press_" .. settings.flag] = keyPressConnection

                Connections[settings.flag..'_feature_click'] = FeatureButton.MouseButton1Click:Connect(function()
                    if settings.button_callback then
                        settings.button_callback()
                    end
                end)

                if not settings.disablecheck then
                    settings.callback(checked)
                end

                ModuleManager:refresh_size()
                ModuleManager:schedule_refresh()
                return FeatureContainer
            end

            return ModuleManager
        end

        return TabManager
    end

    local lastShiftToggle = 0
    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, process)
        if input.KeyCode ~= _G.UIKey then
            return
        end
        if pcall(function() return getgenv().HyperionColorPickerOpen == true end) then
            if getgenv().HyperionColorPickerOpen == true then
                return
            end
        end
        local now = tick()
        if now - lastShiftToggle < 0.3 then return end
        lastShiftToggle = now
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    Connections['minimize_click'] = Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
        if _NotificationContainerAlive and NotificationContainer then
            _NotificationContainerAlive = false
            pcall(function() NotificationContainer:Destroy() end)
        end
    end)

    return self
end

function Library.new(settings)
    settings = type(settings) == "table" and settings or {}
    local customName = settings.UIName or settings.uiName or settings.Name or settings.name
    if customName ~= nil then
        Library.UIName(customName)
    end
    local customIcon = settings.CustomIcon or settings.customIcon or settings.Icon or settings.icon
    if customIcon ~= nil then
        Library.IconAsset(customIcon)
    end
    if settings.IconAnimated ~= nil then
        Library.IconAnimated(settings.IconAnimated)
    elseif settings.iconAnimated ~= nil then
        Library.IconAnimated(settings.iconAnimated)
    end
    local customBackground = settings.BackgroundMedia or settings.backgroundMedia or settings.background_media or settings.Background or settings.background or DefaultBackgroundMedia

    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)
    self:create_ui()
    if customBackground ~= nil then
        task.defer(function()
            if self.SetBackgroundMedia then
                self:SetBackgroundMedia(customBackground)
            end
        end)
    end
    return self
end

local BackgroundMediaHolder = nil
local BackgroundMediaToken = 0
local Container = nil
local ContainerGradient = nil
local SideBar = nil
local SideGradient = nil

local function GetMediaExtensionFromSource(source)
    source = tostring(source or ""):lower()
    local clean = source:match("^([^%?#]+)") or source
    local extension = clean:match("%.([%w]+)$")
    if extension and #extension <= 5 then
        return extension
    end
    return nil
end

local function DetectMediaExtension(data, source, contentType)
    local extension = GetMediaExtensionFromSource(source)
    local content = tostring(contentType or ""):lower()
    if content:find("gif", 1, true) then return "gif" end
    if content:find("png", 1, true) then return "png" end
    if content:find("jpeg", 1, true) or content:find("jpg", 1, true) then return "jpg" end
    if content:find("webp", 1, true) then return "webp" end
    if content:find("mp4", 1, true) then return "mp4" end
    if content:find("webm", 1, true) then return "webm" end
    if content:find("quicktime", 1, true) then return "mov" end
    if type(data) == "string" and #data >= 12 then
        if data:sub(1, 6) == "GIF87a" or data:sub(1, 6) == "GIF89a" then return "gif" end
        if data:byte(1) == 137 and data:sub(2, 4) == "PNG" then return "png" end
        if data:byte(1) == 255 and data:byte(2) == 216 and data:byte(3) == 255 then return "jpg" end
        if data:sub(1, 4) == "RIFF" and data:sub(9, 12) == "WEBP" then return "webp" end
        if data:sub(5, 8) == "ftyp" then return extension == "mov" and "mov" or "mp4" end
        if data:byte(1) == 26 and data:byte(2) == 69 and data:byte(3) == 223 and data:byte(4) == 163 then return "webm" end
    end
    return extension or "png"
end

local function GetMediaTypeFromExtension(extension)
    extension = tostring(extension or ""):lower()
    if extension == "mp4" or extension == "webm" or extension == "mov" then
        return "video"
    end
    return "image"
end

local function FetchMedia(source)
    local requestFunction = request or syn and syn.request or http_request
    if type(requestFunction) == "function" then
        local ok, response = pcall(requestFunction, { Url = source, Method = "GET" })
        if ok and type(response) == "table" then
            local body = response.Body or response.body
            local headers = response.Headers or response.headers or {}
            local contentType = headers["Content-Type"] or headers["content-type"] or headers["content-Type"]
            if type(body) == "string" and body ~= "" then
                return body, contentType
            end
        end
    end
    local ok, data = pcall(function()
        return game:HttpGet(source, true)
    end)
    if ok and type(data) == "string" and data ~= "" then
        return data, nil
    end
    return nil, nil
end

local function ResolveBackgroundMediaAsset(source, name)
    source = ResolveAssetId(source)
    if typeof(source) ~= "string" or source == "" then
        return nil, nil
    end
    local localExtension = GetMediaExtensionFromSource(source)
    if not source:match("^https?://") and type(isfile) == "function" and type(getcustomasset) == "function" and isfile(source) then
        local ok, customAsset = pcall(getcustomasset, source)
        if ok and customAsset then
            return customAsset, GetMediaTypeFromExtension(localExtension)
        end
    end
    if source:match("^https?://") and type(writefile) == "function" and type(getcustomasset) == "function" then
        local mediaFolder = ConfigFolder .. "/BackgroundMedia"
        if type(isfolder) == "function" and type(makefolder) == "function" then
            if not isfolder(ConfigFolder) then
                pcall(makefolder, ConfigFolder)
            end
            if not isfolder(mediaFolder) then
                pcall(makefolder, mediaFolder)
            end
        end
        local fileName = tostring(name or "background_media"):gsub("[^%w_%-]", "_")
        local data, contentType = FetchMedia(source)
        local extension = DetectMediaExtension(data, source, contentType)
        local mediaType = GetMediaTypeFromExtension(extension)
        local filePath = mediaFolder .. "/" .. fileName .. "." .. extension
        if type(data) == "string" and data ~= "" then
            local ok = pcall(writefile, filePath, data)
            if not ok and extension ~= "png" then
                extension = "png"
                mediaType = "image"
                filePath = mediaFolder .. "/" .. fileName .. ".png"
                pcall(writefile, filePath, data)
            end
        end
        if type(isfile) == "function" and not isfile(filePath) then
            return nil, nil
        end
        if type(isfile) ~= "function" or isfile(filePath) then
            local ok, customAsset = pcall(getcustomasset, filePath)
            if ok and customAsset then
                return customAsset, mediaType
            end
        end
    end
    return source, GetMediaTypeFromExtension(localExtension)
end

local function ResolveScaleType(value)
    if typeof(value) == "EnumItem" then
        return value
    end
    if typeof(value) == "string" and Enum.ScaleType[value] then
        return Enum.ScaleType[value]
    end
    return Enum.ScaleType.Crop
end

local function ClearBackgroundMedia()
    BackgroundMediaToken += 1
    if BackgroundMediaHolder then
        BackgroundMediaHolder.Visible = false
        for _, child in BackgroundMediaHolder:GetChildren() do
            if child ~= BackgroundMediaCorner then
                child:Destroy()
            end
        end
    end
    if Container then
        Container.BackgroundTransparency = 0.05
        if ContainerGradient then ContainerGradient.Enabled = true end
        if SideBar then SideBar.BackgroundTransparency = 0 end
        if SideGradient then SideGradient.Enabled = true end
    end
end

function Library:ClearBackgroundMedia()
    ClearBackgroundMedia()
end

function Library:SetBackgroundMedia(mediaSettings)
    if mediaSettings == nil or mediaSettings == false then
        ClearBackgroundMedia()
        return false
    end
    if typeof(mediaSettings) ~= "table" then
        mediaSettings = { Source = mediaSettings }
    end
    if mediaSettings.Enabled == false or mediaSettings.enabled == false then
        ClearBackgroundMedia()
        return false
    end
    local requestedMediaType = mediaSettings.Type or mediaSettings.type or mediaSettings.MediaType or mediaSettings.mediaType or mediaSettings.media_type
    local mediaType = tostring(requestedMediaType or "auto"):lower()
    if mediaType == "none" or mediaType == "off" or mediaType == "clear" then
        ClearBackgroundMedia()
        return false
    end
    local source = mediaSettings.Source or mediaSettings.source or mediaSettings.Asset or mediaSettings.asset or mediaSettings.Url or mediaSettings.url or mediaSettings.Image or mediaSettings.image or mediaSettings.Video or mediaSettings.video
    local asset, detectedMediaType = ResolveBackgroundMediaAsset(source, mediaSettings.SaveAs or mediaSettings.saveAs or mediaSettings.Name or mediaSettings.name)
    if not asset then
        ClearBackgroundMedia()
        return false
    end
    if mediaType == "auto" or mediaType == "" then
        mediaType = detectedMediaType or "image"
    end
    ClearBackgroundMedia()
    BackgroundMediaToken += 1
    local token = BackgroundMediaToken
    local opacity = Clamp01(mediaSettings.Opacity or mediaSettings.opacity)
    opacity = opacity or 0.45

    if not BackgroundMediaHolder and Container then
        BackgroundMediaHolder = CreateInstance("Frame", {
            Name = "BackgroundMedia",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Visible = false,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            ZIndex = 0,
            Parent = Container
        })
        BackgroundMediaCorner = CreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 14),
            Parent = BackgroundMediaHolder
        })
    end

    local media
    if mediaType == "video" or mediaType == "mp4" or mediaType == "webm" then
        media = CreateInstance("VideoFrame", {
            Video = asset,
            Looped = mediaSettings.Looped ~= false and mediaSettings.looped ~= false,
            Volume = tonumber(mediaSettings.Volume or mediaSettings.volume) or 0,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            ZIndex = 0,
            Parent = BackgroundMediaHolder
        })
        pcall(function() media:Play() end)
    else
        media = CreateInstance("ImageLabel", {
            Image = asset,
            ImageTransparency = 1 - opacity,
            ImageColor3 = mediaSettings.Color or mediaSettings.color or Theme.Text,
            ScaleType = ResolveScaleType(mediaSettings.ScaleType or mediaSettings.scaleType),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            ZIndex = 0,
            Parent = BackgroundMediaHolder
        })
    end
    media.Name = "Media"

    local dimOpacity = Clamp01(mediaSettings.DimOpacity or mediaSettings.dimOpacity or mediaSettings.dim_opacity)
    if dimOpacity and dimOpacity > 0 then
        local dim = CreateInstance("Frame", {
            Name = "Dim",
            BackgroundColor3 = mediaSettings.DimColor or mediaSettings.dimColor or Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1 - dimOpacity,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            ZIndex = 0,
            Parent = BackgroundMediaHolder
        })
    end

    BackgroundMediaHolder.Visible = token == BackgroundMediaToken
    if token == BackgroundMediaToken then
        pcall(function()
            Container.BackgroundTransparency = 1
            if ContainerGradient then ContainerGradient.Enabled = false end
            if SideBar then SideBar.BackgroundTransparency = 1 end
            if SideGradient then SideGradient.Enabled = false end
        end)
    end
    return true
end

Library.set_background_media = Library.SetBackgroundMedia
Library.clear_background_media = Library.ClearBackgroundMedia
Library.SetBackgroundImage = Library.SetBackgroundMedia
Library.set_background_image = Library.SetBackgroundMedia

-- UIName Breathing Animation
local function AnimateUIName()
    if not Library._ui then return end
    local ClientName = Library._ui.Container.Content.TopBar.PageTitle
    if not ClientName then return end
    local DeepRed = Color3.fromRGB(80, 8, 8)
    local BrightRed = Color3.fromRGB(255, 45, 45)
    while Library._ui and Library._ui.Parent do
        TweenGUISafe(ClientName, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextColor3 = BrightRed
        })
        task.wait(2)
        if not Library._ui or not Library._ui.Parent then break end
        TweenGUISafe(ClientName, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextColor3 = DeepRed
        })
        task.wait(2)
    end
end

-- Preserve old API for compatibility
Library.create_module = Library.create_module or Library.create_module

return Library
