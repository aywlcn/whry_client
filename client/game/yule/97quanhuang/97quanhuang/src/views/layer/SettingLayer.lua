--
-- Author: luo
-- Date: 2016年12月30日 17:50:01
--
--设置界面
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")

local SettingLayer = class("SettingLayer", cc.Layer)

SettingLayer.BT_EFFECT = 1
SettingLayer.BT_MUSIC = 2
SettingLayer.BT_CLOSE = 3
--构造
function SettingLayer:ctor( verstr )
    --注册触摸事件
    ExternalFun.registerTouchEvent(self, true)
    --加载csb资源
    self._csbNode = ExternalFun.loadCSB("setLayer.csb", self)

    self._csbNode:setZOrder(10)

    local cbtlistener = function (sender,eventType)
        if eventType == ccui.TouchEventType.ended then
            self:OnButtonClickedEvent(sender:getTag(),sender,eventType)
        end
    end 

    --关闭按钮
    local btn = self._csbNode:getChildByName("closeBtn")
        btn:setTag(SettingLayer.BT_CLOSE)
        btn:addTouchEventListener(function (ref, eventType)
            if eventType == ccui.TouchEventType.ended then
                ExternalFun.playClickEffect()
                self:removeFromParent()
            end
    end)
    --音效
    self.m_btnEffect = self._csbNode:getChildByName("Button_4")
    self.m_btnEffect:setTag(SettingLayer.BT_EFFECT) 
    self.m_btnEffect:addTouchEventListener(cbtlistener)
    --音乐
    self.m_btnMusic = self._csbNode:getChildByName("Button_4_0")
    self.m_btnMusic:setTag(SettingLayer.BT_MUSIC) 
    self.m_btnMusic:addTouchEventListener(cbtlistener)
      
    self:refreshBtnState()
end
-- 

function SettingLayer:OnButtonClickedEvent( tag, sender , eventType )
    if SettingLayer.BT_MUSIC == tag then
		local music = not GlobalUserItem.bVoiceAble;
		GlobalUserItem.setVoiceAble(music)
		self:refreshMusicBtnState()
		if GlobalUserItem.bVoiceAble == true then
			ExternalFun.playBackgroudAudio("QUANHUANG.mp3")
		end
	elseif SettingLayer.BT_EFFECT == tag then
		local effect = not GlobalUserItem.bSoundAble
		GlobalUserItem.setSoundAble(effect)
		self:refreshEffectBtnState()
	end
end
 
 
function SettingLayer:refreshBtnState(  )
	self:refreshEffectBtnState()
	self:refreshMusicBtnState()
end
--lcs按钮状态
function SettingLayer:refreshEffectBtnState(  )
	local str = nil
	if GlobalUserItem.bSoundAble then
		self.m_btnEffect:setBright(true)
	else
		self.m_btnEffect:setBright(false)
	end
end
--lcs音效状态
function SettingLayer:refreshMusicBtnState(  )
	local str = nil
	if GlobalUserItem.bVoiceAble then
		self.m_btnMusic:setBright(true)
	else
		self.m_btnMusic:setBright(false)
	end
end
 

return SettingLayer