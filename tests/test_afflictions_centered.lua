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
assert(not A.minimalUnits.focus,"Nonlethal focus gets no overlay")
assert(not A.minimalPlates[plateA],"Nonlethal nameplate gets no overlay")
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
-- WoW native color curves can display a conditional alpha from SECRET health
-- without ever returning the numeric health to Lua. The MOCK below owns its
-- hidden input; production addon code must only pass the opaque value through.
local secretRawHealth=350
CreateColor=function(r,g,b,a)return {r=r,g=g,b=b,a=a} end
Enum={LuaCurveType={Step="STEP"}}
C_CurveUtil={CreateColorCurve=function()
 local curve={points={}}
 function curve:SetType(kind)self.kind=kind end
 function curve:AddPoint(x,color)self.points[#self.points+1]={x=x,color=color} end
 function curve:EvaluateUnpacked(value)
  assert(rawequal(value,secret),"Native curve must receive secret health untouched")
  assert(self.kind==Enum.LuaCurveType.Step and #self.points==3,
   "Native non-interpolating threshold must also hide dead units")
  local color=secretRawHealth<self.points[2].x and self.points[1].color
    or (secretRawHealth<self.points[3].x and self.points[2].color or self.points[3].color)
  return color.r,color.g,color.b,color.a
 end
 return curve
end}
health.target=secret
A:RefreshAll()
assert(target.active and target.mode=="native_curve_applied" and target.word.color[4]==1,
 "Client-supported curve shows a lethal enemy without comparing secret health")
-- A protected/unavailable death flag MUST NOT hide a living enemy merely
-- because WoW keeps its boolean secret. The native curve handles 0 HP.
UnitIsDeadOrGhost=function()return secret end
A:RefreshAll()
assert(target.active and target.word.color[4]==1,
 "Secret dead flag must not preempt native health curve")
secretRawHealth=0
A:RefreshAll()
assert(target.word.color[4]==0,"Dead enemy health must suppress DIES natively")
secretRawHealth=350
UnitIsDeadOrGhost=function()return false end
secretRawHealth=1000
A:RefreshAll()
assert(target.active and target.word.color[4]==0,
 "Native step curve must hide a secret-health nonlethal enemy")
secretRawHealth=600
A:RefreshAll()
assert(target.word.color[4]==0,"Exact threshold is intentionally hidden to avoid boundary false positives")
secretRawHealth=350
C_CurveUtil=nil
A:RefreshAll()
assert(target.frame.hidden,"No native curve support must fail closed even when tracked DoTs are strong")
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
