local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.CMD_Game")

local GameViewLayer = class("GameViewLayer",function(scene)
	print("kevin1")
	local gameViewLayer =  cc.CSLoader:createNode(cmd.RES_PATH.."game/GameScene.csb")
	print("kevin2")
    return gameViewLayer
end)

require("client/src/plaza/models/yl")
local PopupInfoHead = appdf.req("client.src.external.PopupInfoHead")
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.GameLogic")
local CardLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.views.layer.CardLayer")
local ResultLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.views.layer.ResultLayer")
local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")
local PlayerInfo = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.views.layer.PlayerInfo")
local SettingLayer = appdf.req(appdf.GAME_SRC .. "yule.sparrowzz.src.views.layer.SettingLayer")
local GameEffectLayer = appdf.req(appdf.GAME_SRC .. "yule.sparrowzz.src.views.layer.GameEffectLayer")

local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. "AnimationMgr")
local VOICE_BTN_NAME = "__voice_record_button__"  --语音按钮名字，可以获取语音按钮，控制显示与否

GameViewLayer.BT_MENU				= 10 				--按钮开关按钮
GameViewLayer.BT_CHAT 				= 11				--聊天按钮
GameViewLayer.CBX_SOUNDOFF 			= 13				--声音开关
GameViewLayer.BT_EXIT	 			= 14				--退出按钮
GameViewLayer.BT_TRUSTEE 			= 15				--托管按钮
GameViewLayer.BT_HOWPLAY 			= 16				--玩法按钮
GameViewLayer.BT_START 				= 20				--开始按钮
GameViewLayer.BT_CLOSERESULTLAYER 	= 21				--关闭结算层按钮

GameViewLayer.BT_GANG 				= 31				--游戏操作按钮杠
GameViewLayer.BT_PENG				= 32				--游戏操作按钮碰
GameViewLayer.BT_HU 				= 33				--游戏操作按钮胡
GameViewLayer.BT_GUO				= 34				--游戏操作按钮过

GameViewLayer.DICE_ZORDER = 7
GameViewLayer.ZORDER_OUTCARD = 40
GameViewLayer.ZORDER_EFFECT = 50
GameViewLayer.ZORDER_ACTION = 51
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

	--红中癞子标识
	self.m_bHongZhong = false

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

	for i=1,cmd.zhzmj_GAME_PLAYER do
		if nil ~=  self.m_tabUserHead[i] then
			self.m_tabUserHead[i]:showBank(false)
		end
	end

	self:showOutCard(nil, nil, false)
	self._cardLayer:onResetData()

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

	self:initUserInfo()
	self._cardLayer = CardLayer:create(self):addTo(self:getChildByName("Node_MaJong"))					--牌图层
	self._resultLayer = ResultLayer:create(self):addTo(self, GameViewLayer.ZORDER_RESULT):setVisible(false)	--结算框
    self._chatLayer = GameChatLayer:create(self._scene._gameFrame):addTo(self, GameViewLayer.ZORDER_CHAT)	--聊天框

    --设置麻将层级，由于可以拖动出牌，设置高一些
    --self:getChildByName("Node_MaJong"):setLocalZOrder(101)

    self:initButtons()

    self._gameEffectLayer = GameEffectLayer:create(self)
    self._gameEffectLayer:setVisible(false)
    self:addChild(self._gameEffectLayer, GameViewLayer.ZORDER_EFFECT)

    --左上角游戏信息
    --local CsbgameInfoNode = self:getChildByName("FileNode_info")

    self.gameInfoNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/NodeInfo.csb"):addTo(self, GameViewLayer.ZORDER_INFO)
    self.gameInfoNode:setPosition(cc.p(0, 750))

    --剩余牌数
    self.nCardLeft = 0
    self.labelCardLeft = self.gameInfoNode:getChildByName("AtlasLabel_1")
    self.labelCardLeft:setString(string.format("%d", self.nCardLeft))

    --中间时钟背景
    self.clockdirBg = self:getChildByName("sp_clock")
    self.clockdirBg:setVisible(false)

    --方向
    self.arrowDir = 
    {
    	self.clockdirBg:getChildByName("sp_dir_1"),
    	self.clockdirBg:getChildByName("sp_dir_2"),
    	self.clockdirBg:getChildByName("sp_dir_3"),
    	self.clockdirBg:getChildByName("sp_dir_4"),
	}

    --倒计时
    self.labelClock = self.clockdirBg:getChildByName("AsLab_time")
    self.labelCardLeft:setString("00")

    --出牌界面
    self.sprOutCardBg = cc.Sprite:create(cmd.RES_PATH.."game/outCardBg.png"):addTo(self, GameViewLayer.ZORDER_OUTCARD)
    self.sprOutCardBg:setVisible(false)
    --self.sprOutCardBg:setLocalZOrder(102)
    self.sprMajong = self._cardLayer:createMyActiveCardSprite(0x35, false):addTo(self.sprOutCardBg)
    self.sprMajong:setPosition(self.sprOutCardBg:getContentSize().width/2, self.sprOutCardBg:getContentSize().height/2)

    --准备按钮
   	local btnReady = ccui.Button:create(cmd.RES_PATH.."common/btn_start1.png", cmd.RES_PATH.."common/btn_start2.png",
		cmd.RES_PATH.."common/btn_start1.png")
	--btnReady:addTo(self.sprNoWin)
	btnReady:setPosition(ccp(249, 80))

	--按钮回调
	local btnReadyCallback = function(ref, eventType)
		if eventType == ccui.TouchEventType.ended then
			-- 准备
			self._scene:sendGameStart()
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
	for i=1,cmd.zhzmj_GAME_PLAYER do
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
end

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
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		self.nodePlayer[i] = faceNode:getChildByName(nodeName[i])
		self.nodePlayer[i]:setLocalZOrder(1)
		self.nodePlayer[i]:setVisible(true)
	end
