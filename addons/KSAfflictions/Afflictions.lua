-- KS Afflictions public module data API. MIT-licensed original KoolSupport code.
-- DoT estimation originates in Joe Greive's DoesItDie tracker (Vendor/).
local _, ns = ...
KSAfflictions = KSAfflictions or {}
local A = KSAfflictions
A.API_VERSION = 1
A.DEFAULTS = { target=true, focus=true, nameplates=true, lethal=true,
  schoolColors=true, showLabels=true, scale=1, height=15, offsetY=7 }
A.COLORS = { [1]={1,.37,.4}, [2]={1,.83,.36}, [4]={1,.45,.22}, [8]={.25,.91,.54},
 [16]={.39,.73,1}, [32]={.74,.5,1}, [64]={.60,.68,1} }
function A:Store()
  local db = KoolSupport:GetDatabase()
  db.modules = db.modules or {}
  db.modules.ks_afflictions = db.modules.ks_afflictions or {}
  local mine = db.modules.ks_afflictions
  for k,v in pairs(self.DEFAULTS) do if mine[k]==nil then mine[k]=v end end
  return mine
end
function A:TrackerReady()
  return ns.db~=nil and type(ns.dotBreakdownForUnit)=="function"
end
-- Only safe, player-owned DoT data is returned. UnitHealth remains secret in Forever;
-- no Lua arithmetic on target health is ever performed.
function A:Snapshot(unit)
  if not self:TrackerReady() or type(unit)~="string" then return {},0 end
  local ok, dots, total = pcall(ns.dotBreakdownForUnit, unit)
  if not ok or type(dots)~="table" or type(total)~="number" then return {},0 end
  return dots,total
end
function A:ChangeSetting(key,value)
  if KoolSupport:IsInCombat() then return false,"Change display settings outside combat" end
  if self.DEFAULTS[key]==nil then return false,"Unknown option" end
  local old=self.DEFAULTS[key]
  if type(old)=="boolean" then
    if type(value)~="boolean" then return false,"Expected a toggle" end
  elseif type(value)~="number" then return false,"Expected a number"
  elseif key=="scale" then value=math.max(.65,math.min(1.65,value))
  elseif key=="height" then value=math.max(9,math.min(25,value))
  elseif key=="offsetY" then value=math.max(-20,math.min(50,value))
  end
  self:Store()[key]=value
  if self.RefreshAll then self:RefreshAll() end
  return true
end
function A:SchoolColor(school)
  if self:Store().schoolColors and self.COLORS[school] then
    local c=self.COLORS[school]
    return c[1],c[2],c[3]
  end
  return .99,.70,.28
end
-- Integrators can use snapshots without loading KS Macros or KS Stealth.
function A:GetDoTs(unit) return self:Snapshot(unit) end
