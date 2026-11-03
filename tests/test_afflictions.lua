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
 function f:ClearAllPoints()end
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
 function f:SetScript()end
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
assert(A:ChangeSetting("nameplates",false))
assert(A.plates[plate].hidden)
print("PASS afflictions: vendor bridge, values, secret sinks, settings, nameplates, module")
