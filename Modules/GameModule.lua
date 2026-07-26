local Packages, Settings = ...

const _ENV = (getgenv or getrenv or getfenv)()

local Module, Cache = {}, {}

local Connectors = Packages.Connectors
local Importer = Packages.Importer

local Connect = Connectors.Connect

function NewModule(Name, Function)
    do Module[Name] = Function(Module)
        return Module[Name]
    end
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService('Lighting')
local Players = game:GetService("Players")
local CoreGui = game:GetService('CoreGui')

local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local ChestModels = workspace:WaitForChild("ChestModels")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")
local NPCs = workspace:WaitForChild('NPCs')
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild("CommE")

local Player = Players.LocalPlayer

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped

local KeyboardEnabled = UserInputService.KeyboardEnabled
local TouchEnabled = UserInputService.TouchEnabled

local ServerOwnerId = ReplicatedStorage:FindFirstChild("PrivateServerOwnerId")
local IsPrivateServer = ServerOwnerId and ServerOwnerId.Value ~= 0 or true

const KILLAURA_TAG = _ENV.TAGS_KILLABLE or tostring(math.random(120, 2e4))
const BRING_TAG = _ENV.TAGS_BRINGABLE or tostring(math.random(80, 2e4))

const HIDDEN_SETTINGS = {} do
    _ENV.TAGS_KILLABLE = KILLAURA_TAG
    _ENV.TAGS_BRINGABLE = BRING_TAG
end

local function GetEnemyName(strings)
    return (strings:find("Lv. ") and strings:gsub(" %pLv. %d+%p", "") or strings):gsub(" %pBoss%p", "")
end

local function CreateDictionary(Array, Value)
    local Dictionary = {}

    for _, strings in Array do
        Dictionary[ strings ] = type(Value) == "table" and {} or Value
    end

    return Dictionary
end

local function ValidData(Filter, Enemy)
    if Filter == nil then return true end

    if type(Filter) == "table" then
        return table.find(Filter, Enemy.Name) ~= nil
    end

    if type(Filter) == "string" then
        return Enemy.Name == Filter
    end

    return false
end

Module.PirateRaid = 0 do
    Module.IsSuperBring = false

    Module.EnemyLocations = {}
    Module.SpawnLocations = {}

    Module.IsPrivateService = IsPrivateServer
    Module.IsMobile = TouchEnabled and not KeyboardEnabled and true or false

    Module.SeaName = { "Main", "Dressrosa", "Zou" }
    Module.Sea = tonumber(workspace:GetAttribute("MAP"):match("^Sea(%d+)$") ) or 1
end

NewModule("RaidList", function()
    local Success, RaidModule = pcall(require, ReplicatedStorage:WaitForChild("Raids"))

    if not Success or type(RaidModule) ~= "table" then
        return {
            "Phoenix", "Dough", "Flame", "Ice", "Quake", "Light",
            "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand",
        }
    end

    local AdvancedRaids = RaidModule.advancedRaids or {}
    local NormalRaids = RaidModule.raids or {}

    local RaidList = {}

    for i = 1, #AdvancedRaids do table.insert(RaidList, AdvancedRaids[i]) end
    for i = 1, #NormalRaids do table.insert(RaidList, NormalRaids[i]) end

    return RaidList
end)

NewModule("GoodSignal", function()
    local Signal = {}
    local Connection = {}

    Connection.__index = Connection
    Signal.__index = Signal

    function Connection:Disconnect()
        if not self.Connected then
            return
        end

        local find = table.find(self.Signal._connections, self)

        if find then
            table.remove(self.Signal._connections, find)
        end

        self.Function = nil
        self.Connected = false
    end

    function Connection:Fire(...)
        if self.Function then
            task.spawn(self.Function, ...)
        end
    end

    function Signal.new()
        return setmetatable({
            _connections = {}
        }, Signal)
    end

    function Signal:Connect(fn)
        local connection = setmetatable({
            Signal = self,
            Function = fn,
            Connected = true
        }, Connection)

        table.insert(self._connections, connection)
        return connection
    end

    function Signal:Fire(...)
        for _, connection in ipairs(self._connections) do
            connection:Fire(...)
        end
    end

    return Signal
end)

