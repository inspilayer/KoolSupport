-- KS Stealth: target nameplate display settings (legacy HUD API compatibility).
-- No detached draggable HUD: all combo segments are owned by target nameplate.
local S=KSStealth
function S:HUDSettings()
 local db=self:Store()
 if db.hudEnabled==nil then db.hudEnabled=true end
 if db.hudPlacement~="above" then db.hudPlacement="below" end
 if type(db.hudScale)~="number" or db.hudScale~=db.hudScale then db.hudScale=1 end
 db.hudScale=math.max(.7,math.min(1.8,db.hudScale))
 return db
end
function S:HUDModuleReady()
 return KoolSupport:IsModuleEnabled("ks_stealth") and self:IsSupportedClass()
end
function S:HideHUD()
 self:HideAll()
end
function S:UpdateHUD()
 self:UpdateTargetNameplate()
end
function S:SetHUDEnabled(value)
 if KoolSupport:IsInCombat() then return false,"Change combo display settings outside combat" end
 self:HUDSettings().hudEnabled=not not value
 self:UpdateAll()
 return true
end
function S:SetHUDPlacement(value)
 if KoolSupport:IsInCombat() then return false,"Move combo points outside combat" end
 if value~="above" and value~="below" then return false,"Use above or below" end
 self:HUDSettings().hudPlacement=value
 self:Relayout()
 return true
end
function S:SetHUDScale(value)
 if KoolSupport:IsInCombat() then return false,"Resize combo points outside combat" end
 if type(value)~="number" or value~=value then return false,"Invalid scale" end
 self:HUDSettings().hudScale=math.max(.7,math.min(1.8,value))
 self:Relayout()
 return true
end
function S:ResetHUDPosition()
 if KoolSupport:IsInCombat() then return false,"Reset combo points outside combat" end
 local db=self:HUDSettings()
 db.hudPlacement="below"
 db.hudScale=1
 -- Obsolete free-floating offsets are deliberately not used or deleted.
 self:Relayout()
 return true
end
-- Older UI calls remain safe but never open a free-floating frame.
function S:ShowHUDForPositioning()
 if not self:HUDModuleReady() then return false,"Enable KS Stealth on a Druid or Rogue." end
 if KoolSupport:IsInCombat() then return false,"Change settings outside combat" end
 self:UpdateAll()
 return true
end
function S:FinishHUDPositioning()
 return true
end
function S:SetHUDLocked(_)
 return false,"Combo points are attached to your target nameplate; no drag lock needed."
end


-- Optional player energy display; rendering reads resources only in Stealth.lua.
function S:SetEnergyEnabled(enabled)
 if KoolSupport:IsInCombat() then return false,"Change energy display outside combat" end
 if type(enabled)~="boolean" then return false,"Expected energy toggle" end
 self:HUDSettings().energyEnabled=enabled
 self:UpdateAll()
 return true
end
function S:SetEnergyHeight(value)
 if KoolSupport:IsInCombat() then return false,"Resize energy display outside combat" end
 if type(value)~="number" or value~=value or value==math.huge or value==-math.huge then
  return false,"Invalid height"
 end
 self:HUDSettings().energyHeight=math.max(4,math.min(20,math.floor(value+.5)))
 self:Relayout()
 return true
end
function S:SetEnergyColor(color)
 if KoolSupport:IsInCombat() then return false,"Change energy color outside combat" end
 if color~="gold" and color~="lime" and color~="amber" and color~="cyan" then
  return false,"Unknown energy color"
 end
 self:HUDSettings().energyColor=color
 self:Relayout()
 return true
end

function S:StyleEnergyBar(bar)
 local db=self:HUDSettings()
 local palette={
  gold={1,.79,.16},lime={.54,.94,.19},
  amber={1,.46,.12},cyan={.24,.81,.96},
 }
 local rgb=palette[db.energyColor] or palette.gold
 if type(bar.SetStatusBarTexture)=="function" then
  bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
 end
 if type(bar.SetStatusBarColor)=="function" then
  bar:SetStatusBarColor(rgb[1],rgb[2],rgb[3],.98)
 end
end

