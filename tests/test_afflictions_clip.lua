-- Secret-health centered DIES regression: no readable max HP is EVER needed.
-- The upstream MIT DoesItDie clipped-StatusBar technique is rendered as text.
local secret=setmetatable({},{
 __lt=function()error("compared secret HP")end,
 __le=function()error("compared secret HP")end,
 __eq=function()error("compared secret HP")end,
 __add=function()error("added secret HP")end,
 __div=function()error("divided secret HP")end,
 __tostring=function()error("formatted secret HP")end,
})
issecretvalue=function(value)return rawequal(value,secret)end
local t=100
GetTime=function()return t end
KoolSupportDB={core={},modules={ks_afflictions={displayMode="centered"}}}
local combat=false
local enabled=true
KoolSupport={
 GetDatabase=function()return KoolSupportDB end,
 IsInCombat=function()return combat end,
 IsModuleEnabled=function(_,key)return key=="ks_afflictions" and enabled end,
}
local frames={}
local function mk(kind,parent)
 local f={kind=kind or "Frame",parent=parent,hidden=false,alterations=0}
 function f:GetObjectType()return self.kind end
 function f:IsShown()return not self.hidden end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:SetShown(v)self.hidden=not v end
 function f:SetAllPoints(target)self.anchor=target end
 function f:SetPoint(...)self.point={...}end
 function f:ClearAllPoints()self.point=nil end
 function f:SetSize(w,h)self.width=w;self.height=h end
 function f:SetWidth(w)self.width=w end
 function f:SetFrameLevel(n)self.level=n end
 function f:GetFrameLevel()return self.level or 5 end
 function f:GetFrameStrata()return "MEDIUM" end
 function f:SetFrameStrata(value)self.strata=value end
 function f:SetClipsChildren(value)self.clips=value end
 function f:EnableMouse(value)self.mouse=value end
 function f:CreateFontString()return mk("FontString",self)end
 function f:CreateTexture()return mk("Texture",self)end
 function f:SetText(value)self.text=value end
 function f:SetTextColor(...)self.color={...}end
 function f:SetAlpha(n)self.alpha=n end
 function f:SetFont(...)self.font={...}end
 function f:SetJustifyH(v)self.justify=v end
 function f:SetShadowColor(...)self.shadow={...}end
 function f:SetShadowOffset(...)self.shadowOffset={...}end
 function f:SetStatusBarTexture(texture)
  self.alterations=self.alterations+1
  self.texture=texture
  self.fill=mk("Texture",self)
 end
 function f:GetStatusBarTexture()return self.fill end
 function f:SetStatusBarColor(...)self.alterations=self.alterations+1;self.barColor={...}end
 function f:SetMinMaxValues(a,b)
  self.alterations=self.alterations+1
  self.min=a;self.max=b
 end
 function f:SetValue(v)self.alterations=self.alterations+1;self.value=v end
 function f:SetScript(event,fn)self.scripts=self.scripts or {};self.scripts[event]=fn end
 function f:RegisterEvent(ev)self.events=self.events or {};self.events[ev]=true end
 return f
