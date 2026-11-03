-- KS-native settings page. Matches Base spacing, fonts and shared colors; no standalone UI.
local A=KSAfflictions
local function label(parent,text,x,y,width,style)
  local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontNormal")
  f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  f:SetWidth(width)
  f:SetJustifyH("LEFT")
  f:SetText(text)
  return f
end
local function button(parent,title,x,y,width,callback)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetSize(width,32)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  b:SetText(title)
  b:SetScript("OnClick",callback)
  return b
end
function A.BuildPage(parent)
  local db=A:Store()
  label(parent,"|cffffd87aKS Afflictions|r  — Damage Over Time",20,-18,730,"GameFontNormalLarge")
  label(parent,"Original DoT estimation engine: DoesItDie by Joe Greive (MIT); KS-native bar rendering.",20,-60,765)
  label(parent,"Visual estimates only; never makes a spell choice for you.",20,-87,760)
  local status=label(parent,"",20,-516,760)
  local function change(key,value)
    local ok,err=A:ChangeSetting(key,value)
    status:SetText(ok and "Display updated" or tostring(err))
    if parent.IsShown and parent:IsShown() then A:RefreshAll() end
  end
  label(parent,"|cffffd87aDisplayed frames|r",20,-130,700,"GameFontNormalLarge")
  local toggles={}
  for i,entry in ipairs({{"target","Target bar"},{"focus","Focus bar"},{"nameplates","Visible nameplates"},{"lethal","Lethal indicator"},{"showLabels","DoT labels"},{"schoolColors","School colors"}}) do
    local key,title=entry[1],entry[2]
    local col=(i-1)%3
    local row=math.floor((i-1)/3)
    toggles[#toggles+1]=button(parent,"",20+col*247,-176-row*49,225,function()
      change(key,not A:Store()[key])
      for _,item in ipairs(toggles) do item.button:SetText(item.title..": "..(A:Store()[item.key] and "ON" or "OFF")) end
    end)
    toggles[#toggles]={button=toggles[#toggles],key=key,title=title}
  end
  for _,entry in ipairs(toggles) do
    if type(entry)=="table" and entry.button then entry.button:SetText(entry.title..": "..(db[entry.key] and "ON" or "OFF")) end
  end
  label(parent,"|cffffd87aBar layout|r",20,-313,700,"GameFontNormalLarge")
  local scaleText=label(parent,"",20,-355,200)
  local heightText=label(parent,"",285,-355,200)
  local offsetText=label(parent,"",551,-355,230)
  local function redraw()
    scaleText:SetText(string.format("Scale: %.2fx",A:Store().scale))
    heightText:SetText("Height: "..A:Store().height.." px")
    offsetText:SetText("Nameplate offset: "..A:Store().offsetY)
  end
  button(parent,"Smaller",20,-384,100,function()change("scale",A:Store().scale-.1);redraw()end)
  button(parent,"Larger",126,-384,100,function()change("scale",A:Store().scale+.1);redraw()end)
  button(parent,"Lower",285,-384,100,function()change("height",A:Store().height-2);redraw()end)
  button(parent,"Taller",391,-384,100,function()change("height",A:Store().height+2);redraw()end)
  button(parent,"Down",551,-384,100,function()change("offsetY",A:Store().offsetY+3);redraw()end)
  button(parent,"Up",657,-384,100,function()change("offsetY",A:Store().offsetY-3);redraw()end)
  redraw()
  label(parent,"|cff9fb4adDoTs are estimated from casts and observed ticks. Target health remains secret during combat.|r",20,-457,775)
  label(parent,"|cff9fb4adNameplate tracking covers visible plates only; no arbitrary range scan or automatic casts.|r",20,-481,775)
end
