-- Optional, read-only native spell tooltip additions for known DRUID/ROGUE spells.
-- NO Blizzard frame replacement, hooksecurefunc on combat controls, or casts.
-- The tooltip processor is feature-detected and every callback fails closed.
local S=KSStealth
local hooked=false
local last={}

function S:CanAnnotateTalent()
 return KoolSupport:IsModuleEnabled("ks_stealth") and
  self:Store().talentImpactOverlay and self:Store().talentAnnotate and
  not KoolSupport:IsInCombat()
end

function S:AnnotateTalentTooltip(tooltip,data)
 if not self:CanAnnotateTalent() then return end
 if type(data)~="table" or type(tooltip)~="table" then return end
 local spellID=data.id
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,spellID)
  if not ok or secret then return end
 end
 if type(spellID)~="number" or spellID<=0 or spellID~=spellID then return end
 local snap=self.talentSnapshot
 if not snap or not snap.talents or not snap.abilities then return end
 local name
 for n,info in pairs(snap.abilities) do
  if info.spellID==spellID then name=n;break end
 end
 if not name then return end
 local rows=self:AbilityInsightLines(name)
 if #rows==0 or type(tooltip.AddLine)~="function" then return end
 -- Avoid duplicates when Blizzard reprocesses the same tooltip data.
 if last[tooltip]==spellID then return end
 last[tooltip]=spellID
 local success=pcall(function()
  tooltip:AddLine("KS Talent Impacts (read-only)",1,.81,.43)
  for i=1,math.min(3,#rows) do tooltip:AddLine(rows[i],.76,.88,.78,true) end
  if #rows>3 then tooltip:AddLine("More modifiers in /kool -> Talent Impacts",.7,.7,.7) end
 end)
 if not success then last[tooltip]=nil end
end

function S:InstallTalentTooltipHook()
 if hooked then return true end
 if not TooltipDataProcessor or type(TooltipDataProcessor.AddTooltipPostCall)~="function"
  or not Enum or not Enum.TooltipDataType or not Enum.TooltipDataType.Spell then
  return false,"Native spell tooltip processor not available on this client"
 end
 local ok=pcall(TooltipDataProcessor.AddTooltipPostCall,Enum.TooltipDataType.Spell,
  function(tooltip,data)
   local good=pcall(function()S:AnnotateTalentTooltip(tooltip,data)end)
   if not good then return end
  end)
 if not ok then return false,"Spell tooltip hook rejected by client" end
 hooked=true
 if GameTooltip and type(GameTooltip.HookScript)=="function" then
  pcall(GameTooltip.HookScript,GameTooltip,"OnHide",function(self)last[self]=nil end)
 end
 return true
end
