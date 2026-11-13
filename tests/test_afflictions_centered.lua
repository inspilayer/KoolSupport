-- 0.10.9 text-only DIES: strict, attributable, fail-closed and nonintrusive.
local secret=setmetatable({},{
 __lt=function()error("compared protected health")end,
 __le=function()error("compared protected health")end,
 __eq=function()error("compared protected health")end,
 __tostring=function()error("formatted protected health")end,
})
issecretvalue=function(value)return rawequal(value,secret)end
KoolSupportDB={core={},modules={}}
local now=100
local enabled=true
KoolSupport={
 GetDatabase=function()return KoolSupportDB end,
 IsInCombat=function()return false end,
 IsModuleEnabled=function(_,id)return enabled and id=="ks_afflictions" end,
}
GetTime=function()return now end
local frames={}
local function mk(kind)
 local f={kind=kind or "Frame",hidden=false,values=0}
 function f:GetObjectType()return self.kind end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:SetShown(value)self.hidden=not value end
 function f:EnableMouse(value)self.mouse=value end
 function f:SetAllPoints(anchor)self.anchor=anchor end
 function f:SetPoint(...)self.point={...}end
 function f:SetSize(w,h)self.width=w;self.height=h end
 function f:SetFrameLevel(value)self.level=value end
 function f:GetFrameLevel()return self.level or 5 end
 function f:GetFrameStrata()return "MEDIUM" end
 function f:SetFrameStrata(value)self.strata=value end
 function f:CreateTexture()return mk("Texture")end
 function f:CreateFontString()return mk("FontString")end
 function f:SetText(value)self.text=value end
 function f:SetTextColor(...)self.color={...}end
 function f:SetAlpha(alpha)self.alpha=alpha end
 function f:SetShadowColor(...)self.shadow={...}end
 function f:SetShadowOffset(...)self.shadowOffset={...}end
 function f:SetFont(...)self.font={...}end
 function f:SetWidth(w)self.width=w end
 function f:SetJustifyH(v)self.justify=v end
 function f:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
 function f:SetScript(event,fn)self.scripts=self.scripts or {};self.scripts[event]=fn end
 function f:SetStatusBarTexture()self.nativeMutation=true end
 function f:SetMinMaxValues()self.nativeMutation=true end
 function f:SetValue()self.nativeMutation=true end
 function f:SetStatusBarColor()self.nativeMutation=true end
 return f
