-- Read-only quest ID/name search, exact character completion status and native UI.
SlashCmdList={}
KoolSupportDB={sentinel={kept=true}}
InCombatLockdown=function()return false end
assert(loadfile("addons/KoolSupport/Core.lua"))()
local ids={3527,100,101,250}
local names={
 [3527]="The Prophecy of Mosh'aru",[100]="Testing Quest",
 [101]="Testing Quest",[250]="A Different Quest",
 [400]="A Previously Completed Quest",[500]="A Quest In Progress",
}
QuestDB={
 GetAllIds=function()return ids end,
 name=function(id)return names[id]end,
}
local checked={}
C_QuestLog={
 GetTitleForQuestID=function(id)return names[id]end,
 GetAllCompletedQuestIDs=function()return {400}end,
 IsQuestFlaggedCompleted=function(id)checked[#checked+1]=id;return id==3527 or id==400 end,
}
GetNumQuestLogEntries=function()return 1 end
GetQuestLogTitle=function()return names[500],45,nil,false,false,nil,nil,500 end
assert(loadfile("addons/KSQuestChecker/QuestChecker.lua"))()
local A=KSQuestChecker
assert(A:BuildIndex() and A.provider=="QuestieDB")
assert(A.byID[3527]=="The Prophecy of Mosh'aru")
assert(A.byID[400]=="A Previously Completed Quest")
assert(A.byID[500]=="A Quest In Progress")
local res,count=A:Search("pRoPhEcY")
assert(count==1 and res[1].id==3527 and #res==1)
res,count=A:Search("Testing")
assert(count==2 and res[1].id==100 and res[2].id==101,"duplicate names must keep both quest IDs")
res,count=A:Search("3527")
assert(count==1 and res[1].id==3527)
res,count=A:Search("9999")
assert(count==1 and res[1].name=="Quest #9999","unknown numeric ID can still be checked")
assert(#A:Search("x")==0 and #A:Search("not anywhere")==0)
local yes,text=A:Completed(3527)
assert(yes==true and text=="Completed / turned in")
local no,reason=A:Completed(500)
assert(no==false and reason=="Not flagged completed","in-progress quests must not be presented as completed")
assert(checked[1]==3527 and checked[2]==500)
local had=C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted=nil
local unknown,status=A:Completed(500)
assert(unknown==nil and status=="Quest completion API unavailable")
C_QuestLog.IsQuestFlaggedCompleted=function()error("protected/unavailable")end
unknown,status=A:Completed(500)
assert(unknown==nil and status=="Quest completion could not be verified")
C_QuestLog.IsQuestFlaggedCompleted=had

A:SaveRecent(3527)
A:SaveRecent(100)
A:SaveRecent(3527)
assert(A:Recent()[1].id==3527 and A:Recent()[2].id==100)
assert(KoolSupportDB.sentinel.kept)
for id=1,25 do A:SaveRecent(1000+id) end
assert(#A:Store().recent==20 and A:Store().recent[1]==1025)
local blank=A:SaveRecent(-1)
assert(blank==false)
-- Full provider disabled should still expose Blizzard-known + bundled titles.
QuestDB=nil
A:BuildIndex(true)
assert(A.provider=="Local + Blizzard")
assert(A.byID[3527] and A.byID[500] and A.byID[400])
assert(A.byID[250]==nil,"no misleading promise of a complete standalone catalog")
QuestDB={GetAllIds=function()return ids end,name=function(id)return names[id]end}
A:BuildIndex(true)

-- UI integration; search and completion checks must be player-initiated.
local widgets={}
local function frame(kind)
 local f={kind=kind,hidden=false}
 function f:SetPoint(...)self.point={...}end
 function f:SetWidth(w)self.width=w end
 function f:SetSize(w,h)self.width=w;self.height=h end
 function f:SetJustifyH()end
 function f:SetText(text)self.text=text end
 function f:GetText()return self.text end
 function f:SetAutoFocus()end
 function f:SetMaxLetters()end
 function f:ClearFocus()end
 function f:SetScript(key,fn)self[key]=fn end
 function f:Show()self.hidden=false end
 function f:Hide()self.hidden=true end
 function f:CreateFontString()local x=frame("FontString");widgets[#widgets+1]=x;return x end
 widgets[#widgets+1]=f
 return f
end
CreateFrame=function(kind)return frame(kind)end
assert(loadfile("addons/KSQuestChecker/UI.lua"))()
assert(loadfile("addons/KSQuestChecker/Module.lua"))()
assert(KoolSupport:CanOpenPage("quest_checker"))
assert(KoolSupport:SetModuleEnabled("ks_quest_checker",false))
assert(not KoolSupport:CanOpenPage("quest_checker"))
assert(KoolSupport:SetModuleEnabled("ks_quest_checker",true))
local parent=frame("Frame")
A.BuildPage(parent)
local search,edit,choice
for _,w in ipairs(widgets) do
 if w.kind=="EditBox" then edit=w end
 if w.text=="Search" then search=w end
end
assert(search and edit,"native input and search controls required")
edit:SetText("Prophecy")
search.OnClick()
for _,w in ipairs(widgets) do
 if w.kind=="Button" and w.text and w.text:find("Prophecy",1,true) then choice=w;break end
end
assert(choice and not choice.hidden,"search must display the matching quest row")
choice.OnClick()
local shown=false
for _,w in ipairs(widgets) do
 if w.kind=="FontString" and type(w.text)=="string" and
    w.text:find("COMPLETE",1,true) and w.text:find("3527",1,true) then
   shown=true
 end
end
assert(shown,"Quest checker must render actual completion flag + exact quest ID")
assert(A:Recent()[1].id==3527,"clicking result saves the recent ID")
assert(KoolSupportDB.sentinel.kept,"pre-existing settings preserved")
print("PASS Quest Checker: optional full catalog, local/Blizzard fallback, duplicate titles, exact quest flags, native UI, settings")
