local _, Addon = ...
local T = Addon.Tooltip
local records, installed, writing = {}, false, false
local comparisonManager

local function plan(source, data)
    if not T.Readable(source, data) then return end
    local patches, rows = {}, {}
    if data.type == Enum.TooltipDataType.Item then
        local name = source:GetName()
        local types = Enum.TooltipDataLineType or {}
        for _, line in ipairs(data.lines) do
            local index = line.lineIndex
            if T.Number(index) and index>=1 and index<=source:NumLines()
                and (line.type==0 or (types.ItemSpellTriggerOnEquip and line.type==types.ItemSpellTriggerOnEquip)) then
                local left, right = _G[name.."TextLeft"..index], _G[name.."TextRight"..index]
                if left and (not right or not right:IsShown() or T.Text(right)=="") then
                    local r,g,b = left:GetTextColor()
                    if r<0.3 and g>0.7 and b<0.3 then
                        local first, _, second = T.CompactEquipEffect(T.Text(left))
                        if first then patches[#patches+1]={region=left,value=first..(second and ("\n"..second) or "")} end
                    end
                end
            end
        end
    elseif data.type == Enum.TooltipDataType.Spell and (source==GameTooltip or source==ItemRefTooltip) then
        local model = {kind="Spell",rows={}}
        T.AddSpellDetails(model, data.id)
        if #model.rows>0 then
            rows[1]={left=" "}
            for _, row in ipairs(model.rows) do rows[#rows+1]=row end
        end
    end
    if source:NumLines()+#rows>T.maxLines then return end
    return patches, rows
end

local function decorate(source, data)
    if writing or not Addon.Active() or not T.Usable(source) then return end
    local record = records[source]
    if not record or record.done then return end
    local ok, patches, rows = pcall(plan, source, data)
    if not ok or not patches then return end
    writing, record.done = true, true
    local applied = pcall(function()
        for _, patch in ipairs(patches) do patch.region:SetText(patch.value) end
        for _, row in ipairs(rows) do
            local color = row.detailRole=="heading" and {1,0.82,0}
                or (row.detailRole=="note" or row.detailRole=="hint") and {0.7,0.7,0.7} or {1,1,1}
            if row.right and row.right~="" then
                source:AddDoubleLine(row.left,row.right,color[1],color[2],color[3],1,1,1)
            else source:AddLine(row.left,color[1],color[2],color[3],true) end
        end
    end)
    if not applied and source.RefreshData then
        pcall(source.RefreshData,source)
        record.done=true
    end
    writing=false
end

local function comparisons(source)
    if writing or not Addon.Active() or not T.Usable(source) or not records[source] then return end
    if source==GameTooltip or source==ItemRefTooltip then return end
    local count, name = source:NumLines(), source:GetName()
    if not T.Number(count) or count>T.maxLines or not T.Plain(name) or type(name)~="string" then return end
    local entries, summary, separate = {}, false, false
    -- Finish reading the complete summary before making any changes.
    for i=1,count do
        local left, right = _G[name.."TextLeft"..i], _G[name.."TextRight"..i]
        local value = T.Text(left)
        if right and right:IsShown() and T.Text(right)~="" then summary=false
        elseif value==ITEM_DELTA_DESCRIPTION or value==ITEM_DELTA_MULTIPLE_COMPARISON_DESCRIPTION then summary=true
        elseif summary then
            local first, second, kind = T.CompactComparisonStat(value)
            if first then
                entries[#entries+1]={region=left,value=first..(second and ("\n"..second) or ""),kind=kind}
                if kind~="power" then separate=true end
            elseif value=="" then summary=false end
        end
    end
    local changed=false
    for _, entry in ipairs(entries) do
        if not (entry.kind=="power" and separate) and T.Text(entry.region)~=entry.value then
            entry.region:SetText(entry.value)
            changed=true
        end
    end
    if changed then source:Show() end
end

function Addon.Install()
    if not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall or not hooksecurefunc then return end
    for _, name in ipairs({"GameTooltip","ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2",
        "ItemRefShoppingTooltip1","ItemRefShoppingTooltip2"}) do
        local source = _G[name]
        if T.Usable(source) and source.GetName and source.NumLines and not records[source] then
            local record = {elapsed=0,shift=false}
            records[source]=record
            hooksecurefunc(source,"ClearLines",function()
                record.done=false
                record.shift=IsShiftKeyDown and IsShiftKeyDown()==true or false
            end)
            if source==GameTooltip or source==ItemRefTooltip then
                source:HookScript("OnUpdate",function(self,elapsed)
                    if not Addon.Active() or not T.Usable(self) then return end
                    record.elapsed=record.elapsed+elapsed
                    if record.elapsed<0.1 then return end
                    record.elapsed=0
                    local shift=IsShiftKeyDown and IsShiftKeyDown()==true or false
                    if record.shift~=shift then
                        record.shift=shift
                        local getter=self.GetPrimaryTooltipData or self.GetTooltipData
                        if getter then
                            local ok,data=pcall(getter,self)
                            if ok and T.Plain(data) and type(data)=="table" and T.Plain(data.type)
                                and data.type==Enum.TooltipDataType.Spell and self.RefreshData then
                                pcall(self.RefreshData,self)
                            end
                        end
                    end
                end)
            end
        end
    end
    -- Blizzard appends deltas after the data callback, before placing the
    -- comparison group. A synchronous post-hook avoids polling/flicker.
    local manager=TooltipComparisonManager
    if manager and manager~=comparisonManager and type(manager.SetItemTooltip)=="function" then
        hooksecurefunc(manager,"SetItemTooltip",function(self,primary)
            local owner=self.tooltip
            local tips=owner and owner.shoppingTooltips
            local source=tips and tips[primary and 1 or 2]
            if source then pcall(comparisons,source) end
        end)
        comparisonManager=manager
    end
    if not installed then
        installed=true
        TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes,function(source,data)
            pcall(decorate,source,data)
        end)
    end
end
