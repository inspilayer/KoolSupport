-- Read the actual player's spellbook. No expansion-specific guessed spells.
local M=KSMacros
local function validName(name)
  return type(name)=="string" and #name>0 and #name<120 and not name:find("[\r\n%[%]/;]")
end

function M:ScanSpellbook()
  if KoolSupport:IsInCombat() then return nil,"Refresh the spellbook outside combat" end
  local a=C_SpellBook
  if not a or type(a.GetNumSpellBookSkillLines)~="function" or type(a.GetSpellBookSkillLineInfo)~="function" or type(a.GetSpellBookItemInfo)~="function" then
    return nil,"The Forever spellbook APIs are unavailable"
  end
  local bank=(Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
  local kinds=(Enum and Enum.SpellBookItemType) or {}
  local ok,count=pcall(a.GetNumSpellBookSkillLines)
  if not ok or type(count)~="number" then return nil,"Unable to read spellbook skill lines" end
  local result,seen={},{}
  for i=1,math.min(count,60) do
    local good,line=pcall(a.GetSpellBookSkillLineInfo,i)
    if good and type(line)=="table" and not line.shouldHide then
      local start=tonumber(line.itemIndexOffset) or 0
      local len=math.min(tonumber(line.numSpellBookItems) or 0,500)
      for slot=start+1,start+len do
        local works,info=pcall(a.GetSpellBookItemInfo,slot,bank)
        if works and type(info)=="table" then
          local kind=info.itemType
          local active=(kind==kinds.Spell or kind==1 or kind=="SPELL")
          local passive=info.isPassive
          if passive==nil and type(a.IsSpellBookItemPassive)=="function" then
            local pOk,p=pcall(a.IsSpellBookItemPassive,slot,bank)
            if pOk then passive=p end
          end
          if active and not passive then
            local name=info.name
            if not name and type(a.GetSpellBookItemName)=="function" then
              local nOk,n=pcall(a.GetSpellBookItemName,slot,bank)
              if nOk then name=n end
            end
            if not name and info.spellID and C_Spell and type(C_Spell.GetSpellName)=="function" then
              local nOk,n=pcall(C_Spell.GetSpellName,info.spellID)
              if nOk then name=n end
            end
            if validName(name) and not seen[name] then
              seen[name]=true
              result[#result+1]={name=name,group=line.name or "General",spellID=info.spellID}
            end
          end
        end
      end
    end
  end
  table.sort(result,function(a,b)
    if a.group~=b.group then return a.group<b.group end
    return a.name<b.name
  end)
  self.spellbook=result
  return result
end

function M.BuildSpellbook(parent)
  local function lbl(text,x,y,w,style)
    local t=parent:CreateFontString(nil,"OVERLAY",style or "GameFontNormal")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT");t:SetText(text);return t
  end
  local function btn(text,x,y,w,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w or 140,29);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetText(text);b:SetScript("OnClick",callback);return b
  end
  lbl("|cffffd87aFull Spellbook|r",20,-18,740,"GameFontNormalLarge")
  lbl("Learned active spells only. Select a spell to start a generic macro draft.",20,-55,750)
  local search=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
  search:SetSize(230,26);search:SetPoint("TOPLEFT",parent,"TOPLEFT",20,-91);search:SetAutoFocus(false)
  local status=lbl("",20,-510,750)
  local page,filtered=1,{}
  local rows={}
  local perPage=11
  local function filter()
    filtered={}
    local needle=(search:GetText() or ""):lower()
    for _,entry in ipairs(M.spellbook or {}) do
      if needle=="" or entry.name:lower():find(needle,1,true) or entry.group:lower():find(needle,1,true) then
        filtered[#filtered+1]=entry
      end
    end
    page=1
  end
  local render
  render=function()
    for i,b in ipairs(rows) do
      local entry=filtered[(page-1)*perPage+i]
      b:SetShown(entry~=nil)
      if entry then
        b:SetText(entry.name.."  ("..entry.group..")")
        b:SetScript("OnClick",function()
          local store=M:Store()
          store.selectedSpell=entry.name
          KoolSupport:ShowPage("macro_workshop")
        end)
        b:SetScript("OnEnter",function(self)
          if GameTooltip and entry.spellID then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            if type(GameTooltip.SetSpellByID)=="function" then GameTooltip:SetSpellByID(entry.spellID) end
            GameTooltip:Show()
          end
        end)
        b:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide() end end)
      end
    end
    status:SetText(#filtered.." learned spells | Page "..page.." / "..math.max(1,math.ceil(#filtered/perPage)))
  end
  for i=1,perPage do rows[i]=btn("",20,-155-(i-1)*29,750,function()end) end
  btn("Refresh from client",275,-90,190,function()
    local list,why=M:ScanSpellbook()
    if not list then status:SetText(why);return end
    filter();render()
  end)
  btn("Search",480,-90,105,function()filter();render()end)
  btn("Previous",20,-550,140,function()page=math.max(1,page-1);render()end)
  btn("Next",170,-550,140,function()page=math.min(math.max(1,math.ceil(#filtered/perPage)),page+1);render()end)
  local list,why=M:ScanSpellbook()
  if not list then status:SetText(why) else filter();render() end
end
