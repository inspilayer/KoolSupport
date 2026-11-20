local A=KSGuiltyForever
local function label(parent,text,x,y,w,font)
 local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT");t:SetText(text)
 return t
end
local function button(parent,text,x,y,w,fn)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,29);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetText(text);b:SetScript("OnClick",fn)
 return b
end
function A.BuildPage(parent)
 label(parent,"|cffffd87aGuilty Forever|r",20,-22,755,"GameFontNormalLarge")
 label(parent,"Private notes for ignored and enemy-faction players. Encounter reminders stay private.",20,-59,770)
 label(parent,"Player or Name-Realm",20,-96,400,"GameFontHighlightSmall")
 local name=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
 name:SetSize(380,30);name:SetPoint("TOPLEFT",parent,"TOPLEFT",30,-113)
 name:SetAutoFocus(false);name:SetMaxLetters(100)
 label(parent,"Reason / what they did",20,-155,700,"GameFontHighlightSmall")
 local reason=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
 reason:SetSize(730,30);reason:SetPoint("TOPLEFT",parent,"TOPLEFT",30,-175)
 reason:SetAutoFocus(false);reason:SetMaxLetters(500)
 local status=label(parent,"",20,-265,760,"GameFontHighlightSmall")
 local rows={}
 local function refresh()
  for _,b in ipairs(rows) do b:Hide() end
  local entries={}
  for _,e in pairs(A:Store().notes) do if type(e)=="table" and type(e.name)=="string" then entries[#entries+1]=e end end
  table.sort(entries,function(a,b)return a.name:lower()<b.name:lower()end)
  for i=1,math.min(7,#entries) do
   local b=rows[i]
   if not b then
    b=button(parent,"",20,-322-(i-1)*35,755,function()
     if b.entry then name:SetText(b.entry.name);reason:SetText(b.entry.reason) end
    end)
    rows[i]=b
   end
   b.entry=entries[i]
   b:SetText((entries[i].kind=="enemy" and "[ENEMY] " or "[IGNORE] ")..entries[i].name.." — "..entries[i].reason:gsub("[\r\n]"," "):sub(1,84));b:Show()
  end
  status:SetText("Saved notes: "..#entries..". Click a row to edit (first 7 displayed).")
 end
 button(parent,"Save note",20,-223,155,function()
  if A:Save(name:GetText(),reason:GetText()) then refresh() else status:SetText("Enter a valid name and reason.") end
 end)
 button(parent,"Delete note",192,-223,155,function()
  A:Delete(name:GetText());name:SetText("");reason:SetText("");refresh()
 end)
 button(parent,"Use target",365,-223,155,function()
  if UnitExists and UnitExists("target") and UnitName then
   local n,r=UnitName("target")
   if type(n)=="string" then name:SetText((type(r)=="string" and r~="") and n.."-"..r or n) end
  end
 end)
 label(parent,"|cff9fb4adNew ignores prompt for a note. Skipping never cancels Blizzard's ignore.|r",20,-292,770,"GameFontHighlightSmall")
 refresh()
end
