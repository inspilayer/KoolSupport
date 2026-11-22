-- Shared WoW-native host UI. Module pages register themselves; Base never imports their Lua.
local KS = KoolSupport
local window, content, pageWidgets, currentPage, navigation
local navButtons = {}
local openGroup=nil
local FONT=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local KIT=KS.UIKit
local function enlarge(obj,size)
 if obj and obj.SetFont then pcall(obj.SetFont,obj,FONT,size,"") end
end
local function tile(parent,x,y,w,h)
 if KIT then return KIT:Panel(parent,x,y,w,h) end
 local p=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 p:SetSize(w,h);p:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 if p.SetBackdrop then
  p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  if p.SetBackdropColor then p:SetBackdropColor(0.08,0.10,0.13,0.94) end
  if p.SetBackdropBorderColor then p:SetBackdropBorderColor(0.45,0.34,0.19,0.8) end
 end
 return p
end
local GOLD = "|cffffd87a"
local MUTED = "|cff9fb4ad"

local function label(parent, text, x, y, width, font)
  local item = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
  item:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  item:SetWidth(width)
  item:SetJustifyH("LEFT")
  item:SetText(text)
  enlarge(item,font=="GameFontNormalLarge" and 21 or font=="GameFontHighlightSmall" and 12 or 14)
  return item
end
local function button(parent, text, x, y, width, onClick)
  if KIT then return KIT:Button(parent,text,x,y,width,onClick,"secondary",33) end
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 160, 33)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b:SetText(text)
  if b.GetFontString then enlarge(b:GetFontString(),13) end
  b:SetScript("OnClick", onClick)
  return b
end

local function buildHome(parent)
 label(parent,GOLD.."KoolSupport|r  Addon Workshop",26,-25,880,"GameFontNormalLarge")
 label(parent,"All your tools, organized and ready to use.",26,-70,870)
 local cards={
  {"MACRO WORKSHOP","Presets, spellbook and custom macro creation.","Open Macro Suite","macro_suite"},
  {"COMBAT","Afflictions, stealth, tracking and threat.","Open Afflictions","afflictions"},
  {"SOCIAL","Guilty Forever and Campfire Chat.","Open Guilty Forever","guilty_forever"},
  {"QUESTS & TOOLS","Quest checker, launch checks and reminders.","Open Quest Checker","quest_checker"},
 }
 for i,c in ipairs(cards) do
  local x=25+((i-1)%2)*455
  local y=-125-math.floor((i-1)/2)*222
  local box=tile(parent,x,y,430,204)
  label(box,GOLD..c[1].."|r",18,-20,390,"GameFontNormalLarge")
  label(box,c[2],18,-71,391)
  button(box,c[3],18,-134,391,function()
   KS:ShowPage(KS:CanOpenPage(c[4]) and c[4] or "modules")
  end)
 end
 label(parent,MUTED.."TIP: Expand a category on the left, or browse the FAQ.|r",25,-583,885)
 button(parent,"Module Manager",25,-620,272,function()KS:ShowPage("modules")end)
 button(parent,"FAQ / Help",311,-620,272,function()KS:ShowPage("faq")end)
 button(parent,"Launch Checks",597,-620,272,function()KS:ShowPage("launch_checks")end)
end
-- Base feature: a compact player-only XP inactivity timer, not a child module.
local function buildXPReminder(parent)
  local R=KS.XPReminder
  label(parent,GOLD.."Time Since Last XP|r",20,-22,740,"GameFontNormalLarge")
  label(parent,"A gentle reminder to get out of town and level.",20,-65,730)
  label(parent,MUTED.."Every 15 minutes without earned XP, you'll get a chat and center-screen nudge.|r",
    20,-94,765,"GameFontHighlightSmall")
  label(parent,MUTED.."Gaining XP or leveling resets the clock. No reminders at max level.|r",
    20,-117,765,"GameFontHighlightSmall")
  local status=label(parent,"",20,-173,765,"GameFontNormalLarge")
  local buttonLabel=label(parent,"",20,-207,765,"GameFontHighlightSmall")
  local function refresh()
    if not R then status:SetText("XP reminder unavailable");return end
    status:SetText(R:Status())
    buttonLabel:SetText("Per-character reminder: "..(R:Settings().enabled and "ON" or "OFF"))
  end
  button(parent,"Toggle reminder",20,-255,224,function()
    if not R then return end
    R:SetEnabled(not R:Settings().enabled)
    refresh()
  end)
  button(parent,"Test notification",267,-255,224,function()
    if R and type(R.Preview)=="function" then R:Preview() end
  end)
  button(parent,"Refresh timer",514,-255,225,refresh)
  label(parent,GOLD.."How it works|r",20,-324,700,"GameFontNormalLarge")
  label(parent,"15 minutes with no XP: first reminder. Another 15: second reminder, and so on.",
    20,-356,760,"GameFontHighlightSmall")
  label(parent,"The timer starts fresh on login/reload; it never counts overnight offline time.",
    20,-383,760,"GameFontHighlightSmall")
  label(parent,"No quest automation, spellcasting, party messages, or extra minimap icons.",
    20,-410,760,"GameFontHighlightSmall")
  local last=0
  parent:SetScript("OnUpdate",function(_,delta)
    if type(delta)~="number" or delta<0 then return end
    last=last+delta
    if last>=5 then last=0;refresh() end
  end)
  refresh()
