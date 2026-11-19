-- KS Quest Checker: offline quest title lookup, exact Blizzard completion flags.
-- QuestieDB integration is OPTIONAL and read-only. No GPL database is bundled.
KSQuestChecker = KSQuestChecker or {}
local A = KSQuestChecker
A.SEED = {
  [3527] = "The Prophecy of Mosh'aru",
}
A.MAX_RESULTS = 11
A.MAX_RECENTS = 20
A.MAX_QUESTS = 100000

local function ordinary(value)
  if type(issecretvalue) == "function" then
    local ok,secret = pcall(issecretvalue,value)
    if not ok or secret then return false end
  end
  return true
end
local function safeString(value)
  if not ordinary(value) then return nil end
  if type(value) == "string" and #value > 0 and #value <= 350 then return value end
end
local function safeID(value)
  if not ordinary(value) or type(value) ~= "number" then return nil end
  if value >= 1 and value <= 1000000 and value == math.floor(value) then return value end
end
local function gameTitle(id)
  local api = C_QuestLog and C_QuestLog.GetTitleForQuestID
  if type(api) ~= "function" then return nil end
  local ok,title = pcall(api,id)
  if ok then return safeString(title) end
end

function A:Remember(id,name)
  id = safeID(id)
  name = safeString(name)
  if not id or not name then return false end
  self.byID = self.byID or {}
  self.byID[id] = name
  return true
end

function A:ReadActiveLog()
  local count
  local api = GetNumQuestLogEntries or GetNumQuests
  if type(api) == "function" then
    local ok,value = pcall(api)
    if ok and ordinary(value) and type(value) == "number" then
      count = math.min(math.max(0,math.floor(value)),1000)
    end
  end
  if not count or type(GetQuestLogTitle) ~= "function" then return end
  for i = 1,count do
    local ok,title,_,_,header,_,_,_,id = pcall(GetQuestLogTitle,i)
    if ok and ordinary(header) and header ~= true then
      self:Remember(id,title)
    end
  end
end

function A:ReadCompletedNames()
  -- Completion APIs supply IDs, never a full name catalog. Resolve only IDs
  -- for which Blizzard can return a title (or which our other sources know).
  local listAPI = C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs
  if type(listAPI) == "function" then
    local ok,list = pcall(listAPI)
    if ok and type(list) == "table" then
      local count = math.min(#list,self.MAX_QUESTS)
      for i = 1,count do
        local id = safeID(list[i])
        if id and not self.byID[id] then self:Remember(id,gameTitle(id)) end
      end
      return
    end
  end
  if type(GetQuestsCompleted) == "function" then
    local ok,map = pcall(GetQuestsCompleted)
    if ok and type(map) == "table" then
      local n = 0
      for raw,value in pairs(map) do
        n = n + 1
        if n > self.MAX_QUESTS then break end
        if value == true then
          local id = safeID(raw)
          if id and not self.byID[id] then self:Remember(id,gameTitle(id)) end
        end
      end
    end
  end
end

function A:ReadQuestieDB()
  -- Public QuestieDB contract: QuestDB.GetAllIds() and QuestDB.name(id).
  -- We neither import nor alter QuestieDB's GPL data; only read a provider
  -- already installed on this client. NEVER create a hard addon dependency.
  local provider = QuestDB or (LibQuestieDB and LibQuestieDB.Quest)
  if type(provider) ~= "table" or type(provider.GetAllIds) ~= "function"
      or type(provider.name) ~= "function" then return false end
  local ok,ids = pcall(provider.GetAllIds)
  if not ok or type(ids) ~= "table" then return false end
  local n = math.min(#ids,self.MAX_QUESTS)
  for i = 1,n do
    local id = safeID(ids[i])
    if id then
      local worked,name = pcall(provider.name,id)
      if worked then self:Remember(id,name) end
    end
  end
  self.provider = "QuestieDB"
  return true
end

function A:BuildIndex(refresh)
  if self.byID and not refresh then return self.byID end
  self.byID = {}
  self.provider = "Local + Blizzard"
  for id,name in pairs(self.SEED) do self:Remember(id,name) end
  self:ReadQuestieDB()
  self:ReadActiveLog()
  self:ReadCompletedNames()
  self.sorted = {}
  for id,name in pairs(self.byID) do
    self.sorted[#self.sorted + 1] = {id=id,name=name,lower=name:lower()}
  end
  table.sort(self.sorted,function(a,b)
    if a.lower ~= b.lower then return a.lower < b.lower end
    return a.id < b.id
  end)
  return self.byID
end

function A:Resolve(id)
  id = safeID(id)
  if not id then return nil end
  self:BuildIndex()
  if not self.byID[id] then
    local name = gameTitle(id)
    if name then
      self:Remember(id,name)
      self.sorted[#self.sorted+1] = {id=id,name=name,lower=name:lower()}
      table.sort(self.sorted,function(a,b)
        if a.lower ~= b.lower then return a.lower < b.lower end
        return a.id < b.id
      end)
    end
  end
  return self.byID[id] or ("Quest #"..id)
end

function A:Search(input,limit)
  if type(input) ~= "string" then return {},0 end
  local query = input:match("^%s*(.-)%s*$")
  if #query > 100 then return {},0 end
  local numeric = query:match("^%d+$")
  if numeric then
    local id = safeID(tonumber(numeric))
    if id then return {{id=id,name=self:Resolve(id)}},1 end
    return {},0
  end
  if #query < 2 then return {},0 end
  self:BuildIndex()
  limit = math.min(math.max(1,tonumber(limit) or self.MAX_RESULTS),self.MAX_RESULTS)
  local q = query:lower()
  local results,total = {},0
  -- Order exact matches, then prefix, then substring, with deterministic ties.
  for priority=1,3 do
    for _,entry in ipairs(self.sorted) do
      local start = entry.lower:find(q,1,true)
      local rank = start == 1 and (entry.lower == q and 1 or 2) or (start and 3)
      if rank == priority then
        total = total + 1
        if #results < limit then results[#results+1] = {id=entry.id,name=entry.name} end
      end
    end
  end
  return results,total
end

function A:Completed(id)
  id = safeID(id)
  if not id then return nil,"Invalid quest ID" end
  local fn = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
  if type(fn) ~= "function" then return nil,"Quest completion API unavailable" end
  local ok,flag = pcall(fn,id)
  if not ok or not ordinary(flag) or type(flag) ~= "boolean" then
    return nil,"Quest completion could not be verified"
  end
  -- "false" means not flagged as turned in, NOT necessarily never accepted.
  if flag then return true,"Completed / turned in" end
  return false,"Not flagged completed"
end

function A:Store()
  local db=KoolSupport:GetDatabase()
  db.modules=db.modules or {}
  db.modules.ks_quest_checker=db.modules.ks_quest_checker or {}
  local mine=db.modules.ks_quest_checker
  if type(mine.recent) ~= "table" then mine.recent={} end
  return mine
end
function A:SaveRecent(id)
  id=safeID(id)
  if not id then return false end
  local recent=self:Store().recent
  for i=#recent,1,-1 do if recent[i]==id then table.remove(recent,i) end end
  table.insert(recent,1,id)
  while #recent > self.MAX_RECENTS do table.remove(recent) end
  return true
end
function A:Recent()
  local result={}
  for _,id in ipairs(self:Store().recent) do
    id=safeID(id)
    if id then result[#result+1]={id=id,name=self:Resolve(id)} end
    if #result >= 6 then break end
  end
  return result
end
