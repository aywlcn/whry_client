local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")

local GameLayer = class("GameLayer", GameModel)

local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.GameLogic")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.views.layer.GameViewLayer")
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function GameLayer:ctor(frameEngine, scene)
    GameLayer.super.ctor(self, frameEngine, scene)
end

function GameLayer:CreateView()
    return GameViewLayer:create(self):addTo(self)
end

function GameLayer:getParentNode()
    return self._scene
end

--设置私有房的层级
function GameLayer:addPrivateGameLayer( layer )
    if nil == layer then
        return
    end
        self._gameView:addChild(layer, 40)
end

function GameLayer:OnInitGameEngine()
	self.cbTimeOutCard = 20
	self.cbTimeOperateCard = 20
	self.cbTimeStartGame = 30
	self.wCurrentUser = yl.INVALID_CHAIR
	self.wBankerUser = yl.INVALID_CHAIR
	self.cbPlayStatus = {0, 0, 0, 0}

	self.bTrustee = false
	self.m_bOnGame = false

	self.myChirID = yl.INVALID_CHAIR

	--红中癞子标识
	self.m_bHongZhong = false
	
	self.cbOutCardData = {}
	self.cbActionMask = nil
	self.cbLeftCardCount = 0

	--房卡需要
	self.m_sparrowUserItem = {}
	self.wRoomHostViewId = 0

	--约战结算标识
	self.m_bPriEnd = false
	print("Hello Hello!")
end

function GameLayer:OnResetGameEngine()
    GameLayer.super.OnResetGameEngine(self)
    self._gameView:onResetData()
	self.bTrustee = false
	self.cbActionMask = nil

	--红中癞子标识
	self.m_bHongZhong = false
end

--获取gamekind
function GameLayer:getGameKind()
    return cmd.KIND_ID
end

function GameLayer:onExitRoom()
    self._gameFrame:onCloseSocket()
    self:stopAllActions()
    self:KillGameClock()
    self:dismissPopWait()
    --self._scene:onChangeShowMode(yl.SCENE_ROOMLIST)
    self._scene:onKeyBack()
end

-- 椅子号转视图位置,注意椅子号从0~nChairCount-1,返回的视图位置从1~nChairCount
function GameLayer:SwitchViewChairID(chair)
    local viewid = yl.INVALID_CHAIR
    local nChairCount = self._gameFrame:GetChairCount()
    --nChairCount = cmd.zhzmj_GAME_PLAYER
    local myChairID = self:GetMeChairID()
 	 
 	 local right = myChairID +1
 	 right = right >= nChairCount and right - nChairCount or right
 	 local left  = myChairID -1
 	 left = left < 0 and left + nChairCount or left 
 	 local top = myChairID + 2
 	 top = top >= nChairCount and top - nChairCount or top

 	 ---------------------测试两人对面坐
 	 if nChairCount == 2 then
		 if chair == myChairID then
		 	return cmd.MY_VIEWID
		 elseif chair == right then
		 	return cmd.TOP_VIEWID
		 end
 	 end

 	 ----------------------


 	 print("获取转换后的位置ID nChairCount chair, myChairID, right, top, left",nChairCount, chair, myChairID, right, top, left)
 	 if chair == myChairID then
 	 	return cmd.MY_VIEWID
 	 elseif chair == right then
 	 	return cmd.RIGHT_VIEWID
 	 elseif chair == left then
 	 	return cmd.LEFT_VIEWID
 	 elseif chair == top then
 	 	return cmd.TOP_VIEWID
 	 end
end

function GameLayer:getRoomHostViewId()
	return self.wRoomHostViewId
end

function GameLayer:getUserInfoByChairID(chairId)
	return self.m_sparrowUserItem[chairId + 1]
end

function GameLayer:onGetSitUserNum()
	local num = 0
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		if nil ~= self._gameView.m_tabUserHead[i] then
			num = num + 1
		end
	end
    return num
end

function GameLayer:onEnterTransitionFinish()
    GameLayer.super.onEnterTransitionFinish(self)
end

-- 计时器响应
function GameLayer:OnEventGameClockInfo(chair,time,clockId)
    self._gameView.labelClock:setVisible(true)
    print("clockId", clockId)
    print("chair", chair)
    print("time", time)

    --设置转盘时间
    self._gameView:OnUpdataClockTime(time)

	if GlobalUserItem.bPrivateRoom then
    	return
    end
    -- body
    --print("更新中间指针， 位置， 时间", chair, time)

    local meChairId = self:SwitchViewChairID(self:GetMeChairID())
    if clockId == cmd.IDI_START_GAME then
    	--托管
    	--超时
		if time <= 0 then
			self._gameFrame:setEnterAntiCheatRoom(false)--退出防作弊，如果有的话
		elseif time <= 5 then
    		self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
		end
    elseif clockId == cmd.IDI_OUT_CARD then
    	if chair == meChairId then
    		--托管.
    		--超时
    		if time <= 0 then
    			self._gameView:ShowGameBtn(GameLogic.WIK_NULL)
				self:sendUserTrustee()
    		elseif time <= 5 then
    			self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
    		end
    	end
    elseif clockId == cmd.IDI_OPERATE_CARD then
    	if chair == meChairId then
    		--超时
    		if time <= 0 then
    			--放弃，进入托管,隐藏操作按钮
    			self._gameView:ShowGameBtn(GameLogic.WIK_NULL)
    			self:sendUserTrustee()
    		elseif time <= 5 then
    			self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
    		end
    	end
    end
