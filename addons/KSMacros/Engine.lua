-- Native macro operations are performed only when the player clicks Create/Update.
KSMacros = KSMacros or {}
local M = KSMacros
local MAX_BODY, MAX_NAME = 255, 16

-- Validate native API outputs before any mutation. Some Forever API surfaces
-- may be unavailable or throw; ambiguous lookup must never become "new macro".
local function nativeIndex(name)
  if type(GetMacroIndexByName)~="function" then return nil end
  local ok, index=pcall(GetMacroIndexByName,name)
  if not ok or type(index)~="number" or index<0 or index~=math.floor(index) then return nil end
  return index
end
local function nativeBody(index)
  if type(GetMacroBody)~="function" then return nil end
  local ok,body=pcall(GetMacroBody,index)
  return ok and type(body)=="string" and body or nil
end
local function nativeCharacterCount()
  if type(GetNumMacros)~="function" then return nil end
  local ok,_,characters=pcall(GetNumMacros)
  if not ok or type(characters)~="number" or characters<0 or characters~=math.floor(characters) then return nil end
  return characters
end
local function characterLimit()
  if type(MAX_CHARACTER_MACROS)=="number" and MAX_CHARACTER_MACROS>0 then return MAX_CHARACTER_MACROS end
  return 18
end

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
  if not data.legacyMigrationV1 then
    -- Copy only safely attributed legacy macros. Legacy owned[name] is a boolean;
    -- generated[name] is the last body written. Preserve both legacy tables.
    if type(root.owned)=="table" and type(root.generated)=="table" then
      for name, owned in pairs(root.owned) do
        local oldBody=root.generated[name]
        -- Only an explicit legacy-owned flag and a valid name/body can grant
        -- an ownership fingerprint. A future edit still requires an EXACT
        -- match against the player's native GetMacroBody result.
        if owned==true and self:Validate(name,oldBody) and data.owned[name]==nil then
          data.owned[name]=oldBody
        end
      end
    end
    if type(root.customDrafts)=="table" then
      local present={}
      for _,name in ipairs(data.draftOrder) do present[name]=true end
      -- Preserve malformed historical values in place, never replace them.
      -- Do not finalize migration until a malformed order can be reviewed.
      if root.customOrder~=nil and type(root.customOrder)~="table" then return data end
      for _,name in ipairs(root.customOrder or {}) do
        local legacy=root.customDrafts[name]
        local body=type(legacy)=="table" and legacy.body or legacy
        if type(name)=="string" and type(body)=="string" and data.drafts[name]==nil then
          local normalized=self:NormalizeTooltip(body)
          if self:Validate(name,normalized) then
            data.drafts[name]=normalized
            if not present[name] then data.draftOrder[#data.draftOrder+1]=name;present[name]=true end
          end
        end
      end
    end
    data.legacyMigrationV1=true
  end
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

function M:Install(name, body, icon)
  if KoolSupport:IsInCombat() then return false, "Cannot edit macros in combat" end
  body = self:NormalizeTooltip(body)
  local ok, why = self:Validate(name, body)
  if not ok then return false, why end
  if type(GetMacroIndexByName) ~= "function" or type(CreateMacro) ~= "function" or type(EditMacro) ~= "function" then
    return false, "WoW macro API is unavailable"
  end
  local data = self:Store()
  local index=nativeIndex(name)
  if index==nil then return false,"Cannot verify native macro lookup" end
  if index>0 then
    if not data.owned[name] then return false, "Refusing to overwrite a macro not owned by KS Macros" end
    local existing=nativeBody(index)
    if existing==nil then return false,"Cannot verify existing macro body" end
    if existing~=data.owned[name] then return false, "Existing macro was edited outside KoolSupport" end
    local success,result=pcall(EditMacro,index,name,icon or "INV_Misc_QuestionMark",body)
    if not success or not result then return false,"WoW rejected the macro update" end
  else
    local count=nativeCharacterCount()
    if count==nil then return false,"Cannot verify character macro slots" end
    if count>=characterLimit() then return false, "Character macro slots are full" end
    local success,result=pcall(CreateMacro,name,icon or "INV_Misc_QuestionMark",body,true)
    if not success or not result then return false,"WoW rejected the macro creation" end
  end
  data.owned[name]=body
  return true
end

-- Validate every proposed macro before writing any; client API errors can still
-- interrupt a batch, but conflicts and slot exhaustion cannot partially apply.
function M:InstallBatch(entries)
  if KoolSupport:IsInCombat() then return false,"Cannot edit macros in combat" end
  if type(entries)~="table" or #entries==0 then return false,"No macros selected" end
  if type(GetMacroIndexByName)~="function" or type(GetMacroBody)~="function" or type(GetNumMacros)~="function" then
    return false,"WoW macro APIs unavailable"
  end
  local store=self:Store()
  local seen,need={},0
  for _,entry in ipairs(entries) do
    if type(entry)~="table" then return false,"Invalid template" end
    local body=self:NormalizeTooltip(entry.body)
    local ok,why=self:Validate(entry.name,body)
    if not ok then return false,entry.name..": "..why end
    if seen[entry.name] then return false,"Duplicate macro name: "..entry.name end
    seen[entry.name]=true
    local index=nativeIndex(entry.name)
    if index==nil then return false,"Cannot verify native macro lookup: "..entry.name end
    if index>0 then
      local body=nativeBody(index)
      if not body or not store.owned[entry.name] or body~=store.owned[entry.name] then
        return false,"Refusing to overwrite an unrelated or edited macro: "..entry.name
      end
    else need=need+1 end
  end
  local count=nativeCharacterCount()
  if count==nil then return false,"Cannot verify character macro slots" end
  if count+need>characterLimit() then return false,"Character macro slots are full" end
  local completed=0
  for _,entry in ipairs(entries) do
    local ok,why=self:Install(entry.name,entry.body,entry.icon)
    if not ok then return false,"Installed "..completed.." before API failure: "..tostring(why) end
    completed=completed+1
  end
  return true,"Installed "..completed.." macro(s)"
end
