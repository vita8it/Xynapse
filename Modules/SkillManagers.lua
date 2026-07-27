local Module, Settings, Connect = ...

local _ENV = (getgenv or getrenv or getfenv)()

local SkillManagers = {}

local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character and Character:WaitForChild('Humanoid', 10)

local Skills = PlayerGui.Main.Skills

local CurrentTool = nil

local LastSkillUse = 0
local LastSimple = 0

local IsReloading = false
local OnFirstTime = true

local function GetEnabledSkills()
    return {
        ['Melee'] = Settings['Melee'] or { "Z", "X", "C" },
        ['Sword'] = Settings['Sword'] or { "Z", "X" },
        ['Gun'] = Settings['Gun'] or { "Z", "X" },
        ['Blox Fruit'] = Settings['Blox Fruit'] or { "Z", "X", "C" }
    }
end

local function GetEnabledList(ToolName)
    local Tool = Backpack:FindFirstChild(ToolName) or Character:FindFirstChild(ToolName)

    return Tool and GetEnabledSkills()[Tool.ToolTip] or {}
end

local function IsToolValid(ToolFrame)
    if not ToolFrame or not ToolFrame:IsA("Frame") then return false end

    local Tool = Backpack:FindFirstChild(ToolFrame.Name) or Character:FindFirstChild(ToolFrame.Name)

    if not Tool then return false end

    local EnabledList = GetEnabledSkills()[Tool.ToolTip]

    return EnabledList and #EnabledList > 0
end

local function IsSkillUnlocked(Skill)
    local Title = Skill:FindFirstChild("Title")

    return Title and Title.TextColor3 == Color3.fromRGB(255, 255, 255)
end

local function IsSkillOnCooldown(Skill)
    local Cooldown = Skill:FindFirstChild("Cooldown")

    return Cooldown and Cooldown.Size.X.Scale > 0
end

local function IsSkillReady(Skill, ToolName)
    return table.find(GetEnabledList(ToolName), Skill.Name) and IsSkillUnlocked(Skill) and not IsSkillOnCooldown(Skill)
end

local function FindReadySkill(ToolContainer, ToolName)
    for _, Skill in ToolContainer:GetChildren() do
        if not Skill:IsA("Frame") or Skill.Name == "Template" then continue end

        if IsSkillReady(Skill, ToolName) then
            return Skill.Name
        end
    end
end

local function FindLowestCooldownSkill(ToolContainer, ToolName)
    local SelectedSkill, LowestCooldown = nil, math.huge
    local EnabledList = GetEnabledList(ToolName)

    for _, Skill in ToolContainer:GetChildren() do
        if not Skill:IsA("Frame") or Skill.Name == "Template" then continue end

        if not IsSkillUnlocked(Skill) or not table.find(EnabledList, Skill.Name) then continue end

        local Cooldown = Skill:FindFirstChild("Cooldown")

        if not Cooldown or Cooldown.Size.X.Scale >= LowestCooldown then continue end

        LowestCooldown, SelectedSkill = Cooldown.Size.X.Scale, Skill.Name
    end

    return SelectedSkill
end

local function GetBestSkill(CurrentToolName)
    if CurrentToolName then
        local ToolContainer = Skills:FindFirstChild(CurrentToolName)

        if ToolContainer and IsToolValid(ToolContainer) then
            local SkillName = FindReadySkill(ToolContainer, CurrentToolName)

            if SkillName then
                return CurrentToolName, SkillName
            end
        end
    end

    local BestTool, BestSkill, LowestCooldown = nil, nil, math.huge

    for _, Tool in Skills:GetChildren() do
        if not Tool:IsA("Frame") or Tool.Name == "Container" then continue end

        if not IsToolValid(Tool) then continue end

        if Tool.Name == CurrentToolName then continue end

        local SkillName = FindReadySkill(Tool, Tool.Name)

        if SkillName then return Tool.Name, SkillName end

        local LowestSkill = FindLowestCooldownSkill(Tool, Tool.Name)

        if not LowestSkill then continue end

        local SkillFrame = Tool:FindFirstChild(LowestSkill)
        local Cooldown = SkillFrame and SkillFrame:FindFirstChild("Cooldown")

        if not Cooldown or Cooldown.Size.X.Scale >= LowestCooldown then continue end

        LowestCooldown, BestTool, BestSkill = Cooldown.Size.X.Scale, Tool.Name, LowestSkill
    end

    if not BestTool and CurrentToolName then
        local ToolContainer = Skills:FindFirstChild(CurrentToolName)

        if ToolContainer and IsToolValid(ToolContainer) then
            local LowestSkill = FindLowestCooldownSkill(ToolContainer, CurrentToolName)

            if LowestSkill then
                return CurrentToolName, LowestSkill
            end
        end
    end

    return BestTool, BestSkill