end

function GameViewLayer:showUserState(viewid, isReady)
	print("更新用户状态", viewid, isReady, #self.readySpr)
	local spr = self.readySpr[viewid]
	if nil ~= spr then
		spr:setVisible(isReady)
	end
end

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
	menuBg:setTouchEnabled(true)
	menuBg:setSwallowTouches(true)
	local callbackShield = function(ref)
		local pos = ref:getTouchEndPosition()
        local rectBg = menuBg:getBoundingBox()
        if not cc.rectContainsPoint(rectBg, pos)then
        	self:showMenu(false)
        end
	end
	self.layoutShield = self:getChildByName("Image_Touch"):setTouchEnabled(false)
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
	btTrustee:setEnabled(false)

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
    self:getParentNode():getParentNode():createVoiceBtn(cc.p(1268, 212), 0, self)

	--游戏操作按钮
	--获取操作按钮node
	local nodeOpBar = self:getChildByName("FileNode_Op")
	nodeOpBar:setLocalZOrder(GameViewLayer.ZORDER_ACTION)

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

    print("GameViewLayer:onUserChat", playerItem, viewId)

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
	print("GameViewLayer:ShowUserVoice", playerItem, viewid)
    if nil ~= playerItem then
    	if isPlay then
    		playerItem:onUserVoiceStart()
    	else
    		playerItem:onUserVoiceEnded()
    	end
    end

    print("GameViewLayer 1 2 3 4", self.m_tabUserHead[1], self.m_tabUserHead[2], self.m_tabUserHead[3], self.m_tabUserHead[4])
    
end

function GameViewLayer:onButtonClickedEvent(tag, ref)
	if tag == GameViewLayer.BT_START then
		print("麻将开始！")

		--隐藏箭头
		for i=1, 4 do
			self.arrowDir[i]:setVisible(false)
			self.arrowDir[i]:stopAllActions()
		end
		self.btStart:setVisible(false)
		self._scene:sendGameStart()
	elseif tag == GameViewLayer.BT_CLOSERESULTLAYER then
		--self.labelCardLeft:setString("00")
		self:OnUpdataClockPointView(self._scene:SwitchViewChairID(self._scene:GetMeChairID()))
		self._scene:OnResetGameEngine()
		self._scene:SetGameClock(self._scene:SwitchViewChairID(self._scene:GetMeChairID()), cmd.IDI_START_GAME, self._scene.cbTimeStartGame)
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
		self._scene:KillGameClock()
		self._scene:onQueryExitGame()
	elseif tag == GameViewLayer.BT_TRUSTEE then
		print("托管")

		--隐藏动作面板
		self:ShowGameBtn(GameLogic.WIK_NULL)
		self._scene:sendUserTrustee()
		self:showMenu(false)
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
	--隐藏箭头
	for i=1, 4 do
		self.arrowDir[i]:setVisible(false)
		self.arrowDir[i]:stopAllActions()
	end

	if viewId ~= nil and viewId ~= yl.INVALID_CHAIR then
		self.arrowDir[viewId]:setVisible(true)
		self.arrowDir[viewId]:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeTo:create(0.5, 128), cc.FadeTo:create(0.5, 256))))
	end
