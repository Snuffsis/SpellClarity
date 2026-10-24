local _, Addon = ...
local T = {maxLines=48}
Addon.Tooltip = T
Addon.session = {language="enUS", tooltipspelldetails=true}
Addon.L = setmetatable({}, {__index=function(_, key)
    return Addon.session.language == "svSE" and Addon.svSE[key] or key
end})

function T.Plain(value)
    return not issecretvalue or not issecretvalue(value)
end
function T.Number(value)
    return T.Plain(value) and type(value)=="number" and value==value
        and value > -math.huge and value < math.huge
end
function T.Usable(frame)
    return T.Plain(frame) and frame and not (frame.IsForbidden and frame:IsForbidden())
        and not (frame.IsProtected and frame:IsProtected())
end

-- Optional conflict avoidance only: no framework, settings or assets are read.
function Addon.Active()
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    return not (loaded and (loaded("Aevum_Tooltips") or loaded("ForeverUI_Tooltips") or loaded("ForeverSkin_Tooltips")))
end

function T.Text(region)
    local value = region and region:GetText()
    if not T.Plain(value) then error("Unreadable tooltip text") end
    if value == nil then return "" end
    if type(value) ~= "string" then error("Unexpected tooltip text") end
    return value
end

-- Validate the whole transaction before writing any text. Embedded profession
-- panels and restricted data stay entirely native; no TooltipData is mutated.
function T.Readable(source, data)
    if not T.Usable(source) or not T.Plain(data) or type(data)~="table" then return end
    if not T.Plain(data.type) or not T.Plain(data.worldLootObjectInventoryType)
        or data.worldLootObjectInventoryType~=nil then return end
    local types = Enum and Enum.TooltipDataType
    if not types or (data.type~=types.Item and data.type~=types.Spell) then return end
    for _, child in ipairs({"ItemTooltip", "BattlePetTooltip"}) do
        if source[child] and source[child]:IsShown() then return end
    end
    local count, name = source:NumLines(), source:GetName()
    if not T.Number(count) or count<1 or count>T.maxLines or not T.Plain(name) or type(name)~="string" then return end
    if not T.Plain(data.lines) or type(data.lines)~="table" then return end
    local nested = Enum.TooltipDataLineType and Enum.TooltipDataLineType.NestedBlock
    for _, line in ipairs(data.lines) do
        if not T.Plain(line) or type(line)~="table" or not T.Plain(line.type)
            or not T.Plain(line.lineIndex) or (nested and line.type==nested) then return end
    end
    for i=1,count do
        for _, side in ipairs({"Left", "Right"}) do
            local region = _G[name.."Text"..side..i]
            T.Text(region)
            if region then
                local r,g,b = region:GetTextColor()
                if not T.Number(r) or not T.Number(g) or not T.Number(b) then return end
            end
        end
    end
    return true
end
