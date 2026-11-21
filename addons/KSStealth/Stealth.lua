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
  if s.hudEnabled==nil then s.hudEnabled=true end
  if s.hudPlacement~="above" then s.hudPlacement="below" end
  if s.talentImpactOverlay==nil then s.talentImpactOverlay=false end
  if s.talentAnnotate==nil then s.talentAnnotate=false end
  if s.talentCritEstimate==nil then s.talentCritEstimate=false end
  if type(s.scale)~="number" then s.scale=1 end
  if type(s.offsetY)~="number" then s.offsetY=12 end
  return s
end
function S:IsSupportedClass()
  if type(UnitClass)~="function" then return false end
  local _,class=UnitClass("player")
  return class=="ROGUE" or class=="DRUID"
end
-- Forever combo points are target-bound. We only display the selected
-- target on its actual overhead nameplate health bar, never on a floating HUD.
function S:CanDisplay()
  return KoolSupport:IsModuleEnabled("ks_stealth") and self:IsSupportedClass()
   and self:Store().hudEnabled~=false
end

local function readable(value)
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,value)
  if not ok or secret then return false end
 end
 return true
end
local function targetPlate()
 if not C_NamePlate then return nil,"Nameplate API unavailable" end
 local plate
 if type(C_NamePlate.GetNamePlateForUnit)=="function" then
  local ok,result=pcall(C_NamePlate.GetNamePlateForUnit,"target")
  if ok and readable(result) then plate=result end
 end
 if plate then return plate,"target lookup" end
 -- Some Forever layouts only expose a nameplate1..N unit token.
 if type(C_NamePlate.GetNamePlates)~="function" or type(UnitIsUnit)~="function" then
  return nil,"Target lookup returned nil; fallback unavailable"
 end
 local ok,plates=pcall(C_NamePlate.GetNamePlates)
 if not ok or type(plates)~="table" then return nil,"Cannot enumerate visible nameplates" end
 for _,candidate in ipairs(plates) do
  local unit=candidate.namePlateUnitToken or candidate.unitToken
  if type(unit)=="string" then
   local works,same=pcall(UnitIsUnit,unit,"target")
   if works and readable(same) and same==true then return candidate,"nameplate unit match" end
  end
 end
 return nil,"No visible nameplate matched target"
end
local function healthBar(plate)
 local unit=plate and (plate.UnitFrame or plate.unitFrame)
 if not unit then return plate end
 local bars=unit.healthBar or unit.HealthBar or
  (unit.HealthBarsContainer and (unit.HealthBarsContainer.healthBar or unit.HealthBarsContainer.HealthBar))
 return bars or plate
end

function S:Layout(record)
 local db=self:Store()
 local size=type(db.hudScale)=="number" and db.hudScale or 1
 size=math.max(.7,math.min(1.8,size))
 local w,h,g=19*size,12*size,4*size
 local holder=record.holder
 holder:SetSize(CAP*w+(CAP-1)*g,h)
 holder:ClearAllPoints()
 local anchor=healthBar(record.plate)
 if db.hudPlacement=="above" then
  holder:SetPoint("BOTTOM",anchor,"TOP",0,4)
 else
  holder:SetPoint("TOP",anchor,"BOTTOM",0,-5)
 end
 for i,bar in ipairs(record.bars) do
  bar:ClearAllPoints()
  bar:SetPoint("LEFT",holder,"LEFT",(i-1)*(w+g),0)
  bar:SetSize(w,h)
 end
end

function S:MakePlate(plate,unit)
 local old=self.plates[plate]
 if old then old.unit=unit; self:Layout(old);return old end
 local holder=CreateFrame("Frame",nil,plate)
 holder:SetFrameLevel((plate.GetFrameLevel and plate:GetFrameLevel() or 1)+20)
 local record={plate=plate,holder=holder,unit=unit,bars={}}
 for i=1,CAP do
  local bar=CreateFrame("StatusBar",nil,holder)
  bar:SetStatusBarTexture(TEX)
  bar:SetStatusBarColor(1,.72,.20,1)
  bar:SetMinMaxValues(i-1,i)
  bar:SetValue(0)
  if type(bar.CreateTexture)=="function" then
   local backing=bar:CreateTexture(nil,"BACKGROUND")
   backing:SetAllPoints(bar)
   if backing.SetColorTexture then backing:SetColorTexture(.10,.11,.13,.88)
   elseif backing.SetTexture and backing.SetVertexColor then
    backing:SetTexture("Interface\\Buttons\\WHITE8X8")
    backing:SetVertexColor(.10,.11,.13,.88)
   end
  end
  record.bars[i]=bar
 end
 self.plates[plate]=record
 self:Layout(record)
 return record
end

function S:HideAll()
 for _,record in pairs(self.plates) do record.holder:Hide() end
end