end

--用户聊天
function GameLayer:onUserChat(chat, wChairId)
	print("玩家聊天", chat.szChatString)
    self._gameView:onUserChat(chat, self:SwitchViewChairID(wChairId))
end

--用户表情
function GameLayer:onUserExpression(expression, wChairId)
    self._gameView:onUserExpression(expression, self:SwitchViewChairID(wChairId))
end

-- 语音播放开始
function GameLayer:onUserVoiceStart( useritem, filepath )
	print("GameLayer:onUserVoiceStart", viewid)
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    if viewid and viewid ~= yl.INVALID_CHAIR then
        self._gameView:ShowUserVoice(viewid, true)
    end
end

-- 语音播放结束
function GameLayer:onUserVoiceEnded( useritem, filepath )
	print("GameLayer:onUserVoiceEnded")
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    if viewid and viewid ~= yl.INVALID_CHAIR then
        self._gameView:ShowUserVoice(viewid, false)
    end
end


--用户状态
function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)

    print("change user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
    if newstatus.cbUserStatus == yl.US_FREE or newstatus.cbUserStatus == yl.US_NULL then

	    if (oldstatus.wTableID ~= self:GetMeUserItem().wTableID) then
	        return
	    end

        if yl.INVALID_CHAIR ==  useritem.wChairID then
        	print("查找人数",#self._gameView.m_UserItem)
        	for i=1, 4 do
	        	if self._gameView.m_UserItem[i] and self._gameView.m_UserItem[i].dwUserID == useritem.dwUserID then
	        		print("查找",#self._gameView.m_UserItem, useritem.szNickName, self._gameView.m_UserItem[i].szNickName)

	        		if self.m_bPriEnd == false then
	        			self._gameView:OnUpdateUserExit(i)
	        		end
	        		self._gameView:showUserState(i, false)
	        	end
        	end
        else
        	local wViewChairId = self:SwitchViewChairID(useritem.wChairID)
        	if self.m_bPriEnd == false then
        		self._gameView:OnUpdateUserExit(wViewChairId)
        	end
        	print("删除", wViewChairId)

        	self._gameView:showUserState(wViewChairId, false)
        end
   
    else
    	if (newstatus.wTableID ~= self:GetMeUserItem().wTableID) then
	        return
	    end
	    local wViewChairId = self:SwitchViewChairID(useritem.wChairID)
	    if newstatus.cbUserStatus == yl.US_READY then
            self._gameView:showUserState(wViewChairId, true)
        end
        self.m_sparrowUserItem[useritem.wChairID +1] = useritem
        --刷新用户信息
        if useritem == self:GetMeUserItem() then
            return
        end
        --先判断是否是换桌
        print("更新新玩家", wViewChairId, useritem)
    	self._gameView:OnUpdateUser(wViewChairId, useritem)
    end    
end

--用户进入
function GameLayer:onEventUserEnter(tableid,chairid,useritem)

    print("the table id is ================ >"..tableid)

  --刷新用户信息
    if useritem == self:GetMeUserItem() or tableid ~= self:GetMeUserItem().wTableID then
        return
    end
    local wViewChairId = self:SwitchViewChairID(useritem.wChairID)
    self.m_sparrowUserItem[useritem.wChairID +1] = useritem
    self._gameView:OnUpdateUser(wViewChairId, userItem)
    if useritem.cbUserStatus == yl.US_READY then
        self._gameView:showUserState(wViewChairId, true)
    end
end


--用户分数
function GameLayer:onEventUserScore( item )
    if item.wTableID ~= self:GetMeUserItem().wTableID then
       return
    end
    --self._gameView:updateScore(item)
end

--查找可以杠的牌
function GameLayer:findUserGangCard(cbCardData)
	local card = {}
	for i=1,#cbCardData do
		local cardNum = 0
		local cardValue = cbCardData[i]
		for j=i,#cbCardData do
			if cardValue == cbCardData[j] then
				cardNum = cardNum +1
			end
		end
		if 4 == cardNum then
			table.insert(card, cardValue)
		end
	end
	return card
end

-- 场景消息
function GameLayer:onEventGameScene(cbGameStatus, dataBuffer)
	if self.m_bOnGame then
        return
    end

    print("onEventGameScene1")

    self.m_cbGameStatus = cbGameStatus
    self.m_bOnGame = true
    --初始化已有玩家
    for i = 1, cmd.zhzmj_GAME_PLAYER do
        local userItem = self._gameFrame:getTableUserItem(self._gameFrame:GetTableID(), i-1)
        if nil ~= userItem then
            local wViewChairId = self:SwitchViewChairID(i-1)
            self.m_sparrowUserItem[i] = userItem
            self._gameView:OnUpdateUser(wViewChairId, userItem)
            if userItem.cbUserStatus == yl.US_READY then
        		self._gameView:showUserState(wViewChairId, true)
        	else
        		self._gameView:showUserState(wViewChairId, false)
    		end
            if PriRoom then
                PriRoom:getInstance():onEventUserState(wViewChairId, userItem, false)
            end
        end
    end

    print("onEventGameScene2")

	if cbGameStatus == cmd.zhzmj_GAME_SCENE_FREE then
		print("onEventGameScene2.1")
		self:onGameSceneFree(dataBuffer)
	elseif cbGameStatus == cmd.zhzmj_GAME_SCENE_PLAY then
		print("onEventGameScene2.2")
		self:onGameScenePlay(dataBuffer)
	else
		print("onEventGameScene2.3")
		print("\ndefault\n")
		return false
	end

	print("onEventGameScen3")

    -- 刷新房卡
    if PriRoom and GlobalUserItem.bPrivateRoom then
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
            self._gameView._priView:onRefreshInfo()
        end
    end

	self:dismissPopWait()

	return true
end
function GameLayer:onGameSceneFree(dataBuffer)
		print("空闲状态")
		local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusFree, dataBuffer)
		dump(cmd_data, "空闲状态")

		--防作弊不显示
		if not GlobalUserItem.isAntiCheat() then 
			self._gameView.btStart:setVisible(true)
		end

		--更新红中标识
        self._gameView:setCardLaiZiFlag(cmd.bHongZhong)

        --红中癞子标识
		self.m_bHongZhong = cmd.bHongZhong

		self._gameView.clockdirBg:setVisible(true)
		local wMyChairId = self:GetMeChairID()
		self:SetGameClock(self:SwitchViewChairID(wMyChairId), cmd.IDI_START_GAME, self.cbTimeStartGame)

		--指针指向
    	self._gameView:OnUpdataClockPointView(self:SwitchViewChairID(wMyChairId))

    	if GlobalUserItem.bSoundAble == true then
        	AudioEngine.playMusic("sound/backgroud.mp3", true)
        end
end

function GameLayer:onGameScenePlay(dataBuffer)
	print("游戏状态")
	--准备不显示
	for i=1,cmd.zhzmj_GAME_PLAYER do
		self._gameView:showUserState(i, false)
	end

	--激活托管
	self._gameView:EnableTrustee(true)

	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusPlay, dataBuffer)
	dump(cmd_data.WeaveItemArray, "WeaveItemArray")
	dump(cmd_data.cbWeaveCount, "cbWeaveCount")
	dump(cmd_data.cbCardData, "cbCardData")

	self.wCurrentUser = cmd_data.wCurrentUser
	self.wBankerUser = cmd_data.wBankerUser

	--更新红中标识
    self._gameView:setCardLaiZiFlag(cmd_data.bHongZhong)

    --红中癞子标识
	self.m_bHongZhong = cmd_data.bHongZhong

    self._gameView.clockdirBg:setVisible(true)

	--游戏配置
	if cmd_data.bHongZhong == true then
		GameLogic:SetMagicIndex(GameLogic:SwitchToCardIndex(0x35))
	end

	self.cbLeftCardCount = cmd_data.cbLeftCardCount

	--庄家self.cbMagicData
	local wViewBankerUser = self:SwitchViewChairID(self.wBankerUser)
	self._gameView.m_tabUserHead[wViewBankerUser]:showBank(true)

	--剩余牌数
	self._gameView:onUpdataLeftCard(self.cbLeftCardCount)

	--先设置已经出的牌
	for i=1,cmd.zhzmj_GAME_PLAYER do
		local wViewChairId = self:SwitchViewChairID(i - 1)
		if cmd_data.cbWeaveCount[1][i] > 0 then
			for j = 1, cmd_data.cbWeaveCount[1][i] do
				local cbOperateData = {} --此处为tagAvtiveCard
				cbOperateData.cbCardValue = cmd_data.WeaveItemArray[i][j].cbCardData[1]
				dump(cbOperateData.cbCardValue, "已经出的牌")
				local nShowStatus = GameLogic.SHOW_NULL
				local cbParam = cmd_data.WeaveItemArray[i][j].cbWeaveKind
				if cbParam == GameLogic.WIK_PENG then
					nShowStatus = GameLogic.SHOW_PENG   --碰
					cbOperateData.cbCardNum = 3
				elseif cbParam == GameLogic.WIK_GANG then  --杠
					if cmd_data.WeaveItemArray[i][j].cbPublicCard == 1 then
						nShowStatus = GameLogic.SHOW_MING_GANG 
						cbOperateData.cbCardNum = 4
					elseif cmd_data.WeaveItemArray[i][j].cbPublicCard == 0 then
						nShowStatus = GameLogic.SHOW_AN_GANG
						cbOperateData.cbCardNum = 4
					end
				end
				cbOperateData.cbType = nShowStatus

				self._gameView._cardLayer:createActiveCardReEnter(wViewChairId, cbOperateData)
			end
		end
	end

	--设置手牌
	local viewCardCount = {}
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		local viewId = self:SwitchViewChairID(i - 1)

		if viewId ~= nil then
			print("viewId", viewId)

			local cardcount = 0
			for j=1, cmd.zhzmj_MAX_INDEX do
				if cmd_data.cbCardIndex[i][j] ~= 0 then
					cardcount = cardcount + cmd_data.cbCardIndex[i][j]
				end
			end

			viewCardCount[viewId] = cardcount
			if viewCardCount[viewId] > 0 then
				self.cbPlayStatus[viewId] = 1
			end
		end		
	end
	local cbHandCardData = {}
	for i = 1, viewCardCount[cmd.MY_VIEWID] do
		local data = cmd_data.cbCardData[1][i]
		table.insert(cbHandCardData, data)
	end
	local cbSendCard = cmd_data.cbSendCardData
	if cbSendCard > 0 and self.wCurrentUser == wMyChairId then
		for i = 1, #cbHandCardData do
			if cbHandCardData[i] == cbSendCard then
				table.remove(cbHandCardData, i)				--把刚抓的牌放在最后
				break
			end
		end
		table.insert(cbHandCardData, cbSendCard)
	end

	--dump(cbHandCardData, "我的手牌")
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		local userItem = self._gameFrame:getTableUserItem(self:GetMeTableID(), i - 1)
		if userItem ~= nil then
			local wViewChairId = self:SwitchViewChairID(i - 1)
			if wViewChairId == cmd.MY_VIEWID then
				self._gameView._cardLayer:createHandCard(wViewChairId, cbHandCardData, viewCardCount[wViewChairId], cmd_data.bHongZhong)
			else
				self._gameView._cardLayer:createHandCard(wViewChairId, nil, viewCardCount[wViewChairId], cmd_data.bHongZhong)
			end
		end

	end

	--设置已经出的牌
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		local viewId = self:SwitchViewChairID(i - 1)
		local cbOutCardData = {}
		for j = 1, cmd_data.cbDiscardCount[1][i] do
			--已出的牌
			cbOutCardData[j] = cmd_data.cbDiscardCard[i][j]
		end
		self._gameView._cardLayer:createOutCard(viewId, cbOutCardData, cmd_data.cbDiscardCount[1][i])
	end

	--托管判断
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		--self._gameView:setUserTrustee(viewId, cmd_data.bTrustee[1][i])
		if viewId == cmd.MY_VIEWID then
			self.bTrustee = cmd_data.bTrustee[1][i]
			if self.bTrustee then --显示托管界面
				self._gameView.TrustShadow:setVisible(true)
			end
		end
	end

	--刚出的牌
	if cmd_data.cbOutCardData and cmd_data.cbOutCardData > 0 then
		local wOutUserViewId = self:SwitchViewChairID(cmd_data.wOutCardUser)
		self._gameView:showOutCard(wOutUserViewId, cmd_data.cbOutCardData, true)
	end

	--计时器
	self:SetGameClock(self:SwitchViewChairID(self.wCurrentUser), cmd.IDI_OUT_CARD, self.cbTimeOutCard)
	--指针指向
    self._gameView:OnUpdataClockPointView(self:SwitchViewChairID(self.wCurrentUser))

	--允许操作操作
	if self.wCurrentUser == self:GetMeChairID() then
		self._gameView._cardLayer:setMyCardTouchEnabled(true)
		self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_OUTCARD)
	else
		self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_WAIT)
	end

	--操作提示
	print("断线重连玩家碰杠信息", self.bTrustee, cmd_data.cbActionMask)
	if not self.bTrustee then
		--如果我可以操作，显示操作栏
		if GameLogic.WIK_NULL ~=  cmd_data.cbActionMask then
			if bit:_and(GameLogic.WIK_GANG, cmd_data.cbActionMask) ~= GameLogic.WIK_NULL then
				local cardGang = self:findUserGangCard(self._gameView._cardLayer.cbCardData[cmd.MY_VIEWID])
				if nil ~= cardGang[1] then
					self._gameView.cbActionCard = cardGang[1]
					self.cbActionMask = cmd_data.cbActionMask
					self.cbActionCard = cardGang[1]
					self._gameView:ShowGameBtn(cmd_data.cbActionMask)
				end
			else
				self._gameView:ShowGameBtn(cmd_data.cbActionMask)
				self._gameView.cbActionCard = cmd_data.cbOutCardData
				self.cbActionMask = cmd_data.cbActionMask
				self.cbActionCard = cmd_data.cbOutCardData
			end
		end
	end