-- Energy segmented pills are purely presentational. Each segment has a fixed,
-- player-configured range and receives the SAME opaque UnitPower result through
-- its native StatusBar:SetValue; never compare or calculate on combat Energy.
local MAX_ENERGY_BREAKS=10
local function breakpointsFrom(raw,ceiling)
 if type(raw)~="string" or #raw>120 then return nil,"Enter at most ten numbers" end
 local parsed,seen={},{}
 if raw:match("^%s*$") then return parsed end
 if raw:find("[^%d,%s]") then return nil,"Use whole numbers separated by commas" end
 if raw:match("^%s*,") or raw:match(",%s*,") or raw:match(",%s*$") then
  return nil,"Remove empty breakpoint entries"
 end
 for number in raw:gmatch("%d+") do
  local value=tonumber(number)
  if not value or value<1 or value>=ceiling or seen[value] then
   return nil,"Breakpoints must be unique and strictly between 0 and "..ceiling
  end
  parsed[#parsed+1]=value
  if #parsed>MAX_ENERGY_BREAKS then return nil,"Maximum ten breakpoints" end
  seen[value]=true
 end
 if #parsed==0 then return nil,"Enter at least one energy value" end
 table.sort(parsed)
 return parsed
end
function S:EnergySettings()
 local db=self:HUDSettings()
 if type(db.energyCeiling)~="number" or db.energyCeiling~=db.energyCeiling
    or db.energyCeiling<50 or db.energyCeiling>250 then db.energyCeiling=100 end
 if type(db.energySegmentGap)~="number" or db.energySegmentGap~=db.energySegmentGap then
  db.energySegmentGap=1
 end
 db.energySegmentGap=math.max(0,math.min(4,db.energySegmentGap))
 if type(db.energyBreakpoints)~="string" then db.energyBreakpoints="" end
 local parsed=breakpointsFrom(db.energyBreakpoints,db.energyCeiling)
 if not parsed then db.energyBreakpoints="" end
 return db
end
function S:EnergyBreakpoints()
 local db=self:EnergySettings()
 return breakpointsFrom(db.energyBreakpoints,db.energyCeiling) or {}
end
function S:SetEnergyBreakpoints(raw)
 if KoolSupport:IsInCombat() then return false,"Edit Energy breakpoints outside combat" end
 local ceiling=self:EnergySettings().energyCeiling
 local parsed,err=breakpointsFrom(raw,ceiling)
 if not parsed then return false,err end
 self:EnergySettings().energyBreakpoints=table.concat(parsed,", ")
 self:Relayout()
 return true
end
function S:SetEnergyCeiling(value)
 if KoolSupport:IsInCombat() then return false,"Set Energy maximum outside combat" end
 if type(value)~="number" or value~=value or value==math.huge or
   value~=math.floor(value) or value<50 or value>250 then
  return false,"Maximum Energy must be a whole number from 50 to 250"
 end
 local db=self:EnergySettings()
 local marks,err=breakpointsFrom(db.energyBreakpoints,value)
 if not marks then return false,err end
 db.energyCeiling=value
 self:Relayout()
 return true
end
function S:SetEnergySegmentGap(value)
 if KoolSupport:IsInCombat() then return false,"Change Energy spacing outside combat" end
 if type(value)~="number" or value~=math.floor(value) or value<0 or value>4 then
  return false,"Gap must be 0, 1, 2, 3 or 4 pixels"
 end
 self:EnergySettings().energySegmentGap=value
 self:Relayout()
 return true
end
-- Configure fixed, numeric segment boundaries; never inspect resource data.
function S:LayoutEnergySegments(bars,width,height)
 local db=self:EnergySettings()
 local marks=self:EnergyBreakpoints()
 local count=#marks+1
 local gap=db.energySegmentGap*db.hudScale
 local remaining=math.max(1,width-gap*(count-1))
 local previous=0
 local at=0
 for i,bar in ipairs(bars) do
  if i<=count and #marks>0 then
   local upper=marks[i] or db.energyCeiling
   local size=remaining*(upper-previous)/db.energyCeiling
   bar:ClearAllPoints()
   bar:SetPoint("LEFT",bar:GetParent(),"LEFT",at,0)
   bar:SetSize(size,height)
   bar:SetMinMaxValues(previous,upper)
   self:StyleEnergyBar(bar)
   bar:Show()
   at=at+size+gap
   previous=upper
  else
   bar:Hide()
  end
 end
 return #marks>0
end
function S:CreateEnergySegments(parent)
 local group=CreateFrame("Frame",nil,parent)
 local bars={}
 for i=1,MAX_ENERGY_BREAKS+1 do
  local bar=CreateFrame("StatusBar",nil,group)
  bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  bar:SetMinMaxValues(0,100)
  bar:SetValue(0)
  if type(bar.CreateTexture)=="function" then
   local backing=bar:CreateTexture(nil,"BACKGROUND")
   backing:SetAllPoints(bar)
   if backing.SetColorTexture then backing:SetColorTexture(.08,.09,.12,.88) end
   bar.backing=backing
  end
  -- Modern client optional rounded mask. Fail open to plain, tightly-spaced
  -- native rectangles on Forever clients lacking MaskTexture support.
  if type(bar.CreateMaskTexture)=="function" and
     type(bar.GetStatusBarTexture)=="function" then
   local ok,mask=pcall(bar.CreateMaskTexture,bar,nil,"ARTWORK")
   if ok and mask then
    local ready=pcall(function()
     mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
     mask:SetAllPoints(bar)
     local fill=bar:GetStatusBarTexture()
     if fill and fill.AddMaskTexture then fill:AddMaskTexture(mask) end
     if bar.backing and bar.backing.AddMaskTexture then
      bar.backing:AddMaskTexture(mask)
     end
    end)
    if ready then bar.pillMask=mask end
   end
  end
  bars[i]=bar
 end
 group:Hide()
 return group,bars
end

-- Pip Designer: all settings are presentation-only and saved per character.
-- This code never reads, inspects or branches on the possibly secret combo value.
local PRESETS={
 classic={shape="bars",palette="gold",texture="smooth",width=19,height=12,gap=4,opacity=1,emptyAlpha=.88},
 assassin={shape="slim",palette="crimson",texture="flat",width=24,height=7,gap=3,opacity=1,emptyAlpha=.65},
 jewels={shape="square",palette="violet",texture="smooth",width=15,height=15,gap=6,opacity=1,emptyAlpha=.78},
 nature={shape="chunky",palette="emerald",texture="smooth",width=22,height=16,gap=3,opacity=.95,emptyAlpha=.72},
 frost={shape="slim",palette="frost",texture="flat",width=27,height=7,gap=5,opacity=.95,emptyAlpha=.56},
 minimal={shape="square",palette="silver",texture="flat",width=10,height=10,gap=3,opacity=.85,emptyAlpha=.35},
}
local PALETTES={
 custom={1,.72,.20},gold={1,.72,.20},crimson={.97,.22,.28},emerald={.20,.86,.50},
 violet={.71,.43,1},frost={.28,.77,1},silver={.88,.91,.95},
 ember={1,.42,.13},rose={1,.47,.70},toxic={.73,1,.18},
}
local TEXTURES={
 smooth="Interface\\TARGETINGFRAME\\UI-StatusBar",
 flat="Interface\\Buttons\\WHITE8X8",
}
local SHAPES={bars=true,slim=true,square=true,chunky=true}
local ALLOWED={shape=SHAPES,palette=PALETTES,texture=TEXTURES,
 growth={right=true,left=true},border={none=true,subtle=true,strong=true},
 colorMode={uniform=true,progression=true,rainbow=true}}
local NUMBERS={
 width={8,42,1},height={5,26,1},gap={0,16,1},
 opacity={.35,1,.05},emptyAlpha={.1,1,.05},
 customR={0,1,.05},customG={0,1,.05},customB={0,1,.05},
 offset={0,32,1},
}
local function clamp(value,min,max)
 return math.max(min,math.min(max,value))
end
function S:PipPresets() return PRESETS end
function S:PipPalettes() return PALETTES end
function S:PipStyle()
 local d=self:HUDSettings()
 d.pipStyle=d.pipStyle or {}
 local style=d.pipStyle
 local base=PRESETS.classic
 for k,v in pairs(base) do if style[k]==nil then style[k]=v end end
 if style.growth~="left" then style.growth="right" end
 if not ALLOWED.border[style.border] then style.border="subtle" end
 if style.offset==nil then style.offset=5 end
 if style.customR==nil then style.customR=1 end
 if style.customG==nil then style.customG=.72 end
 if style.customB==nil then style.customB=.20 end
 if not ALLOWED.colorMode[style.colorMode] then style.colorMode="uniform" end
 return style
end
function S:PresetPips(name)
 if KoolSupport:IsInCombat() then return false,"Change pip designs outside combat" end
 local preset=PRESETS[name]
 if not preset then return false,"Unknown preset" end
 local style=self:PipStyle()
 for key,value in pairs(preset) do style[key]=value end
 style.growth="right"
 style.border="subtle"
 self:Relayout()
 return true
end
function S:CustomizePips(key,value)
 if KoolSupport:IsInCombat() then return false,"Change pip designs outside combat" end
 local options=ALLOWED[key]
 local range=NUMBERS[key]
 if options then
  if options[value]==nil then return false,"Invalid "..tostring(key) end
 elseif range then
  if type(value)~="number" or value~=value or value==math.huge or value==-math.huge then
   return false,"Invalid "..tostring(key)
  end
  value=clamp(value,range[1],range[2])
  local step=range[3]
  value=math.floor(value/step+.5)*step
  value=clamp(value,range[1],range[2])
 else
  return false,"Unknown pip setting"
 end
 local style=self:PipStyle()
 style[key]=value
 if key=="customR" or key=="customG" or key=="customB" then style.palette="custom" end
 self:Relayout()
 return true
end
function S:ResetPipDesign()
 if KoolSupport:IsInCombat() then return false,"Reset outside combat" end
 self:HUDSettings().pipStyle={}
 self:Relayout()
 return true
end
function S:PipTexture()
 local style=self:PipStyle()
 return TEXTURES[style.texture] or TEXTURES.smooth
end
function S:StyleComboBar(bar,i)
 local style=self:PipStyle()
 local palette=PALETTES[style.palette] or PALETTES.gold
 if style.palette=="custom" then
  palette={style.customR,style.customG,style.customB}
 end
 if style.colorMode=="rainbow" then
  local rainbow={PALETTES.crimson,PALETTES.ember,PALETTES.gold,PALETTES.emerald,PALETTES.violet}
  palette=rainbow[i] or PALETTES.gold
 elseif style.colorMode=="progression" then
  local factor=.58+.105*(i-1)
  palette={palette[1]*factor,palette[2]*factor,palette[3]*factor}
 end
 if bar.SetStatusBarTexture then bar:SetStatusBarTexture(self:PipTexture()) end
 if bar.SetStatusBarColor then
  bar:SetStatusBarColor(palette[1],palette[2],palette[3],style.opacity)
 end
 if bar.backing and bar.backing.SetColorTexture then
  bar.backing:SetColorTexture(.065,.077,.095,style.emptyAlpha)
 elseif bar.backing and bar.backing.SetTexture and bar.backing.SetVertexColor then
  bar.backing:SetTexture(TEXTURES.flat)
  bar.backing:SetVertexColor(.065,.077,.095,style.emptyAlpha)
 end
 if bar.borderArt and bar.borderArt.SetColorTexture then
  local alpha=style.border=="none" and 0 or style.border=="strong" and .95 or .5
  bar.borderArt:SetColorTexture(palette[1],palette[2],palette[3],alpha)
 end
end
function S:PipDimensions()
 local style=self:PipStyle()
 local w,h=style.width,style.height
 if style.shape=="slim" then h=math.min(h,7)
 elseif style.shape=="square" then
  local side=math.min(w,h)
  w,h=side,side
 elseif style.shape=="chunky" then h=math.max(h,14) end
 local size=self:HUDSettings().hudScale
 return w*size,h*size,style.gap*size,style.offset*size
end
