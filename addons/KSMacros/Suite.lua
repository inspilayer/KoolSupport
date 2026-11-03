-- Class-aware Macro Suite; generic templates remain available for every class.
-- Supportee / focus healing and following remain exclusive to KSSupportSessions.
local M=KSMacros
M.genericTemplates={
  {id="KS-Assist",title="Assist focus",group="Targeting",body="#showtooltip\n/assist [@focus,exists]"},
  {id="KS-Follow",title="Follow focus",group="Targeting",body="#showtooltip\n/follow focus"},
  {id="KS-Stop",title="Stop casting",group="Actions",body="#showtooltip\n/stopcasting"},
  {id="KS-Atk",title="Start attacking",group="Actions",body="#showtooltip\n/startattack [harm,nodead]"},
  {id="KS-Cancel",title="Cancel current form",group="Forms",body="#showtooltip\n/cancelform [form]"},
  {id="KS-Target",title="Target last enemy",group="Targeting",body="#showtooltip\n/targetlastenemy"},
  {id="KS-Focus",title="Focus current target",group="Targeting",body="#showtooltip\n/focus [@target,exists]"},
}
function M:GetSuite()
  local items={}
  for _,template in ipairs(self:GetRecommended()) do items[#items+1]=template end
  for _,template in ipairs(self.genericTemplates) do items[#items+1]=template end
  local saved=self:Store()
  for _,name in ipairs(saved.draftOrder) do
    if saved.drafts[name] then
      items[#items+1]={id=name,title="Saved draft: "..name,group="Custom",body=saved.drafts[name],custom=true}
    end
  end
  return items
end
function M:KnownSpellIndex()
  if not self.ScanSpellbook then return nil,"Spellbook scanner is not loaded" end
  local result,reason=self:ScanSpellbook()
  if not result then return nil,reason end
  local known={}
  for _,entry in ipairs(result) do
    known[entry.name]=entry
  end
  return known
end
function M.BuildSuite(parent)
  local function text(value,x,y,width,style)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontNormal")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    f:SetWidth(width);f:SetJustifyH("LEFT");f:SetText(value);return f
  end
  local function button(value,x,y,width,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,31);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(value);b:SetScript("OnClick",fn);return b
  end
  local class=M:CurrentClass()
  local pretty=class and (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class] or class) or "Unrecognized class"
  text("|cffffd87aMacro Suite|r — "..pretty,20,-17,770,"GameFontNormalLarge")
  text("Recommended class macros are optional; the spellbook checks what you've learned. Support sessions are separate.",20,-50,775,"GameFontHighlightSmall")
  local known,scanError=M:KnownSpellIndex()
  local entries=M:GetSuite()
  local filtered,selected={},{}
  local filter,page="Recommended",1
  local perPage=8
  local rows={}
  local status=text(known and "Learned spellbook loaded." or ("Spell verification unavailable: "..tostring(scanError)),20,-560,490,"GameFontHighlightSmall")
  local preview=text("Click a row to preview its commands. Check a row to include it.",20,-485,770,"GameFontHighlightSmall")
  local pageLabel=text("",217,-528,290,"GameFontHighlightSmall")
  local filterNames={"Recommended","General","Custom","All"}
  local filterButtons={}
  local function categoryMatch(item)
    if filter=="Recommended" then return item.recommended end
    if filter=="General" then return not item.recommended and not item.custom end
    if filter=="Custom" then return item.custom end
    return true
  end
  local function updateFilter()
    filtered={}
    for _,entry in ipairs(entries) do
      if categoryMatch(entry) then filtered[#filtered+1]=entry end
    end
    page=1
  end
  local function readyFor(item)
    if not item.recommended then return true,"Ready" end
    return M:RecommendationAvailability(item,known)
  end
  local function iconFor(item,widget)
    if not item then widget:Hide();return nil end
    widget:Show()
    widget:SetTexCoord(0,1,0,1)
    local texture=M:RecommendationIcon(item,known)
    if texture then widget:SetTexture(texture);return texture end
    local coords=M:ClassIconCoords(class)
    if coords then
      widget:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
      widget:SetTexCoord(coords[1],coords[2],coords[3],coords[4])
    else widget:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
    return nil
  end
  local render
  render=function()
    local maxPage=math.max(1,math.ceil(#filtered/perPage))
    page=math.min(page,maxPage)
    for i,row in ipairs(rows) do
      local item=filtered[(page-1)*perPage+i]
      row.check:SetShown(item~=nil)
      row.choose:SetShown(item~=nil)
      row.availability:SetShown(item~=nil)
      if item then
        local can,reason=readyFor(item)
        iconFor(item,row.icon)
        local title=item.title
        row.choose:SetText(title)
        row.check:SetChecked(selected[item.id] or false)
        row.check:SetEnabled(can~=false)
        row.availability:SetText(can==false and "|cffff9879Locked|r" or can==nil and "|cffffdc8aVerify|r" or "|cff92d6a3Ready|r")
        if can==false then selected[item.id]=nil;row.check:SetChecked(false) end
        row.check:SetScript("OnClick",function(self)
          if can==false then self:SetChecked(false);return end
          selected[item.id]=self:GetChecked() or nil
        end)
        row.choose:SetScript("OnClick",function()
          preview:SetText((item.recommended and "|cffffd87aRecommended|r · " or "")..
            item.group.." · "..(item.note or reason or "").."\n"..item.body)
        end)
        row.choose:SetScript("OnEnter",function(self)
          local detail=known and known[item.spell]
          if detail and detail.spellID and GameTooltip and type(GameTooltip.SetSpellByID)=="function" then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetSpellByID(detail.spellID);GameTooltip:Show()
          end
        end)
        row.choose:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide() end end)
      else row.icon:Hide() end
    end
    for i,b in ipairs(filterButtons) do
      b:SetText((filter==filterNames[i] and "> " or "")..filterNames[i])
    end
    pageLabel:SetText(#filtered.." macros · page "..page.." / "..maxPage)
  end
  for i,name in ipairs(filterNames) do
    filterButtons[i]=button(name,20+(i-1)*184,-88,173,function()
      filter=name;updateFilter();render()
    end)
  end
  for i=1,perPage do
    local y=-147-(i-1)*39
    local check=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    check:SetPoint("TOPLEFT",parent,"TOPLEFT",20,y)
    local icon=parent:CreateTexture(nil,"ARTWORK")
    icon:SetSize(30,30);icon:SetPoint("TOPLEFT",parent,"TOPLEFT",64,y)
    local choose=button("",101,y,575,function()end)
    local availability=text("",680,y-7,125,"GameFontHighlightSmall")
    rows[#rows+1]={check=check,icon=icon,choose=choose,availability=availability}
  end
  button("Previous",20,-526,134,function()page=math.max(1,page-1);render()end)
  button("Next",525,-526,120,function()page=page+1;render()end)
  button("Install selected",650,-526,155,function()
    local batch={}
    for _,item in ipairs(entries) do
      if selected[item.id] then
        local can,reason=readyFor(item)
        if can==false then status:SetText("Not learned: "..item.title);return end
        batch[#batch+1]={name=item.id,body=item.body,icon=M:RecommendationIcon(item,known)}
      end
    end
    local ok,reason=M:InstallBatch(batch)
    status:SetText((ok and "|cff92d6a3" or "|cffff9879")..tostring(reason).."|r")
  end)
  updateFilter();render()
end
