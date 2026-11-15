-- KoolSupport Base: session XP inactivity reminder (not a child addon).
local clock=100
local playerXP=250
local xpMax=1100
local secret={}
local chat={}
local notices={}
local frames={}
issecretvalue=function(v)return rawequal(v,secret)end
GetTime=function()return clock end
UnitXP=function(unit)assert(unit=="player");return playerXP end
UnitXPMax=function(unit)assert(unit=="player");return xpMax end
local originalPrint=print
print=function(msg)chat[#chat+1]=msg end
UIErrorsFrame={AddMessage=function(_,msg)notices[#notices+1]=msg end}
CreateFrame=function()
 local frame={events={}}
 function frame:RegisterEvent(ev)self.events[ev]=true end
 function frame:SetScript(ev,fn)self[ev]=fn end
 frames[#frames+1]=frame
 return frame
end
local sentinel={original=true}
KoolSupportDB={keep=sentinel,core={enabled={}}}
KoolSupport={
 GetDatabase=function()return KoolSupportDB end,
}
assert(loadfile("addons/KoolSupport/XPReminder.lua"))()
local R=KoolSupport.XPReminder
local driver=assert(R.driver)
assert(R.INTERVAL==900)
assert(driver.events.PLAYER_ENTERING_WORLD and driver.events.PLAYER_XP_UPDATE
 and driver.events.PLAYER_LEVEL_UP)
assert(driver.OnUpdate and driver.OnEvent)
assert(R:Settings().enabled==true,"Per-character reminders default enabled")
assert(KoolSupportDB.keep==sentinel,"Do not overwrite unrelated settings")
assert(#chat==0 and #notices==0,"Cold load must never announce itself")
driver.OnEvent(driver,"PLAYER_ENTERING_WORLD")
local started=R.lastGainAt
driver.OnEvent(driver,"PLAYER_ENTERING_WORLD")
assert(R.lastGainAt==started,"Zoning must not reset the timer")
local function tick(seconds)
 clock=clock+seconds
 driver.OnUpdate(driver,seconds)
end
tick(899)
assert(#chat==0,"No nudge earlier than 15 minutes")
tick(1)
R:Check() -- real client schedules a bounded check about every 10 seconds
assert(#chat==1 and #notices==1 and chat[1]:find("15 minutes without XP",1,true))
driver.OnUpdate(driver,10)
assert(#chat==1,"No duplicate notification in same 15-min window")
-- Changing something other than player XP never counts.
clock=clock+25
driver.OnEvent(driver,"PLAYER_XP_UPDATE","pet")
assert(R.lastGainAt==started)
-- Zero change is not a gain; updates can occur without an increase.
driver.OnEvent(driver,"PLAYER_XP_UPDATE","player")
assert(R.lastGainAt==started)
clock=clock+900
R:Check()
assert(#chat==2 and chat[2]:find("30 minutes without XP",1,true))
-- Actual XP gained immediately resets the time-since-XP clock.
playerXP=400
driver.OnEvent(driver,"PLAYER_XP_UPDATE","player")
assert(R.lastGainAt==clock and R.lastAlertNumber==0)
tick(900)
assert(#chat==3 and chat[3]:find("15 minutes without XP",1,true))
-- A level-up resets the timer even though the XP bar wraps to zero.
clock=clock+50
playerXP=0
driver.OnEvent(driver,"PLAYER_LEVEL_UP",60)
assert(R.lastGainAt==clock and R.lastXP==0)
clock=clock+898
R:Check()
assert(#chat==3)
clock=clock+2
R:Check()
assert(#chat==4)
-- Never replay five old notifications after the client pauses or AFKs.
clock=clock+6500
R:Check()
assert(#chat==5 and #notices==5)
R:Check()
assert(#chat==5)
assert(R:Status():find("min without XP",1,true))
-- If max level, XP bar max is zero and warning must be suppressed.
xpMax=0
clock=clock+900
R:Check()
assert(#chat==5 and R:Status():find("Max level",1,true))
xpMax=1100
assert(R:SetEnabled(false))
clock=clock+900
R:Check()
assert(#chat==5 and R:Status()=="XP reminders OFF.")
assert(KoolSupportDB.core.xpReminder.enabled==false)
assert(R:SetEnabled(true))
assert(R.lastGainAt==clock,"Re-enabling should not instantly nag with stale time")
R:Check()
assert(#chat==5)
-- Preview is explicit, does not affect XP/timer accounting.
local lastGain=R.lastGainAt
R:Preview()
assert(#chat==6 and #notices==6 and R.lastGainAt==lastGain)
assert(chat[#chat]:find("preview",1,true))
clock=clock+900
R:Check()
assert(#chat==7)
-- Restoring an old character choice must not overwrite it.
KoolSupportDB.core.xpReminder.enabled=false
assert(R:Settings().enabled==false)
assert(not R:SetEnabled("yes"))
-- Fails closed on protected XPMax; no artificial max-level nags.
KoolSupportDB.core.xpReminder.enabled=true
xpMax=secret
clock=clock+900
R:Check()
assert(#chat==7 and R:Eligible()==nil)
xpMax=1100
playerXP=secret
clock=clock+2
driver.OnEvent(driver,"PLAYER_XP_UPDATE","player")
assert(R.lastGainAt==clock,"XP update event handles unreadable player XP safely")
assert(#chat==7)
-- A backwards game clock (rare reload/runtime anomaly) restarts at zero.
clock=10
assert(R:Elapsed()==0 and R.lastGainAt==10)
-- Status and server actions cannot send messages merely by being inspected.
local status=R:Status()
assert(type(status)=="string" and #chat==7)
print=originalPrint
print("PASS XP reminder: 15-minute cadence, actual XP reset, level-up, UI notice, pause, max level, privacy, session reset")
