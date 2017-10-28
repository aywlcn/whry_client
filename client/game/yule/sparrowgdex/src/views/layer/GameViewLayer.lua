local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.models.CMD_Game")

local GameViewLayer = class("GameViewLayer",function(scene)
	local gameViewLayer =  cc.CSLoader:createNode(cmd.RES_PATH.."game/GameScene.csb")
    return gameViewLayer
end)

require("client/src/plaza/models/yl")
local PopupInfoHead = appdf.req("client.src.external.PopupInfoHead")
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.models.GameLogic")
local CardLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.views.layer.CardLayer")
local ResultLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.views.layer.ResultLayer")
local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
local PlayerInfo = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.views.layer.PlayerInfo")
local SettingLayer = appdf.req(appdf.GAME_SRC .. "yule.sparrowgdex.src.views.layer.SettingLayer")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")

local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. "AnimationMgr")

local anchorPointHead = {cc.p(1, 1), cc.p(0, 0.5), cc.p(0, 0), cc.p(1, 0.5)}
local posHead = {cc.p(577, 295), cc.p(165, 332), cc.p(166, 257), cc.p(724, 273)}
local posReady = {cc.p(-333, 0), cc.p(135, 0), cc.p(516, -80), cc.p(-134, 0)}
local posPlate = {cc.p(667, 589), cc.p(237, 464), cc.p(667, 174), cc.p(1093, 455)}
local posChat = {cc.p(873, 660), cc.p(229, 558), cc.p(270, 285), cc.p(1095, 528)}


local VOICE_BTN_NAME = "__voice_record_button__"  --语音按钮名字，可以获取语音按钮，控制显示与否

GameViewLayer.BT_MENU				= 10 				--按钮开关按钮
GameViewLayer.BT_CHAT 				= 11				--聊天按钮
GameViewLayer.BT_SET 				= 12				--设置
GameViewLayer.CBX_SOUNDOFF 			= 13				--声音开关
GameViewLayer.BT_EXIT	 			= 14			--退出按钮
GameViewLayer.BT_TRUSTEE 			= 15				--托管按钮
GameViewLayer.BT_HOWPLAY 			= 16				--玩法按钮

GameViewLayer.BT_START 				= 20				--开始按钮
GameViewLayer.NODE_INFO_TAG			= 100				--信息界面

GameViewLayer.BT_CHI				= 30				--游戏操作按钮吃
GameViewLayer.BT_GANG 				= 31				--游戏操作按钮杠
GameViewLayer.BT_PENG				= 32				--游戏操作按钮碰
GameViewLayer.BT_HU 				= 33				--游戏操作按钮胡
GameViewLayer.BT_GUO				= 34				--游戏操作按钮过
GameViewLayer.BT_TING				= 35				--游戏操作按钮听

GameViewLayer.ZORDER_OUTCARD = 40
GameViewLayer.ZORDER_ACTION = 50
GameViewLayer.ZORDER_CHAT = 60
GameViewLayer.ZORDER_SETTING = 70
GameViewLayer.ZORDER_INFO = 90
GameViewLayer.ZORDER_RESULT = 100	

function GameViewLayer:onInitData()
	self.cbActionCard = 0
	self.cbOutCardTemp = 0
	self.bListenBtnEnabled = false
	self.chatDetails = {}
	self.cbAppearCardIndex = {}
	self.bChoosingHu = false
	self.m_bNormalState = {}
	self.m_nLeftCard = 0
	self.m_nAllCard = 0

	-- 用户头像
    self.m_tabUserHead = {}

	--房卡需要
	self.m_UserItem = {}

	-- 语音动画
    AnimationMgr.loadAnimationFromFrame("record_play_ani_%d.png", 1, 3, cmd.VOICE_ANIMATION_KEY)
end

function GameViewLayer:onResetData()
	self._cardLayer:onResetData()

	self.bChoosingHu = false
	self.cbOutCardTemp = 0
	self.cbAppearCardIndex = {}

	self.m_nLeftCard = 0

	self.TrustShadow:setVisible(false)

	self.nCardLeft = self.m_nAllCard
	self.labelCardLeft:setString(string.format("%d", self.nCardLeft))
	self:ShowGameBtn(GameLogic.WIK_NULL)

	for i=1,cmd.GAME_PLAYER do
		if nil ~=  self.m_tabUserHead[i] then
			self.m_tabUserHead[i]:showBank(false)
		end
	end

	self:showOutCard(nil, nil, false)
	self._cardLayer:onResetData()

	self:resetMagicInfo()
end

function GameViewLayer:onExit()
	print("GameViewLayer onExit")
	cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("gameScene.plist")
	cc.Director:getInstance():getTextureCache():removeTextureForKey("gameScene.png")
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()

    self.m_UserItem = {}
    AnimationMgr.removeCachedAnimation(cmd.VOICE_ANIMATION_KEY)
end

function GameViewLayer:getParentNode()
    return self._scene
end

