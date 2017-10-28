local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")

local GameLayer = class("GameLayer", GameModel)

local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.models.CMD_Game")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.models.GameLogic")
local GameViewLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowgdex.src.views.layer.GameViewLayer")
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
	self.lCellScore = 0
	self.cbTimeOutCard = 0
	self.cbTimeOperateCard = 0
	self.cbTimeStartGame = 0
	self.cbTimeWaitEnd = 0
	self.wCurrentUser = yl.INVALID_CHAIR
	self.wBankerUser = yl.INVALID_CHAIR
	self.cbPlayStatus = {0, 0, 0, 0}
	self.cbGender = {0, 0, 0, 0}
	self.bListening = false
	self.bTrustee = false
	self.m_bOnGame = false

	self.isMyProvideUser = false  --我是操作提供者，这样不进入托管

	self.myChirID = yl.INVALID_CHAIR
	-- self.cbListenPromptOutCard = {}
	-- self.cbListenCardList = {}
	-- self.cbHuFanList = {}

	self.cbOutCardData = {}
	self.cbHuCardCount = {}
	self.cbHuCardData = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
	self.cbHuCardRemainingCount = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}
	self.cbHuFan = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}}

	self.cbActionMask = nil
	self.bSendCardFinsh = true
	self.lDetailScore = {}
	self.m_userRecord = {}

	--规则
	self.cbPlayerCount = 4
	self.cbMaCount = 0
	self.cbMagicMode = 0
	self.bQiangGangHu = false
	self.bHuQiDui = false
	self.bHaveZiCard = false
	self.bNoMagicDouble = false


	self.cbAllCardCount = cmd.MAX_REPERTORY
	self.cbLeftCardCount = 0
	--房卡需要
	self.m_sparrowUserItem = {}
	self.wRoomHostViewId = 0
	print("Hello Hello!")
end

function GameLayer:OnResetGameEngine()
    GameLayer.super.OnResetGameEngine(self)
    self._gameView:onResetData()
    self.bListening = false
	self.nGameSceneLimit = false
	self.bTrustee = false
	self.cbAppearCardData = {} 		--已出现的牌
	self.bMoPaiStatus = false
	self.cbActionMask = nil

	self.isMyProvideUser = false
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
    self.m_userRecord = {}
end

-- 椅子号转视图位置,注意椅子号从0~nChairCount-1,返回的视图位置从1~nChairCount
function GameLayer:SwitchViewChairID(chair)
    local viewid = yl.INVALID_CHAIR
    local nChairCount = self._gameFrame:GetChairCount()
    --nChairCount = cmd.GAME_PLAYER
    local myChairID = yl.INVALID_CHAIR
    if self:GetMeChairID() ~= yl.INVALID_CHAIR then
    	myChairID = self:GetMeChairID()
    else
    	myChairID = self.myChirID
    end
 	 
 	 local right = myChairID +1
 	 right = right >= nChairCount and right - nChairCount or right
 	 local left  = myChairID -1
 	 left = left < 0 and left + nChairCount or left 
 	 local top = myChairID + 2
 	 top = top >= nChairCount and top - nChairCount or top

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
	return self.m_sparrowUserItem[chairId]
end

function GameLayer:getMaCount()
	print("返回码数", self.cbMaCount)
	return self.cbMaCount
end

function GameLayer:onGetSitUserNum()
	local num = 0
	for i = 1, cmd.GAME_PLAYER do
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
	--指针指向
    self._gameView:OnUpdataClockPointView(chair)
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
			--self:onExitTable()
		elseif time <= 5 then
    		self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
		end
    elseif clockId == cmd.IDI_OUT_CARD then
    	if chair == meChairId then
    		--托管.
    		--超时
    		if time <= 0 then
				self:sendUserTrustee()
    		elseif time <= 5 then
    			self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
    		end
    	end
    elseif clockId == cmd.IDI_OPERATE_CARD then
    	--if chair == meChairId then
    		if self.isMyProvideUser then
    			return
    		end
    		--超时
    		if time <= 0 then
    			--放弃，进入托管,隐藏操作按钮
    			self._gameView:ShowGameBtn(GameLogic.WIK_NULL)
    			self:sendUserTrustee()
    		elseif time <= 5 then
    			self:PlaySound(cmd.RES_PATH.."sound/GAME_WARN.wav")
    		end
    	--end
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
    local viewid = self:SwitchViewChairID(useritem.wChairID)
    if viewid and viewid ~= yl.INVALID_CHAIR then
        self._gameView:ShowUserVoice(viewid, true)
    end
