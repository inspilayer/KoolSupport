-- KS Afflictions: game UI only. Remaining DoT damage is a player-owned estimate.
-- NEVER inspect or compare the secret UnitHealth/UnitHealthMax values in Lua.
local _,ns=...
local A=KSAfflictions
local WHITE="Interface\\Buttons\\WHITE8X8"
local UNITS={"target","focus"}
local BACK={modern={.045,.12,.105,.9},classic={.075,.065,.055,.93},minimal={0,0,0,0}}
local function label(parent,text,x,y,width,font)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetWidth(width)
  t:SetJustifyH("LEFT")
  t:SetText(text or "")
  return t
end
local function bar(parent,role)
  local f=CreateFrame("StatusBar",nil,parent)
  if KoolSupport.BarTheme then KoolSupport.BarTheme:StyleBar(f,role)
  else f:SetStatusBarTexture(WHITE);f:SetStatusBarColor(.98,.7,.28,1) end
  return f
end
local function lethalWidget(h)
  -- UI-only comparison: as the estimated DoT damage fill reaches the right edge
  -- of the hidden bar, its anchored icon/word enters the clipping window.
  -- This is approximate, and may not work on every Forever client.
  local clip=CreateFrame("Frame",nil,h)
  clip:SetSize(90,22)
  clip:SetPoint("LEFT",h,"RIGHT",3,0)
  local works=type(clip.SetClipsChildren)=="function" and pcall(clip.SetClipsChildren,clip,true)
  local detector=CreateFrame("StatusBar",nil,clip)
  detector:SetSize(18000,22)
  detector:SetPoint("RIGHT",clip,"RIGHT",0,0)
  detector:SetStatusBarTexture(WHITE)
  detector:SetStatusBarColor(0,0,0,0)
  local edge=detector:GetStatusBarTexture()
  local word=clip:CreateFontString(nil,"OVERLAY","GameFontNormal")
  word:SetText("|cff83ed70DIES|r")
  word:SetWidth(45)
  word:SetJustifyH("RIGHT")
  word:SetPoint("RIGHT",edge,"RIGHT",-1,0)
  local skull=detector:CreateTexture(nil,"OVERLAY")
  skull:SetSize(18,18)
  skull:SetPoint("RIGHT",edge,"RIGHT",-3,0)
  skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
  h.lethalClip=clip
  h.lethal=detector
  h.lethalWord=word
  h.lethalIcon=skull
  h.lethalAvailable=works
end
local function makeHUD(parent,small)
  local h=CreateFrame("Frame",nil,parent)
  h.small=small
  h:SetSize(small and 164 or 282,small and 46 or 81)
  h.bg=h:CreateTexture(nil,"BACKGROUND")
  h.bg:SetAllPoints()
  h.label=label(h,small and "DoTs" or "Target DoTs",8,-4,small and 126 or 215)
  h.count=label(h,"",small and 141 or 255,-4,24,"GameFontHighlightSmall")
  h.health=bar(h,"health")
  h.health:SetPoint("TOPLEFT",h,"TOPLEFT",8,small and -17 or -24)
  h.health:SetSize(small and 148 or 266,small and 6 or 13)
  h.dot=bar(h,"dot")
  h.dot:SetPoint("TOPLEFT",h.health,"BOTTOMLEFT",0,-3)
  h.dot:SetSize(small and 148 or 266,small and 6 or 10)
  h.icons={}
  for i=1,3 do
    local icon=h:CreateTexture(nil,"ARTWORK")
    icon:SetSize(small and 12 or 17,small and 12 or 17)
    icon:SetPoint("TOPLEFT",h,"TOPLEFT",8+(i-1)*(small and 15 or 20),small and -32 or -58)
    icon:Hide()
    h.icons[i]=icon
  end
  if not small then h.spells=label(h,"",72,-59,200,"GameFontHighlightSmall") end
  lethalWidget(h)
  return h
end
A.huds=A.huds or {}
A.plates=A.plates or {}
A.onFrameHUDs=A.onFrameHUDs or {}

-- Read-only discovery of stock unit-frame health StatusBars. Forever builds and
-- UI skins may expose different structures; never infer a bar from a plain Frame.
-- No Blizzard frame properties, secure regions, or original health values change.
local function statusBar(candidate)
  if not candidate or type(candidate.GetObjectType)~="function" then return nil end
  local ok,kind=pcall(candidate.GetObjectType,candidate)
  return ok and kind=="StatusBar" and candidate or nil