local this
function GameViewLayer:ctor(scene)
	this = self
	self._scene = scene
	self:onInitData()
	self:preloadUI()
	self:initButtons()
	self:initUserInfo()
	self._cardLayer = CardLayer:create(self):addTo(self:getChildByName("Node_MaJong"))					--牌图层
	self._resultLayer = ResultLayer:create(self):addTo(self, GameViewLayer.ZORDER_RESULT):setVisible(false)	--结算框
    self._chatLayer = GameChatLayer:create(self._scene._gameFrame):addTo(self, GameViewLayer.ZORDER_CHAT)	--聊天框

    --左上角游戏信息
    --local CsbgameInfoNode = self:getChildByName("FileNode_info")

    --播放背景音乐
    if GlobalUserItem.bVoiceAble == true then  
        AudioEngine.playMusic("sound/backgroud.mp3", true)
	end

    self.gameInfoNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/NodeInfo.csb"):addTo(self, GameViewLayer.ZORDER_INFO)
    self.gameInfoNode:setPosition(cc.p(0, 750))

    --剩余牌数
    self.nCardLeft = 0
    self.labelCardLeft = self.gameInfoNode:getChildByName("AtlasLabel_1")
    self.labelCardLeft:setString(string.format("%d", self.nCardLeft))

    --指针
    self.userPoint = self:getChildByName("sp_clock")
    self.userPoint:setVisible(false)

    --倒计时
    self.labelClock = self.userPoint:getChildByName("AsLab_time")
    self.labelCardLeft:setString("00")

    --出牌界面
    self.sprOutCardBg = cc.Sprite:create(cmd.RES_PATH.."game/outCardBg.png"):addTo(self, GameViewLayer.ZORDER_OUTCARD)
    self.sprOutCardBg:setVisible(false)
    self.sprMajong = self._cardLayer:createMyActiveCardSprite(0x35, false):addTo(self.sprOutCardBg)
    self.sprMajong:setPosition(self.sprOutCardBg:getContentSize().width/2, self.sprOutCardBg:getContentSize().height/2)


    --荒庄图片
    self.sprNoWin = cc.Sprite:create(cmd.RES_PATH.."gameResult/huangzhuang.png"):addTo(self, GameViewLayer.ZORDER_RESULT)
    self.sprNoWin:setPosition(cc.p(667, 400))
    self.sprNoWin:setVisible(false)

    --准备按钮
   	local btnReady = ccui.Button:create(cmd.RES_PATH.."common/btn_start1.png", cmd.RES_PATH.."common/btn_start2.png",
		cmd.RES_PATH.."common/btn_start1.png")
	btnReady:addTo(self.sprNoWin)
	btnReady:setPosition(ccp(249, 80))

	--按钮回调
	local btnReadyCallback = function(ref, eventType)
		if eventType == ccui.TouchEventType.ended then
			-- 准备
			self._scene:sendGameStart()
			self:showNoWin(false)
			self:onResetData()
		end
	end

	btnReady:addTouchEventListener(btnReadyCallback)

	--准备状态
	local posACtion = 
	{
		cc.p(667, 230),
		cc.p(1085, 420),
		cc.p(260, 420),
		cc.p(667, 575)
	}
	self.readySpr = {}
	for i=1,cmd.GAME_PLAYER do
		local sprPath = nil
		if i == cmd.MY_VIEWID or i == cmd.TOP_VIEWID then
			sprPath = cmd.RES_PATH.."game/Ready_1.png"
		else
			sprPath = cmd.RES_PATH.."game/Ready_2.png"
		end
		local sprReady = ccui.ImageView:create(sprPath)
		sprReady:addTo(self)
		sprReady:setVisible(false)
		sprReady:setPosition(posACtion[i])
		table.insert(self.readySpr,sprReady)
	end

	--节点事件
	local function onNodeEvent(event)
		if event == "exit" then
			self:onExit()
		end
	end
	self:registerScriptHandler(onNodeEvent)


	--托管覆盖层
	self.TrustShadow = ccui.ImageView:create(cmd.RES_PATH.."game/btn_trustShadow.png")
	self.TrustShadow:addTo(self)
	self.TrustShadow:setTouchEnabled(true)
	self.TrustShadow:setPosition(cc.p(667, 100))
	self.TrustShadow:setVisible(false)
	--取消托管按钮
	local btnExitTrust = ccui.Button:create(cmd.RES_PATH.."game/btn_trustCancel1.png", cmd.RES_PATH.."game/btn_trustCancel2.png",
		cmd.RES_PATH.."game/btn_trustCancel1.png")
	btnExitTrust:addTo(self.TrustShadow)
	btnExitTrust:setPosition(ccp(1175, 62))
	--按钮回调
	local btnCallback = function(ref, eventType)
		if eventType == ccui.TouchEventType.ended then
			-- 取消托管
			self._scene:sendUserTrustee()
			self.TrustShadow:setVisible(false)
		end
	end
	btnExitTrust:addTouchEventListener(btnCallback)

	--玩家出牌
	self.spOutCardBg = cc.Sprite:create(cmd.RES_PATH.."game/outCardBg.png")
	self.spOutCardBg:addTo(self)
	self.spOutCardBg:setVisible(false)

	--玩家胡牌提示
	self.nodeTips = cc.Node:create()
	self.nodeTips:addTo(self, GameViewLayer.ZORDER_ACTION)
	self.nodeTips:setPosition(cc.p(667, 215))
end

function GameViewLayer:preloadUI()
    print("欢迎来到召唤师峡谷！")
    --导入动画
    local animationCache = cc.AnimationCache:getInstance()
    for i = 1, 12 do
    	local strColor = ""
    	local index = 0
    	if i <= 6 then
    		strColor = "white"
    		index = i
    	else
    		strColor = "red"
    		index = i - 6
    	end
		local animation = cc.Animation:create()
		animation:setDelayPerUnit(0.1)
		animation:setLoops(1)
		for j = 1, 9 do
			local strFile = cmd.RES_PATH.."Animate_sice_"..strColor..string.format("/sice_%d.png", index)
			local spFrame = cc.SpriteFrame:create(strFile, cc.rect(133*(j - 1), 0, 133, 207))
			animation:addSpriteFrame(spFrame)
		end

		local strName = "sice_"..strColor..string.format("_%d", index)
		animationCache:addAnimation(animation, strName)
	end
end

--初始化玩家信息
function GameViewLayer:initUserInfo()
	local nodeName = 
	{
		"FileNode_3",
		"FileNode_4",
		"FileNode_2",
		"FileNode_1",
	}

	local faceNode = self:getChildByName("Node_User")
	self.nodePlayer = {}
	for i = 1, cmd.GAME_PLAYER do
		self.nodePlayer[i] = faceNode:getChildByName(nodeName[i])
		self.nodePlayer[i]:setLocalZOrder(1)
		self.nodePlayer[i]:setVisible(true)
	end
