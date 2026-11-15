-- KS Threat offline contract. No third-party nameplate framework or protected arithmetic.
local secret=setmetatable({secret=true},{
 __lt=function()error("secret value compared")end,
 __le=function()error("secret value compared")end,
 __eq=function()error("secret value compared")end,
 __add=function()error("secret value added")end,
 __tostring=function()error("secret value formatted")end
})
local combat=false
local enabled=false
local hostile=true
local fighting=true
local state=3
local tapDenied=false
local plates={}
KoolSupportDB={untouched={preserveMe=true},modules={ks_afflictions={onFrame=true}}}
KoolSupport={
 GetDatabase=function()return KoolSupportDB end,
 IsInCombat=function()return combat end,
 IsModuleEnabled=function(_,id)return id=="ks_threat" and enabled end,
 RegisterModule=function(self,x)self.module=x end,
 RegisterPage=function(self,x)self.page=x end,
}
issecretvalue=function(value)return value==secret end
local frames={}
local function makeFrame(kind)
 local f={kind=kind or "Frame",hidden=false}
 function f:GetObjectType()return self.kind end
 function f:SetSize(w,h)self.w=w;self.h=h end
 function f:SetPoint(...)self.point={...}end
 function f:SetWidth(w)self.w=w end
 function f:SetJustifyH()end
 function f:SetText(t)self.text=t end
 function f:SetScript(key,fn)self.scripts=self.scripts or {};self.scripts[key]=fn end
 function f:RegisterEvent(ev)self.events=self.events or {};self.events[ev]=true end
 function f:EnableMouse(v)self.mouse=v end
 function f:SetAllPoints(parent)self.allPoints=parent end
 function f:SetStatusBarTexture(texture)self.texture=texture end
 function f:SetStatusBarColor(...)self.color={...}end
 function f:SetMinMaxValues(a,b)self.min=a;self.max=b end
 function f:SetValue(v)self.value=v end
 function f:SetShown(v)self.hidden=not v end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:CreateFontString()
  local item=makeFrame("FontString")
  frames[#frames+1]=item
  return item
 end
 return f
end
CreateFrame=function(kind,_,parent)
 local f=makeFrame(kind)
 f.parent=parent
 frames[#frames+1]=f
 return f
end
UnitCanAttack=function()return hostile end
UnitAffectingCombat=function()return fighting end
UnitThreatSituation=function()return state end
UnitIsTapDenied=function()return tapDenied end
UnitHealth=function()return secret end
UnitHealthMax=function()return secret end
local plate={
 namePlateUnitToken="nameplate1",
 UnitFrame={healthBar=makeFrame("StatusBar")}
}
local native=plate.UnitFrame.healthBar
plates[1]=plate
C_NamePlate={GetNamePlates=function()return plates end}
assert(loadfile("addons/KSThreat/Threat.lua"))()
assert(loadfile("addons/KSThreat/UI.lua"))()
assert(loadfile("addons/KSThreat/Module.lua"))()
local A=KSThreat
assert(KoolSupport.module.id=="ks_threat" and KoolSupport.module.defaultEnabled==false)
assert(KoolSupport.page.id=="ks_threat")
assert(KoolSupportDB.untouched.preserveMe and KoolSupportDB.modules.ks_afflictions.onFrame)
assert(A:Store().onlyCombat and A:Store().purpleNoThreat and A:Store().greyTagged,
 "External tap silver should default ON for an upgraded tank")
assert(A:HealthBar(plate)==native)
local repaint=A:ThreatState("nameplate1")
assert(repaint==3)
A:RefreshAll()
assert(A.plates[plate]==nil,"Module disabled by default must not paint")
enabled=true
A:RefreshAll()
local overlay=A.plates[plate].overlay
assert(overlay and overlay.parent==native and overlay.allPoints==native)
assert(overlay.color[1]==A.COLORS[3][1],"Red for held aggro")
assert(overlay.value==secret and overlay.max==secret,"Opaque health passes ONLY through StatusBar")
assert(native.value==nil and native.color==nil and native.min==nil,
 "Threat overlay must not mutate Blizzard's native health bar")
assert(overlay.mouse==false and not overlay.hidden)
-- A tap by a player outside our party takes precedence over threat AND the
-- combat-only filter. Aggro cannot imply tag ownership (or loot rights).
tapDenied=true
fighting=false
state=secret
A:RefreshAll()
assert(overlay.color[1]==A.COLORS.tagged[1] and
 overlay.color[2]==A.COLORS.tagged[2] and not overlay.hidden,
 "Externally tagged mob is silver even if our threat state is hidden")
local summary,reason=A:DiagnosticText()
assert(summary:find("Tagged silver: 1",1,true),
 "Diagnostics must identify silver external tags separately from threats")
assert(A:ThreatState("nameplate1")=="tagged",
 "Ownership must be checked before threat or combat-only gates")
state=3
assert(A:ChangeSetting("greyTagged",false))
assert(overlay.hidden,"Tag overlay OFF suppresses outsider-owned mob, never paints red")
assert(A:ChangeSetting("greyTagged",true))
assert(not overlay.hidden and overlay.color[1]==A.COLORS.tagged[1])
fighting=true
tapDenied=secret
A:RefreshAll()
assert(overlay.hidden,"Secret tag value must not be compared")
summary,reason=A:DiagnosticText()
assert(reason:find("tap unavailable: 1",1,true),"Unknown tap state should be explained")
UnitIsTapDenied=nil
A:RefreshAll()
assert(overlay.hidden,"Unavailable Forever API fails closed, not as false red")
UnitIsTapDenied=function()return tapDenied end
tapDenied=false
A:RefreshAll()
assert(overlay.color[1]==A.COLORS[3][1] and not overlay.hidden,
 "Known untapped/group-owned mob returns to normal threat palette")
local driver
for _,frame in ipairs(frames) do
 if frame.events and frame.events.UNIT_THREAT_LIST_UPDATE then driver=frame;break end
end
assert(driver and driver.events.NAME_PLATE_UNIT_ADDED and driver.events.PLAYER_REGEN_DISABLED
 and driver.events.UNIT_HEALTH and driver.events.UNIT_MAXHEALTH
 and driver.events.UNIT_FLAGS and driver.events.UNIT_FACTION,
 "Ownership changes must refresh without polling")
state=2
driver.scripts.OnEvent(driver,"UNIT_THREAT_LIST_UPDATE","target")
assert(overlay.color[1]==A.COLORS[2][1],
 "Some Forever clients report threat changes for target, not nameplate token")
for i=0,3 do
 state=i
 A:RefreshAll()
 assert(A.plates[plate].overlay==overlay,"Reuses the same overlay")
 assert(overlay.color[1]==A.COLORS[i][1] and not overlay.hidden)
end
-- No known threat in active combat means purple, not red.
state=nil
A:RefreshAll()
assert(overlay.color[1]==A.COLORS[0][1])
assert(A:ChangeSetting("purpleNoThreat",false))
assert(overlay.hidden)
state=1
A:RefreshAll()
assert(not overlay.hidden)
assert(A:ChangeSetting("purpleNoThreat",true))
state=3
fighting=false
A:RefreshAll()
assert(overlay.hidden,"Non-engaged mobs retain Blizzard's colors")
assert(A:ChangeSetting("onlyCombat",false))
assert(not overlay.hidden,"Player can opt out of combat-only filtering")
assert(A:ChangeSetting("onlyCombat",true))
hostile=false
A:RefreshAll()
assert(overlay.hidden,"Never recolor friendly nameplates")
hostile=true;fighting=true
-- Secret threat status must fail closed even within combat.
state=secret
A:RefreshAll()
assert(overlay.hidden,"No comparing or arithmetic on secret threat status")
state=3
UnitCanAttack=function()return secret end
A:RefreshAll()
assert(overlay.hidden,"Secret hostility must fail closed")
UnitCanAttack=function()return true end
UnitAffectingCombat=function()return secret end
A:RefreshAll()
assert(overlay.hidden,"Secret combat flag must fail closed")
UnitAffectingCombat=function()return true end
issecretvalue=nil
A:RefreshAll()
assert(overlay.hidden,"No secret-detection API means no threat status inspection")
issecretvalue=function(value)return value==secret end
A:RefreshAll()
assert(not overlay.hidden)
-- Regression: native Blizzard nameplates use plate.unitToken, not necessarily
-- the older third-party namePlateUnitToken field (the 0.10.6 blank-plate bug).
plate.namePlateUnitToken=nil
plate.unitToken="nameplate1"
A:RefreshAll()
assert(A.plates[plate].overlay==overlay and not overlay.hidden,
 "Blizzard unitToken must work with no namePlateUnitToken")
local main,details=A:DiagnosticText()
assert(main:find("Visible plates: 1",1,true) and main:find("colored: 1",1,true))
assert(details:find("No skipped plates",1,true))
plate.unitToken=nil
plate.GetUnit=function()return "nameplate1" end
A:RefreshAll()
assert(not overlay.hidden,"Blizzard GetUnit() fallback must resolve native nameplates")
plate.GetUnit=nil
A:RefreshAll()
assert(overlay.hidden,"Unsupported token must fail closed")
main,details=A:DiagnosticText()
assert(main:find("colored: 0",1,true) and details:find("no token: 1",1,true),
 "Diagnostics must show why a plate was skipped")
plate.namePlateUnitToken="nameplate1"
A:RefreshAll()
assert(not overlay.hidden,"Restored token restores coloring")
assert(A:HealthBar({UnitFrame={HealthBarsContainer={HealthBar=native}}})==native,
 "Resolve Blizzard nested health StatusBar as well")
-- Nameplate lacking a native StatusBar is ignored; original bar never restyled.
plate.UnitFrame.healthBar=makeFrame("Frame")
A:RefreshAll()
assert(overlay.hidden)
plate.UnitFrame.healthBar=native
-- Remove stale overlays on nameplate removal or module shutdown.
plates={}
A:RefreshAll()
assert(overlay.hidden)
plates={plate}
C_NamePlate.GetNamePlates=function()return plates end
A:RefreshAll()
assert(not overlay.hidden)
enabled=false
A:Disable()
assert(overlay.hidden and native.color==nil)
-- Settings and module isolation.
combat=true
assert(not A:ChangeSetting("purpleNoThreat",false))
combat=false
assert(not A:ChangeSetting("badkey",false))
assert(KoolSupportDB.modules.ks_afflictions.onFrame)
-- The native UI pane has a bounded page with no automatic game writes.
local current=#frames
KoolSupport.page.build(makeFrame())
assert(#frames>current,"Settings UI should create preview swatches and toggles")
assert(native.color==nil)
local foundSilverToggle=false
local foundSilverLegend=false
for i=current+1,#frames do
 local part=frames[i]
 if part.text and part.text:find("Silver for outside tags: ON",1,true) then
  foundSilverToggle=true
 end
 if part.text and part.text:find("SILVER",1,true) then foundSilverLegend=true end
end
assert(foundSilverToggle and foundSilverLegend,"The page must show the silver override and legend")
assert(KoolSupportDB.modules.ks_afflictions.onFrame)
print("PASS KS Threat: tag ownership silver priority, secret tap safety, red-purple palette, UI, diagnostics and native integrity")