end
function A:ResolveUnitHealthBar(unit)
  if unit~="target" and unit~="focus" then return nil end
  local root=unit=="target" and TargetFrame or FocusFrame
  if not root then return nil end
  local named=unit=="target" and TargetFrameHealthBar or FocusFrameHealthBar
  local content=root.TargetFrameContent or root.FocusFrameContent
  local main=content and (content.TargetFrameContentMain or content.FocusFrameContentMain)
  local container=main and main.HealthBarsContainer
  return statusBar(named) or statusBar(root.healthbar) or statusBar(root.healthBar)
    or statusBar(root.HealthBar) or statusBar(container and container.HealthBar)
    or statusBar(container)
end

-- A narrow, noninteractive overlay on Blizzard's EXISTING health bar. Never
-- reparent, resize, recolor, or replace the original health StatusBar.
function A:EnsureOnFrame(unit,native)
  if not native then return nil end
  local h=self.onFrameHUDs[unit]
  if h then
    if h.nativeBar~=native then
      if KoolSupport:IsInCombat() then h:Hide();return nil end
      h:ClearAllPoints()
      h:SetAllPoints(native)
      h.nativeBar=native
    end
    return h
  end
  if KoolSupport:IsInCombat() then return nil end
  h=CreateFrame("Frame",nil,UIParent)
  h:SetAllPoints(native)
  h:EnableMouse(false)
  local level=type(native.GetFrameLevel)=="function" and native:GetFrameLevel()
  if type(level)=="number" then h:SetFrameLevel(level+4) end
  h.nativeBar=native
  h.dot=bar(h,"dot")
  h.dot:SetPoint("BOTTOMLEFT",h,"BOTTOMLEFT",0,0)
  h.dot:SetPoint("BOTTOMRIGHT",h,"BOTTOMRIGHT",0,0)
  h.dot:SetHeight(4)
  h.icons={}
  for i=1,3 do
    local icon=h:CreateTexture(nil,"OVERLAY")
    icon:SetSize(13,13)
    icon:SetPoint("BOTTOMLEFT",h,"TOPLEFT",(i-1)*15,2)
    icon:Hide()
    h.icons[i]=icon
  end
  lethalWidget(h)
  self.onFrameHUDs[unit]=h
  return h
end

function A:AnchorUnitHUD(unit,h)
  if unit~="target" and unit~="focus" then return end
  local pos=self:HUDPosition(unit)
  h:ClearAllPoints()
  if pos then
    h:SetPoint("CENTER",UIParent,"CENTER",pos.x,pos.y)
  else
    -- Preserve the original anchoring until the player chooses a position.
    local anchor=unit=="target" and TargetFrame or FocusFrame
    if anchor then h:SetPoint("TOP",anchor,"BOTTOM",0,unit=="target" and -14 or -16)
    else h:SetPoint("CENTER",UIParent,"CENTER",unit=="target" and 170 or -170,-150) end
  end
end
function A:EnsureUnit(unit)
  if self.huds[unit] then return self.huds[unit] end
  -- Parent to UIParent so the player can move these independently of
  -- Blizzard's target/focus frames. Nameplate HUDs are never draggable.
  local h=makeHUD(UIParent,false)
  h:SetMovable(true)
  h:SetClampedToScreen(true)
  h:SetUserPlaced(false)
  h.label:SetText(unit=="target" and "Target DoTs" or "Focus DoTs")
  local grip=CreateFrame("Frame",nil,h)
  grip:SetPoint("TOPLEFT",h,"TOPLEFT",0,0)
  grip:SetSize(220,21)
  grip:EnableMouse(true)
  grip:RegisterForDrag("LeftButton")
  local dragging=false
  grip:SetScript("OnDragStart",function()
    if KoolSupport:IsInCombat() then return end
    -- Convert any default unit-frame anchor to a free screen anchor before
    -- moving. Keep the same visible position to avoid a first-drag jump.
    local cx,cy=h:GetCenter()
    local ux,uy=UIParent:GetCenter()
    local uiScale=UIParent:GetEffectiveScale()
    local frameScale=h:GetEffectiveScale()
    if type(cx)~="number" or type(cy)~="number" or
       type(ux)~="number" or type(uy)~="number" or
       type(uiScale)~="number" or uiScale<=0 or
       type(frameScale)~="number" or frameScale<=0 then return end
    h:ClearAllPoints()
    h:SetPoint("CENTER",UIParent,"CENTER",cx*frameScale/uiScale-ux,cy*frameScale/uiScale-uy)
    dragging=true
    h:StartMoving()
  end)
  grip:SetScript("OnDragStop",function()
    if not dragging then return end
    dragging=false
    h:StopMovingOrSizing()
    h:SetUserPlaced(false)
    local ok=self:SaveHUDPosition(unit,h)
    self:AnchorUnitHUD(unit,h)
  end)
  grip:SetScript("OnEnter",function(self)
    if not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
    GameTooltip:AddLine("Drag to move "..(unit=="target" and "Target DoTs" or "Focus DoTs"))
    GameTooltip:AddLine("Left-drag the title outside combat; position saves per character.",.8,.8,.8,true)
    GameTooltip:Show()
  end)
  grip:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide() end end)
  h.dragHandle=grip
  self:AnchorUnitHUD(unit,h)
  self.huds[unit]=h
  return h