NewModule("HumanoidManager", function()
    local HumanoidManager = {}

    HumanoidManager.HumanoidsCache = (function()
        local HumanoidsCache = {} do
            HIDDEN_SETTINGS.COUNT_NEWINDEX = 0
            HIDDEN_SETTINGS.MAX_NEWINDEX = 50
        end

        HumanoidsCache.__newindex = function(self, Index, Value)
            if HIDDEN_SETTINGS.COUNT_NEWINDEX >= HIDDEN_SETTINGS.MAX_NEWINDEX then
                for Index, Cache in pairs(self) do
                    if typeof(Cache) ~= 'Instance' then
                        continue
                    end

                    if not Cache:IsDescendantOf(game) then
                        rawset(self, Index, nil)
                    end
                end

                HIDDEN_SETTINGS.COUNT_NEWINDEX = 0
            end

            HIDDEN_SETTINGS.COUNT_NEWINDEX += 1
            return rawset(self, Index, Value)
        end

        HumanoidsCache.__index = function(self, Character)
            local Property = Character.Parent == SeaBeasts and "Health" or "Humanoid"
            local Humanoid = Character:FindFirstChild(Property)

            if Humanoid then
                rawset(self, Character, Humanoid)
            end

            return Humanoid
        end

        return setmetatable({}, HumanoidsCache)
    end)()

    function HumanoidManager:GetHumanoidHealth(Humanoid)
        return Humanoid[ Humanoid.ClassName == "Humanoid" and "Health" or "Value" ]
    end

    function Module:IsAlive(Character)
        Character = Character or Player.Character

        local Humanoid = HumanoidManager.HumanoidsCache[ Character ]

        if Humanoid then
            return HumanoidManager:GetHumanoidHealth(Humanoid) > 0
        end

        return Character.Parent == Boats
    end

    function Module:IsAlly(Target)
        if Target.Parent == Characters then
            Target = Players:GetPlayerFromCharacter(Target)
        end

        if not Target then return false end

        if tostring(Target.Team) == "Marines" and Target.Team == Player.Team then
            return false
        elseif Target:HasTag(`Ally{Player.Name}`) or Player:HasTag(`Ally{Target.Name}`) then
            return false
        end

        return true
    end

    return HumanoidManager
end)

NewModule("CalculateManager", function()
    local Calculates = {}

    Calculates.Handlers = (function()
        local Handlers = {}

        Handlers.CFrame = function(Coordinate)
            return Coordinate.Position
        end

        Handlers.Vector3 = function(Position)
            return Position
        end

        Handlers.Instance = function(Object)
            if Object:IsA("Model") then
                return Object:GetPivot().Position
            elseif Object:IsA("BasePart") then
                return Object.Position
            elseif Object:IsA("Attachment") then
                return Object.WorldPosition
            end

            error(("Unsupported instance type: %s"):format(Object.ClassName))
        end

        return Handlers
    end)()

    Calculates.Positions = setmetatable({}, {
        __index = function(self, Value)
            local Type = typeof(Value)
            local Handler = Calculates.Handlers[ Type ]

            assert(Handler, ("Unsupported type: %s"):format(Type))

            return Handler(Value)
        end,
    })

    function Module:ToDistance(Value)
        Value = Calculates.Positions[ Value ]
        return Player:DistanceFromCharacter(Value)
    end

    function Module:ToUnit(Value)
        local Character = Player.Character

        if not Character then return end

        local Current = Character:GetPivot().Position
        local Result = Calculates.Positions[ Value ]

        return (Result - Current).Unit
    end
end)

NewModule("NetworkManager", function()
    local NetworkManager = {}

    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local Modules = ReplicatedStorage:WaitForChild("Modules")

    local Net = require(Modules:WaitForChild("Net"))

    local CommF = Remotes:WaitForChild("CommF_")
    local CommE = Remotes:WaitForChild("CommE")

    function Module:Send(IsEvent, Name, ...)
        local Remote = Cache[Name]

        if not Remote then
            if IsEvent then
                Remote = Net:RemoteEvent(Name)
            else
                Remote = Net:RemoteFunction(Name)
            end

            Cache[Name] = Remote
        end

        if IsEvent then
            return Remote:FireServer(...)
        end

        return Remote:InvokeServer(...)
    end

    function Module:ComF(...)
        return CommF:InvokeServer(...)
    end

    function Module:ComE(...)
        return CommE:FireServer(...)
    end

    return NetworkManager
end)