end

local function buildModules(parent)
 label(parent,GOLD.."Module Manager|r",25,-25,875,"GameFontNormalLarge")
 label(parent,"Enable the tools you need. Disabled features disappear from navigation.",25,-72,885)
 for i,id in ipairs(KS.moduleOrder) do
  local def=KS.modules[id]
  local enabled=KS:IsModuleEnabled(id)
  local x=25+((i-1)%2)*455
  local y=-121-math.floor((i-1)/2)*135
  local box=tile(parent,x,y,430,122)
  label(box,def.title,17,-15,390,"GameFontNormalLarge")
  label(box,enabled and "|cff7ddca1ENABLED|r" or "|cffffaa77DISABLED|r",17,-61,230)
  button(box,enabled and "Disable" or "Enable",287,-61,127,function()
   local ok,reason=KS:SetModuleEnabled(id,not enabled)
   if not ok and print then print("KoolSupport: "..tostring(reason)) end
  end)
 end
 label(parent,MUTED.."Your module preferences are stored per character.|r",25,-668,885)
end
local FAQ={
 {"GETTING STARTED","Click a left-side category, then choose a tool. The Modules page lets you enable or disable features."},
 {"GUILTY FOREVER","Use /kool guilty. Type /gf enemy First Surname to open an enemy record with the name filled in."},
 {"IGNORE REMINDERS","Using /ignore can ask for a reason. Your notes stay private; no party-leaving or chat messages are sent."},
 {"ENEMY TAGS","Save both first name and surname, select Enemy Faction and write a reason. This does not ignore the player."},
 {"MACRO WORKSHOP","Choose presets or create a custom macro. Review each macro before installing."},
 {"AFFLICTIONS","Open Combat > KS Afflictions for damage-over-time tracking and optional DIES estimates."},
 {"QUEST CHECKER","Find quests by name and check their reported completion status."},
 {"UPDATES & DATA","Settings are per character. Back up SavedVariables when reinstalling or removing addon folders."},
}
local function buildFAQ(parent)
 label(parent,GOLD.."Frequently Asked Questions|r",25,-25,890,"GameFontNormalLarge")
 label(parent,"Quick answers for KoolSupport and World of Warcraft: Forever.",25,-72,880)
 for i,q in ipairs(FAQ) do
  local x=25+((i-1)%2)*455
  local y=-121-math.floor((i-1)/2)*135
  local box=tile(parent,x,y,430,124)
  label(box,GOLD..q[1].."|r",16,-14,395,"GameFontNormalLarge")
  local answer=label(box,q[2],16,-57,396)
  if answer.SetWordWrap then answer:SetWordWrap(true) end
 end
