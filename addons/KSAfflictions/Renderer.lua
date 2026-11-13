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
  -- Every display mode uses the same conservative nonsecret lethal decision.
  -- The old 18,000px clipped StatusBar could leak an off-bar DIES at threshold.
  local word=h:CreateFontString(nil,"OVERLAY","GameFontNormal")
  word:SetText("DIES")
  word:SetTextColor(.83,1,.84,1)
  if type(word.SetFont)=="function" then
    word:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE")
  end
  if type(word.SetShadowColor)=="function" then word:SetShadowColor(0,0,0,1) end
  if type(word.SetShadowOffset)=="function" then word:SetShadowOffset(1,-1) end
  word:Hide()
  local skull=h:CreateTexture(nil,"OVERLAY")
  skull:SetSize(13,13)
  skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
  skull:Hide()
  h.lethalWord=word
  h.lethalIcon=skull
end
local function paintLethal(A,h,unit,db,center)
  local mode=db.lethalMode
  local eligible,reason=A:ApplyLethalTint(unit,h,h.lethalWord,h.lethalIcon)
  A:NoteMinimalReason(unit,reason)
  h.lethalWord:ClearAllPoints()
  h.lethalIcon:ClearAllPoints()
  h.lethalWord:SetPoint("CENTER",center,"CENTER",mode=="both" and -8 or 0,0)
  h.lethalIcon:SetPoint("CENTER",center,"CENTER",mode=="both" and 21 or 0,0)
  h.lethalWord:SetShown(eligible and (mode=="dies" or mode=="both"))
  h.lethalIcon:SetShown(eligible and (mode=="skull" or mode=="both"))
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
  end)
  if not ok then h:Hide();return end
  for i,icon in ipairs(h.icons) do
    local dot=dots[i]
    local texture=dot and db.showIcons and spellTexture(dot)
    if texture then icon:SetTexture(texture);icon:Show() else icon:Hide() end
  end
  paintLethal(self,h,unit,db,h)
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
  paintLethal(self,h,unit,db,h.health)
  h:Show()
end

-- 0.10.9: text ONLY on Blizzard's native health bars. There is no replacement
-- health bar, DoT strip, icon, popup or mouse hitbox in this display mode.
A.minimalUnits=A.minimalUnits or {}
A.minimalPlates=A.minimalPlates or {}

local function publicPlateToken(raw)
  if type(issecretvalue)~="function" then return nil end
  local ok,secret=pcall(issecretvalue,raw)
  if not ok or secret or type(raw)~="string" then return nil end
  if raw:match("^nameplate%d+$") then return raw end
end
function A:PlateUnit(plate)
  if not plate then return nil end
  local token=publicPlateToken(plate.namePlateUnitToken)
    or publicPlateToken(plate.unitToken)
  if token then return token end
  if type(plate.GetUnit)=="function" then
    local ok,result=pcall(plate.GetUnit,plate)
    if ok then return publicPlateToken(result) end
  end
  return nil
end
function A:ResolvePlateHealthBar(plate)
  local root=plate and (plate.UnitFrame or plate.unitFrame)
  if not root then return nil end
  local container=root.HealthBarsContainer
  return statusBar(root.healthBar) or statusBar(root.healthbar)
    or statusBar(root.HealthBar) or statusBar(container and container.HealthBar)
    or statusBar(container and container.healthBar)
    or statusBar(root.healthBars and root.healthBars.healthBar)
end
local function nativeVisible(native)
  if not native then return false end
  if type(native.IsShown)~="function" then return true end
  local ok,shown=pcall(native.IsShown,native)
  return ok and shown==true
end
local function hideMinimal(record)
  if record then
    record.active=false
    record.frame:Hide()
  end
end
function A:EnsureMinimal(cache,key,native)
  if not native then return nil end
  local old=cache[key]
  if old and old.native==native then return old end
  hideMinimal(old)
  local ok,record=pcall(function()
    -- Independent, nonsecure overlay anchored to the ORIGINAL StatusBar;
    -- never resize/reparent/recolor the Blizzard bar or consume mouse input.
    local frame=CreateFrame("Frame",nil,UIParent)
    frame:SetAllPoints(native)
    frame:EnableMouse(false)
    local level=type(native.GetFrameLevel)=="function" and native:GetFrameLevel()
    if type(level)=="number" then frame:SetFrameLevel(level+6) end
    if type(native.GetFrameStrata)=="function" and type(frame.SetFrameStrata)=="function" then
      frame:SetFrameStrata(native:GetFrameStrata())
    end
    local word=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    word:SetPoint("CENTER",frame,"CENTER",0,0)
    word:SetText("DIES")
    word:SetTextColor(.83,1,.84,1)
    if type(word.SetFont)=="function" then
      word:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE")
    end
    if type(word.SetShadowColor)=="function" then word:SetShadowColor(0,0,0,1) end
    if type(word.SetShadowOffset)=="function" then word:SetShadowOffset(1,-1) end
    frame:Hide()
    return {frame=frame,word=word,native=native,active=false}
  end)
  if not ok or not record then return nil end
  cache[key]=record
  return record