end

-- 游戏消息
function GameLayer:onEventGameMessage(sub, dataBuffer)
    -- body
    self.m_cbGameStatus = cmd.zhzmj_GAME_SCENE_PLAY
	if sub == cmd.zhzmj_SUB_S_GAME_START then 					--游戏开始
		return self:onSubGameStart(dataBuffer)
	elseif sub == cmd.zhzmj_SUB_S_OUT_CARD then 				--用户出牌
		return self:onSubOutCard(dataBuffer)
	elseif sub == cmd.zhzmj_SUB_S_SEND_CARD then 				--发送扑克
		return self:onSubSendCard(dataBuffer)
	elseif sub == cmd.zhzmj_SUB_S_OPERATE_NOTIFY then 			--操作提示
		return self:onSubOperateNotify(dataBuffer)
	elseif sub == cmd.zhzmj_SUB_S_OPERATE_RESULT then 			--操作命令
		return self:onSubOperateResult(dataBuffer)
	elseif sub == cmd.zhzmj_SUB_S_TRUSTEE then 					--用户托管
		return self:onSubTrustee(dataBuffer)
	elseif sub == cmd.zhzmj_SUB_S_GAME_END then 					--游戏结束
		return self:onSubGameEnd(dataBuffer)
	else
		assert(false, "default")
	end

	return false