NewModule("FastAttack", function()
    local FastAttack = {} do
        FastAttack.Cooldown = 0.5
        FastAttack.Distance = 50

        FastAttack.ThreadId = (function()
            local UserId = tostring(Player.UserId)
            local Coroutine = tostring( coroutine.running() )

            return `{UserId:sub(2, 4)}{Coroutine:sub(11, 15)}`
        end)()

        FastAttack.Guns = Importer('Modules/GunManagers')()
    end

    local CurrentBladeHits = {} do
        Module.Closest = nil
        Module.LocalPosition = nil 
    end

    local HitboxLimbs = {
        "RightLowerArm", "RightUpperArm", "LeftLowerArm",
        "LeftUpperArm", "RightHand", "LeftHand"
    }

    function FastAttack:GetRandomHitboxLimb(Character)
        return Character:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)])
    end

    function FastAttack:ProcessHits(Folder, Distance)
        local Character = Player.Character
        local Targets = Folder:GetChildren()

        for i = 1, #Targets do
            local Enemy = Targets[i]

            if Enemy == Character then continue end

            if not Module:IsAlive(Enemy) then continue end

            if Enemy:GetAttribute("IsBoat") then continue end

            local PrimaryPart = Enemy.PrimaryPart
            local IsAlly = Enemy.Parent ~= Characters or Module:IsAlly(Enemy)

            if PrimaryPart and IsAlly then
                local Hitbox = self:GetRandomHitboxLimb(Enemy) or PrimaryPart

                if Hitbox and Module:ToDistance(PrimaryPart.Position) <= Distance then
                    table.insert(CurrentBladeHits, { Enemy, Hitbox })
                end
            end
        end
    end

    function FastAttack:UpdateBladeHits(Distance)
        Distance = Distance or self.Distance
        CurrentBladeHits = {}

        self:ProcessHits(Enemies, Distance)
        self:ProcessHits(Characters, Distance)

        return true
    end

    function FastAttack:GetClosest(Distance)
        Distance = Distance or self.Distance

        local Distance, Closest = math.huge, nil

        for i = 1, #CurrentBladeHits do
            local Enemy = CurrentBladeHits[i]

            local Position = Enemy[2].Position
            local Absolute = Closest and (Closest.Position - Position)
            local Magnitude = Absolute and Absolute.Magnitude or Distance

            if Magnitude <= Distance then
                Distance, Closest = Magnitude, Enemy[2]
            end
        end

        Module.Closest = Closest
        return Closest
    end

    function FastAttack:SendHits(Closest, Targets)
        Module:Send(true, "RegisterAttack", 0.5)

        if self.HIT_FUNCTION then
            self.HIT_FUNCTION(Closest, Targets, nil, self.ThreadId)
        else
            Module:Send(true, "RegisterHit", Closest, Targets, nil, self.ThreadId)
        end
    end

    function FastAttack:SendSlash(Equipped, Closest)
        local LeftClick = Equipped:FindFirstChild("LeftClickRemote")

        if not LeftClick then return end

        LeftClick:FireServer(false)
        LeftClick:FireServer(Module:ToUnit(Closest), 2)
    end

    Connect(Stepped, function()
        local self = FastAttack

        if not Settings['Fast Attack'] then return end
        if not Module:IsAlive() then return end

        local Character = Player.Character
        if not Character then return end

        local Equipped = Character and Character:FindFirstChildOfClass("Tool")
        if not Equipped then return end

        Module.LocalPosition = Character:GetPivot().Position

        local ToolTip = Equipped.ToolTip
        local Name = Equipped.Name

        if ToolTip == 'Gun' then 
            return self.Guns:FireTarget(Equipped, Character)
        end

        self:UpdateBladeHits()

        local Closest = self:GetClosest()
        if not Closest then return end

        if Name == 'Ice-Ice' or Name == 'Light-Light' then
            return self:SendHits(Closest, CurrentBladeHits)
        elseif ToolTip == 'Blox Fruit' then
            return self:SendSlash(Equipped, Closest)
        else
            self:SendHits(Closest, CurrentBladeHits)
        end
    end)

    task.defer(pcall, function()
        assert(getsenv, "getsenv is unavailable.")

        local PlayerScripts = Player.PlayerScripts
        local LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")

        while not LocalScript do
            PlayerScripts.ChildAdded:Wait()
            LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")
        end

        local Success, Environtment = pcall(getsenv, LocalScript)

        if Success and Environtment then
            if Environtment._G.SendHitsToServer then
                FastAttack.HIT_FUNCTION = Environtment._G.SendHitsToServer
            end
        end
    end)

    return FastAttack
