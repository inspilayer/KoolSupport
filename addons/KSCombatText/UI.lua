-- KS Combat Text Studio settings: compact dark UI; all operations explicit.
local S=KSCombatText
local KS=KoolSupport
local KIT=KS.UIKit
local GOLD="|cffffd87a"
local DIM="|cff9fb4ad"
local FONT=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local laneNames={incoming="Incoming",heal="Healing",notification="Notices",target="Observed target"}
local orderPatterns={"float","rise","drop","fountain","arc","wave","pop","burst",
 "cascade","slide","pulse","static"}
local orderFonts={"blizzard","friz","arial","morpheus","skurri"}
local orderPalettes={"classic","muted","arcade","class"}
local orderPresets={"classic","minimal","arcade","fountain","cascade","zen"}
local selectedLane="incoming"
local function text(parent,str,x,y,w,size)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 f:SetWidth(w);f:SetJustifyH("LEFT");f:SetText(str)
 if type(f.SetFont)=="function" then
  pcall(f.SetFont,f,FONT,size or 14,"")
 end
 return f
end
local function box(parent,x,y,w,h)
 if KIT then return KIT:Panel(parent,x,y,w,h) end
 local f=CreateFrame("Frame",nil,parent)
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetSize(w,h)
 return f
end
local function button(parent,label,x,y,w,click)
 if KIT then return KIT:Button(parent,label,x,y,w,click,"secondary",29) end
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetSize(w,29)
 b:SetText(label);b:SetScript("OnClick",click)
 return b
end
local function labelNum(value)
 if type(value)=="number" then return string.format("%.2f",value):gsub("0+$",""):gsub("%.$","") end
 return tostring(value)
