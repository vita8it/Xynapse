# Skilled.md

## Roblox LuaU Coding Style Guide

### Language
- **Language:** Roblox LuaU
- Write clean, readable, and maintainable code.
- Prioritize performance without sacrificing readability.

---

# Naming Convention

## PascalCase

Use **PascalCase** for:

- Variables
- Parameters
- Functions
- Classes
- Modules

### Example

```lua
local PlayerData = {}
local Character = Player.Character

local function GetPlayerData(Player)
    return PlayerData[Player]
end

local function CreateWeapon(WeaponName)
    -- Code
end
```

---

## UPPER_CASE

Use **UPPER_CASE** for constants that never change.

### Example

```lua
local MAX_DISTANCE = 100
local DEFAULT_SPEED = 16
local UPDATE_INTERVAL = 0.1
```

---

# Loop Style

## Generic Loop

Use descriptive variable names.

Preferred:

```lua
for Index, Value in Table do
    if not Value then
        continue
    end

    -- Code
end
```

Avoid:

```lua
for i, v in Table do
end
```

unless the meaning is obvious.

---

## Numeric Loop (Performance)

For arrays returned from Roblox APIs such as:

- `GetChildren()`
- `GetDescendants()`
- `GetPlayers()`

Prefer caching the array and using a numeric loop.

Good:

```lua
local Objects = Folder:GetDescendants()

for Index = 1, #Objects do
    local Object = Objects[Index]

    -- Code
end
```

Avoid:

```lua
for _, Object in Folder:GetDescendants() do
end
```

This avoids repeatedly creating iterators and is preferred for large collections.

---

# Continue Style

Prefer `continue` over unnecessary nesting.

Good:

```lua
for Index, Value in Table do
    if not Value then
        continue
    end

    print(Value)
end
```

Avoid:

```lua
for Index, Value in Table do
    if Value then
        print(Value)
    end
end
```

---

# Early Return

Prefer early returns to reduce indentation.

Good:

```lua
local function EquipTool(Player)
    if not Player.Character then
        return
    end

    -- Code
end
```

Avoid:

```lua
local function EquipTool(Player)
    if Player.Character then
        -- Code
    end
end
```

---

# Cache Style

When writing search functions (`Get...`, `Find...`, `Locate...`) that are called frequently, cache the result before searching again.

Good:

```lua
local Cache = {}

local function GetClosestPart()
    if Cache.ClosestPart and Cache.ClosestPart:IsDescendantOf(Folder) then
        return Cache.ClosestPart
    end

    Cache.ClosestPart = nil

    local Parts = Folder:GetChildren()

    for Index = 1, #Parts do
        local Part = Parts[Index]

        Cache.ClosestPart = Part
        return Part
    end
end
```

Rules:

- Check cache first.
- Validate cached instances.
- Only search when cache is invalid.
- Store the result back into cache.

---

# Expression Style

Avoid chaining multiple operations into a single line whenever readability can be improved.

Avoid:

```lua
local Distance = (Part.Position - Origin.Position).Magnitude
```

Preferred:

```lua
local Absolute = Part.Position - Origin.Position
local Magnitude = Absolute.Magnitude
```

Another example:

```lua
local Character = Player.Character

if not Character then
    return
end

local RootPart = Character.PrimaryPart

if not RootPart then
    return
end

local Position = RootPart.Position
```

Rules:

- Prefer intermediate variables.
- Use meaningful variable names.
- Reduce chained expressions.

---

# Class Style

Organize classes using metatables.

Example:

```lua
local PlayerClass = {}
PlayerClass.__index = PlayerClass

function PlayerClass.new(Player)
    local self = setmetatable({}, PlayerClass)

    self.Player = Player
    self.Level = 1

    return self
end

function PlayerClass:SetLevel(Level)
    if Level <= 0 then
        return
    end

    self.Level = Level
end

return PlayerClass
```

---

# Formatting

- Use 4 spaces for indentation.
- Add spaces around operators.
- Separate logical code blocks with blank lines.
- Keep functions focused on a single responsibility.
- Avoid overly long expressions.
- Cache expensive function calls whenever possible.

---

# General Principles

- Don't Write comments
- Write readable code first.
- Performance comes second, readability comes first.
- Keep functions small.
- Avoid unnecessary nesting.
- Prefer early `return`.
- Prefer `continue`.
- Cache frequently used search results.
- Cache Roblox API array results before looping.
- Prefer numeric loops for large arrays.
- Use meaningful variable names.
- Avoid chained expressions.
- Break complex operations into multiple variables.
- Use `PascalCase` for variables, parameters, functions, classes, and modules.
- Use `UPPER_CASE` for constants.
- Use `Index` and `Value` as loop variable names whenever applicable.