end

--游戏开始
function GameLayer:onSubGameStart(dataBuffer)
	--游戏开始音效
	self:PlaySound(cmd.RES_PATH.."sound/GAME_START.wav")

	--禁用退出按钮到发完牌才激活
	self._gameView:EnableExit(false)

	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameStart, dataBuffer)

	--更新红中标识
	self._gameView:setCardLaiZiFlag(cmd_data.bHongZhong)

	self.m_bHongZhong = cmd_data.bHongZhong

	--游戏配置
	if cmd_data.bHongZhong == true then
		GameLogic:SetMagicIndex(GameLogic:SwitchToCardIndex(0x35))
	end

	--准备不显示
	for i=1, cmd.zhzmj_GAME_PLAYER do
		self._gameView:showUserState(i, false)
	end

	-- 刷新房卡
    if PriRoom and GlobalUserItem.bPrivateRoom then
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
        	PriRoom:getInstance().m_tabPriData.dwPlayCount = PriRoom:getInstance().m_tabPriData.dwPlayCount + 1
            self._gameView._priView:onRefreshInfo()
        end
    end

    --摇筛子开始
 	--剩余张数
	self._gameView:onUpdataLeftCard(cmd_data.cbLeftCardCount + self._gameFrame:GetChairCount() * 13 + 1)

	self.wBankerUser = cmd_data.wBankerUser
	local wViewBankerUser = self:SwitchViewChairID(self.wBankerUser)

	local cbCardCount = {0, 0, 0, 0}
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		local userItem = self._gameFrame:getTableUserItem(self:GetMeTableID(), i - 1)
		self.m_sparrowUserItem[i] = userItem
		local wViewChairId = self:SwitchViewChairID(i - 1)
		self._gameView:OnUpdateUser(wViewChairId, userItem)
		if userItem then
			self.cbPlayStatus[wViewChairId] = 1
			cbCardCount[wViewChairId] = 13
			if wViewChairId == wViewBankerUser then
				cbCardCount[wViewChairId] = cbCardCount[wViewChairId] + 1
			end
		end
	end

	--开始发牌
	local cbMagicIndex = nil
	if cmd_data.bHongZhong == true then
		cbMagicIndex = 0x35
	end

	self._gameView:gameStart(wViewBankerUser, cmd_data.cbCardData[1], cbCardCount, cmd_data.cbUserAction, cbMagicIndex, cmd_data.cbSick[1])