end
function A:EnsurePlate(plate)
  if self.plates[plate] then return self.plates[plate] end
  local h=makeHUD(plate,true)
  h:SetPoint("TOP",plate,"BOTTOM",0,-self:Store().offsetY)
  self.plates[plate]=h
  return h
end
function A:StyleHUD(h,db)
  local classic=db.style=="classic"
  local c=BACK[db.style] or BACK.modern
  h.bg:SetColorTexture(c[1],c[2],c[3],c[4])
  if db.style=="minimal" then h:SetHeight(h.small and 37 or 66)
  else h:SetHeight(h.small and 46 or 81) end
  h.health:SetHeight(h.small and math.max(4,math.floor(db.height*.36)) or db.height)
  h.dot:SetHeight(h.small and math.max(4,math.floor(db.height*.35)) or math.max(5,math.floor(db.height*.65)))
  h.health:SetStatusBarColor(classic and .58 or .26,classic and .18 or .76,classic and .18 or .53,1)
  h.label:SetTextColor(classic and 1 or .92,classic and .79 or .89,classic and .45 or .74)
  if h.spells then h.spells:SetShown(db.showLabels) end
end
local function spellTexture(dot)
  if type(dot.spellID)~="number" then return nil end
  local fn=(C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture
  if type(fn)~="function" then return nil end
  local ok,texture=pcall(fn,dot.spellID)
  if ok and texture then return texture end
  return nil
end
function A:PaintOnFrame(h,unit)
  local dots,total=self:Snapshot(unit)
  local db=self:Store()
  local red,green,blue=self:DotColor(dots[1] and dots[1].school)
  h.dot:SetStatusBarColor(red,green,blue,.94)
  -- Protected/secret health flows ONLY to WoW StatusBar setters. The estimate
  -- is from our owned DoT tracker; never compare it with UnitHealth in Lua.
  local ok=pcall(function()
    h.dot:SetMinMaxValues(0,UnitHealthMax(unit))
    h.dot:SetValue(total)
    h.lethal:SetMinMaxValues(0,UnitHealth(unit))
    h.lethal:SetValue(total)
  end)
  if not ok then h:Hide();return end
  for i,icon in ipairs(h.icons) do
    local dot=dots[i]
    local texture=dot and db.showIcons and spellTexture(dot)
    if texture then icon:SetTexture(texture);icon:Show() else icon:Hide() end
  end
  local allowed=h.lethalAvailable and #dots>0 and self:LethalOn(unit)
  local mode=db.lethalMode
  h.lethalClip:SetShown(allowed)
  h.lethalWord:SetShown(allowed and (mode=="dies" or mode=="both"))
  h.lethalIcon:SetShown(allowed and (mode=="skull" or mode=="both"))
  h.lethalWord:ClearAllPoints()
  h.lethalWord:SetPoint("RIGHT",h.lethal:GetStatusBarTexture(),"RIGHT",mode=="both" and -22 or -1,0)
  h:Show()
end

function A:Paint(h,unit)
  local dots,total=self:Snapshot(unit)
  local db=self:Store()
  self:StyleHUD(h,db)
  local red,green,blue=self:DotColor(dots[1] and dots[1].school)
  h.dot:SetStatusBarColor(red,green,blue,1)
  -- Only the WoW StatusBar receives secret health. No Lua branching, math, label
  -- formatting, numeric comparisons or logs on those values.
  local ok=pcall(function()
    h.health:SetMinMaxValues(0,UnitHealthMax(unit))
    h.health:SetValue(UnitHealth(unit))
    h.dot:SetMinMaxValues(0,UnitHealthMax(unit))
    h.dot:SetValue(total)
    h.lethal:SetMinMaxValues(0,UnitHealth(unit))
    h.lethal:SetValue(total)
  end)
  if not ok then h:Hide();return end
  h.count:SetText(tostring(#dots))
  local names={}
  for i=1,3 do
    local dot=dots[i]
    local icon=h.icons[i]
    local texture=dot and db.showIcons and spellTexture(dot)
    if texture then icon:SetTexture(texture);icon:Show() else icon:Hide() end
    if dot and h.spells and type(dot.name)=="string" then
      local expires=type(dot.expiresAt)=="number" and math.max(0,dot.expiresAt-GetTime()) or nil
      names[#names+1]=dot.name..(expires and string.format(" %.0fs",expires) or "")
    end
  end
  if h.spells then
    h.spells:SetText(#names>0 and table.concat(names," · ") or "No active DoTs")
  end
  local mode=db.lethalMode
  local allowed=h.lethalAvailable and self:LethalOn(unit)
  h.lethalClip:SetShown(allowed)
  h.lethalWord:SetShown(allowed and (mode=="dies" or mode=="both"))
  h.lethalIcon:SetShown(allowed and (mode=="skull" or mode=="both"))
  if mode=="both" then
    h.lethalWord:ClearAllPoints()
    h.lethalWord:SetPoint("RIGHT",h.lethal:GetStatusBarTexture(),"RIGHT",-22,0)
  else
    h.lethalWord:ClearAllPoints()
    h.lethalWord:SetPoint("RIGHT",h.lethal:GetStatusBarTexture(),"RIGHT",-1,0)
  end
  h:Show()
end
function A:RefreshAll()
  local db=self:Store()
  local enabled=KoolSupport:IsModuleEnabled("ks_afflictions")
  for _,unit in ipairs(UNITS) do
    local visible=enabled and db[unit] and type(UnitExists)=="function" and UnitExists(unit)
    local existing=self.onFrameHUDs[unit]
    local native=visible and db.onFrame and self:ResolveUnitHealthBar(unit) or nil
    local overlay=native and self:EnsureOnFrame(unit,native) or nil
    if overlay and (not native.IsShown or native:IsShown()) then
      local legacy=self.huds[unit]
      if legacy then legacy:Hide() end
      self:PaintOnFrame(overlay,unit)
    else
      if existing then existing:Hide() end
      -- Some client skins do not expose a standard health StatusBar. Keep the
      -- existing movable HUD available rather than silently losing DoT data.
      local h=self:EnsureUnit(unit)
      if visible then
        h:SetScale(db.scale)
        self:Paint(h,unit)
      else h:Hide() end
    end
  end
  local seen={}
  if enabled and db.nameplates and C_NamePlate and C_NamePlate.GetNamePlates then
    for _,plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
      local unit=plate.namePlateUnitToken
      if type(unit)=="string" then
        local h=self:EnsurePlate(plate)
        seen[plate]=true
        h:SetScale(db.scale)
        h:ClearAllPoints()
        h:SetPoint("TOP",plate,"BOTTOM",0,-db.offsetY)
        self:Paint(h,unit)
      end
    end
  end
  for plate,h in pairs(self.plates) do if not seen[plate] then h:Hide() end end
end
function A:HideAll()
  for _,h in pairs(self.huds) do h:Hide() end
  for _,h in pairs(self.onFrameHUDs) do h:Hide() end
  for _,h in pairs(self.plates) do h:Hide() end
end
function A:Enable() self:RefreshAll() end
function A:Disable() self:HideAll() end
local driver=CreateFrame("Frame")
local timer=0
driver:SetScript("OnUpdate",function(_,elapsed)
  timer=timer+elapsed
  if timer<.2 then return end
  timer=0
  if KoolSupport:IsModuleEnabled("ks_afflictions") and A:TrackerReady() then A:RefreshAll() end
end)
for _,event in ipairs({"PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED",
  "NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_ENTERING_WORLD"}) do
  driver:RegisterEvent(event)
end
driver:SetScript("OnEvent",function()
  if A:TrackerReady() then A:RefreshAll() end
end)