end
CreateFrame=function(kind,_,parent)
 local frame=mk(kind,parent)
 frames[#frames+1]=frame
 return frame
end
UIParent=mk()
TargetFrame=mk()
FocusFrame=mk()
TargetFrameHealthBar=mk("StatusBar")
FocusFrameHealthBar=mk("StatusBar")
local plate={unitToken="nameplate1",UnitFrame={healthBar=mk("StatusBar")}}
local plates={plate}
C_NamePlate={GetNamePlates=function()return plates end}
local hp={target=secret,focus=secret,nameplate1=secret}
UnitHealth=function(unit)return hp[unit] end
UnitHealthMax=function(unit)return secret end
UnitExists=function(unit)return hp[unit]~=nil end
UnitIsDeadOrGhost=function()return false end
UnitCanAttack=function(_,unit)return hp[unit]~=nil end
local keys={target="mob-target",focus="mob-focus",nameplate1="mob-plate"}
local active={
 target={100,181,100},
 focus={90},
 nameplate1={120,240},
}
local function snapshot(unit)
 local values=active[unit] or {}
 local list,total={},0
 for _,amount in ipairs(values) do
  list[#list+1]={name="Rip",spellID=123,school=1,damage=amount,expiresAt=t+30}
  total=total+amount
 end
 return list,total
end
local ns={db={},tracking={
 unitKey=function(unit)return keys[unit] end,
 housekeep=function()end,
},dotBreakdownForUnit=snapshot}
assert(loadfile("addons/KSAfflictions/Afflictions.lua"))("KoolSupport",ns)
assert(loadfile("addons/KSAfflictions/Renderer.lua"))("KoolSupport",ns)
local A=KSAfflictions
assert(A:Store().displayMode=="centered")
assert(A:KnownMax("target")==nil and A:KnownMax("nameplate1")==nil,
 "Client refuses max HP even outside combat")
local driver=frames[#frames]
assert(driver.events.UNIT_HEALTH and driver.events.UNIT_AURA)
-- Prewarm invisible native text, not a new visible bar or extra HUD.
active.target={}
active.focus={}
active.nameplate1={}
A:RefreshAll()
local target=A.minimalUnits.target
local focus=A.minimalUnits.focus
local nameplate=A.minimalPlates[plate]
assert(target and focus and nameplate,"Supported target/focus/plate get native anchors")
for _,entry in ipairs({target,focus,nameplate}) do
 assert(entry.clip and entry.clip.window.clips==true and entry.clip.window.hidden)
 assert(entry.clip.window.parent==entry.frame)
 assert(entry.clip.bar.parent==entry.clip.window)
 assert(entry.clip.bar.width==10000 and entry.clip.bar.barColor[4]==0)
 assert(entry.clip.word.text=="DIES" and entry.clip.word.width==38)
 assert(entry.clip.word.point[1]=="RIGHT" and
        entry.clip.word.point[2]==entry.clip.bar.fill)
 assert(entry.frame.hidden,"No lethal estimate must not draw any text")
end
-- Reestablish attributable DoT evidence and paint via opaque native HP sink.
active.target={100,181,100}
active.focus={90}
active.nameplate1={120,240}
A:RefreshAll()
for _,v in ipairs({
 {target,"target",381,TargetFrameHealthBar},
 {focus,"focus",90,FocusFrameHealthBar},
 {nameplate,"nameplate1",360,plate.UnitFrame.healthBar},
}) do
 local entry,unit,total,native=v[1],v[2],v[3],v[4]
 assert(entry.mode=="native_clip_applied" and entry.active and not entry.frame.hidden)
 assert(entry.clip.bar.min==0 and rawequal(entry.clip.bar.max,secret))
 assert(entry.clip.bar.value==total)
 assert(not entry.clip.window.hidden and entry.word.hidden,
  "Display only clipped DIES, not a second floating word")
 assert(entry.frame.anchor==native and entry.frame.mouse==false)
 assert(native.alterations==0,"Never mutate Blizzard native healthbar")
 assert(A:DiagnosticLine(unit):find("display native_clip_applied",1,true),
  "Expose successful native comparison in /kool dies")
end
assert(A:KnownMax("target")==nil and A:KnownMax("focus")==nil,
 "Native clip must not fabricate a baseline")
-- No numeric secret data was retrieved, printed, compared or passed to Lua math.
-- Damage updates keep the same clip objects and isolated per-enemy amounts.
local oldTargetClip=target.clip.bar
active.target={8}
A:RefreshAll()
assert(target.clip.bar==oldTargetClip and target.clip.bar.value==8)
assert(focus.clip.bar.value==90 and nameplate.clip.bar.value==360)
-- DoT loss, expiry, changed identity and nameplate removal clear the text.
active.target={}
A:RefreshAll()
assert(target.frame.hidden and target.clip.window.hidden)
active.target={381}
keys.target=nil
A:RefreshAll()
assert(target.frame.hidden)
keys.target="mob-target"
A:RefreshAll()
assert(target.active)
plates={}
A:RefreshAll()
assert(nameplate.frame.hidden and nameplate.clip.window.hidden)
plates={plate}
A:RefreshAll()
assert(nameplate.active)
enabled=false
A:RefreshAll()
assert(target.frame.hidden and focus.frame.hidden and nameplate.frame.hidden)
-- No positive damage / premature first tick => no DIES.
enabled=true
active.target={0}
A:RefreshAll()
assert(target.frame.hidden)
assert(KoolSupportDB.modules.ks_afflictions.displayMode=="centered")
print("PASS DIES native clip: secret HP without max, 3 unit types, invisible prewarm, isolated estimates and cleanup")