end)

NewModule("DataManagers", function()
    local DataManagers = {} do
        DataManagers.FruitsId = Importer('Modules/FruitsModule')() 
    end

    local function NewData(Instancer)
        if not Instancer.ClassName:find('Value') then
            return false
        end
        
        local Name = Instancer.Name

        if not DataManagers[Name] then
            DataManagers[Name] = Instancer.Value

            Connect(Instancer:GetPropertyChangedSignal('Value'), function()
                DataManagers[Name] = Instancer.Value
            end)
        end
    end

    for _, Instance in Player.Data:GetChildren() do NewData(Instance) end
    Connect(Player.Data.ChildAdded, NewData)

    return DataManagers
end)

NewModule("InventoryModule", function()
    local InventoryModule = {} do
        InventoryModule.Requirements = {}
        InventoryModule.Unlocked = {}
        InventoryModule.Mastery = {}
        InventoryModule.Items = {}
        InventoryModule.Count = {}
    end
    
    function InventoryModule:HasFruit(Container)
        if not Container then return false end
        
        local Objects = Container:GetChildren()
        
        for i = 1, #Objects do
            local Object = Objects[i]
            
            if Object.Name:find("Fruit") then
                return true
            end
        end
    end

    function InventoryModule:HaveFruit(Character, Backpack)
        Character = Character or Player.Character
        Backpack = Backpack or Player:FindFirstChildOfClass("Backpack")

        return self:HasFruit(Character) or self:HasFruit(Backpack)
    end

    function InventoryModule:GetFruits(IsHigh)
        local Collects, Threshold = {}, 999999
        local Fruits = Module:ComF("GetFruits")
        
        for i = 1, #Fruits do
            local Fruit = Fruits[i]
            
            local Price = Fruit.Price or 0
            local Name = Fruit.Name or "Unknow"
            
            if (Price >= Threshold) == IsHigh then
                Collects[ Name ] = Price
            end
        end

        return Collects
    end 

    function InventoryModule:GetFruit(IsHigh)
        local Target, Lowest = nil, math.huge
        local Fruits = self:GetFruits(IsHigh)

        for _, Item in Module:ComF("getInventory") do
            local Value = Item.Type == "Blox Fruit" and Fruits[ Item.Name ]

            if Value and Value < Lowest then
                Lowest, Target = Value, Item.Name
            end
        end

        return Target
    end

    function InventoryModule:LoadFruit(IsHigh)
        if self:HaveFruit() then return  end

        local Fruit = self:GetFruit(IsHigh)
        if not Fruit then return end

        return Module:ComF("LoadFruit", Fruit)
    end

    function InventoryModule:UpdateItem(Item)
        if type(Item) == "table" then
            if Item.Type == "Wear" then
                Item.Type = "Accessory"
            end

            local Name = Item.Name do
                self.Items[Name] = Item
            end

            if not self.Unlocked[Name] then
                self.Unlocked[Name] = true
            end
            
            if Item.Count then
                self.Count[Name] = Item.Count
            end
            
            if Item.Mastery then
                self.Mastery[Name] = Item.Mastery
            end
            
            if Item.MasteryRequirements then
                self.Requirements[Name] = Item.MasteryRequirements
            end
        end
    end

    function InventoryModule:RemoveItem(ItemName)
        if type(ItemName) == "string" then
            self.Unlocked[ItemName] = nil
            self.Mastery[ItemName] = nil
            self.Count[ItemName] = nil
            self.Items[ItemName] = nil
        end
    end

    local function OnClientEvent(Method, ...)
        if Method == "ItemChanged" then
            InventoryModule:UpdateItem(...)
        elseif Method == "ItemAdded" then
            InventoryModule:UpdateItem(...)
        elseif Method == "ItemRemoved" then
            InventoryModule:RemoveItem(...)
        end
    end

    task.spawn(function()
        Connect(CommE.OnClientEvent, OnClientEvent)

        local InventoryItems = nil

        repeat
            task.wait(1)
            InventoryItems = Module:ComF("getInventory")
        until type(InventoryItems) == "table"

        for index = 1, #InventoryItems do
            InventoryModule:UpdateItem(InventoryItems[index])
        end
    end)

    return InventoryModule
end)

