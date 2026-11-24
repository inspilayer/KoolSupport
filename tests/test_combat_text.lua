-- KS Combat Text: event-value isolation and animated native text widgets.
SlashCmdList={}
KoolSupportDB={}
local secret=setmetatable({value="opaque"},{
 __tostring=function()error("secret must not be stringified")end,
 __eq=function()error("secret must not be compared")end,
 __lt=function()error("secret must not be ordered")end,
 __add=function()error("secret must not be added")end,
 __concat=function()error("secret must not be concatenated")end,
})
issecretvalue=function(v)return rawequal(v,secret)end
local inCombat=false
InCombatLockdown=function()return inCombat end
local objects={}
local function frame(kind,parent)
 local f={kind=kind or "Frame",parent=parent,shown=true}
 function f:SetSize(w,h)self.w,self.h=w,h end
 function f:SetPoint(...)self.point={...}end
 function f:GetPoint()return table.unpack(self.point or {"CENTER",UIParent,"CENTER",0,0})end
 function f:GetNumPoints()return self.point and 1 or 0 end
 function f:ClearAllPoints()self.point=nil end
 function f:SetText(t)self.text=t end
 function f:SetTextColor(...)self.color={...}end
 function f:SetTextHeight(v)self.textHeight=v end
 function f:SetFont(...)self.font={...};return true end
 function f:SetAlpha(v)self.alpha=v end
 function f:GetCenter()return 300,200 end
 function f:CreateFontString()return frame("FontString",self)end
 function f:CreateTexture()return frame("Texture",self)end
 function f:SetTexture()end
 function f:SetBackdrop()end
 function f:SetBackdropColor()end
 function f:SetBackdropBorderColor()end
 function f:SetFrameStrata()end
 function f:SetClampedToScreen()end
 function f:SetMovable()end
 function f:EnableMouse(v)self.mouse=v end
 function f:RegisterForDrag()end
 function f:StartMoving()end
 function f:StopMovingOrSizing()end
 function f:Show()self.shown=true end
 function f:Hide()self.shown=false end
 function f:SetWidth(w)self.w=w end
 function f:SetJustifyH()end
 function f:SetScript(ev,fn)self[ev]=fn end
 function f:RegisterEvent(ev)self.registered=self.registered or {};self.registered[ev]=true end
 objects[#objects+1]=f
 return f
end
CreateFrame=function(kind,_,parent)return frame(kind,parent)end
UIParent=frame("Frame")
function UIParent:GetCenter()return 400,300 end
CombatText=frame("Frame",UIParent)
CombatText:SetPoint("TOP",UIParent,"TOP",12,-36)
local defaultAnchor={CombatText:GetPoint()}
local cvars={enableFloatingCombatText="1"}
GetCVar=function(k)return cvars[k]end
SetCVar=function(k,v)cvars[k]=v end
assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KSCombatText/CombatText.lua"))()
assert(loadfile("addons/KSCombatText/Render.lua"))()
assert(loadfile("addons/KSCombatText/UI.lua"))()
assert(loadfile("addons/KSCombatText/Module.lua"))()
local S=KSCombatText
local KS=KoolSupport
assert(not KS:IsModuleEnabled("ks_combat_text"),"new 1.1 module defaults off")
assert(KS.pages.combat_text and KS.pages.combat_text_tuning)
assert(KS:SetModuleEnabled("ks_combat_text",true))
assert(S:Store().mode=="native" and S:Store().lanes.incoming.size==23)
assert(CombatText.point[1]=="CENTER","native mode docks Blizzard frame")
assert(S:MoveNative(118,80))
assert(CombatText.point[4]==118 and CombatText.point[5]==80)
assert(S:SetUnlocked(true))
assert(S:SetMode("studio"))
assert(CombatText.point[1]=="TOP" and CombatText.point[4]==12 and CombatText.point[5]==-36,
 "native anchor must restore after Studio activation")
assert(S.framesReady)
assert(S:SetLaneOption("incoming","pattern","arc"))
assert(S:SetLaneOption("incoming","font","morpheus"))
assert(S:SetLaneOption("incoming","size",31))
assert(S:SetLaneOption("incoming","critScale",1.65))
assert(S:SetLaneOption("incoming","palette","arcade"))
assert(S:SetLaneOption("incoming","outline","THICKOUTLINE"))
assert(S:SetLaneOption("incoming","limit",4))
assert(S:SetLaneOption("incoming","lifetime",2.0))
assert(not S:SetLaneOption("incoming","font","notafont"))
assert(not S:SetLaneOption("incoming","pattern","hack"))
assert(not S:SetLaneOption("incoming","size",0/0))
assert(not S:SetLaneOption("incoming","limit","ten"))
assert(S:Preset("fountain"))
assert(S:Store().lanes.heal.pattern=="fountain")
assert(S:SetMode("studio"))
local nativeEventsBefore=S.stats.nativeEvents
local before=#objects
S:Receive("COMBAT_TEXT_UPDATE","DAMAGE",secret)
assert(S.stats.nativeEvents==nativeEventsBefore+1)
local secretSinks=0
for _,o in ipairs(objects) do
 if o.kind=="FontString" and rawequal(o.text,secret) then secretSinks=secretSinks+1 end
end
assert(secretSinks==1,"opaque combat value passed to exactly one native FontString")
local poolCreated=#objects
S:Receive("COMBAT_TEXT_UPDATE","DAMAGE_CRIT",secret)
S:Receive("COMBAT_TEXT_UPDATE","HEAL",secret)
S:Receive("COMBAT_TEXT_UPDATE","MISS",secret)
assert(#objects==poolCreated,"no frames allocated by combat event handling")
local observed=S.stats.targetEvents
S:Receive("UNIT_COMBAT","target","WOUND","CRITICAL",secret)
assert(S.stats.targetEvents==observed,"observed-target lane opt-in")
assert(S:SetOption("showTarget",true))
S:Receive("UNIT_COMBAT","target","WOUND","CRITICAL",secret)
assert(S.stats.targetEvents==observed+1)
local x,y,alpha,scale=S:Animation("fountain",.25,1,80,50,3)
assert(type(x)=="number" and type(y)=="number" and alpha>=0 and alpha<=1)
assert(S:SetOption("nativeHidden",true))
assert(cvars.enableFloatingCombatText=="0")
assert(S:SetOption("nativeHidden",false))
assert(cvars.enableFloatingCombatText=="1")
assert(S:SetOption("nativeHidden",true))
assert(KS:SetModuleEnabled("ks_combat_text",false))
assert(cvars.enableFloatingCombatText=="1","disabling module must restore original Blizzard setting")
assert(KS:SetModuleEnabled("ks_combat_text",true))
assert(cvars.enableFloatingCombatText=="0","re-enabling opt-in module should reapply saved setting")
assert(S:SetOption("nativeHidden",false))
assert(cvars.enableFloatingCombatText=="1")
assert(S:Preview())
local sampled=false
for _,o in ipairs(objects) do
 if o.kind=="FontString" and o.text=="DODGE" then sampled=true end
end
assert(sampled)
local mockParent=frame("Frame",UIParent)
assert(type(S.BuildPage)=="function" and type(S.BuildTuningPage)=="function")
S.BuildPage(mockParent)
S.BuildTuningPage(mockParent)
inCombat=true
assert(not S:SetMode("native"))
assert(not S:Preset("zen"))
assert(not S:SetLaneOption("incoming","speed",120))
assert(not S:MoveLane("incoming",0,0))
assert(not S:SetUnlocked(false))
assert(not S:SetOption("nativeHidden",true))
inCombat=false
assert(S:Reset())
assert(S:Store().mode=="native")
assert(KS:SetModuleEnabled("ks_combat_text",false))
assert(not KS:IsModuleEnabled("ks_combat_text"))
print("PASS KS Combat Text: native anchor, 4 lanes, 12 patterns, 5 fonts, previews, secret passthrough, combat and CVar restore")