end

 --设置转盘时间
 function GameViewLayer:OnUpdataClockTime(time)
 	if 10 > time then
 		self.labelClock:setString(string.format("0%d", time))
 	elseif time > 0 then
 		self.labelClock:setString(string.format("%d", time))
 	end
 end

--刷新剩余牌数
function GameViewLayer:onUpdataLeftCard( numCard )
	 self.nCardLeft = numCard
	 self.labelCardLeft:setString(string.format("%d", self.nCardLeft))
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
	for i=1,12 do
		local strPath = cmd.RES_PATH.."game/".. strPath ..string.format("/%d.png", i)
		print("动画资源路径", strPath,  viewId, actionCode)
		local spriteFrame = cc.Sprite:create(strPath):getSpriteFrame()
		if spriteFrame then
			animation:addSpriteFrame(spriteFrame)
		else
			break
		end
		animation:setLoops(2)
		animation:setDelayPerUnit(0.05)
	end
	local animate = cc.Animate:create(animation)
	local spr = cc.Sprite:create(cmd.RES_PATH.."game/".. strPath ..string.format("/%d.png", 1))
	spr:addTo(self, GameViewLayer.ZORDER_ACTION)
	spr:setPosition(posACtion[viewId])
	spr:runAction(cc.Sequence:create(animate, cc.CallFunc:create(function()
			spr:removeFromParent()
		end)))
end

--开始
function GameViewLayer:gameStart(startViewId, cbCardData, cbCardCount, cbUserAction, cbMagicData, sice)
	--筛子动画
	self:showDice(sice[1], true)
    self:showDice(sice[2], false)

	self:runAction(cc.Sequence:create(cc.DelayTime:create(2),cc.CallFunc:create(function ()
		self:removeChildByTag(1111)
		self:removeChildByTag(1111)
		self.m_tabUserHead[startViewId]:showBank(true)

		local cbPlayercount = self._scene._gameFrame:GetChairCount()

		--每次发四张,第四次一张
		local viewid = startViewId
		local tableView = (cbPlayercount == 4 and {1, 2, 4, 3} or {1, 2, 3, 4}) --对面索引为3
		local cardIndex = 1 --读取自己卡牌的索引
		local actionList = {}

		for i=1, 4 do
			local cardCount = (i == 4 and 1 or 4)

			for i=1, cmd.zhzmj_GAME_PLAYER do
				if 5 == viewid then
					viewid = 1
				end

				print("viewid11 = ", viewid);
				local chairid = self:getChairID(viewid)
				print("chairid = ", chairid);

				local userItem = self._scene._gameFrame:getTableUserItem(self._scene:GetMeTableID(), chairid)
				print("userItem = ", userItem);
				repeat
				    if userItem == nil then
				    	viewid = viewid +1
				        break
				    end

				    local myCardDate = {}
					if viewid == cmd.MY_VIEWID  then
						for j=1,cardCount do
							print("开始发牌,我的卡牌", cardIndex, cbCardData[cardIndex])
							myCardDate[j] = cbCardData[cardIndex]
							cardIndex = cardIndex +1
						end
					end

					print("viewid22 = ", viewid);

					function callbackWithArgs(viewid, myCardDate, cardCount)
			              local ret = function ()
			              	self._cardLayer:sendCardToPlayer(viewid, myCardDate, cardCount, self.m_bHongZhong)
			              	self:onUpdataLeftCard(self.nCardLeft - cardCount)
			              end
			              return ret
			        end

			        local callFun = cc.CallFunc:create(callbackWithArgs(tableView[viewid], myCardDate, cardCount))
			        table.insert(actionList, cc.DelayTime:create(0.5))
			        table.insert(actionList, callFun)
				    --如果是我要发卡牌信息过去
					viewid = viewid +1

				until true
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
				self._cardLayer:sendCardToPlayer(viewid, myCardDate, cardCount, self.m_bHongZhong)

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

		local callDispatch = cc.CallFunc:create(function () self._scene:DispatchFinish()
			end)

		table.insert(actionList, callDispatch)
		self:runAction(cc.Sequence:create(actionList))
	end)))
