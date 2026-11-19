-- KS Stealth movable combo-point HUD.
-- Combo points may be secret in Forever. Pass the opaque result directly to
-- Blizzard StatusBar:SetValue; NEVER compare, format or perform math with it.
local S=KSStealth
local TEX="Interface\\TARGETINGFRAME\\UI-StatusBar"
local BACK="Interface\\Buttons\\WHITE8X8"
local COUNT=5
local BAR_WIDTH,BAR_HEIGHT,GAP=25,14,4
local WIDTH=COUNT*BAR_WIDTH+(COUNT-1)*GAP

local function validNumber(value)
  if type(issecretvalue)=="function" then
    local ok,secret=pcall(issecretvalue,value)
    if not ok or secret then return false end
  end
  return type(value)=="number" and value==value and
         value~=math.huge and value~=-math.huge
end

function S:HUDSettings()
  local db=self:Store()
  if db.hudEnabled==nil then db.hudEnabled=true end
  if db.hudLocked==nil then db.hudLocked=true end
  if not validNumber(db.hudX) then db.hudX=0 end
  if not validNumber(db.hudY) then db.hudY=-170 end
  if not validNumber(db.hudScale) then db.hudScale=1 end
  db.hudScale=math.max(.7,math.min(1.8,db.hudScale))
  return db
end

function S:PositionHUD()
  local holder=self.comboHUD
  if not holder then return end
  local db=self:HUDSettings()
  holder:ClearAllPoints()
  holder:SetPoint("CENTER",UIParent,"CENTER",db.hudX,db.hudY)
  holder:SetScale(db.hudScale)
end

function S:SaveHUDPosition()
  if KoolSupport:IsInCombat() or not self.comboHUD or not UIParent then
    return false,"Move the HUD outside combat."
  end
  if type(self.comboHUD.GetCenter)~="function" or
     type(UIParent.GetCenter)~="function" then return false,"Position unavailable" end
  local ok,x,y,ox,oy=pcall(function()
    local a,b=self.comboHUD:GetCenter()
    local c,d=UIParent:GetCenter()
    return a,b,c,d
  end)
  if not ok or not (validNumber(x) and validNumber(y) and
                     validNumber(ox) and validNumber(oy)) then
    self:PositionHUD()
    return false,"Position unavailable"
  end
  local db=self:HUDSettings()
  local dx,dy=x-ox,y-oy
  if type(UIParent.GetWidth)=="function" and type(UIParent.GetHeight)=="function" then
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    if validNumber(width) and validNumber(height) then
      local maxX=math.max(0,width/2-40)
      local maxY=math.max(0,height/2-30)
      dx=math.max(-maxX,math.min(maxX,dx))
      dy=math.max(-maxY,math.min(maxY,dy))
    end
  end
  db.hudX,db.hudY=math.floor(dx+.5),math.floor(dy+.5)
  self:PositionHUD()
  return true
end

function S:EnsureHUD()
  if self.comboHUD then return self.comboHUD end
  -- Create nonsecure display frames only outside combat.
  if not UIParent or KoolSupport:IsInCombat() or type(CreateFrame)~="function" then
    return nil
  end
  local holder=CreateFrame("Frame","KoolSupportComboPointHUD",UIParent)
  holder:SetSize(WIDTH,39)
  holder:SetFrameStrata("MEDIUM")
  holder:SetFrameLevel(25)
  holder:SetMovable(true)
  holder:RegisterForDrag("LeftButton")
  if type(holder.SetClampedToScreen)=="function" then holder:SetClampedToScreen(true) end
  local handle=holder:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  handle:SetPoint("TOP",holder,"TOP",0,0)
  handle:SetText("|cffffd87aDRAG COMBO POINTS|r")
  holder.dragLabel=handle
  holder.bars={}
  for i=1,COUNT do
    local bar=CreateFrame("StatusBar",nil,holder)
    bar:SetPoint("TOPLEFT",holder,"TOPLEFT",(i-1)*(BAR_WIDTH+GAP),-20)
    bar:SetSize(BAR_WIDTH,BAR_HEIGHT)
    if KoolSupport.BarTheme then
      KoolSupport.BarTheme:StyleBar(bar,"dot")
    else
      bar:SetStatusBarTexture(TEX)
      bar:SetStatusBarColor(1,.71,.26,1)
    end
    bar:SetMinMaxValues(i-1,i)
    bar:SetValue(0)
    -- A dark backing makes empty pips visible while positioning, with no
    -- second health/resource widget and no extra secret API reads.
    if type(bar.CreateTexture)=="function" then
      local backing=bar:CreateTexture(nil,"BACKGROUND")
      backing:SetAllPoints(bar)
      backing:SetTexture(BACK)
      backing:SetVertexColor(.11,.14,.13,.82)
    end
    holder.bars[i]=bar
  end
  holder:SetScript("OnDragStart",function(frame)
    if KoolSupport:IsInCombat() or S:HUDSettings().hudLocked then return end
    frame:StartMoving()
  end)
  holder:SetScript("OnDragStop",function(frame)
    if frame.StopMovingOrSizing then frame:StopMovingOrSizing() end
    S:SaveHUDPosition()
  end)
  self.comboHUD=holder
  self:PositionHUD()
  holder:Hide()
  self:RefreshHUDDragState()
  return holder
