-- KoolSupport Base: lightweight session-only "time since last XP" nudge.
-- A passive player reminder, never a character action, quest automation, or
-- chat broadcast. One XP change resets the clock; 15/30/45... minute nudges.
local KS=KoolSupport
local R={INTERVAL=15*60}
KS.XPReminder=R

local function safeNumber(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if not ok then return nil end
  if type(issecretvalue)=="function" then
    local checked,secret=pcall(issecretvalue,value)
    if not checked or secret then return nil end
  end
  if type(value)~="number" or value~=value or value==math.huge
    or value==-math.huge then return nil end
  return value
end

local function settings()
  local db=KS:GetDatabase().core
  if type(db.xpReminder)~="table" then db.xpReminder={} end
  if type(db.xpReminder.enabled)~="boolean" then
    db.xpReminder.enabled=true
  end
  return db.xpReminder
end
function R:Settings()return settings()end
function R:Now()return safeNumber(GetTime)end
function R:CurrentXP()return safeNumber(UnitXP,"player")end
function R:Eligible()
  local maximum=safeNumber(UnitXPMax,"player")
  if maximum~=nil then return maximum>0 end
  -- If the client has no XP bar, determine max level when possible.
  local level=safeNumber(UnitLevel,"player")
  local cap=safeNumber(GetMaxPlayerLevel)
  if level and cap then return level<cap end
  return nil -- No reliable answer: don't nag max-level characters.
end
function R:Reset(now,xp)
  now=now or self:Now()
  if not now then return false end
  self.lastGainAt=now
  self.lastXP=xp~=nil and xp or self:CurrentXP()
  self.lastAlertNumber=0
  return true
end
function R:Initialize()
  if self.lastGainAt~=nil then return end -- zoning doesn't reset elapsed time
  self:Reset(self:Now(),self:CurrentXP())
end

function R:SetEnabled(on)
  if type(on)~="boolean" then return false,"Expected On or Off" end
  settings().enabled=on
  if on then
    -- Re-enabling starts a fresh timer, never an immediate stale reminder.
    self:Reset(self:Now(),self:CurrentXP())
  end
  return true
end

function R:XPChanged(unit)
  if unit~=nil and unit~="player" then return end
  local now=self:Now()
  if not now then return end
  if not self.lastGainAt then self:Reset(now,self:CurrentXP());return end
  local xp=self:CurrentXP()
  if xp~=nil and self.lastXP~=nil then
    if xp>self.lastXP then self:Reset(now,xp)
    else self.lastXP=xp end
  elseif xp~=nil then
    -- First readable XP update after an unavailable initial sample.
    self:Reset(now,xp)
  else
    -- This event is emitted when the player's XP changes. With a client that
    -- hides the XP read, use the event instead of reading secret values.
    self:Reset(now,nil)
  end
end
function R:LevelChanged()
  -- The XP bar rolls back to zero at a level-up, which still counts as gain.
  self:Reset(self:Now(),self:CurrentXP())
end
function R:Elapsed()
  local now=self:Now()
  if not now or not self.lastGainAt then return nil end
  if now<self.lastGainAt then self:Reset(now,self:CurrentXP());return 0 end
  return math.max(0,now-self.lastGainAt)
end
function R:Status()
  self:Initialize()
  local eligible=self:Eligible()
  if eligible==false then return "Max level: XP reminders paused." end
  if eligible==nil then return "XP progress unavailable on this client." end
  if not settings().enabled then return "XP reminders OFF." end
  local elapsed=self:Elapsed()
  if not elapsed then return "Waiting for game clock." end
  local minutes=math.floor(elapsed/60)
  local nextMinute=15*(math.floor(elapsed/self.INTERVAL)+1)
  return string.format("%d min without XP. Next reminder at %d min.",minutes,nextMinute)
end

function R:Notify(minutes)
  local text=string.format("KoolSupport: %d minutes without XP! Get out of town and earn some experience.",minutes)
  if type(print)=="function" then print("|cffffd87a"..text.."|r") end
  -- A brief center-screen nudge, not a blocking popup or protected action.
  if UIErrorsFrame and type(UIErrorsFrame.AddMessage)=="function" then
    pcall(UIErrorsFrame.AddMessage,UIErrorsFrame,text,1,.79,.38,1)
  end
end
function R:Preview()
  local text="KoolSupport (preview): Get out of town! It's time to earn some XP."
  if type(print)=="function" then print("|cffffd87a"..text.."|r") end
  if UIErrorsFrame and type(UIErrorsFrame.AddMessage)=="function" then
    pcall(UIErrorsFrame.AddMessage,UIErrorsFrame,text,1,.79,.38,1)
  end
end
function R:Check()
  self:Initialize()
  if not settings().enabled or self:Eligible()~=true then return end
  local elapsed=self:Elapsed()
  if not elapsed then return end
  local ordinal=math.floor(elapsed/self.INTERVAL)
  if ordinal<1 or ordinal<=(self.lastAlertNumber or 0) then return end
  -- Never fire multiple notices after a long frame stall or AFK return.
  self.lastAlertNumber=ordinal
  self:Notify(ordinal*15)
end

local driver=CreateFrame("Frame")
R.driver=driver
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("PLAYER_XP_UPDATE")
driver:RegisterEvent("PLAYER_LEVEL_UP")
driver:SetScript("OnEvent",function(_,event,unit)
  if event=="PLAYER_ENTERING_WORLD" then
    R:Initialize()
  elseif event=="PLAYER_XP_UPDATE" then
    R:XPChanged(unit)
  elseif event=="PLAYER_LEVEL_UP" then
    R:LevelChanged()
  end
end)
local elapsed=0
driver:SetScript("OnUpdate",function(_,delta)
  -- One tiny clock check every 10 seconds. No combat scans or chat parsing.
  if type(delta)~="number" or delta<0 then return end
  elapsed=elapsed+delta
  if elapsed<10 then return end
  elapsed=0
  R:Check()
end)
