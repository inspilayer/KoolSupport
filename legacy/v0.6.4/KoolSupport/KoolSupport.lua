-- KoolSupport v0.6.2 | WoW Forever 1.60 / Interface 16001
-- Manual out-of-combat macro builder. This addon never casts, follows,
-- chooses combat actions, or sends inputs to another client.
local SUPPORTED = {DRUID=true,PALADIN=true,SHAMAN=true,PRIEST=true}
local CLASS_ORDER = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local CLASS_DISPLAY = {WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",PRIEST="Priest",SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid"}
local CLASS_SPECS = {DRUID={"Restoration / hybrid"},PALADIN={"Holy"},SHAMAN={"Restoration"},PRIEST={"Holy","Discipline"}}
local ICON = "INV_Misc_QuestionMark"
local MAX_BODY = 255
local MAX_NAME = 16
local PAGE_SIZE = 6
local class, spec, targetClass, selectedName
local profile, roster, page = {}, {}, 1
local frame, rowWidgets = nil, {}
local suiteMode, suitePage = "preset",1
local SUITE_PAGE_SIZE = 16
local showHome, showSetup
local status = "Select the main you want to support, then Generate."

local function say(msg) print("|cffebc964KoolSupport:|r " .. tostring(msg)) end
local function combat() return InCombatLockdown and InCombatLockdown() end
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end
local function safeName(s)
  s = trim(s)
  if #s<1 or #s>60 or s:find("[%c/;\\%[%]{}<>|]") then return nil end
  return s
end
local function db()
  KoolSupportDB = KoolSupportDB or {}
  local d=KoolSupportDB
  d.owned=d.owned or {}
  d.generated=d.generated or {}
  d.enabledProfiles=d.enabledProfiles or {}
  d.customEnabled=d.customEnabled or {}
  return d
end
local function specValues() return CLASS_SPECS[class] or {} end
local function pkey() return (class or "NONE")..":"..(spec or "NONE")..":"..(targetClass or "NONE") end
-- Class presets and saved drafts are selected independently but generated together.
local function enabled(d)
  local store=d.isCustom and db().customEnabled or db().enabledProfiles
  local settings=store[pkey()]
  if settings and settings[d.name]~=nil then return settings[d.name] end
  return d.isCustom and false or d.default