end


--用户出牌
function GameLayer:onSubOutCard(dataBuffer)
	print("用户出牌")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_OutCard, dataBuffer)
	dump(cmd_data, "CMD_S_OutCard")

	local wViewId = self:SwitchViewChairID(cmd_data.wOutCardUser)
	self._gameView:gameOutCard(wViewId, cmd_data.cbOutCardData)

	self:PlaySound(cmd.RES_PATH.."sound/OUT_CARD.wav")
	self:playCardDataSound(cmd_data.wOutCardUser, cmd_data.cbOutCardData)

	--转盘指向下一个
	self.wCurrentUser = cmd_data.wOutCardUser
	local wTurnUser = self.wCurrentUser
	while true do
		wTurnUser = (wTurnUser + 1) % cmd.zhzmj_GAME_PLAYER
		if self._gameFrame:getTableUserItem(self:GetMeTableID(), wTurnUser) ~= nil then
			break
		end
	end

	print("wTurnUser", wTurnUser)
	local wViewTurnUser = self:SwitchViewChairID(wTurnUser)
	--设置时间
	self:SetGameClock(wViewTurnUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard)

	--指针指向
    self._gameView:OnUpdataClockPointView(wViewTurnUser)
	return true
end

--发送扑克(抓牌)
function GameLayer:onSubSendCard(dataBuffer)
	print("发送扑克")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_SendCard, dataBuffer)
	--dump(cmd_data, "CMD_S_SendCard")

	self.wCurrentUser = cmd_data.wCurrentUser
	local wCurrentViewId = self:SwitchViewChairID(self.wCurrentUser)
	self._gameView:gameSendCard(wCurrentViewId, cmd_data.cbCardData)

	self:PlaySound(cmd.RES_PATH.."sound/SEND_CARD.wav")

	self:SetGameClock(wCurrentViewId, cmd.IDI_OUT_CARD, self.cbTimeOutCard)

	--指针指向
    self._gameView:OnUpdataClockPointView(wCurrentViewId)

	--如果我可以操作，显示操作栏
	if GameLogic.WIK_NULL ~=  cmd_data.cbActionMask and self.wCurrentUser == self:GetMeChairID()then
		if bit:_and(GameLogic.WIK_GANG, cmd_data.cbActionMask) ~= GameLogic.WIK_NULL then
			local cardGang = self:findUserGangCard(self._gameView._cardLayer.cbCardData[cmd.MY_VIEWID])
			if nil ~= cardGang[1] then --暗杠
				self._gameView.cbActionCard = cardGang[1]
				self.cbActionMask = cmd_data.cbActionMask
				self.cbActionCard = cardGang[1]
				self._gameView:ShowGameBtn(cmd_data.cbActionMask)
			else --明杠
				self._gameView:ShowGameBtn(cmd_data.cbActionMask)
				self._gameView.cbActionCard = cmd_data.cbCardData
				self.cbActionMask = cmd_data.cbActionMask
				self.cbActionCard = cmd_data.cbCardData
			end
		else
			self._gameView:ShowGameBtn(cmd_data.cbActionMask)
			self._gameView.cbActionCard = cmd_data.cbCardData
			self.cbActionMask = cmd_data.cbActionMask
			self.cbActionCard = cmd_data.cbCardData
		end
	end

	return true
