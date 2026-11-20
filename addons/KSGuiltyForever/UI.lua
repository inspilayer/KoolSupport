-- Guilty Forever: native WoW grudge ledger. Presentation only; core owns persistence.
local A=KSGuiltyForever
local C={
 gold={0.94,0.76,0.40}, pale={0.87,0.90,0.87}, muted={0.60,0.67,0.67},
 red={0.88,0.32,0.30}, violet={0.66,0.47,0.90}, teal={0.27,0.75,0.66},
 dark={0.065,0.083,0.10,0.98}, panel={0.105,0.125,0.15,0.96},
 inset={0.035,0.048,0.065,0.92}, line={0.31,0.29,0.24,0.8},
}
local function color(widget,c)
 widget:SetTextColor(c[1],c[2],c[3])
end
local function text(parent,words,x,y,width,size,c)
 local t=parent:CreateFontString(nil,"OVERLAY",size or "GameFontHighlight")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 t:SetWidth(width)
 t:SetJustifyH("LEFT")
 t:SetText(words)
 if c then color(t,c) end
 return t
end
local function panel(parent,x,y,w,h,bg,edge)
 local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 f:SetSize(w,h)
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 if f.SetBackdrop then
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
   edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,
   insets={left=1,right=1,top=1,bottom=1}})
  local p=bg or C.panel
  f:SetBackdropColor(p[1],p[2],p[3],p[4] or 1)
  local e=edge or C.line
  f:SetBackdropBorderColor(e[1],e[2],e[3],e[4] or 1)
 end
 return f
end
local function rule(parent,x,y,w,c)
 local r=parent:CreateTexture(nil,"ARTWORK")
 r:SetColorTexture((c or C.line)[1],(c or C.line)[2],(c or C.line)[3],0.8)
 r:SetSize(w,1)
 r:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 return r
end
local function button(parent,title,x,y,w,action,accent)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,29)
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetText(title)
 b:SetScript("OnClick",action)
 if accent then
  local mark=b:CreateTexture(nil,"OVERLAY")
  mark:SetColorTexture(accent[1],accent[2],accent[3],0.95)
  mark:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",8,3)
  mark:SetSize(w-16,2)
 end
 return b
end
local function edit(parent,x,y,w,h,multiline)
 local frame=panel(parent,x,y,w,h,C.inset)
 local box=CreateFrame("EditBox",nil,frame)
 box:SetPoint("TOPLEFT",frame,"TOPLEFT",10,-8)
 box:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-10,7)
 box:SetAutoFocus(false)
 box:SetFontObject("ChatFontNormal")
 box:SetTextColor(0.92,0.91,0.86)
 box:SetMaxLetters(multiline and 500 or 100)
 box:SetMultiLine(multiline or false)
 if multiline then
  box:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
 else
  box:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
  box:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
 end
 return box
