-- KS Stealth: visual-only combo pips for visible nameplate units.
-- Forever combo points can be secret values: never branch, compare, format, log,
-- or calculate with the returned value. Only pass it into supported StatusBars.
KSStealth=KSStealth or {}
local S=KSStealth
S.plates=S.plates or {}
local CAP=5
local TEX="Interface\\TARGETINGFRAME\\UI-StatusBar"

function S:Store()
  local d=KoolSupport:GetDatabase()
  d.modules=d.modules or {}
  d.modules.ks_stealth=d.modules.ks_stealth or {}
  local s=d.modules.ks_stealth
  if s.nameplates==nil then s.nameplates=true end
  if type(s.scale)~="number" then s.scale=1 end
  if type(s.offsetY)~="number" then s.offsetY=12 end
  return s
end
function S:IsSupportedClass()
  if type(UnitClass)~="function" then return false end
  local _,class=UnitClass("player")
  return class=="ROGUE" or class=="DRUID"
end
function S:CanDisplay()
  return self.active and self:IsSupportedClass() and self:Store().nameplates and type(GetComboPoints)=="function"
end
function S:Layout(record)
  local db=self:Store()
  local w,h,g=15*db.scale,10*db.scale,3*db.scale
  local holder=record.holder
  holder:SetSize(CAP*w+(CAP-1)*g,h)
  holder:ClearAllPoints()
  holder:SetPoint("BOTTOM",record.plate,"TOP",0,db.offsetY)
  for i,bar in ipairs(record.bars) do
    bar:ClearAllPoints()
    bar:SetPoint("LEFT",holder,"LEFT",(i-1)*(w+g),0)
    bar:SetSize(w,h)
  end
end
function S:MakePlate(plate,unit)
  local old=self.plates[plate]
  if old then
    old.unit=unit
    self:Layout(old)
    return old
  end
  local holder=CreateFrame("Frame",nil,plate)
  holder:SetFrameLevel((plate.GetFrameLevel and plate:GetFrameLevel() or 1)+5)
  local record={plate=plate,holder=holder,unit=unit,bars={}}
  for i=1,CAP do
    local bar=CreateFrame("StatusBar",nil,holder)
    bar:SetStatusBarTexture(TEX)
    bar:SetStatusBarColor(1,.25,.12,1)
    bar:SetMinMaxValues(i-1,i)
    bar:SetValue(0)
    record.bars[i]=bar
  end
  self.plates[plate]=record
  self:Layout(record)
  return record
end
function S:UpdatePlate(unit)
  if not self:CanDisplay() then return end
  if not C_NamePlate or type(C_NamePlate.GetNamePlateForUnit)~="function" then return end
  local plate=C_NamePlate.GetNamePlateForUnit(unit)
  if not plate then return end
  local record=self:MakePlate(plate,unit)
  record.holder:Show()
  -- A secret numeric value is safe as a StatusBar value, but NOT in a Lua test.
  -- Each bar clamps the same secret value to its own [i-1, i] interval.
  local ok,points=pcall(GetComboPoints,"player",unit)
  if not ok then
    record.holder:Hide()
    return
  end
  for _,bar in ipairs(record.bars) do
    local works=pcall(bar.SetValue,bar,points)
    if not works then record.holder:Hide();return end
  end
end
function S:UpdateAll()
  if not self:CanDisplay() then self:HideAll();return end
  if not C_NamePlate or type(C_NamePlate.GetNamePlates)~="function" then return end
  local list=C_NamePlate.GetNamePlates()
  if type(list)~="table" then return end
  local visible={}
  for _,plate in ipairs(list) do
    local unit=plate.namePlateUnitToken or plate.unitToken
    if not unit and type(plate.GetUnit)=="function" then unit=plate:GetUnit() end
    if type(unit)=="string" then
      visible[plate]=true
      self:UpdatePlate(unit)
    end
  end
  for plate,record in pairs(self.plates) do
    if not visible[plate] then record.holder:Hide() end
  end
end
function S:RemoveUnit(unit)
  for _,record in pairs(self.plates) do
    if record.unit==unit then
      record.holder:Hide()
      record.unit=nil
    end
  end
end
function S:HideAll()
  for _,record in pairs(self.plates) do record.holder:Hide() end
end
function S:Relayout()
  for _,record in pairs(self.plates) do self:Layout(record) end
  self:UpdateAll()
end
function S:SetNameplates(enabled)
  if KoolSupport:IsInCombat() then return false,"Change display settings outside combat" end
  self:Store().nameplates=not not enabled
  self:UpdateAll()
  return true
end
function S:SetScale(value)
  if KoolSupport:IsInCombat() then return false,"Change display settings outside combat" end
  if type(value)~="number" then return false,"Invalid scale" end
  self:Store().scale=math.max(.6,math.min(2,value))
  self:Relayout()
  return true
end
function S:SetOffset(value)
  if KoolSupport:IsInCombat() then return false,"Change display settings outside combat" end
  if type(value)~="number" then return false,"Invalid offset" end
  self:Store().offsetY=math.max(-25,math.min(70,value))
  self:Relayout()
  return true
end
function S:OnModuleEnabled()
  self.active=true
  self:UpdateAll()
end
function S:OnModuleDisabled()
  self.active=false
  self:HideAll()
end

-- Event-driven updates; no secret-value comparisons and no polling for enemies.
function S:OnEvent(event,unit)
  if event=="PLAYER_LOGIN" then
    self.active=KoolSupport:IsModuleEnabled("ks_stealth")
    self:UpdateAll()
  elseif not self.active then return
  elseif event=="NAME_PLATE_UNIT_ADDED" then self:UpdatePlate(unit)
  elseif event=="NAME_PLATE_UNIT_REMOVED" then self:RemoveUnit(unit)
  elseif event=="UNIT_COMBO_POINTS" or event=="UNIT_POWER_UPDATE" or event=="UNIT_POWER_FREQUENT" then self:UpdateAll()
  elseif event=="PLAYER_TARGET_CHANGED" or event=="PLAYER_ENTERING_WORLD" or event=="UPDATE_SHAPESHIFT_FORM" then self:UpdateAll()
  end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","UNIT_COMBO_POINTS","UNIT_POWER_UPDATE","UNIT_POWER_FREQUENT","PLAYER_TARGET_CHANGED","UPDATE_SHAPESHIFT_FORM"}) do
  events:RegisterEvent(event)
end
events:SetScript("OnEvent",function(_,event,unit)S:OnEvent(event,unit)end)