end

--操作提示
function GameLayer:onSubOperateNotify(dataBuffer)
	print("操作提示")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_OperateNotify, dataBuffer)
	dump(cmd_data, "CMD_S_OperateNotify")

	--当前用户
	if self:GetMeChairID() == cmd_data.wCurrentUser then
		self._gameView:ShowGameBtn(cmd_data.cbActionMask)
		self._gameView.cbActionCard = cmd_data.cbActionCard

		self.cbActionMask = cmd_data.cbActionMask
		self.cbActionCard = cmd_data.cbActionCard
	else
		self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_WAIT)
	end
		
	--删除定时器
	self:KillGameClock()

	--当一方打出的牌其他方有操作的时候，箭头指向供应方,但是实际定时器还是有操作的玩家
	local wCurrentViewId = self:SwitchViewChairID(cmd_data.wCurrentUser)
	self:SetGameClock(wCurrentViewId, cmd.IDI_OPERATE_CARD, self.cbTimeOperateCard)

	--指针指向供应方
    self._gameView:OnUpdataClockPointView(self:SwitchViewChairID(cmd_data.wProvideUser))

	return true
end

--操作结果
function GameLayer:onSubOperateResult(dataBuffer)
	print("操作结果")

	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_OperateResult, dataBuffer)
	dump(cmd_data, "CMD_S_OperateResult")
	if cmd_data.cbOperateCode == GameLogic.WIK_NULL then
		assert(false, "没有操作也会进来？")
		return true
	end

	local wOperateViewId = self:SwitchViewChairID(cmd_data.wOperateUser)
	local wProvideViewId = self:SwitchViewChairID(cmd_data.wProvideUser)
	local tagAvtiveCard = {}
	tagAvtiveCard.cbType = GameLogic.SHOW_NULL
	print("操作的麻将玩家", wOperateViewId, wProvideViewId)
	print("操作的命令", cmd_data.cbOperateCode)
	if cmd_data.cbOperateCode == GameLogic.WIK_GANG then
		--暗杠标识
		local bAnGangCard = true
		for i=1,#self._gameView._cardLayer.cbActiveCardData[wOperateViewId] do
			--查找是否已经碰
			local activeInfo = self._gameView._cardLayer.cbActiveCardData[wOperateViewId][i]
			if activeInfo.cbCardValue[1] == cmd_data.cbOperateCard[1][1] and activeInfo.cbType == GameLogic.SHOW_PENG then --有碰
				bAnGangCard = false
			end
		end

		--存在组合牌明杠
		if bAnGangCard == false then
			tagAvtiveCard.cbType = GameLogic.SHOW_MING_GANG
		else
			--手牌有3张，别家打出一张为明杠
			if wOperateViewId ~= wProvideViewId then
				tagAvtiveCard.cbType = GameLogic.SHOW_MING_GANG
			else -- 自己手牌3张，摸了一张为暗杠
				tagAvtiveCard.cbType = GameLogic.SHOW_AN_GANG
			end
		end

		--tagAvtiveCard.cbType = (bAnGangCard == true and GameLogic.SHOW_AN_GANG or GameLogic.SHOW_MING_GANG)
		tagAvtiveCard.cbCardNum = 4
		tagAvtiveCard.cbCardValue = cmd_data.cbOperateCard[1]
		--再加一个
		tagAvtiveCard.cbCardValue[4] = cmd_data.cbOperateCard[1][1]
		print("操作的麻将信息", tagAvtiveCard.cbType, tagAvtiveCard.cbCardNum, tagAvtiveCard.cbCardValue[1])
	end
	
	if cmd_data.cbOperateCode == GameLogic.WIK_PENG then
		tagAvtiveCard.cbType = GameLogic.SHOW_PENG
		print("操作的命令tagAvtiveCard ", tagAvtiveCard.cbType)
		tagAvtiveCard.cbCardNum = 3
		tagAvtiveCard.cbCardValue = cmd_data.cbOperateCard[1]
		--再加一个
		tagAvtiveCard.cbCardValue[3] = cmd_data.cbOperateCard[1][1]
	end
	-- 显示操作动作
	print("createActiveCardbHongZhong", self.m_bHongZhong)
	self._gameView._cardLayer:createActiveCard(wOperateViewId, tagAvtiveCard, wProvideViewId, self.m_bHongZhong)

	self._gameView:showOperateAction(wOperateViewId, cmd_data.cbOperateCode)
	self:playCardOperateSound(cmd_data.wOperateUser, false, cmd_data.cbOperateCode)

	self:SetGameClock(wOperateViewId, cmd.IDI_OPERATE_CARD, self.cbTimeOperateCard)
	--指针指向
    self._gameView:OnUpdataClockPointView(wOperateViewId)

	if cmd_data.wOperateUser == self:GetMeChairID() then
		self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_OUTCARD)
	end

	return true
end