end
local function buildLaunchChecks(parent)
  label(parent, GOLD .. "Launch Checks  -  World of Warcraft: Forever", 20, -19, 775, "GameFontNormalLarge")
  label(parent, "Read-only snapshot: installed modules and API presence, NOT proof features work.", 20, -54, 775)
  label(parent, "No combat values, SavedVariables, macros or network requests are modified.", 20, -79, 775)
  local rows=KS:CollectLaunchChecks()
  for i,entry in ipairs(rows) do
    local y=-115-(i-1)*31
    local tone=(entry.status=="MISSING" or entry.status=="UNAVAILABLE") and "|cffff9a87" or
      (entry.status=="REVIEW" or entry.status=="UNKNOWN" or entry.status=="UNVERIFIED") and "|cffffd87a" or "|cff9bd9ab"
    label(parent, entry.title, 20, y, 225, "GameFontHighlightSmall")
    label(parent, tone .. entry.status .. "|r", 255, y, 116, "GameFontHighlightSmall")
    label(parent, entry.detail, 376, y, 408, "GameFontHighlightSmall")
  end
  label(parent, MUTED .. "API presence is preliminary; verify gameplay, tooltips and persistence in-client.|r",20,-540,775,"GameFontHighlightSmall")
  button(parent, "Re-run checks", 20, -565, 186, function()KS:ShowPage("launch_checks")end)
end
-- Common visual system based on the Guilty Forever ledger. Additive only:
-- module layouts, saved settings and click handlers remain owned by each module.
local themePageIDs={
 macro_suite=true,full_spellbook=true,macro_workshop=true,
 support_session=true,afflictions=true,campfire_chat=true,
 quest_checker=true,ks_threat=true,stealth=true,stealth_talents=true,
}
local function themeTexture(parent,x,y,w,h,r,g,b,a)
 if not parent or type(parent.CreateTexture)~="function" then return end
 local t=parent:CreateTexture(nil,"BACKGROUND")
 if not t or type(t.SetColorTexture)~="function" then return end
 t:SetColorTexture(r,g,b,a)
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 t:SetSize(w,h)
 return t
end
local function themePageBackground(pane,id)
 if not themePageIDs[id] then return end
 -- Background textures never block buttons or input fields.
 themeTexture(pane,7,-7,928,679,.045,.063,.079,.94)
 themeTexture(pane,7,-7,928,3,.82,.61,.33,.91)
 themeTexture(pane,15,-85,912,1,.38,.31,.22,.72)
 local zones={
  macro_suite={{16,-118,909,444}},
  full_spellbook={{16,-124,909,466}},
  macro_workshop={{16,-125,909,327},{16,-460,909,146}},
  support_session={{16,-151,909,380}},
  afflictions={{16,-94,909,258},{16,-369,909,239}},
  campfire_chat={{16,-140,909,336}},
  quest_checker={{16,-187,909,356}},
  ks_threat={{16,-112,909,105},{16,-232,909,335}},
  stealth_talents={{16,-159,909,403}},
 }
 for _,r in ipairs(zones[id] or {}) do
  themeTexture(pane,r[1],r[2],r[3],r[4],.095,.125,.149,.62)
  themeTexture(pane,r[1],r[2],3,r[4],.68,.51,.28,.72)
 end
end
local function themePageFonts(pane,id)
 if not themePageIDs[id] then return end
 -- Increase text size consistently, without touching gameplay methods.
 local seen={}
 local function visit(node,depth)
  if not node or seen[node] or depth>6 then return end
  seen[node]=true
  local kind
  if type(node.GetObjectType)=="function" then
   local ok,k=pcall(node.GetObjectType,node)
   if ok then kind=k end
  end
  if (kind=="FontString" or kind=="EditBox") and type(node.GetFont)=="function" and type(node.SetFont)=="function" then
   local ok,path,size,flags=pcall(node.GetFont,node)
   if ok and type(size)=="number" then
    local target=kind=="EditBox" and math.min(15,math.max(12,size)) or math.max(11,math.min(15,size))
    pcall(node.SetFont,node,path or FONT,target,flags or "")
   end
  elseif (kind=="Button" or kind=="CheckButton") then
   if KIT and kind=="Button" then KIT:StyleExistingButton(node) end
   if type(node.GetFontString)=="function" then
    local ok,font=pcall(node.GetFontString,node)
    if ok and font then visit(font,depth+1) end
   end
   -- Native button surfaces remain interactive, but adopt slate/gold.
   if kind=="Button" and type(node.GetNormalTexture)=="function" then
    local ok,texture=pcall(node.GetNormalTexture,node)
    if ok and texture and type(texture.SetVertexColor)=="function" then
     pcall(texture.SetVertexColor,texture,.33,.35,.38,1)
    end
   end
  end
  if type(node.GetRegions)=="function" then
   local ok,regions=pcall(function()return {node:GetRegions()}end)
   if ok then for _,region in ipairs(regions) do visit(region,depth+1) end end
  end
  if type(node.GetChildren)=="function" then
   local ok,children=pcall(function()return {node:GetChildren()}end)
   if ok then for _,child in ipairs(children) do visit(child,depth+1) end end
  end
 end
 visit(pane,0)