end

-- 语音播放结束
function GameLayer:onUserVoiceEnded( useritem, filepath )
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
	        		self._gameView:OnUpdateUserExit(i)
	        		self._gameView:showUserState(i, false)
	        	end
        	end
        else
        	local wViewChairId = self:SwitchViewChairID(useritem.wChairID)
        	self._gameView:OnUpdateUserExit(wViewChairId)
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
    self._gameView:OnUpdateUser(wViewChairId, useritem)
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
    self.m_cbGameStatus = cbGameStatus
    self.m_bOnGame = true
    --初始化已有玩家
    for i = 1, cmd.GAME_PLAYER do
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

	if cbGameStatus == cmd.GAME_SCENE_FREE then
		self:onGameSceneFree(dataBuffer)
	elseif cbGameStatus == cmd.GAME_SCENE_PLAY then
		self:onGameScenePlay(dataBuffer)
	else
		print("\ndefault\n")
		return false
	end
	self.myChirID = self:GetMeChairID()

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

		self.lCellScore = cmd_data.lCellScore
		self.cbTimeOutCard = cmd_data.cbTimeOutCard
		self.cbTimeOperateCard = cmd_data.cbTimeOperateCard
		self.cbTimeStartGame = cmd_data.cbTimeStartGame
		self.cbTimeWaitEnd = cmd_data.cbTimeWaitEnd
		--历史积分

		--规则
		self.cbPlayerCount = cmd_data.cbPlayerCount or 4
		self.cbMaCount = cmd_data.cbMaCount
		print("设置码数", self.cbMaCount)
		self.cbMagicMode = cmd_data.cbMagicMode
		self.bQiangGangHu = cmd_data.bQiangGangHu
		self.bHuQiDui = cmd_data.bHuQiDui
		self.bHaveZiCard = cmd_data.bHaveZiCard
		self.bNoMagicDouble = cmd_data.bNoMagicDouble
		self.cbAllCardCount = cmd_data.cbAllCardCount
		self._gameView.m_nAllCard = self.cbAllCardCount
		
		--设置信息
		self._gameView:onshowRule( self.lCellScore, self.cbMaCount, self.cbMagicMode, self.bQiangGangHu, self.bHuQiDui, self.bHaveZiCard ,self.bNoMagicDouble, self.cbMagicMode)
		--设置牌数
		self._gameView:onUpdataLeftCard(self.cbAllCardCount)

		--防作弊不显示
		if not GlobalUserItem.isAntiCheat() then 
			--判断我的状态
			local userItem = self._gameFrame:getTableUserItem(self._gameFrame:GetTableID(), self:GetMeChairID())
			if nil ~= userItem then
				if userItem.cbUserStatus < yl.US_READY then
					self._gameView.btStart:setVisible(true)
				end
			end
		end

		if GlobalUserItem.bPrivateRoom then
			self._gameView.userPoint:setVisible(false)
		else
			local wMyChairId = self:GetMeChairID()
			self:SetGameClock(self:SwitchViewChairID(wMyChairId), cmd.IDI_START_GAME, self.cbTimeStartGame)
		end