--用户托管
function GameLayer:onSubTrustee(dataBuffer)
	print("用户托管")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_Trustee, dataBuffer)

	local wViewChairId = self:SwitchViewChairID(cmd_data.wChairID)
	if cmd_data.wChairID == self:GetMeChairID() then
		self.bTrustee = cmd_data.bTrustee
		self._gameView.TrustShadow:setVisible(self.bTrustee)
	end

	return true
end

--游戏结束
function GameLayer:onSubGameEnd(dataBuffer)
	print("游戏结束")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameEnd, dataBuffer)

	local winchairid = 0
	local resultList = {}
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		local viewid = self:SwitchViewChairID(i - 1)
		local result = {}

		--昵称
		local useritem = self._gameFrame:getTableUserItem(self:GetMeTableID(), i - 1)
		result.useritem = useritem
		result.sznickname = (useritem == nil and "" or useritem.szNickName)
		result.score = cmd_data.lGameScore[1][i]

		if result.score > 0 then
			winchairid = i
		end
		result.bBanker = (self:SwitchViewChairID(self.wBankerUser) == viewid)
		result.enFlag = self._gameView._resultLayer.kFlagDefault
		result.lGangCount = cmd_data.lGangCount[1][i]

		--插入
		table.insert(resultList, result)
	end

	--抓鸟个数
	local nzhuoniaocount = 0

	if cmd_data.bZhuaNiao then
		for i=1 ,6  do
		    if cmd_data.cbZhuaNiaoCardArray[1][i] ~= 0 then
		        nzhuoniaocount = nzhuoniaocount + 1
		    end
    	end
	end

    print("resultList", cmd_data.wProvideUser)
    local resultbuf = ""
    local m_enFlag = 0
    if cmd_data.wProvideUser ~= yl.INVALID_CHAIR and cmd_data.wLeftUser == yl.INVALID_CHAIR then
        --放炮
        if cmd_data.wProvideUser ~= cmd_data.wCurrentIdx then       
            m_enFlag = self._gameView._resultLayer.kFangPao

            resultList[cmd_data.wProvideUser + 1].enFlag = self._gameView._resultLayer.kFangPao

            local resultdescrip = ""
            if cmd_data.cbChiHuType == GameLogic.CHR_PU_TONG then
                resultdescrip = "普通胡"
            elseif cmd_data.cbChiHuType == GameLogic.CHR_PENG_PENG then
                resultdescrip = "碰碰胡"
            elseif cmd_data.cbChiHuType == GameLogic.CHR_QI_DUI then
                resultdescrip = "七对胡"
            elseif cmd_data.cbChiHuType == GameLogic.CHR_SI_HONG_ZHONG then
                resultdescrip = "四红中胡"
            end

            resultbuf = string.format("抓%d鸟 ", nzhuoniaocount)..string.format("放炮 %s", resultdescrip)
        --自摸
        else
            m_enFlag = self._gameView._resultLayer.kZiMo
            resultList[cmd_data.wProvideUser + 1].enFlag = self._gameView._resultLayer.kZiMo

            local resultdescrip = ""
            if cmd_data.cbChiHuType == GameLogic.CHR_PU_TONG then
                resultdescrip = "普通胡"
            elseif cmd_data.cbChiHuType == GameLogic.CHR_PENG_PENG then
                resultdescrip = "碰碰胡"
            elseif cmd_data.cbChiHuType == GameLogic.CHR_QI_DUI then
                resultdescrip = "七对胡"
            elseif cmd_data.cbChiHuType == GameLogic.CHR_SI_HONG_ZHONG then
                resultdescrip = "四红中胡"
            end

            resultbuf = string.format("抓%d鸟 ", nzhuoniaocount)..string.format("自摸 %s", resultdescrip)
        end

    --荒庄
    elseif cmd_data.wProvideUser == yl.INVALID_CHAIR and cmd_data.wLeftUser == yl.INVALID_CHAIR then
        m_enFlag = self._gameView._resultLayer.kFlagHuangzZhuang

        --游戏结束
        self:PlaySound(cmd.RES_PATH.."sound/ZIMO_WIN.wav")
    --逃跑
    elseif cmd_data.wProvideUser == yl.INVALID_CHAIR and cmd_data.wLeftUser ~= yl.INVALID_CHAIR then
        m_enFlag = self._gameView._resultLayer.kTaoPao

        --游戏结束
        self:PlaySound(cmd.RES_PATH.."sound/ZIMO_WIN.wav")
    end

    print("resultbuf11", resultbuf)
	print("m_enFlag11", m_enFlag)
	LogAsset:getInstance():logData("resultbuf11",true)
	LogAsset:getInstance():logData("m_enFlag11",true)
    self._gameView._resultLayer:showLayer(resultList, resultbuf, m_enFlag)

    --玩家牌
    local resultCardList = {}
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		local viewid = self:SwitchViewChairID(i - 1)
		local useritem = self._gameFrame:getTableUserItem(self:GetMeTableID(), i - 1)
		
		local resultCard = {}

		resultCard.viewid = viewid
		resultCard.useritem = useritem
		--碰杠组合牌
		resultCard.cbActiveCardData = self._gameView._cardLayer.cbActiveCardData[viewid]
		
		--玩家手牌
		print("cbCardCount", cmd_data.cbCardCount[1][i])
		dump(value, desciption, nesting)
		resultCard.cbCardData = {}

		for j = 1, cmd_data.cbCardCount[1][i] do
			resultCard.cbCardData[j] = cmd_data.cbCardData[i][j]
			print("resultCard.cbCardData", cmd_data.cbCardData[i][j])
		end

		--玩家手牌张数
		resultCard.cbCardCount = cmd_data.cbCardCount[1][i]

		--供应牌
		resultCard.cbProvideCard = cmd_data.cbProvideCard

		--插入
		table.insert(resultCardList, resultCard)
	end
	LogAsset:getInstance():logData("addCards",true)

	if self._gameView._resultLayer:isVisible() then
		LogAsset:getInstance():logData("_resultLayerVisible",true)
	else
		LogAsset:getInstance():logData("_resultLayerInVisible",true)
	end
	print("addCards", winchairid)
	self._gameView._resultLayer:addCards(resultCardList, winchairid)

	if cmd_data.bZhuaNiao then
		local cbZhuaNiaoCard = {}
		for i=1, 6 do
			cbZhuaNiaoCard[i] = cmd_data.cbZhuaNiaoCardArray[1][i]
		end

		self._gameView._resultLayer:addZhuoNiaoCards(cbZhuaNiaoCard)
	end

	self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_BLANK)

	--禁用托管
	self._gameView:EnableTrustee(false)

	self:KillGameClock()

	return true
