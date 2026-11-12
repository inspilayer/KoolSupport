-- KS Threat: visual-only, event-driven enemy nameplate coloring.
-- Do NOT read, compare, format, or infer hidden/secret threat/health values.
-- An independent StatusBar overlays the existing nameplate health bar; we never
-- write native bar colors, values, layout, nameplate text, or combat state.
KSThreat=KSThreat or {}
local A=KSThreat
local WHITE="Interface\\Buttons\\WHITE8X8"

A.COLORS={
 [0]={.443,.227,.831}, -- purple: no/low threat
 [1]={.639,.416,.878}, -- violet: some threat, not tanking
 [2]={.875,.341,.580}, -- pink: threat rising, not securely tanking
 [3]={.937,.204,.290}, -- red: holding aggro
}
A.DEFAULTS={onlyCombat=true,purpleNoThreat=true}
A.plates=A.plates or {}

function A:Store()
 local db=KoolSupport:GetDatabase()
 db.modules=db.modules or {}
 db.modules.ks_threat=db.modules.ks_threat or {}
 local mine=db.modules.ks_threat
 for k,v in pairs(self.DEFAULTS) do
  if mine[k]==nil then mine[k]=v end
 end
 return mine
end

function A:ChangeSetting(key,value)
 if KoolSupport:IsInCombat() then return false,"Change KS Threat settings outside combat." end
 if self.DEFAULTS[key]==nil or type(value)~="boolean" then
  return false,"Invalid KS Threat setting."
 end
 self:Store()[key]=value
 self:RefreshAll()
 return true
end

-- Even booleans and four-state threat statuses can be secret in Forever.
-- Missing secret-detection support fails closed instead of comparing secrets.
local function safeValue(value)
 if type(issecretvalue)~="function" then return nil,false end
 local ok,secret=pcall(issecretvalue,value)
 if not ok or secret then return nil,false end
 return value,true
end
local function safeCall(fn,...)
 if type(fn)~="function" then return nil,false end
 local ok,result=pcall(fn,...)
 if not ok then return nil,false end
 return safeValue(result)
end
local function validUnit(unit)
 if type(unit)~="string" or not unit:match("^nameplate%d+$") then return false end
 local hostile,readable=safeCall(UnitCanAttack,"player",unit)
 return readable and hostile==true
end

function A:ThreatState(unit)
 if not validUnit(unit) then return nil end
 if self:Store().onlyCombat then
  local fighting,known=safeCall(UnitAffectingCombat,unit)
  if not known or fighting~=true then return nil end
 end
 local status,known=safeCall(UnitThreatSituation,"player",unit)
 if not known then return nil end
 if status==nil then
  return self:Store().purpleNoThreat and 0 or nil
 end
 if type(status)~="number" or status%1~=0 or status<0 or status>3 then
  return nil
 end
 if status==0 and not self:Store().purpleNoThreat then return nil end
 return status
end

local function isStatusBar(bar)
 if not bar or type(bar.GetObjectType)~="function" then return false end
 local ok,kind=pcall(bar.GetObjectType,bar)
 return ok and kind=="StatusBar"
end
function A:HealthBar(plate)
 if not plate then return nil end
 local unitFrame=plate.UnitFrame or plate.unitFrame
 if not unitFrame then return nil end
 local container=unitFrame.HealthBarsContainer
 local bar=unitFrame.healthBar or unitFrame.healthbar or unitFrame.HealthBar or
   (container and container.HealthBar) or (unitFrame.healthBars and unitFrame.healthBars.healthBar)
 return isStatusBar(bar) and bar or nil
end

function A:HidePlate(plate)
 local entry=self.plates[plate]
 if entry and entry.overlay then entry.overlay:Hide() end
end

function A:EnsureOverlay(plate,native)
 local entry=self.plates[plate]
 if entry and entry.native==native then return entry.overlay end
 if entry then self:HidePlate(plate) end
 -- Noninteractive frame with no protected attributes. All operations are
 -- guarded because some client/UI skins refuse changes to their child tree.
 local ok,overlay=pcall(function()
  local frame=CreateFrame("StatusBar",nil,native)
  frame:SetAllPoints(native)
  frame:SetStatusBarTexture(WHITE)
  frame:SetStatusBarColor(1,1,1,.93)
  frame:EnableMouse(false)
  return frame
 end)
 if not ok or not overlay then return nil end
 self.plates[plate]={native=native,overlay=overlay}
 return overlay
end

function A:PaintPlate(plate)
 if not KoolSupport:IsModuleEnabled("ks_threat") then self:HidePlate(plate);return end
 local unit=plate and plate.namePlateUnitToken
 local safeUnit,known=safeValue(unit)
 if not known then self:HidePlate(plate);return end
 local state=self:ThreatState(safeUnit)
 if state==nil then self:HidePlate(plate);return end
 local native=self:HealthBar(plate)
 if not native then self:HidePlate(plate);return end
 local overlay=self:EnsureOverlay(plate,native)
 if not overlay then return end
 local c=self.COLORS[state]
 local ok=pcall(function()
  overlay:SetStatusBarColor(c[1],c[2],c[3],.93)
  -- Preserve secret health entirely inside WoW StatusBar setters.
  overlay:SetMinMaxValues(0,UnitHealthMax(unit))
  overlay:SetValue(UnitHealth(unit))
  overlay:Show()
 end)
 if not ok then overlay:Hide() end
end

function A:RefreshAll()
 local enabled=KoolSupport:IsModuleEnabled("ks_threat")
 local seen={}
 if enabled and C_NamePlate and type(C_NamePlate.GetNamePlates)=="function" then
  local ok,plates=pcall(C_NamePlate.GetNamePlates)
  if ok and type(plates)=="table" then
   for _,plate in ipairs(plates) do
    seen[plate]=true
    self:PaintPlate(plate)
   end
  end
 end
 for plate,_ in pairs(self.plates) do
  if not seen[plate] then self:HidePlate(plate) end
 end
end
function A:HideAll()
 for plate,_ in pairs(self.plates) do self:HidePlate(plate) end
end
function A:Enable()self:RefreshAll()end
function A:Disable()self:HideAll()end

local driver=CreateFrame("Frame")
for _,event in ipairs({
 "PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
 "UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE",
 "NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED",
}) do driver:RegisterEvent(event) end
driver:SetScript("OnEvent",function()
 -- Some clients emit threat updates for "target" rather than nameplateN.
 -- Refresh only currently visible plates; never poll on every rendered frame.
 A:RefreshAll()
end)
