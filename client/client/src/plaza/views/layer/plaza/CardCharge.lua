--
-- Author: wss 点卡充值界面
-- Date: 2017-11-19
--
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
appdf.req(appdf.BASE_SRC.."function")

--返回按钮
local BT_EXIT 		= 101
--选择图片
local BT_PICIMG 	= 102
--发送按钮
local BT_SEND 		= 103
--我的反馈
local BT_MYFEEDBACk = 104
-- 充值按钮
local BT_CHARGE = 105

----我的反馈列表
--local CardChargeListLayer = class("CardChargeListLayer", cc.Layer)
--function CardChargeListLayer:ctor(scene)
--	self._scene = scene

--	--加载csb资源
--	local rootLayer, csbNode = ExternalFun.loadRootCSB("feedback/CardChargeListLayer.csb", self)
--	self.m_csbNode = csbNode

--	local function btncallback(ref, type)
--        if type == ccui.TouchEventType.ended then
--         	self:onButtonClickedEvent(ref:getTag(),ref)
--        end
--    end

--    --返回按钮
--    local btn = csbNode:getChildByName("btn_back")
--    btn:setTag(BT_EXIT)
--    btn:addTouchEventListener(btncallback)
--end

--function CardChargeListLayer:onButtonClickedEvent( tag, sender )
--	if BT_EXIT == tag then
--		self._scene:onKeyBack()		
--	end
--end

----反馈编辑界面
local CardChargeLayer = class("CardChargeLayer", cc.Layer)
--function CardChargeLayer.createFeedbackList( scene )
--	local list = CardChargeListLayer.new(scene)
--	return list
--end

function CardChargeLayer:ctor( scene )
	self._scene = scene

	--加载csb资源
	local rootLayer, csbNode = ExternalFun.loadRootCSB("CardCharge/CardChargeLayer.csb", self)
	self.m_csbNode = csbNode

	local function btncallback(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end
    --返回按钮
    local btn = csbNode:getChildByName("btn_back")
    btn:setTag(BT_EXIT)
    btn:addTouchEventListener(btncallback)

    csbNode:getChildByName("sp_modify_title_3"):setVisible(false)

    getChildFormObject(csbNode , "nameInputPanel"):setVisible(false)
    getChildFormObject(csbNode , "cardNumInputPanel"):setVisible(false)
    getChildFormObject(csbNode , "passwardInputPanel"):setVisible(false)

    -- 充值账号
    self._chargeNameInput = getChildFormObject(csbNode , "nameInputValue") 
    -- 点卡卡号
    self._cardNumInput = getChildFormObject(csbNode , "cardNumInputValue") 
    -- 点卡密码
    self._passwordInput = getChildFormObject(csbNode , "passwardInputValue") 

--    local editHanlder = function ( name, sender )
--		self:onEditEvent(name, sender)
--	end

    local chargeNameInput = ccui.EditBox:create(cc.size(490,67), ccui.Scale9Sprite:create("Logon/text_field_frame.png"))
		:move(self._chargeNameInput:getPositionX() ,self._chargeNameInput:getPositionY())
		:setAnchorPoint(cc.p(0.5,0.5))
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(40)
		:setPlaceholderFontSize(40)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)		
        :setPlaceHolder(self._chargeNameInput:getPlaceHolder())
        :setPlaceholderFontColor(self._chargeNameInput:getPlaceHolderColor())
		:addTo(self._chargeNameInput:getParent(),10)
        

    self._chargeNameInput:removeFromParent()
    self._chargeNameInput = chargeNameInput
	--self.edit_Account:registerScriptEditBoxHandler(editHanlder)

    local cardNumInput = ccui.EditBox:create(cc.size(490,67), ccui.Scale9Sprite:create("Logon/text_field_frame.png"))
		:move(self._cardNumInput:getPositionX() ,self._cardNumInput:getPositionY())
		:setAnchorPoint(cc.p(0.5,0.5))
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(40)
		:setPlaceholderFontSize(40)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)		
        :setPlaceHolder(self._cardNumInput:getPlaceHolder())
        :setPlaceholderFontColor(self._cardNumInput:getPlaceHolderColor())
		:addTo(self._cardNumInput:getParent(),10)

    self._cardNumInput:removeFromParent()
    self._cardNumInput = cardNumInput

    local passwordInput = ccui.EditBox:create(cc.size(490,67), ccui.Scale9Sprite:create("Logon/text_field_frame.png"))
		:move(self._passwordInput:getPositionX() ,self._passwordInput:getPositionY())
		:setAnchorPoint(cc.p(0.5,0.5))
		:setFontName("fonts/round_body.ttf")
		:setPlaceholderFontName("fonts/round_body.ttf")
		:setFontSize(40)
		:setPlaceholderFontSize(40)
		:setMaxLength(31)
		:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)	
        :setPlaceHolder(self._passwordInput:getPlaceHolder())
        :setPlaceholderFontColor(self._passwordInput:getPlaceHolderColor())
		:addTo(self._passwordInput:getParent(),10)

    self._passwordInput:removeFromParent()
    self._passwordInput = passwordInput


    self._chargeNameInput:setText( GlobalUserItem.szNickName )
    
    -- 充值按钮
    self._chargeBtn = getChildFormObject(csbNode , "chargeButton") 
    self._chargeBtn:setTag(BT_CHARGE)
    self._chargeBtn:addTouchEventListener(btncallback)
    