end

function GameViewLayer:showDice(num, bfirst)

    local frames = {}
    for i=1,31 do
      local frame = cc.SpriteFrame:create("game/SICK"..num..".png",cc.rect(70*(i-1),0,70,128))
      table.insert(frames, frame)
    end

    local  animation =cc.Animation:createWithSpriteFrames(frames,0.05)

    local sprite = cc.Sprite:createWithSpriteFrame(cc.SpriteFrame:create("game/SICK"..num..".png",cc.rect(0,0,70,128)))
    
    sprite:runAction(cc.Animate:create(animation))
    sprite:setTag(1111)
    
    if bfirst then
    	sprite:setPosition(605, 255)
    else
    	sprite:setPosition(605 + 120, 255)
    end

    --sprite:setPosition(545+math.random(230),255+math.random(150))
    sprite:setLocalZOrder(self.DICE_ZORDER)
    self:addChild(sprite) 

end

--用户出牌
function GameViewLayer:gameOutCard(viewId, card)

	print("用户出牌", viewId, card)
	self:showOutCard(viewId, card, true) --展示出牌
	if viewId ~= cmd.MY_VIEWID then
		self._cardLayer:outCard(viewId, card, self.m_bHongZhong)
	elseif self._scene.bTrustee then
		self._cardLayer:outCardTrustee(card, self.m_bHongZhong)
	end

	self.cbOutCardTemp = card
	self.cbOutUserTemp = viewId
	--self._cardLayer:discard(viewId, card)
end
--用户抓牌
function GameViewLayer:gameSendCard(viewId, card)
	--把上一个人打出的牌丢入弃牌堆
	if viewId == cmd.MY_VIEWID then
		--如果我是庄家，允许触摸
		self._cardLayer:setMyCardTouchEnabled(true)
		self._gameEffectLayer:showGameTip(self._gameEffectLayer.kGAME_TIP_OUTCARD)
	else
		self._gameEffectLayer:showGameTip(self._gameEffectLayer.kGAME_TIP_BLANK)
	end

	self:onUpdataLeftCard(self.nCardLeft - 1)

	self._cardLayer:sendCardToPlayer(viewId, {card}, 1, self.m_bHongZhong)
end

--设置红中癞子标识
function GameViewLayer:setCardLaiZiFlag(bHongZhong)
	self.m_bHongZhong = bHongZhong
end

--获取chairID
function GameViewLayer:getChairID(ViewId)
	for i=1, cmd.zhzmj_GAME_PLAYER do
		if self._scene:SwitchViewChairID(i - 1) == ViewId then
			return i - 1
		end
	end

	return 0xffff
end

--激活托管
function GameViewLayer:EnableTrustee(bEnableTrustee)
	local menuBg = self:getChildByName("sp_tableBtBg")
	local btTrustee = menuBg:getChildByName("bt_trustee")

	--私人房禁用托管
	if GlobalUserItem.bPrivateRoom then
		btTrustee:setEnabled(false)
	else
		btTrustee:setEnabled(bEnableTrustee)
	end
end

--激活退出
function GameViewLayer:EnableExit(bEnableExit)
	local menuBg = self:getChildByName("sp_tableBtBg")
	local btexit = menuBg:getChildByName("bt_exit")
	btexit:setEnabled(bEnableExit)
end

return GameViewLayer