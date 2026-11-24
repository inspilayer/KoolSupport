-- Sleeping bag: faction routes, quest progression, waypoint fallback,
-- draggable overlay, secret-safe coordinates and opt-in module controls.
SlashCmdList={}
KoolSupportDB={}
local disabled=false
local faction="Horde"
UnitFactionGroup=function()return faction end
InCombatLockdown=function()return false end
local complete,ongoing={},{}
C_QuestLog={
 IsQuestFlaggedCompleted=function(id)return complete[id]==true end,
 IsOnQuest=function(id)return ongoing[id]==true end,
}
local names={}
local function mock(kind,parent)
 local f={kind=kind,parent=parent,children={},shown=true}
 function f:SetPoint(...)self.point={...}end
 function f:SetAllPoints()end
 function f:ClearAllPoints()self.point=nil end
 function f:SetSize(w,h)self.width,self.height=w,h end
 function f:SetWidth(w)self.width=w end
 function f:SetHeight(h)self.height=h end
 function f:SetText(v)self.value=v end
 function f:GetText()return self.value end
 function f:SetJustifyH()end
 function f:SetFont()end
 function f:SetTexture(t)self.texture=t end
 function f:SetRotation(r)self.rotation=r end
 function f:SetVertexColor(...)end
 function f:SetBackdrop()end
 function f:SetBackdropColor()end
 function f:SetBackdropBorderColor()end
 function f:SetFrameStrata()end
 function f:SetClampedToScreen()end
 function f:SetMovable()end
 function f:EnableMouse()end
 function f:RegisterForDrag()end
 function f:SetAutoFocus()end
 function f:SetMaxLetters()end
 function f:SetScript(id,fn)self[id]=fn end
 function f:RegisterEvent(e)self.registered=self.registered or {};self.registered[e]=true end
 function f:CreateFontString()return mock("FontString",self)end
 function f:CreateTexture()return mock("Texture",self)end
 function f:Show()self.shown=true end
 function f:Hide()self.shown=false end
 function f:IsShown()return self.shown end
 function f:StartMoving()end
 function f:StopMovingOrSizing()end
 function f:GetCenter()return 500,400 end
 function f:ClearFocus()end
 names[#names+1]=f
 return f
end
UIParent=mock("Frame")
CreateFrame=function(kind,_,parent)return mock(kind,parent)end
local qs={}
C_Map={GetBestMapForUnit=function()return 1413 end}
UnitPosition=function()return 0,0,0,1 end
GetPlayerFacing=function()return 0 end
assert(loadfile("addons/KoolSupport/Core.lua"))()
assert(loadfile("addons/KSSleepingBag/SleepingBag.lua"))()
assert(loadfile("addons/KSSleepingBag/UI.lua"))()
assert(loadfile("addons/KSSleepingBag/Module.lua"))()
local S=KSSleepingBag
assert(not KoolSupport:IsModuleEnabled("ks_sleeping_bag"),"optional guide defaults disabled")
assert(KoolSupport:GetModule("ks_sleeping_bag"))
assert(KoolSupport.pages.sleeping_bag.moduleId=="ks_sleeping_bag")
local q=S.QUESTS
assert(q.noteHorde==79007 and q.noteAlliance==79008)
assert(q.stepping==79192 and q.scramble==79980 and q.wet==79974)
assert(q.eagle==79975 and q.final==79976 and q.rekindle==80001)
assert(S:SelectedIndex()==1 and S:CurrentStop().map==1413)
assert(S:Store().visible==false)
assert(KoolSupport:SetModuleEnabled("ks_sleeping_bag",true))
assert(S:SetVisible(true))
assert(S:Store().visible)
local overlay
for _,f in ipairs(names) do
 if f.kind=="Frame" and f.width==310 and f.height==162 then overlay=f end
end
assert(overlay and overlay.shown and overlay.OnDragStart and overlay.OnDragStop)
overlay.OnDragStart(overlay)
overlay.OnDragStop(overlay)
assert(type(S:Store().left)=="number")
ongoing[q.noteHorde]=true
assert(S:SelectedIndex()==2 and S:CurrentStop().map==1436)
ongoing[q.noteHorde]=nil
complete[q.noteHorde]=true
assert(S:SelectedIndex()==4 and S:CurrentStop().map==1442)
ongoing[q.stepping]=true
assert(S:SelectedIndex()==4)
ongoing[q.stepping]=nil
ongoing[q.scramble]=true
assert(S:SelectedIndex()==5)
ongoing[q.scramble]=nil
ongoing[q.wet]=true
assert(S:SelectedIndex()==6)
ongoing[q.wet]=nil
ongoing[q.eagle]=true
assert(S:SelectedIndex()==8)
ongoing[q.eagle]=nil
ongoing[q.final]=true
assert(S:SelectedIndex()==9 and S:CurrentStop().id=="satchel")
ongoing[q.final]=nil
complete[q.final]=true
local _,index,done=S:CurrentStop()
assert(done and index==10)
complete[q.final]=nil
faction="Alliance"
complete={}
assert(S:SelectedIndex()==1 and S:CurrentStop().map==1436)
assert(S:ManualStep(1))
assert(S:SelectedIndex()==2 and S:CurrentStop().map==1413)
assert(S:ManualStep(1))
assert(S:CurrentStop().id=="stonetalonPath")
S:AutoStep()
assert(S:SelectedIndex()==1)
local nextStop=S:CurrentStop()
local heading,why=S:Direction(nextStop)
assert(heading==nil and why:find("Travel to Westfall",1,true),
 "no invented off-map direction")
local ok,pinText=S:Pin()
assert(not ok and pinText:find("/mappin 1436",1,true))
assert(S:SetVisible(false))
assert(not overlay.shown)
InCombatLockdown=function()return true end
assert(not S:SetVisible(true))
assert(not S:ManualStep(1))
assert(S:Store().visible==false)
InCombatLockdown=function()return false end
local page=mock("Frame",UIParent)
S.BuildPage(page)
assert(S:Store().visible==false)
assert(KoolSupport:SetModuleEnabled("ks_sleeping_bag",false))
assert(not overlay.shown)
print("PASS sleeping bag: Horde/Alliance stops, IDs, optional enable, progression, pin fallback, drag, combat and disable")