end

local function EquipTool(ToolName)
    if not Module:IsAlive() then return false end

    local Tool = Backpack:FindFirstChild(ToolName)

    if not Tool then return false end

    if Tool:GetAttribute("Locks") then
        Tool:SetAttribute("Locks", nil)
    end

    if not Character:FindFirstChild(ToolName) then
        Humanoid:EquipTool(Tool)

        local Timeout = tick() + 1

        while not Character:FindFirstChild(ToolName) and tick() < Timeout do
            task.wait()
        end
    end

    return Character:FindFirstChild(ToolName) ~= nil
end

local function GetUnCooldownSkill(Name, Select)
    local ToolContainer = Skills:FindFirstChild(Name)
    if not ToolContainer then return nil end

    for _, KeyName in ipairs(Select) do
        local Skill = ToolContainer:FindFirstChild(KeyName)
        
        if not Skill or not Skill:IsA("Frame") then continue end
        
        if not IsSkillUnlocked(Skill) then continue end
        
        if IsSkillOnCooldown(Skill) then continue end

        return KeyName
    end

    return nil
end

local function OnToolAdded(Tool)
    if not Tool:IsA("Tool") then return end

    local EnabledSkills = GetEnabledSkills()

    if not EnabledSkills[Tool.ToolTip] then return end

    if Skills:FindFirstChild(Tool.Name) then return end

    IsReloading = true

    task.wait(0.5)

    Humanoid:UnequipTools()

    CurrentTool = nil

    Module:Equip(Tool.ToolTip, true)

    Humanoid:UnequipTools()

    IsReloading = false
end

local function BindBackpack()
    if _ENV.Reload then _ENV.Reload:Disconnect() end
    _ENV.Reload = Connect(Backpack.ChildAdded, OnToolAdded)
end

function SkillManagers:Use()
    if not Character then return end

    if OnFirstTime then
        OnFirstTime = false do
            return Module:EquipTool("Melee", true)
        end
    end

    if IsReloading then return end
    if tick() - LastSkillUse < 0.2 then return end

    local ToolName, SkillName = GetBestSkill(CurrentTool)

    if not ToolName or not SkillName then return end

    if CurrentTool ~= ToolName then
        if not EquipTool(ToolName) then
            Humanoid:UnequipTools()
            task.wait(0.25)

            for _, ToolType in pairs({"Melee", "Sword", "Gun", "Blox Fruit"}) do
                Module:Equip(ToolType, true)
                task.wait(0.15)
            end

            return
        end

        CurrentTool = ToolName
        task.wait(0.15)
    end

    if not Character:FindFirstChild(ToolName) then
        CurrentTool = nil
        return
    end

    LastSkillUse = tick()

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[SkillName], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[SkillName], false, game)
end

function SkillManagers:Skill(Select)
    if not Character then return end

    if not Select or #Select == 0 then return end

    if tick() - LastSimple < 0.2 then return end

    local Equipped = Character:FindFirstChildOfClass("Tool")

    if not Equipped then return end

    local Skill = GetUnCooldownSkill(Equipped.Name, Select)

    if not Skill then return end

    LastSimple = tick()

    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[Skill], false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[Skill], false, game)
end

task.spawn(BindBackpack) do
    Connect(Player.CharacterAdded, function(NewCharacter)
        Character = NewCharacter

        Humanoid = NewCharacter:WaitForChild("Humanoid", 10)
        Backpack = Player:FindFirstChildOfClass('Backpack')

        CurrentTool = nil
        IsReloading = false

        BindBackpack()
    end)
end

return SkillManagers
