-- KoolSupport 1.0 UX foundation. Visual-only, native WoW controls.
-- Palette follows the Guilty Forever ledger; no gameplay or state mutation.
local KS=KoolSupport
local UI={}
KS.UIKit=UI
UI.font=STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
UI.palette={
 panel={.074,.087,.109,.97}, soft={.11,.132,.153,.94},
 border={.27,.30,.33,.85}, gold={.92,.72,.40,1},
 text={.87,.89,.86,1}, muted={.60,.68,.68,1},
 accent={.25,.56,.51,.98}, success={.31,.69,.48,1},
 danger={.69,.31,.29,1},
}
local function textureColor(target,color)
 if not target or not color then return end
 if target.SetColorTexture then
  target:SetColorTexture(color[1],color[2],color[3],color[4] or 1)
 elseif target.SetTexture and target.SetVertexColor then
  target:SetTexture("Interface\\Buttons\\WHITE8X8")
  target:SetVertexColor(color[1],color[2],color[3],color[4] or 1)
 end
end
function UI:Text(parent,words,x,y,w,role)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 t:SetWidth(w);t:SetJustifyH("LEFT");t:SetText(words or "")
 local size=role=="page" and 22 or role=="section" and 17 or role=="caption" and 12 or 14
 if t.SetFont then pcall(t.SetFont,t,self.font,size,"") end
 return t
end
function UI:Panel(parent,x,y,w,h,variant)
 local p=CreateFrame("Frame",nil,parent,"BackdropTemplate")
 p:SetSize(w,h)
 p:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 if p.SetBackdrop then
  p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
   edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  local bg=self.palette[variant=="soft" and "soft" or "panel"]
  local edge=self.palette.border
  if p.SetBackdropColor then p:SetBackdropColor(bg[1],bg[2],bg[3],bg[4]) end
  if p.SetBackdropBorderColor then p:SetBackdropBorderColor(edge[1],edge[2],edge[3],edge[4]) end
 end
 return p
end
function UI:Button(parent,title,x,y,w,callback,variant,h)
 -- Template-free buttons avoid bright red native button textures.
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetSize(w or 140,h or 30)
 if b.SetBackdrop then
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
   edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 end
 local name=b:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 name:SetPoint("CENTER",b,"CENTER",0,0)
 name:SetWidth((w or 140)-14)
 name:SetJustifyH("CENTER")
 if name.SetFont then pcall(name.SetFont,name,self.font,13,"") end
 b:SetFontString(name)
 local normal=self.palette[variant=="primary" and "accent" or variant=="danger" and "danger" or "soft"]
 local hover=self.palette[variant=="primary" and "success" or "border"]
 local function paint(c)
  if b.SetBackdropColor then b:SetBackdropColor(c[1],c[2],c[3],c[4] or 1) end
  if b.SetBackdropBorderColor then
   local e=UI.palette.border
   b:SetBackdropBorderColor(e[1],e[2],e[3],e[4])
  end
 end
 paint(normal)
 b:SetText(title)
 b:SetScript("OnEnter",function()paint(hover)end)
 b:SetScript("OnLeave",function()paint(normal)end)
 b:SetScript("OnClick",callback or function()end)
 return b
end
function UI:SettingRow(parent,x,y,w,title,description)
 local row=self:Panel(parent,x,y,w,52,"soft")
 self:Text(row,title,12,-7,w-25,"body")
 if description then
  local sub=self:Text(row,description,12,-30,w-25,"caption")
  if sub.SetTextColor then sub:SetTextColor(.60,.68,.68) end
 end
 return row
end
function UI:Segmented(parent,x,y,values,selected,onSelect,width)
 local gap=4
 width=width or 330
 local per=(width-gap*(#values-1))/#values
 local buttons={}
 local selectedValue=selected
 local function refresh()
  for i,entry in ipairs(values) do
   local b=buttons[i]
   if b and b.SetBackdropColor then
    local p=UI.palette[entry[1]==selectedValue and "accent" or "soft"]
    b:SetBackdropColor(p[1],p[2],p[3],p[4])
   end
  end
 end
 for i,entry in ipairs(values) do
  buttons[i]=self:Button(parent,entry[2],x+(i-1)*(per+gap),y,per,function()
   if onSelect(entry[1])~=false then selectedValue=entry[1];refresh() end
  end,"secondary",30)
 end
 refresh()
 return {refresh=refresh,select=function(value)selectedValue=value;refresh()end}
end
function UI:StyleExistingButton(b)
 if not b or type(b.GetObjectType)~="function" then return end
 -- Some older module buttons use UIPanelButtonTemplate with a red atlas.
 -- Keep their handlers and geometry intact; only replace the visual textures.
 local function change(method,color)
  local fn=b[method]
  if type(fn)~="function" then return end
  local ok,t=pcall(fn,b)
  if ok and t and type(t.SetVertexColor)=="function" then
   pcall(t.SetVertexColor,t,color[1],color[2],color[3],1)
  end
 end
 change("GetNormalTexture",{.40,.42,.43})
 change("GetPushedTexture",{.26,.45,.42})
 change("GetHighlightTexture",{.54,.49,.34})
 local text=b.GetFontString and b:GetFontString()
 if text and text.GetFont and text.SetFont then
  local ok,font,size,flags=pcall(text.GetFont,text)
  if ok and type(size)=="number" and size>15 then
   pcall(text.SetFont,text,font or self.font,14,flags or "")
  end
 end
end