end

--更新玩家准备状态
function GameViewLayer:showUserState(viewid, isReady)
	print("更新用户状态", viewid, isReady, #self.readySpr)
	local spr = self.readySpr[viewid]
	if nil ~= spr then
		spr:setVisible(isReady)
	end
end

--初始化界面上button
function GameViewLayer:initButtons()
	--按钮回调
	local btnCallback = function(ref, eventType)
		if eventType == ccui.TouchEventType.ended then
			self:onButtonClickedEvent(ref:getTag(), ref)
		elseif eventType == ccui.TouchEventType.began and ref:getTag() == GameViewLayer.BT_VOICE then
			--self:onButtonClickedEvent(GameViewLayer.BT_VOICEOPEN, ref)
		end
	end

	--桌子操作按钮屏蔽层
	--按钮背景
	local menuBg = self:getChildByName("sp_tableBtBg")
	local callbackShield = function(ref)
		local pos = ref:getTouchEndPosition()
        local rectBg = menuBg:getBoundingBox()
        if not cc.rectContainsPoint(rectBg, pos)then
        	self:showMenu(false)
        end
	end
	self.layoutShield = self:getChildByName("Image_Touch")
		:setTouchEnabled(false)
	self.layoutShield:addClickEventListener(callbackShield)

	--右上角按钮控制开关
	local btnMenu = self:getChildByName("bt_menu")
	btnMenu:addTouchEventListener(btnCallback)
	btnMenu:setTag(GameViewLayer.BT_MENU)

	local btSet = menuBg:getChildByName("bt_set")
	btSet:addTouchEventListener(btnCallback)
	btSet:setTag(GameViewLayer.CBX_SOUNDOFF)

	local btChat = menuBg:getChildByName("bt_chat")	--聊天
	btChat:setTag(GameViewLayer.BT_CHAT)
	btChat:addTouchEventListener(btnCallback)

	local btExit = menuBg:getChildByName("bt_exit")	--退出
	btExit:addTouchEventListener(btnCallback)
	btExit:setTag(GameViewLayer.BT_EXIT)

	local btTrustee = menuBg:getChildByName("bt_trustee")	--托管
	btTrustee:addTouchEventListener(btnCallback)
	btTrustee:setTag(GameViewLayer.BT_TRUSTEE)
	if GlobalUserItem.bPrivateRoom then
		btTrustee:setEnabled(false)
		--btTrustee:setColor(cc.c3b(158, 112, 8))
	end

	local btHowPlay = menuBg:getChildByName("bt_help")	--玩法
	btHowPlay:addTouchEventListener(btnCallback)
	btHowPlay:setTag(GameViewLayer.BT_HOWPLAY)

	--开始
	self.btStart = self:getChildByName("bt_start")
		:setLocalZOrder(2)
		:setVisible(false)
	self.btStart:addTouchEventListener(btnCallback)
	self.btStart:setTag(GameViewLayer.BT_START)

	-- 语音按钮 gameviewlayer -> gamelayer -> clientscene
    --self:getParentNode():getParentNode():createVoiceBtn(cc.p(1268, 212), 0, self)
	local btnVoice = ccui.Button:create(cmd.RES_PATH.."game/btn_voice1.png", cmd.RES_PATH.."game/btn_voice2.png",
		cmd.RES_PATH.."game/btn_voice2.png")
		:move(1268, 212)
		:addTo(self)
	btnVoice:setName(VOICE_BTN_NAME)
	btnVoice:addTouchEventListener(function(ref, eventType)
 		if eventType == ccui.TouchEventType.began then
 			self:getParentNode():getParentNode():startVoiceRecord()
        elseif eventType == ccui.TouchEventType.ended 
        	or eventType == ccui.TouchEventType.canceled then
        	self:getParentNode():getParentNode():stopVoiceRecord()
        end
	end)

	--游戏操作按钮
	--获取操作按钮node
	local nodeOpBar = self:getChildByName("FileNode_Op")
	--广东麻将只有4个，不同游戏自行添加
	local btGang = nodeOpBar:getChildByName("Button_gang") 	--杠
	btGang:setEnabled(false)
	btGang:addTouchEventListener(btnCallback)
	btGang:setTag(GameViewLayer.BT_GANG)

	local btPeng = nodeOpBar:getChildByName("Button_pen") 	--碰
	btPeng:setEnabled(false)
	btPeng:addTouchEventListener(btnCallback)
	btPeng:setTag(GameViewLayer.BT_PENG)

	local btHu = nodeOpBar:getChildByName("Button_hu") 	--胡
	btHu:setEnabled(false)
	btHu:addTouchEventListener(btnCallback)
	btHu:setTag(GameViewLayer.BT_HU)

	local btGuo = nodeOpBar:getChildByName("Button_guo") 	--过
	btGuo:setEnabled(false)
	btGuo:addTouchEventListener(btnCallback)
	btGuo:setTag(GameViewLayer.BT_GUO)
end

--按钮控制（下拉菜单下拉，隐藏语音按钮）
function GameViewLayer:showMenu(bVisible)
	--按钮背景
	local menuBg = self:getChildByName("sp_tableBtBg")
	if menuBg:isVisible() == bVisible then
		return false
	end

	local btnMenu = self:getChildByName("bt_menu")
	self.layoutShield:setTouchEnabled(bVisible)
	menuBg:setVisible(bVisible)

	--显示菜单按钮时，隐藏录音按钮
	local btnVoice = self:getChildByName(VOICE_BTN_NAME)
	btnVoice:setVisible(not bVisible)

	return true
end

--更新用户显示
function GameViewLayer:OnUpdateUser(viewId, userItem)
	if not viewId or viewId == yl.INVALID_CHAIR then
		print("OnUpdateUser viewId is nil")
		return
	end

	if nil == userItem then
        return
    end
    self.m_UserItem[viewId] = userItem

    local bReady = userItem.cbUserStatus == yl.US_READY
    --self:onUserReady(viewId, bReady)
    print("更新用户显示", self.m_tabUserHead[viewId])
    if nil == self.m_tabUserHead[viewId] then
        local playerInfo = PlayerInfo:create(userItem, viewId)
        self.m_tabUserHead[viewId] = playerInfo
        self.nodePlayer[viewId]:addChild(playerInfo)
    else
        self.m_tabUserHead[viewId].m_userItem = userItem
        self.m_tabUserHead[viewId]:updateStatus()
    end
    --判断房主
	if PriRoom and GlobalUserItem.bPrivateRoom then
		if userItem.dwUserID == PriRoom:getInstance().m_tabPriData.dwTableOwnerUserID then
			self.m_tabUserHead[viewId]:showRoomHolder(true)
		else
			self.m_tabUserHead[viewId]:showRoomHolder(false)
		end
	end
end

--玩家退出，移除头像信息
function GameViewLayer:OnUpdateUserExit(viewId)
	print("移除用户", viewId)
	if nil ~= self.m_tabUserHead[viewId] then
		self.m_tabUserHead[viewId] = nil  --退出依然保存信息
		self.nodePlayer[viewId]:removeAllChildren()
		self.m_UserItem[viewId] = nil
	end
end

-- 文本聊天
function GameViewLayer:onUserChat(chatdata, viewId)
    local playerItem = self.m_tabUserHead[viewId]
    print("获取当前显示聊天的玩家头像", playerItem, viewId, chatdata.szChatString)
    if nil ~= playerItem then
        playerItem:textChat(chatdata.szChatString)
        self._chatLayer:showGameChat(false)
    end
end

-- 表情聊天
function GameViewLayer:onUserExpression(chatdata, viewId)
    local playerItem = self.m_tabUserHead[viewId]
    if nil ~= playerItem then
        playerItem:browChat(chatdata.wItemIndex)
        self._chatLayer:showGameChat(false)
    end
end

--显示语音
function GameViewLayer:ShowUserVoice(viewid, isPlay)
	--取消文字，表情
	local playerItem = self.m_tabUserHead[viewid]
    if nil ~= playerItem then
    	if isPlay then
    		playerItem:onUserVoiceStart()
    	else
    		playerItem:onUserVoiceEnded()
    	end
    end
end

--按键事件
function GameViewLayer:onButtonClickedEvent(tag, ref)
	if tag == GameViewLayer.BT_START then
		print("麻将开始！")
		self.btStart:setVisible(false)
		self._scene:sendGameStart()
	elseif tag == GameViewLayer.BT_MENU then
		print("按钮开关")
		local menuBg = self:getChildByName("sp_tableBtBg")
		self:showMenu(not menuBg:isVisible())
	elseif tag == GameViewLayer.BT_CHAT then
		print("聊天！")
		self._chatLayer:showGameChat(true)
		self:showMenu(false)
	elseif tag == GameViewLayer.CBX_SOUNDOFF then
		print("设置开关！")
		local set = SettingLayer:create( self )
        self:addChild(set, GameViewLayer.ZORDER_SETTING)
	elseif tag == GameViewLayer.BT_HOWPLAY then
		print("玩法！")
		self._scene._scene:popHelpLayer2(391, 0)
        --self._scene._scene:popHelpLayer(yl.HTTP_URL .. "/Mobile/Introduce.aspx?kindid=391&typeid=0")
	elseif tag == GameViewLayer.BT_EXIT then
		print("退出！")
		self._scene:onQueryExitGame()
	elseif tag == GameViewLayer.BT_TRUSTEE then
		print("托管")
		self._scene:sendUserTrustee()
	elseif tag == GameViewLayer.BT_PENG then
		print("碰！")

		--发送碰牌
		local cbOperateCard = {self.cbActionCard, self.cbActionCard, self.cbActionCard}
		self._scene:sendOperateCard(GameLogic.WIK_PENG, cbOperateCard)

		self:ShowGameBtn(GameLogic.WIK_NULL)
	elseif tag == GameViewLayer.BT_GANG then
		print("杠！")
		local cbOperateCard = {self.cbActionCard, self.cbActionCard, self.cbActionCard}
		self._scene:sendOperateCard(GameLogic.WIK_GANG, cbOperateCard)

		self:ShowGameBtn(GameLogic.WIK_NULL)
	elseif tag == GameViewLayer.BT_HU then
		print("胡！")

		local cbOperateCard = {self.cbActionCard, 0, 0}
		self._scene:sendOperateCard(GameLogic.WIK_CHI_HU, cbOperateCard)

		self:ShowGameBtn(GameLogic.WIK_NULL)
	elseif tag == GameViewLayer.BT_GUO then
		print("过！")
		if not self.bListenBtnEnabled and
		not self._cardLayer.bChoosingOutCard and
		not self.bChoosingHu then
			local cbOperateCard = {0, 0, 0}
			self._scene:sendOperateCard(GameLogic.WIK_NULL, cbOperateCard)
		end

		self:ShowGameBtn(GameLogic.WIK_NULL)
	else
		print("default")
	end
end

--更新操作按钮状态
function GameViewLayer:ShowGameBtn(cbActionMask)
	--获取node
	local OpNode = self:getChildByName("FileNode_Op")
	local btGang = OpNode:getChildByName("Button_gang") 	--杠
	local btPeng = OpNode:getChildByName("Button_pen") 	--碰
	local btHu = OpNode:getChildByName("Button_hu") 	--胡
	local btGuo = OpNode:getChildByName("Button_guo") 	--过

	OpNode:setVisible(true)
	if cbActionMask == GameLogic.WIK_NULL then
		OpNode:setVisible(false)
		btGang:setEnabled(false)
		btPeng:setEnabled(false)
		btHu:setEnabled(false)
		btGuo:setEnabled(false)
		return
	end
	--通过动作码，判断操作按钮状态
	if bit:_and(cbActionMask, GameLogic.WIK_GANG) ~= GameLogic.WIK_NULL then
		btGang:setEnabled(true)
	end

	if bit:_and(cbActionMask, GameLogic.WIK_PENG) ~= GameLogic.WIK_NULL then
		btPeng:setEnabled(true)
	end

	if bit:_and(cbActionMask, GameLogic.WIK_CHI_HU) ~= GameLogic.WIK_NULL then
		btHu:setEnabled(true)
	end
	btGuo:setEnabled(true)
end

--玩家指向刷新
function GameViewLayer:OnUpdataClockPointView(viewId)
	local viewImage = 
	{
		cmd.RES_PATH.."game/point2.png",
		cmd.RES_PATH.."game/point3.png",
		cmd.RES_PATH.."game/point1.png",
		cmd.RES_PATH.."game/point4.png",
	}
	--print("指针文件路径", viewImage[viewId])
	if not viewId or viewId == yl.INVALID_CHAIR then
	    self.userPoint:setVisible(false)
	else
		--通过ID设置纹理
		local sprPoint = cc.Sprite:create(viewImage[viewId])
		if nil ~=  sprPoint then
			self.userPoint:setSpriteFrame(sprPoint:getSpriteFrame())
			self.userPoint:setVisible(true)
		end
	end
end

 --设置转盘时间
 function GameViewLayer:OnUpdataClockTime(time)
 	if 10 > time then
 		self.labelClock:setString(string.format("0%d", time))
 	else
 		self.labelClock:setString(string.format("%d", time))
 	end
 end

--刷新剩余牌数
function GameViewLayer:onUpdataLeftCard( numCard )
	 self.nCardLeft = numCard
	 self.labelCardLeft:setString(string.format("%d", self.nCardLeft))
end


--消息操作处理
function GameViewLayer:resetMagicInfo()
	local majongNode = self.gameInfoNode:getChildByName("magicBg_4")
	majongNode:setVisible(false)
	for i=1,2 do
		local card = majongNode:getChildByName(string.format("majongNode_%d", i))
		card:setVisible(false)
	end
end

--显示癞子信息
function GameViewLayer:onUpdataMagicCard( cbCardData, isAni ) --此处为索引
	if nil ~= cbCardData then
		--左上角游戏信息
    	--local gameInfoNode = self:getChildByTag(GameViewLayer.NODE_INFO_TAG)
    	local majongNode = self.gameInfoNode:getChildByName("magicBg_4")
    	if nil == majongNode then
    		return
    	end
		for i=1,#cbCardData do
			if 34 ~= cbCardData[i] then --无效值为34
				--majongNode:setVisible(true)
				--获取麻将
				local card = majongNode:getChildByName(string.format("majongNode_%d", i))
				if nil ~= card then
					--card:setVisible(true)
					--获取数值
					local cardIndex = cbCardData[i] +1
					local sprPath = cmd.RES_PATH.."card/my_small/tile_meUp_"
					if cardIndex < 10 then
						sprPath = sprPath..string.format("0%d", cardIndex)..".png"
					else
						sprPath = sprPath..string.format("%d", cardIndex)..".png"
					end
					local spriteValue = display.newSprite(sprPath)
					--获取精灵
					local sprCard = card:getChildByName("card_value")
					if nil ~= sprCard then
						sprCard:setSpriteFrame(spriteValue:getSpriteFrame())
					end

					local sprFlag = card:getChildByName("flag")
					if nil ~=  sprFlag then
						sprFlag:setVisible(true)
					end
					card:runAction(cc.Sequence:create(cc.DelayTime:create(3 *i), cc.Show:create()))

				end

				if isAni then --动画sortHandCard
					local cardData = GameLogic.SwitchToCardData(cbCardData[i] +1) --本地是1到34，服务器是0到33
					local cardMagic = self._cardLayer:createStandCardSprite(cmd.MY_VIEWID, cardData, true)
					if cardMagic then
						cardMagic:addTo(self)
						cardMagic:setPosition(cc.p(667, 450))
						cardMagic:setVisible(false)
						cardMagic:runAction(cc.Sequence:create(cc.DelayTime:create(3 *(i -1)), 
								cc.Show:create(), cc.DelayTime:create(2.5), cc.MoveTo:create(0.5, cc.p(70 +(i-1)*55, 705)), cc.CallFunc:create(function (node)
								node:removeFromParent()
								--刷新我的手牌
								self._cardLayer:sortHandCard(cmd.MY_VIEWID)
						end)))
					end
					--动画(第一个麻将飞过去后)
					majongNode:runAction(cc.Sequence:create(cc.DelayTime:create(3.2), cc.Show:create()))
				else
					--动画(立刻显示)
					majongNode:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.Show:create()))
				end
			end
		end
	end