end
local function entries()
 local result={}
 for _,e in pairs(A:Store().notes) do
  if type(e)=="table" and type(e.name)=="string" and type(e.reason)=="string" then
   result[#result+1]=e
  end
 end
 table.sort(result,function(a,b)
  local at=tonumber(a.created) or 0
  local bt=tonumber(b.created) or 0
  if at~=bt then return at>bt end
  return a.name:lower()<b.name:lower()
 end)
 return result
end
local function isEnemy(e)return e.kind=="enemy"end
function A:PrepareEditor(name,kind)
 if not A:Key(name) then return false end
 A.editorPrefill={name=name,kind=kind=="enemy" and "enemy" or "ignore"}
 return true
end

function A.BuildPage(parent)
 -- All dimensions fit the 824x605 KoolSupport content panel.
 local state={filter="all",query="",page=1,selected=nil,kind="ignore",dirty=false}
 local bg=panel(parent,8,-8,804,588,C.dark,{0.38,0.30,0.20,0.95})
 local sigil=bg:CreateTexture(nil,"ARTWORK")
 sigil:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")
 sigil:SetSize(41,41)
 sigil:SetPoint("TOPLEFT",bg,"TOPLEFT",15,-13)
 sigil:SetAlpha(0.86)
 text(bg,"GUILTY FOREVER",69,-14,450,"GameFontNormalLarge",C.gold)
 text(bg,"THE GRUDGE LEDGER  /  REMEMBER FOREVER",69,-39,550,"GameFontHighlightSmall",C.muted)
 local count=text(bg,"",612,-22,168,"GameFontNormal",C.gold)
 rule(bg,14,-68,776,C.line)
 local left=panel(bg,14,-80,328,491,C.panel)
 local right=panel(bg,354,-80,436,491,C.panel)
 text(left,"THE ARCHIVE",13,-12,230,"GameFontNormal",C.gold)
 local leftDesc=text(left,"",13,-37,295,"GameFontHighlightSmall",C.muted)
 rule(left,12,-59,304)
 local search=edit(left,13,-70,302,33,false)
 search:SetText("")
 local filterButtons={}
 local filtered={}
 local rowButtons={}
 local selectedTint=C.gold
 local player=edit(right,15,-96,395,34,false)
 local note=edit(right,15,-174,395,119,true)
 local headline=text(right,"NEW ENTRY",15,-16,385,"GameFontNormalLarge",C.gold)
 local kindLabel=text(right,"",15,-47,395,"GameFontHighlightSmall",C.muted)
 local setKind
 text(right,"PLAYER NAME",15,-76,385,"GameFontHighlightSmall",C.muted)
 text(right,"REASON FOR RECORD",15,-153,385,"GameFontHighlightSmall",C.muted)
 local stateLine=text(right,"",15,-318,398,"GameFontHighlightSmall",C.muted)
 local footer=text(right,"",15,-350,400,"GameFontHighlightSmall",C.muted)
 local rows={}
 for i=1,7 do
  local y=-148-(i-1)*43
  local b=CreateFrame("Button",nil,left,"BackdropTemplate")
  b:SetSize(302,39)
  b:SetPoint("TOPLEFT",left,"TOPLEFT",13,y)
  if b.SetBackdrop then
   b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
    edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  end
  b.name=text(b,"",9,-5,207,"GameFontNormal",C.pale)
  b.note=text(b,"",9,-22,266,"GameFontHighlightSmall",C.muted)
  b.kind=text(b,"",214,-7,80,"GameFontHighlightSmall",C.violet)
  rowButtons[i]=b
 end
 local function highlight(b,active)
  if not b.SetBackdropColor then return end
  if active then b:SetBackdropColor(0.24,0.20,0.15,0.97)
  else b:SetBackdropColor(0.085,0.10,0.12,0.95) end
  if b.SetBackdropBorderColor then
   if active then b:SetBackdropBorderColor(0.78,0.61,0.34,0.95)
   else b:SetBackdropBorderColor(0.19,0.23,0.25,0.85) end
  end
 end
 local function totals()
  local all,ignore,enemy=0,0,0
  for _,e in ipairs(entries()) do
   all=all+1
   if isEnemy(e) then enemy=enemy+1 else ignore=ignore+1 end
  end
  count:SetText(all.." RECORDS")
  leftDesc:SetText(ignore.." ignored  |  "..enemy.." enemy tags")
  return all
 end
 local function showEntry(e)
  state.selected=e and A:Key(e.name) or nil
  if e then
   player:SetText(e.name)
   note:SetText(e.reason)
   state.kind=isEnemy(e) and "enemy" or "ignore"
   headline:SetText("EDIT RECORD")
   kindLabel:SetText(isEnemy(e) and "ENEMY FACTION  -  PRIVATE TAG" or "IGNORED PLAYER  -  PRIVATE NOTE")
  else
   player:SetText("")
   note:SetText("")
   state.kind="ignore"
   headline:SetText("NEW ENTRY")
   kindLabel:SetText("Choose a category and record your reason.")
  end
  stateLine:SetText("")
  state.dirty=false
  if setKind then setKind(state.kind) end
 end
 local function refresh()
  totals()
  filtered={}
  local q=state.query:lower()
  for _,e in ipairs(entries()) do
   if (state.filter=="all" or (state.filter=="enemy" and isEnemy(e))
    or (state.filter=="ignore" and not isEnemy(e))) and
    (q=="" or e.name:lower():find(q,1,true) or e.reason:lower():find(q,1,true)) then
    filtered[#filtered+1]=e
   end
  end
  local pages=math.max(1,math.ceil(#filtered/7))
  if state.page>pages then state.page=pages end
  for i,b in ipairs(rowButtons) do
   local e=filtered[(state.page-1)*7+i]
   b.entry=e
   if e then
    b.name:SetText(e.name)
    b.kind:SetText(isEnemy(e) and "ENEMY" or "IGNORE")
    color(b.kind,isEnemy(e) and C.violet or C.red)
    b.note:SetText(e.reason:gsub("[\r\n]"," "):sub(1,46))
    highlight(b,state.selected==A:Key(e.name))
    b:Show()
   else b:Hide() end
  end
  footer:SetText(#filtered.." matching records  |  Page "..state.page.." of "..pages)
  for key,b in pairs(filterButtons) do
   if b.SetText then b:SetText((state.filter==key and "[ "..key:upper().." ]" or key:upper())) end
  end
 end
 for i,b in ipairs(rowButtons) do
  b:SetScript("OnClick",function()
   if b.entry then showEntry(b.entry);refresh() end
  end)
  b:SetScript("OnEnter",function(self)
   if self.entry and state.selected~=A:Key(self.entry.name) then highlight(self,true) end
  end)
  b:SetScript("OnLeave",function(self)
   if self.entry then highlight(self,state.selected==A:Key(self.entry.name)) end
  end)
 end
 local filters={{"all",13},{"ignore",114},{"enemy",215}}
 for _,item in ipairs(filters) do
  local k=item[1]
  filterButtons[k]=button(left,k:upper(),item[2],-110,96,function()
   state.filter=k;state.page=1;refresh()
  end,k=="enemy" and C.violet or k=="ignore" and C.red or C.gold)
 end
 search:SetScript("OnTextChanged",function(self)
  state.query=self:GetText() or ""
  state.page=1
  refresh()
 end)
 button(left,"< PREV",13,-455,101,function()
  state.page=math.max(1,state.page-1);refresh()
 end)
 button(left,"NEXT >",214,-455,101,function()
  if state.page*7<#filtered then state.page=state.page+1 end
  refresh()
 end)
 local function selectTarget()
  if not (UnitExists and UnitName) then return end
  local ok,exists=pcall(UnitExists,"target")
  if not ok or exists~=true then stateLine:SetText("Target a player first.");return end
  local n,r=UnitName("target")
  if type(n)~="string" then stateLine:SetText("Couldn't read target name.");return end
  local full=(type(r)=="string" and r~="") and (n.."-"..r) or n
  player:SetText(full)
  local old=A:Get(full)
  if old then showEntry(old) else state.selected=nil end
  stateLine:SetText("Target selected: "..full)
  refresh()
 end
 local ignoreKind=button(right,"IGNORED PLAYER",15,-298,188,function()
  state.kind="ignore";setKind(state.kind)
 end,C.red)
 local enemyKind=button(right,"ENEMY FACTION",222,-298,197,function()
  state.kind="enemy";setKind(state.kind)
 end,C.violet)
 setKind=function(kind)
  ignoreKind:SetText(kind=="ignore" and "[ IGNORED PLAYER ]" or "IGNORED PLAYER")
  enemyKind:SetText(kind=="enemy" and "[ ENEMY FACTION ]" or "ENEMY FACTION")
  kindLabel:SetText(kind=="enemy" and "ENEMY FACTION  -  PRIVATE TAG" or "IGNORED PLAYER  -  PRIVATE NOTE")
 end
 button(right,"NEW RECORD",15,-372,127,function()showEntry(nil);refresh()end,C.gold)
 button(right,"USE TARGET",155,-372,127,selectTarget,C.teal)
 button(right,"TAG ENEMY",296,-372,123,function()
  local ok,result=A:TagEnemyTarget(note:GetText())
  if ok then
   showEntry(A:Get(result));state.filter="all";state.page=1;refresh()
   stateLine:SetText("Enemy tagged: "..result)
  else stateLine:SetText(result or "Select an enemy player.") end
 end,C.violet)
 button(right,"SAVE NOTE",15,-411,190,function()
  local currentName=player:GetText()
  local oldKey=state.selected
  if oldKey and oldKey~=A:Key(currentName) then
   stateLine:SetText("Name changed. Create a NEW record instead of renaming.")
   return
  end
  if A:Save(currentName,note:GetText(),state.kind) then
   showEntry(A:Get(currentName));refresh()
   stateLine:SetText("Saved. The grudge has been recorded.")
  else stateLine:SetText("Enter a player name and a reason.") end
 end,C.teal)
 button(right,"DELETE NOTE",220,-411,199,function()
  if not state.selected then stateLine:SetText("Select a record to delete.");return end
  if A:Delete(state.selected) then
   showEntry(nil);refresh()
   stateLine:SetText("Record deleted.")
  end
 end,C.red)
 text(bg,"Private and saved per character. No messages, ignores, attacks or party actions are sent automatically.",
  16,-579,770,"GameFontHighlightSmall",C.muted)
 showEntry(nil)
 if A.editorPrefill then
  local prefill=A.editorPrefill
  A.editorPrefill=nil
  local existing=A:Get(prefill.name)
  if existing then showEntry(existing)
  else
   player:SetText(prefill.name)
   state.kind=prefill.kind
   setKind(state.kind)
  end
  stateLine:SetText("Enter a reason, then SAVE NOTE.")
  player:SetFocus()
 end
 refresh()
end
