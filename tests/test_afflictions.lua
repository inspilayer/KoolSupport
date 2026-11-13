-- KS Afflictions offline contract: independent data, opaque health passthrough, toggles.
KoolSupportDB={core={},modules={ks_afflictions={displayMode="panels"}}}
local combat=false
KoolSupport={
 GetDatabase=function()return KoolSupportDB end,
 IsInCombat=function()return combat end,
 IsModuleEnabled=function(_,id)return id=="ks_afflictions" end,
 RegisterModule=function(self,d)self.module=d end,
 RegisterPage=function(self,d)self.page=d end,
}
local secret=setmetatable({},{
 __lt=function()error("secret health compared")end,
 __le=function()error("secret health compared")end,
 __eq=function()error("secret health compared")end,
 __tostring=function()error("secret health formatted")end,
})
issecretvalue=function(value)return rawequal(value,secret)end
local uiButtons={}
local uiChecks={}
local uiLabels={}
local function mk(kind)
 local f={hidden=false,kind=kind or "Frame"}
 local function stub()end
 function f:SetSize(w,h)self.width=w;self.height=h end
 function f:SetHeight(v)self.height=v end
 function f:SetPoint(...)self.point={...}end
 function f:ClearAllPoints()self.point=nil end
 function f:GetCenter()return self.centerX or 960,self.centerY or 540 end
 function f:GetEffectiveScale()return self.effectiveScale or 1 end
 function f:StartMoving()self.moving=true end
 function f:StopMovingOrSizing()self.moving=false end
 function f:SetAllPoints(anchor)self.allPoints=anchor end
 function f:GetObjectType()return self.kind end
 function f:SetStatusBarTexture()end
 function f:SetStatusBarColor(...)self.color={...}end
 function f:SetMinMaxValues(min,max)self.min=min;self.max=max end
 function f:SetValue(value)self.value=value end
 function f:SetText(t)self.text=t end
 function f:SetChecked(v)self.checked=v end
 function f:GetChecked()return self.checked end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:SetShown(x)self.hidden=not x end
 function f:SetScale(scale)self.scale=scale end
 function f:EnableMouse(value)self.mouseEnabled=value end
 function f:RegisterEvent()end
 function f:SetScript(event,handler)self.scripts=self.scripts or {};self.scripts[event]=handler end
 function f:CreateTexture()return mk()end
 function f:CreateFontString()
  local item=mk("FontString")
  uiLabels[#uiLabels+1]=item
  return item
 end
 function f:GetStatusBarTexture()return mk()end
 return setmetatable(f,{__index=function(_,key)
  if type(key)=="string" and (key:match("^Set") or key:match("^Get") or key:match("^Register") or key:match("^Clear")) then return stub end
  return nil
 end})
end
CreateFrame=function(kind)
 local item=mk(kind)
 if kind=="Button" then uiButtons[#uiButtons+1]=item end
 if kind=="CheckButton" then uiChecks[#uiChecks+1]=item end
 return item
end
UIParent=mk();TargetFrame=mk();FocusFrame=mk()
TargetFrameHealthBar=mk("StatusBar");FocusFrameHealthBar=mk("StatusBar")
local readableHealth=secret
UnitHealth=function()return readableHealth end
UnitCanAttack=function(_,unit)return true end
UnitHealthMax=function()return secret end
UnitExists=function()return true end
UnitIsDeadOrGhost=function()return false end
GetTime=function()return 100 end
local plate=mk();plate.namePlateUnitToken="nameplate1"
C_NamePlate={GetNamePlates=function()return {plate}end}
local dots={{name="Rip",spellID=1234,school=1,expiresAt=110,damage=600}}
C_Spell={GetSpellTexture=function(id) if id==1234 then return "Interface\\\\Icons\\\\Ability_GhoulFrenzy" end end}
local ns={db={},tracking={housekeep=function()end,unitKey=function(unit)return "guid-"..unit end},
 dotBreakdownForUnit=function(unit)
  assert(unit=="target" or unit=="focus" or unit=="nameplate1")
  return dots,600
 end}
assert(loadfile("addons/KSAfflictions/TrackerBridge.lua"))("KSAfflictions",ns)
assert(ns.display and ns.refresh and ns.registerOptions)
assert(loadfile("addons/KSAfflictions/Afflictions.lua"))("KSAfflictions",ns)
local A=KSAfflictions
local list,total=A:GetDoTs("target")
assert(#list==1 and total==600)
assert(A:Store().nameplates and A:Store().lethal)
assert(A:Store().style=="modern","new installs default to Modern KS")
assert(A:Store().dotColor=="purple" and A:Store().lethalMode=="dies")
assert(A:Store().showIcons and A:Store().lethalNameplates)
assert(A:ChangeSetting("style","classic"))
assert(A:Store().style=="classic")
assert(A:ChangeSetting("style","minimal"))
assert(A:ChangeSetting("style","modern"))
assert(not A:ChangeSetting("style","rainbow"),"invalid styles are rejected")
assert(A:ChangeSetting("lethalMode","skull"))
assert(A:ChangeSetting("lethalMode","both"))
assert(A:ChangeSetting("lethalMode","dies"))
assert(not A:ChangeSetting("lethalMode","destroy"),"invalid lethal modes rejected")
assert(A:ChangeSetting("dotColor","red"))
assert(A:ChangeSetting("dotColor","school"))
assert(A:ChangeSetting("dotColor","purple"))
local red,green,blue=A:DotColor(1)
assert(red==.7 and green==.32 and blue==.92)
assert(A:LethalOn("target") and A:LethalOn("focus") and A:LethalOn("nameplate1"))
assert(A:ChangeSetting("lethalNameplates",false))
assert(not A:LethalOn("nameplate1"))
assert(A:ChangeSetting("lethalNameplates",true))
assert(A:ChangeSetting("scale",5))
assert(A:Store().scale==1.65)
assert(A:ChangeSetting("scale",1))
assert(A:ChangeSetting("height",20))
assert(not A:ChangeSetting("invalid",1))
combat=true
assert(not A:ChangeSetting("nameplates",false),"combat must block settings")
combat=false
assert(loadfile("addons/KSAfflictions/Renderer.lua"))("KSAfflictions",ns)
assert(loadfile("addons/KSAfflictions/UI.lua"))("KSAfflictions",ns)
assert(loadfile("addons/KSAfflictions/Module.lua"))("KSAfflictions",ns)
assert(KoolSupport.module.id=="ks_afflictions")
assert(#KoolSupport.module.requires==0)
assert(KoolSupport.page.id=="afflictions")
A:RefreshAll()
assert(A.huds.target.health.value==secret,"secret must pass untouched to StatusBar")
assert(A.huds.target.dot.value==600)
assert(A.plates[plate].dot.value==600)
assert(A.huds.target.lethalWord.hidden==true,
  "Legacy displays must never show DIES for secret health")
assert(A.plates[plate].lethalWord.hidden==true)
-- Legacy advanced modes must use the SAME opaque native alpha path as
-- DIES-only when Forever protects enemy health.
CreateColor=function(r,g,b,a)return {r=r,g=g,b=b,a=a} end
Enum={LuaCurveType={Step="STEP"}}
local nativeHiddenHealth=300
C_CurveUtil={CreateColorCurve=function()
 local curve={points={}}
 function curve:SetType(t)self.kind=t end
 function curve:AddPoint(x,color)self.points[#self.points+1]={x=x,color=color} end
 function curve:EvaluateUnpacked(hp)
  assert(rawequal(hp,secret),"Secret must flow untouched into native curve")
  assert(#self.points==3 and self.points[1].color.a==0,
   "Zero health must always hide a DIES label")
  local color=nativeHiddenHealth==0 and self.points[1].color
    or (nativeHiddenHealth<self.points[3].x and self.points[2].color
      or self.points[3].color)
  return color.r,color.g,color.b,color.a
 end
 return curve
end}
A:RefreshAll()
assert(not A.huds.target.lethalWord.hidden and not A.plates[plate].lethalWord.hidden,
 "Legacy panel/nameplate alerts must accept native secret colors")
assert(A.huds.target.lethalWord.color==nil or A.huds.target.lethalWord.color[4]~=nil)
-- A real native widget may carry secret color values, so only the mock's
-- internal calculated alpha is visible to this test.
nativeHiddenHealth=1000
A:RefreshAll()
assert(not A.huds.target.lethalWord.hidden,
 "The client, not Lua, decides secret-health alpha")
C_CurveUtil=nil
A:RefreshAll()
assert(A.huds.target.lethalWord.hidden,"Without native support fail closed")
readableHealth=400
A:RefreshAll()
assert(not A.huds.target.lethalWord.hidden,
  "Readably lethal estimate should enable legacy DIES")
assert(A.huds.target.lethalWord.point[1]=="CENTER" and
  A.huds.target.lethalWord.point[2]==A.huds.target.health,
  "Panel DIES should be centered on its own health bar, not off to the right")
assert(not A.plates[plate].lethalWord.hidden and
  A.plates[plate].lethalWord.point[2]==A.plates[plate].health,
  "Legacy nameplate alert stays centered on its own health bar")
assert(A.huds.target.lethalIcon.hidden)
assert(A:ChangeSetting("lethalMode","skull"))
assert(A.huds.target.lethalWord.hidden)
assert(not A.huds.target.lethalIcon.hidden)
assert(A:ChangeSetting("lethalMode","both"))
assert(not A.huds.target.lethalWord.hidden and not A.huds.target.lethalIcon.hidden)
assert(A:ChangeSetting("lethalMode","off"))
assert(A.huds.target.lethalWord.hidden and A.huds.target.lethalIcon.hidden)
assert(A:ChangeSetting("lethalMode","dies"))
assert(A:ChangeSetting("lethalTarget",false))
assert(A.huds.target.lethalWord.hidden)
assert(not A.plates[plate].lethalWord.hidden)
assert(A:ChangeSetting("lethalTarget",true))

-- Independent, per-character Target/Focus dragging. Never move nameplate HUDs.
local target=A.huds.target
local focus=A.huds.focus
assert(target.dragHandle and focus.dragHandle,"Both unit HUDs need a drag title")
assert(not A.plates[plate].dragHandle,"Nameplates must not be draggable")
assert(target.point[1]=="TOP" and target.point[2]==TargetFrame,"Existing default target anchor preserved")
assert(not A:HUDPosition("target"),"Default is not written until the user moves it")
target.dragHandle.scripts.OnDragStart()
assert(target.moving,"User drag should start outside combat")
target.centerX=1075
target.centerY=585
target.dragHandle.scripts.OnDragStop()
assert(not target.moving)
assert(A:HUDPosition("target").x==115 and A:HUDPosition("target").y==45)
assert(target.point[1]=="CENTER" and target.point[2]==UIParent)
assert(target.point[4]==115 and target.point[5]==45)
assert(not A:HUDPosition("focus"),"Target and Focus must not share positions")
local saved=KoolSupportDB.modules.ks_afflictions.hudPositions.target
A:RefreshAll()
assert(A:HUDPosition("target")==saved,"Frequent refresh must preserve saved HUD position")
-- Simulate reloading the renderer while retaining per-character SavedVariables.
A.huds.target=nil
local restored=A:EnsureUnit("target")
assert(restored.point[1]=="CENTER" and restored.point[4]==115 and restored.point[5]==45,
  "A fresh HUD must restore the stored position")
combat=true
restored.dragHandle.scripts.OnDragStart()
assert(not restored.moving,"Drag must not start in combat")
restored.dragHandle.scripts.OnDragStop()
assert(A:HUDPosition("target")==saved,"Combat cannot overwrite position")
assert(not A:ResetHUDPosition("target"),"Reset is blocked in combat")
combat=false
assert(A:ResetHUDPosition("target"))
assert(not A:HUDPosition("target"))
assert(restored.point[1]=="TOP" and restored.point[2]==TargetFrame)
assert(not A:SaveHUDPosition("nameplate1",restored),"Nameplates cannot save screen positions")
assert(A:ResetHUDPosition("focus"),"Focus reset works independently")
-- Malformed saved positions fail closed without crashing or changing root keys.
KoolSupportDB.modules.ks_afflictions.hudPositions.target={x=0/0,y=400}
assert(not A:HUDPosition("target"))
A:AnchorUnitHUD("target",restored)
assert(restored.point[1]=="TOP")
KoolSupportDB.modules.ks_afflictions.hudPositions.target=nil

-- Opt-in simplified overlay attaches to stock target/focus health bars without modifying them.
assert(not A:Store().onFrame,"New and upgraded characters keep movable panels by default")
assert(A:ChangeSetting("onFrame",true))
local onTarget=A.onFrameHUDs.target
local onFocus=A.onFrameHUDs.focus
assert(onTarget and onFocus,"Both unit health bars get independent overlays")
assert(onTarget.allPoints==TargetFrameHealthBar and onFocus.allPoints==FocusFrameHealthBar)
assert(not A.onFrameHUDs.nameplate1,"Nameplate HUDs stay independent")
assert(onTarget.dot.value==600 and onTarget.dot.max==secret,"Estimated damage uses a separate StatusBar with opaque health max")
assert(not onTarget.lethalWord.hidden,"Verified readable lethal estimate should show DIES")
assert(onTarget.lethalWord.point[1]=="CENTER" and
  onTarget.lethalWord.point[2]==onTarget,
  "On-frame alert must be centered INSIDE the native health-bar overlay")
assert(not onTarget.icons[1].hidden and onTarget.icons[2].hidden)
assert(A.huds.target.hidden and A.huds.focus.hidden,"On-frame replaces bulky unit panels")
assert(not A.plates[plate].hidden,"Nameplate options stay unchanged")
assert(TargetFrameHealthBar.value==nil and FocusFrameHealthBar.value==nil,
  "Never modify Blizzard health-bar values")
assert(A:ChangeSetting("showIcons",false))
assert(onTarget.icons[1].hidden,"On-frame icons honor existing settings")
assert(A:ChangeSetting("showIcons",true))
assert(A:ChangeSetting("target",false))
assert(onTarget.hidden,"Turning Target off hides only its overlay")
assert(not onFocus.hidden,"Focus remains visible")
assert(A:ChangeSetting("target",true))
-- A client with no known Focus health StatusBar must retain the movable HUD.
FocusFrameHealthBar=nil
A:RefreshAll()
assert(onFocus.hidden and not A.huds.focus.hidden,"Missing native bar gracefully falls back")
FocusFrameHealthBar=mk("StatusBar")
A:RefreshAll()
assert(onFocus.allPoints==FocusFrameHealthBar and A.huds.focus.hidden,
  "Recovered native bar restores the compact display")
assert(A:ChangeSetting("onFrame",false))
assert(onTarget.hidden and onFocus.hidden,"Legacy mode hides both new overlays")
assert(not A.huds.target.hidden and not A.huds.focus.hidden,"Legacy panels remain intact")
combat=true
assert(not A:ChangeSetting("onFrame",true),"Combat must block mode changes")
combat=false
assert(A:ChangeSetting("nameplates",false))
assert(A.plates[plate].hidden)

-- Clean settings: the default page uses radio/checkboxes, and advanced buttons
-- live in a separate hidden view rather than all being actionable at once.
local before=#uiButtons
local beforeChecks=#uiChecks
local beforeLabels=#uiLabels
A.BuildPage(mk())
local function findButton(term)
 for i=before+1,#uiButtons do
  local b=uiButtons[i]
  if type(b.text)=="string" and b.text:find(term,1,true) then return b end
 end
end
local function findCheck(key,value)
 for i=beforeChecks+1,#uiChecks do
  local c=uiChecks[i]
  if c.ksKey==key and (value==nil or c.ksValue==value) then return c end
 end
end
local centered=findCheck("displayMode","centered")
assert(centered,"DIES-only mode must be a visible native checkbox/radio")
assert(centered.point[5]==-161 and centered.checked==false)
assert(findCheck("target") and findCheck("focus") and findCheck("nameplates")
 and findCheck("lethal"),"Simple view should expose only essential location toggles")
assert(#uiChecks-beforeChecks<=15,"Avoid a huge grid of simultaneous toggle buttons")
local advanced=findButton("Advanced settings")
assert(advanced,"The compact simple UI must have one advanced entry point")
centered.scripts.OnClick()
assert(A:Store().displayMode=="centered" and centered.checked,
  "Choosing DIES-only updates saved mode and visual selection")
local targetToggle=findCheck("target")
targetToggle.scripts.OnClick()
assert(not A:Store().target and not targetToggle.checked)
targetToggle.scripts.OnClick()
assert(A:Store().target and targetToggle.checked)
advanced.scripts.OnClick()
local back=findButton("Back to simple settings")
assert(back and back.scripts.OnClick,"Advanced view must have a usable way back")
assert(findButton("Reset Target") and findButton("Reset Focus"),
  "Legacy saved panel positions remain controllable in advanced settings")
local barCycle=findButton("Bar style")
assert(barCycle,"Advanced bar look is a compact cycle control")
barCycle.scripts.OnClick()
assert(A:Store().style=="classic")
back.scripts.OnClick()
assert(centered.checked,"Basic preference survives browsing advanced options")
for i=before+1,#uiButtons do
 local b=uiButtons[i]
 if b.point and b.point[1]=="TOPLEFT" and b.width and b.height then
  local x,y=b.point[4],b.point[5]
  assert(x>=0 and x+b.width<=824,"Settings button overflows horizontally")
  assert(y<=0 and y-b.height>=-605,"Settings button overflows vertically")
 end
end
for i=beforeLabels+1,#uiLabels do
 local item=uiLabels[i]
 if item.point and item.point[1]=="TOPLEFT" then
  local x,y=item.point[4],item.point[5]
  assert(x>=0 and x<=824 and y<=0 and y>=-590,
    "Settings label falls outside available content")
 end
end
print("PASS afflictions: vendor bridge, values, secret sinks, settings, nameplates, mode tab layout")
