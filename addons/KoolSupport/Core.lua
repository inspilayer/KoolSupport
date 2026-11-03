-- KoolSupport Base API v1. This module never casts spells or controls another client.
KoolSupport = KoolSupport or {}
local KS = KoolSupport
KS.API_VERSION = 1
KS.VERSION = "0.7.0-dev"
KS.modules = KS.modules or {}
KS.moduleOrder = KS.moduleOrder or {}
KS.pages = KS.pages or {}
KS.pageOrder = KS.pageOrder or {}

local function database()
  KoolSupportDB = KoolSupportDB or {}
  KoolSupportDB.core = KoolSupportDB.core or {}
  KoolSupportDB.core.enabled = KoolSupportDB.core.enabled or {}
  return KoolSupportDB
end

function KS:GetDatabase()
  return database()
end

function KS:IsInCombat()
  return type(InCombatLockdown) == "function" and InCombatLockdown() or false
end

function KS:RegisterModule(def)
  assert(type(def) == "table" and type(def.id) == "string" and def.id:match("^[%w_]+$"), "invalid module id")
  assert(type(def.title) == "string" and def.title ~= "", "module title required")
  assert(not self.modules[def.id], "module already registered: " .. def.id)
  assert(def.apiVersion == self.API_VERSION, "incompatible KoolSupport API version")
  def.requires = def.requires or {}
  self.modules[def.id] = def
  self.moduleOrder[#self.moduleOrder + 1] = def.id
  return def
end

function KS:GetModule(id)
  return self.modules[id]
end

function KS:IsModuleEnabled(id, visited)
  local def = self.modules[id]
  if not def then return false, "Not installed" end
  visited = visited or {}
  if visited[id] then return false, "Circular module dependency" end
  visited[id] = true
  local selected = database().core.enabled[id]
  if selected == false or (selected == nil and def.defaultEnabled == false) then
    visited[id] = nil
    return false, "Disabled"
  end
  for _,dep in ipairs(def.requires) do
    local available, why = self:IsModuleEnabled(dep, visited)
    if not available then
      visited[id] = nil
      return false, "Requires " .. dep .. " (" .. (why or "unavailable") .. ")"
    end
  end
  visited[id] = nil
  return true
end

function KS:SetModuleEnabled(id, newValue)
  if self:IsInCombat() then return false, "Module settings cannot change in combat" end
  local def = self.modules[id]
  if not def then return false, "Module not installed" end
  if newValue then
    for _,dep in ipairs(def.requires) do
      local ok, why = self:IsModuleEnabled(dep)
      if not ok then return false, "Enable " .. dep .. " first: " .. (why or "not available") end
    end
  else
    for otherId, other in pairs(self.modules) do
      if otherId ~= id then
        local active = self:IsModuleEnabled(otherId)
        if active then
          for _,dep in ipairs(other.requires) do
            if dep == id then return false, "Disable " .. otherId .. " first" end
          end
        end
      end
    end
  end
  local wasEnabled = self:IsModuleEnabled(id)
  database().core.enabled[id] = not not newValue
  local isEnabled = self:IsModuleEnabled(id)
  if wasEnabled ~= isEnabled then
    local fn = isEnabled and def.onEnable or def.onDisable
    if type(fn) == "function" then pcall(fn, def, self) end
  end
  if type(self.RefreshUI) == "function" then self:RefreshUI() end
  return true
end

function KS:RegisterPage(page)
  assert(type(page) == "table" and type(page.id) == "string", "page id required")
  assert(type(page.title) == "string" and type(page.build) == "function", "page title/build required")
  assert(not self.pages[page.id], "page already registered: " .. page.id)
  if page.moduleId then assert(self.modules[page.moduleId], "page owner must register first") end
  self.pages[page.id] = page
  self.pageOrder[#self.pageOrder + 1] = page.id
end

function KS:CanOpenPage(id)
  local page = self.pages[id]
  if not page then return false end
  if not page.moduleId then return true end
  return self:IsModuleEnabled(page.moduleId)
end

SLASH_KOOLSUPPORT1 = "/kool"
SlashCmdList = SlashCmdList or {}
SlashCmdList.KOOLSUPPORT = function(text)
  local page = (text or ""):lower():match("^%s*(.-)%s*$")
  if page == "" then page = "home" end
  if page == "builder" or page == "macros" then page = "macro_workshop" end
  KS:Open(page)
end