--	local tmp = csbNode:getChildByName("sp_public_frame")
--	--平台判定
--	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
--	if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then
--		--反馈页面
--		self.m_webView = ccexp.WebView:create()
--	    self.m_webView:setPosition(cc.p(667, 322))
--	    self.m_webView:setContentSize(cc.size(1260, 580))

--	    self.m_webView:setScalesPageToFit(true)
--	    --local url = yl.HTTP_URL .. "/Pay/PayCardFill.aspx"
--        local url = yl.HTTP_URL .. "/SyncLogin.aspx?userid=" .. GlobalUserItem.dwUserID .. "&time=".. os.time() .. "&signature="..GlobalUserItem:getSignature(os.time()).."&url=/Pay/PayCardFill.aspx"
--	    self.m_webView:loadURL(url)
--        ExternalFun.visibleWebView(self.m_webView, false)
--	    self._scene:showPopWait()

--	    self.m_webView:setOnJSCallback(function ( sender, url )

--	    end)

--	    self.m_webView:setOnDidFailLoading(function ( sender, url )
--	    	self._scene:dismissPopWait()
--	    	print("open " .. url .. " fail")
--	    end)
--	    self.m_webView:setOnShouldStartLoading(function(sender, url)
--	        print("onWebViewShouldStartLoading, url is ", url)	        
--	        return true
--	    end)
--	    self.m_webView:setOnDidFinishLoading(function(sender, url)
--	    	self._scene:dismissPopWait()
--            ExternalFun.visibleWebView(self.m_webView, true)
--	        print("onWebViewDidFinishLoading, url is ", url)
--	    end)
--	    self:addChild(self.m_webView)
--	end
    --tmp:removeFromParent()
end

function CardChargeLayer:doCharge()
    --- test
    local beanurl = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
    --print("self._chargeNameInput:getString()------》",self._chargeNameInput:getText())
    --print("self._cardNumInput:getString()------》",self._cardNumInput:getText())
    --print("self._passwordInput:getString()------》",self._passwordInput:getText())

   

    appdf.onHttpJsionTable(beanurl ,"GET","action=GetActivateCard&account=" .. self._chargeNameInput:getText() .. "&card=".. self._cardNumInput:getText() .. "&pas=".. self._passwordInput:getText() .. "&userid=" .. GlobalUserItem.dwGameID ,function(sjstable,sjsdata)
        if sjstable then
            --dump(sjstable, "-------------------------- GetActivateCard", 6)
            showToast(self, sjstable.msg , 3)
        end
        self._scene:queryUserScoreInfo()
        self._scene:updateInfomation()
        
    end)
end

function CardChargeLayer:onButtonClickedEvent( tag, sender )
	if BT_EXIT == tag then
		self._scene:onKeyBack()
	elseif BT_CHARGE == tag then
		self:doCharge()
	end
end



return CardChargeLayer