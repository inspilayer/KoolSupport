-- KS Afflictions public module data API. MIT-licensed original KoolSupport code.
-- DoT estimation originates in Joe Greive's DoesItDie tracker (Vendor/).
local _, ns = ...
KSAfflictions = KSAfflictions or {}
local A = KSAfflictions
A.API_VERSION = 1
-- All new installs use Modern KS, retaining the old display keys for upgrades.
A.DEFAULTS = { target=true, focus=true, nameplates=true, lethal=true,
  schoolColors=true, showLabels=true, showIcons=true, scale=1, height=15, offsetY=7,
  style="modern", lethalMode="dies", dotColor="purple",
  lethalTarget=true, lethalFocus=true, lethalNameplates=true }
A.ENUMS = {
  style={modern=true,classic=true,minimal=true},
  lethalMode={dies=true,skull=true,both=true,off=true},
  dotColor={purple=true,gold=true,red=true,school=true}
}
A.PALETTE = {purple={.7,.32,.92}, gold={.96,.73,.30}, red={.91,.32,.34}}
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
-- Per-character screen positions are separate from nameplate offsets and DoT data.
-- Only Target/Focus HUDs can be moved. Never read secret combat values.
local function validPosition(pos)
  return type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number"
    and pos.x==pos.x and pos.y==pos.y
    and math.abs(pos.x)<10000 and math.abs(pos.y)<10000
end
function A:HUDPosition(unit)
  if unit~="target" and unit~="focus" then return nil end
  local positions=self:Store().hudPositions
  if type(positions)~="table" then return nil end
  local pos=positions[unit]
  return validPosition(pos) and pos or nil
end
function A:SaveHUDPosition(unit,frame)
  if unit~="target" and unit~="focus" then return false,"Unsupported HUD" end
  if KoolSupport:IsInCombat() then return false,"Move HUDs outside combat" end
  if not frame or not UIParent then return false,"HUD unavailable" end
  local cx,cy=frame:GetCenter()
  local ux,uy=UIParent:GetCenter()
  local uiScale=UIParent:GetEffectiveScale()
  local frameScale=frame:GetEffectiveScale()
  if type(cx)~="number" or type(cy)~="number" or
     type(ux)~="number" or type(uy)~="number" or
     type(uiScale)~="number" or uiScale<=0 or
     type(frameScale)~="number" or frameScale<=0 then
    return false,"HUD geometry unavailable"
  end
  -- Convert the frame's scaled screen position into UIParent coordinates.
  local x=cx*frameScale/uiScale-ux
  local y=cy*frameScale/uiScale-uy
  local pos={x=math.floor(x+.5),y=math.floor(y+.5)}
  if not validPosition(pos) then return false,"HUD position invalid" end
  local db=self:Store()
  if type(db.hudPositions)~="table" then db.hudPositions={} end
  db.hudPositions[unit]=pos
  return true
end
function A:ResetHUDPosition(unit)
  if unit~="target" and unit~="focus" then return false,"Unsupported HUD" end
  if KoolSupport:IsInCombat() then return false,"Reset HUDs outside combat" end
  local db=self:Store()
  if type(db.hudPositions)=="table" then db.hudPositions[unit]=nil end
  if self.huds and self.huds[unit] and self.AnchorUnitHUD then
    self:AnchorUnitHUD(unit,self.huds[unit])
  end
  if self.RefreshAll then self:RefreshAll() end
  return true
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
  if self.ENUMS[key] then
    if type(value)~="string" or not self.ENUMS[key][value] then return false,"Invalid option" end
  elseif type(old)=="boolean" then
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
function A:DotColor(school)
  local mode=self:Store().dotColor
  if mode=="school" then return self:SchoolColor(school) end
  local c=self.PALETTE[mode] or self.PALETTE.purple
  return c[1],c[2],c[3]
end
function A:LethalOn(unit)
  local db=self:Store()
  if not db.lethal or db.lethalMode=="off" then return false end
  if unit=="target" then return db.lethalTarget end
  if unit=="focus" then return db.lethalFocus end
  return db.lethalNameplates
end
-- Integrators can use snapshots without loading KS Macros or KS Stealth.
function A:GetDoTs(unit) return self:Snapshot(unit) end
