-- Imported from Aevum; maintained independently here. See UPSTREAM.md.
local _, Addon = ...
local T = Addon.Tooltip

-- Only complete, unconditional English equip descriptions are shortened.
-- Unknown schools, locales, procs and trailing conditions retain native text.
local equipEffects = {
    holy = {"Holy spell dmg", {229/255,213/255,138/255}},
    fire = {"Fire spell dmg", {227/255,149/255,136/255}},
    nature = {"Nature spell dmg", {143/255,188/255,141/255}},
    shadow = {"Shadow spell dmg", {174/255,138/255,194/255}},
    frost = {"Frost spell dmg", {140/255,189/255,224/255}},
    arcane = {"Arcane spell dmg", {196/255,180/255,237/255}},
    ["spell damage"] = {"Spell dmg", {145/255,191/255,193/255}},
    healing = {"Healing", {168/255,213/255,186/255}},
    ["attack power"] = {"Attack power", {212/255,170/255,115/255}},
    ["melee attack power"] = {"Melee attack power", {205/255,150/255,124/255}},
    ["ranged attack power"] = {"Ranged attack power", {201/255,190/255,131/255}},
}
local function compactEffect(effect, amount)
    local entry = equipEffects[effect]
    if not entry or not amount or not T.Number(tonumber(amount)) or tonumber(amount) <= 0 then return end
    return "+" .. amount .. " " .. Addon.L[entry[1]], entry[2]
end

-- Returns first-row text/color and, for combined bonuses, healing text/color.
function T.CompactEquipEffect(text)
    if not T.Plain(text) or type(text) ~= "string" or text:find("|", 1, true) then return end
    local plain = text:lower():gsub("%s+", " "):match("^%s*(.-)%s*$")
    local amount = plain:match("^equip: increases damage and healing done by magical spells and effects by up to (%d+)%.?$")
    local healingAmount = amount
    if not amount then
        healingAmount, amount = plain:match("^equip: increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects%.?$")
    end
    if not amount then
        amount, healingAmount = plain:match("^equip: increases damage done by up to (%d+) and healing done by up to (%d+) for all magical spells and effects%.?$")
    end
    if amount then
        local damage, damageColor = compactEffect("spell damage", amount)
        local healing, healingColor = compactEffect("healing", healingAmount)
        -- Never show a partial interpretation of a combined effect.
        if damage and healing then return damage, damageColor, healing, healingColor end
        return
    end
    local effect, amount = plain:match("^equip: increases damage done by (%a+) spells and effects by up to (%d+)%.?$")
    if not effect then
        effect, amount = plain:match("^equip: increases ([%a ]+attack power) by (%d+)%.?$")
        if not effect then
            amount = plain:match("^equip: increases attack power by (%d+)%.?$")
            if amount then effect = "attack power" end
        end
    end
    if not effect then
        amount, effect = plain:match("^equip: %+(%d+) ([%a ]+)%.?$")
        -- Short forms are supported for AP only, never guessed spell bonuses.
        if effect ~= "attack power" and effect ~= "melee attack power" and effect ~= "ranged attack power" then return end
    end
    return compactEffect(effect, amount)
end

-- Native comparison deltas are appended after ProcessInfo, without line
-- metadata. Keep their signed value/color codes; only replace known labels.
function T.CompactComparisonStat(text)
    if not T.Plain(text) or type(text) ~= "string" then return end
    local labels = {
        {ITEM_MOD_SPELL_POWER_SHORT or "Spell Power", "power"},
        {ITEM_MOD_SPELL_DAMAGE_DONE_SHORT or "Spell Damage", "damage"},
        {ITEM_MOD_SPELL_HEALING_DONE_SHORT or "Spell Healing", "healing"},
    }
    for _, entry in ipairs(labels) do
        local suffix = " " .. entry[1]
        if text:sub(-#suffix) == suffix then
            local value = text:sub(1, -#suffix - 1)
            local number = value:match("^([+-]%d+)$")
                or value:match("^|c%x%x%x%x%x%x%x%x([+-]%d+)|r$")
            if number and T.Number(tonumber(number)) and tonumber(number) ~= 0 then
                local damage = value .. " " .. Addon.L["Spell dmg"]
                local healing = value .. " " .. Addon.L["Healing"]
                if entry[2] == "power" then return damage, healing, "power" end
                return entry[2] == "damage" and damage or healing, nil, entry[2]
            end
        end
    end
end
