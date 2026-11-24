-- KS Combat Text visual layer: four movable lanes and an optional native dock.
-- Text payloads are ONLY handed unchanged to native FontString:SetText.
local S=KSCombatText
local KS=KoolSupport
local anchors,active,pools,elapsed,serial={}, {}, {},0,0
local nativeHandle
local paletteOrder={incoming="incoming",heal="heal",notification="notification",target="target"}
local laneTitles={incoming="INCOMING DAMAGE",heal="HEALS",notification="NOTIFICATIONS",
 target="TARGET OBSERVED",native="BLIZZARD TEXT DOCK"}
S.laneTitles=laneTitles

local function nativeFrame()
 return CombatText or CombatTextFrame
end
local oldPoints=nil
local oldFloating=nil
local changedFloating=false
local nativeMoved=false
-- Blizzard renders outgoing damage in world text, NOT the CombatText frame.
-- Forever exposes vertical world-text placement through these two CVars.
-- Native mode intentionally does not claim to restyle Blizzard fonts.
local WORLD_HIT="WorldTextScreenY_v2"
local WORLD_CRIT="WorldTextCritScreenY_v2"
local OUTGOING_CVARS={"floatingCombatTextCombatDamage_v2","floatingCombatTextCombatDamage"}
local outgoingKey,outgoingBefore,outgoingChanged=nil,nil,false
local targetBaseline=nil
local targetMoved=false
local function getCvar(name)
 if C_CVar and type(C_CVar.GetCVar)=="function" then
  local ok,value=pcall(C_CVar.GetCVar,name)
  if ok then return value end
 end
 if type(GetCVar)=="function" then
  local ok,value=pcall(GetCVar,name)
  if ok then return value end
 end
 return nil
end
local function setCvar(name,value)
 if C_CVar and type(C_CVar.SetCVar)=="function" then
  return pcall(C_CVar.SetCVar,name,tostring(value))
 end
 if type(SetCVar)=="function" then return pcall(SetCVar,name,tostring(value)) end
 return false
end
function S:RestoreOutgoingVisibility()
 if not outgoingChanged then return true end
 if KS:IsInCombat() then return false,"Wait until outside combat" end
 if not outgoingKey or outgoingBefore==nil then return false,"Original Blizzard damage setting unavailable" end
 if not setCvar(outgoingKey,outgoingBefore) then
  return false,"Failed to restore outgoing damage text"
 end
 outgoingChanged=false
 return true
end
function S:UpdateOutgoingVisibility()
 if KS:IsInCombat() then return false,"Change Blizzard damage visibility outside combat" end
 -- Blizzard native mode must never have its own outgoing text hidden by
 -- Studio's optional replacement setting; restore it on mode switch.
 if not self:Enabled() or self:Store().mode~="studio" or
    not self:Store().hideNativeOutgoing then
  return self:RestoreOutgoingVisibility()
 end
 local key=outgoingKey
 if not key then
  for _,candidate in ipairs(OUTGOING_CVARS) do
   local value=getCvar(candidate)
   if value~=nil and value~="" then
    key=candidate
    break
   end
  end
 end
 if not key then return false,"Blizzard outgoing-damage CVar unavailable on this client" end
 if not outgoingChanged then
  outgoingBefore=getCvar(key)
  if outgoingBefore==nil then return false,"Could not read original outgoing damage setting" end
 end
 if not setCvar(key,"0") then return false,"Could not hide Blizzard outgoing damage" end
 outgoingKey=key;outgoingChanged=true
 return true
end
function S:RestoreNativeTargetHeight()
 if not targetMoved then return true end
 if KS:IsInCombat() then return false,"Wait until outside combat" end
 if not targetBaseline then return false,"Target text defaults unavailable" end
 if not setCvar(WORLD_HIT,targetBaseline.hit) or
    not setCvar(WORLD_CRIT,targetBaseline.crit) then
  return false,"Could not restore target text height"
 end
 targetMoved=false
 targetBaseline=nil
 self:Store().native.targetSteps=0
 return true
