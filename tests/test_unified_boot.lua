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
-- One installable AddOn TOC; each nested source module shares the SAME
-- KoolSupport addon namespace (critical for DoesItDie event initialization).
local ns={}
local counts={KoolSupport=0,KSMacros=0,KSSupportSessions=0,KSStealth=0,
 KSAfflictions=0,KSCampfireChat=0,KSThreat=0}
local loaded={}
local toc=assert(io.open("addons/KoolSupport/KoolSupport.toc","r"))
for line in toc:lines() do
 if line:match("%.lua%s*$") and not line:match("^%s*#") then
  local rel=line:match("^%s*(.-)%s*$"):gsub("\\","/")
  local module,path=rel:match("^Modules/([^/]+)/(.+)$")
  local filename
  if module then
   assert(counts[module]~=nil,"Unexpected root module: "..module)
   filename="addons/"..module.."/"..path
  else
   module="KoolSupport"
   filename="addons/KoolSupport/"..rel
  end
  assert(not loaded[filename],"A Lua file appeared twice in unified TOC: "..filename)
  loaded[filename]=true
  counts[module]=counts[module]+1
  local fn=assert(loadfile(filename))
  fn("KoolSupport",ns)
 end
end
toc:close()
for module,count in pairs(counts) do
 assert(count>0,"Unified TOC omitted all Lua from "..module)
end
-- The vendored Afflictions tracker is now owned by the single KoolSupport
-- physical addon, so it must initialize on ADDON_LOADED("KoolSupport")
-- rather than the old sibling-addon name "KSAfflictions".
local trackerInitialized=false
for _,frame in ipairs(fns) do
 if frame.events and frame.events.ADDON_LOADED and type(frame.OnEvent)=="function" then
  frame.OnEvent(frame,"ADDON_LOADED","KoolSupport")
  if ns.db==KSAfflictionsTrackerDB then trackerInitialized=true end
 end
end
assert(trackerInitialized,"Afflictions tracker must initialize in the new host addon namespace")
local K=KoolSupport
assert(K.API_VERSION==1)
assert(K.VERSION=="0.10.9-rc.1")
assert(K.BarTheme and K.CollectLaunchChecks)
assert(K.modules.ks_macros and K.modules.ks_support_sessions and
 K.modules.ks_stealth and K.modules.ks_afflictions and K.modules.ks_campfire_chat and K.modules.ks_threat)
assert(#K.moduleOrder==6,"exactly six independently managed child modules")
for _,id in ipairs({"home","modules","launch_checks","macro_suite","full_spellbook",
 "macro_workshop","support_session","stealth","stealth_talents","afflictions","campfire_chat"}) do
 assert(K.pages[id] and K:CanOpenPage(id),"page must be registered: "..id)
end
assert(K:GetModule("ks_support_sessions").requires[1]=="ks_macros")
assert(K:GetModule("ks_stealth").requires[1]==nil)
assert(K:GetModule("ks_afflictions").requires[1]==nil)
assert(K:GetModule("ks_campfire_chat").requires[1]==nil)
assert(K:GetModule("ks_threat").requires[1]==nil)
assert(not K:IsModuleEnabled("ks_threat"),"Threat module must be opt in")
assert(not K:CanOpenPage("ks_threat"),"Opt-in module page hidden until enabled")
assert(K:SetModuleEnabled("ks_threat",true))
assert(K:CanOpenPage("ks_threat"))
assert(K:SetModuleEnabled("ks_threat",false))
assert(K:CanOpenPage("campfire_chat"))
assert(ns.locale and ns.tracking and ns.display,"vendored Locale, Tracker and Bridge must share namespace")
assert(type(ns.tracking.housekeep)=="function")
assert(KoolSupportDB.untouched==sentinel and KSAfflictionsTrackerDB.untouched==sentinel)
assert(createdMacros==0)
assert(KSCampfireChat.CAMPFIRE_SPELL_ID==1283391)
-- A cold load must never publish a story.
assert(KSCampfireChat.lastSent==nil)
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
print("PASS unified boot: ONE TOC loads all seven code groups in order, shared namespace, six modules, no macro writes")