end
function GameLayer:onGameScenePlay(dataBuffer)
	print("游戏状态")
	--准备不显示
	for i=1,cmd.GAME_PLAYER do
		self._gameView:showUserState(i, false)
	end

	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_StatusPlay, dataBuffer)
	dump(cmd_data.WeaveItemArray, "WeaveItemArray")
	dump(cmd_data.cbWeaveItemCount, "cbWeaveItemCount")
	dump(cmd_data.cbCardData, "cbCardData")
	dump(cmd_data.cbMagicIndex, "cbMagicIndex")

	self.lCellScore = cmd_data.lCellScore
	self.cbTimeOutCard = cmd_data.cbTimeOutCard
	self.cbTimeOperateCard = cmd_data.cbTimeOperateCard
	self.cbTimeStartGame = cmd_data.cbTimeStartGame
	self.cbTimeWaitEnd = cmd_data.cbTimeWaitEnd
	self.wCurrentUser = cmd_data.wCurrentUser
	self.wBankerUser = cmd_data.wBankerUser

	--设置癞子
	self._gameView._cardLayer.cbMagicData = cmd_data.cbMagicIndex[1]
	self._gameView:onUpdataMagicCard(cmd_data.cbMagicIndex[1])
	--规则
	self.cbPlayerCount = cmd_data.cbPlayerCount or 4
	self.cbMaCount = cmd_data.cbMaCount
	self.cbMagicMode = cmd_data.cbMagicMode
	self.bQiangGangHu = cmd_data.bQiangGangHu
	self.bHuQiDui = cmd_data.bHuQiDui
	self.bHaveZiCard = cmd_data.bHaveZiCard
	self.bNoMagicDouble = cmd_data.bNoMagicDouble
	self.cbAllCardCount = cmd_data.cbAllCardCount
	self.cbLeftCardCount = cmd_data.cbLeftCardCount
	self._gameView.m_nAllCard = self.cbAllCardCount
	--庄家self.cbMagicData
	local wViewBankerUser = self:SwitchViewChairID(self.wBankerUser)
	self._gameView.m_tabUserHead[wViewBankerUser]:showBank(true)

	--设置信息
	self._gameView:onshowRule( self.lCellScore, self.cbMaCount, self.cbMagicMode, self.bQiangGangHu, self.bHuQiDui, self.bHaveZiCard ,self.bNoMagicDouble, self.cbMagicMode)
	--剩余牌数
	self._gameView:onUpdataLeftCard(self.cbLeftCardCount)

	--先设置已经出的牌
	for i=1,cmd.GAME_PLAYER do
		local wViewChairId = self:SwitchViewChairID(i - 1)
		if cmd_data.cbWeaveItemCount[1][i] > 0 then
			for j = 1, cmd_data.cbWeaveItemCount[1][i] do
				local cbOperateData = {} --此处为tagAvtiveCard
				cbOperateData.cbCardValue = cmd_data.WeaveItemArray[i][j].cbCardData[1]
				dump(cbOperateData.cbCardValue, "已经出的牌")
				local nShowStatus = GameLogic.SHOW_NULL
				local cbParam = cmd_data.WeaveItemArray[i][j].cbParam
				if cbParam == GameLogic.WIK_GANERAL then
					if cbOperateData[1] == cbOperateData[2] then 	--碰
						nShowStatus = GameLogic.SHOW_PENG
					else 											--吃
						nShowStatus = GameLogic.SHOW_CHI
					end
					cbOperateData.cbCardNum = 3
				elseif cbParam == GameLogic.WIK_MING_GANG then
					nShowStatus = GameLogic.SHOW_MING_GANG
					cbOperateData.cbCardNum = 4
				elseif cbParam == GameLogic.WIK_FANG_GANG then
					nShowStatus = GameLogic.SHOW_FANG_GANG
					cbOperateData.cbCardNum = 4
				elseif cbParam == GameLogic.WIK_AN_GANG then
					nShowStatus = GameLogic.SHOW_AN_GANG
					cbOperateData.cbCardNum = 4
				end
				cbOperateData.cbType = nShowStatus

				self._gameView._cardLayer:createActiveCardReEnter(wViewChairId, cbOperateData)
			end
		end
	end

	--设置手牌
	local viewCardCount = {}
	for i = 1, cmd.GAME_PLAYER do
		local viewId = self:SwitchViewChairID(i - 1)
		viewCardCount[viewId] = cmd_data.cbCardCount[1][i]
		if viewCardCount[viewId] > 0 then
			self.cbPlayStatus[viewId] = 1
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
	for i = 1, cmd.GAME_PLAYER do
		if i == cmd.MY_VIEWID then
			self._gameView._cardLayer:createHandCard(i, cbHandCardData, viewCardCount[i])
		else
			self._gameView._cardLayer:createHandCard(i, nil, viewCardCount[i])
		end
	end

	--设置已经出的牌
	for i = 1, cmd.GAME_PLAYER do
		local viewId = self:SwitchViewChairID(i - 1)
		local cbOutCardData = {}
		for j = 1, cmd_data.cbDiscardCount[1][i] do
			--已出的牌
			cbOutCardData[j] = cmd_data.cbDiscardCard[i][j]
		end
		self._gameView._cardLayer:createOutCard(i, cbOutCardData, cmd_data.cbDiscardCount[1][i])
	end

	--托管判断
	for i = 1, cmd.GAME_PLAYER do
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

	--允许操作操作
	if self.wCurrentUser == self:GetMeChairID() then
		self._gameView._cardLayer:setMyCardTouchEnabled(true)
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
    self.m_cbGameStatus = cmd.GAME_SCENE_PLAY
	if sub == cmd.SUB_S_GAME_START then 					--游戏开始
		return self:onSubGameStart(dataBuffer)
	elseif sub == cmd.SUB_S_OUT_CARD then 					--用户出牌
		return self:onSubOutCard(dataBuffer)
	elseif sub == cmd.SUB_S_SEND_CARD then 					--发送扑克
		return self:onSubSendCard(dataBuffer)
	elseif sub == cmd.SUB_S_OPERATE_NOTIFY then 			--操作提示
		return self:onSubOperateNotify(dataBuffer)
	elseif sub == cmd.SUB_S_HU_CARD then 					--胡牌提示
		return self:onSubHuNotify(dataBuffer)
	elseif sub == cmd.SUB_S_OPERATE_RESULT then 			--操作命令
		return self:onSubOperateResult(dataBuffer)
	elseif sub == cmd.SUB_S_LISTEN_CARD then 				--用户听牌
		return self:onSubListenCard(dataBuffer)
	elseif sub == cmd.SUB_S_TING_DATA then 					--听牌数据
		return self:onSubListenCardData(dataBuffer)
	elseif sub == cmd.SUB_S_TRUSTEE then 					--用户托管
		return self:onSubTrustee(dataBuffer)
	elseif sub == cmd.SUB_S_GAME_CONCLUDE then 				--游戏结束
		return self:onSubGameConclude(dataBuffer)
	elseif sub == cmd.SUB_S_RECORD then 					--游戏记录
		return self:onSubGameRecord(dataBuffer)
	elseif sub == cmd.SUB_S_SET_BASESCORE then 				--设置基数
		self.lCellScore = dataBuffer:readint()
		return true
	else
		assert(false, "default")
	end

	return false
