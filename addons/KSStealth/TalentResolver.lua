-- KS Stealth talent/spell resolver. Read-only; NEVER sample combat target health,
-- combo points or combat auras. This module scans the player's traits/spells
-- only outside combat and fails closed when Forever changes its API schema.
local S=KSStealth
local MAX_TREES,MAX_NODES,MAX_LINES,MAX_SLOTS=10,500,45,500
local function plainNumber(value)
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,value)
  if not ok or secret then return nil end
 end
 if type(value)~="number" or value~=value or value<0 or value==math.huge then return nil end
 return value
end
local function plainString(value)
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,value)
  if not ok or secret then return nil end
 end
 if type(value)~="string" or #value>160 then return nil end
 return value
end
local function safeCall(fn,...)
 if type(fn)~="function" then return nil end
 local ok,result=pcall(fn,...)
 if ok then return result end
end

function S:ReadTalentRanks()
 if KoolSupport:IsInCombat() then return nil,"Talent inspection is outside-combat only" end
 local ct,traits=C_ClassTalents,C_Traits
 if not ct or not traits then return nil,"Forever trait APIs unavailable" end
 for _,fn in ipairs({"GetConfigInfo","GetTreeNodes","GetNodeInfo","GetEntryInfo","GetDefinitionInfo"}) do
  if type(traits[fn])~="function" then return nil,"Trait API incomplete: "..fn end
 end
 local config=plainNumber(safeCall(ct.GetActiveConfigID))
 if not config or config==0 then return nil,"No active Forever talent configuration" end
 if type(traits.ConfigHasStagedChanges)=="function" then
  local pending=safeCall(traits.ConfigHasStagedChanges,config)
  if pending==nil or pending then return nil,"Pending talent changes; confirm talents and refresh" end
 end
 local configInfo=safeCall(traits.GetConfigInfo,config)
 if type(configInfo)~="table" or type(configInfo.treeIDs)~="table" then
  return nil,"Active trait tree is not accessible"
 end
 local ranks,found={},{}
 local trees=0
 for _,tree in ipairs(configInfo.treeIDs) do
  trees=trees+1
  if trees>MAX_TREES then return nil,"Trait tree exceeds safety limit" end
  local nodes=safeCall(traits.GetTreeNodes,tree)
  if type(nodes)~="table" then return nil,"A trait tree could not be read" end
  if #nodes>MAX_NODES then return nil,"Trait tree exceeds node safety limit" end
  for _,nodeID in ipairs(nodes) do
   local node=safeCall(traits.GetNodeInfo,config,nodeID)
   if type(node)=="table" then
    local entries={}
    if type(node.entryIDs)=="table" then
     for _,id in ipairs(node.entryIDs) do entries[#entries+1]=id end
    end
    local selected=node.activeEntry
    local selectedID=type(selected)=="table" and selected.entryID or nil
    if selectedID and #entries==0 then entries[1]=selectedID end
    for _,entryID in ipairs(entries) do
     local entry=safeCall(traits.GetEntryInfo,config,entryID)
     local definition=type(entry)=="table" and
       safeCall(traits.GetDefinitionInfo,entry.definitionID) or nil
     if type(definition)=="table" then
      local name=plainString(definition.overrideName)
      if not name and definition.spellID and C_Spell then
       name=plainString(safeCall(C_Spell.GetSpellName,definition.spellID))
      end
      if not name and definition.spellID and C_Spell and type(C_Spell.GetSpellInfo)=="function" then
       local info=safeCall(C_Spell.GetSpellInfo,definition.spellID)
       if type(info)=="table" then name=plainString(info.name) end
      end
      if name then
       found[name]=true
       local rank=0
       if selectedID==entryID then
        rank=plainNumber(selected.rank) or plainNumber(node.activeRank) or
          plainNumber(node.currentRank) or 0
       elseif #entries==1 then
        rank=plainNumber(node.activeRank) or plainNumber(node.currentRank) or 0
       end
       if rank~=math.floor(rank) or rank>50 then return nil,"Unexpected talent rank data" end
       ranks[name]=math.max(ranks[name] or 0,rank)
      end
     end
    end
   end
  end
 end
 if trees==0 then return nil,"No active talent trees" end
 return {ranks=ranks,found=found,configID=config}
end

function S:ReadLearnedAbilities()
 if KoolSupport:IsInCombat() then return nil,"Spellbook inspection is outside-combat only" end
 local a=C_SpellBook
 if not a or type(a.GetNumSpellBookSkillLines)~="function" or
  type(a.GetSpellBookSkillLineInfo)~="function" or
  type(a.GetSpellBookItemInfo)~="function" then
  return nil,"Forever spellbook APIs unavailable"
 end
 local count=plainNumber(safeCall(a.GetNumSpellBookSkillLines))
 if not count then return nil,"Spellbook skill lines unavailable" end
 local bank=(Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
 local kinds=(Enum and Enum.SpellBookItemType) or {}
 local learned={}
 for i=1,math.min(count,MAX_LINES) do
  local line=safeCall(a.GetSpellBookSkillLineInfo,i)
  if type(line)=="table" and not line.shouldHide then
   local offset=plainNumber(line.itemIndexOffset)
   local total=plainNumber(line.numSpellBookItems)
   if offset and total then
    for slot=offset+1,offset+math.min(total,MAX_SLOTS) do
     local info=safeCall(a.GetSpellBookItemInfo,slot,bank)
     if type(info)=="table" and
      (info.itemType==kinds.Spell or info.itemType==1 or info.itemType=="SPELL") then
      local passive=info.isPassive
      if passive==nil and type(a.IsSpellBookItemPassive)=="function" then
       passive=safeCall(a.IsSpellBookItemPassive,slot,bank)
      end
      if not passive then
       local name=plainString(info.name)
       local spellID=plainNumber(info.spellID)
       if not name and spellID and C_Spell then
        name=plainString(safeCall(C_Spell.GetSpellName,spellID))
       end
       if name and spellID then
        local sub=plainString(info.subName) or ""
        local rank=tonumber(sub:match("[Rr]ank%s+(%d+)"))
        rank=plainNumber(rank) or 0
        local best=learned[name]
        if not best or rank>best.rank then learned[name]={spellID=spellID,rank=rank} end
       end
      end
     end
    end
   end
  end
 end
 return learned
end

function S:RefreshTalentInsights()
 if KoolSupport:IsInCombat() then return false,"Refresh Talent Impacts outside combat" end
 local class
 if type(UnitClass)=="function" then local _; _,class=UnitClass("player") end
 if class~="DRUID" and class~="ROGUE" then
  self.talentSnapshot=nil
  return false,"Talent Impacts currently supports Druid and Rogue"
 end
 local talents,talentWhy=self:ReadTalentRanks()
 local abilities,spellWhy=self:ReadLearnedAbilities()
 self.talentSnapshot={
  class=class,talents=talents,abilities=abilities,
  talentError=talentWhy,spellError=spellWhy
 }
 if not talents then return false,talentWhy end
 if not abilities then return false,spellWhy end
 return true,"Talent ranks and learned spellbook refreshed"
end

function S:LiveCost(ability,resource)
 if KoolSupport:IsInCombat() then return nil end
 local snapshot=self.talentSnapshot
 local spell=snapshot and snapshot.abilities and snapshot.abilities[ability]
 if not spell or not C_Spell or type(C_Spell.GetSpellPowerCost)~="function" then return nil end
 local costs=safeCall(C_Spell.GetSpellPowerCost,spell.spellID)
 if type(costs)~="table" then return nil end
 for _,cost in ipairs(costs) do
  if type(cost)=="table" and cost.name==resource then
   local value=plainNumber(cost.cost)
   local minimum=plainNumber(cost.minCost)
   if value and (not minimum or minimum==value) then return value end
  end
 end
 return nil
end

function S:TrainedRank(entry)
 local snap=self.talentSnapshot
 if not snap or not snap.talents then return nil end
 if not snap.talents.found[entry.name] then return nil end
 local rank=snap.talents.ranks[entry.name]
 if type(rank)=="number" and rank>=0 and rank<=entry.maxRank then return rank end
 return nil
end

-- Returns read-only observations for a spell. Nothing here runs in combat.
-- Numbers based on 100 damage are explicitly normalized, NOT actual hits.
function S:AbilityInsights(ability)
 if KoolSupport:IsInCombat() or not KoolSupport:IsModuleEnabled("ks_stealth") then return {} end
 if not self:Store().talentImpactOverlay then return {} end
 local snapshot=self.talentSnapshot
 if not snapshot or not snapshot.talents or snapshot.class~=select(2,UnitClass("player")) then return {} end
 local result={}
 for _,entry in ipairs(self:GetTalentImpactCatalog(snapshot.class)) do
  local rank=self:TrainedRank(entry)
  local mod=rank and rank>0 and entry.modifiers and entry.modifiers[ability]
  if mod and mod.values and mod.values[rank] then
   local value=mod.values[rank]
   local description
   if mod.kind=="damage_pct" then
    description="+"..value.."% damage (normalized 100 -> "..(100+value)..")"
    if self:Store().talentCritEstimate then
     description=description.."; 200% crit example: "..(200+2*value)
    end
   elseif mod.kind=="crit_chance" then
    description="+"..value.." percentage points crit chance"
   elseif mod.kind=="cost_flat" then
    description="-"..value.." "..mod.resource.." cost"
    local live=self:LiveCost(ability,mod.resource)
    if live then
     description=description.." (current API "..live..
       "; without talent approx. "..(live+value)..")"
    end
   elseif mod.kind=="cost_pct" then
    description="-"..value.."% "..mod.resource.." cost"
    local live=self:LiveCost(ability,mod.resource)
    if live then description=description.." (current API "..live..")" end
   elseif mod.kind=="cooldown_flat" then
    description="-"..value.." sec cooldown"
   end
   if description then
    result[#result+1]={talent=entry.name,rank=rank,maxRank=entry.maxRank,
      description=description,kind=mod.kind}
   end
  end
 end
 return result
end

function S:AbilityInsightLines(ability)
 local lines={}
 for _,entry in ipairs(self:AbilityInsights(ability)) do
  lines[#lines+1]=entry.talent.." ("..entry.rank.."/"..entry.maxRank.."): "..entry.description
 end
 return lines
end


-- Trait/learned spell changes can invalidate a previous out-of-combat snapshot.
-- Forever may omit events; RegisterEvent MUST be protected with pcall.
local watcher=CreateFrame("Frame")
for _,event in ipairs({"TRAIT_CONFIG_UPDATED","SPELLS_CHANGED","PLAYER_ENTERING_WORLD"}) do
 pcall(watcher.RegisterEvent,watcher,event)
end
watcher:SetScript("OnEvent",function()
 S.talentSnapshot=nil
 if S:Store().talentImpactOverlay and not KoolSupport:IsInCombat() then
  S:RefreshTalentInsights()
 end
end)
