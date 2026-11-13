-- KS Threat: small, event-driven, per-character tank threat overlay.
-- Never compare or format secret combat values. Unknown => Blizzard display.
KSThreat=KSThreat or {}
local A=KSThreat
local WHITE="Interface\\Buttons\\WHITE8X8"

A.COLORS={
 [0]={.443,.227,.831}, -- purple: low/no threat
 [1]={.639,.416,.878}, -- violet: some threat, not the target
 [2]={.875,.341,.580}, -- pink: tanking but contested
 [3]={.937,.204,.290}, -- red: securely tanking
}
A.DEFAULTS={onlyCombat=true,purpleNoThreat=true}
A.plates=A.plates or {}
A.lastCounts=A.lastCounts or {}

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

-- Every unit token and condition is checked before Lua branches on it.
-- If the client has no secret checker, decline combat classification.
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

-- Blizzard's actual C_NamePlate entries use unitToken (or GetUnit());
-- namePlateUnitToken is a field used by some third-party nameplate APIs.
-- 0.10.6 wrongly read ONLY namePlateUnitToken and silently skipped plates.
function A:PlateUnit(plate)
 if not plate then return nil end
 local function recognized(raw)
  local token,known=safeValue(raw)
  if known and type(token)=="string" and token:match("^nameplate%d+$") then
   return token
  end
 end
 local token=recognized(plate.namePlateUnitToken)
 if token then return token end
 token=recognized(plate.unitToken)
 if token then return token end
 if type(plate.GetUnit)=="function" then
  local ok,result=pcall(plate.GetUnit,plate)
  if ok then return recognized(result) end
 end
 return nil
end

function A:ThreatState(unit)
 if type(unit)~="string" or not unit:match("^nameplate%d+$") then
  return nil,"no token"
 end
 local hostile,known=safeCall(UnitCanAttack,"player",unit)
 if not known then return nil,"hostility unavailable" end
 if hostile~=true then return nil,"not hostile" end
 if self:Store().onlyCombat then
  local fighting,readable=safeCall(UnitAffectingCombat,unit)
  if not readable then return nil,"combat unavailable" end
  if fighting~=true then return nil,"not in combat" end
 end
 local status,readable=safeCall(UnitThreatSituation,"player",unit)
 if not readable then return nil,"threat unavailable" end
 if status==nil then
  if self:Store().purpleNoThreat then return 0 end
  return nil,"no threat"
 end
 if type(status)~="number" or status%1~=0 or status<0 or status>3 then
  return nil,"threat unavailable"
 end
 if status==0 and not self:Store().purpleNoThreat then
  return nil,"no threat"
 end
 return status
end

local function isStatusBar(candidate)
 if not candidate or type(candidate.GetObjectType)~="function" then return false end
 local ok,kind=pcall(candidate.GetObjectType,candidate)
 return ok and kind=="StatusBar"
end
function A:HealthBar(plate)
 if not plate then return nil end
 local unitFrame=plate.UnitFrame or plate.unitFrame
 if not unitFrame then return nil end
 local container=unitFrame.HealthBarsContainer
 local candidates={
  unitFrame.healthBar,unitFrame.healthbar,unitFrame.HealthBar,
  container and container.HealthBar,container and container.healthBar,
  unitFrame.healthBars and unitFrame.healthBars.healthBar,
 }
 -- Explicit count: table holes must not stop discovery early with ipairs().
 for i=1,6 do
  if isStatusBar(candidates[i]) then return candidates[i] end
 end
 return nil
end

function A:HidePlate(plate)
 local entry=self.plates[plate]
 if entry and entry.overlay then entry.overlay:Hide() end
end

function A:EnsureOverlay(plate,native)
 local entry=self.plates[plate]
 if entry and entry.native==native then return entry.overlay end
 if entry then self:HidePlate(plate) end
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
 if not KoolSupport:IsModuleEnabled("ks_threat") then
  self:HidePlate(plate);return false,"disabled"
 end
 local unit=self:PlateUnit(plate)
 if not unit then self:HidePlate(plate);return false,"no token" end
 local state,reason=self:ThreatState(unit)
 if state==nil then self:HidePlate(plate);return false,reason end
 local native=self:HealthBar(plate)
 if not native then self:HidePlate(plate);return false,"no health bar" end
 local overlay=self:EnsureOverlay(plate,native)
 if not overlay then return false,"overlay unavailable" end
 local color=self.COLORS[state]
 local ok=pcall(function()
  overlay:SetStatusBarColor(color[1],color[2],color[3],.93)
  -- Opaque health is passed only into WoW's StatusBar widget API.
  overlay:SetMinMaxValues(0,UnitHealthMax(unit))
  overlay:SetValue(UnitHealth(unit))
  overlay:Show()
 end)
 if not ok then overlay:Hide();return false,"paint unavailable" end
 return true,"colored"
end

function A:RefreshAll()
 local enabled=KoolSupport:IsModuleEnabled("ks_threat")
 local seen={}
 local counts={visible=0,colored=0}
 if enabled and C_NamePlate and type(C_NamePlate.GetNamePlates)=="function" then
  local ok,plates=pcall(C_NamePlate.GetNamePlates)
  if ok and type(plates)=="table" then
   for _,plate in ipairs(plates) do
    counts.visible=counts.visible+1
    seen[plate]=true
    local painted,reason=self:PaintPlate(plate)
    if painted then counts.colored=counts.colored+1
    else
     -- Only fixed diagnostic labels are stored, never unit names or values.
     counts[reason or "unknown"]= (counts[reason or "unknown"] or 0)+1
    end
   end
  else counts["nameplate API unavailable"]=1 end
 else
  counts[enabled and "nameplate API unavailable" or "disabled"]=1
 end
 for plate in pairs(self.plates) do
  if not seen[plate] then self:HidePlate(plate) end
 end
 self.lastCounts=counts
 return counts
end

function A:DiagnosticText()
 local counts=self:RefreshAll()
 local reasons={
  "no token","hostility unavailable","not hostile","combat unavailable",
  "not in combat","threat unavailable","no threat","no health bar",
  "overlay unavailable","paint unavailable","nameplate API unavailable","disabled",
 }
 local reasonText={}
 for _,reason in ipairs(reasons) do
  if counts[reason] and counts[reason]>0 then
   reasonText[#reasonText+1]=reason..": "..counts[reason]
  end
 end
 return "Visible plates: "..counts.visible.." | KS Threat colored: "..counts.colored,
    #reasonText>0 and table.concat(reasonText,"  |  ") or
    "No skipped plates. Check an enemy pull if no bars are visible."
end
function A:HideAll()
 for plate in pairs(self.plates) do self:HidePlate(plate) end
end
function A:Enable() self:RefreshAll() end
function A:Disable() self:HideAll() end

local driver=CreateFrame("Frame")
for _,event in ipairs({
 "PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
 "UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE",
 "UNIT_HEALTH","UNIT_MAXHEALTH",
 "NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED",
}) do driver:RegisterEvent(event) end
driver:SetScript("OnEvent",function()
 -- Refresh only currently visible plates, including events reported as target.
 A:RefreshAll()
end)