end

--显示规则信息
function GameViewLayer:onshowRule( cellScore, cbMaCount, cbMagicMode, bQiangGangHu, bHuQiDui, bHaveZiCard ,bNoMagicDouble, cbMagicModel)
	--底注
	local labelCellScore = self.gameInfoNode:getChildByName("AtlasLabel_cellscore")
	local info_cellscore = self.gameInfoNode:getChildByName("info_cellscore_14")
	if nil ~= labelCellScore then
		labelCellScore:setVisible(true)
		info_cellscore:setVisible(true)
		labelCellScore:setString(string.format("%d", cellScore))
	end

	--马
	local labelMa = self.gameInfoNode:getChildByName("AtlasLabel_ma")
	local info_ma = self.gameInfoNode:getChildByName("info_ma_15")
	if nil ~= labelMa then
		labelMa:setVisible(true)
		info_ma:setVisible(true)
		labelMa:setString(string.format("%d", cbMaCount))
	end
	
	local strModel = 
	{
		"无鬼",
		"白板做鬼",
		"翻一鬼",
		"翻双鬼",
	}
	local labModel = self.gameInfoNode:getChildByName("Text_1")
	if nil ~= labModel then
		labModel:setString(strModel[cbMagicModel +1])
	end
	--鬼牌模式

	-- local pos = cc.p(175, -58)
	-- local ruleNum = 0   --选择规则个数
	-- if cbMagicMode == 0 then --无鬼
	-- 	pos = cc.p(20, -58)
	-- end

	-- --抢杠胡
	-- if bQiangGangHu then
	-- 	local info_Qianggang = self.gameInfoNode:getChildByName("info_Qianggang_3")
	-- 	if nil ~= info_Qianggang then 
	-- 		info_Qianggang:setVisible(true)
	-- 		info_Qianggang:setPosition(cc.p(pos.x +math.mod(ruleNum, 2) *107, pos.y -math.floor(ruleNum/2) *30))
	-- 		ruleNum = ruleNum +1
	-- 	end
	-- end
	-- --七对
	-- if bHuQiDui then
	-- 	local info_QiDui = self.gameInfoNode:getChildByName("info_Qidui_5")
	-- 	if nil ~= info_QiDui then 
	-- 		info_QiDui:setVisible(true)
	-- 		info_QiDui:setPosition(cc.p(pos.x +math.mod(ruleNum, 2) *107,pos.y -math.floor(ruleNum/2) *30))
	-- 		ruleNum = ruleNum +1
	-- 	end
	-- end
	-- --带风
	-- if bHaveZiCard then
	-- 	local info_Daizi = self.gameInfoNode:getChildByName("info_Daizi_1")
	-- 	if nil ~= info_Daizi then 
	-- 		info_Daizi:setVisible(true)
	-- 		info_Daizi:setPosition(cc.p(pos.x +math.mod(ruleNum, 2) *107,pos.y -math.floor(ruleNum/2) *30))
	-- 		ruleNum = ruleNum +1
	-- 	end
	-- end
	-- --无鬼翻倍
	-- if bNoMagicDouble then
	-- 	local info_NoMagicDouble = self.gameInfoNode:getChildByName("info_NoMagicDouble_2")
	-- 	if nil ~= info_NoMagicDouble then 
	-- 		info_NoMagicDouble:setVisible(true)
	-- 		info_NoMagicDouble:setPosition(cc.p(pos.x +math.mod(ruleNum, 2) *107,pos.y -math.floor(ruleNum/2) *30))
	-- 		ruleNum = ruleNum +1
	-- 	end
	-- end
