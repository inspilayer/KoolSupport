-- KoolSupport Studio v0.6 / WoW Forever Interface 16001
-- Manual, out-of-combat authoring only. Never casts or follows automatically.
KoolSupportStudio = {}
local Studio = KoolSupportStudio
local MAX_BODY, MAX_NAME = 255, 16
local ui, spells, filtered = nil, {}, {}
local spellPage, draftPage, selectedSpell = 1, 1, nil
local mode = 'spellbook'
local draft = {name='KSC-New',spell='',unit='focus',conditions={'help','nodead'},body='#showtooltip\n'}
local status = 'Scan your spellbook or create a custom macro.'
local PER_PAGE = 11
local UNITS = {'focus','focustarget','player','target','mouseover','targettarget','pet','pettarget','party1','party2','party3','party4','raid1','arena1','cursor','none'}
local FLAG_CATEGORIES = {
 {name='Common',items={'help','harm','exists','noexists','nodead','dead','combat','nocombat'}},
 {name='Keyboard',items={'mod','nomod','mod:shift','mod:alt','mod:ctrl','button:1','button:2','actionbar:1'}},
 {name='Forms',items={'form:1','form:2','form:3','noform','stealth','nostealth','mounted','nomounted','swimming','indoors','outdoors','flying','flyable'}},
 {name='Group/Pet',items={'group','nogroup','group:party','group:raid','party','raid','pet','nopet','equipped:Shields','channeling','nochanneling'}},
 {name='Advanced',items={'spec:1','spec:2','known:Spell Name','noknown:Spell Name','vehicleui','bonusbar:1','resting'}},
}
local FLAGS={}
for _,category in ipairs(FLAG_CATEGORIES) do for _,flag in ipairs(category.items) do FLAGS[#FLAGS+1]=flag end end
local COMMAND_CATEGORIES = {
 {name='Casting',entries={
  {'Cast spell','/cast Spell Name'}, {'Mouseover heal','/cast [@mouseover,help,nodead] Spell Name'},
  {'Focus enemy cast','/cast [@focustarget,harm,nodead] Spell Name'}, {'Self cast','/cast [@player] Spell Name'},
  {'Heal fallback','/cast [@mouseover,help,nodead][help,nodead][@player] Spell Name'},
  {'Cast sequence','/castsequence reset=target Spell One, Spell Two'},
  {'Random cast','/castrandom Spell One, Spell Two'}, {'Show tooltip','#showtooltip Spell Name'},
  {'Help / harm','/cast [help,nodead] Friendly Spell; [harm,nodead] Harmful Spell'},
  {'Shift / normal','/cast [mod:shift] Spell A; Spell B'},
 }},
 {name='Targeting',entries={
  {'Set named focus',function() return '/focus '..((KoolSupportDB and KoolSupportDB.character) or 'CharacterName') end},
  {'Focus target','/focus [@target,exists]'}, {'Clear focus','/clearfocus'},
  {'Follow focus','/follow focus'}, {'Assist focus','/assist focus'},
  {'Target focus','/target [@focus]'}, {'Target exact','/targetexact CharacterName'},
  {'Target last','/targetlasttarget'}, {'Enemy nearest','/targetenemy'},
  {'Friend nearest','/targetfriend'}, {'Clear target','/cleartarget'},
  {'Last enemy','/targetlastenemy'}, {'Last friend','/targetlastfriend'},
 }},
 {name='Combat / form',entries={
  {'Stop casting','/stopcasting'}, {'Stop macro','/stopmacro [@focus,noexists]'},
  {'Start attack','/startattack [harm,nodead]'}, {'Stop attack','/stopattack'},
  {'Cancel form','/cancelform [form]'}, {'Cancel aura','/cancelaura Aura Name'},
  {'Dismount','/dismount'}, {'Keep form on','/cast !Toggle Spell'},
  {'Stop targeting','/stopspelltarget'}, {'Change bar','/changeactionbar 2'},
  {'Swap bar','/swapactionbar 1 2'},
 }},
 {name='Items / gear',entries={
  {'Use item','/use Item Name'}, {'Trinket 1','/use 13'}, {'Trinket 2','/use 14'},
  {'Bag slot','/use 0 1'}, {'Mainhand','/use 16'}, {'Item ID','/use item:12345'},
  {'Equip item','/equip Item Name'}, {'Equip main','/equipslot 16 Item Name'},
  {'Equip set','/equipset Set Name'},
 }},
 {name='Pets',entries={
  {'Attack','/petattack [@target,harm,nodead]'}, {'Follow','/petfollow'},
  {'Stay','/petstay'}, {'Passive','/petpassive'}, {'Defensive','/petdefensive'},
  {'Assist','/petassist'}, {'Auto on','/petautocaston Pet Ability'},
  {'Auto off','/petautocastoff Pet Ability'}, {'Cast pet','/cast Pet Ability'},
 }},
 {name='Forms/ground',entries={
  {'Cursor ground','/cast [@cursor] Ground Spell'}, {'Ground at self','/cast [@player] Ground Spell'},
  {'Manual reticle','/cast [@none] Ground Spell'},
  {'Form 1 / 3','/cast [form:1] Bear Spell; [form:3] Cat Spell'},
  {'Travel conditional','/cast [swimming] Aquatic Form; [outdoors] Travel Form; Cat Form'},
  {'Alt / ctrl','/cast [mod:alt] Spell A; [mod:ctrl] Spell B; Spell C'},
 }},
 {name='Chat',entries={
  {'Say','/say Message'}, {'Party','/party Message'}, {'Raid','/raid Message'},
  {'Raid warning','/rw Message'}, {'Yell','/yell Message'},
  {'Whisper','/w CharacterName Message'}, {'Emote','/em cheers'},
  {'Focus announcement','/p Supporting %f'}, {'Target announce','/p Attacking %t'},
 }},
 {name='Advanced',entries={
  {'UI script','/run print("Macro executed")'}, {'Console','/console cvarName value'},
  {'Click (restricted)','/click ButtonName'}, {'Open addon','/kool'},
  {'Known (verify)','/cast [known:Spell A] Spell A; Spell B'},
  {'Spec (verify)','/cast [spec:1] Spell A; Spell B'},
 }},
}
local commandCategory,commandPage=1,1
local flagCategory,flagPage=1,1
local COMMANDS_PER_PAGE=12
local FLAGS_PER_PAGE=10
local function db()
  KoolSupportDB=KoolSupportDB or {}
  local d=KoolSupportDB
  d.owned=d.owned or {};d.generated=d.generated or {}
  d.customDrafts=d.customDrafts or {};d.customOrder=d.customOrder or {}
  return d
end
local function trim(s) return (s or ''):match('^%s*(.-)%s*$') end
-- The native WoW macro editor uses #showtooltip as a directive; never
-- insert cast/utility commands above it, even in hand-edited saved drafts.
local function normalizeTooltip(body)
  if type(body)~='string' then return body end
  body=body:gsub('\r\n','\n'):gsub('\r','\n')
  local first, lines=nil,{}
  for line in (body..'\n'):gmatch('(.-)\n') do
    local t=trim(line)
    if t=='#showtooltip' or t:match('^#showtooltip%s+') then
      if not first or (first=='#showtooltip' and t~='#showtooltip') then first=t end
    else
      lines[#lines+1]=line
    end
  end
  while #lines>0 and trim(lines[1])=='' do table.remove(lines,1) end
  return (first or '#showtooltip')..'\n'..table.concat(lines,'\n')
end
Studio.NormalizeTooltip=normalizeTooltip
local function combat() return InCombatLockdown and InCombatLockdown() end
local function setStatus(s)
  status=s
  if ui and ui.status then ui.status:SetText(s) end
end
local function safeSpell(s)
  s=trim(s)
  if #s<1 or #s>120 or s:find('[\r\n%[%]/;]') then return nil end
  return s
end
local function safeMacroName(s)
  s=trim(s)
  if #s<1 or #s>MAX_NAME or s:find('[^%w_%-]') or not s:match('^KSC%-') then return nil end
  return s
end
local function addSpell(list,seen,name,group,subName,spellID,flyout,future,passive)
  if not safeSpell(name) then return end
  local key=group..'\031'..name..'\031'..(subName or '')
  if seen[key] then return end
  seen[key]=true
  list[#list+1]={name=name,group=group,subName=subName or '',spellID=spellID,flyout=flyout or false, future=future or false, passive=passive or false}
end
-- Scans spellbook items rather than a static expansion-specific spell list.
-- Future spells and passives are not castable macro commands, so exclude them.
-- Flyout headings are shown as informational rows, not directly cast as spells.
function Studio.ScanSpellbook()
  spells={}
  if combat() then setStatus('Refresh spellbook outside combat.'); return false end
  local api=C_SpellBook
  if not api or type(api.GetNumSpellBookSkillLines)~='function' or type(api.GetSpellBookSkillLineInfo)~='function' or type(api.GetSpellBookItemInfo)~='function' then
    setStatus('C_SpellBook APIs unavailable; no spell data guessed.')
    return false
  end
  local bank=(Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
  local kinds=(Enum and Enum.SpellBookItemType) or {}
  local seen={}
  local okCount,count=pcall(api.GetNumSpellBookSkillLines)
  if not okCount or type(count)~='number' then setStatus('Could not read spellbook skill lines.'); return false end
  for i=1, math.min(count,60) do
    local ok,line=pcall(api.GetSpellBookSkillLineInfo,i)
    if ok and type(line)=='table' and not line.shouldHide then
      local group=line.name or 'General'
      local from=tonumber(line.itemIndexOffset) or 0
      local slots=math.min(tonumber(line.numSpellBookItems) or 0,500)
      for k=from+1,from+slots do
        local okItem,item=pcall(api.GetSpellBookItemInfo,k,bank)
        if okItem and type(item)=='table' then
          local kind=item.itemType
          local future=kind==(kinds.FutureSpell or 2)
          local flyout=kind==(kinds.Flyout or 4)
          local active=kind==(kinds.Spell or 1)
          local passive=item.isPassive
          if passive==nil and type(api.IsSpellBookItemPassive)=='function' then
            local okPassive,p=pcall(api.IsSpellBookItemPassive,k,bank)
            if okPassive then passive=p end
          end
          if active or future or flyout then
            local name=item.name
            local subName=item.subName
            if not name and type(api.GetSpellBookItemName)=='function' then
              local okName,n,s=pcall(api.GetSpellBookItemName,k,bank)
              if okName then name,subName=n,s end
            end
            if (not name or name=='') and item.spellID and C_Spell and C_Spell.GetSpellName then
              local okName,n=pcall(C_Spell.GetSpellName,item.spellID)
              if okName then name=n end
            end
            addSpell(spells,seen,name,group,subName,item.spellID or item.actionID,flyout,future,passive)
            -- Expand learned flyout children when Forever exposes the flyout APIs.
            if flyout and item.actionID and type(GetFlyoutInfo)=='function' and type(GetFlyoutSlotInfo)=='function' then
              local okFly,flyName,_,countFly=pcall(GetFlyoutInfo,item.actionID)
              if okFly and type(countFly)=='number' then
                for slot=1,math.min(countFly,40) do
                  local okSlot,childID,overrideID,isKnown,childName=pcall(GetFlyoutSlotInfo,item.actionID,slot)
                  if okSlot and isKnown then
                    local id=overrideID or childID
                    if (not childName or childName=='') and C_Spell and type(C_Spell.GetSpellName)=='function' and id then
                      local okChild,resolved=pcall(C_Spell.GetSpellName,id)
                      if okChild then childName=resolved end
                    end
                    addSpell(spells,seen,childName,group..' / '..(flyName or name or 'Flyout'),'',id,false,false,false)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  table.sort(spells,function(a,b)
    if a.group~=b.group then return a.group<b.group end
    if a.name~=b.name then return a.name<b.name end
    return a.subName<b.subName
  end)
  db().spellbookSnapshot=spells
  setStatus('Found '..#spells..' spellbook entries (passives/future and flyouts are read-only).')
  return true
end
function Studio.BuildCast(spell,unit,conditions)
  spell=safeSpell(spell)
  if not spell then return nil end
  local validUnit=false
  for _,v in ipairs(UNITS) do if v==unit then validUnit=true break end end
  if not validUnit then return nil end
  local mods={}
  if unit~='none' then mods[#mods+1]='@'..unit end
  for _,condition in ipairs(conditions or {}) do
    for _,f in ipairs(FLAGS) do if f==condition then mods[#mods+1]=f;break end end
  end
  return '/cast '..(#mods>0 and ('['..table.concat(mods,',')..'] ') or '')..spell
end
local function draftText() return draft.body or '' end
local function validate(name,body)
  name=safeMacroName(name)
  if not name then return false,'Custom name must start KSC- and use up to 16 bytes of letters, numbers, _ or -.' end
  if type(body)~='string' or #body==0 then return false,'Macro body is empty.' end
  if #body>MAX_BODY then return false,'Body is '..#body..' bytes (maximum 255).' end
  if body:find('%b[]') then
    for cond in body:gmatch('%b[]') do
      if cond:match('(%f[%w]help%f[%W])') and cond:match('(%f[%w]harm%f[%W])') then
        return false,'A clause cannot require both help and harm.'
      end
      if cond:match('(%f[%w]dead%f[%W])') and cond:match('(%f[%w]nodead%f[%W])') then
        return false,'A clause cannot require both dead and nodead.'
      end
    end
  end
  return true,nil
end
local function saveDraft()
  draft.body=normalizeTooltip(draftText())
  if ui and ui.body and ui.body:GetText()~=draft.body then ui.body:SetText(draft.body) end
  local name=safeMacroName(draft.name)
  local ok,why=validate(name,draftText())
  if not ok then setStatus(why);return false end
  local d=db()
  if not d.customDrafts[name] then
    if #d.customOrder>=50 then setStatus('Maximum 50 saved custom macros.');return false end
    d.customOrder[#d.customOrder+1]=name
  end
  d.customDrafts[name]={body=draftText(),spell=draft.spell,unit=draft.unit,conditions=draft.conditions}
  setStatus('Saved '..name..' to character SavedVariables. Not installed in /macro yet.')
  return true
end
function Studio.InstallCustom(name,body)
  if combat() then return false,'Native macro creation is blocked during combat.' end
  body=normalizeTooltip(body)
  local valid,why=validate(name,body)
  if not valid then return false,why end
  if type(CreateMacro)~='function' or type(EditMacro)~='function' or type(GetMacroIndexByName)~='function' or type(GetMacroBody)~='function' or type(GetNumMacros)~='function' then
    return false,'WoW macro APIs unavailable.'
  end
  local d=db()
  local idx=GetMacroIndexByName(name) or 0
  if idx>0 then
    if not d.owned[name] or not d.generated[name] or GetMacroBody(idx)~=d.generated[name] then
      return false,'Existing macro is unowned or manually edited; will not overwrite.'
    end
    local ok,result=pcall(EditMacro,idx,nil,nil,body)
    if not ok or result==nil then return false,'WoW rejected EditMacro.' end
  else
    local _,used=GetNumMacros()
    local cap=type(MAX_CHARACTER_MACROS)=='number' and MAX_CHARACTER_MACROS or 30
    if type(used)=='number' and used>=cap then return false,'No character-specific macro slots available.' end
    local ok,result=pcall(CreateMacro,name,'INV_Misc_QuestionMark',body,true)
    if not ok or type(result)~='number' or result<=0 then return false,'WoW rejected CreateMacro.' end
  end
  d.owned[name]=true;d.generated[name]=body
  return true,'Installed '..name..' in /macro > Character-Specific.'
end
local function button(parent,label,w,h,x,y,action)
  local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
  b:SetSize(w,h);b:SetPoint('TOPLEFT',x,y);b:SetText(label);b:SetScript('OnClick',action);return b
end
local function redAccent(widget)
  if not widget or not widget.GetNormalTexture then return end
  local normal=widget:GetNormalTexture()
  if normal and normal.SetVertexColor then normal:SetVertexColor(.72,.24,.19) end
end
local function label(parent,str,x,y,width,font)
  local f=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall')
  f:SetPoint('TOPLEFT',x,y);f:SetText(str);f:SetJustifyH('LEFT');if width then f:SetWidth(width) end;return f
end
local function input(parent,w,x,y,onCommit)
  local b=CreateFrame('EditBox',nil,parent,'InputBoxTemplate')
  b:SetSize(w,26);b:SetPoint('TOPLEFT',x,y);b:SetAutoFocus(false)
  b:SetScript('OnEnterPressed',function(self)onCommit(self:GetText());self:ClearFocus()end)
  b:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  return b
end
local function append(text)
  text=trim(text)
  if #text==0 or not ui then return end
  local existing=ui.body:GetText() or ''
  if text=='#showtooltip' or text:match('^#showtooltip%s+') then
    ui.body:SetText(normalizeTooltip(existing..'\n'..text))
  else
    local body=normalizeTooltip(existing)
    ui.body:SetText(normalizeTooltip(body..(body:sub(-1)=='\n' and '' or '\n')..text))
  end
end
local function refreshBody()
  if not ui then return end
  draft.body=ui.body:GetText() or ''
  local n=#draft.body
  if not ui.byteCount or not ui.save or not ui.install then return end
  ui.byteCount:SetText(n..' / 255 bytes'..(n>255 and '  |cffff7777OVER LIMIT|r' or ''))
  ui.save:SetEnabled(not combat() and validate(draft.name,draft.body))
  ui.install:SetEnabled(not combat() and validate(draft.name,draft.body))
end
local function updateUnit()
  if not ui then return end
  ui.unit:SetText('Target: '..draft.unit)
  ui.cond:SetText('Conditions: '..table.concat(draft.conditions,', '))
end
local function updateList()
  if not ui then return end
  filtered={}
  local query=trim(ui.search:GetText()):lower()
  for _,s in ipairs(spells) do
    if query=='' or (s.name..' '..s.group..' '..s.subName):lower():find(query,1,true) then filtered[#filtered+1]=s end
  end
  local maxPage=math.max(1,math.ceil(#filtered/PER_PAGE))
  spellPage=math.min(spellPage,maxPage)
  ui.page:SetText('Page '..spellPage..' / '..maxPage..'  ('..#filtered..' entries)')
  for i=1,PER_PAGE do
    local spell=filtered[(spellPage-1)*PER_PAGE+i]
    local b=ui.spellButtons[i]
    if spell then
      b:Show();b:SetText((spell.flyout and '[Flyout] ' or spell.passive and '[Passive] ' or spell.future and '[Future] ' or '')..spell.name..(spell.subName~='' and ' ('..spell.subName..')' or ''))
      b.spell=spell
    else b:Hide();b.spell=nil end
  end
end
local function refreshDrafts()
  if not ui then return end
  local order=db().customOrder
  local maxPage=math.max(1,math.ceil(#order/5))
  draftPage=math.min(draftPage,maxPage)
  ui.savedPage:SetText('Saved '..draftPage..'/'..maxPage)
  for i=1,5 do
    local name=order[(draftPage-1)*5+i]
    local b=ui.savedButtons[i]
    if name then b:Show();b:SetText(name);b.key=name else b:Hide();b.key=nil end
  end
end
local function showMode(tab)
  mode=tab
  if not ui then return end
  local spellMode=mode=='spellbook'
  for _,w in ipairs(ui.spellElements) do if spellMode then w:Show() else w:Hide() end end
  for _,w in ipairs(ui.builderElements) do if spellMode then w:Hide() else w:Show() end end
  ui.spellTab:SetEnabled(not spellMode)
  ui.builderTab:SetEnabled(spellMode)
  ui.modeTitle:SetText(spellMode and 'Full character spellbook (learned active abilities)' or 'Custom macro builder — click to assemble, edit freely')
end
function Studio.RefreshTools()
  if not ui then return end
  local c=COMMAND_CATEGORIES[commandCategory]
  local maxCommandPage=math.max(1,math.ceil(#c.entries/COMMANDS_PER_PAGE))
  commandPage=math.min(commandPage,maxCommandPage)
  ui.commandsTitle:SetText('Commands: '..c.name)
  ui.commandsPrevious:SetEnabled(commandPage>1)
  ui.commandsNext:SetEnabled(commandPage<maxCommandPage)
  for i,b in ipairs(ui.commandButtons or {}) do
    local entry=c.entries[(commandPage-1)*COMMANDS_PER_PAGE+i]
    if entry then b.command=entry;b:SetText(entry[1]);b:Show() else b.command=nil;b:Hide() end
  end
  local f=FLAG_CATEGORIES[flagCategory]
  local maxFlagPage=math.max(1,math.ceil(#f.items/FLAGS_PER_PAGE))
  flagPage=math.min(flagPage,maxFlagPage)
  ui.flagHeading:SetText('Conditions: '..f.name)
  ui.flagBack:SetEnabled(flagPage>1)
  ui.flagNext:SetEnabled(flagPage<maxFlagPage)
  for i,b in ipairs(ui.flagButtons or {}) do
    local flag=f.items[(flagPage-1)*FLAGS_PER_PAGE+i]
    if flag then
      b.flag=flag;b:SetText(flag);b:Show()
    else b.flag=nil;b:Hide() end
  end
end
local function createUI()
  if ui then return end
  ui={spellElements={},builderElements={}}
  local frame=CreateFrame('Frame','KoolSupportStudioPanel',UIParent,'BackdropTemplate')
  ui.frame=frame
  frame:SetSize(1130,805);frame:SetPoint('CENTER');frame:SetFrameStrata('DIALOG')
  if UIParent and UIParent.GetWidth and UIParent.GetHeight then
    local w,h=UIParent:GetWidth(),UIParent:GetHeight()
    if type(w)=='number' and type(h)=='number' and w>0 and h>0 then
      frame:SetScale(math.min(1,(w-28)/1130,(h-28)/805))
    end
  end
  frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag('LeftButton')
  frame:SetScript('OnDragStart',function(self)self:StartMoving()end)
  frame:SetScript('OnDragStop',function(self)self:StopMovingOrSizing()end)
  frame:SetClampedToScreen(true)
  frame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=16,edgeSize=24,insets={left=8,right=8,top=8,bottom=8}})
  frame:SetBackdropColor(.015,.065,.052,.97)
  table.insert(UISpecialFrames,'KoolSupportStudioPanel')
  label(frame,'|cffffd83fKoolSupport Studio|r |cffa9b9b4v0.6.2|r',20,-18,400,'GameFontNormalLarge')
  ui.spellTab=button(frame,'Full Spellbook',158,27,20,-55,function()showMode('spellbook')end)
  ui.builderTab=button(frame,'Custom Builder',158,27,181,-55,function()showMode('builder')end)
  button(frame,'Close',80,26,1020,-18,function()frame:Hide()end)
  ui.modeTitle=label(frame,'',365,-62,500,'GameFontHighlight')
  local function asSpell(w)ui.spellElements[#ui.spellElements+1]=w;return w end
  local function asBuilder(w)ui.builderElements[#ui.builderElements+1]=w;return w end
  asSpell(label(frame,'Search learned spells',20,-106))
  ui.search=asSpell(input(frame,300,29,-126,function()spellPage=1;updateList()end))
  ui.search:SetScript('OnTextChanged',function()spellPage=1;updateList()end)
  asSpell(button(frame,'Refresh spellbook',165,25,352,-128,function()Studio.ScanSpellbook();updateList()end))
  asSpell(label(frame,'General/class spells and ranks. Passive/future entries are read-only.',20,-167,780))
  ui.spellButtons={}
  for i=1,PER_PAGE do
    local b=asSpell(button(frame,'',435,32,20,-191-(i-1)*34,function(self)
      local spell=self.spell
      if not spell then return end
      if spell.flyout or spell.passive or spell.future then setStatus('This spellbook entry is not directly castable; select a learned active spell.');return end
      selectedSpell=spell.name
      draft.spell=spell.name
      if draft.name=='KSC-New' then draft.name='KSC-'..spell.name:gsub('[^%w]',''):sub(1,12) end
      ui.spellName:SetText(spell.name)
      ui.spellInput:SetText(spell.name)
      ui.macroName:SetText(draft.name)
      setStatus('Selected '..spell.name..'. Switch to Custom Builder to add a /cast line.')
    end))
    ui.spellButtons[i]=b
  end
  asSpell(button(frame,'< Prev',90,24,20,-580,function()spellPage=math.max(1,spellPage-1);updateList()end))
  ui.page=asSpell(label(frame,'Page 1/1',160,-585,210))
  asSpell(button(frame,'Next >',90,24,355,-580,function()spellPage=spellPage+1;updateList()end))
  asSpell(label(frame,'Select a spell to use it in the Custom Builder.',493,-205,385,'GameFontNormal'))
  ui.spellName=asSpell(label(frame,'(none)',493,-236,410,'GameFontHighlight'))
  asSpell(button(frame,'Open Builder with Selected Spell',395,28,493,-273,function()showMode('builder')end))
  asSpell(label(frame,'The real addon reads all learned active spellbook entries.',493,-327,410))
  asSpell(label(frame,'Flyouts are shown as headers, not direct /cast commands.',493,-347,410))
  asSpell(label(frame,'Spell ranks are shown for reference; casting an exact',493,-367,410))
  asSpell(label(frame,'rank in Forever requires in-game verification.',493,-387,410))
  -- Custom builder view
  asBuilder(label(frame,'Macro name (up to 16 bytes)',20,-106))
  ui.macroName=asBuilder(input(frame,245,29,-126,function(text)draft.name=trim(text);refreshBody()end))
  ui.macroName:SetScript('OnTextChanged',function(self)draft.name=trim(self:GetText());refreshBody()end)
  asBuilder(label(frame,'Spell name (from spellbook or type manually)',302,-106))
  ui.spellInput=asBuilder(input(frame,290,313,-126,function(text)draft.spell=text;setStatus('Spell updated.')end))
  ui.spellInput:SetScript('OnTextChanged',function(self)draft.spell=trim(self:GetText())end)
  ui.unit=asBuilder(button(frame,'Target: focus',190,25,20,-172,function()
    local found=1
    for i,s in ipairs(UNITS) do if s==draft.unit then found=i;break end end
    draft.unit=UNITS[found%#UNITS+1];updateUnit()
  end))
  ui.cond=asBuilder(button(frame,'Conditions',300,25,224,-172,function()
    -- Individual flags are toggled by chips below; this is a summary only.
    setStatus('Toggle individual friendly/hostile/other flags below.')
  end))
  ui.flagHeading=asBuilder(button(frame,'Conditions: Common',220,24,20,-199,function()
    flagCategory=flagCategory%#FLAG_CATEGORIES+1;flagPage=1
    Studio.RefreshTools()
  end))
  ui.flagBack=asBuilder(button(frame,'<',28,24,246,-199,function()
    flagPage=math.max(1,flagPage-1);Studio.RefreshTools()
  end))
  ui.flagNext=asBuilder(button(frame,'>',28,24,280,-199,function()
    flagPage=flagPage+1;Studio.RefreshTools()
  end))
  ui.flagButtons={}
  for i=1,FLAGS_PER_PAGE do
    local row,col=math.floor((i-1)/5),(i-1)%5
    local b=asBuilder(button(frame,'',100,24,20+col*107,-229-row*30,function(self)
      local flag=self.flag
      if not flag then return end
      local found=nil
      for j,v in ipairs(draft.conditions) do if v==flag then found=j;break end end
      if found then table.remove(draft.conditions,found) else draft.conditions[#draft.conditions+1]=flag end
      updateUnit();Studio.RefreshTools()
    end))
    ui.flagButtons[i]=b
  end
  local QUICK_UNITS={{'@focus','focus'},{'@focustarget','focustarget'},{'@player','player'},{'@target','target'},{'@mouseover','mouseover'},{'No unit','none'}}
  for i,entry in ipairs(QUICK_UNITS) do
    local row,col=math.floor((i-1)/2),(i-1)%2
    asBuilder(button(frame,entry[1],150,25,582+col*157,-360-row*29,function()
      draft.unit=entry[2]
      local other={}
      for _,v in ipairs(draft.conditions) do if v~='help' and v~='harm' then other[#other+1]=v end end
      if draft.unit=='focustarget' then other[#other+1]='harm'
      elseif draft.unit=='focus' or draft.unit=='player' then other[#other+1]='help' end
      draft.conditions=other;updateUnit()
    end))
  end
  asBuilder(button(frame,'+ Insert /cast spell',215,25,20,-294,function()
    local line=Studio.BuildCast(ui.spellInput:GetText(),draft.unit,draft.conditions)
    if not line then setStatus('Enter a valid spell and unit.');return end
    append(line)
  end))
  asBuilder(button(frame,'New blank draft',170,25,244,-294,function()
    draft={name='KSC-New',spell='',unit='focus',conditions={'help','nodead'},body='#showtooltip\n'}
    ui.macroName:SetText(draft.name);ui.spellInput:SetText('');ui.body:SetText(draft.body);updateUnit()
  end))
  local scroll=asBuilder(CreateFrame('ScrollFrame',nil,frame,'UIPanelScrollFrameTemplate'))
  scroll:SetPoint('TOPLEFT',28,-337);scroll:SetSize(525,180)
  ui.body=CreateFrame('EditBox',nil,scroll)
  ui.body:SetMultiLine(true);ui.body:SetAutoFocus(false);ui.body:SetFontObject('ChatFontNormal')
  ui.body:SetWidth(503);ui.body:SetHeight(180)
  ui.body:SetTextInsets(5,5,5,5)
  ui.body:SetScript('OnTextChanged',function()refreshBody()end)
  ui.body:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
  ui.body:SetScript('OnEditFocusLost',function(self)
    local fixed=normalizeTooltip(self:GetText())
    if fixed~=self:GetText() then self:SetText(fixed) end
  end)
  scroll:SetScrollChild(ui.body)
  ui.body:SetText(draft.body)
  asBuilder(label(frame,'Manual macro script (editable):',20,-316,390,'GameFontNormal'))
  ui.byteCount=asBuilder(label(frame,'0 / 255 bytes',400,-315,160))
  ui.commandsTitle=asBuilder(button(frame,'Commands: Casting',205,26,582,-100,function()
    commandCategory=commandCategory%#COMMAND_CATEGORIES+1;commandPage=1
    Studio.RefreshTools()
  end))
  ui.commandsPrevious=asBuilder(button(frame,'<',45,25,792,-100,function()
    commandPage=math.max(1,commandPage-1);Studio.RefreshTools()
  end))
  ui.commandsNext=asBuilder(button(frame,'>',45,25,843,-100,function()
    commandPage=commandPage+1;Studio.RefreshTools()
  end))
  ui.commandButtons={}
  for i=1,COMMANDS_PER_PAGE do
    local row,col=math.floor((i-1)/2),(i-1)%2
    local b=asBuilder(button(frame,'',152,25,582+col*157,-132-row*31,function(self)
      local entry=self.command
      if entry then append(type(entry[2])=='function' and entry[2]() or entry[2]) end
    end))
    ui.commandButtons[i]=b
  end
  ui.save=asBuilder(button(frame,'Save draft',132,28,20,-551,function()saveDraft();refreshDrafts()end))
  ui.install=asBuilder(button(frame,'Create / Update in WoW',195,28,164,-551,function()
    local ok,msg=Studio.InstallCustom(ui.macroName:GetText(),ui.body:GetText())
    if ok then saveDraft();refreshDrafts() end
    setStatus(msg)
  end))
  redAccent(ui.save);redAccent(ui.install)
  asBuilder(label(frame,'Saved drafts (character-specific)',20,-593,320,'GameFontNormal'))
  ui.savedButtons={}
  for i=1,5 do
    local b=asBuilder(button(frame,'',144,25,20+(i-1)*148,-613,function(self)
      if not self.key then return end
      local s=db().customDrafts[self.key]
      if not s then return end
      draft={name=self.key,body=s.body,spell=s.spell or '',unit=s.unit or 'focus',conditions=s.conditions or {}}
      ui.macroName:SetText(draft.name);ui.spellInput:SetText(draft.spell);ui.body:SetText(draft.body);updateUnit();setStatus('Loaded saved draft '..self.key)
    end))
    ui.savedButtons[i]=b
  end
  ui.savedPage=asBuilder(label(frame,'Saved 1/1',20,-652,120))
  asBuilder(button(frame,'< Saved',100,25,149,-648,function()draftPage=math.max(1,draftPage-1);refreshDrafts()end))
  asBuilder(button(frame,'Saved >',100,25,263,-648,function()draftPage=draftPage+1;refreshDrafts()end))
  ui.status=label(frame,status,20,-687,895)
  frame:SetScript('OnShow',function()
    if #spells==0 then Studio.ScanSpellbook() end
    ui.macroName:SetText(draft.name);ui.spellInput:SetText(draft.spell)
    ui.body:SetText(draft.body);updateList();refreshDrafts();updateUnit();refreshBody();Studio.RefreshTools();showMode(mode)
  end)
  frame:Hide()
end
function Studio.Open(tab)
  if combat() then setStatus('Open the macro builder outside combat.');return false end
  createUI()
  ui.frame:Show()
  if tab=='spellbook' or tab=='builder' then showMode(tab) end
  return true
end
-- Spellbook data becomes available after the client fires SPELLS_CHANGED.
local events=CreateFrame('Frame')
events:RegisterEvent('SPELLS_CHANGED')
events:SetScript('OnEvent',function() if ui and ui.frame and ui.frame:IsShown() and not combat() then Studio.ScanSpellbook();updateList() end end)
