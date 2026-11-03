-- Generic Custom Builder with grouped native command snippets.
local M=KSMacros
local CATEGORY={
 {"Cast and targeting",{
  {"Cast spell","/cast Spell Name"},{"Mouseover heal","/cast [@mouseover,help,nodead] Spell Name"},
  {"Focus heal","/cast [@focus,help,nodead] Spell Name"},{"Focus enemy","/cast [@focustarget,harm,nodead] Spell Name"},
  {"Self cast","/cast [@player] Spell Name"},{"Target cast","/cast [@target] Spell Name"},
  {"Help/harm","/cast [help,nodead] Friendly Spell; [harm,nodead] Harmful Spell"},
  {"Cast sequence","/castsequence reset=target Spell One, Spell Two"},
  {"Modifier","/cast [mod:shift] Spell A; Spell B"},
  {"Show tooltip","#showtooltip Spell Name"},
 }},
 {"Target controls",{
  {"Set focus","/focus [@target,exists]"},{"Focus by name","/focus CharacterName"},
  {"Clear focus","/clearfocus"},{"Follow focus","/follow focus"},{"Assist focus","/assist focus"},
  {"Exact target","/targetexact CharacterName"},{"Last target","/targetlasttarget"},
  {"Next enemy","/targetenemy"},{"Next friend","/targetfriend"},{"Clear target","/cleartarget"},
 }},
 {"Combat and forms",{
  {"Stop casting","/stopcasting"},{"Stop macro","/stopmacro [@focus,noexists]"},
  {"Start attack","/startattack [harm,nodead]"},{"Stop attack","/stopattack"},
  {"Cancel form","/cancelform [form]"},{"Cancel aura","/cancelaura Aura Name"},
  {"Dismount","/dismount"},{"Keep form","/cast !Toggle Spell"},
  {"Bear/Cat","/cast [form:1] Bear Spell; [form:3] Cat Spell"},
 }},
 {"Items and pets",{
  {"Use item","/use Item Name"},{"Trinket 1","/use 13"},{"Trinket 2","/use 14"},
  {"Equip","/equip Item Name"},{"Equip slot","/equipslot 16 Item Name"},
  {"Pet attack","/petattack [@target,harm,nodead]"},{"Pet follow","/petfollow"},
  {"Pet passive","/petpassive"},{"Pet assist","/petassist"},
 }},
 {"Modifiers, ground and chat",{
  {"At cursor","/cast [@cursor] Ground Spell"},{"At player","/cast [@player] Ground Spell"},
  {"Alt/Ctrl","/cast [mod:alt] Spell A; [mod:ctrl] Spell B; Spell C"},
  {"Target fallback","/cast [@mouseover,help,nodead][@focus,help,nodead][@player] Spell Name"},
  {"Party message","/p Message"},{"Raid message","/raid Message"},
  {"Emote","/em cheers"},{"UI script (advanced)","/run print('Macro executed')"},
 }},
}
M.builderCategories=CATEGORY
local function label(parent,text,x,y,w)
  local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w or 400);t:SetJustifyH("LEFT");t:SetText(text);return t
end
local function button(parent,text,x,y,w,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,30);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetText(text);b:SetScript("OnClick",fn);return b
end
local function field(parent,x,y,w,initial,multi,height)
  local f=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
  f:SetSize(w,height or 27);f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  f:SetAutoFocus(false);f:SetText(initial or "")
  if multi then f:SetMultiLine(true);f:SetTextInsets(9,9,9,9) end
  return f
end

function M.BuildWorkshop(parent)
  label(parent,"|cffffd87aCustom Builder|r",20,-15,730)
  label(parent,"Macro name",20,-53,180)
  local name=field(parent,20,-75,184,"KSM-New")
  label(parent,"Spell (from Full Spellbook or manual)",219,-53,360)
  local spell=field(parent,219,-75,298,M:Store().selectedSpell or "")
  local body=field(parent,20,-245,766,"#showtooltip\n",true,175)
  local status=label(parent,"Draft only. Installation is always a deliberate click outside combat.",20,-557,770)
  local category=1
  local rowButtons={}
  local title=label(parent,"",20,-115,700)
  local function append(snippet)
    local selected=spell:GetText() or ""
    if selected~="" then snippet=snippet:gsub("Spell Name",selected) end
    body:SetText(M:NormalizeTooltip(body:GetText().."\n"..snippet))
  end
  local function render()
    local group=CATEGORY[category]
    title:SetText(group[1].."  ("..category.."/"..#CATEGORY..")")
    for i,item in ipairs(rowButtons) do
      local command=group[2][i]
      item:SetShown(command~=nil)
      if command then
        item:SetText(command[1])
        item:SetScript("OnClick",function()append(command[2])end)
      end
    end
  end
  for i=1,10 do
    local col=(i-1)%5
    local row=math.floor((i-1)/5)
    rowButtons[i]=button(parent,"",20+col*154,-142-row*39,146,function()end)
  end
  button(parent,"< Category",552,-99,105,function()category=(category-2)%#CATEGORY+1;render()end)
  button(parent,"Category >",665,-99,105,function()category=category%#CATEGORY+1;render()end)
  label(parent,"255-byte native macro limit. #showtooltip is normalized to line 1.",20,-222,745)
  button(parent,"Save Draft",20,-460,130,function()
    local ok,why=M:SaveDraft(name:GetText(),body:GetText())
    status:SetText(ok and "Saved per character. Open Macro Suite to include it." or why)
  end)
  button(parent,"Create / Update",161,-460,155,function()
    local ok,why=M:Install(name:GetText(),body:GetText())
    status:SetText(ok and "Native macro created/updated. Drag it from /macro." or why)
  end)
  button(parent,"New Draft",327,-460,115,function()
    name:SetText("KSM-New");spell:SetText("");body:SetText("#showtooltip\n");status:SetText("New draft")
  end)
  local data=M:Store()
  local draftIndex=1
  local function openDraft()
    local key=data.draftOrder[draftIndex]
    if key and data.drafts[key] then
      name:SetText(key);body:SetText(data.drafts[key]);status:SetText("Loaded "..key)
    else status:SetText("No saved drafts") end
  end
  button(parent,"Prev draft",456,-460,129,function()draftIndex=math.max(1,draftIndex-1);openDraft()end)
  button(parent,"Next draft",595,-460,129,function()draftIndex=math.min(#data.draftOrder,draftIndex+1);openDraft()end)
  render()
end