end

local function clearCurrent()
  if pageWidgets then pageWidgets:Hide() end
  pageWidgets = nil
end
-- Compact category sidebar: only the active group expands, replacing a tall
-- stack of bulky buttons with simple text rows. Page IDs/dependencies unchanged.
local categories={
  {id="workshop",label="MACROS",pages={"macro_suite","full_spellbook","macro_workshop","support_session"}},
  {id="combat",label="COMBAT",pages={"afflictions","ks_threat","stealth","stealth_designer","stealth_talents"}},
  {id="social",label="SOCIAL",pages={"campfire_chat","guilty_forever"}},
  {id="system",label="TOOLS",pages={"quest_checker","xp_reminder","launch_checks"}},
  {id="help",label="FAQ / HELP",pages={"faq"}},
}
local function groupForPage(id)
  for _,group in ipairs(categories) do
    for _,page in ipairs(group.pages) do
      if id==page then return group.id end
    end
  end
end
local function makeNavRow(key,action)
  local b=navButtons[key]
  if b then return b end
  b=CreateFrame("Button",nil,navigation)
  b:SetSize(250,34)
  b:EnableMouse(true)
  local section=key:sub(1,6)=="group:"
  b.isSection=section
  local name=b:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  enlarge(name,14)
  name:SetPoint("LEFT",b,"LEFT",section and 15 or 12,0)
  name:SetWidth(section and 221 or 229)
  name:SetJustifyH("LEFT")
  b:SetFontString(name)
  b.caption=name
  if type(b.CreateTexture)=="function" then
    -- Section categories are actual solid buttons, not translucent captions.
    -- Solid dark backing masks busy world scenery and makes labels readable.
    local shade=b:CreateTexture(nil,"BACKGROUND")
    if shade and shade.SetColorTexture then
      shade:SetColorTexture(.13,.17,.20,section and 1 or .98)
      shade:SetAllPoints(b)
      if not section then shade:Hide() end
      b.selectedShade=shade
    end
    if section then
      local hover=b:CreateTexture(nil,"BORDER")
      if hover and hover.SetColorTexture then
        hover:SetColorTexture(.25,.32,.34,1)
        hover:SetAllPoints(b)
        hover:Hide()
        b.hoverShade=hover
      end
    end
    local stripe=b:CreateTexture(nil,"ARTWORK")
    if stripe and stripe.SetColorTexture then
      stripe:SetColorTexture(.90,.70,.40,.95)
      stripe:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
      stripe:SetSize(3,34)
      stripe:Hide()
      b.selectedStripe=stripe
    end
  end
  if section then
    b:SetScript("OnEnter",function(self)
      if self.hoverShade then self.hoverShade:Show() end
    end)
    b:SetScript("OnLeave",function(self)
      if self.hoverShade then self.hoverShade:Hide() end
    end)
  end
  b:SetScript("OnClick",action)
  navButtons[key]=b
  return b