end
-- 0.10.10 RC3: NEVER call Curve:Evaluate* on secret UnitHealth from
-- tainted addon code; that API is AllowedWhenUntainted and Forever rejects it.
-- UnitHealthPercent(unit, false, curve), however, is a native unit API that
-- evaluates a scalar Curve itself. Its secret result goes directly to a
-- FontString/Texture:SetAlpha sink (AllowedWhenTainted). The absolute DoT
-- threshold requires an exact max-HP baseline captured while readable.
local function percentCurveSupported()
  return type(C_CurveUtil)=="table"
    and type(C_CurveUtil.CreateCurve)=="function"
    and type(Enum)=="table" and type(Enum.LuaCurveType)=="table"
    and Enum.LuaCurveType.Step~=nil
    and type(UnitHealthPercent)=="function"
end
function A:SecretCurveSupported()
  return percentCurveSupported()
end
A.knownUnitMax=A.knownUnitMax or {}
local function publicKey(unit)
  if not ns.tracking or type(ns.tracking.unitKey)~="function"
    or type(issecretvalue)~="function" then return nil end
  local ok,key=pcall(ns.tracking.unitKey,unit)
  if not ok then return nil end
  local checked,secret=pcall(issecretvalue,key)
  if not checked or secret or type(key)~="string" or key=="" then return nil end
  return key
end
function A:ForgetKnownMax(unit)
  if type(unit)~="string" then return end
  if type(issecretvalue)~="function" then return end
  local ok,secret=pcall(issecretvalue,unit)
  if ok and not secret then self.knownUnitMax[unit]=nil end
end
function A:RememberPublicMax(unit)
  if not unit or type(UnitHealthMax)~="function"
    or type(issecretvalue)~="function" then return false end
  local key=publicKey(unit)
  if not key then self:ForgetKnownMax(unit);return false end
  local old=self.knownUnitMax[unit]
  if old and old.key~=key then self:ForgetKnownMax(unit) end
  local ok,value=pcall(UnitHealthMax,unit)
  if not ok then return false end
  local checked,secret=pcall(issecretvalue,value)
  if not checked or secret then return false end
  if type(value)~="number" or value~=value or value<=0
    or value==math.huge then return false end
  self.knownUnitMax[unit]={key=key,max=value}
  return true
end
function A:KnownMax(unit)
  local saved=self.knownUnitMax[unit]
  if not saved then return nil end
  local key=publicKey(unit)
  if not key or key~=saved.key then
    self:ForgetKnownMax(unit)
    return nil
  end
  return saved.max
end
local function ensurePercentCurve(record,total,maxHP)
  if not percentCurveSupported() or type(total)~="number" then return nil end
  local cutoff=math.floor(total)
  if cutoff<2 or type(maxHP)~="number" or maxHP<=0 then return nil end
  if record.percentCurve and record.percentCutoff==cutoff
    and record.percentMax==maxHP then return record.percentCurve end
  local ok,curve=pcall(function()
    local c=C_CurveUtil.CreateCurve()
    c:SetType(Enum.LuaCurveType.Step)
    -- 0 HP: transparent (corpse); 1+ HP: visible only while remaining
    -- damage strictly exceeds HP. Equal threshold stays hidden.
    c:AddPoint(0,0)
    c:AddPoint(1/maxHP,1)
    c:AddPoint(cutoff/maxHP,0)
    return c
  end)
  if not ok or not curve then return nil end
  record.percentCurve=curve
  record.percentCutoff=cutoff
  record.percentMax=maxHP
  return curve
end
A.minimalReasons=A.minimalReasons or {}
function A:NoteMinimalReason(unit,reason)
  if type(unit)=="string" and (unit=="target" or unit=="focus" or
    unit:match("^nameplate%d+$")) then
    self.minimalReasons[unit]=reason
  end