end
function S:NativeTextStatus()
 local hit=getCvar(WORLD_HIT)
 local crit=getCvar(WORLD_CRIT)
 local damage=getCvar(outgoingKey or OUTGOING_CVARS[1])
 local height=hit~=nil and crit~=nil and "available" or "unavailable"
 return ("Target height CVars: %s | Outgoing Blizzard: %s | Self frame: %s"):format(
  height,damage==nil and "unavailable" or damage,
  self.nativeMoveStatus or "unverified")
end
function S:SetNativeTargetHeight(steps)
 if KS:IsInCombat() then return false,"Adjust Blizzard target text out of combat" end
 if type(steps)~="number" or steps~=math.floor(steps) or steps< -40 or steps>40 then
  return false,"Native target text height must be -40 through 40"
 end
 local rawHit,rawCrit=getCvar(WORLD_HIT),getCvar(WORLD_CRIT)
 local hit,crit=tonumber(rawHit),tonumber(rawCrit)
 if not hit or not crit then
  return false,"Forever's native outgoing target-height CVars are unavailable"
 end
 if steps==0 then
  self:Store().native.targetSteps=0
  return self:RestoreNativeTargetHeight()
 end
 if not targetBaseline then
  targetBaseline={hit=rawHit,crit=rawCrit}
 end
 -- 1 screen-height step = 0.002 of the client coordinate fraction.
 local diff=(steps-(self:Store().native.targetSteps or 0))*.002
 if not setCvar(WORLD_HIT,hit+diff) or not setCvar(WORLD_CRIT,crit+diff) then
  return false,"Forever rejected the target height change"
 end
 self:Store().native.targetSteps=steps
 targetMoved=true
 return true
end
function S:RestoreBlizzardAnchor()
 if not nativeMoved or KS:IsInCombat() then return false end
 local frame=nativeFrame()
 if not frame then return false end
 local ok=pcall(function()
  frame:ClearAllPoints()
  if oldPoints and #oldPoints>0 then
   for _,a in ipairs(oldPoints) do frame:SetPoint(a[1],a[2],a[3],a[4],a[5]) end
  else frame:SetPoint("CENTER",UIParent,"CENTER",0,0) end
 end)
 if ok then nativeMoved=false end
 return ok
