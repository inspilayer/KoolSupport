-- Guilty Forever slash-command post-hook, persistence and deduplication.
KoolSupportDB={}
local hooks={}
SlashCmdList={IGNORE=function()end}
C_FriendList={AddIgnore=function()end,AddOrDelIgnore=function()end,
 GetNumIgnores=function()return 0 end,GetIgnoreName=function()return nil end}
hooksecurefunc=function(tbl,name,cb)
 assert(type(tbl[name])=="function")
 hooks[#hooks+1]={tbl=tbl,name=name,cb=cb}
end
local events={}
CreateFrame=function()
 return {RegisterEvent=function(_,name)events[name]=true end,
         SetScript=function(self,_,cb)self.OnEvent=cb end}
end
local prompts={}
StaticPopupDialogs={}
StaticPopup_Show=function(id,name,_,data)
 prompts[#prompts+1]={id=id,name=name,data=data}
end
KoolSupport={
 GetDatabase=function()return KoolSupportDB end,
 IsModuleEnabled=function()return true end
}
assert(loadfile("addons/KSGuiltyForever/GuiltyForever.lua"))()
local A=KSGuiltyForever
assert(#hooks>=1,"slash ignore post-hook missing")
local function request(name)
 for _,h in ipairs(hooks) do
  if h.tbl==SlashCmdList and h.name=="IGNORE" then h.cb(name) end
 end
end
request("Griefer-SomeRealm")
assert(#prompts==1 and prompts[1].name=="Griefer-SomeRealm",
 "direct /ignore must prompt")
request("Griefer-SomeRealm")
assert(#prompts==1,"duplicate pending popup")
local popup=StaticPopupDialogs.KS_GUILTY_FOREVER
assert(popup and popup.OnAccept)
popup.OnAccept({editBox={GetText=function()return "Ninja looted the boss" end}},"Griefer-SomeRealm")
assert(A:Get("Griefer-SomeRealm").reason=="Ninja looted the boss")
assert(A:Get("Griefer-SomeRealm").kind=="ignore")
request("Griefer-SomeRealm")
assert(#prompts==1,"existing note must not re-prompt")
request("AnotherPlayer")
assert(#prompts==2)
popup.OnCancel(nil,"AnotherPlayer")
request("AnotherPlayer")
assert(#prompts==3,"cancel allows future explicit prompt")
-- Forever's UnitName() second result is a SURNAME, not a realm.
assert(A:Key("Soqz Rotweaver")=="soqz rotweaver")
assert(A:Key("Soqz-Rotweaver")=="soqz rotweaver")
assert(A:IsFullName("Soqz Rotweaver"))
assert(not A:IsFullName("Soqz"))
assert(A:UnitFullName("Soqz","Rotweaver")=="Soqz Rotweaver")
assert(A:Save("Soqz Rotweaver","Ganked my alt","enemy"))
assert(A:Save("Soqz Hoofmender","Ninja loot","enemy"))
assert(not A:Save("Soqz","Ambiguous tag","enemy"))
assert(A:Get("Soqz-Rotweaver").reason=="Ganked my alt")
assert(A:Get("Soqz Hoofmender").reason=="Ninja loot")
assert(A:Save("Legacy Surname","Stored historically","enemy"))
local db=KoolSupportDB.modules.ks_guilty_forever.notes
local old=db["legacy surname"]
db["legacy surname"]=nil
db["legacy-surname"]=old
assert(A:Get("Legacy Surname").reason=="Stored historically")
assert(A:Save("Legacy Surname","Updated","enemy"))
assert(db["legacy-surname"]==nil and db["legacy surname"].reason=="Updated")
-- A full name must never fall back to the first name and cause false positives.
A:Save("Soqz","Legacy first-name note","ignore")
assert(A:Get("Soqz Rival")==nil)
local currentName,currentSurname="Soqz","Rotweaver"
UnitExists=function(unit)return unit=="target" or unit=="party1" end
UnitIsPlayer=function(unit)return unit=="target" end
UnitIsEnemy=function(_,unit)return unit=="target" end
UnitName=function()return currentName,currentSurname end
IsInGroup=function()return true end
local alerts={}
print=function(msg)alerts[#alerts+1]=msg end
A:CheckGroup()
assert(#alerts==1 and alerts[1]:find("Soqz Rotweaver",1,true))
currentSurname="Rival"
A:CheckGroup()
assert(#alerts==1,"Other players with same first name must never match")
currentSurname="Hoofmender"
A:CheckEnemyTarget()
assert(#alerts==2 and alerts[2]:find("Soqz Hoofmender",1,true))
currentSurname="Rival"
A:CheckEnemyTarget()
assert(#alerts==2,"Enemy alerts must match full name")
request("Another Fullname")
assert(prompts[#prompts].name=="Another Fullname","Slash /ignore must retain surname")
assert(events.IGNORELIST_UPDATE)
print("PASS Guilty Forever: immediate /ignore prompt, dedupe, persistence, cancel")