NewModule("QuestManager", function()
    local DataManagers = Module.DataManagers

    local QuestManager = {} do
        QuestManager.Blacklist = { "BartiloQuest", "MarineQuest", "CitizenQuest", "ImpelQuest" }
        QuestManager.GuideModule = require(ReplicatedStorage:WaitForChild('GuideModule'))
        QuestManager.Quests = require(ReplicatedStorage:WaitForChild('Quests')) 
    end

    function QuestManager:Pack(Data, Levels)
        return Data[ tostring(math.max(unpack(Levels))) ]
    end

    function QuestManager:GetMonster(CurrentLevel)
        local Data, Levels = {}, {}
        local Maximum = ({ {0, 700}, {700, 1500}, {1500, math.huge} })[ Module.Sea ]

        for Name, Task in self.Quests do
            if table.find(self.Blacklist, Name) then continue end

            for Number, Mission in Task do
                local Level = Mission.LevelReq
                local Monster, Value = next(Mission.Task)

                if Level >= Maximum[1] and Level < Maximum[2] and CurrentLevel >= Level and Value > 1 then
                    table.insert(Levels, Level)

                    Data[ tostring(Level) ] = {
                        Name = Mission.Name,
                        Level = Number,
                        Monster = Monster,
                    }
                end
            end
        end

        if #Levels == 0 then return nil end

        return self:Pack(Data, Levels)
    end

    function QuestManager:NPCsData(CurrentLevel)
        local Data, Levels = {}, {}

        for _, Npcs in self.GuideModule[ Module.Sea ] do
            if not Npcs.InternalQuestName then continue end

            if not table.find(self.Blacklist, Npcs.InternalQuestName) then
                local Level = Npcs.Levels[1]

                if CurrentLevel >= Level then
                    table.insert(Levels, Level)
                    Data[ tostring(Level) ] = {
                        Position = Npcs.Position,
                        Quest = Npcs.InternalQuestName,
                    }
                end 
            end
        end

        if #Levels == 0 then return nil end

        return self:Pack(Data, Levels)
    end

    function QuestManager:GetQuest()
        local Level = DataManagers.Level

        if Level == 1 and Level <= 9 then
            if tostring(Player.Team) == "Marines" then
                return {
                    Name = "Trainees",
                    Monster = "Trainee",
                    Level = 1,
                    Quest = "MarineQuest",
                    Position = CFrame.new(-2711, 24, 2104),
                }
            elseif tostring(Player.Team) == "Pirates" then
                return {
                    Name = "Bandits",
                    Monster = "Bandit",
                    Level = 1,
                    Quest = "BanditQuest1",
                    Position = CFrame.new(1059, 15, 1550),
                }
            end
        else
            local Data = self:GetMonster(Level)
            if not Data then return end

            local NPCsData = self:NPCsData(Level)
            if not NPCsData then return end

            Data.Quest = NPCsData.Quest
            Data.Position = CFrame.new(NPCsData.Position)

            return Data
        end
    end

    return QuestManager
end)

