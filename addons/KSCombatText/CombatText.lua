-- KS Combat Text Studio: player-operated visual customization for Forever.
-- All event payload amounts may be protected secrets. Pass unchanged to
-- FontString:SetText; NEVER branch, compare, format, cache as numbers, or
-- calculate animations from combat payloads.
KSCombatText=KSCombatText or {}
local S=KSCombatText
local KS=KoolSupport

S.PRESETS={
 classic={pattern="float",font="blizzard",size=23,lifetime=1.65,speed=70,spread=22,critScale=1.3,outline="OUTLINE",palette="classic"},
 minimal={pattern="rise",font="arial",size=17,lifetime=1.20,speed=45,spread=4,critScale=1.15,outline="OUTLINE",palette="muted"},
 arcade={pattern="pop",font="skurri",size=27,lifetime=1.35,speed=35,spread=38,critScale=1.6,outline="THICKOUTLINE",palette="arcade"},
 fountain={pattern="fountain",font="morpheus",size=24,lifetime=1.8,speed=93,spread=55,critScale=1.4,outline="OUTLINE",palette="class"},
 cascade={pattern="cascade",font="blizzard",size=21,lifetime=1.8,speed=75,spread=18,critScale=1.3,outline="OUTLINE",palette="classic"},
 zen={pattern="pulse",font="blizzard",size=20,lifetime=1.4,speed=25,spread=2,critScale=1.17,outline="",palette="muted"},
}
S.FONTS={
 blizzard=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
 friz="Fonts\\FRIZQT__.TTF", arial="Fonts\\ARIALN.TTF",
 morpheus="Fonts\\MORPHEUS.TTF", skurri="Fonts\\SKURRI.TTF",
}
S.PATTERNS={
 float=true,rise=true,drop=true,fountain=true,arc=true,wave=true,
 pop=true,burst=true,cascade=true,slide=true,pulse=true,static=true,
}
S.PALETTES={
 classic={incoming={1,.32,.27},heal={.36,1,.47},notification={1,.85,.38},target={1,.77,.37}},
 muted={incoming={.86,.69,.68},heal={.61,.87,.75},notification={.83,.82,.71},target={.83,.77,.70}},
 arcade={incoming={1,.23,.45},heal={.37,1,.56},notification={1,.89,.19},target={1,.51,.12}},
 class={incoming={1,.44,.32},heal={.40,.90,.66},notification={.67,.66,1},target={1,.79,.26}},
}
S.LANES={"incoming","heal","notification","target"}
S.EVENT_TYPES={
 DAMAGE={"incoming",false},DAMAGE_CRIT={"incoming",true},DAMAGE_SHIELD={"incoming",false},
 HEAL={"heal",false},HEAL_CRIT={"heal",true},HEAL_ABSORB={"heal",false},
 MISS={"notification",false},DODGE={"notification",false},PARRY={"notification",false},
 BLOCK={"notification",false},RESIST={"notification",false},IMMUNE={"notification",false},
 ENERGIZE={"notification",false},HONOR_GAINED={"notification",false},
 XP_GAIN={"notification",false},FACTION={"notification",false},
 SPELL_ACTIVE={"notification",false},SPELL_AURA_START={"notification",false},
}
local MAX_ACTIVE=20
local function ordinary(value)
 if type(issecretvalue)=="function" then
  local ok,secret=pcall(issecretvalue,value)
  if not ok or secret then return false end
 end
 return true
end
local function finite(v)
 return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end
local function clamp(n,lo,hi)
 return math.max(lo,math.min(hi,n))
