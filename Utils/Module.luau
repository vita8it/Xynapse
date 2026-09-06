local _ENV = (getgenv or getrenv or getfenv)()

local Owner = "vita8it"
local Respoitory = "Next.js"

local Cached = {}
local Module, Settings = {}, {}
local Errors = _ENV.Errors or {}

local Session = os.clock() do
    _ENV.Errors = Errors
    _ENV.Session = Session
    _ENV.Settings = Settings
end

local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService('TeleportService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local Players = game:GetService('Players')

local PlaceId = game.PlaceId
local JobId = game.JobId

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped
local Player = Players.LocalPlayer

function Module:NewModule(Name, Function)
    do Module[Name] = Function()
        return Module[Name]
    end
end

function Module:Import(Path)
    local Github = 'https://raw.githubusercontent.com/%s'
    local Direct = `{Owner}/{Respoitory}/main/{Path}.luau`

    local Formater = Github:format(Direct)
    local Success, Result = pcall(function()
        return game:HttpGet(Formater)
    end)

    return loadstring(Result)
end 

function Module:Color(Text, Color)
    if type(Text) ~= "string" or typeof(Color) ~= "Color3" then
        return Text
    end

    local R = math.floor(Color.R * 255)
    local G = math.floor(Color.G * 255)
    local B = math.floor(Color.B * 255)

    return string.format(
        '<font color="rgb(%d, %d, %d)">%s</font>',
        R, G, B, Text
    )
end

function Module:TableToString(Value, Indent, Seen)
    Indent = Indent or 0
    Seen = Seen or {}

    if type(Value) ~= "table" then
        if typeof(Value) == "Instance" then
            return Value:GetFullName()
        elseif type(Value) == "string" then
            return string.format("%q", Value)
        end

        return tostring(Value)
    end

    if Seen[Value] then
        return "<recursive>"
    end

    Seen[Value] = true

    local Space = string.rep("    ", Indent)
    local Result = {"{\n"}

    for Key, Object in next, Value do
        table.insert(Result,
            string.format(
                "%s    [%s] = %s,\n",
                Space,
                self:TableToString(Key, 0, Seen),
                self:TableToString(Object, Indent + 1, Seen)
            )
        )
    end

    table.insert(Result, Space .. "}")
    return table.concat(Result)
end

Module:NewModule("Connections", function()
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

Module:NewModule("Configurations", function()
    local Configurations = {}
    Configurations.__index = Configurations

    local Operators = {
        "makefolder", "writefile", "getcustomasset",
        "isfolder", "readfile", "isfile", "setclipboard"
    }

    for _, Operator in Operators do
        Cached[Operator] = _ENV[Operator]
    end

    function Configurations:Folder()
        local Pathable = self.Paths

        for i = 1, #Pathable do
            local Path = Pathable[i]

            if not Cached.isfolder(Path) then
                Cached.makefolder(Path)
            end
        end
    end

    function Configurations:Default(Index, Value)
        if rawget(self.Data, Index) == nil then
            rawset(self.Data, Index, Value); self:Save()
        end
    end

    function Configurations:Save(Index, Value)
        if Index ~= nil then
            rawset(self.Data, Index, Value)
        end

        self:Folder()

        local Json = HttpService:JSONEncode(self.Data) do
            return Cached.writefile(self.Json, Json) 
        end
    end

    function Configurations:Load()
        if not Cached.isfile(self.Json) then
            self:Save()
        end

        local Success, Result = pcall(function()
            return HttpService:JSONDecode(
                Cached.readfile(self.Json)
            )
        end)

        if Success and typeof(Result) == "table" then
            table.clear(self.Data)

            for Index, Value in Result do
                self.Data[Index] = Value
            end
        end
    end

    function Configurations.Build(Folder)
        local self = setmetatable({}, Configurations)

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

    return Configurations
end)

Module:NewModule("GoodQueue", function()
    local Queueable = {}
    Queueable.__index = Queueable

    function Queueable:Error(Message)
        _ENV.OnFarm = false

        local Option = _ENV.RunningOption or "Unknown"
        local Text = (`error [ {Option} ] {Message}`)

        Errors[Option] = Errors[Option] or {}
        table.insert(Errors[Option], Message)

        local Error = _ENV.Error

        if Error and Error.Parent then
            Error.Text ..= `\n\n{Text}`
            return
        end

        Error = Instance.new("Message")
        Error.Parent = workspace
        Error.Text = Text

        _ENV.Error = Error
    end

    function Queueable:ResetQueue()
        if self.Resetting then
            return
        end

        self.Resetting = true

        local Error = _ENV.Error
        local Option = _ENV.RunningOption
        local Fallback = self.Fallback

        if Error and Error.Parent then
            Error.Text = "Start Refresh Options."

            task.wait(2)

            local Value = Option and Fallback[Option]

            if Value then
                pcall(Value.SetValue, Value, false)
                Error.Text = `Disabled : {Option}`
            end

            task.wait(2)

            if Error.Parent then
                Error:Destroy()
            end

            if _ENV.Error == Error then
                _ENV.Error = nil
            end
        end

        self.Resetting = false

        if _ENV.Session == Session then
            self:RunQueue()
        end
    end

    function Queueable:GetQueue()
        for _, Option in ipairs(self.FarmFunctions) do
            if type(Option) ~= "table" or type(Option.Function) ~= "function" then
                continue
            end

            local Name = Option.Name or "Unknown"
            _ENV.RunningOption = Name

            local Success, Result = pcall(Option.Function)

            if not Success then
                error(Result, 0)
            end

            if Result then
                _ENV.RunningMethod = type(Result) == "string" and Result or nil
                return Result
            end
        end

        _ENV.RunningOption = nil
        _ENV.RunningMethod = nil

        return nil
    end

    function Queueable:RunQueue()
        if self.Running then
            return
        end

        self.Running = true

        task.spawn(function()
            local Success, Error = xpcall(function()
                while _ENV.Session == Session do
                    local Result = self:GetQueue()
                    _ENV.OnFarm = Result ~= nil

                    RunService.Heartbeat:Wait()
                end

                _ENV.RunningOption = nil
                _ENV.RunningMethod = nil
                _ENV.OnFarm = false
            end, debug.traceback)

            self.Running = false

            if not Success and _ENV.Session == Session then
                self:Error(Error)

                task.delay(3, function()
                    if _ENV.Session == Session then
                        self:ResetQueue()
                    end
                end)
            end
        end)
    end

    function Queueable:UpdateOptions()
        table.clear(self.FarmFunctions)

        for Index, Value in pairs(self.NewValues) do
            self.Cloneables[Index] = Value or nil
            self.NewValues[Index] = nil
        end

        for _, Function in ipairs(self.Functions) do
            if self.Cloneables[Function.Name] then
                table.insert(self.FarmFunctions, Function)
            end
        end
    end

    function Queueable:While(Value, Interval, Callback, Break)
        Interval = Interval or 0.1

        while Value and _ENV.Session == Session do
            local Start = os.clock()

            if Callback then
                local Success, Error = pcall(Callback)

                if not Success then
                    error(Error, 0)
                end
            end

            if Break and Break() then
                break
            end

            repeat
                RunService.Heartbeat:Wait()
            until os.clock() - Start >= Interval or _ENV.Session ~= Session
        end
    end

    function Queueable:NewOption(Flag, Function, Interval)
        if type(Flag) ~= "string" or type(Function) ~= "function" then
            return
        end

        if Interval then
            self.Threads[Flag] = function(Value)
                self:While(Value, Interval, Function, function()
                    return not Value or _ENV.Session ~= Session
                end)
            end
        else
            self.Indexable[Flag] = Function

            table.insert(self.Functions, {
                Name = Flag,
                Function = Function
            })
        end
    end

    function Queueable.Build(Running)
        local self = setmetatable({}, Queueable)

        self.Fallback = {}
        self.NewValues = {}
        self.Cloneables = {}
        self.Threads = {}
        self.Indexable = {}
        self.Running = false
        self.Resetting = false

        self.Functions = _ENV.Functions or {}
        self.FarmFunctions = _ENV.FarmFunctions or {}

        self.Enableds = _ENV.Enableds or setmetatable({}, {
            __newindex = function(_, Index, Value)
                self.NewValues[Index] = Value or false
                self:UpdateOptions()
            end,

            __index = self.Cloneables
        })

        _ENV.Functions = self.Functions
        _ENV.FarmFunctions = self.FarmFunctions
        _ENV.Enableds = self.Enableds

        if Running then
            self:RunQueue()
        end

        table.clear(self.Functions)

        return self
    end

    return Queueable
end)

Module:NewModule("EachOthers", function()
    local EachOthers = {}

    function EachOthers:Join(Id)
        return TeleportService:TeleportToPlaceInstance(PlaceId, Id, Player)
    end

    function EachOthers:Reversed(Cursor)
        local Url = `https://games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Asc&limit=100`

        if Cursor then Url ..= `&cursor={Cursor}` end

        local Result = game:HttpGet(Url)

        return HttpService:JSONDecode(Result)
    end

    function EachOthers:Rejoin()
        if #Players:GetPlayers() <= 1 then
            Player:Kick("\nRejoining");wait()

            return TeleportService:Teleport(PlaceId, Player)
        end

        return self:Join(JobId)
    end

    function EachOthers:Change()
        local Server, Next

        repeat
            local Servers = self:Reversed(Next)

            Server = Servers and Servers.data and Servers.data[1]
            Next = Servers and Servers.nextPageCursor
        until Server

        if not Server or not Server.id then return end
        return self:Join(Server.id)
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

Module:NewModule("Plugins", function()
    local Plugins = {}

    local Nodes = Module:Import("Utils/Library")()

    local Configurations = Module.Configurations
    local EachOthers = Module.EachOthers

    local Configable = Configurations.Build('Next-js')

    Plugins.Add = function(En, th)
        return Settings['Select Laugage'] == 'English' and En or th
    end

    Plugins.ParagraphTypes = {
        Icon = function(Paragraph, Value)
            return Paragraph:Icon(Value)
        end,
        Text = function(Paragraph, Value)
            return Paragraph:Typography(Value)
        end,
        Status = function(Paragraph, Value)
            return Paragraph:Status(Value)
        end,
    }

    function Plugins:Default(...)
        Configable:Default(...)
    end

    Plugins:Default("Select Laugage", "English")

    function Plugins:NewProxy(Tab)
        local Proxy = {}

        function Proxy:Section(Name, Callback)
            local Element = Tab[Name]

            if not Element then
                Element = Tab:Section(Name)
                rawset(Tab, Name, Element)
            end

            if Callback then
                Callback(Element)
            end

            return Element
        end

        setmetatable(Proxy, {
            __index = function(self, Index)
                return Tab[Index]
            end,
            __newindex = function(self, Index, Value)
                rawset(Tab, Index, Value)
            end,
        })

        return Proxy
    end

    function Plugins:Window(Queueable, Args)
        Args = Args or {}

        self.Nodes = Nodes

        self.Enableds = Queueable.Enableds
        self.Fallback = Queueable.Fallback
        self.Threads = Queueable.Threads

        self.Library = Nodes.Application("Next.js", {
            Title = Args[1] or "Xynapse",
            Footer = Args[2] or "Made by vita8it",
            Logo = Args[3] or 124715602753920,
        })

        return self.Library
    end

    function Plugins:Notify(Args, Duration)
        return self.Library:Notification({
            Title = Args[1],
            Description = Args[2],
            Icon = Args[3] or 107131709546324,
            Duration = Duration or 5
        })
    end

    function Plugins:Dialog(Args, Callback)
        return self.Library:Dialog({
            Title = Args[1],
            Description = Plugins.Add("Are you sure?", "คุณแน่ใจหรือไม่?"),
            Content = Args[2],
            Icon = Args[3] or 107131709546324,
            Callback = function(State)
                if State then
                    task.spawn(pcall, Callback)
                end
            end,
        })
    end

    function Plugins:MakeTab(Args, Select)
        local NewTab = self.Library:MakeTab({
            Title = Args[1],
            Description = Args[2] or Plugins.Add("Automatically", "อัตโนมัติ"),
            Icon = Args[3],
        })

        return self:NewProxy(NewTab)
    end

    function Plugins:Paragraph(Section, Args, Types)
        local Paragraph = Section:Paragraph({
            Title = Args[1],
            Description = Args[2],
        })

        if not Types then
            return Paragraph
        end

        local Handler = Plugins.ParagraphTypes[Types[1]]

        if Handler then
            return Handler(Paragraph, Types[2])
        end

        return Paragraph
    end

    function Plugins:Button(Section, Args, Callback)
        return Section:Button({
            Title = Args[1],
            Description = Args[2],
            Type = Args[3] or "Primary",
            Callback = Callback,
        })
    end

    function Plugins:Toggle(Section, Args, Flag, Callback)
        local Thread = nil

        self.Fallback[ Flag ] = Section:Toggle({
            Title = Args[1],
            Description = Args[2],
            Value = Settings[Flag],
            Callback = function(_, Value)
                Settings[ Flag ] = Value
                self.Enableds[ Flag ] = Value

                if Value and self.Threads[ Flag ] ~= nil then
                    Thread = task.spawn(self.Threads[ Flag ], Value)
                else
                    if Thread then task.cancel(Thread) end
                end

                if Callback then Callback(Value) end
            end
        })

        return self.Fallback[Flag]
    end

    function Plugins:Slider(Section, Args, Values, Flag, Callback)
        return Section:Slider({
            Title = Args[1],
            Description = Args[2],
            Min = Values[1],
            Max = Values[2],
            Rounding = Values[3],
            Value = Settings[Flag],
            Callback = function(self, Value)
                Settings[ Flag ] = Value
                if Callback then Callback(Value) end
            end
        })
    end

    function Plugins:Dropdown(Section, Title, List, Flag, Callback)
        return Section:Dropdown({
            Title = Title,
            Value = Settings[Flag] or Plugins.Add("None", "ไม่มี"),
            List = List,
            Callback = function(self, Value)
                Settings[Flag] = Value
                if Callback then Callback(Value) end
            end
        })
    end

    function Plugins:Textbox(Section, Args, Flag, Callback)
        return Section:Textbox({
            Title = Args[1],
            Description = Args[2],
            Value = Settings[Flag] or Plugins.Add("None", "ไม่มี"),
            Callback = function(self, Value)
                Settings[Flag] = Value
                if Callback then Callback(Value) end
            end,
        })
    end

    function Plugins:Community()
        local Community = self:MakeTab({
            Plugins.Add("Community", "ชุมชน"),
            Plugins.Add("Integration", "การเชื่อมต่อ"),
            115960025411300
        }) do
            Community:Section(Plugins.Add("Community", "ชุมชน"), function(self)
                Plugins:Paragraph(self, {
                    Plugins.Add("Welcome", "ยินดีต้อนรับ"),
                    Plugins.Add(
                        `{os.date("%d/%m/%Y")}, What would you like to do today?`,
                        `{os.date("%d/%m/%Y")}, วันนี้คุณต้องการทำอะไร?`
                    )
                }, { "Icon", 107131709546324 })

                local Members = Plugins:Paragraph(self, {
                    Plugins.Add("Members", "สมาชิก"),
                    Plugins.Add("All member in our discord.", "สมาชิกทั้งหมดใน Discord ของเรา")
                }, { "Text", "N/A" })

                Plugins:Button(self, {
                    "Discord",
                    Plugins.Add("Join our community.", "เข้าร่วมชุมชนของเรา")
                }, function()
                    pcall(Cached.setclipboard, "https://discord.gg/Q2jyDsT9yv")

                    Plugins:Notify({
                        Plugins.Add("Copy Discord", "คัดลอก Discord"),
                        Plugins.Add("Copy success.", "คัดลอกสำเร็จ"),
                        116378866141355
                    })
                end)

                task.defer(function()
                    local InviteCode = "nb6xyzwngH"
                    local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

                    local Request = request({
                        Url = DiscordAPI,
                        Method = "GET",
                        Headers = {
                            ["User-Agent"] = "WindUI/Example",
                            ["Accept"] = "application/json",
                        },
                    })

                    local Response = HttpService:JSONDecode(Request and Request.Body or "{}")

                    if Response and Response.guild then
                        local MemberCount = Response.approximate_member_count or 0
                        local OnlineCount = Response.approximate_presence_count or 0

                        Members.Text = Module:Color(tostring(OnlineCount), Color3.fromRGB(255, 255, 255)) .. " | " .. MemberCount    
                    end
                end)
            end)
        end
    end

    function Plugins:Managers()
        local Managers = self:MakeTab({
            Plugins.Add("Managers", "จัดการ"),
            Plugins.Add("Extension", "ส่วนขยาย"),
            127866486547434
        }) do
            Managers:Section(Plugins.Add("Developing", "การพัฒนา"), function(self)
                Plugins:Button(self, {
                    Plugins.Add("Copy Error", "คัดลอก Error"),
                    Plugins.Add("Copy all errors that have occurred.", "คัดลอก error ทั้งหมดที่เกิดขึ้น"),
                    "Secondary"
                }, function()
                    pcall(Cached.setclipboard, Module:TableToString(Errors))

                    Plugins:Notify({
                        Plugins.Add("Copy Error", "คัดลอก Error"),
                        Plugins.Add("Copy success.", "คัดลอกสำเร็จ"),
                        116378866141355
                    })
                end)

                Plugins:Button(self, {
                    Plugins.Add("Remove Workspace", "ลบ Workspace"),
                    Plugins.Add("Reset save setting file to default value.", "รีเซ็ตไฟล์การตั้งค่าเป็นค่าเริ่มต้น"),
                    "Danger"
                }, function()
                    local Json = Configable.Json

                    if Json and Cached.isfile(Json) then
                        pcall(Cached.delfile, Json)
                    end
                end)
            end)

            Managers:Section(Plugins.Add("Server", "เซิร์ฟเวอร์"), function(self)
                Configable:Default("JobId", JobId)

                Plugins:Textbox(self, { 
                    "JobId",
                    Plugins.Add("Put the job id.", "ใส่ job id")
                }, 'JobId')

                Plugins:Button(self, {
                    Plugins.Add("Join", "เข้าร่วม"),
                    Plugins.Add("Connect to the server using the provided JobId.", "เชื่อมต่อไปยังเซิร์ฟเวอร์ด้วย JobId ที่ระบุ"),
                }, function()
                    EachOthers:Join(Settings.JobId)
                end)

                Plugins:Button(self, {
                    Plugins.Add("Change", "เปลี่ยน"),
                    Plugins.Add("Teleport to a different public server instance.", "เทเลพอร์ตไปยังเซิร์ฟเวอร์สาธารณะอื่น"),
                    "Secondary"
                }, function()
                    task.spawn(function()
                        Plugins:Notify({
                            Plugins.Add("Server", "เซิร์ฟเวอร์"),
                            Plugins.Add("Wait for hopping.", "กรุณารอการสลับเซิร์ฟเวอร์"),
                            105706502741449
                        })

                        EachOthers:Change()
                    end)
                end)

                Plugins:Button(self, {
                    Plugins.Add("Rejoin", "เข้าร่วมใหม่"),
                    Plugins.Add("Reconnect to the current server instance.", "เชื่อมต่อกลับไปยังเซิร์ฟเวอร์ปัจจุบัน"),
                    "Secondary"
                }, function()
                    EachOthers:Rejoin()
                end)
            end)

            Managers:Section(Plugins.Add("Optimize", "ปรับแต่งประสิทธิภาพ"), function(self)
                Plugins:Toggle(self, {
                    Plugins.Add("White Screen", "หน้าจอขาว"),
                    Plugins.Add("Disabled 3D Rendering to improve performance.", "ปิดการเรนเดอร์ 3D เพื่อเพิ่มประสิทธิภาพ")
                }, "White Screen", function(value)
                    EachOthers:Set3d(value)
                end)

                Plugins:Button(self, { 
                    Plugins.Add("Fast Mode", "โหมดเร็ว"),
                    Plugins.Add("Set graphics quality to low.", "ตั้งค่าคุณภาพกราฟิกเป็นต่ำ")
                }, function()
                    EachOthers:Low()
                    Plugins:Notify({
                        Plugins.Add("Fast Mode", "โหมดเร็ว"),
                        Plugins.Add("Has been enabled.", "เปิดใช้งานแล้ว"),
                        140109651313859
                    })
                end)
            end)

            Managers:Section(Plugins.Add("Language", "ภาษา"), function(self)
                Plugins:Dropdown(self, Plugins.Add("Language", "ภาษา"), {
                    "English", "ภาษาไทย"
                },"Select Laugage", nil)

                Plugins:Button(self,{
                    Plugins.Add("Change Language", "เปลี่ยนภาษา"),
                    Plugins.Add("Apply language and rejoin server.","บันทึกภาษาและเข้าร่วมเซิร์ฟเวอร์ใหม่")
                }, function()
                    Plugins:Notify({
                        Plugins.Add("Language", "ภาษา"),
                        Plugins.Add("Applying and rejoining...","กำลังบันทึกและเข้าร่วมใหม่..."),
                        105706502741449
                    })

                    EachOthers:Rejoin()
                end)
            end)
        end
    end

    return Plugins
end)

return Module, Settings