end

--游戏开始
function GameLayer:onSubGameStart(dataBuffer)
	self.m_cbGameStatus = cmd.GAME_SCENE_PLAY

	--准备不显示
	for i=1,cmd.GAME_PLAYER do
		self._gameView:showUserState(i, false)
	end

	self.myChirID = self:GetMeChairID()
	print("游戏开始")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameStart, dataBuffer)
	--dump(cmd_data, "CMD_S_GameStart")
	
	self.wBankerUser = cmd_data.wBankerUser
	local wViewBankerUser = self:SwitchViewChairID(self.wBankerUser)
	self._gameView.m_tabUserHead[wViewBankerUser]:showBank(true)


	local cbCardCount = {0, 0, 0, 0}
	for i = 1, cmd.GAME_PLAYER do
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

	if self.wBankerUser ~= self:GetMeChairID() then
		cmd_data.cbCardData[1][cmd.MAX_COUNT] = nil
	end
	--设置癞子
	self._gameView._cardLayer.cbMagicData = cmd_data.cbMagicIndex[1]
	
	--开始发牌
	self._gameView:gameStart(wViewBankerUser, cmd_data.cbCardData[1], cbCardCount, cmd_data.cbUserAction, cmd_data.cbMagicIndex[1])
	--设置时间
	self:SetGameClock(wViewBankerUser, cmd.IDI_OUT_CARD, self.cbTimeOutCard +8) --加的8为发牌时间

	self.wCurrentUser = cmd_data.wBankerUser
	self.bMoPaiStatus = true
	self.bSendCardFinsh = false
	self:PlaySound(cmd.RES_PATH.."sound/GAME_START.wav")
	-- 刷新房卡
    if PriRoom and GlobalUserItem.bPrivateRoom then
        if nil ~= self._gameView._priView and nil ~= self._gameView._priView.onRefreshInfo then
        	PriRoom:getInstance().m_tabPriData.dwPlayCount = PriRoom:getInstance().m_tabPriData.dwPlayCount + 1
            self._gameView._priView:onRefreshInfo()
        end
    end