end
function S.BuildPage(parent)
 local state=S:Store()
 if not S.LANES[1] then return end
 local banner=text(parent,GOLD.."KS COMBAT TEXT  /  STUDIO|r",22,-17,900,22)
 text(parent,DIM.."Blizzard-faithful native dock or original animated text zones. All positions save per character.|r",
  22,-49,900,13)
 local mode=box(parent,21,-79,895,82)
 text(mode,GOLD.."RENDER MODE|r",13,-12,335,16)
 text(mode,DIM.."Blizzard frame: "..((CombatText or CombatTextFrame) and "detected" or "unavailable").."|r",491,-11,380,12)
 local status=text(parent,"",22,-650,860,13)
 local lane=state.lanes[selectedLane]
 local laneHeader,details
 local fields={}
 local function refresh()
  state=S:Store()
  lane=state.lanes[selectedLane]
  if laneHeader then
   laneHeader:SetText(GOLD..laneNames[selectedLane]:upper().."|r  "..DIM..
    (lane.enabled and "ACTIVE" or "DISABLED").."|r  |  "..lane.pattern:upper().."  ·  "..
    lane.font:upper().."  ·  "..lane.palette:upper())
  end
  if details then details:SetText(
   "Size "..labelNum(lane.size).."   /   Life "..labelNum(lane.lifetime)..
   "s   /   Speed "..labelNum(lane.speed).."   /   Spread "..labelNum(lane.spread)..
   "   /   Crit "..labelNum(lane.critScale).."×   /   Max "..labelNum(lane.limit))
  end
  for key,entry in pairs(fields) do
   if entry and type(entry.SetText)=="function" then
    entry:SetText(key..": "..labelNum(lane[key]))
   end
  end
 end
 local function apply(fn,...)
  local ok,why=fn(S,...)
  status:SetText(ok and (GOLD.."Saved. Use PREVIEW to see the result.|r") or
    ("|cffffa58d"..(why or "Setting unavailable").."|r"))
  refresh()
 end
 local native=button(mode,state.mode=="native" and "[ SELECTED ] BLIZZARD" or "BLIZZARD ORIGINAL",13,-38,269,function()apply(S.SetMode,"native")end)
 local studio=button(mode,state.mode=="studio" and "[ SELECTED ] STUDIO" or "ANIMATED STUDIO",296,-38,269,function()apply(S.SetMode,"studio")end)
 button(mode,state.unlocked and "LOCK ZONES" or "UNLOCK & DRAG",582,-38,292,function()
  apply(S.SetUnlocked,not S:Store().unlocked)
  KS:ShowPage("combat_text")
 end)
 local left=box(parent,21,-172,895,88)
 text(left,GOLD.."PRESET LIBRARY|r",13,-12,400,16)
 for i,name in ipairs(orderPresets) do
  button(left,name:upper(),12+(i-1)*146,-45,137,function()apply(S.Preset,name)end)
 end
 local nav=box(parent,21,-270,895,72)
 text(nav,GOLD.."TEXT AREAS|r",13,-9,670,16)
 for i,key in ipairs(S.LANES) do
  local title=laneNames[key]:upper()
  button(nav,title,12+(i-1)*219,-36,206,function()
   selectedLane=key
   KS:ShowPage("combat_text")
  end)
 end
 local panel=box(parent,21,-352,895,277)
 laneHeader=text(panel,"",13,-9,700,16)
 button(panel,lane.enabled and "DISABLE LANE" or "ENABLE LANE",722,-8,161,function()
  apply(S.SetLaneOption,selectedLane,"enabled",not S:Store().lanes[selectedLane].enabled)
  KS:ShowPage("combat_text")
 end)
 -- A compact effect selector, not giant red option buttons.
 text(panel,DIM.."ANIMATION|r",13,-42,300,12)
 for i,pattern in ipairs(orderPatterns) do
  local x=12+((i-1)%6)*145
  local y=-64-math.floor((i-1)/6)*35
  button(panel,pattern:upper(),x,y,137,function()
   apply(S.SetLaneOption,selectedLane,"pattern",pattern)
  end)
 end
 text(panel,DIM.."FONT|r",13,-149,200,12)
 for i,font in ipairs(orderFonts) do
  button(panel,font:upper(),12+(i-1)*174,-172,167,function()
   apply(S.SetLaneOption,selectedLane,"font",font)
  end)
 end
 text(panel,DIM.."PALETTE|r",13,-213,205,12)
 for i,palette in ipairs(orderPalettes) do
  button(panel,palette:upper(),12+(i-1)*218,-236,206,function()
   apply(S.SetLaneOption,selectedLane,"palette",palette)
  end
  )
 end
  -- Floating area constraints use the lower portion of the page.
 -- Keep the size controls inside a subpage accessible via a single button.
 button(parent,"TYPE, SPEED & EFFECTS",21,-650,267,function()KS:ShowPage("combat_text_tuning")end)
 button(parent,"PREVIEW",305,-650,165,function()
  local ok,why=S:Preview()
  status:SetText(ok and GOLD.."Preview sent to your four zones.|r" or
   "|cffffa58d"..(why or "Preview unavailable").."|r")
 end)
 button(parent,"BLIZZARD VISIBILITY",486,-650,217,function()KS:ShowPage("combat_text_tuning")end)
 button(parent,"RESET ALL",717,-650,199,function()
  apply(S.Reset)
  KS:ShowPage("combat_text")
 end)
 -- Status footer is over buttons in this page; place at top of options card.
 status:ClearAllPoints()
 status:SetPoint("TOPLEFT",parent,"TOPLEFT",24,-338)
 refresh()