end
local defaultOffsets={
 incoming={x=-195,y=35},heal={x=0,y=75},
 notification={x=0,y=-90},target={x=195,y=35},
}
function S:Store()
 local db=KS:GetDatabase()
 db.modules=db.modules or {}
 db.modules.ks_combat_text=db.modules.ks_combat_text or {}
 local s=db.modules.ks_combat_text
 if s.mode~="native" and s.mode~="studio" then s.mode="native" end
 if type(s.unlocked)~="boolean" then s.unlocked=false end
 if type(s.nativeHidden)~="boolean" then s.nativeHidden=false end
 if type(s.showTarget)~="boolean" then s.showTarget=false end
 if type(s.lanes)~="table" then s.lanes={} end
 if type(s.preset)~="string" or not self.PRESETS[s.preset] then s.preset="classic" end
 if type(s.native)~="table" then s.native={x=0,y=0} end
 for _,key in ipairs(self.LANES) do
  local o=defaultOffsets[key]
  if type(s.lanes[key])~="table" then s.lanes[key]={} end
  local l=s.lanes[key]
  if not finite(l.x) then l.x=o.x end
  if not finite(l.y) then l.y=o.y end
  if type(l.enabled)~="boolean" then l.enabled=key~="target" end
  if not self.PATTERNS[l.pattern] then l.pattern=self.PRESETS[s.preset].pattern end
  if not self.FONTS[l.font] then l.font=self.PRESETS[s.preset].font end
  if not self.PALETTES[l.palette] then l.palette=self.PRESETS[s.preset].palette end
  if not finite(l.size) then l.size=self.PRESETS[s.preset].size end
  if not finite(l.lifetime) then l.lifetime=self.PRESETS[s.preset].lifetime end
  if not finite(l.speed) then l.speed=self.PRESETS[s.preset].speed end
  if not finite(l.spread) then l.spread=self.PRESETS[s.preset].spread end
  if not finite(l.critScale) then l.critScale=self.PRESETS[s.preset].critScale end
  if l.outline~="" and l.outline~="OUTLINE" and l.outline~="THICKOUTLINE" then l.outline=self.PRESETS[s.preset].outline end
  if not finite(l.opacity) then l.opacity=1 end
  if not finite(l.limit) then l.limit=12 end
  l.size=clamp(l.size,10,54); l.lifetime=clamp(l.lifetime,.5,4)
  l.speed=clamp(l.speed,0,190);l.spread=clamp(l.spread,0,100)
  l.critScale=clamp(l.critScale,1,2.5);l.opacity=clamp(l.opacity,.3,1)
  l.limit=clamp(math.floor(l.limit),2,MAX_ACTIVE)
  l.x=clamp(l.x,-1500,1500);l.y=clamp(l.y,-1000,1000)
 end
 if not finite(s.native.x) then s.native.x=0 end
 if not finite(s.native.y) then s.native.y=0 end
 return s
end
function S:Enabled()
 return KS:IsModuleEnabled("ks_combat_text")
end
function S:SetMode(mode)
 if KS:IsInCombat() then return false,"Change modes out of combat" end
 if mode~="native" and mode~="studio" then return false,"Unknown mode" end
 local db=self:Store()
 if db.mode=="native" and mode~="native" then self:RestoreBlizzardAnchor() end
 db.mode=mode
 self:Refresh()
 return true
end
function S:SetUnlocked(enabled)
 if KS:IsInCombat() then return false,"Move zones out of combat" end
 self:Store().unlocked=not not enabled
 self:Refresh()
 return true
end
function S:SetOption(key,value)
 if KS:IsInCombat() then return false,"Change combat text outside combat" end
 local s=self:Store()
 if key=="showTarget" then s.showTarget=not not value
 elseif key=="nativeHidden" then
  local before=s.nativeHidden
  s.nativeHidden=not not value
  local ok,why=self:UpdateBlizzardVisibility()
  if not ok then s.nativeHidden=before;return false,why end
 else return false,"Unknown setting" end
 self:Refresh()
 return true
end
function S:SetLaneOption(lane,key,value)
 if KS:IsInCombat() then return false,"Change lanes out of combat" end
 if not defaultOffsets[lane] then return false,"Unknown lane" end
 local opts=self:Store().lanes[lane]
 if key=="enabled" then
  if type(value)~="boolean" then return false,"Expected boolean" end
 elseif key=="pattern" then
  if not self.PATTERNS[value] then return false,"Unknown animation" end
 elseif key=="font" then
  if not self.FONTS[value] then return false,"Unknown font" end
 elseif key=="palette" then
  if not self.PALETTES[value] then return false,"Unknown palette" end
 elseif key=="outline" then
  if value~="" and value~="OUTLINE" and value~="THICKOUTLINE" then return false,"Unknown outline" end
 else
  local limits={
   size={10,54,1},lifetime={.5,4,.1},speed={0,190,5},spread={0,100,5},
   critScale={1,2.5,.05},opacity={.3,1,.05},limit={2,MAX_ACTIVE,1},
  }
  local range=limits[key]
  if not range or not finite(value) then return false,"Invalid lane option" end
  value=clamp(math.floor(value/range[3]+.5)*range[3],range[1],range[2])
 end
 opts[key]=value
 self:Refresh()
 return true
end
function S:Preset(name)
 if KS:IsInCombat() then return false,"Presets unavailable in combat" end
 local p=self.PRESETS[name]
 if not p then return false,"Unknown preset" end
 local s=self:Store()
 s.preset=name
 for _,k in ipairs(self.LANES) do
  local lane=s.lanes[k]
  for _,field in ipairs({"pattern","font","size","lifetime","speed","spread","critScale","outline","palette"}) do
   lane[field]=p[field]
  end
 end
 self:Refresh()
 return true
