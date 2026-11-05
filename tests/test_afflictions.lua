-- KS Afflictions offline contract: independent data, opaque health passthrough, toggles.
KoolSupportDB={core={},modules={}}
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
local function mk()
 local f={hidden=false}
 local function stub()end
 function f:SetSize(w,h)self.width=w;self.height=h end
 function f:SetHeight(v)self.height=v end
 function f:SetPoint(...)self.point={...}end
 function f:ClearAllPoints()self.point=nil end
 function f:GetCenter()return self.centerX or 960,self.centerY or 540 end
 function f:GetEffectiveScale()return self.effectiveScale or 1 end
 function f:StartMoving()self.moving=true end
 function f:StopMovingOrSizing()self.moving=false end
 function f:SetAllPoints()end
 function f:SetStatusBarTexture()end
 function f:SetStatusBarColor(...)self.color={...}end
 function f:SetMinMaxValues(min,max)self.min=min;self.max=max end
 function f:SetValue(value)self.value=value end
 function f:SetText(t)self.text=t end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:SetShown(x)self.hidden=not x end
 function f:SetScale(scale)self.scale=scale end
 function f:RegisterEvent()end
 function f:SetScript(event,handler)self.scripts=self.scripts or {};self.scripts[event]=handler end
 function f:CreateTexture()return mk()end
 function f:CreateFontString()return mk()end
 function f:GetStatusBarTexture()return mk()end
 return setmetatable(f,{__index=function(_,key)
  if type(key)=="string" and (key:match("^Set") or key:match("^Get") or key:match("^Register") or key:match("^Clear")) then return stub end
  return nil
 end})
end
CreateFrame=function()return mk()end
UIParent=mk();TargetFrame=mk();FocusFrame=mk()
UnitHealth=function()return secret end
UnitHealthMax=function()return secret end
UnitExists=function()return true end
GetTime=function()return 100 end
local plate=mk();plate.namePlateUnitToken="nameplate1"
C_NamePlate={GetNamePlates=function()return {plate}end}
local dots={{name="Rip",school=1,expiresAt=110,damage=600}}
local ns={db={},tracking={housekeep=function()end},
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
assert(A.huds.target.lethalWord.hidden==false,"DIES text should be active")
assert(A.huds.target.lethalIcon.hidden==true,"skull hidden in DIES mode")
assert(A.plates[plate].lethalWord.hidden==false,"nameplate DIES enabled by default")
assert(A:ChangeSetting("lethalMode","skull"))
assert(A.huds.target.lethalWord.hidden==true)
assert(A.huds.target.lethalIcon.hidden==false)
assert(A:ChangeSetting("lethalMode","both"))
assert(A.huds.target.lethalWord.hidden==false and A.huds.target.lethalIcon.hidden==false)
assert(A:ChangeSetting("lethalMode","off"))
assert(A.huds.target.lethalClip.hidden==true,"off must hide the lethal clip")
assert(A:ChangeSetting("lethalMode","dies"))
assert(A:ChangeSetting("lethalTarget",false))
assert(A.huds.target.lethalClip.hidden==true)
assert(A.plates[plate].lethalClip.hidden==false)
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

assert(A:ChangeSetting("nameplates",false))
assert(A.plates[plate].hidden)
print("PASS afflictions: vendor bridge, values, secret sinks, settings, nameplates, module")
