-- WoW-native UI; intentionally light-weight for the first modular foundation.
local KS = KoolSupport
local window, content, pageWidgets, currentPage
local COLORS = { gold = "|cffffd87a", muted = "|cff9fb4ad", stop = "|r" }

local function label(parent, text, x, y, width, font)
  local item = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
  item:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  item:SetWidth(width)
  item:SetJustifyH("LEFT")
  item:SetText(text)
  return item
end
local function button(parent, name, x, y, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 160, 30)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b:SetText(name)
  b:SetScript("OnClick", onClick)
  return b
end
local function clearCurrent()
  if pageWidgets then pageWidgets:Hide() end
  pageWidgets = nil
end

local function buildHome(parent)
  label(parent, COLORS.gold .. "KoolSupport" .. COLORS.stop, 20, -20, 500, "GameFontNormalLarge")
  label(parent, "Your addon workshop. Start with Macros, or manage installed modules.", 20, -60, 590)
  button(parent, "Open Macro Workshop", 20, -112, 210, function() KS:ShowPage("macro_workshop") end)
  button(parent, "Manage Modules", 245, -112, 170, function() KS:ShowPage("modules") end)
  label(parent, COLORS.muted .. "KS Macros ships with KoolSupport. Profiles and Support Sessions are optional extensions." .. COLORS.stop, 20, -180, 590)
  label(parent, COLORS.muted .. "Development preview - not a replacement for the v0.6.4 CurseForge submission." .. COLORS.stop, 20, -208, 590)
end

local function buildModules(parent)
  label(parent, COLORS.gold .. "Installed modules" .. COLORS.stop, 20, -20, 550, "GameFontNormalLarge")
  label(parent, "Disabling a loaded module hides its features. It does not unload Lua until a reload.", 20, -55, 600)
  for i,id in ipairs(KS.moduleOrder) do
    local def = KS.modules[id]
    local y = -104 - (i - 1) * 72
    label(parent, def.title, 20, y, 250)
    local enabled, why = KS:IsModuleEnabled(id)
    label(parent, enabled and "Enabled" or (why or "Disabled"), 280, y, 180)
    button(parent, enabled and "Disable" or "Enable", 480, y + 8, 104, function()
      local ok, message = KS:SetModuleEnabled(id, not enabled)
      if not ok and type(print) == "function" then print("KoolSupport: " .. tostring(message)) end
    end)
  end
  label(parent, COLORS.muted .. "Optional: KS Macro Profiles, KS Support Sessions and KS Stealth (not included)." .. COLORS.stop, 20, -420, 595)
end

function KS:RefreshUI()
  if not window or not window:IsShown() then return end
  self:ShowPage(currentPage or "home")
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
  pane:Show()
end

function KS:Open(page)
  if not window then
    window = CreateFrame("Frame", "KoolSupportMainPanel", UIParent, "BackdropTemplate")
    window:SetSize(890, 660)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=26, insets={left=8,right=8,top=8,bottom=8}})
    label(window, "KoolSupport  " .. KS.VERSION, 28, -22, 640, "GameFontNormalLarge")
    button(window, "X", 830, -17, 35, function() window:Hide() end)
    button(window, "Home", 25, -65, 118, function() KS:ShowPage("home") end)
    button(window, "Modules", 150, -65, 118, function() KS:ShowPage("modules") end)
    button(window, "KS Macros", 275, -65, 130, function() KS:ShowPage("macro_workshop") end)
    content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 22, -115)
    content:SetSize(842, 510)
    if UISpecialFrames then table.insert(UISpecialFrames, "KoolSupportMainPanel") end
  end
  window:Show()
  self:ShowPage(page or "home")
end

KS:RegisterPage({id = "home", title = "Home", build = buildHome})
KS:RegisterPage({id = "modules", title = "Modules", build = buildModules})
