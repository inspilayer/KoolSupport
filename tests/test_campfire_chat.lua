-- Offline contract: campfire buff must gate every player-clicked SAY.
-- No network calls, chat timers, macro modifications, or unsolicited broadcasts.
local calls,frames={},{}
local clock=100
local hasAura=false
KoolSupport={
 IsModuleEnabled=function(_,id)return id=="ks_campfire_chat" and not _G.moduleOff end,
 RegisterModule=function(self,def)self.module=def end,
 RegisterPage=function(self,page)self.page=page end,
}
local function frame(kind)
 local f={kind=kind,enabled=true}
 function f:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
 function f:SetScript(event,cb)self.scripts=self.scripts or {};self.scripts[event]=cb end
 function f:CreateFontString()return frame("FontString")end
 function f:SetSize(w,h)self.w=w;self.h=h end
 function f:SetPoint(...)self.point={...}end
 function f:SetWidth(w)self.w=w end
 function f:SetJustifyH()end
 function f:SetText(text)self.text=text end
 function f:SetEnabled(enabled)self.enabled=enabled end
 return f
end
CreateFrame=function(kind)
 local f=frame(kind)
 frames[#frames+1]=f
 return f
end
GetTime=function()return clock end
C_UnitAuras={
 GetPlayerAuraBySpellID=function(id)
  assert(id==1283391)
  return hasAura and {spellId=id,name="Campfire Nearby"} or nil
 end,
 GetAuraDataByIndex=function()return nil end,
}
SendChatMessage=function(message,channel)
 calls[#calls+1]={message=message,channel=channel}
 return true
end
local runner=assert(loadfile("addons/KSCampfireChat/Content.lua"))
runner()
runner=assert(loadfile("addons/KSCampfireChat/CampfireChat.lua"))
runner()
runner=assert(loadfile("addons/KSCampfireChat/UI.lua"))
runner()
runner=assert(loadfile("addons/KSCampfireChat/Module.lua"))
runner()
local A=KSCampfireChat
assert(A.CAMPFIRE_SPELL_ID==1283391)
assert(KoolSupport.module.id=="ks_campfire_chat")
assert(KoolSupport.module.defaultEnabled and #KoolSupport.module.requires==0)
assert(KoolSupport.page.id=="campfire_chat")
assert(#calls==0 and A.lastSent==nil,"Cold load must never broadcast")
for _,kind in ipairs({"joke","spooky","ramble","edgy"}) do
 assert(type(A.lines[kind])=="table" and #A.lines[kind]>=12)
 local seen={}
 for _,str in ipairs(A.lines[kind]) do
  assert(#str>0 and #str<=240,"Each story must fit in one /say message")
  assert(not str:find("%c"),"Chat cannot contain control characters")
  assert(not seen[str],"Story categories should not contain duplicates")
  seen[str]=true
 end
end
assert(not A:CampfireNearby())
local ok,why=A:Tell("spooky")
assert(not ok and why:find("Campfire Nearby",1,true))
assert(#calls==0 and next(A.bags)==nil,"No content drawn or chat sent without aura")
-- A page can be opened and refreshed while unbuffed; no chat should appear.
local parent=frame("Frame")
KoolSupport.page.build(parent)
assert(A.view and A.view.refresh)
local buttons={}
for _,f in ipairs(frames) do if f.kind=="Button" then buttons[#buttons+1]=f end end
assert(#buttons==5,"Four story buttons and one refresh button")
for i=1,4 do assert(not buttons[i].enabled,"Stories disabled without buff") end
assert(not buttons[5].scripts or type(buttons[5].scripts.OnClick)=="function")
assert(#calls==0)
-- A UNIT_AURA signal is a display-only refresh, never a chat broadcast.
local driver
for _,f in ipairs(frames) do if f.events and f.events.UNIT_AURA then driver=f end end
assert(driver and driver.events.PLAYER_ENTERING_WORLD)
hasAura=true
driver.scripts.OnEvent(driver,"UNIT_AURA","target")
assert(not buttons[1].enabled,"Other units must not unlock controls")
driver.scripts.OnEvent(driver,"UNIT_AURA","player")
for i=1,4 do assert(buttons[i].enabled,"Campfire aura unlocks the buttons")end
assert(#calls==0,"Aura gain must never trigger SAY")
-- The literal button callback must send exactly one short, nearby SAY.
buttons[2].scripts.OnClick()
assert(#calls==1 and calls[1].channel=="SAY")
assert(A.lastSent==clock)
clock=clock+1
buttons[1].scripts.OnClick()
assert(#calls==1,"Cooldown must reject rapid repeated clicks")
assert(A.lastSent==100)
clock=clock+10
-- One category cycles without repeats.
local seen={}
for n=1,#A.lines.joke do
 local ok,line=A:Tell("joke")
 assert(ok and not seen[line])
 seen[line]=true
 clock=clock+10
end
local previous=A.lastChoice.joke
local ok,nextLine=A:Tell("joke")
assert(ok and nextLine~=A.lines.joke[previous],
  "The first story in a refreshed bag must differ from the last one")
-- Ensure every successful request sends exactly once with no queued output.
assert(#calls==1+#A.lines.joke+1)
for _,entry in ipairs(calls) do
 assert(entry.channel=="SAY" and #entry.message<=240)
end
clock=clock+10
_G.moduleOff=true
ok=A:Tell("ramble")
assert(not ok and #calls==1+#A.lines.joke+1)
_G.moduleOff=false
hasAura=false
driver.scripts.OnEvent(driver,"PLAYER_ENTERING_WORLD")
assert(not buttons[1].enabled)
ok=A:Tell("edgy")
assert(not ok and #calls==1+#A.lines.joke+1)
-- Classic fallbacks work when modern Aura APIs do not.
C_UnitAuras=nil
UnitBuff=function(_,index)
 if index==1 then return "Campfire Nearby",nil,nil,nil,nil,nil,nil,nil,nil,1283391 end
 return nil
end
assert(A:CampfireNearby(),"UnitBuff detects exact campfire buff")
UnitBuff=function(_,index)
 if index==1 then return "Someone Else's Hearth",nil,nil,nil,nil,nil,nil,nil,nil,12 end
 return nil
end
assert(not A:CampfireNearby(),"Other buffs never count")
UnitBuff=nil
UnitAura=function(_,index)
 if index==1 then return "Campfire Nearby" end
 return nil
end
assert(A:CampfireNearby(),"UnitAura detects campfire buff as final fallback")
UnitAura=nil
assert(not A:CampfireNearby(),"Missing aura API fails closed")
-- Unavailable chat API also fails closed; no queued, delayed retry.
C_UnitAuras={GetPlayerAuraBySpellID=function()return {spellId=1283391}end}
SendChatMessage=nil
C_ChatInfo=nil
clock=clock+10
ok,why=A:Tell("spooky")
assert(not ok and why:find("unavailable",1,true))
assert(#calls==1+#A.lines.joke+1)
SendChatMessage=function()error("restricted SAY")end
ok,why=A:Tell("spooky")
assert(not ok and why:find("rejected",1,true))
assert(#calls==1+#A.lines.joke+1)
print("PASS campfire chat: 64 original lines, buff gating, guarded SAY, cooldown, shuffled bags, optional module and UI")