end
-- Shared native visual primitive for Centered DIES AND optional advanced
-- bars. Returns whether a trusted visual predicate was installed, NOT the
-- actual outcome when health/curve colors are secret. Neither Lua nor chat
-- ever inspect or compare the returned secret RGBA values.
function A:ApplyLethalTint(unit,record,word,skull,knownTotal)
  local total,reason=knownTotal,"ready"
  if not total then total,reason=self:LethalEvidence(unit) end
  if not total then return false,reason or "no_estimate" end
  if type(UnitHealth)~="function" or type(issecretvalue)~="function" then
    return false,"health_api_unavailable"
  end
  local ok,health=pcall(UnitHealth,unit)
  if not ok then return false,"health_unavailable" end
  local checked,secret=pcall(issecretvalue,health)
  if not checked then return false,"health_unavailable" end
  if not secret then
    if type(health)~="number" or health~=health or health<=0 or total<health then
      return false,"not_lethal"
    end
    if type(word.SetAlpha)~="function"
      or not pcall(word.SetAlpha,word,1) then return false,"text_rejected" end
    if skull and (type(skull.SetAlpha)~="function"
      or not pcall(skull.SetAlpha,skull,1)) then return false,"skull_rejected" end
    return true,"readable_lethal"
  end
  local maxHP=self:KnownMax(unit)
  if not maxHP then return false,"max_baseline_unavailable" end
  local curve=ensurePercentCurve(record,total,maxHP)
  if not curve then return false,"percent_curve_unavailable" end
  -- The curve, not Lua, evaluates protected percent inside UnitHealthPercent.
  -- Neither the secret percent nor resulting alpha is read or compared.
  local evaluated,alpha=pcall(UnitHealthPercent,unit,false,curve)
  if not evaluated then return false,"native_percent_rejected" end
  if type(word.SetAlpha)~="function"
    or not pcall(word.SetAlpha,word,alpha) then
    return false,"secret_alpha_rejected"
  end
  if skull then
    if type(skull.SetAlpha)~="function"
      or not pcall(skull.SetAlpha,skull,alpha) then
      return false,"secret_skull_alpha_rejected"
    end
  end
  return true,"native_percent_applied"
end
function A:PaintMinimal(cache,key,native,unit)
  local record=cache[key]
  if not nativeVisible(native) or not unit then
    self:NoteMinimalReason(unit,"native_bar_unavailable")
    hideMinimal(record)
    return
  end
  -- Avoid creating new nameplate frames until public DoT evidence exists.
  local total,reason=self:LethalEvidence(unit)
  if not total then
    self:NoteMinimalReason(unit,reason or "no_estimate")
    hideMinimal(record)
    return
  end
  record=self:EnsureMinimal(cache,key,native)
  if not record then
    self:NoteMinimalReason(unit,"unsupported_frame")
    return
  end
  local eligible,why=self:ApplyLethalTint(unit,record,record.word,nil,total)
  if not eligible then
    self:NoteMinimalReason(unit,why)
    hideMinimal(record)
    return
  end
  record.unit=unit
  record.active=true
  record.mode=why
  self:NoteMinimalReason(unit,why)
  record.frame:Show()
end
function A:AnyMinimalShown()
  for _,record in pairs(self.minimalUnits) do if record.active then return true end end
  for _,record in pairs(self.minimalPlates) do if record.active then return true end end
  return false
end

