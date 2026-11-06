-- KS Campfire Chat native WoW panel. One genuine click -> at most one /say.
local A=KSCampfireChat
local GOLD="|cffffd87a"
local MUTED="|cff9fb4ad"
local GREEN="|cff9bd9ab"
local RED="|cffffa58d"

local function label(parent,text,x,y,w,font)
  local l=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
  l:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  l:SetWidth(w)
  l:SetJustifyH("LEFT")
  l:SetText(text)
  return l
end
local function button(parent,text,x,y,w,cb)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(w,36)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(text)
  b:SetScript("OnClick",cb)
  return b
end

function A.BuildPage(parent)
  label(parent,GOLD.."Campfire Chat|r",22,-22,740,"GameFontNormalLarge")
  label(parent,"Stay a while and tell a tale. All stories are original, lighthearted and shared in nearby /say.",22,-61,770)
  label(parent,"One click tells ONE short story. No automatic chat, no background broadcasts.",22,-91,770,"GameFontHighlightSmall")
  local buff=label(parent,"",22,-132,740,"GameFontNormalLarge")
  local status=label(parent,"",22,-373,768,"GameFontHighlightSmall")
  local preview=label(parent,"",22,-412,765,"GameFontHighlight")
  local buttons={}
  local choices={
    {"joke","Joke","Friendly groaners and campsite puns.",22,-192},
    {"spooky","Spooky","Tiny mysterious stories with cozy twists.",408,-192},
    {"ramble","Ramble","Very serious nonsense about very silly things.",22,-280},
    {"edgy","Edgy Joke","Cheeky tavern humor. Playfully spicy, never cruel.",408,-280}
  }
  for _,c in ipairs(choices) do
    local kind,title,description,x,y=c[1],c[2],c[3],c[4],c[5]
    local btn=button(parent,title,x,y,352,function()
      local ok,text=A:Tell(kind)
      status:SetText((ok and GREEN or RED)..(ok and "Shared in /say (subject to game chat limits)." or text).."|r")
      if ok then preview:SetText(MUTED..text.."|r") end
      A:RefreshAvailability()
    end)
    buttons[#buttons+1]=btn
    label(parent,description,x,y-44,352,"GameFontHighlightSmall")
  end
  local function refresh()
    local active=A:CampfireNearby()
    local enabled=KoolSupport:IsModuleEnabled("ks_campfire_chat")
    buff:SetText((active and GREEN or RED)..
      (active and "Campfire Nearby: active" or "Campfire Nearby: not detected").."|r")
    for _,b in ipairs(buttons) do b:SetEnabled(active and enabled) end
  end
  button(parent,"Check campfire buff",22,-502,231,function()
    refresh()
    status:SetText(MUTED.."Campfire status refreshed; nothing was said.|r")
  end)
  label(parent,MUTED.."Requires the Campfire Nearby buff (not the separate Camp Benefits buff).",272,-506,504,"GameFontHighlightSmall")
  label(parent,MUTED.."If the client hides the aura or blocks /say, Campfire Chat fails closed.",22,-545,765,"GameFontHighlightSmall")
  A.view={parent=parent,refresh=refresh}
  refresh()
end
