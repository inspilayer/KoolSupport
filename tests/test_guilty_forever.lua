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
assert(events.IGNORELIST_UPDATE)
print("PASS Guilty Forever: immediate /ignore prompt, dedupe, persistence, cancel")