end

--用户出牌
function GameLayer:onSubOutCard(dataBuffer)
	print("用户出牌")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_OutCard, dataBuffer)
	dump(cmd_data, "CMD_S_OutCard")

	local wViewId = self:SwitchViewChairID(cmd_data.wOutCardUser)
	self._gameView:gameOutCard(wViewId, cmd_data.cbOutCardData, cmd_data.bSysOut)

	self:PlaySound(cmd.RES_PATH.."sound/OUT_CARD.wav")
	self:playCardDataSound(cmd_data.wOutCardUser, cmd_data.cbOutCardData)

	return true
end

--发送扑克(抓牌)
function GameLayer:onSubSendCard(dataBuffer)
	print("发送扑克")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_SendCard, dataBuffer)
	--dump(cmd_data, "CMD_S_SendCard")
	self.isMyProvideUser = false

	self.wCurrentUser = cmd_data.wCurrentUser
	local wCurrentViewId = self:SwitchViewChairID(self.wCurrentUser)
	self._gameView:gameSendCard(wCurrentViewId, cmd_data.cbCardData)

	self:PlaySound(cmd.RES_PATH.."sound/SEND_CARD.wav")

	self:SetGameClock(wCurrentViewId, cmd.IDI_OUT_CARD, self.cbTimeOutCard)

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

	self._gameView:ShowGameBtn(cmd_data.cbActionMask)
	self._gameView.cbActionCard = cmd_data.cbActionCard

	self.cbActionMask = cmd_data.cbActionMask
	self.cbActionCard = cmd_data.cbActionCard

	local wProvideUserViewId = self:SwitchViewChairID(cmd_data.wProvideUser)
	self:SetGameClock(wProvideUserViewId, cmd.IDI_OPERATE_CARD, self.cbTimeOutCard)
	if wProvideUserViewId == cmd.MY_VIEWID then
		self.isMyProvideUser = true
	end

	return true
end

--胡牌提示
function GameLayer:onSubHuNotify(dataBuffer)
	print("胡牌数据")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_HU_DATA, dataBuffer)
	--dump(cmd_data, "CMD_S_Hu_Data")
	--胡牌用户位置
	local wViewChairId = self:SwitchViewChairID(cmd_data.wListenUser)
	--胡牌数据
	self.cbHuCardList = {}
	for i = 1, cmd_data.cbHuCardCount do
		self.cbHuCardList[wViewChairId][i] = cmd_data.cbHuCardData[1][i]
	end

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
	self.isMyProvideUser = false

	local wOperateViewId = self:SwitchViewChairID(cmd_data.wOperateUser)
	local wProvideViewId = self:SwitchViewChairID(cmd_data.wProvideUser)
	local tagAvtiveCard = {}
	tagAvtiveCard.cbType = GameLogic.SHOW_NULL
	print("操作的麻将玩家", wOperateViewId, wProvideViewId)
	if cmd_data.cbOperateCode == GameLogic.WIK_GANG then
		--判断杠类型
		if wOperateViewId == wProvideViewId then  --暗杠
			tagAvtiveCard.cbType = GameLogic.SHOW_AN_GANG
		else
			for i=1,#self._gameView._cardLayer.cbActiveCardData[wOperateViewId] do
				--查找是否已经碰
				local activeInfo = self._gameView._cardLayer.cbActiveCardData[wOperateViewId][i]
				if activeInfo.cbCardValue[1] == cmd_data.cbOperateCard[1][1] then --有碰
					tagAvtiveCard.cbType = GameLogic.SHOW_MING_GANG
				end
			end
			if tagAvtiveCard.cbType == GameLogic.SHOW_NULL then
				tagAvtiveCard.cbType = GameLogic.SHOW_FANG_GANG
			end
		end
		tagAvtiveCard.cbCardNum = 4
		tagAvtiveCard.cbCardValue = cmd_data.cbOperateCard[1]
		--再加一个
		tagAvtiveCard.cbCardValue[4] = cmd_data.cbOperateCard[1][1]
		print("操作的麻将信息", tagAvtiveCard.cbType, tagAvtiveCard.cbCardNum, tagAvtiveCard.cbCardValue[1])
	end
	
	if cmd_data.cbOperateCode == GameLogic.WIK_PENG then
		tagAvtiveCard.cbType = GameLogic.SHOW_PENG
		tagAvtiveCard.cbCardNum = 3
		tagAvtiveCard.cbCardValue = cmd_data.cbOperateCard[1]
		--再加一个
		tagAvtiveCard.cbCardValue[3] = cmd_data.cbOperateCard[1][1]
	end
	-- 显示操作动作
	local jsonStr = cjson.encode(tagAvtiveCard)
    LogAsset:getInstance():logData(jsonStr, true)
	self._gameView._cardLayer:createActiveCard(wOperateViewId, tagAvtiveCard, wProvideViewId)

	self._gameView:showOperateAction(wOperateViewId, cmd_data.cbOperateCode)
	self:playCardOperateSound(cmd_data.wOperateUser, false, cmd_data.cbOperateCode)

	self:SetGameClock(wOperateViewId, cmd.IDI_OUT_CARD, self.cbTimeOutCard)

	return true