function A:RefreshAll()
  local db=self:Store()
  local enabled=KoolSupport:IsModuleEnabled("ks_afflictions")
  local centered=db.displayMode=="centered"
  for _,unit in ipairs(UNITS) do
    local visible=enabled and db[unit] and type(UnitExists)=="function"
      and UnitExists(unit)
    -- Learn exact max HP only while readable. Later combat secrecy may reuse
    -- this ephemeral value for the SAME unit identity, until invalidated.
    if enabled and visible then self:RememberPublicMax(unit) end
    local old=self.huds[unit]
    local onframe=self.onFrameHUDs[unit]
    if centered then
      if old then old:Hide() end
      if onframe then onframe:Hide() end
      local native=visible and self:ResolveUnitHealthBar(unit) or nil
      self:PaintMinimal(self.minimalUnits,unit,native,unit)
    else
      hideMinimal(self.minimalUnits[unit])
      local native=visible and db.displayMode=="onframe"
        and self:ResolveUnitHealthBar(unit) or nil
      local overlay=native and self:EnsureOnFrame(unit,native) or nil
      if overlay and nativeVisible(native) then
        if old then old:Hide() end
        self:PaintOnFrame(overlay,unit)
      else
        if onframe then onframe:Hide() end
        -- This fallback is for the explicitly selected legacy HUD modes only.
        local h=self:EnsureUnit(unit)
        if visible then h:SetScale(db.scale);self:Paint(h,unit)
        else h:Hide() end
      end
    end
  end

  local seen={}
  if enabled and db.nameplates and C_NamePlate
    and type(C_NamePlate.GetNamePlates)=="function" then
    local ok,plates=pcall(C_NamePlate.GetNamePlates)
    if ok and type(plates)=="table" then
      for _,plate in ipairs(plates) do
        seen[plate]=true
        local unit=self:PlateUnit(plate)
        if unit then self:RememberPublicMax(unit) end
        local old=self.plates[plate]
        if centered then
          if old then old:Hide() end
          local native=unit and self:ResolvePlateHealthBar(plate) or nil
          self:PaintMinimal(self.minimalPlates,plate,native,unit)
        else
          hideMinimal(self.minimalPlates[plate])
          if unit then
            local h=self:EnsurePlate(plate)
            h:SetScale(db.scale)
            h:ClearAllPoints()
            h:SetPoint("TOP",plate,"BOTTOM",0,-db.offsetY)
            self:Paint(h,unit)
          elseif old then old:Hide() end
        end
      end
    end
  end
  for plate,h in pairs(self.plates) do if not seen[plate] then h:Hide() end end
  for plate,record in pairs(self.minimalPlates) do
    if not seen[plate] then hideMinimal(record) end
  end
end
function A:HideAll()
  for _,h in pairs(self.huds) do h:Hide() end
  for _,h in pairs(self.onFrameHUDs) do h:Hide() end
  for _,h in pairs(self.plates) do h:Hide() end
  for _,record in pairs(self.minimalUnits) do hideMinimal(record) end
  for _,record in pairs(self.minimalPlates) do hideMinimal(record) end
end
function A:Enable() self:RefreshAll() end
function A:Disable() self:HideAll() end

-- The vendored tracker already maintains its DoT housekeeping clock. The
-- minimal renderer has no independent OnUpdate; only active DIES labels need
-- a bounded (0.5s) expiry recheck while quiet.
function A:OnTrackerRefresh()
  if not KoolSupport:IsModuleEnabled("ks_afflictions") then return end
  if self:Store().displayMode=="centered" and not self:AnyMinimalShown() then return end
  local now=type(GetTime)=="function" and GetTime() or 0
  if now-(self.lastTrackerPaint or -10)<.5 then return end
  self.lastTrackerPaint=now
  self:RefreshAll()
end

local driver=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED",
  "NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_ENTERING_WORLD",
  "PLAYER_REGEN_ENABLED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_AURA",
  "UNIT_COMBAT","UNIT_SPELLCAST_SUCCEEDED","UNIT_SPELLCAST_FAILED",
  "UNIT_SPELLCAST_INTERRUPTED"}) do
  driver:RegisterEvent(event)
end
local queued=false
local function repaint()
  queued=false
  if KoolSupport:IsModuleEnabled("ks_afflictions") and A:TrackerReady() then
    A:RefreshAll()
  end
end
driver:SetScript("OnEvent",function(_,event,unit)
  -- A reused plate or changed target cannot inherit a previous enemy's word,
  -- even for the one event turn before the deferred tracker repaint.
  if event=="PLAYER_ENTERING_WORLD" then A.knownUnitMax={} end
  if event=="PLAYER_TARGET_CHANGED" then
    A:ForgetKnownMax("target")
    hideMinimal(A.minimalUnits.target)
  end
  if event=="PLAYER_FOCUS_CHANGED" then
    A:ForgetKnownMax("focus")
    hideMinimal(A.minimalUnits.focus)
  end
  if event=="UNIT_MAXHEALTH" or event=="NAME_PLATE_UNIT_ADDED"
    or event=="NAME_PLATE_UNIT_REMOVED" then
    A:ForgetKnownMax(unit)
  end
  if event=="NAME_PLATE_UNIT_REMOVED" then
    for _,record in pairs(A.minimalPlates) do
      if record.unit==unit then hideMinimal(record) end
    end
  end
  if queued then return end
  queued=true
  if C_Timer and type(C_Timer.After)=="function" then
    C_Timer.After(0,repaint) -- after the vendor's handlers have processed this event
  else
    repaint()
  end
end)
