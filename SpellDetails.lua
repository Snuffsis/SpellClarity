-- Imported from Aevum; maintained independently here. See UPSTREAM.md.
local _, Addon = ...
local T = Addon.Tooltip
local normal, muted = {0.92,0.91,0.86}, {0.61,0.70,0.73}
local gold, spellColor, healColor = {0.84,0.74,0.49}, {145/255,191/255,193/255}, {166/255,207/255,181/255}
local schools = {"Physical", "Holy", "Fire", "Nature", "Frost", "Shadow", "Arcane"}
local utilityEffects = {[5]="Teleport", [18]="Resurrection", [24]="Create item", [28]="Summon",
    [30]="Resource gain", [38]="Dispel", [64]="Triggered effect", [68]="Interrupt"}
local utilityAuras = {[7]="Fear", [12]="Stun", [26]="Root", [27]="Silence",
    [29]="Stat modifier", [31]="Movement speed", [33]="Movement slow", [36]="Shapeshift"}

-- Scalar client facts only, never inferred from cast time or native text.
function T.CalculateSpellDetails(id, level, power, effectIndex)
    if not T.Number(id) or not T.Number(level) or not T.Number(power) or power < 0 then return end
    local spell = T.spellDetailData and T.spellDetailData.spells[id]
    if not spell or level < spell.level or level > 60 then return end
    local e = spell.effects[effectIndex or 1]
    if not e or e[10] ~= 0 then return end
    local cap = spell.maxLevel > 0 and spell.maxLevel or 60
    local growth = math.max(0, math.min(level, cap)-spell.level)*e[5]
    local mean, spread = e[3]+growth, math.abs(e[3]*e[4]/2)
    local bonus = power*e[6]
    return {low=mean-spread, high=mean+spread, bonus=bonus, power=power,
        totalLow=mean-spread+bonus, totalHigh=mean+spread+bonus, coefficient=e[6]}
end

local function decimal(value)
    local text = string.format("%.1f", value)
    if Addon.session.language == "svSE" then text = text:gsub("%.", ",") end
    return text
end
local function range(low, high)
    return low == high and decimal(low) or decimal(low).."–"..decimal(high)
end
local function row(left, right, tint, role)
    return {left=left, right=right or "", color=tint or normal, rightColor=tint or normal, detailRole=role or "value"}
end
local function rule()
    local result = row("", "", muted, "rule")
    result.separator = true
    return result
