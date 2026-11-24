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
 if ok then nativeMoved=true;return true end
 return false,"Forever blocked moving the Blizzard CombatText frame"
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
  self:RestoreBlizzardVisibility()
  for _,frame in pairs(anchors) do frame:Hide();frame:EnableMouse(false) end
  if nativeHandle then nativeHandle:Hide();nativeHandle:EnableMouse(false) end
  for _,queue in pairs(pools) do
   for _,slot in ipairs(queue) do slot.active=false;slot.text:Hide() end
  end
  return
 end
 local db=self:Store()
 -- A previously enabled native-hide preference is reapplied only when
 -- the player explicitly re-enables this optional module outside combat.
 if db.nativeHidden and not changedFloating and not KS:IsInCombat() then
  self:UpdateBlizzardVisibility()
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
 if self:Store().mode~="studio" then return false,"Choose Studio mode to preview effects" end
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