end
function S:Reset()
 if KS:IsInCombat() then return false,"Reset outside combat" end
 KS:GetDatabase().modules.ks_combat_text=nil
 self:RestoreBlizzardAnchor()
 self:RestoreBlizzardVisibility()
 self:Refresh()
 return true
end
function S:MoveLane(lane,x,y)
 if KS:IsInCombat() then return false,"Move zones out of combat" end
 if not defaultOffsets[lane] or not finite(x) or not finite(y) then return false,"Invalid position" end
 local s=self:Store().lanes[lane]
 s.x=clamp(x,-1500,1500);s.y=clamp(y,-1000,1000)
 self:Refresh()
 return true
end
function S:MoveNative(x,y)
 if KS:IsInCombat() then return false,"Move Blizzard text outside combat" end
 if not finite(x) or not finite(y) then return false,"Invalid position" end
 self:Store().native.x=clamp(x,-1500,1500)
 self:Store().native.y=clamp(y,-1000,1000)
 self:Refresh()
 return true
end

-- A native-font fallback only. The addon does not bundle third-party fonts.
function S:FontFor(lane)
 return self.FONTS[lane.font] or self.FONTS.blizzard
end
-- Scripted purely by age and message sequence. Never by the combat value.
function S:Animation(pattern,age,life,speed,spread,serial)
 local t=clamp(age/life,0,1)
 local dir=serial%2==0 and 1 or -1
 local phase=(serial%5-2)/2
 local dx,dy,scale=0,0,1
 if pattern=="rise" then dy=t*speed
 elseif pattern=="drop" then dy=-t*speed
 elseif pattern=="float" then dy=t*speed;dx=dir*spread*t*.45
 elseif pattern=="fountain" then dy=4*speed*t*(1-t);dx=dir*spread*t
 elseif pattern=="arc" then dy=t*speed;dx=dir*math.sin(t*math.pi)*spread
 elseif pattern=="wave" then dy=t*speed;dx=math.sin(t*math.pi*3+serial)*spread
 elseif pattern=="pop" then dy=t*speed*.5;scale=1+.42*math.sin(math.pi*math.min(1,t*3))
 elseif pattern=="burst" then dy=t*speed;dx=phase*spread*t;scale=1+.45*math.max(0,1-t*4)
 elseif pattern=="cascade" then dy=t*speed;dx=dir*spread*.3
 elseif pattern=="slide" then dx=dir*t*speed
 elseif pattern=="pulse" then scale=1+.20*math.sin(t*math.pi*2)
 end
 local alpha=t<.12 and t/.12 or t>.67 and (1-t)/.33 or 1
 return dx,dy,clamp(alpha,0,1),scale
end
function S:SourceStats()
 local a=self.stats or {nativeEvents=0,targetEvents=0,dropped=0,errors=0}
 return ("Native events: %d | Target observations: %d | Dropped: %d | Errors: %d"):format(
  a.nativeEvents,a.targetEvents,a.dropped,a.errors)
end
S.stats=S.stats or {nativeEvents=0,targetEvents=0,dropped=0,errors=0}
-- S.Queue is injected by Render.lua after its UI pools are initialized.
function S:Receive(event,...)
 if not self:Enabled() or self:Store().mode~="studio" then return end
 if event=="COMBAT_TEXT_UPDATE" then
  local kind,value=...
  if not ordinary(kind) or type(kind)~="string" then return end
  local entry=self.EVENT_TYPES[kind]
  if not entry then return end
  self.stats.nativeEvents=self.stats.nativeEvents+1
  if type(self.Queue)=="function" then self:Queue(entry[1],value,entry[2]) end
 elseif event=="UNIT_COMBAT" then
  local unit,action,descriptor,amount=...
  if not ordinary(unit) or unit~="target" or not self:Store().showTarget then return end
  -- UNIT_COMBAT does NOT attribute target damage to a player. This is an
  -- observed-target text lane only; do not label it "your hits".
  if not ordinary(action) or type(action)~="string" then return end
  if action~="WOUND" and action~="HEAL" then return end
  self.stats.targetEvents=self.stats.targetEvents+1
  if type(self.Queue)=="function" then self:Queue("target",amount,false) end
 end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"COMBAT_TEXT_UPDATE","UNIT_COMBAT","PLAYER_ENTERING_WORLD",
 "PLAYER_REGEN_ENABLED"}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,...)
 if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED" then
  if type(S.Refresh)=="function" then S:Refresh() end
 else
  S:Receive(event,...)
 end
end)
S.eventFrame=events
