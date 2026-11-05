-- Full unified package cold-start test in actual TOC load order.
-- This is a mocked Lua loader; live Forever API behavior still requires testing.
SlashCmdList={}
local createdMacros=0
CreateMacro=function()createdMacros=createdMacros+1;error("no macro writes during boot")end
EditMacro=function()error("no edits during boot")end
GetComboPoints=function()error("no combat resource reads during boot")end
UnitHealth=function()error("no protected health reads during boot")end
UnitHealthMax=function()error("no protected health reads during boot")end
InCombatLockdown=function()return false end
UnitClass=function()return "Druid","DRUID" end
UnitExists=function()return false end
GetTime=function()return 100 end
GetBuildInfo=function()return "Forever",123,"2026",16001 end
GetLocale=function()return "enUS" end
local fns={}
local function makeFrame()
 local frame={hidden=false}
 local function noop()end
 function frame:SetScript(which,fn)self[which]=fn end
 function frame:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
 function frame:UnregisterEvent(event)if self.events then self.events[event]=nil end end
 function frame:Show()self.hidden=false end
 function frame:Hide()self.hidden=true end
 function frame:IsShown()return not self.hidden end
 function frame:SetValue(value)self.value=value end
 function frame:SetMinMaxValues(min,max)self.min=min;self.max=max end
 function frame:GetStatusBarTexture()return makeFrame()end
 function frame:CreateTexture()return makeFrame()end
 function frame:CreateFontString()return makeFrame()end
 function frame:SetText(t)self.text=t end
 function frame:SetShown(s)self.hidden=not s end
 function frame:GetFrameLevel()return 1 end
 function frame:SetClipsChildren()end
 function frame:GetWidth()return 1100 end
 function frame:GetHeight()return 750 end
 return setmetatable(frame,{__index=function(_,key)
  if type(key)=="string" and
    (key:match("^Set") or key:match("^Get") or key:match("^Clear") or key:match("^Register")) then
    return noop
  end
 end})
end
CreateFrame=function()local f=makeFrame();fns[#fns+1]=f;return f end
UIParent=makeFrame()
TargetFrame=makeFrame()
FocusFrame=makeFrame()
UISpecialFrames={}
local sentinel={preserved=true}
KoolSupportDB={untouched=sentinel}
KSAfflictionsTrackerDB={untouched=sentinel}
local addons={"KoolSupport","KSMacros","KSSupportSessions","KSStealth","KSAfflictions"}
local ns={}
local manifests={}
local function loadAddon(addon)
 local toc=assert(io.open("addons/"..addon.."/"..addon..".toc","r"))
 local names={}
 for line in toc:lines() do
  if line:match("%.lua%s*$") and not line:match("^%s*#") then
   local path=line:match("^%s*(.-)%s*$")
   local filename="addons/"..addon.."/"..path
   names[#names+1]=filename
   local fn=assert(loadfile(filename))
   if addon=="KSAfflictions" then fn(addon,ns) else fn(addon,{}) end
  end
 end
 toc:close()
 assert(#names>0,"missing addon files in "..addon)
 manifests[addon]=names
end
for _,name in ipairs(addons)do loadAddon(name)end
local K=KoolSupport
assert(K.API_VERSION==1)
assert(K.VERSION=="0.10.4-rc.1")
assert(K.BarTheme and K.CollectLaunchChecks)
assert(K.modules.ks_macros and K.modules.ks_support_sessions and
 K.modules.ks_stealth and K.modules.ks_afflictions)
assert(#K.moduleOrder==4,"exactly four independently managed child modules")
for _,id in ipairs({"home","modules","launch_checks","macro_suite","full_spellbook",
 "macro_workshop","support_session","stealth","stealth_talents","afflictions"}) do
 assert(K.pages[id] and K:CanOpenPage(id),"page must be registered: "..id)
end
assert(K:GetModule("ks_support_sessions").requires[1]=="ks_macros")
assert(K:GetModule("ks_stealth").requires[1]==nil)
assert(K:GetModule("ks_afflictions").requires[1]==nil)
assert(ns.locale and ns.tracking and ns.display,"vendored Locale, Tracker and Bridge must share namespace")
assert(type(ns.tracking.housekeep)=="function")
assert(KoolSupportDB.untouched==sentinel and KSAfflictionsTrackerDB.untouched==sentinel)
assert(createdMacros==0)
-- Optional modules are installed together but independent at runtime.
assert(K:SetModuleEnabled("ks_stealth",false))
assert(not K:CanOpenPage("stealth_talents"))
assert(K:CanOpenPage("afflictions"))
assert(K:SetModuleEnabled("ks_stealth",true))
assert(K:CanOpenPage("stealth_talents"))
assert(K:SetModuleEnabled("ks_support_sessions",false))
assert(not K:CanOpenPage("support_session"))
assert(K:CanOpenPage("macro_suite"))
assert(K:SetModuleEnabled("ks_support_sessions",true))
assert(K:CanOpenPage("support_session"))
assert(not K:SetModuleEnabled("ks_macros",false),"active support dependency must protect macros")
assert(KoolSupportDB.untouched==sentinel and KSAfflictionsTrackerDB.untouched==sentinel)
assert(createdMacros==0)
print("PASS unified boot: all five TOCs in order, shared namespace, pages, dependency gates, no macro writes")