end

function S:RefreshHUDDragState()
  local holder=self.comboHUD
  if not holder then return end
  local unlocked=not self:HUDSettings().hudLocked
  holder:EnableMouse(unlocked)
  holder.dragLabel:SetShown(unlocked)
end

function S:HideHUD()
  if self.comboHUD then self.comboHUD:Hide() end
end

function S:UpdateHUD()
  local db=self:HUDSettings()
  if not (self.active and self:IsSupportedClass() and db.hudEnabled) then
    self:HideHUD()
    return
  end
  local holder=self:EnsureHUD()
  if not holder then return end
  self:RefreshHUDDragState()
  -- Unlocked HUD stays visible with empty pips even without a target, so it
  -- can be positioned during a quiet moment outside combat.
  local preview=not db.hudLocked
  if type(GetComboPoints)~="function" then
    if preview then
      for _,bar in ipairs(holder.bars) do bar:SetValue(0) end
      holder:Show()
    else self:HideHUD() end
    return
  end
  local validTarget=false
  if type(UnitExists)=="function" then
    local ok,exists=pcall(UnitExists,"target")
    if ok and type(exists)=="boolean" then
      if type(issecretvalue)~="function" or
         (function() local safe,secret=pcall(issecretvalue,exists)
           return safe and not secret end)() then
        validTarget=exists
      end
    end
  end
  if not validTarget then
    if preview then
      for _,bar in ipairs(holder.bars) do bar:SetValue(0) end
      holder:Show()
    else self:HideHUD() end
    return
  end
  -- GetComboPoints may return an opaque/secret number. Never inspect it in Lua.
  local ok,points=pcall(GetComboPoints,"player","target")
  if not ok then
    if preview then
      for _,bar in ipairs(holder.bars) do bar:SetValue(0) end
      holder:Show()
    else self:HideHUD() end
    return
  end
  for _,bar in ipairs(holder.bars) do
    if not pcall(bar.SetValue,bar,points) then self:HideHUD();return end
  end
  holder:Show()
end

function S:SetHUDEnabled(enabled)
  if KoolSupport:IsInCombat() then return false,"Change HUD settings outside combat" end
  self:HUDSettings().hudEnabled=not not enabled
  self:UpdateHUD()
  return true
end

function S:SetHUDLocked(locked)
  if KoolSupport:IsInCombat() then return false,"Unlock or lock the HUD outside combat" end
  self:HUDSettings().hudLocked=not not locked
  self:RefreshHUDDragState()
  self:UpdateHUD()
  return true
end

function S:SetHUDScale(scale)
  if KoolSupport:IsInCombat() then return false,"Resize the HUD outside combat" end
  if not validNumber(scale) then return false,"Invalid HUD scale" end
  self:HUDSettings().hudScale=math.max(.7,math.min(1.8,scale))
  self:PositionHUD()
  return true
end

function S:ResetHUDPosition()
  if KoolSupport:IsInCombat() then return false,"Reset HUD position outside combat" end
  local db=self:HUDSettings()
  db.hudX,db.hudY=0,-170
  self:PositionHUD()
  self:UpdateHUD()
  return true
end
