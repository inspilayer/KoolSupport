-- Starter generic workshop. Full legacy Spellbook and support-suite migration is a later PR.
local KS, M = KoolSupport, KSMacros
local function label(parent, text, x, y, width)
  local xref = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  xref:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  xref:SetWidth(width or 300)
  xref:SetJustifyH("LEFT")
  xref:SetText(text)
  return xref
end
local function button(parent, text, x, y, width, callback)
  local item = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  item:SetSize(width or 110, 30)
  item:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  item:SetText(text)
  item:SetScript("OnClick", callback)
  return item
end
local function field(parent, x, y, width, initial)
  local item = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  item:SetSize(width, 28)
  item:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  item:SetAutoFocus(false)
  item:SetText(initial or "")
  return item
end

function M.BuildWorkshop(parent)
  label(parent, "|cffffd87aKS Macros - Generic Macro Workshop|r", 20, -16, 750)
  label(parent, "Macro name", 20, -55, 200)
  local name = field(parent, 20, -77, 190, "KSM-New")
  label(parent, "Spell to insert", 230, -55, 215)
  local spell = field(parent, 230, -77, 225, "")
  label(parent, "Click a targeting shortcut to add a cast command to the editor.", 20, -121, 720)
  local body = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  body:SetSize(790, 200)
  body:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -200)
  body:SetAutoFocus(false)
  body:SetMultiLine(true)
  body:SetTextInsets(10, 10, 10, 10)
  body:SetText("#showtooltip\n")
  local status = label(parent, "Draft only - no in-game actions until Create / Update is clicked.", 20, -455, 790)
  local function append(unit, relation)
    local line = M:CastLine(spell:GetText(), unit, relation)
    if not line then status:SetText("Enter a valid spell name first"); return end
    body:SetText(M:NormalizeTooltip(body:GetText() .. "\n" .. line))
  end
  button(parent, "Focus heal", 20, -155, 115, function() append("focus", "help") end)
  button(parent, "Focus enemy", 145, -155, 120, function() append("focustarget", "harm") end)
  button(parent, "Mouseover", 275, -155, 115, function() append("mouseover", "help") end)
  button(parent, "Self", 400, -155, 90, function() append("player", nil) end)
  button(parent, "Target", 500, -155, 105, function() append("target", nil) end)
  button(parent, "Save draft", 20, -410, 140, function()
    local ok, why = M:SaveDraft(name:GetText(), body:GetText())
    status:SetText(ok and "Draft saved per character" or why)
  end)
  button(parent, "Create / Update", 180, -410, 165, function()
    local ok, why = M:Install(name:GetText(), body:GetText())
    status:SetText(ok and "Native character macro updated; open /macro to bind it" or why)
  end)
  button(parent, "New", 360, -410, 100, function()
    name:SetText("KSM-New")
    spell:SetText("")
    body:SetText("#showtooltip\n")
    status:SetText("New draft")
  end)
  local data = M:Store()
  local selected = 1
  local function loadDraft()
    local key = data.draftOrder[selected]
    if key and data.drafts[key] then
      name:SetText(key)
      body:SetText(data.drafts[key])
      status:SetText("Loaded saved draft " .. selected .. "/" .. #data.draftOrder)
    else
      status:SetText("No saved drafts")
    end
  end
  button(parent, "Previous draft", 480, -410, 125, function()
    selected = math.max(1, selected - 1)
    loadDraft()
  end)
  button(parent, "Next draft", 615, -410, 125, function()
    selected = math.min(#data.draftOrder, selected + 1)
    loadDraft()
  end)
end