end

--用户听牌
function GameLayer:onSubListenCard(dataBuffer)
	print("用户听牌")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_ListenCard, dataBuffer)

	local wViewChairId = self:SwitchViewChairID(cmd_data.wListenUser)
	--如果是true，显示听牌图标
	if cmd_data.bListen then
		print("xxxxxx听牌了")
	end

	return true
end

--用户听牌数据
function GameLayer:onSubListenCardData(dataBuffer)
	print("听牌提示")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_TING_DATA, dataBuffer)
	--dump(cmd_data, "CMD_S_TING_DATA")
	self._gameView._cardLayer.cbListenList = {}
	for i = 1, cmd_data.cbOutCardCount do
		self._gameView._cardLayer.cbListenList[i] = cmd_data.cbOutCardData[1][i]
		print("玩家听牌需要打的字", self._gameView._cardLayer.cbListenList[i])
		self._gameView._cardLayer.cbHuCard[i] = {}
		self._gameView._cardLayer.cbHuCardLeft[i] = {}
		self._gameView._cardLayer.cbHuCardFan[i] = {}
		for j = 1, cmd_data.cbHuCardCount[1][i] do
			self._gameView._cardLayer.cbHuCard[i][j] = cmd_data.cbHuCardData[i][j]
			self._gameView._cardLayer.cbHuCardLeft[i][j] = cmd_data.cbHuCardRemainingCount[i][j]
			self._gameView._cardLayer.cbHuCardFan[i][j] = cmd_data.cbHuFan[i][j]
			print("玩家打完可以胡的字，剩余数，番数", self._gameView._cardLayer.cbHuCard[i][j], self._gameView._cardLayer.cbHuCardLeft[i][j], self._gameView._cardLayer.cbHuCardFan[i][j])
		end
	end
	return true
end

--用户托管
function GameLayer:onSubTrustee(dataBuffer)
	print("用户托管")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_Trustee, dataBuffer)
	--dump(cmd_data, "trustee")

	local wViewChairId = self:SwitchViewChairID(cmd_data.wChairID)
	if cmd_data.wChairID == self:GetMeChairID() then
		self.bTrustee = cmd_data.bTrustee
		self._gameView.TrustShadow:setVisible(self.bTrustee)
	end

	return true
end

