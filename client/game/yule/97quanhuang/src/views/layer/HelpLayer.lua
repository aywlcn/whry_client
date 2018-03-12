--
-- Author: luo
-- Date: 2016年12月26日 20:24:43
--
local HelpLayer = class("HelpLayer", cc.Layer)
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")

-- 关闭
HelpLayer.BT_HOME_Esc = 1
-- 上一页
HelpLayer.BT_HOME_Up = 2
-- 下一页
HelpLayer.BT_HOME_Next = 3

HelpLayer.RES_PATH 				= device.writablePath.. "game/yule/97quanhuang/res/"

function HelpLayer:ctor(scene )
    --注册触摸事件
    ExternalFun.registerTouchEvent(self, true)

    self.scene = scene
   
   local rootLayer, csbNode = ExternalFun.loadRootCSB(HelpLayer.RES_PATH .. "Help.csb", self);

	local function btnEvent( sender, eventType )
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(sender:getTag(), sender)
		end
	end

    local btn_all          = csbNode:getChildByName("ChuangKou_Ban_3") 
    self.first_page_one    = csbNode:getChildByName("BiaoTi_Scene_1")
    self.first_page_two    = csbNode:getChildByName("BiaoTi_Scene_2")
    self.first_page_two:setVisible(false)
    self.first_page_three  = csbNode:getChildByName("YanXian_34") 
    self.first_page_three:setVisible(false)

    local Btn_Up   = btn_all:getChildByName("Button_1")
    Btn_Up:setTag(HelpLayer.BT_HOME_Up)
    Btn_Up:addTouchEventListener(btnEvent)

    local Btn_Esc  = btn_all:getChildByName("Button_3")
    Btn_Esc:setTag(HelpLayer.BT_HOME_Esc)
    Btn_Esc:addTouchEventListener(btnEvent)

    local Btn_Next = btn_all:getChildByName("Button_2")
    Btn_Next:setTag(HelpLayer.BT_HOME_Next)
    Btn_Next:addTouchEventListener(btnEvent)

    self.Index = 1
	self:setVisible(true)
end

function HelpLayer:onButtonClickedEvent( touch, event )
    if touch == HelpLayer.BT_HOME_Esc  then
        self:setVisible(false)
    elseif touch == HelpLayer.BT_HOME_Up  then
        if self.Index == 1 then
            self.first_page_one:setVisible(false)
            self.first_page_three:setVisible(true)
            self.Index = 3
        elseif self.Index == 3 then
            self.first_page_three:setVisible(false)
            self.first_page_two:setVisible(true)
            self.Index = 2
        elseif self.Index == 2 then
            self.first_page_two:setVisible(false)
            self.first_page_one:setVisible(true)
            self.Index = 1
        end
    elseif touch == HelpLayer.BT_HOME_Next  then
        if self.Index == 3 then
            self.first_page_three:setVisible(false)
            self.first_page_one:setVisible(true)
            self.Index = 1
        elseif self.Index == 2 then
            self.first_page_two:setVisible(false)
            self.first_page_three:setVisible(true)
            self.Index = 3
        elseif self.Index == 1 then
            self.first_page_one:setVisible(false)
            self.first_page_two:setVisible(true)
            self.Index = 2
        end
    end
	
end

return HelpLayer