end


--显示出牌
function GameViewLayer:showOutCard(viewid, value, isShow)
	if not isShow then
		self.sprOutCardBg:setVisible(false)
		return
	end

	if nil == value then  --无效值
		return
	end

	local posOurCard = 
	{
		cc.p(667, 230),
		cc.p(1085, 420),
		cc.p(260, 420),
		cc.p(667, 575)
	}
	print("玩家出牌， 位置，卡牌数值", viewid, value)
	self.sprOutCardBg:setVisible(isShow)
	self.sprOutCardBg:setPosition(posOurCard[viewid])
	--获取数值
	local cardIndex = GameLogic.SwitchToCardIndex(value)
	local sprPath = cmd.RES_PATH.."card/my_normal/tile_me_"
	if cardIndex < 10 then
		sprPath = sprPath..string.format("0%d", cardIndex)..".png"
	else
		sprPath = sprPath..string.format("%d", cardIndex)..".png"
	end
	local spriteValue = display.newSprite(sprPath)
	--获取精灵
	local sprCard = self.sprMajong:getChildByName("card_value")
	if nil ~= sprCard then
		sprCard:setSpriteFrame(spriteValue:getSpriteFrame())
	end
end

--用户操作动画
function GameViewLayer:showOperateAction(viewId, actionCode)
	-- body
	local posACtion = 
	{
		cc.p(667, 230),
		cc.p(1085, 420),
		cc.p(260, 420),
		cc.p(667, 575)
	}
	local strPath = ""
	if actionCode == GameLogic.WIK_PENG then
		strPath = strPath.."peng"
	end
	if actionCode == GameLogic.WIK_GANG then
		strPath = strPath.."gang"
	end
	if actionCode == GameLogic.WIK_CHI_HU then
		strPath = strPath.."hu"
	end

	local animation = cc.Animation:create()
	for i=1,9 do
		local strPath = cmd.RES_PATH.."game/".. strPath ..string.format("/%d.png", i)
		print("动画资源路径", strPath,  viewId, actionCode)
		local spriteFrame = cc.Sprite:create(strPath):getSpriteFrame()
		if spriteFrame then
			animation:addSpriteFrame(spriteFrame)
		else
			break
		end
		animation:setLoops(2)
		animation:setDelayPerUnit(0.1)
	end
	local animate = cc.Animate:create(animation)
	local spr = cc.Sprite:create(cmd.RES_PATH.."game/".. strPath ..string.format("/%d.png", 1))
	spr:addTo(self, GameViewLayer.ZORDER_ACTION)
	spr:setPosition(posACtion[viewId])
	spr:runAction(cc.Sequence:create(animate, cc.CallFunc:create(function()
			spr:removeFromParent()
		end)))