--游戏结束
function GameLayer:onSubGameConclude(dataBuffer)
	print("游戏结束")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_GameConclude, dataBuffer)
	--dump(cmd_data, "CMD_S_GameConclude")
	local jsonStr = cjson.encode(cmd_data)
   	LogAsset:getInstance():logData(jsonStr, true)

	local bMeWin = false
	--先显示翻马界面
	--获取胡牌玩家
	local HuView = 0
	local HuChair = yl.INVALID_CHAIR
	for i = 1, cmd.GAME_PLAYER do
		local viewid = self:SwitchViewChairID(i - 1)
		if cmd_data.lHuScore[1][i] > 0 then
			HuView = viewid
			HuChair = i - 1

			--显示胡牌动画
			self._gameView:showOperateAction(viewid, GameLogic.WIK_CHI_HU)
		end
	end

	
	--如果没人胡，则是荒庄
	if 0 ==  HuView and cmd_data.wFleeUser == yl.INVALID_CHAIR then
		--显示荒庄
		self._gameView:showNoWin(true)
		--显示玩家手牌
		for i = 1, cmd.GAME_PLAYER do
			--手牌
			local cbCardData = {}
			local viewid = self:SwitchViewChairID(i - 1)
			for j = 1, cmd_data.cbCardCount[1][i] do
				cbCardData[j] = cmd_data.cbHandCardData[i][j]
			end
			--显示玩家手牌
			self._gameView._cardLayer:showUserTileMajong( viewid, cbCardData)
			--杠碰牌显示
			self._gameView._cardLayer:tileActiveCard(viewid)
		end
		return
	end

	--开启了无鬼翻倍，而且没有鬼牌
	local isNoMagicCard = (cmd_data.bNoMagicCard and self.bNoMagicDouble)
	print("@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#", isNoMagicCard)

	local maNum = cmd_data.cbMaCount;
	local validMaNum = cmd_data.cbZhongMaCount;
	local maData = {}
	for i = 1, maNum do
		maData[i] = cmd_data.cbMaData[1][i]
	end
	local validMaData = {}
	for i=1,validMaNum do
		validMaData[i] = cmd_data.cbZhongMaData[1][i]
	end
	if 0 ~= HuView and maNum > 0 then
		self._gameView:showMoMaAction(self.wBankerUser, HuChair, HuView, maNum, maData, validMaNum, validMaData, self.cbTimeWaitEnd)
	end
	
	local resultList = {}
	for i = 1, cmd.GAME_PLAYER do
		local viewid = self:SwitchViewChairID(i - 1)
		local lScore = cmd_data.lGameScore[1][i]
		local lHuScore = cmd_data.lHuScore[1][i]
		if lHuScore > 0 and viewid == cmd.MY_VIEWID then
			bMeWin = true
		end

		local result = {}
		result.userItem = self._gameFrame:getTableUserItem(self:GetMeTableID(), i - 1)

		if nil == result.userItem then
			result.userItem = self._gameView.m_tabUserHead[viewid].m_userItem
		end
		result.lScore = lScore
		result.lHuScore = lHuScore
		result.lGangScore = cmd_data.lGangScore[1][i]
		result.lMaScore = cmd_data.lMaScore[1][i]
		result.cbChHuKind = cmd_data.cbChiHuKind[1][i]
		--胡牌类型
		result.dwChiHuRight = {}
		for j=1,cmd.MAX_RIGHT_COUNT do
			result.dwChiHuRight[j] = cmd_data.dwChiHuRight[i][j]
		end

		result.cbCardData = {}
		--手牌
		for j = 1, cmd_data.cbCardCount[1][i] do
			result.cbCardData[j] = cmd_data.cbHandCardData[i][j]
		end
		--如果是我自摸
		if HuChair == i -1 and 0 ~= cmd_data.cbSendCardData then
			table.insert(result.cbCardData, cmd_data.cbSendCardData)
		end

		--显示玩家手牌
		self._gameView._cardLayer:showUserTileMajong( viewid, result.cbCardData )
		--杠碰牌显示
		self._gameView._cardLayer:tileActiveCard(viewid)

		--碰杠牌
		result.cbActiveCardData = self._gameView._cardLayer.cbActiveCardData[viewid]

		--插入
		table.insert(resultList, result)
	end

	--显示结算框
	local delayTime = maNum *1 +self.cbTimeWaitEnd
	if cmd_data.wFleeUser ~= yl.INVALID_CHAIR then
		delayTime = 0
	end
	self:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime), cc.CallFunc:create(function(ref)
		self._gameView._resultLayer:showLayer(resultList, self.wBankerUser, self.myChirID, cmd_data.cbProvideCard, maData, validMaNum, validMaData, cmd_data.wFleeUser, isNoMagicCard)
	end)))
	--播放音效
	if bMeWin then
		self:PlaySound(cmd.RES_PATH.."sound/ZIMO_WIN.wav")
	else
		self:PlaySound(cmd.RES_PATH.."sound/ZIMO_LOSE.wav")
	end

	self.cbPlayStatus = {0, 0, 0, 0}
    self.bTrustee = false

	if GlobalUserItem.bPrivateRoom then
		self._gameView.userPoint:setVisible(false)
	else
		self:SetGameClock(self:SwitchViewChairID(self:GetMeChairID()), cmd.IDI_START_GAME, self.cbTimeStartGame)
	end

	return true