end
local function savedDefs()
  local list={}
  local d=db()
  for _,name in ipairs(d.customOrder or {}) do
    local draft=d.customDrafts and d.customDrafts[name]
    if draft and type(draft.body)=="string" then
      list[#list+1]={name=name,caption="Saved Custom Builder: "..name,group="Custom",body=draft.body,default=false,isCustom=true}
    end
  end
  return list
end
local function activeDefs()
  if suiteMode=="custom" then return savedDefs() end
  return profile
end
local function allDefs()
  local defs={}
  for _,d in ipairs(profile) do defs[#defs+1]=d end
  for _,d in ipairs(savedDefs()) do defs[#defs+1]=d end
  return defs
end
local function getActualClass()
  if type(UnitClass)=="function" then
    local _,token=UnitClass("player")
    if token and SUPPORTED[token] then return token end
    return token
  end
end
local function rebuildRoster()
  roster={}
  if combat() then return end
  local seen={}
  local function add(unit)
    if not UnitExists or not UnitExists(unit) then return end
    local name,realm=UnitName(unit)
    if type(name)~="string" or name=="" then return end
    if type(realm)=="string" and realm~="" and type(GetRealmName)=="function" and realm~=GetRealmName() then
      name=name.."-"..realm
    end
    if not seen[name] then
      seen[name]=true
      local _,token=UnitClass(unit)
      roster[#roster+1]={name=name,class=token}
    end
  end
  local count = (GetNumGroupMembers and GetNumGroupMembers()) or 0
  if IsInRaid and IsInRaid() then
    for i=1, math.min(count,40) do add("raid"..i) end
  else
    local subgroup=(GetNumSubgroupMembers and GetNumSubgroupMembers()) or 0
    for i=1,math.min(subgroup,4) do add("party"..i) end
    add("player")
  end
  table.sort(roster,function(a,b) return a.name<b.name end)
  page=math.min(page,math.max(1,math.ceil(#roster/PAGE_SIZE)))
end
local function assemble()
  if SUPPORTED[class] then
    profile=KoolSupportProfiles.Build(class,spec or "Holy",targetClass or "WARRIOR",safeName(selectedName) or "Target")
  else
    profile={}
  end
end
local function setStatus(s)
  status=s
  if frame then frame.status:SetText(s) end
end
-- Compact cast label and real in-game ability tooltip, never a fabricated description.
-- Show the first cast as an indication only: macros can contain multiple commands.
local function primaryCast(def)
  if not def or type(def.body)~='string' then return nil end
  if def.name=='KS-Track' then return 'Travel Form' end -- representative of adaptive form + follow
  for line in (def.body..'\n'):gmatch('(.-)\n') do
    local raw=line:match('^%s*/cast%s+(.+)') or line:match('^%s*/castsequence%s+(.+)')
    if raw then
      raw=raw:gsub('%b[]',''):gsub('^%s*reset=[^%s]+%s*','')
      local first=trim(raw:match('^([^;,]+)') or ''):gsub('^!','')
      if first~='' then return first end
    end
  end
  return nil
end
local function showAbilityTooltip(owner,def)
  if not def or not GameTooltip then return end
  GameTooltip:SetOwner(owner,'ANCHOR_RIGHT')
  local spell=primaryCast(def)
  local rendered=false
  if spell then
    local id
    if C_Spell and type(C_Spell.GetSpellInfo)=='function' then
      local ok,info=pcall(C_Spell.GetSpellInfo,spell)
      if ok and type(info)=='table' then id=info.spellID end
    end
    if not id and type(GetSpellInfo)=='function' then
      local ok,_,_,_,_,_,_,oldID=pcall(GetSpellInfo,spell)
      if ok then id=oldID end
    end
    if id and type(GameTooltip.SetSpellByID)=='function' then
      rendered=pcall(GameTooltip.SetSpellByID,GameTooltip,id)
    end
  end
  if not rendered then GameTooltip:SetText(spell or def.caption or 'Utility macro') end
  GameTooltip:AddLine(def.caption or def.name or 'Macro',1,.85,.3,true)
  if def.note and def.note~='' then GameTooltip:AddLine(def.note,.85,.85,.73,true) end
  GameTooltip:AddLine('Macro commands:',.7,.9,.8)
  GameTooltip:AddLine(def.body or '',.65,.85,.9,true)
  GameTooltip:Show()
end
local function refresh()
  if not frame then return end
  frame.you:SetText("Support character: " .. (CLASS_DISPLAY[class] or (class or "Unknown")) .. "  |cff8dada4(auto-detected)|r")
  frame.spec:SetText("Build: " .. (spec or "N/A") .. "  [change]")
  frame.selected:SetText("Session target: " .. (selectedName or "(none)"))
  frame.target:SetText("Recipient class: " .. (CLASS_DISPLAY[targetClass] or "Unknown") .. "  [change]")
  local current="(none)"
  if UnitExists and UnitExists("focus") and not combat() then
    local focus=UnitName("focus")
    if focus then current=focus end
  end
  frame.focus:SetText("In-game focus: "..current)
  frame.focusMacro:SetText(safeName(selectedName) and ("KS-Session: /focus "..selectedName.."  (target unchanged)") or "KS-Session: choose a name to generate /focus NAME")
  frame.status:SetText(status)
  if frame.homeSummary then frame.homeSummary:SetText("Playing: "..(CLASS_DISPLAY[class] or (class or "Other")).."    Supporting: "..(selectedName or "Not selected")) end
  if safeName(selectedName) and frame.input:GetText()~=selectedName then frame.input:SetText(selectedName) end
  local start=(page-1)*PAGE_SIZE
  for i=1,PAGE_SIZE do
    local e=roster[start+i]
    local b=frame.roster[i]
    if e then b:Show(); b:SetText(e.name.."  ("..(CLASS_DISPLAY[e.class] or "?")..")")
    else b:Hide() end
  end
  frame.page:SetText(page.."/"..math.max(1,math.ceil(#roster/PAGE_SIZE)))
  local defs=activeDefs()
  suitePage=math.min(suitePage,math.max(1,math.ceil(#defs/SUITE_PAGE_SIZE)))
  for i,w in ipairs(rowWidgets) do
    local d=defs[(suitePage-1)*SUITE_PAGE_SIZE+i]
    if d then
      w.check:Show(); w.label:Show(); w.ability:Show(); w.tip:Show()
      w.check:SetChecked(enabled(d))
      w.label:SetText(d.name:gsub("^KS%-","") .. "  |cffc4d6bc"..d.caption.."|r")
      w.check.KSdef=d
      w.tip.KSdef=d
      local spell=primaryCast(d)
      if not spell then
        spell=(d.body:find('/focus',1,true) and 'Set focus') or
              (d.body:find('/follow',1,true) and 'Follow') or 'Utility'
      end
      local label=d.name=='KS-Track' and 'Adaptive forms' or spell
      w.ability:SetText('|cffffd56e'..label:sub(1,22)..'|r')
    else
      w.check:Hide(); w.label:Hide(); w.ability:Hide(); w.tip:Hide(); w.check.KSdef=nil; w.tip.KSdef=nil
    end
  end
  frame.generate:SetEnabled(not combat())
  frame.listtitle:SetText("Macro Suite")
  if frame.presetsButton then frame.presetsButton:SetText(suiteMode=="preset" and "[Class Presets]" or "Class Presets") end
  if frame.customButton then frame.customButton:SetText(suiteMode=="custom" and "[Custom ("..#savedDefs()..")]" or "Custom ("..#savedDefs()..")") end
  if frame.suitePaging then frame.suitePaging:SetText(suitePage.." / "..math.max(1,math.ceil(#defs/SUITE_PAGE_SIZE))) end
end
local function choose(name, token)
  if combat() then setStatus("Change the session outside combat.");return end
  name=safeName(name)
  if not name then setStatus("Invalid character name. Use Character or Character-Realm.");return end
  selectedName=name
  db().character=name
  if CLASS_DISPLAY[token] then targetClass=token; db().recipientClass=token end
  assemble()
  setStatus("Ready. KS-Session focuses "..name.." by name; healing and attacks remain focus-based.")
  refresh()
end
local function setRecipientClass(token)
  if combat() then setStatus("Change recipient class outside combat.");return end
  targetClass=token; db().recipientClass=token
  assemble(); refresh()
end
local function nextRecipient()
  for i,s in ipairs(CLASS_ORDER) do
    if s==targetClass then return setRecipientClass(CLASS_ORDER[i%#CLASS_ORDER+1]) end
  end
  setRecipientClass("WARRIOR")
end
local function nextSpec()
  if combat() then setStatus("Change build outside combat."); return end
  local list=specValues()
  for i,s in ipairs(list) do
    if s==spec then spec=list[i%#list+1]; db().spec=spec; assemble(); refresh(); return end
  end
  spec=list[1]; db().spec=spec; assemble(); refresh()
end
local function generate()
  if combat() then setStatus("Can't generate macros in combat.");return end
  local target=safeName(selectedName)
  local anyPreset=false
  for _,d in ipairs(profile) do if enabled(d) then anyPreset=true;break end end
  if anyPreset and not target then setStatus("Choose a session character for enabled class presets, or disable those presets to install standalone custom drafts.");return end
  if type(CreateMacro)~="function" or type(EditMacro)~="function" or
     type(GetMacroIndexByName)~="function" or type(GetMacroBody)~="function" or
     type(GetNumMacros)~="function" then
    setStatus("Native macro APIs unavailable on this build; no changes made.");return
  end
  local dbase=db()
  local tasks, newCount = {},0
  for _,d in ipairs(allDefs()) do
    if enabled(d) then
      if not d.isCustom and not target then
        setStatus("Preset macro "..d.name.." requires a named supportee. No changes made.");return
      end
      if #d.name>MAX_NAME or #d.body>MAX_BODY then
        setStatus("Too long: "..d.name.." ("..#d.body.." bytes). No changes made.");return
      end
      local idx=GetMacroIndexByName(d.name)
      if not idx or idx==0 then
        newCount=newCount+1
        tasks[#tasks+1]={def=d,index=0}
      else
        if not dbase.owned[d.name] then
          setStatus("Conflict: "..d.name.." belongs to another macro. No changes made.");return
        end
        local original=dbase.generated[d.name]
        local current=GetMacroBody(idx)
        -- v0.1 did not store original bodies. Do not overwrite those macros blindly.
        if not original or current~=original then
          setStatus("Manual change/legacy macro: "..d.name..". Back it up or remove it before generating.");return
        end
        tasks[#tasks+1]={def=d,index=idx}
      end
    end
  end
  if #tasks==0 then setStatus("Enable at least one macro.");return end
  local _, used = GetNumMacros()
  local cap = (type(MAX_CHARACTER_MACROS)=="number" and MAX_CHARACTER_MACROS) or 30
  if type(used)=="number" and used+newCount>cap then
    setStatus("Need "..newCount.." new macro slots; only "..math.max(0,cap-used).." available. Uncheck optional macros.")
    return
  end
  local created,updated,failed=0,0,0
  for _,t in ipairs(tasks) do
    local ok,result
    if t.index==0 then
      ok,result=pcall(CreateMacro,t.def.name,ICON,t.def.body,true)
      if ok and type(result)=="number" and result>0 then
        created=created+1
        dbase.owned[t.def.name]=true
        dbase.generated[t.def.name]=t.def.body
      else failed=failed+1 end
    else
      ok,result=pcall(EditMacro,t.index,nil,nil,t.def.body)
      if ok and result~=nil then
        updated=updated+1
        dbase.generated[t.def.name]=t.def.body
      else failed=failed+1 end
    end
  end
  setStatus("Created "..created.." / updated "..updated.." / failed "..failed..". Custom and class preset selections preserved.")
  say(status)
end
local function button(p,label,w,h,x,y,callback)
  local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate")
  b:SetSize(w,h);b:SetPoint("TOPLEFT",x,y);b:SetText(label);b:SetScript("OnClick",callback)
  return b
end
-- Tint the native Blizzard button textures; the game still supplies all UI assets.
local function redAccent(widget)
  if not widget or not widget.GetNormalTexture then return end
  local normal=widget:GetNormalTexture()
  if normal and normal.SetVertexColor then normal:SetVertexColor(.72,.24,.19) end
  local push=widget.GetPushedTexture and widget:GetPushedTexture()
  if push and push.SetVertexColor then push:SetVertexColor(.52,.12,.10) end
end
local function txt(p,t,x,y,template)
  local f=p:CreateFontString(nil,"OVERLAY",template or "GameFontHighlightSmall")
  f:SetPoint("TOPLEFT",x,y);f:SetText(t);f:SetJustifyH("LEFT");return f
end
local function createUI()
  if frame then return end
  frame=CreateFrame("Frame","KoolSupportPanel",UIParent,"BackdropTemplate")
  frame:SetSize(1020,850);frame:SetPoint("CENTER");frame:SetMovable(true)
  -- Fit whole frame into the client at smaller UI scales without inner scrolling.
  if UIParent and UIParent.GetWidth and UIParent.GetHeight then
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if type(w)=="number" and type(h)=="number" and w>0 and h>0 then
      frame:SetScale(math.min(1,(w-28)/1020,(h-28)/850))
    end
  end
  frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart",function(s) s:StartMoving() end)
  frame:SetScript("OnDragStop",function(s) s:StopMovingOrSizing() end)
  frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
  frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=16,edgeSize=24,insets={left=8,right=8,top=8,bottom=8}})
  frame:SetBackdropColor(.015,.065,.052,.96)
  table.insert(UISpecialFrames,"KoolSupportPanel")
  txt(frame,"|cffffd83fKoolSupport|r  |cffb6c8c6v0.6.3 - Macro Workshop|r",20,-15,"GameFontNormalLarge")
  button(frame,"Home",92,27,20,-42,function()if showHome then showHome() end end)
  txt(frame,"|cffffd83fSupport Session Setup|r",119,-47,"GameFontNormal")
  button(frame,"X",29,25,967,-10,function()frame:Hide()end)
  button(frame,"Spellbook",153,27,665,-42,function()KoolSupportStudio.Open('spellbook')end)
  button(frame,"Custom Builder",153,27,824,-42,function()KoolSupportStudio.Open('builder')end)
  frame.you=txt(frame,"Support character:",20,-78,"GameFontNormal")
  frame.spec=button(frame,"Build",302,25,20,-110,nextSpec)
  frame.selected=txt(frame,"Session target:",20,-149,"GameFontNormal")
  frame.target=button(frame,"Recipient class",302,25,20,-181,nextRecipient)
  txt(frame,"Party / raid roster (select one)",20,-222,"GameFontNormal")
  frame.roster={}
  for i=1,PAGE_SIZE do
    frame.roster[i]=button(frame,"",302,24,20,-245-(i-1)*28,function()
      local entry=roster[(page-1)*PAGE_SIZE+i]
      if entry then choose(entry.name,entry.class) end
    end)
  end
  button(frame,"<",32,22,20,-421,function()page=math.max(1,page-1);refresh()end)
  frame.page=txt(frame,"1/1",146,-426)
  button(frame,">",32,22,290,-421,function()page=math.min(page+1,math.max(1,math.ceil(#roster/PAGE_SIZE)));refresh()end)
  button(frame,"Refresh party",302,24,20,-456,function()
    if combat() then setStatus("Cannot refresh in combat.") else rebuildRoster();setStatus("Party refreshed.") end
    refresh()
  end)
  txt(frame,"Or enter a character name (Character-Realm):",20,-502)
  frame.input=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
  frame.input:SetSize(200,28);frame.input:SetPoint("TOPLEFT",28,-522)
  frame.input:SetAutoFocus(false);frame.input:SetMaxLetters(60)
  frame.input:SetScript("OnEnterPressed",function(s)choose(s:GetText());s:ClearFocus()end)
  frame.input:SetScript("OnEscapePressed",function(s)s:ClearFocus()end)
  button(frame,"Select",76,24,246,-523,function()choose(frame.input:GetText())end)
  frame.focusMacro=txt(frame,"KS-Session: choose a name to generate /focus NAME",20,-554)
  frame.focus=txt(frame,"In-game focus:",20,-579)
  txt(frame,"The selected class adjusts buffs/totems, not automatic decisions.",20,-602)
  txt(frame,"No addon automation or cross-client input broadcasting.",20,-622)

  frame.listtitle=txt(frame,"Macro Suite",357,-78,"GameFontNormal")
  frame.presetsButton=button(frame,"[Class Presets]",156,29,657,-73,function()
    suiteMode="preset";db().suiteMode=suiteMode;suitePage=1
    setStatus("Select class presets here. Click Custom to add saved drafts to this SAME suite.")
    refresh()
  end)
  frame.customButton=button(frame,"Custom (0)",142,29,823,-73,function()
    suiteMode="custom";db().suiteMode=suiteMode;suitePage=1
    setStatus("Saved Custom Builder macros. Check one to ADD it alongside your class presets. Return with Class Presets.")
    refresh()
  end)
  redAccent(frame.customButton)
  txt(frame,"Check macros on either tab to add to suite:",357,-106)
  button(frame,"<",27,22,845,-104,function()suitePage=math.max(1,suitePage-1);refresh()end)
  frame.suitePaging=txt(frame,"1/1",877,-108)
  button(frame,">",27,22,940,-104,function()suitePage=suitePage+1;refresh()end)
  for i=1,SUITE_PAGE_SIZE do
    local y=-132-(i-1)*35
    local cb=CreateFrame("CheckButton",nil,frame,"UICheckButtonTemplate")
    cb:SetSize(27,27);cb:SetPoint("TOPLEFT",351,y)
    cb:SetScript("OnClick",function(s)
      local d=s.KSdef
      if not d then return end
      local key=pkey()
      local store=d.isCustom and db().customEnabled or db().enabledProfiles
      local settings=store[key] or {}
      settings[d.name]=s:GetChecked() and true or false
      store[key]=settings
    end)
    cb:SetScript("OnEnter",function(s)showAbilityTooltip(s,s.KSdef)end)
    cb:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide() end end)
    local label=txt(frame,"",387,y-5)
    label:SetWidth(390)
    local ability=txt(frame,"",795,y-5,"GameFontHighlightSmall")
    ability:SetWidth(143);ability:SetJustifyH("RIGHT")
    -- Mouseover the '?' to see Blizzard's full native spell tooltip (when learned).
    local tip=CreateFrame("Frame",nil,frame)
    tip:SetSize(29,29);tip:SetPoint("TOPLEFT",944,y-2)
    tip:EnableMouse(true)
    txt(tip,"|cffffd945?|r",7,-5,"GameFontNormal")
    tip:SetScript("OnEnter",function(s)showAbilityTooltip(s,s.KSdef)end)
    tip:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide() end end)
    rowWidgets[#rowWidgets+1]={check=cb,label=label,ability=ability,tip=tip}
  end
  frame.generate=button(frame,"Generate / Update selected macros",980,39,20,-747,generate)
  redAccent(frame.generate)
  txt(frame,"Next: /macro > Character-Specific; drag KS macros to action bars; press KS-Session to establish focus.",20,-789)
  frame.status=txt(frame,status,20,-810,"GameFontHighlightSmall")
  frame.status:SetWidth(970)
  -- Landing page overlays the existing native controls. The real WoW frame
  -- remains in charge of rendering; there is no browser view inside WoW.
  local landing=CreateFrame("Frame",nil,frame,"BackdropTemplate")
  landing:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-74)
  landing:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-12,12)
  landing:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=5,right=5,top=5,bottom=5}})
  landing:SetBackdropColor(.018,.105,.084,.97)
  frame.landing=landing
  txt(landing,"|cffffd83fWELCOME TO KOOLSUPPORT|r",24,-24,"GameFontNormalLarge")
  txt(landing,"A class-aware macro workshop for every player.",24,-59,"GameFontHighlight")
  txt(landing,"Choose a tool. All macro creation requires your action and is blocked in combat.",24,-88,"GameFontHighlightSmall")
  frame.homeSummary=txt(landing,"Playing: ...",24,-120,"GameFontNormal")
  local function homeButton(label,y,callback,description)
    redAccent(button(landing,label,890,45,35,y,callback))
    txt(landing,description,45,y-49,"GameFontHighlightSmall")
  end
  showSetup=function(which)
    if which then suiteMode=which;db().suiteMode=which;suitePage=1 end
    landing:Hide();refresh()
  end
  showHome=function()refresh();landing:Show()end
  homeButton("Support Session Setup",-158,function()showSetup("preset")end,"Choose a supporter and focus target; generate healing, utility and follow macros.")
  homeButton("Macro Suite · Class Preset",-246,function()showSetup("preset")end,"Choose recommended support actions for your class and recipient.")
  homeButton("Macro Suite · Custom",-334,function()showSetup("custom")end,"Add saved Custom Builder drafts alongside selected class presets.")
  homeButton("Full Spellbook",-422,function()KoolSupportStudio.Open("spellbook")end,"Browse learned spells and open the spell-based macro builder.")
  homeButton("Custom Builder",-510,function()KoolSupportStudio.Open("builder")end,"Create a native macro using editable commands and conditions.")
  frame:SetScript("OnShow",function()rebuildRoster();assemble();refresh();if showHome then showHome()end end)
  frame:Hide()
end
SLASH_KOOLSUPPORT1="/kool"
SLASH_KOOLSUPPORT2="/koolsupport"
SlashCmdList.KOOLSUPPORT=function(s)
  s=trim(s)
  if s=="help" then
    say("/kool opens Home. /kool setup opens Support Session Setup. /kool custom opens the Custom Macro Suite. /kool builder opens the editor.")
  elseif s=="spellbook" or s=="builder" then
    KoolSupportStudio.Open(s)
  elseif s=="setup" or s=="custom" or s=="presets" then
    createUI();frame:Show()
    if showSetup then showSetup(s=="custom" and "custom" or "preset") end
  elseif s:match("^set%s+") then
    choose(s:match("^set%s+(.+)$"))
  else
    createUI()
    if frame:IsShown() then frame:Hide() else frame:Show() end
  end
end
local loader=CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent",function()
  local d=db()
  suiteMode=d.suiteMode=="custom" and "custom" or "preset"
  class=getActualClass()
  local values=specValues()
  spec=d.spec
  local valid=false
  for _,v in ipairs(values) do if v==spec then valid=true end end
  if not valid then spec=values[1]; d.spec=spec end
  targetClass=CLASS_DISPLAY[d.recipientClass] and d.recipientClass or "WARRIOR"
  selectedName=safeName(d.character or "")
  assemble()
  say("Ready ("..(CLASS_DISPLAY[class] or "other class").."). /kool opens the Macro Workshop Home.")
end)