end

--用户胡牌提示 tagHuInfo
function GameViewLayer:showHuTips(cbHuInfo)
	local infoShow = 0
	local allCard = false
	local isTooMuchCard = false
	if #cbHuInfo == 34 then
		infoShow = 1
		allCard = true
	elseif #cbHuInfo > 7 then
		infoShow = #cbHuInfo
		isTooMuchCard = true
	else
		infoShow = #cbHuInfo
	end
	--判断个数奇
	local pos = cc.p(0, 0)
	if 0 == math.mod(infoShow, 2) then --偶数
		pos = cc.p(-90, 0)
	end
	if allCard then
		local huNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/Node_tips.csb")
		huNode:addTo(self.nodeTips)
		huNode:setPosition(pos)
	elseif isTooMuchCard then
		local huNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/Node_tips.csb")
		huNode:addTo(self.nodeTips)
		huNode:setPosition(pos)

		local tips_all = huNode:getChildByName("tips_all")
		if nil ~= tips_all then
			tips_all:setVisible(false)
		end

		--显示张数
		local node = huNode:getChildByName("Node_num")
		if nil ~= node then
			node:setVisible(true)
			--张数
			local num = node:getChildByName("label_num")
			if nil ~= num then
				num:setString(string.format("%d", infoShow))
			end
		end
	else
		for i=1, infoShow do
			local huNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/Node_tips.csb")
			huNode:addTo(self.nodeTips)
			print("用户胡牌提示1", pos.x, pos.y)
			local posTag = pos
			if 0 == math.mod(i, 2) then
				posTag = cc.p(pos.x +math.floor(i /2) *180, pos.y)
			else
				posTag = cc.p(pos.x -math.floor(i /2) *180, pos.y)
			end
			print("用户胡牌提示2", posTag.x, posTag.y)
			huNode:setPosition(posTag)

			--信息
			local huInfo = cbHuInfo[i]
			local tips_fan = huNode:getChildByName("tips_fan")
			if nil ~= tips_fan then
				tips_fan:setVisible(true)
			end
			local tips_huCardNum = huNode:getChildByName("tips_huCardNum")
			if nil ~= tips_huCardNum then
				tips_huCardNum:setVisible(true)
			end
			local tips_all = huNode:getChildByName("tips_all")
			if nil ~= tips_all then
				tips_all:setVisible(false)
			end
			local Node_Majong = huNode:getChildByName("Node_Majong")
			if nil ~= Node_Majong then
				Node_Majong:setVisible(true)
				--获取数值
				local cardIndex = GameLogic.SwitchToCardIndex(huInfo.cbCardValue)
				local sprPath = cmd.RES_PATH.."card/my_small/tile_meUp_"
				if cardIndex < 10 then
					sprPath = sprPath..string.format("0%d", cardIndex)..".png"
				else
					sprPath = sprPath..string.format("%d", cardIndex)..".png"
				end
				local spriteValue = display.newSprite(sprPath)
				--获取精灵
				local sprCard = Node_Majong:getChildByName("card_value")
				if nil ~= sprCard then
					sprCard:setSpriteFrame(spriteValue:getSpriteFrame())
				end
			end

			local label_Fan = huNode:getChildByName("label_Fan")
			if nil ~= label_Fan then
				label_Fan:setVisible(true)
				label_Fan:setString(string.format("%d", huInfo.cbFan))
			end
			local label_Num = huNode:getChildByName("label_Num")
			if nil ~= label_Num then
				label_Num:setVisible(true)
				label_Num:setString(string.format("%d", huInfo.cbNum))
			end
		end
	end
	
	
