-- Generic, class-neutral macro templates and per-character saved drafts.
-- Supportee / healer presets belong to the separate KSSupportSessions addon.
local M=KSMacros
M.genericTemplates={
  {id="KS-Assist", title="Assist current focus",group="Targeting",body="#showtooltip\n/assist [@focus,exists]"},
  {id="KS-Follow", title="Follow current focus",group="Targeting",body="#showtooltip\n/follow focus"},
  {id="KS-Stop",title="Stop casting",group="Actions",body="#showtooltip\n/stopcasting"},
  {id="KS-Atk",title="Start attacking",group="Actions",body="#showtooltip\n/startattack [harm,nodead]"},
  {id="KS-Cancel",title="Cancel current form",group="Forms",body="#showtooltip\n/cancelform [form]"},
  {id="KS-Target",title="Target last enemy",group="Targeting",body="#showtooltip\n/targetlastenemy"},
  {id="KS-Focus",title="Focus current target",group="Targeting",body="#showtooltip\n/focus [@target,exists]"},
}

function M:GetSuite()
  local entries={}
  for _,v in ipairs(self.genericTemplates) do entries[#entries+1]=v end
  local data=self:Store()
  for _,name in ipairs(data.draftOrder) do
    if data.drafts[name] then
      entries[#entries+1]={id=name,title="Saved draft: "..name,group="Custom",body=data.drafts[name]}
    end
  end
  return entries
end

function M.BuildSuite(parent)
  local function text(str,x,y,width,font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(width);t:SetJustifyH("LEFT");t:SetText(str);return t
  end
  local function button(title,x,y,width,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,31);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetText(title);b:SetScript("OnClick",callback);return b
  end
  text("|cffffd87aMacro Suite|r",20,-20,770,"GameFontNormalLarge")
  text("Generic templates and your saved Custom Builder drafts. Support macros live in Support Sessions.",20,-55,775)
  local entries=M:GetSuite()
  local page=1
  local pageSize=9
  local selected={}
  local rows={}
  local bodyPreview=text("Select a macro to inspect its native commands.",22,-452,770)
  local status=text("",22,-550,770)
  local pageLabel=text("",242,-510,250)
  local render
  render=function()
    for i,widgets in ipairs(rows) do
      local entry=entries[(page-1)*pageSize+i]
      widgets.select:SetShown(entry~=nil)
      widgets.check:SetShown(entry~=nil)
      if entry then
        widgets.select:SetText(entry.title.."  ["..entry.group.."]")
        widgets.check:SetChecked(selected[entry.id] or false)
        widgets.check:SetScript("OnClick",function(self) selected[entry.id]=self:GetChecked() end)
        widgets.select:SetScript("OnClick",function()bodyPreview:SetText(entry.body)end)
      end
    end
    pageLabel:SetText("Page "..page.." / "..math.max(1,math.ceil(#entries/pageSize)))
  end
  for i=1,pageSize do
    local y=-106-(i-1)*38
    local check=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    check:SetPoint("TOPLEFT",parent,"TOPLEFT",20,y)
    local select=button("",59,y,690,function()end)
    rows[i]={check=check,select=select}
  end
  button("Previous",20,-502,130,function()page=math.max(1,page-1);render()end)
  button("Next",530,-502,130,function()page=math.min(math.max(1,math.ceil(#entries/pageSize)),page+1);render()end)
  button("Install selected",530,-548,195,function()
    local items={}
    for _,entry in ipairs(entries) do
      if selected[entry.id] then items[#items+1]={name=entry.id,body=entry.body} end
    end
    local ok,why=M:InstallBatch(items)
    status:SetText(why)
  end)
  render()
end
