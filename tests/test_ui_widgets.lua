-- Native UX kit smoke test: layouts and callbacks without WoW client.
KoolSupport={}
local widgets={}
local function make(kind,parent)
 local f={kind=kind,parent=parent,shown=true}
 function f:SetPoint(...)self.point={...}end
 function f:SetAllPoints()end
 function f:SetSize(w,h)self.w,self.h=w,h end
 function f:SetWidth(w)self.w=w end
 function f:SetText(text)self.text=text end
 function f:GetText()return self.text end
 function f:SetFontString(t)self.fontstring=t end
 function f:GetFontString()return self.fontstring end
 function f:SetFont()end
 function f:SetJustifyH()end
 function f:SetBackdrop()end
 function f:SetBackdropColor(...)self.bg={...}end
 function f:SetBackdropBorderColor(...)self.edge={...}end
 function f:Show()self.shown=true end
 function f:Hide()self.shown=false end
 function f:CreateFontString()return make("FontString",self)end
 function f:SetScript(event,callback)self[event]=callback end
 function f:GetObjectType()return kind end
 widgets[#widgets+1]=f
 return f
end
CreateFrame=function(kind,_,parent)return make(kind,parent)end
assert(loadfile("addons/KoolSupport/UIWidgets.lua"))()
local UI=KoolSupport.UIKit
assert(UI and UI.palette and UI.palette.gold)
local root=make("Frame")
local card=UI:Panel(root,12,-16,400,150)
assert(card.w==400 and card.bg and card.bg[1]<.2)
local label=UI:Text(card,"Settings",12,-12,200,"section")
assert(label.text=="Settings")
local clicks=0
local b=UI:Button(card,"Save",15,-60,130,function()clicks=clicks+1 end,"primary",29)
assert(b.kind=="Button" and b.h==29 and b.text=="Save")
b.OnEnter();b.OnLeave();b.OnClick()
assert(clicks==1)
local chosen="below"
local control=UI:Segmented(card,15,-95,{{"above","Above"},{"below","Below"}},chosen,function(value)chosen=value;return true end,250)
assert(control and control.refresh and control.select)
control.select("above")
assert(chosen=="below","programmatic selection does not mutate callback")
local row=UI:SettingRow(root,12,-170,420,"Combo Points","Visible on your target")
assert(row.w==420)
print("PASS shared UI kit: compact controls, accent state, callback and card styles")