end
UIParent=mk()
CreateFrame=function(kind,_,parent)
 local f=mk(kind);f.parent=parent
 frames[#frames+1]=f
 return f
end
TargetFrame=mk();FocusFrame=mk()
TargetFrameHealthBar=mk("StatusBar")
FocusFrameHealthBar=mk("StatusBar")
local plateA={unitToken="nameplate1",UnitFrame={healthBar=mk("StatusBar")}}
local plateB={UnitFrame={HealthBar=mk("StatusBar")}}
function plateB:GetUnit()return "nameplate2" end
local plateUnsupported={unitToken="nameplate3",UnitFrame={healthBar=mk("Frame")}}
local visiblePlates={plateA,plateB,plateUnsupported}
C_NamePlate={GetNamePlates=function()return visiblePlates end}
local health={target=400,focus=850,nameplate1=900,nameplate2=400,nameplate3=150}
UnitHealth=function(unit)return health[unit] end
local maxHealth={target=1000,focus=2000,nameplate1=1000,nameplate2=1000,nameplate3=1000}
UnitHealthMax=function(unit)return maxHealth[unit] end
UnitExists=function(unit)return health[unit]~=nil end
UnitIsDeadOrGhost=function()return false end
UnitCanAttack=function(_,unit)return health[unit]~=nil end
local keys={target="guid-1",focus="guid-2",nameplate1="guid-3",
  nameplate2="guid-4",nameplate3="guid-5"}
local dots={}
local function dot(amount,expires)
 return {name="Rip",spellID=1234,school=1,damage=amount,expiresAt=expires or 130}
end
local function assign(unit,damage)
 dots[unit]={list=damage and {dot(damage)} or {},total=damage or 0}
end
assign("target",600)
assign("focus",200)
assign("nameplate1",500)
assign("nameplate2",550)
assign("nameplate3",500)
local flipKey=false
local counter=0
local ns={db={},tracking={
 unitKey=function(unit)
  if flipKey and unit=="target" then counter=counter+1;return "unstable-"..counter end
  return keys[unit]
 end,
 housekeep=function()end,
 },dotBreakdownForUnit=function(unit)
  local entry=dots[unit]
  if not entry then return {},0 end
  return entry.list,entry.total
 end}
assert(loadfile("addons/KSAfflictions/Afflictions.lua"))("KoolSupport",ns)
local A=KSAfflictions

-- Migration: new install/default-equivalent old profile -> centered DIES.
assert(A:Store().displayMode=="centered")
assert(A:Store().onFrame==false,"Do not rewrite legacy keys on first installation")
KoolSupportDB.modules.ks_afflictions={onFrame=true,style="modern"}
assert(A:Store().displayMode=="onframe","Explicit old on-frame choice survives")
KoolSupportDB.modules.ks_afflictions={onFrame=false,style="classic",hudPositions={target={x=11,y=12}}}
assert(A:Store().displayMode=="panels","Saved legacy panels/position survive")
assert(A:Store().hudPositions.target.x==11)
KoolSupportDB.modules.ks_afflictions={onFrame=false,style="modern"}
assert(A:Store().displayMode=="centered","Default-equivalent historical user migrates")
KoolSupportDB.modules.ks_afflictions={displayMode="panels",onFrame=false,customKey="keep"}
assert(A:Store().displayMode=="panels" and A:Store().customKey=="keep",
 "Explicit new-mode preference and unknown keys are preserved")
KoolSupportDB.modules.ks_afflictions={}
assert(A:Store().displayMode=="centered")
assert(not A:ChangeSetting("displayMode","unsupported"))
assert(A:ChangeSetting("displayMode","centered"))

local deferred={}
C_Timer={After=function(_,cb)deferred[#deferred+1]=cb end}
local function drain()
 while #deferred>0 do table.remove(deferred,1)() end
end
assert(loadfile("addons/KSAfflictions/Renderer.lua"))("KoolSupport",ns)
local driver=frames[#frames]
assert(driver.scripts.OnUpdate==nil,"Minimal renderer must not add its own polling OnUpdate")
for _,event in ipairs({"UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_AURA","UNIT_COMBAT",
 "PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","NAME_PLATE_UNIT_REMOVED"}) do
 assert(driver.events[event],"Missing event-driven invalidation: "..event)
end
-- Preserve independently owned KS Threat and KS Stealth frames.
local threatOverlay=mk("StatusBar")
local stealthOverlay=mk("Frame")
KSThreat={plates={[plateA]={overlay=threatOverlay}}}
KSStealth={plates={[plateB]={holder=stealthOverlay}}}

A:RefreshAll()
local target=A.minimalUnits.target
local lethalPlate=A.minimalPlates[plateB]
assert(target and target.active and not target.frame.hidden)
assert(target.word.text=="DIES" and target.word.point[1]=="CENTER")
assert(target.word.point[2]==target.frame)
assert(target.frame.anchor==TargetFrameHealthBar and target.frame.mouse==false)
assert(lethalPlate and lethalPlate.active and lethalPlate.frame.anchor==plateB.UnitFrame.HealthBar)
assert(not A.minimalUnits.focus or A.minimalUnits.focus.frame.hidden,
 "Nonlethal focus never displays DIES")
assert(not A.minimalPlates[plateA] or A.minimalPlates[plateA].frame.hidden,
 "Nonlethal nameplate never displays DIES")
assert(not A.minimalPlates[plateUnsupported],"Unsupported native bar must not get overlay")
assert(not A.huds.target and not A.plates[plateA],"Never create extra HUDs in centered mode")
assert(not TargetFrameHealthBar.nativeMutation and not FocusFrameHealthBar.nativeMutation)
assert(not plateA.UnitFrame.healthBar.nativeMutation and not plateB.UnitFrame.HealthBar.nativeMutation)
assert(KSThreat.plates[plateA].overlay==threatOverlay)
assert(KSStealth.plates[plateB].holder==stealthOverlay)

-- Secret health must be opaque, never compared, and hides existing label.
health.target=secret
A:RefreshAll()
assert(not target.active and target.frame.hidden)
health.target=400
A:RefreshAll()
assert(target.active)
-- The restricted Curve:EvaluateUnpacked(secretUnitHealth) path is intentionally
-- NEVER used. Native UnitHealthPercent(unit,false,curve) evaluates the curve
-- inside WoW before returning a protected alpha to Region:SetAlpha.
local secretRawHealth=350
local computedAlpha
local protectedAlpha=setmetatable({},{
 __lt=function()error("compared secret alpha")end,
 __le=function()error("compared secret alpha")end,
 __tostring=function()error("formatted secret alpha")end,
})
Enum={LuaCurveType={Step="STEP"}}
C_CurveUtil={CreateCurve=function()
 local c={points={}}
 function c:SetType(t)self.kind=t end
 function c:AddPoint(x,y)self.points[#self.points+1]={x=x,y=y}end
 function c:Evaluate()error("Tainted code must not call curve evaluator")end
 return c
end}
UnitHealthPercent=function(unit,predicted,curve)
 assert(unit=="target" and predicted==false,"Native health percent called for correct unit")
 assert(curve.kind==Enum.LuaCurveType.Step and #curve.points==3,
  "Native percent curve must be a corpse-safe step")
 local p=secretRawHealth/1000
 computedAlpha=p<curve.points[2].x and curve.points[1].y
   or (p<curve.points[3].x and curve.points[2].y or curve.points[3].y)
 return protectedAlpha
end
maxHealth.target=secret
health.target=secret
A:RefreshAll()
assert(target.active and target.mode=="native_percent_applied"
  and target.word.alpha==protectedAlpha and computedAlpha==1,
 "Client-style native curve is applied without inspecting opaque alpha")
-- Forever may hide GUIDs in combat; vendor deliberately falls back to
-- "target" even for the SAME selected mob. Event boundaries, not opaque GUID
-- changes alone, invalidate a previously captured readable max.
keys.target="target"
A:RefreshAll()
assert(target.active and A:KnownMax("target")==1000 and computedAlpha==1,
 "Secret GUID fallback for unchanged target must preserve precombat max")
keys.target="guid-1"
A:RefreshAll()
assert(target.active and A:KnownMax("target")==1000)

secretRawHealth=0
A:RefreshAll()
assert(computedAlpha==0,"Zero HP must suppress DIES in native evaluator")
-- A protected dead flag must not block a living unit when native zero guard works.
UnitIsDeadOrGhost=function()return secret end
secretRawHealth=350
A:RefreshAll()
assert(target.active and computedAlpha==1,"Secret death flag is handled by native zero alpha")
UnitIsDeadOrGhost=function()return false end
secretRawHealth=1000
A:RefreshAll()
assert(computedAlpha==0,"Nonlethal secret health is transparent")
secretRawHealth=600
A:RefreshAll()
assert(computedAlpha==0,"Equal predicted health is conservatively transparent")
secretRawHealth=350
A:ForgetKnownMax("target")
A:RefreshAll()
assert(target.frame.hidden and A.minimalReasons.target=="max_baseline_unavailable",
 "If secret max cannot be validated, no lethal label is allowed")
maxHealth.target=1000
A:RefreshAll()
assert(target.active and A:KnownMax("target")==1000,
 "Restored readable max enables threshold calculation")
-- A client refusing the safe UnitHealthPercent evaluation must fail closed.
local previousPercent=UnitHealthPercent
UnitHealthPercent=function()error("protected percent not supported")end
A:RefreshAll()
assert(target.frame.hidden and A.minimalReasons.target=="native_percent_rejected")
UnitHealthPercent=previousPercent
C_CurveUtil=nil
A:RefreshAll()
assert(target.frame.hidden,"Unsupported percent curve must fail closed")
health.target=400
A:RefreshAll()
assert(target.active)
-- Healing and an estimate dropping below health hide the word.
health.target=800
A:RefreshAll()
assert(target.frame.hidden,"Healing above total future DoT damage must clear DIES")
health.target=400
assign("target",100)
A:RefreshAll()
assert(target.frame.hidden,"Sublethal revised estimate clears the word")
assign("target",600)
A:RefreshAll()
assert(target.active)
-- Expired / uncertain / provisional damage cannot render as a guaranteed kill.
dots.target.list[1].expiresAt=99
A:RefreshAll()
assert(target.frame.hidden)
assign("target",600)
dots.target.list[1].provisional=true
A:RefreshAll()
assert(target.frame.hidden)
assign("target",600)
A:RefreshAll()
assert(target.active)
flipKey=true
A:RefreshAll()
assert(target.frame.hidden,"Attribution changing mid-read must fail closed")
flipKey=false
A:RefreshAll()
assert(target.active)
local oldChecker=issecretvalue
issecretvalue=nil
A:RefreshAll()
assert(target.frame.hidden,"No secret checker means no trusted lethal comparison")
issecretvalue=oldChecker
A:RefreshAll()
assert(target.active)

-- A different focus has independent attribution, health and overlay.
health.focus=100
A:RefreshAll()
local focus=A.minimalUnits.focus
assert(focus and focus.active and focus.frame.anchor==FocusFrameHealthBar)
assert(A.minimalUnits.target.active)
keys.focus=nil
A:RefreshAll()
assert(focus.frame.hidden,"Unknown GUID / plate attribution cannot claim lethality")
keys.focus="guid-2"
A:RefreshAll()
assert(focus.active)
-- Clearing a target must hide its label before deferred rendering.
driver.scripts.OnEvent(nil,"PLAYER_TARGET_CHANGED")
assert(target.frame.hidden)
assign("target",nil) -- vendor clears the secret-GUID fallback on target change
drain()
assert(target.frame.hidden)
assign("target",600)
A:RefreshAll()
assert(target.active)

-- Reused/missing nameplates must never inherit an old DIES word.
driver.scripts.OnEvent(nil,"NAME_PLATE_UNIT_REMOVED","nameplate2")
assert(lethalPlate.frame.hidden)
visiblePlates={plateA,plateUnsupported}
drain()
assert(lethalPlate.frame.hidden)
A:RefreshAll()
assert(lethalPlate.frame.hidden)
visiblePlates={plateA,plateB,plateUnsupported}
health.nameplate2=750
A:RefreshAll()
assert(lethalPlate.frame.hidden)
health.nameplate2=400
A:RefreshAll()
assert(lethalPlate.active)
enabled=false
A:RefreshAll()
assert(target.frame.hidden and focus.frame.hidden and lethalPlate.frame.hidden)
assert(KSThreat.plates[plateA].overlay==threatOverlay and not threatOverlay.hidden)
assert(KSStealth.plates[plateB].holder==stealthOverlay and not stealthOverlay.hidden)
-- An explicit diagnostic must expose the independent tracker estimate and a
-- categorical protected-health state, NEVER the secret HP value itself.
health.target=secret
local report=A:DiagnosticLine("target")
assert(report:find("HP secret",1,true) and report:find("estimated 600",1,true))
assert(report:find("gate ready",1,true))
assert(not report:find("guid-",1,true),"Do not print internal creature identifiers")
assert(A:DiagnosticLine("player")=="invalid unit")
UnitIsDeadOrGhost=function()return true end
local total,reason=A:LethalEvidence("target")
assert(total==nil and reason=="dead_unit","Known dead units cannot show DIES")

print("PASS centered DIES: migration, attribution, secrets, expiry, healing, bars, event/compatibility")