end

--*****************************    普通函数     *********************************--
--播放麻将数据音效（哪张）
function GameLayer:playCardDataSound(chairID, cbCardData)
	local strGender = ""
	if self._gameFrame:getTableUserItem(self:GetMeTableID(), chairID) == 1 then
		strGender = "1"
	else
		strGender = "0"
	end
	local color = {"0_", "1_", "2_", "3_"}
	local nCardColor = math.floor(cbCardData/16) + 1
	local nValue = math.mod(cbCardData, 16)

	local strFile = cmd.RES_PATH.."sound/"..strGender.."/"..color[nCardColor]..nValue..".wav"
	self:PlaySound(strFile)
end
--播放麻将操作音效
function GameLayer:playCardOperateSound(chairID, bTail, operateCode)
	assert(operateCode ~= GameLogic.WIK_NULL)

	local strGender = ""
	if self._gameFrame:getTableUserItem(self:GetMeTableID(), chairID) == 1 then
		strGender = "1"
	else
		strGender = "0"
	end
	local strName = ""
	if bTail then
		strName = "REPLACE.wav"
	else
		if operateCode >= GameLogic.WIK_CHI_HU then
			strName = "action_64.wav"
		elseif operateCode == GameLogic.WIK_LISTEN then
			strName = "TING.wav"
		elseif operateCode == GameLogic.WIK_GANG then
			strName = "action_16.wav"
		elseif operateCode == GameLogic.WIK_PENG then
			strName = "action_8.wav"
		elseif operateCode <= GameLogic.WIK_RIGHT then
			strName = "action_1.wav"
		end
	end
	local strFile = cmd.RES_PATH.."sound/"..strGender.."/"..strName
	self:PlaySound(strFile)
end

--*****************************    发送消息     *********************************--

--开始游戏
function GameLayer:sendGameStart()
	self:SendUserReady()
	self:OnResetGameEngine()

	--删除时钟
	self:KillGameClock()
	--self._gameView.clockdirBg:setVisible(false)

	self._gameView.labelClock:setVisible(false)
end

--出牌
function GameLayer:sendOutCard(card)
	-- body

	self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_BLANK)

	print("发送出牌：", card)
	local cmd_data = ExternalFun.create_netdata(cmd.CMD_C_OutCard)
	cmd_data:pushbyte(card)
	return self:SendData(cmd.zhzmj_SUB_C_OUT_CARD, cmd_data)
end
--操作扑克
function GameLayer:sendOperateCard(cbOperateCode, cbOperateCard)
	print("发送操作提示：", cbOperateCode, table.concat(cbOperateCard, ","))
	assert(type(cbOperateCard) == "table")

	--听牌数据置空
    local cmd_data = CCmd_Data:create(4)
	cmd_data:pushbyte(cbOperateCode)
	for i = 1, 3 do
		cmd_data:pushbyte(cbOperateCard[i])
	end
	--dump(cmd_data, "operate")
	self:SendData(cmd.zhzmj_SUB_C_OPERATE_CARD, cmd_data)
end

--用户托管
function GameLayer:sendUserTrustee()
	local cmd_data = CCmd_Data:create(1)
	cmd_data:pushbool(not self.bTrustee)
	self:SendData(cmd.zhzmj_SUB_C_TRUSTEE, cmd_data)
end

function GameLayer:DispatchFinish()
	if self.wBankerUser ~= yl.INVALID_CHAIR then
		local wViewBankerUser = self:SwitchViewChairID(self.wBankerUser)
		self:SetGameClock(wViewBankerUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard)
		--指针指向
    	self._gameView:OnUpdataClockPointView(wViewBankerUser)
	end

	if self:GetMeChairID() == self.wBankerUser then
		self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_OUTCARD)
	else
		self._gameView._gameEffectLayer:showGameTip(self._gameView._gameEffectLayer.kGAME_TIP_WAIT)
	end

	--激活托管
	self._gameView:EnableTrustee(true)

	--禁用退出按钮到发完牌才激活
	self._gameView:EnableExit(true)
end

return GameLayer