function S:ComboDiagnosticText()
 local info=self.comboDiagnostic or {}
 return "Combo diagnostics: "..tostring(info.phase or "not initialized")..
  " | Source: "..tostring(info.source or "not read")
end
function S:UpdateTargetNameplate()
 self:HideAll()
 if not self:CanDisplay() then
  self.comboDiagnostic={phase="Display disabled or unsupported class"}
  return
 end
 local plate,method=targetPlate()
 if not plate then
  self.comboDiagnostic={phase=method or "Target nameplate not found"}
  return
 end
 local record=self:MakePlate(plate,"target")
 self.comboDiagnostic={phase="Nameplate found ("..method..")"}
 -- No branching on or formatting of the secret combo count.
 local ok,points=false,nil
 if type(GetComboPoints)=="function" then
  ok,points=pcall(GetComboPoints,"player","target")
 end
 -- The alternative resource API is useful only when the native target-bound
 -- getter is not available. Never inspect its value to decide a fallback.
 if not ok and type(UnitPower)=="function" then
  ok,points=pcall(UnitPower,"player",4)
  if ok then self.comboDiagnostic.source="UnitPower fallback" end
 elseif ok then self.comboDiagnostic.source="GetComboPoints" end
 if not ok then
  self.comboDiagnostic.phase="Nameplate found; combo API calls failed"
  return
 end
 for _,bar in ipairs(record.bars) do
  if not pcall(bar.SetValue,bar,points) then
   self.comboDiagnostic.phase="Nameplate found; StatusBar:SetValue rejected"
   return
  end
 end
 self.comboDiagnostic.phase="Five StatusBars updated"
 record.holder:Show()
end

function S:UpdateAll()
 self:UpdateTargetNameplate()
end
function S:UpdatePlate(unit)
 -- Nameplate events can occur when the target walks into nameplate range.
 -- Always resolve the currently selected target, not arbitrary units.
 self:UpdateTargetNameplate()
end
function S:RemoveUnit(unit)
 self:UpdateTargetNameplate()
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
function S:SetTalentImpactOverlay(enabled)
  if KoolSupport:IsInCombat() then return false,"Change talent preview settings outside combat" end
  self:Store().talentImpactOverlay=not not enabled
  return true
end
function S:SetTalentImpactSetting(key,enabled)
  if KoolSupport:IsInCombat() then return false,"Change talent settings outside combat" end
  if key~="talentAnnotate" and key~="talentCritEstimate" then
    return false,"Unknown talent setting"
  end
  if type(enabled)~="boolean" then return false,"Expected toggle" end
  self:Store()[key]=enabled
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
  if self:Store().talentImpactOverlay and self.RefreshTalentInsights and not KoolSupport:IsInCombat() then
    self:RefreshTalentInsights()
  end
  if self:Store().talentAnnotate and self.InstallTalentTooltipHook then
    self:InstallTalentTooltipHook()
  end
  self:UpdateAll()
end
function S:OnModuleDisabled()
  self.active=false
  self:HideAll()
  if type(self.HideHUD)=="function" then self:HideHUD() end
end

-- Event-driven updates; no secret-value comparisons and no polling for enemies.
function S:OnEvent(event,unit)
  if event=="PLAYER_LOGIN" then
    self.active=KoolSupport:IsModuleEnabled("ks_stealth")
    if self.active and self:Store().talentImpactOverlay and self.RefreshTalentInsights and not KoolSupport:IsInCombat() then
      self:RefreshTalentInsights()
    end
    if self.active and self:Store().talentAnnotate and self.InstallTalentTooltipHook then
      self:InstallTalentTooltipHook()
    end
    self:UpdateAll()
  elseif not KoolSupport:IsModuleEnabled("ks_stealth") then self:HideAll();return
  elseif event=="NAME_PLATE_UNIT_ADDED" then self:UpdatePlate(unit)
  elseif event=="NAME_PLATE_UNIT_REMOVED" then self:RemoveUnit(unit)
  elseif event=="UNIT_COMBO_POINTS" or event=="UNIT_POWER_UPDATE" or event=="UNIT_POWER_FREQUENT" then self:UpdateAll()
  elseif event=="PLAYER_TARGET_CHANGED" or event=="PLAYER_ENTERING_WORLD" or event=="UPDATE_SHAPESHIFT_FORM" or event=="PLAYER_REGEN_ENABLED" then self:UpdateAll()
  end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","UNIT_COMBO_POINTS","UNIT_POWER_UPDATE","UNIT_POWER_FREQUENT","PLAYER_TARGET_CHANGED","UPDATE_SHAPESHIFT_FORM","PLAYER_REGEN_ENABLED"}) do
  events:RegisterEvent(event)
end
events:SetScript("OnEvent",function(_,event,unit)S:OnEvent(event,unit)end)
