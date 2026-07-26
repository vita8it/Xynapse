local Importer = ...

local _ENV = (getgenv or getrenv or getfenv)()

local Cache = {}
local Packages = {}
local Settings = {}

local Session = os.clock() do
    _ENV.Session = Session
    _ENV.Settings = Settings
end

local Owner = "vita8it"
local Respoitory = "Xynapse"

local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService('TeleportService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local Players = game:GetService('Players')

local PlaceId = game.PlaceId
local JobId = game.JobId

local LocalPlayer = Players.LocalPlayer

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped

local KeyboardEnabled = UserInputService.KeyboardEnabled
local TouchEnabled = UserInputService.TouchEnabled

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

function NewPackage(Name, Module)
    do Packages[Name] = Module()
        return Packages[Name]
    end
end 

NewPackage("Importer", function()
    return Importer
end)

NewPackage("Connectors", function()
    local Connectors = {}

    local Connections = _ENV.Connections or {} do
        _ENV.Connections = Connections

        for i = 1, #Connections do
            Connections[i]:Disconnect()
        end

        table.clear(Connections)
    end

    function Connections.Connect(Instance, Callback)
        local Connection = Instance:Connect(Callback)
        table.insert(Connections, Connection) do
            return Connection 
        end
    end

    return Connections
end)

NewPackage("Configurators", function()
    local Configurators = {}
    Configurators.__index = Configurators

    local Operators = {
        "makefolder", "writefile", "getcustomasset",
        "isfolder", "readfile", "isfile", "setclipboard"
    }

    for _, Operator in Operators do
        Cache[Operator] = _ENV[Operator]
    end

    function Configurators:Folder()
        local Pathable = self.Paths

        for i = 1, #Pathable do
            local Path = Pathable[i]

            if not Cache.isfolder(Path) then
                Cache.makefolder(Path)
            end
        end
    end

    function Configurators:Default(Index, Value)
        if rawget(self.Data, Index) == nil then
            rawset(self.Data, Index, Value); self:Save()
        end
    end

    function Configurators:Save(Index, Value)
        if Index ~= nil then
            rawset(self.Data, Index, Value)
        end

        self:Folder()

        local Json = HttpService:JSONEncode(self.Data) do
            return Cache.writefile(self.Json, Json) 
        end
    end

    function Configurators:Load()
        if not Cache.isfile(self.Json) then
            self:Save()
        end

        local Success, Result = pcall(function()
            return HttpService:JSONDecode(
                Cache.readfile(self.Json)
            )
        end)

        if Success and typeof(Result) == "table" then
            table.clear(self.Data)

            for Index, Value in Result do
                self.Data[Index] = Value
            end
        end
    end

    function Configurators.new(Folder)
        local self = setmetatable({}, Configurators)

        Folder = Folder or "Unknown"

        self.Files = Folder
        self.Settings = `{Folder}/settings`

        self.Json = `{self.Settings}/{PlaceId}.json`
        self.Paths = { self.Files, self.Settings }

        self.Data = {}

        self:Folder() do
            self:Load()
            self:Default("Success", true) 
        end

        Settings = setmetatable({}, {
            __index = function(_, Index)
                return self.Data[Index]
            end,
            __newindex = function(_, Index, Value)
                if self.Data[Index] ~= Value then
                    self.Data[Index] = Value; self:Save()
                end
            end
        })

        _ENV.Settings = Settings

        return self
    end

    return Configurators
end)

NewPackage("Queueable", function()
    local Queueable = {}
    Queueable.__index = Queueable

    function Queueable:Error(Message)
        _ENV.OnFarm = false

        local Option = _ENV.RunningOption or "Unknow"
        local Text = (`error [ { Option } ] { Message }`)

        if _ENV.Error then
            _ENV.Error.Text ..= `\n\n{ Text }`
        else
            local Error = Instance.new("Message") do
                Error.Parent = workspace
                Error.Text = Text
            end

            _ENV.Error = Error
        end
    end

    function Queueable:ResetQueue()
        local Fallback = self.Fallback

        local Option = _ENV.RunningOption
        local Error = _ENV.Error

        if Error then
            Error.Text = "Start Refresh Options."

            task.wait(2)


            if Option and Fallback[Option] then
                Fallback[Option]:SetValue(false)
                Error.Text = `Disabled : {Option}`
            end

            task.wait(2)

            Error:Destroy()
            _ENV.Error = nil

            self:RunQueue()
        end
    end

    function Queueable:GetQueue()
        for _, Option in self.FarmFunctions do
            _ENV.RunningOption = Option.Name

            local Method = Option.Function()

            if Method then
                if type(Method) == "string" then
                    _ENV.RunningMethod = Method
                end

                return Method
            end
        end

        _ENV.RunningOption, _ENV.RunningMethod = nil, nil
    end

    function Queueable:RunQueue()
        local Success, Error = pcall(function()
            while task.wait(0) do
                if _ENV.Session ~= Session then
                    _ENV.RunningOption, _ENV.RunningMethod = nil, nil
                    _ENV.OnFarm = false

                    warn("Breakable", Session); break
                end

                _ENV.OnFarm = self:GetQueue() and true or false
            end
        end)

        if not Success then
            self:Error(Error)
            task.delay(3, function()
                self:ResetQueue(Error)
            end)
        end
    end

    function Queueable:UpdateOptions()
        table.clear(self.FarmFunctions)

        for Index, Value in self.NewValues do
            self.Cloneables[ Index ] = Value or nil
            self.NewValues[ Index ] = nil
        end

        for i = 1, #self.Functions do
            local Function = self.Functions[i]

            if self.Cloneables[Function.Name] then
                table.insert(self.FarmFunctions, Function)
            end
        end
    end

    function Queueable:While(Value, Interval, Callback, Break)
        while Value do
            local Tick = tick()

            if Callback then Callback() end
            if Break and Break() then break end

            repeat
                RunService.Heartbeat:Wait()
            until tick() - Tick >= (Interval or 0.1)
        end
    end

    function Queueable:NewOption(Flag, Function, Interval)
        if Interval then
            self.Threads[Flag] = function(Value)
                self:While(Value, Interval or 0.1, Function, function()
                    return not Value or _ENV.Session ~= Session
                end)
            end
        else
            self.Indexable[Flag] = Function
            table.insert(self.Functions, { 
                ["Name"] = Flag,
                ["Function"] = Function
            })
        end
    end

    function Queueable.new(Running)
        local self = setmetatable({}, Queueable)

        self.Fallback = {}

        self.NewValues = {}
        self.Cloneables = {}

        self.Functions = _ENV.Functions or {}
        self.FarmFunctions = _ENV.FarmFunctions or {}

        self.IsDebounce = false

        self.Enableds = _ENV.Enableds or setmetatable({}, {
            __newindex = function(_, Index, Value)
                self.NewValues[Index] = Value or false

                if not self.IsDebounce then
                    self.IsDebounce = true

                    task.spawn(function()
                        self:UpdateOptions()
                        self.IsDebounce = false
                    end)
                end
            end,
            __index = self.Cloneables
        })

        self.Threads = {}
        self.Indexable = {} do
            _ENV.FarmFunctions = self.FarmFunctions
            _ENV.Functions = self.Functions
            _ENV.Enableds = self.Enableds

            task.spawn(function()
                if Running then self:RunQueue() end
            end)

            table.clear(self.Functions)
        end

        return self
    end

    return Queueable
end)

NewPackage("EachOthers", function()
    local EachOthers = {}

    function EachOthers:Reversed(Cursor)
        local Url = `https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&limit=100`

        if Cursor then Url ..= `&cursor={Cursor}` end

        local Result = game:HttpGet(Url)

        return HttpService:JSONDecode(Result)
    end

    function EachOthers:Rejoin()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining");wait()

            return TeleportService:Teleport(PlaceId, LocalPlayer)
        end

        return TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end

    function EachOthers:Change()
        local Server, Next

        repeat
            local Servers = Server:Reversed(Next)

            Server = Servers and Servers.data and Servers.data[1]
            Next = Servers and Servers.nextPageCursor
        until Server

        if not Server or not Server.id then return end
        return TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
    end

    function EachOthers:Join(Id)
        return TeleportService:TeleportToPlaceInstance(PlaceId, Id, LocalPlayer)
    end

    function EachOthers:Set3d(value)
        RunService:Set3dRenderingEnabled(if value then false else true)
    end

    function EachOthers:Low()
        local Terrain = workspace:FindFirstChildOfClass('Terrain') do
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0

            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9

            settings().Rendering.QualityLevel = 1
        end
    end

    return EachOthers
end)

NewPackage("AssetsModule", function()
    local Constant = "Socute.png"
    
    local AssetsModule = {}
    local Saved = {}

    function AssetsModule:Download(Url, Name)
        local Data = game:HttpGet(Url)
        
        Cache.writefile(Name, Data)
        Saved[ Name ] = Data

        return Data
    end

    function AssetsModule:Get(Name)
        if Saved[ Name ] then
            return Cache.getcustomasset( Name )
        end

        if Cache.isfile( Name ) then
            Saved[ Name ] = Cache.readfile( Name )
            return Cache.getcustomasset( Name )
        end

        return 0
    end

    if not Cache.isfile(Constant) then
        AssetsModule:Download("https://raw.githubusercontent.com/vita8it/Xynapse/main/Assets/Socute.png", Constant) 
    end

    return AssetsModule
end)

NewPackage("Plugins", function()
    local Plugins = {}
    
    local StatColors = {
        Working = Color3.fromRGB(0, 200, 100),
        Bugged = Color3.fromRGB(255, 200, 30),
        Tester = Color3.fromRGB(0, 100, 255)
    }

    local Library = Importer("Utils/Library")()

    local AssetsModule = Packages.AssetsModule
    local EachOthers = Packages.EachOthers
    
    local Configable = Packages.Configurators.new(Respoitory)
    
    function Plugins:ProxyPage(Page)
        return setmetatable({}, {
            __index = Page,
            __newindex = function(self, Index, Value)
                local Section = Page:Section({
                    Header = Index,
                    Light = StatColors[ Value ] or StatColors.Bugged
                })

                rawset(self, Index, Section)
            end
        })
    end

    function Plugins:Window(Args, Queueable)
        self.Enableds = Queueable.Enableds
        self.Fallback = Queueable.Fallback
        self.Threads = Queueable.Threads

        self.Sections = {}

        self.Library = Library:Window({
            Title = Args[1],
            Footer = Args[2],
            Logo = Args[3]
        })

        return self.Library
    end

    function Plugins:Page(Icon)
        return self:ProxyPage( self.Library:NewPage(Icon) )
    end

    function Plugins:Button(Section, Info, Callback)
        return Section:Button({
            Title = Info[1],
            Desc = Info[2],
            Type = Info[3] or "Primary",
            Callback = Callback,
        })
    end
    
    function Plugins:Toggle(Section, Info, Flag, Callback)
        local Thread = nil

        self.Fallback[ Flag ] = Section:Toggle({
            Title = Info[1],
            Desc = Info[2],
            Value = Settings[Flag],
            Callback = function(Value)
                Settings[ Flag ] = Value
                Enableds[ Flag ] = Value

                if Value and self.Threads[ Flag ] ~= nil then
                    Thread = task.spawn(self.Threads[ Flag ], Value)
                else
                    if Thread then task.cancel(Thread) end
                end

                if Callback then task.spawn(Callback, Value) end
            end
        })

        return self.Fallback[Flag]
    end
    
    function Plugins:Slider(Section, Info, Value, Flag, Callback)
        return Section:Slider({
            Title = Info[1],
            Desc = Info[2],
            Min = Value[1],
            Max = Value[2],
            Rounding = Value[3],
            Value = Settings[Flag],
            Callback = function(Value)
                Settings[ Flag ] = Value

                if Callback then task.spawn(Callback, Value) end
            end
        })
    end
    
    function Plugins:Dropdown(Section, Info, List, Flag, Callback)
        return Section:Dropdown({
            Title = Info,
            Value = Settings[Flag] or "None",
            List = List,
            Callback = function(Value)
                Settings[Flag] = Value

                if Callback then  task.spawn(Callback, Value) end
            end
        })
    end
    
    function Plugins:Input(Section, Info, Flag, Callback)
        return Section:Textbox({
            Title = Info[1],
            Desc = Info[2],
            Text = Settings[Flag] or "None",
            Callback = function(Value)
                Settings[Flag] = Value

                if Callback then task.spawn(Callback, Value) end
            end,
        })
    end
    
    function Plugins:Community()
        local Community = Plugins:Page(115960025411300) do
            Community.Community = "Working" do
                local Banner = AssetsModule:Get("Socute.png") do
                    Community:Banner(Banner or 133959433736215) 
                end
                
                Plugins:Button(Community.Community, {
                    "Discord",
                    "Join our community."
                }, function()
                    pcall(Cache.setclipboard, "https://discord.gg/T68udyKvAX")
                end)
            end
        end

        return Community:Navative()
    end

    function Plugins:Managers()
        Configable:Default("Language", "English")
        
        local Managers = Plugins:Page(134261589888025) do
            Managers.Server = "Working" do
                Configable:Default("JobId", JobId)
                
                Plugins:Input(Managers.Server, { 
                    "JobId",
                    "Put the job id."
                }, 'JobId')

                Plugins:Button(Managers.Server, {
                    "Join",
                    "Connect to the server using the provided JobId."
                }, function()
                    EachOthers:Join(Settings.JobId)
                end)

                Plugins:Button(Managers.Server, {
                    "Change",
                    "Teleport to a different public server instance."
                }, function()
                    EachOthers:Change()
                end)

                Plugins:Button(Managers.Server, {
                    "Rejoin",
                    "Reconnect to the current server instance."
                }, function()
                    EachOthers:Rejoin()
                end)
            end
            
            Managers.Optimize = "Working" do
                Plugins:Toggle(Managers.Optimize, {
                    "White Screen",
                    "Disabled 3D Rendering to improve performance."
                }, "White Screen", function(value)
                    EachOthers:Set3d(value)
                end)

                Plugins:Button(Managers.Optimize, { 
                    "Fast Mode",
                    "Set graphics quality to low."
                }, function()
                    EachOthers:Low()
                end)
            end
            
            Managers.Settings = "Working" do
                Configable:Default("Scaler", IsMobile and 1 or 1.45)

                Plugins:Slider(Managers.Settings, {
                    "Interface Scaler",
                    "Set interface scale."
                }, { 1, 2, 2 }, "Scaler", function(Value)
                    Plugins.Library:SetScale(Value)
                end)

                Plugins:Button(Managers.Settings, {
                    "Remove Worksapce",
                    "Reset save setting file to default value.",
                }, function()
                    local Json = Configable.Json

                    if Json and Cache.isfile(Json) then
                        pcall(Cache.delfile, Json)
                    end
                end)
            end
        end
    end

    return Plugins
end)

NewPackage("TweenManager", function()
    local TweenManager = {}
    TweenManager.__index = TweenManager

    local Tweens = {}
    local EasingStyle = Enum.EasingStyle.Linear

    function TweenManager.new(Object, Time, Property, Value)
        local self = setmetatable({}, TweenManager)

        self.Value = Value
        self.Object = Object

        self.Info = TweenInfo.new(Time, EasingStyle)
        self.Tween = TweenService:Create(Object, self.Info, {
            [ Property ] = Value
        })

        self.Tween:Play()

        if Tweens[ Object ] then
            Tweens[ Object ]:destroy()
        end

        Tweens[ Object ] = self

        return self
    end

    function TweenManager:Destroy()
        self.Tween:Pause()
        self.Tween:Destroy()

        Tweens[ self.Object ] = nil
        setmetatable(self, nil)
    end

    function TweenManager:StopTween(Object)
        if Object and Tweens[ Object ] then
            Tweens[ Object ]:destroy()
        end
    end

    return TweenManager
end)

NewPackage("BodyVelocity", function()
    local Connectors = Packages.Connectors

    local BodyVelocity = Instance.new("BodyVelocity") do
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyVelocity.P = 1000
    end

    local Highlight = Instance.new("Highlight") do
        Highlight.FillColor = Color3.fromRGB(255, 255, 255)
        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        Highlight.FillTransparency = 0.3
    end

    if _ENV.BodyVelocity then
        _ENV.BodyVelocity:Destroy()
    end

    if _ENV.Highlight then
        _ENV.Highlight:Destroy()
    end

    _ENV.BodyVelocity = BodyVelocity
    _ENV.Highlight = Highlight

    local CanCollideObjects = {}

    local function AddObjectToBaseParts(Object)
        if Object:IsA("BasePart") and Object.CanCollide then
            table.insert(CanCollideObjects, Object)
        end
    end

    local function RemoveObjectsFromBaseParts(BasePart)
        local index = table.find(CanCollideObjects, BasePart)

        if index then
            table.remove(CanCollideObjects, index)
        end
    end

    local function NewCharacter(Character)
        if not Character then return end

        table.clear(CanCollideObjects)

        for _, Object in Character:GetDescendants() do AddObjectToBaseParts(Object) end
        Character.DescendantAdded:Connect(AddObjectToBaseParts)
        Character.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
    end

    Connectors.Connect(LocalPlayer.CharacterAdded, NewCharacter)
    task.spawn(NewCharacter, LocalPlayer.Character)

    local function NoClipOnStepped(Character)
        if _ENV.OnFarm then
            for i = 1, #CanCollideObjects do
                CanCollideObjects[i].CanCollide = false
            end
        elseif Character.PrimaryPart and not Character.PrimaryPart.CanCollide then
            for i = 1, #CanCollideObjects do
                CanCollideObjects[i].CanCollide = true
            end
        end
    end

    local function UpdateVelocityOnStepped(Character)
        local BasePart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")

        local BodyVelocity = _ENV.BodyVelocity
        local Highlight = _ENV.Highlight

        if _ENV.OnFarm and BasePart and Humanoid and Humanoid.Health > 0 then
            if BodyVelocity.Parent ~= BasePart then
                BodyVelocity.Parent = BasePart
            end

            if Highlight.Parent ~= Character then
                Highlight.Parent = Character
            end
        elseif BodyVelocity.Parent then
            BodyVelocity.Parent = nil
            Highlight.Parent = nil
        end

        if not Humanoid or not Humanoid.SeatPart or not _ENV.OnFarm then
            if BodyVelocity.Velocity ~= Vector3.zero then
                BodyVelocity.Velocity = Vector3.zero
                Highlight.Parent = nil
            end
        end
    end

    Connectors.Connect(Stepped, function()
        local Character = LocalPlayer.Character
        if not Character then return end

        local Humanoid = Character:FindFirstChildOfClass('Humanoid')

        if Humanoid and Humanoid.Health > 0 then
            UpdateVelocityOnStepped(Character)
            NoClipOnStepped(Character)
        end
    end)

    return BodyVelocity
end)

return Packages, Settings