end

--游戏记录（房卡）
function GameLayer:onSubGameRecord(dataBuffer)
	print("游戏记录")
	local cmd_data = ExternalFun.read_netdata(cmd.CMD_S_RECORD, dataBuffer)
	dump(cmd_data, "CMD_S_Record")
	    --全部成绩

	self.m_userRecord = {}
	local nInningsCount = cmd_data.nCount
	for i = 1, self.cbPlayerCount do
		self.m_userRecord[i] = {}
		self.m_userRecord[i].cbHuCount = cmd_data.cbHuCount[1][i]
		self.m_userRecord[i].cbMingGang = cmd_data.cbMingGang[1][i]
		self.m_userRecord[i].cbAnGang = cmd_data.cbAnGang[1][i]
		self.m_userRecord[i].cbMaCount = cmd_data.cbMaCount[1][i]
		self.m_userRecord[i].lDetailScore = {}
		for j = 1, nInningsCount do
			self.m_userRecord[i].lDetailScore[j] = cmd_data.lDetailScore[i][j]
		end
	end
	-- local jsonStr = cjson.encode(self.m_userRecord)
 --    LogAsset:getInstance():logData(jsonStr, true)
	--dump(self.m_userRecord, "m_userRecord", 5)
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
--播放随机聊天音效
function GameLayer:playRandomSound(viewId)
	local strGender = ""
	if self.cbGender[viewId] == 1 then
		strGender = "BOY"
	else
		strGender = "GIRL"
	end
	local nRand = math.random(25) - 1
	if nRand <= 6 then
		local num = 6603000 + nRand
		local strName = num..".wav"
		local strFile = cmd.RES_PATH.."sound/PhraseVoice/"..strGender.."/"..strName
		self:PlaySound(strFile)
	end
end

function GameLayer:getDetailScore()
	return self.m_userRecord
end

function GameLayer:getListenPromptOutCard()
	return self.cbListenPromptOutCard
end

function GameLayer:getListenPromptHuCard(cbOutCard)
	if not cbOutCard then
		return nil
	end

	for i = 1, #self.cbListenPromptOutCard do
		if self.cbListenPromptOutCard[i] == cbOutCard then
			assert(#self.cbListenCardList > 0 and self.cbListenCardList[i] and #self.cbListenCardList[i] > 0)
			return self.cbListenCardList[i]
		end
	end

	return nil
end

--*****************************    发送消息     *********************************--
--开始游戏
function GameLayer:sendGameStart()
	self:SendUserReady()
	self:OnResetGameEngine()

	self._gameView.userPoint:setVisible(false)
end
--出牌
function GameLayer:sendOutCard(card)
	-- body
	print("发送出牌：", card)
	local cmd_data = ExternalFun.create_netdata(cmd.CMD_C_OutCard)
	cmd_data:pushbyte(card)
	return self:SendData(cmd.SUB_C_OUT_CARD, cmd_data)
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
	self:SendData(cmd.SUB_C_OPERATE_CARD, cmd_data)
end
--用户听牌
function GameLayer:sendUserListenCard(bListen)
	local cmd_data = CCmd_Data:create(1)
	cmd_data:pushbool(bListen)
	self:SendData(cmd.SUB_C_LISTEN_CARD, cmd_data)
end
--用户托管
function GameLayer:sendUserTrustee()
	local cmd_data = CCmd_Data:create(1)
	cmd_data:pushbool(not self.bTrustee)
	self:SendData(cmd.SUB_C_TRUSTEE, cmd_data)
end
--发送扑克
function GameLayer:sendControlCard(cbControlGameCount, cbCardCount, wBankerUser, cbCardData)
	local cmd_data = ExternalFun.create_netdata(cmd.CMD_C_SendCard)
	cmd_data:pushbyte(cbControlGameCount)
	cmd_data:pushbyte(cbCardCount)
	cmd_data:pushword(wBankerUser)
	for i = 1, #cbCardData do
		cmd_data:pushbyte(cbCardData[i])
	end
	self:SendData(cmd.SUB_C_SEND_CARD, cmd_data)
end

return GameLayer