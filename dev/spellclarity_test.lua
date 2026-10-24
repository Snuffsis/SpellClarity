local pass = ...
-- Isolated globals: no Aevum namespace, locale, renderer or framework.
local E = {}
for _,key in ipairs({"assert","error","ipairs","pairs","pcall","type","tonumber","tostring","setmetatable","math","string","table","unpack"}) do E[key]=_G[key] end
E._G=E
local callbacks, events, shift, conflict = {}, nil, false, false
local version, build, known, power = "1.60.1", "70338", true, 100
E.print=function()end
E.SlashCmdList={}
E.issecretvalue=function(value)return value=="SECRET"end
E.IsShiftKeyDown=function()return shift end
E.GetBuildInfo=function()return version,build end
E.UnitLevel=function()return 60 end
E.GetSpellBonusDamage=function()return power end
E.GetSpellBonusHealing=function()return 200 end
E.UnitAttackPower=function()return 100,20,-5 end
E.UnitRangedAttackPower=E.UnitAttackPower
E.C_SpellBook={IsSpellKnown=function()return known end}
E.C_AddOns={IsAddOnLoaded=function(name)
    assert(name=="Aevum_Tooltips" or name=="ForeverUI_Tooltips" or name=="ForeverSkin_Tooltips")
    return conflict==name
end}
E.Enum={TooltipDataType={Item=0,Spell=1,Unit=2},TooltipDataLineType={ItemName=22,SpellName=13,ItemSpellTriggerOnEquip=45,NestedBlock=19}}
E.ITEM_DELTA_DESCRIPTION="Stat changes:"
E.ITEM_DELTA_MULTIPLE_COMPARISON_DESCRIPTION="Other changes:"
E.TooltipDataProcessor={AllTypes="ALL",AddTooltipPostCall=function(_,fn)callbacks[#callbacks+1]=fn end}
E.CreateFrame=function(kind)
    assert(kind=="Frame" and not events, "Standalone allocated presentation frames")
    events={RegisterEvent=function()end,SetScript=function(self,_,fn)self.fire=fn end}
    return events
end
E.hooksecurefunc=function(object,key,callback)
    local original=object[key]
    object[key]=function(...)local result=original(...);callback(...);return result end
end
local methods={}
local function region(value,color)
    return {value=value,color=color or {1,1,1},shown=true,
        GetText=function(self)return self.value end,
        SetText=function(self,value)
            if self.failOnce then self.failOnce=false;error("write failure")end
            self.value=value
        end,
        GetTextColor=function(self)return unpack(self.color)end,
        IsShown=function(self)return self.shown end}
end
function methods:IsForbidden()return self.forbidden end
function methods:IsProtected()return self.protected end
function methods:GetName()return self.name end
function methods:NumLines()return self.count end
function methods:GetPrimaryTooltipData()return self.data end
function methods:ClearLines()self.count=0 end
function methods:Show()self.showCalls=(self.showCalls or 0)+1 end
function methods:HookScript(event,fn)assert(not self[event]);self[event]=fn end
function methods:AddDoubleLine(left,right,r,g,b,rr,rg,rb)
    self.count=self.count+1
    E[self.name.."TextLeft"..self.count]=region(left,{r,g,b})
    E[self.name.."TextRight"..self.count]=region(right,{rr,rg,rb})
end
function methods:AddLine(value,r,g,b)
    if self.failAppend then self.failAppend=false;error("append failure")end
    self:AddDoubleLine(value,"",r,g,b,1,1,1)
    E[self.name.."TextRight"..self.count].shown=false
end
function methods:RefreshData()
    self:ClearLines()
    self.data={type=self.kind,id=self.id,lines={}}
    for i,row in ipairs(self.original) do
        self:AddDoubleLine(row[1],row[2] or "",unpack(row.color or {1,1,1}))
        E[self.name.."TextRight"..i].color={1,1,1}
        E[self.name.."TextRight"..i].shown=(row[2] or "")~=""
        E[self.name.."TextLeft"..i].failOnce=row.failOnce
        self.data.lines[i]={lineIndex=i,type=row.kind or 0}
    end
    -- Metadata retains the native source text; the addon must never rewrite it.
    self.data.lines[1].leftText=self.original[1][1]
    for _,fn in ipairs(callbacks) do fn(self,self.data) end
    self:Show()
end
local function source(name)
    local f=setmetatable({name=name,count=0,original={},kind=0,id=123},{__index=methods})
    E[name]=f;return f
end
local tip,comparison,secondary=source("GameTooltip"),source("ShoppingTooltip1"),source("ShoppingTooltip2")
local link=source("ItemRefTooltip")
E.TooltipComparisonManager={tooltip={shoppingTooltips={comparison,secondary}}}
function E.TooltipComparisonManager:SetItemTooltip(primary)
    local source=self.tooltip.shoppingTooltips[primary and 1 or 2]
    source:RefreshData()
    source:AddLine(E.ITEM_DELTA_DESCRIPTION,1,1,1)
    for _,value in ipairs(self.deltas or {})do source:AddLine(value,1,1,1)end
end
local Addon={}
for line in io.lines("SpellClarity.toc")do
    if line:match("%.lua$")then
        local fn=assert(loadfile(""..line));setfenv(fn,E);fn("SpellClarity",Addon)
    end
end
assert(not E.Aevum and #callbacks==0)
events:fire("PLAYER_LOGIN");events:fire("ADDON_LOADED");Addon.Install()
assert(#callbacks==1 and E.SpellClarityDB and not E.AevumDB)
pass("SpellClarity loads its real TOC with only WoW APIs, its own database and one set of hooks")

local equip="Equip: Increases healing done by up to 9 and damage done by up to 3 for all magical spells and effects."
tip.original={{"Gloves",kind=22},{equip,kind=45,color={0,1,0}},{"Requires level 50"}}
tip:RefreshData()
assert(E.GameTooltipTextLeft2.value=="+3 Spell dmg\n+9 Healing" and tip.count==3)
assert(E.GameTooltipTextLeft2.color[2]==1 and tip.data.lines[1].leftText=="Gloves")
callbacks[1](tip,tip.data);assert(tip.count==3)
for _,case in ipairs({
    {"Equip: Increases damage done by Holy spells and effects by up to 4.","+4 Holy spell dmg"},
    {"Equip: Increases damage done by Fire spells and effects by up to 19.","+19 Fire spell dmg"},
    {"Equip: +24 Ranged attack power.","+24 Ranged attack power"},
    {"Equip: Increases melee attack power by 5.","+5 Melee attack power"},
    {"Equip: Increases attack power by 6.","+6 Attack power"},
})do tip.original[2][1]=case[1];tip:RefreshData();assert(E.GameTooltipTextLeft2.value==case[2])end
pass("standalone item bonuses retain native colors, split unequal spell/healing values and preserve school/AP scope")

for _,value in ipairs({"Equip: +24 Ranged attack power while in combat.","Use: +24 Attack power.","Equip: +5 Spell damage.","Equip: +0 Attack power.","|cff00ff00Equip: +24 Attack power.|r","Ausrüsten: Zaubermacht +24"})do
    tip.original[2][1]=value;tip:RefreshData();assert(E.GameTooltipTextLeft2.value==value)
end
tip.original[2][1]=equip
for _,color in ipairs({{1,0,0},{0.5,0.5,0.5},{"SECRET",1,0}})do
    tip.original[2].color=color;tip:RefreshData();assert(E.GameTooltipTextLeft2.value==equip)
end
tip.original[2].color={0,1,0}
tip.original[3][1]="SECRET";tip:RefreshData();assert(E.GameTooltipTextLeft2.value==equip)
tip.original[3][1]="Requires level 50"
for _,flag in ipairs({"forbidden","protected"})do
    tip[flag]=true;tip:RefreshData();assert(E.GameTooltipTextLeft2.value==equip);tip[flag]=false
end
tip.original[2].kind=19;tip:RefreshData();assert(E.GameTooltipTextLeft2.value==equip);tip.original[2].kind=45
tip.original[2][2]="Right column";tip:RefreshData();assert(E.GameTooltipTextLeft2.value==equip);tip.original[2][2]=nil
tip.ItemTooltip={IsShown=function()return true end};tip:RefreshData();assert(E.GameTooltipTextLeft2.value==equip);tip.ItemTooltip=nil
pass("standalone leaves unknown, localized, conditional, inactive, restricted, nested and two-column content untouched")

comparison.original=tip.original;secondary.original=tip.original
E.TooltipComparisonManager.deltas={"|cffff2020-6|r Spell Power"}
for i=1,30 do
    for _,primary in ipairs({true,false})do
        E.TooltipComparisonManager:SetItemTooltip(primary)
        local source=primary and comparison or secondary
        assert(E[source.name.."TextLeft5"].value=="|cffff2020-6|r Spell dmg\n|cffff2020-6|r Healing")
        assert(not source.OnUpdate)
    end
end
E.TooltipComparisonManager.deltas={"+1 Spell Power","-2 Spell Damage","+3 Spell Healing"}
E.TooltipComparisonManager:SetItemTooltip(true)
assert(E.ShoppingTooltip1TextLeft5.value=="+1 Spell Power")
assert(E.ShoppingTooltip1TextLeft6.value=="-2 Spell dmg" and E.ShoppingTooltip1TextLeft7.value=="+3 Healing")
E.TooltipComparisonManager.deltas={"+1 Spell Power","SECRET"};E.TooltipComparisonManager:SetItemTooltip(true)
assert(E.ShoppingTooltip1TextLeft5.value=="+1 Spell Power")
pass("standalone comparisons finish synchronously on both panels, preserve colored signs and avoid ambiguous or unreadable summaries")

tip.kind=1;tip.id=585;tip.original={{"Smite",kind=13},{"Smites an enemy."}}
tip:RefreshData();local collapsed=tip.count
assert(collapsed==4 and E.GameTooltipTextLeft4.value=="Hold Shift for details")
shift=true;tip:OnUpdate(0.2);assert(tip.count>collapsed)
local function contains(source,value)
    for i=1,source.count do if E[source.name.."TextLeft"..i].value==value then return true end end
    return false
end
assert(contains(tip,"Base damage") and contains(tip,"Calculated damage"))
assert(E.GameTooltipTextLeft2.value=="Smites an enemy.")
local expanded=tip.count
callbacks[1](tip,tip.data);assert(tip.count==expanded)
shift=false;tip:OnUpdate(0.2);assert(tip.count==collapsed)
link.kind=1;link.id=585;link.original=tip.original;link:RefreshData()
shift=true;link:OnUpdate(0.2);assert(contains(link,"Calculated damage"))
pass("standalone Shift details expand/collapse under the same hover and in linked spells without duplicating native text")

for _,case in ipairs({{2061,"Calculated healing"},{139,"Healing per tick"},{17,"Calculated absorb"},{53,"Weapon attack"}})do
    tip.id=case[1];tip:RefreshData();assert(contains(tip,case[2]),case[2])
end
tip.id=585;build="other";tip:RefreshData()
assert(contains(tip,"Spell details need updated client data.") and not contains(tip,"Calculated damage"))
build="70338";known=false;tip:RefreshData();assert(tip.count==2)
known=true;power="SECRET";tip:RefreshData();assert(contains(tip,"Spell details are currently unavailable."))
power=100;tip.original[2][1]="SECRET";tip:RefreshData();assert(tip.count==2)
tip.original[2][1]="Smites an enemy.";tip:RefreshData();assert(contains(tip,"Calculated damage"))
tip.failAppend=true;tip:RefreshData();assert(tip.count==2 and E.GameTooltipTextLeft2.value=="Smites an enemy.")
tip:RefreshData();assert(contains(tip,"Calculated damage"))
for i=3,48 do tip.original[i]={"Native line "..i}end
tip:RefreshData();assert(tip.count==48 and E.GameTooltipTextLeft48.value=="Native line 48")
pass("standalone healing/ticks/shields/weapon families, build pin, unknown spells, restricted stats, recovery and row limits remain guarded")

tip.original={{"Smite",kind=13},{"Smites an enemy."}}
E.SlashCmdList.SPELLCLARITY("sv");assert(E.SpellClarityDB.language=="svSE")
events:fire("PLAYER_LOGIN");tip:RefreshData()
assert(contains(tip,"Grundskada") and contains(tip,"Beräknad skada"))
assert(Addon.Tooltip.CompactEquipEffect("Equip: +24 Ranged attack power.")=="+24 Attackkraft på distans")
for _,name in ipairs({"Aevum_Tooltips", "ForeverUI_Tooltips", "ForeverSkin_Tooltips"}) do
    conflict=name;tip:RefreshData();assert(tip.count==2, name.." must suppress duplicate processing")
end
conflict=false;tip:RefreshData();assert(tip.count>2)
assert(#callbacks==1 and not E.Aevum)
pass("standalone owns its language settings and defers to all three generations of the tooltip module without reading a framework namespace")