NewModule("EnemiesModule", function()
    local EnemiesModule = CreateDictionary({
        "__CakePrince", "__PirateRaid", "__RaidBoss", "__TyrantSkies", "__Bones", "__Elite", "__Others", 
    }, {})

    local SeaCastle = CFrame.new(-5556, 314, -2988) do
        Cache.Enemies = {}
        Cache.Bring =  {}
    end

    local TagsMobs = {
        __Elite = CreateDictionary({ "Deandre", "Diablo", "Urban", "Tyrant of the skies" }, true),
        __Bones = CreateDictionary({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }, true),
        __CakePrince = CreateDictionary({ "Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter" }, true),
        __TyrantSkies = CreateDictionary({ "Sun-kissed Warrior", "Skull Slayer", "Isle Champion", "Serpent Hunter" }, true)
    }

    local Attachment = Instance.new("Attachment") do
        local AlignPosition = Instance.new("AlignPosition")
        AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        AlignPosition.Position = Vector3.new(0, 20, 0)
        AlignPosition.Responsiveness = 200
        AlignPosition.MaxForce = math.huge
        AlignPosition.Parent = Attachment
        AlignPosition.Attachment0 = Attachment
    end

    local function New(list, NewEnemy)
        if table.find(list, NewEnemy) then return end

        local Humanoid = NewEnemy:WaitForChild("Humanoid")

        if Humanoid and Humanoid.Health > 0 then
            table.insert(list, NewEnemy)
            Humanoid.Died:Wait()
            local index = table.find(list, NewEnemy)
            if index then table.remove(list, index) end
        end
    end

    local function IsFromPiratesSea(Enemy)
        if not Enemy:WaitForChild("Humanoid") or Enemy.Humanoid.Health <= 0 then return end

        local HumanoidRootPart = Enemy:WaitForChild("HumanoidRootPart")

        if HumanoidRootPart and (Enemy.Name ~= "rip_indra True Form" and Enemy.Name ~= "Blank Buddy") then
            if (HumanoidRootPart.Position - SeaCastle.Position).Magnitude <= 750 then
                task.spawn(New, EnemiesModule.__PirateRaid, Enemy)
                Module.PirateRaid = tick()
            end
        end
    end

    local function NewEnemyAdded(Enemy)
        local EnemyName = Enemy.Name
        local Others = EnemiesModule.__Others

        Others[EnemyName] = Others[EnemyName] or {}
        task.spawn(New, Others[EnemyName], Enemy)

        if Module.Sea == 3 then
            task.spawn(IsFromPiratesSea, Enemy)
        end

        if Enemy:GetAttribute("RaidBoss") then
            task.spawn(New, EnemiesModule.__RaidBoss, Enemy)
        elseif EnemiesModule["__" .. EnemyName] then
            task.spawn(New, EnemiesModule["__" .. EnemyName], Enemy)
        else
            for Tag, Mobs in pairs(TagsMobs) do
                if Mobs[EnemyName] then
                    task.spawn(New, EnemiesModule[Tag], Enemy)
                    break
                end
            end
        end
    end

    function EnemiesModule:IsSpawned(EnemyName)
        local Cached = Module.SpawnLocations[EnemyName]

        if Cached and Cached.Parent then
            return (Cached:GetAttribute("Active") or EnemiesModule:GetEnemyByTag(EnemyName)) and true or false
        end

        return EnemiesModule:GetEnemyByTag(EnemyName) and true or false
    end

    function EnemiesModule:GetTagged(TagName)
        return self["__" .. TagName] or self.__Others[TagName]
    end

    function EnemiesModule:GetEnemyByTag(TagName)
        local CachedEnemy = Cache.Enemies[TagName]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Enemies = self:GetTagged(TagName)

        if Enemies and #Enemies > 0 then
            for i = 1, #Enemies do
                local Enemy = Enemies[i]

                if Module:IsAlive(Enemy) then
                    Cached.Enemies[TagName] = Enemy
                    return Enemy
                end
            end
        end
    end

    function EnemiesModule:GetClosest(Enemies)
        local SpecialTag = table.concat(Enemies, ".")
        local CachedEnemy = Cache.Enemies[SpecialTag]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Distance, Nearest = math.huge, nil

        for i = 1, #Enemies do
            local Enemy = self:GetClosestByTag(Enemies[i])
            local Magnitude = Enemy and Module:ToDistance(Enemy)

            if Enemy and Magnitude <= Distance then
                Distance, Nearest = Magnitude, Enemy
            end
        end

        if Nearest then
            Cache.Enemies[SpecialTag] = Nearest
            return Nearest
        end
    end

    function EnemiesModule:GetClosestByTag(TagName)
        local CachedEnemy = Cache.Enemies[TagName]

        if CachedEnemy and Module:IsAlive(CachedEnemy) then
            return CachedEnemy
        end

        local Enemies = self:GetTagged(TagName)

        if Enemies and #Enemies > 0 then
            local Distance, Nearest = math.huge, nil

            for i = 1, #Enemies do
                local Enemy = Enemies[i]
                local PrimaryPart = Enemy.PrimaryPart

                if PrimaryPart and Module:IsAlive(Enemy) then
                    local Magnitude = Module:ToDistance(PrimaryPart)

                    if Magnitude <= 15 then
                        Cache.Enemies[TagName] = Enemy
                        return Enemy
                    elseif Magnitude <= Distance then
                        Distance, Nearest = Magnitude, Enemy
                    end
                end
            end

            if Nearest then
                Cache.Enemies[TagName] = Nearest
                return Nearest
            end
        end
    end

    function EnemiesModule:GetEnemies(Range, Name)
        local Nearest, Distance = nil, math.huge
        local EnemiesList = Enemies:GetChildren()

        for i = 1, #EnemiesList do
            local Enemy = EnemiesList[i]

            if not Enemy.PrimaryPart then continue end
            if not ValidData(Name, Enemy) then continue end

            if Module:IsAlive(Enemy) then
                local Magnitude = Module:ToDistance(Enemy)

                if Enemy and (not Range or Magnitude < Range) and Magnitude < Distance then
                    Distance, Nearest = Magnitude, Enemy
                end
            end
        end

        return Nearest
    end

    local function Bring(Enemy)
        local RootPart = Enemy:WaitForChild("HumanoidRootPart")
        local Humanoid = Enemy:WaitForChild("Humanoid")
        local EnemyName = Enemy.Name

        local CloneAttachment = Attachment:Clone()
        local AlignPosition = CloneAttachment.AlignPosition
        CloneAttachment.Parent = RootPart

        while Enemy and Enemy.Parent == Enemies and Enemy:HasTag(BRING_TAG) do
            if not Humanoid or Humanoid.Health <= 0 then break end
            if not RootPart or RootPart.Parent ~= Enemy then break end

            local Target = Cache.Bring[ Module.IsSuperBring and "ALL_MOBS" or EnemyName ]

            if Target and (Target.Position - RootPart.Position).Magnitude <= Settings["Bring Distance"] then
                if AlignPosition.Position ~= Target.Position then
                    AlignPosition.Position = Target.Position
                end
            else
                break
            end;task.wait()
        end

        if Enemy and Enemy:HasTag(BRING_TAG) then Enemy:RemoveTag(BRING_TAG) end
        if CloneAttachment then CloneAttachment:Destroy() end
    end

    local function KillAura(Enemy)
        local Humanoid = Enemy:FindFirstChild("Humanoid")
        local RootPart = Enemy:FindFirstChild("HumanoidRootPart")

        pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)

        if Humanoid and RootPart then
            RootPart.CanCollide = false
            RootPart.Size = Vector3.new(60, 60, 60)
            Humanoid:ChangeState(15)
            Humanoid.Health = 0
            task.wait()
            Enemy:RemoveTag(KILLAURA_TAG)
        end
    end

    for _, Enemy in CollectionService:GetTagged("BasicMob") do NewEnemyAdded(Enemy) end
    Connect(CollectionService:GetInstanceAddedSignal("BasicMob"), NewEnemyAdded)
    Connect(CollectionService:GetInstanceAddedSignal(KILLAURA_TAG), KillAura)
    Connect(CollectionService:GetInstanceAddedSignal(BRING_TAG), Bring)

    return EnemiesModule
end)

return Module
