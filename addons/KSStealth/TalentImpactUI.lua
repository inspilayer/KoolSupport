-- Read-only KS Stealth talent catalog. The hover effect is inside this
-- optional KS page; it deliberately does not hook Blizzard's talent UI.
local S=KSStealth

local function label(parent,text,x,y,width,font)
  local fs=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
  fs:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  fs:SetWidth(width)
  fs:SetJustifyH("LEFT")
  fs:SetText(text)
  return fs
end

local function button(parent,text,x,y,w,handler)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,34)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(text)
  b:SetScript("OnClick",handler)
  return b
end

function S.BuildTalentPage(parent)
  label(parent,"|cffffd87aKS Stealth - Talent Impacts|r",20,-18,770,"GameFontNormalLarge")
  label(parent,"Read-only ability mapping for WoW Forever. Hover a talent to preview its affected abilities.",20,-54,770)
  label(parent,"Sprint 1: catalog only; no trained-rank detection, damage calculation, or native tooltip changes.",20,-78,780)

  local class
  -- Use the second UnitClass return (the stable nonlocalized class token).
  if type(UnitClass)=="function" then
    local _
    _,class=UnitClass("player")
  end
  if class~="DRUID" and class~="ROGUE" then
    label(parent,"|cffff8080Available for Druid and Rogue characters only.|r",20,-140,760)
    return
  end

  local toggle=button(parent,"",20,-112,280,function()end)
  local status=label(parent,"",319,-119,470)
  local function toggleState()
    toggle:SetText(S:Store().talentImpactOverlay and "Talent previews: ON" or "Talent previews: OFF")
  end
  toggle:SetScript("OnClick",function()
    local ok,why=S:SetTalentImpactOverlay(not S:Store().talentImpactOverlay)
    if ok then KoolSupport:ShowPage("stealth_talents")
    else status:SetText(why or "Cannot update setting now") end
  end)
  toggleState()

  if not S:Store().talentImpactOverlay then
    label(parent,"Enable Talent Previews to browse supported Forever talents and affected spellbook abilities.",20,-184,760)
    label(parent,"This opt-in feature never casts spells, edits macros, or reads combat resource values.",20,-225,760)
    return
  end

  local catalog=S:GetTalentImpactCatalog(class)
  if #catalog==0 then
    label(parent,"No supported talent entries were found for this class.",20,-183,760)
    return
  end
  label(parent,"|cffffd87a"..(class=="DRUID" and "Feral Combat" or "Rogue Combat").." talents|r",20,-173,330,"GameFontNormalLarge")
  label(parent,"|cffffd87aAffected abilities|r",383,-173,392,"GameFontNormalLarge")

  local buttons={}
  local selected=1
  local detailName=label(parent,"",383,-215,420,"GameFontNormalLarge")
  local detailEffect=label(parent,"",383,-249,414)
  label(parent,"Ability names are catalog matches, not a claim that you learned them.",383,-303,405,"GameFontDisableSmall")

  local abilitySlots={}
  for i=1,6 do
    local y=-338-(i-1)*38
    local tex=parent:CreateTexture(nil,"ARTWORK")
    tex:SetSize(25,25)
    tex:SetPoint("TOPLEFT",parent,"TOPLEFT",385,y)
    local name=label(parent,"",420,y-4,350)
    abilitySlots[i]={icon=tex,name=name}
  end

  local function preview(index)
    local entry=catalog[index]
    if not entry then return end
    detailName:SetText(entry.name.."  |cff9fb4ad("..entry.maxRank.." ranks max)|r")
    detailEffect:SetText(entry.effect)
    for i,slot in ipairs(abilitySlots) do
      local spell=entry.abilities[i]
      if spell then
        slot.icon:SetTexture(S:TalentAbilityIcon(spell))
        slot.icon:Show()
        slot.name:SetText(spell)
      else
        slot.icon:Hide()
        slot.name:SetText("")
      end
    end
    for i,b in ipairs(buttons) do
      b:SetText((i==index and "> " or "   ")..catalog[i].name)
    end
  end

  for i,entry in ipairs(catalog) do
    local b=button(parent,entry.name,20,-215-(i-1)*57,315,function()
      selected=i
      preview(selected)
    end)
    b:SetScript("OnEnter",function()preview(i)end)
    b:SetScript("OnLeave",function()preview(selected)end)
    buttons[i]=b
  end
  preview(selected)
  label(parent,"|cff9fb4adForever catalog checked against Nov 2 changes. Confirm ability/talent text in the live client.|r",20,-565,780,"GameFontDisableSmall")
end
