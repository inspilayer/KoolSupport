-- KS Stealth talent impact browser. Opt-in, read-only, paged for the 605px pane.
-- Numeric examples are labeled "normalized" and never claim actual damage.
local S=KSStealth
local PER_PAGE=5
local function label(parent,value,x,y,width,font)
 local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 f:SetWidth(width)
 f:SetJustifyH("LEFT")
 f:SetText(value)
 return f
end
local function button(parent,value,x,y,width,callback)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(width,30)
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetText(value)
 b:SetScript("OnClick",callback)
 return b
end
function S.BuildTalentPage(parent)
 label(parent,"|cffffd87aKS Stealth - Talent Impacts|r",20,-18,770,"GameFontNormalLarge")
 label(parent,"Read-only rank, spellbook and talent effects. No casts, combat automation or hidden damage reads.",20,-50,775)
 label(parent,"API-calculated costs may include other effects; 100-damage and 200%-crit examples are illustrative.",20,-72,775,"GameFontHighlightSmall")

 local class
 if type(UnitClass)=="function" then local _;_,class=UnitClass("player") end
 if class~="DRUID" and class~="ROGUE" then
  label(parent,"|cffff8080Supported class catalog: Druid and Rogue only.|r",20,-133,755)
  return
 end
 local status=label(parent,"",20,-550,760,"GameFontHighlightSmall")
 local function redraw()KoolSupport:ShowPage("stealth_talents")end
 local enable=button(parent,"",20,-100,240,function()end)
 local function showState()
  enable:SetText(S:Store().talentImpactOverlay and "Talent previews: ON" or "Talent previews: OFF")
 end
 enable:SetScript("OnClick",function()
  local newValue=not S:Store().talentImpactOverlay
  local ok,why=S:SetTalentImpactOverlay(newValue)
  if ok then
   if newValue then S:RefreshTalentInsights() end
   redraw()
  else status:SetText(why or "Cannot change setting") end
 end)
 showState()
 if not S:Store().talentImpactOverlay then
  label(parent,"Turn previews ON to browse Forever talent ranks and affected spells.",20,-169,750)
  label(parent,"No game spells, macros or talent points will be changed.",20,-203,740)
  return
 end

 local annotate=button(parent,"",272,-100,226,function()end)
 local crit=button(parent,"",510,-100,270,function()end)
 local function setOption(key,value)
  local ok,why=S:SetTalentImpactSetting(key,value)
  if not ok then status:SetText(why or "Cannot change setting");return end
  if key=="talentAnnotate" and value then S:InstallTalentTooltipHook() end
  redraw()
 end
 annotate:SetText(S:Store().talentAnnotate and "Spellbook overlay: ON" or "Spellbook overlay: OFF")
 annotate:SetScript("OnClick",function()setOption("talentAnnotate",not S:Store().talentAnnotate)end)
 crit:SetText(S:Store().talentCritEstimate and "Crit illustration: ON" or "Crit illustration: OFF")
 crit:SetScript("OnClick",function()setOption("talentCritEstimate",not S:Store().talentCritEstimate)end)

 local snapshot=S.talentSnapshot
 if not snapshot or snapshot.class~=class then
  S:RefreshTalentInsights()
  snapshot=S.talentSnapshot
 end
 local caption
 if not snapshot or not snapshot.talents then
  caption="Talent ranks unavailable: "..tostring(snapshot and snapshot.talentError or "Refresh outside combat")
 elseif not snapshot.abilities then
  caption="Talent ranks ready; learned spells unavailable: "..tostring(snapshot.spellError)
 else caption="Talent ranks + learned spellbook ready (refresh after talent changes)" end
 label(parent,caption,20,-140,755,"GameFontHighlightSmall")

 local catalog=S:GetTalentImpactCatalog(class)
 label(parent,"|cffffd87aTalents ("..#catalog..")|r",20,-176,330,"GameFontNormalLarge")
 label(parent,"|cffffd87aAffected abilities|r",395,-176,388,"GameFontNormalLarge")
 local selected=1
 local page=1
 local buttons={}
 local rankText=label(parent,"",395,-209,410,"GameFontNormalLarge")
 local effect=label(parent,"",395,-244,390)
 local notice=label(parent,"",395,-295,395,"GameFontHighlightSmall")
 local slots={}
 for i=1,6 do
  local y=-329-(i-1)*35
  local tex=parent:CreateTexture(nil,"ARTWORK")
  tex:SetSize(24,24)
  tex:SetPoint("TOPLEFT",parent,"TOPLEFT",395,y)
  local name=label(parent,"",429,y-2,350,"GameFontHighlightSmall")
  slots[i]={icon=tex,name=name}
 end

 local function preview(index)
  local talent=catalog[index]
  if not talent then return end
  local rank=S:TrainedRank(talent)
  local rankLabel=rank==nil and "?/"..talent.maxRank.." (not verified)" or
   rank.."/"..talent.maxRank.." trained"
  rankText:SetText(talent.name.." |cff9fb4ad"..rankLabel.."|r")
  effect:SetText(talent.effect)
  notice:SetText(rank==nil and "Talent node not resolved in current config." or
   (rank==0 and "Not trained on this character." or "Active talent: per-ability modifiers below."))
  for i,slot in ipairs(slots) do
   local spell=talent.abilities[i]
   if spell then
    slot.icon:SetTexture(S:TalentAbilityIcon(spell))
    slot.icon:Show()
    local learned=snapshot and snapshot.abilities and snapshot.abilities[spell]
    local rankNote=learned and (learned.rank>0 and " (spell rank "..learned.rank..")" or " (learned)") or
      (snapshot and snapshot.abilities and " (not in spellbook)" or " (spellbook ?)")
    local lines=S:AbilityInsightLines(spell)
    local line=""
    for _,msg in ipairs(lines) do
     if msg:find(talent.name.." (",1,true)==1 then
      -- Highlight this talent's own contribution, not other modifiers.
      line=" |cff9bd9ab"..msg:match(":%s*(.+)$").."|r"
      break
     end
    end
    -- The right-hand row has limited width; full details are in native spell tooltips.
    if #line>88 then line=" |cff9bd9abSee spell tooltip for values|r" end
    slot.name:SetText(spell..rankNote..line)
   else slot.icon:Hide();slot.name:SetText("") end
  end
  for n,btn in ipairs(buttons) do
   local idx=(page-1)*PER_PAGE+n
   local e=catalog[idx]
   if e then btn:SetText((index==idx and "> " or "   ")..e.name) end
  end
 end

 local function drawList()
  for i,btn in ipairs(buttons) do
   local idx=(page-1)*PER_PAGE+i
   local talent=catalog[idx]
   btn:SetShown(talent~=nil)
   if talent then
    local rank=S:TrainedRank(talent)
    btn:SetText((idx==selected and "> " or "   ")..talent.name..
      (rank~=nil and (" ["..rank.."/"..talent.maxRank.."]") or " [?]"))
    btn:SetScript("OnClick",function()selected=idx;preview(selected)end)
    btn:SetScript("OnEnter",function()preview(idx)end)
    btn:SetScript("OnLeave",function()preview(selected)end)
   end
  end
 end
 for i=1,PER_PAGE do
  buttons[i]=button(parent,"",20,-208-(i-1)*47,345,function()end)
 end
 local pagination=label(parent,"",155,-480,190,"GameFontHighlightSmall")
 local function navigate(delta)
  page=math.max(1,math.min(math.ceil(#catalog/PER_PAGE),page+delta))
  selected=(page-1)*PER_PAGE+1
  drawList();preview(selected)
  pagination:SetText("Page "..page.." / "..math.ceil(#catalog/PER_PAGE))
 end
 button(parent,"Previous",20,-474,127,function()navigate(-1)end)
 button(parent,"Next",281,-474,85,function()navigate(1)end)
 button(parent,"Refresh talent data",20,-508,215,function()
  local ok,why=S:RefreshTalentInsights()
  status:SetText(why or (ok and "Refreshed" or "Cannot refresh"))
  redraw()
 end)
 if S:Store().talentAnnotate then S:InstallTalentTooltipHook() end
 navigate(0)
 status:SetText("Forever data pending in-game validation; unsupported numbers are never invented.")
end