end
local function add(rows, label, value, color, role)
    rows[#rows+1] = row(Addon.L[label], value, color, role)
end
local function note(rows, label) add(rows, label, nil, muted, "note") end
local function heading(rows, label) add(rows, label, nil, gold, "heading") end
local function read(fn, ...)
    if not fn then return end
    local ok, value = pcall(fn, ...)
    if ok and T.Number(value) then return value end
end
local function attackPower(ranged)
    local fn
    if ranged then fn = UnitRangedAttackPower else fn = UnitAttackPower end
    if not fn then return end
    local ok, base, positive, negative = pcall(fn, "player")
    if ok and T.Number(base) and T.Number(positive) and T.Number(negative) then
        local total = base+positive+negative
        if T.Number(total) then return math.max(0, total) end
    end
end
local function effectKind(e)
    if e[1] == 2 then return "Damage breakdown", false, false end
    if e[1] == 10 then return "Healing breakdown", true, false end
    if e[1] == 6 then
        if e[2] == 3 or e[2] == 53 then return "Damage per tick", false, true end
        if e[2] == 8 then return "Healing per tick", true, true end
        if e[2] == 69 then return "Absorb breakdown", true, false end
    end
end
local function numericEffect(rows, spell, id, index, level)
    local e = spell.effects[index]
    local title, healing, periodic = effectKind(e)
    heading(rows, title)
    -- Default physical/weapon coefficient 1 is not a spell-power coefficient.
    -- Resource-dependent and scaling-table effects need separate full formulas.
    if e[8] ~= 0 or e[10] ~= 0 or (not healing and spell.school <= 1) then
        local v = T.CalculateSpellDetails(id, level, 0, index)
        if v then add(rows, "Base component", range(v.low, v.high)) end
        if e[8] ~= 0 then add(rows, "Per resource point", decimal(e[8])) end
        note(rows, "Full formula unavailable; see spell description.")
        return
    end
    local power
    if e[6] == 0 then power = 0
    elseif healing then power = read(GetSpellBonusHealing)
    else power = read(GetSpellBonusDamage, spell.school) end
    local v = T.CalculateSpellDetails(id, level, power, index)
    local ap = 0
    if e[7] ~= 0 then ap = attackPower(spell.ranged) end
    if not v or not T.Number(ap) then note(rows, "Spell details are currently unavailable."); return end
    local absorb = e[1] == 6 and e[2] == 69
    add(rows, absorb and "Base absorb" or healing and "Base healing" or "Base damage", range(v.low, v.high))
    local tint = healing and healColor or spellColor
    if e[6] ~= 0 or not periodic then
        add(rows, healing and "From healing power" or "From spell power", "+"..decimal(v.bonus), tint)
    end
    local apBonus = ap*e[7]
    if e[7] ~= 0 then add(rows, "From attack power", "+"..decimal(apBonus), spellColor) end
    rows[#rows+1] = rule()
    add(rows, absorb and "Calculated absorb" or healing and "Calculated healing" or "Calculated damage",
        range(v.totalLow+apBonus, v.totalHigh+apBonus), tint)
    if e[6] ~= 0 then
        local label = healing and Addon.L["Healing power"] or Addon.L[schools[spell.school]].." "..Addon.L["spell power"]
        rows[#rows+1] = row(decimal(power).." "..label.." · "..decimal(e[6]*100)..Addon.L["% coefficient"], nil, muted, "note")
    end
    if periodic and e[9] > 0 then
        add(rows, "Tick interval", decimal(e[9]/1000).." s")
        -- No invented tick count for channels, instant ticks or haste.
        note(rows, "Values per tick; duration modifiers excluded.")
    end
    if e[2] == 53 then note(rows, "Leech healing depends on damage dealt.") end
end
local function weaponEffects(rows, spell, id, level)
    local normalized, low, high, percent = false, 0, 0, 100
    local found = false
    for i,e in ipairs(spell.effects) do
        if e[1] == 17 or e[1] == 58 or e[1] == 121 or e[1] == 31 then
            found = true
            if e[8] ~= 0 or e[10] ~= 0 then return false end
            if e[1] == 31 then percent = e[3] else
                local v = T.CalculateSpellDetails(id, level, 0, i)
                if not v then return false end
                low, high = low+v.low, high+v.high
                normalized = normalized or e[1] == 121
            end
        end
    end
    if not found then return false end
    heading(rows, "Weapon attack")
    add(rows, normalized and "Normalized weapon damage" or "Weapon damage", decimal(percent).."%")
    add(rows, "Ability base bonus", range(low, high))
    local ap = attackPower(spell.ranged)
    if ap then add(rows, spell.ranged and "Current ranged attack power" or "Current melee attack power", decimal(ap)) end
    note(rows, "Components only; weapon modifiers affect the total.")
    return true
end
local function eligibility(id)
    local fn = C_SpellBook and C_SpellBook.IsSpellKnown or IsSpellKnown
    if not fn then return end
    local known = fn(id)
    if T.Plain(known) and known == true then return "player" end
    -- Never calculate pet spells using the owner's stats.
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    if C_SpellBook and C_SpellBook.IsSpellKnown and bank then known = fn(id, bank)
    elseif IsSpellKnown then known = IsSpellKnown(id, true) else return end
    if T.Plain(known) and known == true then return "pet" end
end
local function details(id, expanded)
    if not T.Number(id) or id <= 0 then return end
    local owner = eligibility(id)
    if not owner then return end
    if not expanded then return {} end
    local result = {rule()}
    local data = T.spellDetailData
    local version, build = GetBuildInfo()
    if not data or not T.Plain(version) or not T.Plain(build) or version ~= data.version or build ~= data.build then
        heading(result, "Spell details")
        note(result, "Spell details need updated client data.")
        return result
    end
    local spell = data.spells[id]
    if not spell or owner == "pet" then
        heading(result, "Spell details")
        note(result, owner == "pet" and "Pet formula unavailable; see spell description." or "Full formula unavailable; see spell description.")
        return result
    end
    local level = read(UnitLevel, "player")
    if not level or level < spell.level or level > 60 then
        note(result, "Spell details are currently unavailable."); return result
    end
    local shown, other = false, false
    for i,e in ipairs(spell.effects) do
        if effectKind(e) then
            if shown then result[#result+1] = rule() end
            numericEffect(result, spell, id, i, level)
            shown = true
        elseif e[1] ~= 17 and e[1] ~= 58 and e[1] ~= 121 and e[1] ~= 31 then other = true end
    end
    if weaponEffects(result, spell, id, level) then shown = true end
    if not shown then heading(result, "Spell details") end
    if spell.duration and spell.duration > 0 then
        if spell.durationPerResource == 0 and spell.maxDuration == spell.duration then
            add(result, "Base duration", decimal(spell.duration/1000).." s")
        else note(result, "Duration varies; see spell description.") end
    end
    if not shown then
        if spell.school > 0 then add(result, "School", Addon.L[schools[spell.school]]) end
        local seen, utility = {}, false
        for _,e in ipairs(spell.effects) do
            local label = e[1] == 6 and utilityAuras[e[2]] or utilityEffects[e[1]]
            if label and not seen[label] then
                add(result, "Effect", Addon.L[label]); seen[label] = true; utility = true
            end
        end
        note(result, utility and "Effect conditions: see spell description." or "Full formula unavailable; see spell description.")
    elseif other then note(result, "Other effects: see spell description.") end
    note(result, "Estimate before talents, crits and target effects.")
    return result
end

function T.AddSpellDetails(model, id)
    if model.kind ~= "Spell" or Addon.session.tooltipspelldetails == false then return end
    local expanded = IsShiftKeyDown and IsShiftKeyDown()
    if not T.Plain(expanded) then return end
    expanded = expanded == true
    local ok, additions = pcall(details, id, expanded)
    if not ok then
        -- An API error in eligibility checking leaves the original untouched.
        return
    end
    if not additions then return end
    local footer = row(Addon.L[expanded and "Release Shift to hide details" or "Hold Shift for details"], nil, muted, "hint")
    if #model.rows+#additions+1 > T.maxLines then return end
    -- Keep PTR/help/addon rows in their original order, below the description
    -- and its new details. Untyped descriptions fall back to an appended block.
    local insertion = #model.rows
    for i, original in ipairs(model.rows) do if original.spellDescription then insertion = i end end
    local rows = {}
    for i=1,insertion do rows[#rows+1] = model.rows[i] end
    for _, addition in ipairs(additions) do rows[#rows+1] = addition end
    for i=insertion+1,#model.rows do rows[#rows+1] = model.rows[i] end
    rows[#rows+1] = footer
    model.rows = rows
    local signature = {expanded and "expanded" or "collapsed", footer.left}
    for _, addition in ipairs(additions) do signature[#signature+1] = addition.left.."\031"..addition.right end
    return table.concat(signature, "\030")
end