end

--用户摸马动画
function GameViewLayer:showMoMaAction(bankChair, huChair, viewId, maNum, maData, validMaNum, validMaData, endDelayTime)
	-- body
	--延时显示摸马
	local delayTime = 2.0
	if 0 ~= endDelayTime then
		delayTime = endDelayTime
	end

	local moMaNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/Node_moma.csb")
	moMaNode:addTo(self, GameViewLayer.ZORDER_RESULT +1)
	moMaNode:setPosition(cc.p(667, 400))
	moMaNode:setVisible(false)
	moMaNode:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime), cc.Show:create()))

	local userItem = self.m_tabUserHead[viewId].m_userItem
	--设置姓名
	local userName = moMaNode:getChildByName("Text_name")
	if nil ~= userName then
		local clipNick = ClipText:createClipText(cc.size(110, 20), userItem.szNickName)
	    clipNick:setAnchorPoint(cc.p(0.5, 0.5))
	    clipNick:setPosition(userName:getPosition())
	    moMaNode:addChild(clipNick)
	    clipNick:setTextColor(cc.c3b(0x00,0x93,0xFC))
		--userName:setString(userItem.szNickName)
		userName:setVisible(false)
	end
	--摸马倍数
	local MaNum = moMaNode:getChildByName("text_maNum")
	if nil ~= MaNum then --初始为0
		MaNum:setString("0")
		MaNum:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime + 1.0 *maNum), cc.CallFunc:create(function()
			MaNum:setString(string.format("%d", validMaNum))
		end)))
	end
	--摸马动画
	local cardNode = moMaNode:getChildByName("Node_majong")
	for i=1,maNum do
		--创建麻将
		local card = self._cardLayer:createMyActiveCardSprite(maData[i], false)
		card:addTo(cardNode)
		card:setVisible(false)
		card:setPosition(80 *(i -1), 0)
		-- if not self:isValidMa(bankChair, huChair, maData[i]) then
		-- 	card:setColor(cc.c3b(127,127,127))
		-- end
		--判断马牌
		local isValidMa = false
		for j=1,validMaNum do
			if maData[i] == validMaData[j] then
				isValidMa = true
				break
			end
		end
		if not isValidMa then
			card:setColor(cc.c3b(127,127,127))
		end

		card:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime +1.0 *(i -1)), cc.Show:create()))
	end
	moMaNode:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime +1.0 *maNum +2), cc.CallFunc:create(function()
			moMaNode:removeFromParent()
		end)))
