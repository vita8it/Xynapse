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

Always use descriptive variable names.

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

# Formatting

- Use 4 spaces for indentation.
- Add spaces around operators.
- Separate logical code blocks with blank lines.
- Keep functions focused on a single responsibility.

---

# General Principles

- Write readable code first.
- Keep functions small.
- Avoid unnecessary nesting.
- Use meaningful names.
- Prefer early `return`.
- Prefer `continue` inside loops.
- Use `PascalCase` for variables, functions, parameters, classes, and modules.
- Use `UPPER_CASE` for constants.
- Use `Index` and `Value` as loop variable names.
