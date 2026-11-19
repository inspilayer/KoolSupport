-- KS Quest Checker native WoW UI: type a name or ID, click result to check.
local A=KSQuestChecker
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
  b:SetSize(w,29)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(text)
  b:SetScript("OnClick",cb)
  return b
end
function A.BuildPage(parent)
  A:BuildIndex()
  label(parent,GOLD.."KS Quest Checker|r",20,-20,755,"GameFontNormalLarge")
  label(parent,"Search quests by name or enter an exact quest ID; select a result to check your character.",20,-56,777)
  local source=label(parent,"",20,-83,777,"GameFontHighlightSmall")
  local input=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
  input:SetSize(510,32)
  input:SetPoint("TOPLEFT",parent,"TOPLEFT",29,-120)
  input:SetAutoFocus(false)
  input:SetMaxLetters(100)
  local status=label(parent,MUTED.."Enter at least two letters, or any numeric quest ID.|r",20,-165,778,"GameFontHighlightSmall")
  local result=label(parent,"",20,-205,778,"GameFontNormalLarge")
  local description=label(parent,"",20,-238,775,"GameFontHighlightSmall")
  local controls={}
  local selectedID=nil
  local function showStatus(id,name)
    local completed,text=A:Completed(id)
    selectedID=id
    A:SaveRecent(id)
    result:SetText((completed==true and GREEN or completed==false and RED or MUTED)..
      (completed==true and "COMPLETE" or completed==false and "NOT COMPLETED" or "UNKNOWN")..
      "|r   "..name.."  |cff9fb4ad[#"..id.."]|r")
    description:SetText(text.." - Based on this character's quest completion flags.")
  end
  local function search()
    for _,b in ipairs(controls) do b:Hide() end
    selectedID=nil
    result:SetText("")
    description:SetText("")
    local query=input:GetText() or ""
    local rows,count=A:Search(query)
    if count == 0 then
      status:SetText(MUTED.."No matching known quests. Try a quest ID or install QuestieDB for the complete searchable catalog.|r")
    else
      status:SetText(MUTED..count.." matching quest"..(count==1 and "" or "s")..
        (count>#rows and " (first "..#rows.." shown)" or "").." | "..A.provider.."|r")
    end
    for i,entry in ipairs(rows) do
      local b=controls[i]
      if not b then
        b=button(parent,"",20,-278-(i-1)*27,755,function()
          local active=b.quest
          if active then showStatus(active.id,active.name) end
        end)
        -- Each row owns its own button; never share a loop-local closure.
        controls[i]=b
      end
      b.quest=entry
      b:SetText(entry.name.."  (#"..entry.id..")")
      b:Show()
    end
  end
  local submit=button(parent,"Search",556,-118,108,search)
  button(parent,"Refresh catalog",675,-118,123,function()
    A:BuildIndex(true)
    source:SetText(MUTED.."Catalog: "..#A.sorted.." quests | "..A.provider..
      (A.provider=="QuestieDB" and "" or " (install QuestieDB for more)").."|r")
    search()
  end)
  input:SetScript("OnEnterPressed",function(self)self:ClearFocus();search()end)
  input:SetScript("OnEscapePressed",function(self)self:ClearFocus()end)
  input:SetScript("OnTextChanged",function(_,userInput)
    if userInput then search() end
  end)
  source:SetText(MUTED.."Catalog: "..#A.sorted.." quests | "..A.provider..
    (A.provider=="QuestieDB" and "" or " (install QuestieDB for more)").."|r")
  label(parent,MUTED.."QuestieDB is optional; names are searched locally, never fetched over the network.|r",
    20,-585,770,"GameFontHighlightSmall")
  label(parent,MUTED.."NOT COMPLETED means not turned in. It does not mean you haven't started the quest.|r",
    20,-563,770,"GameFontHighlightSmall")
  local recent=A:Recent()
  if #recent>0 then
    local msg={}
    for _,item in ipairs(recent) do msg[#msg+1]=item.id end
    label(parent,MUTED.."Recent quest IDs: "..table.concat(msg,", ").."|r",
      20,-540,770,"GameFontHighlightSmall")
  end
end