end

--判断胡牌玩家是否买中了马
function GameViewLayer:isValidMa( bankChair, huChair, cardData )
	local MaData = 
	{
		{0x01, 0x05, 0x09, 0x11, 0x15, 0x19, 0x21, 0x25, 0x29, 0x31},
		{0x02, 0x06,  0x12, 0x16, 0x22, 0x26, 0x32, 0x35},
		{0x04, 0x08,  0x14, 0x18, 0x24, 0x28, 0x34, 0x37},
		{0x03, 0x07, 0x13, 0x17, 0x23, 0x27, 0x33, 0x36},
	}
	--转换
	local tag = yl.INVALID_CHAIR
    local nChairCount = 4--self._scene._gameFrame:GetChairCount()
 	 
 	 local right = bankChair +1
 	 right = right >= nChairCount and right - nChairCount or right
 	 local left  = bankChair -1
 	 left = left < 0 and left + nChairCount or left 
 	 local top = bankChair + 2
 	 top = top >= nChairCount and top - nChairCount or top

 	 if huChair == bankChair then
 	 	tag = cmd.MY_VIEWID
 	 elseif huChair == right then
 	 	tag = cmd.RIGHT_VIEWID
 	 elseif huChair == left then
 	 	tag = cmd.LEFT_VIEWID
 	 elseif huChair == top then
 	 	tag = cmd.TOP_VIEWID
 	 end
 	 for i=1,#MaData[tag] do
 	 	if cardData == MaData[tag][i] then
 	 		return true
 	 	end
 	 end
 	 return false
end

--显示荒庄
function GameViewLayer:showNoWin( isShow )
	self.sprNoWin:setVisible(isShow)
end

--开始
function GameViewLayer:gameStart(startViewId, cbCardData, cbCardCount, cbUserAction, cbMagicData)
	--每次发四张,第四次一张
	local viewid = startViewId
	local tableView = {1, 2, 4, 3} --对面索引为3
	local cardIndex = 1 --读取自己卡牌的索引
	local actionList = {}
	for i=1,4 do
		local cardCount = (i == 4 and 1 or 4)
		for k=1,cmd.GAME_PLAYER do

			if 5 == viewid then
				viewid = 1
			end
			local myCardDate = {}
			if viewid == cmd.MY_VIEWID  then
				for j=1,cardCount do
					print("开始发牌,我的卡牌", cardIndex, cbCardData[cardIndex])
					myCardDate[j] = cbCardData[cardIndex]
					cardIndex = cardIndex +1
				end
			end

			function callbackWithArgs(viewid, myCardDate, cardCount)
	              local ret = function ()
	              	self._cardLayer:sendCardToPlayer(viewid, myCardDate, cardCount)
	              	self:onUpdataLeftCard(self.nCardLeft - cardCount)
	              end
	              return ret
	        end
	        local callFun = cc.CallFunc:create(callbackWithArgs(tableView[viewid], myCardDate, cardCount))
	        table.insert(actionList, cc.DelayTime:create(0.5))
	        table.insert(actionList, callFun)
		    --如果是我要发卡牌信息过去
			viewid = viewid +1
		end
	end
	--发完手牌给庄家发牌
	local myCardDate = {}
	if startViewId == cmd.MY_VIEWID then
		myCardDate[1] = cbCardData[14]
		--如果我是庄家，允许触摸
		self._cardLayer:setMyCardTouchEnabled(true)
	end
	function callbackWithArgs(viewid, myCardDate, cardCount, cbUserAction, cbMagicData)
		local ret = function ()
			self:onUpdataLeftCard(self.nCardLeft - cardCount)
			self._cardLayer:sendCardToPlayer(viewid, myCardDate, cardCount)
			self:onUpdataMagicCard(cbMagicData, true)

			if viewid == cmd.MY_VIEWID then
				--判断有没有操作
				if cbUserAction ~= GameLogic.WIK_NULL then
					if bit:_and(GameLogic.WIK_GANG, cbUserAction) ~= GameLogic.WIK_NULL then
						local cardGang = self._scene:findUserGangCard(self._cardLayer.cbCardData[cmd.MY_VIEWID])
						if nil ~= cardGang[1] then
							self.cbActionMask = cbUserAction
							self.cbActionCard = cardGang[1]
							self:ShowGameBtn(cbUserAction)
						end
					else
						self:ShowGameBtn(cbUserAction)
					end
				end
			end
		end
		return ret
    end
	local callFun = cc.CallFunc:create(callbackWithArgs(startViewId, myCardDate, 1, cbUserAction, cbMagicData))
	table.insert(actionList, cc.DelayTime:create(0.5))
    table.insert(actionList, callFun)

	self:runAction(cc.Sequence:create(actionList))
end
--用户出牌
function GameViewLayer:gameOutCard(viewId, card, bIsSysOut)

	print("用户出牌", viewId, card)
	self:showOutCard(viewId, card, true) --展示出牌
	if viewId ~= cmd.MY_VIEWID then
		self._cardLayer:outCard(viewId, card)
	elseif self._scene.bTrustee or bIsSysOut then
		self._cardLayer:outCardTrustee(card)
	end

	self.cbOutCardTemp = card
	self.cbOutUserTemp = viewId
	--self._cardLayer:discard(viewId, card)
end
--用户抓牌
function GameViewLayer:gameSendCard(viewId, card)
	--发牌
	if viewId == cmd.MY_VIEWID then
		self._cardLayer:setMyCardTouchEnabled(true)
	end
	self:onUpdataLeftCard(self.nCardLeft - 1)
	self._cardLayer:sendCardToPlayer(viewId, {card}, 1)
end

return GameViewLayer