-- Unified bars for KS Afflictions. Only observational UI updates; combat health secrets
-- go directly into StatusBar sinks, NEVER into numeric comparisons or branching.
local _,ns=...
local A=KSAfflictions
local WHITE="Interface\\Buttons\\WHITE8X8"
local ALL={"target","focus"}
local function safeStatus(bar,fn)
  -- Client API inconsistencies should hide an individual view, not break gameplay.
  return pcall(fn)
end
local function font(parent,text,x,y,w,size)
  local t=parent:CreateFontString(nil,"OVERLAY",size or "GameFontNormalSmall")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetWidth(w)
  t:SetJustifyH("LEFT")
  t:SetText(text or "")
  return t
end
local function status(parent,role)
  local b=CreateFrame("StatusBar",nil,parent)
  if KoolSupport.BarTheme then KoolSupport.BarTheme:StyleBar(b,role)
  else b:SetStatusBarTexture(WHITE);b:SetStatusBarColor(.99,.71,.26,1) end
  return b
end
local function hud(parent,small)
  local h=CreateFrame("Frame",nil,parent)
  h:SetSize(small and 142 or 264,small and 31 or 63)
  if KoolSupport.BarTheme then KoolSupport.BarTheme:FrameBackground(h,.82) end
  h.label=font(h,small and "DoTs" or "Target DoTs",6,-3,small and 110 or 200,"GameFontNormalSmall")
  h.count=font(h,"",small and 112 or 219,-3,small and 26 or 40,"GameFontHighlightSmall")
  h.health=status(h,"health")
  h.health:SetPoint("TOPLEFT",h,"TOPLEFT",6,small and -15 or -22)
  h.health:SetSize(small and 130 or 252,small and 5 or 11)
  h.dot=status(h,"dot")
  h.dot:SetPoint("TOPLEFT",h.health,"BOTTOMLEFT",0,-2)
  h.dot:SetSize(small and 130 or 252,small and 5 or 10)
  if not small then
    h.spells=font(h,"No active DoTs",6,-48,248,"GameFontHighlightSmall")
    -- No secret comparisons: the long invisible StatusBar is clipped, exposing the
    -- icon only when raw remaining damage visually reaches secret target health.
    local clip=CreateFrame("Frame",nil,h)
    clip:SetSize(17,17)
    clip:SetPoint("TOPRIGHT",h,"TOPRIGHT",-6,-1)
    if clip.SetClipsChildren then clip:SetClipsChildren(true) end
    local detector=CreateFrame("StatusBar",nil,clip)
    detector:SetSize(12000,17)
    detector:SetPoint("RIGHT",clip,"RIGHT",0,0)
    detector:SetStatusBarTexture(WHITE)
    detector:SetStatusBarColor(0,0,0,0)
    local skull=detector:CreateTexture(nil,"OVERLAY")
    skull:SetSize(17,17)
    skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    skull:SetPoint("RIGHT",detector:GetStatusBarTexture(),"RIGHT")
    h.lethal=detector
    h.lethalClip=clip
  end
  return h
end
A.huds=A.huds or {}
A.plates=A.plates or {}
function A:EnsureUnit(unit)
  if self.huds[unit] then return self.huds[unit] end
  local anchor=unit=="target" and TargetFrame or FocusFrame
  local parent=anchor or UIParent
  local h=hud(parent,false)
  if anchor then h:SetPoint("TOP",anchor,"BOTTOM",0,-(unit=="target" and 14 or 16))
  else h:SetPoint("CENTER",UIParent,"CENTER",unit=="target" and 170 or -170,unit=="target" and -140 or -170) end
  h.label:SetText(unit=="target" and "Target DoTs" or "Focus DoTs")
  self.huds[unit]=h
  return h
end
function A:EnsurePlate(plate)
  local h=self.plates[plate]
  if h then return h end
  h=hud(plate,true)
  h:SetPoint("TOP",plate,"BOTTOM",0,-self:Store().offsetY)
  self.plates[plate]=h
  return h
end
function A:Paint(h,unit)
  local dots,total=self:Snapshot(unit)
  local cfg=self:Store()
  if h.spells then h.spells:SetShown(cfg.showLabels) end
  if h.spells then
    h.health:SetHeight(cfg.height)
    h.dot:SetHeight(math.max(5,math.floor(cfg.height*.7)))
  else
    h.health:SetHeight(math.max(4,math.floor(cfg.height*.38)))
    h.dot:SetHeight(math.max(4,math.floor(cfg.height*.35)))
  end
  if #dots>0 and cfg.schoolColors then
    local red,green,blue=self:SchoolColor(dots[1].school)
    h.dot:SetStatusBarColor(red,green,blue,1)
  else h.dot:SetStatusBarColor(.99,.71,.26,1) end
  local ok=safeStatus(h.health,function()
    h.health:SetMinMaxValues(0,UnitHealthMax(unit))
    h.health:SetValue(UnitHealth(unit))
    h.dot:SetMinMaxValues(0,UnitHealthMax(unit))
    h.dot:SetValue(total)
    if h.lethal then h.lethal:SetMinMaxValues(0,UnitHealth(unit));h.lethal:SetValue(total) end
  end)
  if not ok then h:Hide(); return end
  h.count:SetText(tostring(#dots))
  if h.spells then
    local names={}
    for i=1,math.min(3,#dots) do
      local d=dots[i]
      if type(d.name)=="string" then
        local expires=type(d.expiresAt)=="number" and math.max(0,d.expiresAt-GetTime()) or nil
        names[#names+1]=d.name..(expires and string.format(" %.0fs",expires) or "")
      end
    end
    h.spells:SetText(#names>0 and table.concat(names,"  ·  ") or "No active DoTs")
    h.lethalClip:SetShown(cfg.lethal)
  end
  h:Show()
end
function A:RefreshAll()
  local cfg=self:Store()
  local enabled=KoolSupport:IsModuleEnabled("ks_afflictions")
  for _,unit in ipairs(ALL) do
    local h=self:EnsureUnit(unit)
    local shown=enabled and cfg[unit] and type(UnitExists)=="function" and UnitExists(unit)
    if shown then
      h:SetScale(cfg.scale)
      self:Paint(h,unit)
    else h:Hide() end
  end
  local seen={}
  if enabled and cfg.nameplates and C_NamePlate and C_NamePlate.GetNamePlates then
    for _,plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
      local unit=plate.namePlateUnitToken
      if type(unit)=="string" then
        local h=self:EnsurePlate(plate)
        seen[plate]=true
        h:SetScale(cfg.scale)
        h:ClearAllPoints()
        h:SetPoint("TOP",plate,"BOTTOM",0,-cfg.offsetY)
        self:Paint(h,unit)
      end
    end
  end
  for plate,h in pairs(self.plates) do if not seen[plate] then h:Hide() end end
end
function A:HideAll()
  for _,h in pairs(self.huds) do h:Hide() end
  for _,h in pairs(self.plates) do h:Hide() end
end
function A:Enable() self:RefreshAll() end
function A:Disable() self:HideAll() end
local driver=CreateFrame("Frame")
local t=0
driver:SetScript("OnUpdate",function(_,elapsed)
  t=t+elapsed
  if t<.2 then return end
  t=0
  if KoolSupport:IsModuleEnabled("ks_afflictions") and A:TrackerReady() then A:RefreshAll() end
end)
driver:RegisterEvent("PLAYER_TARGET_CHANGED")
driver:RegisterEvent("PLAYER_FOCUS_CHANGED")
driver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
driver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:SetScript("OnEvent",function() if A:TrackerReady() then A:RefreshAll() end end)
