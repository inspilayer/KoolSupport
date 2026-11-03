-- Native macro operations are performed only when the player clicks Create/Update.
KSMacros = KSMacros or {}
local M = KSMacros
local MAX_BODY, MAX_NAME = 255, 16

local function trim(text)
  return (text or ""):match("^%s*(.-)%s*$")
end

function M:Store()
  local root = KoolSupport:GetDatabase()
  root.modules = root.modules or {}
  root.modules.ks_macros = root.modules.ks_macros or {}
  local data = root.modules.ks_macros
  data.owned = data.owned or {}
  data.drafts = data.drafts or {}
  data.draftOrder = data.draftOrder or {}
  return data
end

function M:NormalizeTooltip(body)
  if type(body) ~= "string" then return "#showtooltip\n" end
  local first, lines = nil, {}
  body = body:gsub("\r\n", "\n"):gsub("\r", "\n")
  for line in (body .. "\n"):gmatch("(.-)\n") do
    local text = trim(line)
    if text == "#showtooltip" or text:match("^#showtooltip%s+") then
      if not first or (first == "#showtooltip" and text ~= "#showtooltip") then first = text end
    else
      lines[#lines + 1] = line
    end
  end
  while #lines > 0 and trim(lines[1]) == "" do table.remove(lines, 1) end
  return (first or "#showtooltip") .. "\n" .. table.concat(lines, "\n")
end

function M:Validate(name, body)
  if type(name) ~= "string" or #name < 1 or #name > MAX_NAME or not name:match("^[%w_%-]+$") then
    return false, "Macro name must be 1-16 ASCII letters, digits, - or _"
  end
  if type(body) ~= "string" or #body == 0 then return false, "Macro body is empty" end
  if #body > MAX_BODY then return false, "Macro exceeds 255 bytes" end
  return true
end

function M:CastLine(spell, unit, relation)
  if type(spell) ~= "string" or #trim(spell) == 0 or #spell > 100 or spell:find("[\r\n%[%]/;]") then return nil end
  local allowed = {target=true,focus=true,focustarget=true,mouseover=true,player=true,none=true}
  if not allowed[unit] then return nil end
  if relation ~= nil and relation ~= "help" and relation ~= "harm" then return nil end
  if unit == "none" then return "/cast " .. trim(spell) end
  local conditions = "@" .. unit
  if relation then conditions = conditions .. "," .. relation .. ",nodead" end
  return "/cast [" .. conditions .. "] " .. trim(spell)
end

function M:SaveDraft(name, body)
  body = self:NormalizeTooltip(body)
  local ok, why = self:Validate(name, body)
  if not ok then return false, why end
  local data = self:Store()
  if not data.drafts[name] then data.draftOrder[#data.draftOrder + 1] = name end
  data.drafts[name] = body
  return true
end

function M:Install(name, body)
  if KoolSupport:IsInCombat() then return false, "Cannot edit macros in combat" end
  body = self:NormalizeTooltip(body)
  local ok, why = self:Validate(name, body)
  if not ok then return false, why end
  if type(GetMacroIndexByName) ~= "function" or type(CreateMacro) ~= "function" or type(EditMacro) ~= "function" then
    return false, "WoW macro API is unavailable"
  end
  local data = self:Store()
  local index = GetMacroIndexByName(name)
  if index and index > 0 then
    if type(GetMacroBody) ~= "function" then return false, "Cannot verify existing macro" end
    if not data.owned[name] then return false, "Refusing to overwrite a macro not owned by KS Macros" end
    if GetMacroBody(index) ~= data.owned[name] then return false, "Existing macro was edited outside KoolSupport" end
    local result = EditMacro(index, name, "INV_Misc_QuestionMark", body)
    if not result then return false, "WoW rejected the macro update" end
  else
    if type(GetNumMacros) ~= "function" then return false, "Macro count API unavailable" end
    local _, numCharacter = GetNumMacros()
    local limit = MAX_CHARACTER_MACROS or 18
    if (numCharacter or 0) >= limit then return false, "Character macro slots are full" end
    local result = CreateMacro(name, "INV_Misc_QuestionMark", body, true)
    if not result then return false, "WoW rejected the macro creation" end
  end
  data.owned[name] = body
  return true
end
