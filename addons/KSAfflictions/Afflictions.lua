-- KS Afflictions public module data API. MIT-licensed original KoolSupport code.
-- DoT estimation originates in Joe Greive's DoesItDie tracker (Vendor/).
local _, ns = ...
KSAfflictions = KSAfflictions or {}
local A = KSAfflictions
A.API_VERSION = 1
-- Centered DIES is the default; historical visual preferences are retained.
A.DEFAULTS = { target=true, focus=true, nameplates=true, lethal=true, onFrame=false, displayMode="centered",
  schoolColors=true, showLabels=true, showIcons=true, scale=1, height=15, offsetY=7,
  style="modern", lethalMode="dies", dotColor="purple",
  lethalTarget=true, lethalFocus=true, lethalNameplates=true }
A.ENUMS = {
  displayMode={centered=true,onframe=true,panels=true},
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
  -- There was no explicit mode key before 0.10.9: onFrame=false was written
  -- automatically even for users who never chose it. Preserve detectable
  -- deliberate advanced choices, and migrate default-equivalent saves to DIES.
  if mine.displayMode==nil then
    local advanced=mine.style~=nil and mine.style~="modern"
      or (mine.dotColor~=nil and mine.dotColor~="purple")
      or (mine.lethalMode~=nil and mine.lethalMode~="dies")
      or (mine.showIcons==false or mine.showLabels==false)
      or (mine.scale~=nil and mine.scale~=1)
      or (mine.height~=nil and mine.height~=15)
      or (mine.offsetY~=nil and mine.offsetY~=7)
      or (type(mine.hudPositions)=="table"
          and (mine.hudPositions.target~=nil or mine.hudPositions.focus~=nil))
    if mine.onFrame==true then mine.displayMode="onframe"
    elseif advanced then mine.displayMode="panels"
    else mine.displayMode="centered" end
  end
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

-- Strict visibility decision for the text-only display. A clipping StatusBar
-- cannot reliably convert secret health into an exact Lua-visible Boolean.
-- We NEVER compare secret values, and we NEVER assume that a partial fill is
-- lethal. Secret/unsupported health therefore results in no label.
local function readable(value)
  if type(issecretvalue)~="function" then return false end
  local ok,hidden=pcall(issecretvalue,value)
  return ok and hidden==false
end
local function knownCall(fn,...)
  if type(fn)~="function" then return nil,false end
  local ok,value=pcall(fn,...)
  if not ok or not readable(value) then return nil,false end
  return value,true
end
local function finiteNumber(n)
  return type(n)=="number" and n==n and n>=0 and n<math.huge
end
-- Shared *public* confidence gate. This never opens enemy health in Lua.
-- It only inspects our own tracker estimates and nonsecret unit identity.
-- Native color curves may subsequently use opaque UnitHealth as widget input.
function A:LethalEvidence(unit)
  if unit~="target" and unit~="focus"
    and (type(unit)~="string" or not unit:match("^nameplate%d+$")) then
    return nil,"invalid_unit"
  end
  if not self:TrackerReady() or not self:LethalOn(unit) then
    return nil,"disabled"
  end
  local exists,valid=knownCall(UnitExists,unit)
  if not valid or exists~=true then return nil,"unit_unavailable" end
  local hostile,hostileKnown=knownCall(UnitCanAttack,"player",unit)
  if not hostileKnown or hostile~=true then return nil,"not_confirmed_hostile" end
  -- The dead flag may itself be secret or unavailable on Forever. Reject a
  -- *confirmed* dead unit; don't reject every living unit simply because the
  -- boolean is protected. The renderer independently makes alpha ZERO for
  -- raw health 0 using a native Step ColorCurve, or checks nonsecret HP > 0.
  if type(UnitIsDeadOrGhost)=="function" then
    local dead,deadKnown=knownCall(UnitIsDeadOrGhost,unit)
    if deadKnown and dead==true then return nil,"dead_unit" end
  end
  if type(ns.tracking)~="table" or type(ns.tracking.unitKey)~="function" then
    return nil,"identity_unavailable"
  end
  local key,keyKnown=knownCall(ns.tracking.unitKey,unit)
  if not keyKnown or type(key)~="string" or key=="" then
    return nil,"identity_unavailable"
  end
  if key=="target" and unit~="target" then return nil,"identity_unavailable" end
  local dots,total=self:Snapshot(unit)
  if #dots==0 or not readable(total) or not finiteNumber(total) or total<=0 then
    return nil,"no_estimate"
  end
  local now,timeKnown=knownCall(GetTime)
  if not timeKnown or not finiteNumber(now) then return nil,"time_unavailable" end
  local sum=0
  for _,dot in ipairs(dots) do
    if type(dot)~="table" or dot.provisional
      or not readable(dot.damage) or not finiteNumber(dot.damage)
      or not readable(dot.expiresAt) or not finiteNumber(dot.expiresAt)
      or dot.expiresAt<=now then return nil,"untrusted_estimate" end
    sum=sum+dot.damage
  end
  if not finiteNumber(sum) or math.abs(sum-total)>0.01 then
    return nil,"untrusted_estimate"
  end
  local after,afterKnown=knownCall(ns.tracking.unitKey,unit)
  if not afterKnown or after~=key then return nil,"identity_changed" end
  return total,"ready"
end

-- For clients exposing *readable* health, direct comparison is safe after
-- checking issecretvalue. For secret health the renderer uses UnitHealthPercent's built-in curve
-- evaluator only when a verified nonsecret maximum HP was cached beforehand.
function A:ConfirmedLethal(unit)
  local total=self:LethalEvidence(unit)
  if not total then return false end
  local health,known=knownCall(UnitHealth,unit)
  if not known or not finiteNumber(health) or health<=0 then return false end
  return total>=health
end

-- Read-only, user-triggered diagnostic. Every displayed number is from our
-- player-owned DoT model, NEVER from enemy health. Only the categorical
-- issecretvalue result is reported. No GUID, unit name or secret RGBA output.
function A:DiagnosticLine(unit)
  if unit~="target" and unit~="focus" and
    (type(unit)~="string" or not unit:match("^nameplate%d+$")) then
    return "invalid unit"
  end
  local dots,damage=self:Snapshot(unit)
  local count=type(dots)=="table" and #dots or 0
  local estimate="unavailable"
  if readable(damage) and finiteNumber(damage) then
    estimate=tostring(math.floor(damage+.5))
  end
  local _,gate=self:LethalEvidence(unit)
  local mode="unknown"
  if type(UnitHealth)=="function" and type(issecretvalue)=="function" then
    local ok,hp=pcall(UnitHealth,unit)
    if ok then
      local checked,hidden=pcall(issecretvalue,hp)
      if checked then mode=hidden and "secret" or "readable" end
    end
  end
  local stage=self.minimalReasons and self.minimalReasons[unit] or "not_rendered"
  local label=unit=="target" and "Target"
    or unit=="focus" and "Focus" or "Plate"
  -- Unit token indexes are deliberately not logged; these fields cannot
  -- identify a player or creature and contain no secret health.
  local calibrated=self.KnownMax and self:KnownMax(unit)~=nil
  return label..": "..count.." DoT, estimated "..estimate..
    " remaining; HP "..mode.."; max baseline "..(calibrated and "ready" or "missing")..
    "; gate "..(gate or "ready").."; display "..stage
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
  local mine=self:Store()
  mine[key]=value
  -- Backward-compatible old toggle for callers that still use onFrame.
  if key=="onFrame" then mine.displayMode=value and "onframe" or "panels" end
  if key=="displayMode" then mine.onFrame=(value=="onframe") end
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