end
local adjustments={
 {"size","TEXT SIZE",2},
 {"lifetime","DURATION",.2},
 {"speed","SCROLL SPEED",10},
 {"spread","SPREAD",5},
 {"critScale","CRIT SCALE",.1},
 {"opacity","OPACITY",.1},
 {"limit","ACTIVE LINES",1},
}
function S.BuildTuningPage(parent)
 local status=text(parent,"",23,-154,865,13)
 text(parent,GOLD.."COMBAT TEXT  /  FINE TUNING|r",22,-17,882,22)
 text(parent,DIM.."Tune individual lanes, text density, crit intensity and Blizzard integration.|r",
 22,-55,875,13)
 local bar=box(parent,21,-87,895,67)
 for i,key in ipairs(S.LANES) do
  button(bar,laneNames[key],12+(i-1)*218,-18,207,function()
   selectedLane=key
   KS:ShowPage("combat_text_tuning")
  end)
 end
 local lane=S:Store().lanes[selectedLane]
 local p=box(parent,21,-169,895,365)
 local title=text(p,GOLD..laneNames[selectedLane]:upper().."  |  TYPOGRAPHY + MOTION|r",14,-14,790,17)
 local function save(key,value)
  local ok,why=S:SetLaneOption(selectedLane,key,value)
  status:SetText(ok and GOLD.."Updated "..key.."|r" or "|cffffa58d"..(why or "Unable to save").."|r")
  KS:ShowPage("combat_text_tuning")
 end
 for i,entry in ipairs(adjustments) do
  local col=(i-1)%2
  local row=math.floor((i-1)/2)
  local x=15+col*441
  local y=-56-row*64
  local key,name,step=entry[1],entry[2],entry[3]
  local value=S:Store().lanes[selectedLane][key]
  text(p,name..": "..labelNum(value),x,y,197,14)
  button(p,"−",x+212,y+4,67,function()save(key,value-step)end)
  button(p,"+",x+293,y+4,67,function()save(key,value+step)end)
 end
 text(p,GOLD.."FONT OUTLINES|r",15,-323,230,14)
 for i,entry in ipairs({{"","NONE"},{"OUTLINE","OUTLINE"},{"THICKOUTLINE","THICK"}}) do
  button(p,entry[2],249+(i-1)*207,-321,195,function()
   save("outline",entry[1])
  end)
 end
 local tools=box(parent,21,-541,895,82)
 local db=S:Store()
 text(tools,GOLD.."BLIZZARD & TARGET SETTINGS|r",13,-10,700,15)
 button(tools,db.mode=="native" and "NATIVE MODE" or "STUDIO MODE",13,-43,175,function()
  S:SetMode(db.mode=="native" and "studio" or "native")
  KS:ShowPage("combat_text_tuning")
 end)
 button(tools,db.nativeHidden and "RESTORE BLIZZARD" or "HIDE BLIZZARD",201,-43,195,function()
  local ok,why=S:SetOption("nativeHidden",not S:Store().nativeHidden)
  status:SetText(ok and "Blizzard setting changed." or (why or "Client did not accept CVar change."))
  KS:ShowPage("combat_text_tuning")
 end)
 button(tools,db.showTarget and "TARGET EVENTS ON" or "TARGET EVENTS OFF",408,-43,213,function()
  S:SetOption("showTarget",not S:Store().showTarget)
  KS:ShowPage("combat_text_tuning")
 end)
 button(tools,db.unlocked and "LOCK ANCHORS" or "UNLOCK ANCHORS",635,-43,246,function()
  S:SetUnlocked(not S:Store().unlocked)
  KS:ShowPage("combat_text_tuning")
 end)
 button(parent,"BACK TO STUDIO",24,-650,241,function()KS:ShowPage("combat_text")end)
 button(parent,"PREVIEW",279,-650,186,function()
  local ok,why=S:Preview()
  status:SetText(ok and "Preview sent." or (why or "Preview unavailable"))
 end)
 text(parent,DIM.."Target events are OBSERVED hits on your current target; Forever cannot reliably attribute all of them to you.|r",
  22,-626,888,12)
end

SLASH_KSCOMBAT1="/kct"
SlashCmdList=SlashCmdList or {}
SlashCmdList.KSCOMBAT=function(raw)
 local command=(raw or ""):match("^%s*(%S+)") or ""
 if command=="test" then S:Preview()
 elseif command=="status" then
  if type(print)=="function" then
   print("KoolSupport  "..S:SourceStats())
  end
 elseif command=="unlock" then S:SetUnlocked(true)
 elseif command=="lock" then S:SetUnlocked(false)
 else KS:Open("combat_text") end
end