end
local function redrawNavigation()
  if not navigation then return end
  for _,item in pairs(navButtons) do item:Hide() end
  local y=-14
  local used={}
  local function drawPage(id,indent)
    if used[id] or not KS:CanOpenPage(id) then return end
    local p=KS.pages[id]
    if not p then return end
    used[id]=true
    local b=makeNavRow(id,function()KS:ShowPage(id)end)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT",navigation,"TOPLEFT",indent and 16 or 0,y)
    b.caption:SetText((currentPage==id and GOLD or "|cfff0f2f0")..
      (p.title or id).."|r")
    if b.selectedShade then if currentPage==id then b.selectedShade:Show() else b.selectedShade:Hide() end end
    if b.selectedStripe then if currentPage==id then b.selectedStripe:Show() else b.selectedStripe:Hide() end end
    b:Show()
    y=y-34
  end
  drawPage("home")
  drawPage("modules")
  y=y-5
  for _,group in ipairs(categories) do
    local hasPages=false
    for _,page in ipairs(group.pages) do
      if KS:CanOpenPage(page) and KS.pages[page] then hasPages=true;break end
    end
    if hasPages then
      local key="group:"..group.id
      local b=makeNavRow(key,function()
        openGroup=(openGroup==group.id) and nil or group.id
        redrawNavigation()
      end)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT",navigation,"TOPLEFT",0,y)
      local expanded=openGroup==group.id
      b.caption:SetText((expanded and "|cffffd894" or "|cfff7f9f8")..
        (expanded and "  -  " or "  +  ")..group.label.."|r")
      -- An opaque filled section button stays visible even when collapsed.
      if b.selectedShade then
        b.selectedShade:Show()
        if type(b.selectedShade.SetColorTexture)=="function" then
          if expanded then
            b.selectedShade:SetColorTexture(.22,.30,.32,1)
          else
            b.selectedShade:SetColorTexture(.13,.17,.20,1)
          end
        end
      end
      if b.selectedStripe then
        if expanded then b.selectedStripe:Show() else b.selectedStripe:Hide() end
      end
      b:Show()
      y=y-40
      if openGroup==group.id then
        for _,page in ipairs(group.pages) do drawPage(page,true) end
        y=y-8
      end
    end
  end
  for _,id in ipairs(KS.pageOrder) do
    if not used[id] and not groupForPage(id) then drawPage(id) end
  end
end

function KS:RefreshUI()
  if window and window:IsShown() then self:ShowPage(currentPage or "home") end
end
function KS:ShowPage(id)
  if not self:CanOpenPage(id) then id = "home" end
  if not window then self:Open(id); return end
  currentPage = id
  local group=groupForPage(id)
  if group then openGroup=group
  elseif id=="home" or id=="modules" then openGroup=nil end
  clearCurrent()
  local pane = CreateFrame("Frame", nil, content)
  pane:SetAllPoints(content)
  pageWidgets = pane
  themePageBackground(pane,id)
  if id == "home" then buildHome(pane)
  elseif id == "modules" then buildModules(pane)
  elseif id == "faq" then buildFAQ(pane)
  elseif id == "launch_checks" then buildLaunchChecks(pane)
  elseif id == "xp_reminder" then buildXPReminder(pane)
  else
    local page = self.pages[id]
    if page then page.build(pane, self) else buildHome(pane) end
  end
  themePageFonts(pane,id)
  redrawNavigation()
  pane:Show()
end
function KS:Open(page)
  if not window then
    window = CreateFrame("Frame", "KoolSupportMainPanel", UIParent, "BackdropTemplate")
    window:SetSize(1280, 830)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=26,insets={left=8,right=8,top=8,bottom=8}})
    if UIParent and UIParent.GetWidth and UIParent.GetHeight then
      local w, h = UIParent:GetWidth(), UIParent:GetHeight()
      if w and h and w > 0 and h > 0 then window:SetScale(math.min(.84, w / 1310, h / 860)) end
    end
    if window.SetBackdropColor then window:SetBackdropColor(0.06,0.07,0.09,0.96) end
    label(window, GOLD.."KoolSupport|r  "..KS.VERSION, 34, -27, 950, "GameFontNormalLarge")
    button(window, "X", 1216, -23, 40, function() window:Hide() end)
    navigation = CreateFrame("Frame", nil, window)
    navigation:SetPoint("TOPLEFT", window, "TOPLEFT", 26, -100)
    navigation:SetSize(250, 680)
    if type(navigation.CreateTexture)=="function" then
      local backdrop=navigation:CreateTexture(nil,"BACKGROUND")
      if backdrop and backdrop.SetColorTexture then
        backdrop:SetColorTexture(.035,.048,.062,1)
        backdrop:SetAllPoints(navigation)
        navigation.backdrop=backdrop
      end
    end
    content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 292, -100)
    content:SetSize(950, 695)
    if UISpecialFrames then table.insert(UISpecialFrames, "KoolSupportMainPanel") end
  end
  window:Show()
  self:ShowPage(page or "home")
end
KS:RegisterPage({id="home",title="Home",build=buildHome})
KS:RegisterPage({id="faq",title="FAQ",build=buildFAQ})
KS:RegisterPage({id="modules",title="Modules",build=buildModules})
KS:RegisterPage({id="launch_checks",title="Launch Checks",build=buildLaunchChecks})
KS:RegisterPage({id="xp_reminder",title="Time Since XP",build=buildXPReminder})