end
function S:DockBlizzard()
 if KS:IsInCombat() then return false,"Blizzard frame can only move outside combat" end
 local frame=nativeFrame()
 if not frame or type(frame.SetPoint)~="function" or type(frame.GetPoint)~="function" then
  self.nativeMoveStatus="self frame unavailable (outgoing uses target CVars)"
  return false,"The Blizzard CombatText frame is unavailable on this client"
 end
 if not nativeMoved then
  oldPoints={}
  local ok,count=pcall(frame.GetNumPoints,frame)
  if not ok or type(count)~="number" then count=1 end
  for i=1,math.min(count,8) do
   local safe,a,b,c,d,e=pcall(frame.GetPoint,frame,i)
   if safe and a then oldPoints[#oldPoints+1]={a,b,c,d,e} end
  end
 end
 local db=self:Store()
 local ok=pcall(function()
  frame:ClearAllPoints()
  frame:SetPoint("CENTER",UIParent,"CENTER",db.native.x,db.native.y)
 end)
 if ok then nativeMoved=true;self.nativeMoveStatus="self frame moved";return true end
 self.nativeMoveStatus="self frame movement rejected"
 return false,"Forever blocked moving the Blizzard self-combat-text frame"
end
function S:RestoreBlizzardVisibility()
 if not changedFloating or KS:IsInCombat() then return false end
 if type(SetCVar)=="function" and oldFloating~=nil then
  local ok=pcall(SetCVar,"enableFloatingCombatText",oldFloating)
  if ok then changedFloating=false;return true end
 end
 return false
end
function S:UpdateBlizzardVisibility()
 local db=self:Store()
 if KS:IsInCombat() then return false,"Change Blizzard text outside combat" end
 if type(SetCVar)~="function" or type(GetCVar)~="function" then
  return false,"Forever does not expose Blizzard's floating-text CVar"
 end
 if db.nativeHidden then
  if not changedFloating then
   local ok,previous=pcall(GetCVar,"enableFloatingCombatText")
   if not ok then return false,"Could not read Blizzard's current setting" end
   oldFloating=previous
  end
  local ok=pcall(SetCVar,"enableFloatingCombatText","0")
  if ok then changedFloating=true;return true end
  return false,"Could not hide Blizzard's text"
 end
 return self:RestoreBlizzardVisibility()
end
local function fontFor(text,db,crit)
 local path=S:FontFor(db)
 local size=db.size*(crit and db.critScale or 1)
 local ok,res=pcall(text.SetFont,text,path,size,db.outline)
 if not ok or res==false then
  pcall(text.SetFont,text,STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,db.outline)
 end
end
local function createAnchor(key)
 local frame=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
 frame:SetSize(210,115)
 frame:SetFrameStrata("HIGH")
 frame:SetClampedToScreen(true)
 frame:SetMovable(true)
 frame:EnableMouse(false)
 frame:RegisterForDrag("LeftButton")
 frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
 if frame.SetBackdrop then
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
    edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  frame:SetBackdropColor(.05,.09,.11,.78)
  frame:SetBackdropBorderColor(.91,.71,.38,.92)
 end
 local caption=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
 caption:SetPoint("TOP",frame,"TOP",0,-10)
 caption:SetText("|cffffd87a"..laneTitles[key].."|r")
 frame.caption=caption
 frame:SetScript("OnDragStart",function(self)
  if not KS:IsInCombat() and S:Store().unlocked then self:StartMoving() end
 end)
 frame:SetScript("OnDragStop",function(self)
  self:StopMovingOrSizing()
  local cx,cy=self:GetCenter()
  local ux,uy=UIParent:GetCenter()
  if type(cx)=="number" and type(cy)=="number" and type(ux)=="number" and type(uy)=="number" then
   S:MoveLane(key,cx-ux,cy-uy)
  end
 end)
 return frame
end
function S:EnsureFrames()
 if self.framesReady then return true end
 if KS:IsInCombat() then return false end
 -- Preallocate entire pool OUTSIDE combat. Nothing is allocated in Queue.
 nativeHandle=createAnchor("native")
 nativeHandle:SetScript("OnDragStop",function(self)
  self:StopMovingOrSizing()
  local cx,cy=self:GetCenter()
  local ux,uy=UIParent:GetCenter()
  if type(cx)=="number" and type(cy)=="number" and
     type(ux)=="number" and type(uy)=="number" then S:MoveNative(cx-ux,cy-uy) end
 end)
 nativeHandle:Hide()
 for _,key in ipairs(self.LANES) do
  local anchor=createAnchor(key)
  anchors[key]=anchor
  pools[key]={};active[key]={}
 end
 -- Explicit constant avoids secret values controlling pool size.
 for _,key in ipairs(self.LANES) do
  for i=1,20 do
   local line=UIParent:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
   line:SetPoint("CENTER",anchors[key],"CENTER",0,0)
   line:Hide()
   pools[key][i]={text=line,active=false,age=0,serial=0}
  end
 end
 self.framesReady=true
 return true
end
function S:Refresh()
 if not self:Enabled() then
  self:RestoreBlizzardAnchor()
  self:RestoreNativeTargetHeight()
  self:RestoreBlizzardVisibility()
  self:RestoreOutgoingVisibility()
  for _,frame in pairs(anchors) do frame:Hide();frame:EnableMouse(false) end
  if nativeHandle then nativeHandle:Hide();nativeHandle:EnableMouse(false) end
  for _,queue in pairs(pools) do
   for _,slot in ipairs(queue) do slot.active=false;slot.text:Hide() end
  end
  return
 end
 local db=self:Store()
 if db.mode~="studio" then
  -- OnUpdate intentionally stops Studio animations in Native mode.
  -- Expire all Studio slots first or the last visible numbers would freeze.
  for _,queue in pairs(pools) do
   for _,slot in ipairs(queue) do slot.active=false;slot.text:Hide() end
  end
 end
 -- A previously enabled native-hide preference is reapplied only when
 -- the player explicitly re-enables this optional module outside combat.
 if db.nativeHidden and not changedFloating and not KS:IsInCombat() then
  self:UpdateBlizzardVisibility()
 end
 if not KS:IsInCombat() and (db.hideNativeOutgoing or outgoingChanged) then
  self:UpdateOutgoingVisibility()
 end
 if db.mode=="native" and not KS:IsInCombat() then
  self:DockBlizzard()
 else
  self:RestoreBlizzardAnchor()
 end
 if not self:EnsureFrames() then return end
 if nativeHandle then
  if not KS:IsInCombat() then
   nativeHandle:ClearAllPoints()
   nativeHandle:SetPoint("CENTER",UIParent,"CENTER",db.native.x,db.native.y)
  end
  local editing=db.unlocked and db.mode=="native"
  nativeHandle:EnableMouse(editing)
  if editing then nativeHandle:Show() else nativeHandle:Hide() end
 end
 for _,key in ipairs(self.LANES) do
  local anchor=anchors[key]
  local style=db.lanes[key]
  if not KS:IsInCombat() then
   anchor:ClearAllPoints()
   anchor:SetPoint("CENTER",UIParent,"CENTER",style.x,style.y)
  end
  local showEditor=db.unlocked and db.mode=="studio"
  anchor:EnableMouse(showEditor)
  if showEditor then anchor:Show() else anchor:Hide() end
 end
end
function S:Queue(key,value,critical)
 if not self:Enabled() or self:Store().mode~="studio" then return false end
 local style=self:Store().lanes[key]
 if not style or not style.enabled then return false end
 if not pools[key] then
  self.stats.dropped=self.stats.dropped+1
  return false
 end
 local slot
 local list=pools[key]
 local oldest
 for i=1,style.limit do
  local item=list[i]
  if not item.active then slot=item;break end
  if not oldest or item.age>oldest.age then oldest=item end
 end
 if not slot then slot=oldest;self.stats.dropped=self.stats.dropped+1 end
 if not slot then return false end
 local text=slot.text
 -- The possibly-secret value goes directly into the native sink.
 local ok=pcall(text.SetText,text,value)
 if not ok then
  self.stats.errors=self.stats.errors+1
  return false
 end
 serial=serial+1
 slot.active=true
 slot.age=0
 slot.serial=serial
 slot.critical=critical==true
 slot.base=style.size*(slot.critical and style.critScale or 1)
 fontFor(text,style,slot.critical)
 local color=(self.PALETTES[style.palette] or self.PALETTES.classic)[paletteOrder[key]]
 text:SetTextColor(color[1],color[2],color[3],1)
 text:ClearAllPoints()
 text:SetPoint("CENTER",anchors[key],"CENTER",0,0)
 text:Show()
 return true
end
function S:Preview()
 if not self:Enabled() then return false,"Enable KS Combat Text first" end
 if self:Store().mode~="studio" then
  local ok,why=self:SetMode("studio")
  if not ok then return false,why end
 end
 if not self:EnsureFrames() then return false,"Preview outside combat" end
 self:Queue("incoming","-842",false)
 self:Queue("incoming","-2,461",true)
 self:Queue("heal","+1,275",true)
 self:Queue("notification","DODGE",false)
 self:Queue("target","1,583",false)
 return true
end
local ticker=CreateFrame("Frame",nil,UIParent)
ticker:SetScript("OnUpdate",function(_,dt)
 if not S.framesReady or not S:Enabled() then return end
 if type(dt)~="number" or dt<=0 then return end
 elapsed=elapsed+dt
 if elapsed<.016 then return end
 local delta=math.min(elapsed,.07)
 elapsed=0
 local settings=S:Store()
 if settings.mode~="studio" then return end
 for _,key in ipairs(S.LANES) do
  local style=settings.lanes[key]
  for _,slot in ipairs(pools[key]) do
   if slot.active then
    slot.age=slot.age+delta
    if slot.age>=style.lifetime then
     slot.active=false
     slot.text:Hide()
    else
     local x,y,alpha,scale=S:Animation(style.pattern,slot.age,
      style.lifetime,style.speed,style.spread,slot.serial)
     local text=slot.text
     text:ClearAllPoints()
     text:SetPoint("CENTER",anchors[key],"CENTER",x,y)
     text:SetAlpha(alpha*style.opacity)
     if text.SetTextHeight then pcall(text.SetTextHeight,text,slot.base*scale) end
    end
   end
  end
 end
end)
function S:OnModuleDisabled()
 self:Refresh()
end
