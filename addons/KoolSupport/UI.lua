-- Shared WoW-native host UI. Module pages register themselves; Base never imports their Lua.
local KS = KoolSupport
local window, content, pageWidgets, currentPage, navigation
local navButtons = {}
local GOLD = "|cffffd87a"
local MUTED = "|cff9fb4ad"

local function label(parent, text, x, y, width, font)
  local item = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
  item:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  item:SetWidth(width)
  item:SetJustifyH("LEFT")
  item:SetText(text)
  return item
end
local function button(parent, text, x, y, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 160, 31)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b:SetText(text)
  b:SetScript("OnClick", onClick)
  return b
end

local function buildHome(parent)
  label(parent, GOLD .. "KoolSupport|r  - Addon Workshop", 20, -22, 660, "GameFontNormalLarge")
  label(parent, "Build macros and enable only the tools you actually want.", 20, -64, 690)
  button(parent, "Open Macro Suite", 20, -122, 208, function() KS:ShowPage("macro_suite") end)
  button(parent, "Full Spellbook", 246, -122, 190, function() KS:ShowPage("full_spellbook") end)
  button(parent, "Custom Builder", 456, -122, 190, function() KS:ShowPage("macro_workshop") end)
  label(parent, "KS Macros ships with the base addon. Support Sessions and Stealth are optional.", 20, -195, 750)
  label(parent, MUTED .. "Development only: not a replacement for the existing CurseForge candidate.|r", 20, -241, 760)
end
local function buildModules(parent)
  label(parent, GOLD .. "Module Manager|r", 20, -22, 660, "GameFontNormalLarge")
  label(parent, "Disabling a module hides its UI; loaded Lua remains until reload.", 20, -60, 730)
  for i, id in ipairs(KS.moduleOrder) do
    local def = KS.modules[id]
    local y = -106 - (i - 1) * 69
    local enabled, why = KS:IsModuleEnabled(id)
    label(parent, def.title, 20, y, 310)
    label(parent, enabled and "Enabled" or (why or "Disabled"), 349, y, 190)
    button(parent, enabled and "Disable" or "Enable", 592, y + 9, 110, function()
      local ok, reason = KS:SetModuleEnabled(id, not enabled)
      if not ok and type(print) == "function" then print("KoolSupport: " .. tostring(reason)) end
    end)
  end
end

local function clearCurrent()
  if pageWidgets then pageWidgets:Hide() end
  pageWidgets = nil
end
local function redrawNavigation()
  if not navigation then return end
  for _, item in pairs(navButtons) do item:Hide() end
  local ordered = {"home", "modules", "macro_suite", "full_spellbook", "macro_workshop", "support_session", "stealth"}
  local seen = {}
  local index = 0
  local function addPage(id)
    if seen[id] or not KS:CanOpenPage(id) then return end
    local p = KS.pages[id]
    if not p then return end
    seen[id] = true
    local y = -18 - index * 46
    local b = navButtons[id]
    if not b then
      b = button(navigation, p.title, 10, y, 176, function() KS:ShowPage(id) end)
      navButtons[id] = b
    end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", navigation, "TOPLEFT", 10, y)
    b:SetText((currentPage == id and "> " or "") .. p.title)
    b:Show()
    index = index + 1
  end
  for _,id in ipairs(ordered) do addPage(id) end
  for _,id in ipairs(KS.pageOrder) do addPage(id) end
end

function KS:RefreshUI()
  if window and window:IsShown() then self:ShowPage(currentPage or "home") end
end
function KS:ShowPage(id)
  if not self:CanOpenPage(id) then id = "home" end
  if not window then self:Open(id); return end
  currentPage = id
  clearCurrent()
  local pane = CreateFrame("Frame", nil, content)
  pane:SetAllPoints(content)
  pageWidgets = pane
  if id == "home" then buildHome(pane)
  elseif id == "modules" then buildModules(pane)
  else
    local page = self.pages[id]
    if page then page.build(pane, self) else buildHome(pane) end
  end
  redrawNavigation()
  pane:Show()
end
function KS:Open(page)
  if not window then
    window = CreateFrame("Frame", "KoolSupportMainPanel", UIParent, "BackdropTemplate")
    window:SetSize(1090, 740)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=26,insets={left=8,right=8,top=8,bottom=8}})
    if UIParent and UIParent.GetWidth and UIParent.GetHeight then
      local w, h = UIParent:GetWidth(), UIParent:GetHeight()
      if w and h and w > 0 and h > 0 then window:SetScale(math.min(1, w / 1120, h / 770)) end
    end
    label(window, "KoolSupport  " .. KS.VERSION, 30, -23, 780, "GameFontNormalLarge")
    button(window, "X", 1030, -19, 37, function() window:Hide() end)
    navigation = CreateFrame("Frame", nil, window)
    navigation:SetPoint("TOPLEFT", window, "TOPLEFT", 25, -90)
    navigation:SetSize(200, 615)
    content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 235, -92)
    content:SetSize(824, 605)
    if UISpecialFrames then table.insert(UISpecialFrames, "KoolSupportMainPanel") end
  end
  window:Show()
  self:ShowPage(page or "home")
end
KS:RegisterPage({id="home",title="Home",build=buildHome})
KS:RegisterPage({id="modules",title="Modules",build=buildModules})
