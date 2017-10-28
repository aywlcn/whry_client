--
-- Author: Tang
-- Date: 2016-12-08 15:41:53
--
local GameModel = appdf.req(appdf.CLIENT_SRC.."gamemodel.GameModel")
local GameLayer = class("GameLayer", GameModel)

local module_pre = "game.xiuxian.forestdance.src"
local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var
local cmd = module_pre .. ".models.cmd_game"
local GameFrame = appdf.req(module_pre .. ".models.GameFrame")
local game_cmd = appdf.HEADER_SRC .. "CMD_GameServer"
local GameViewLayer = appdf.req(module_pre .. ".views.layer.GameViewLayer")
local scheduler = cc.Director:getInstance():getScheduler()
function GameLayer:ctor( frameEngine,scene )        
    GameLayer.super.ctor(self, frameEngine, scene)
    self:OnInitGameEngine()
    self._roomRule = self._gameFrame._dwServerRule
    self.m_bLeaveGame = false
    self._bCaijinStatus = false
    self.m_bPlaceRecord = false
    self._caijinStatus  = 0
    self.m_lMeGrade     = 0   --玩家自己输赢
    self.m_wBankerUser = yl.INVALID_CHAIR
    self._drawIndex   = 0       --中奖索引 
    self._curJettonIndex = -1   --当前筹码索引
    self._clockTimeLeave = 0    --剩余时间
    self._gameStatus = g_var(cmd).IDI_GAME_DRAW_RESULT  --游戏状态
    self._applyStatus= g_var(cmd).unApply
    self._rotateStatus =  0     --转盘状态
    self._selfBetItemScore = {0,0,0,0,0,0,0,0,0,0,0,0} 
    self.m_lContinueRecord  = {0,0,0,0,0,0,0,0,0,0,0,0}  --续压记录
    self._gameModel = GameFrame:create()

    self:createSchedule()

end

--获取gamekind
function GameLayer:getGameKind()
    return cmd.KIND_ID
end

--创建场景
function GameLayer:CreateView()
     self._gameView = GameViewLayer:create(self)
     self:addChild(self._gameView)
     return self._gameView
end

function GameLayer:getParentNode( )
    return self._scene
end

function GameLayer:getFrame( )
    return self._gameFrame
end
function GameLayer:getUserList()
    return self._gameFrame._UserList
end
function GameLayer:logData(msg)
    if nil ~= self._scene.logData then
        self._scene:logData(msg)
    end
end

function GameLayer:sendNetData( cmddata )
    return self:getFrame():sendSocketData(cmddata)
end

function GameLayer:reSetData()
  self._applyStatus = g_var(cmd).unApply
  self._gameModel:removeBankList(self:GetMeUserItem()) 
  if nil ~= self._gameView._bankerView  then
    self._gameView._bankerView:reloadData()
    self._gameView._bankerView:setApplyStatus()
  end
end

function GameLayer:createSchedule()

    local function update(dt)
      --动物转动
      if true == self._bAnimalAction then
          self._gameView:runRotateAction(dt)
      end

      if true == self._bCaijinStatus then
        if math.mod(self._timeSkip,10) == 0 then
          self._gameView:updateCaijin()
        end
      end
      self._timeSkip = self._timeSkip + 1
    end

   --游戏定时器
    if nil == self.m_scheduleUpdate then
        self._timeSkip = 0
        self.m_scheduleUpdate = scheduler:scheduleScriptFunc(update, 0.02, false)
    end
end

function GameLayer:unSchedule( )

--游戏定时器
    if nil ~= self.m_scheduleUpdate then
        scheduler:unscheduleScriptEntry(self.m_scheduleUpdate)
        self.m_scheduleUpdate = nil
    end
end
---------------------------------------------------------------------------------------
------继承函数
function GameLayer:onEnterTransitionFinish()
    GameLayer.super.onEnterTransitionFinish(self)
end

function GameLayer:onExit()
    self:unSchedule()
    self:KillGameClock()
    self:dismissPopWait()
    GameLayer.super.onExit(self)
    print("GameLayer onExit")
end

--退出桌子
function GameLayer:onExitTable()
    self:KillGameClock()
    local MeItem = self:GetMeUserItem()
    if MeItem and MeItem.cbUserStatus > yl.US_FREE then
        self:showPopWait()
        self:runAction(cc.Sequence:create(
            cc.CallFunc:create(
                function () 
                    self._gameFrame:StandUp(1)
                end
                ),
            cc.DelayTime:create(10),
            cc.CallFunc:create(
                function ()
                    print("delay leave")
                    self:onExitRoom()
                end
                )
            )
        )
        return
    end

   self:onExitRoom()
end


--离开房间
function GameLayer:onExitRoom()
    self._scene:onKeyBack()
end

function GameLayer:OnEventGameClockInfo(chair,clocktime,clockID)
    if nil ~= self._gameView  and self._gameView.UpdataClockTime then
        self._gameView:UpdataClockTime(chair,clocktime)
    end
end

-- 设置计时器
function GameLayer:SetGameClock(chair,id,time)
    self:KillGameClock()
    GameLayer.super.SetGameClock(self,chair,id,time)

    if nil ~= self._gameView  and self._gameView.setClockView then
        self._gameView:setClockView(chair,id,time)
    else
        print("the clock init failure")    
    end
end

function GameLayer:OnResetGameEngine()
    print("OnResetGameEngine")
    if self._gameView then
      self._gameView:loading()
    end
    self:reSetData() 
    GameLayer.super.OnResetGameEngine(self)
end

-- 场景信息
function GameLayer:onEventGameScene(cbGameStatus,dataBuffer)
    print("场景数据:" .. cbGameStatus)
    self:dismissPopWait()

    self._gameModel._bScene = true
    self._gameModel._sceneData = ExternalFun.read_netdata(g_var(cmd).CMD_S_Status_Base, dataBuffer)
    dump(self._gameModel._sceneData, "the scene data is ==============", 5)

    self.m_wBankerUser = self._gameModel._sceneData.wBankerChairID
    self.m_lApplyBankerScore = self._gameModel._sceneData.lApplyBankerScore
    self.m_lBankerGrade = self._gameModel._sceneData.lBankerGrade

    local meItem = self:GetMeUserItem()
    for i=1,self._gameModel._sceneData.cbApplyBankerCount do
        local userItem = self._gameModel:getUserByChair(self:getUserList(),self._gameModel._sceneData.wApplyBankerList[1][i])
        if userItem.wChairID ~= meItem.wChairID then
          self._gameModel:insertBankerList(userItem)
        end
    end
end

--游戏消息
function GameLayer:onEventGameMessage(sub,dataBuffer)
    if nil == self._gameView or  not self._gameView._resLoadFinish then
        return
    end

    if sub == g_var(cmd).SUB_S_START_FREE then                  --空闲时间
        self:onSubStartFree(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_START_BET then               --开始下注
        self:onSubStartBet(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_START_DRAW then               --开始开奖
        self:onSubStartDraw(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_DRAW_RESULT then              --派彩时间
        self:onSubDrawResult(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_BETCOUNT_CHANGE then          --下注额改变
        self:onSubBetCountChange(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_USER_BET then                 --用户下注
        self:onSubUserBet(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_BET_FAILED then               --下注失败
        self:onSubBetFailure(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_BANKER_OPERATE then           --庄家操作
        self:onSubBankerOperate(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_SWITCH_BANKER then            --切换庄家
        self:onSubSwitchBanker(dataBuffer)
    elseif sub == g_var(cmd).SUB_S_BANKERINFO_VARIATION then     --信息更新
        self:onSubBankerInfoVariation(dataBuffer)
    end

    print("forestdance onEventGameMessage ======== >"..sub)
end

function GameLayer:onSubStartFree(dataBuffer)
  print("游戏空闲")

  if not self._gameView._resLoadFinish then
    return
  end
  
  self._gameView:playEffect("wait.wav")
  local result = ExternalFun.read_netdata(g_var(cmd).CMD_S_Start_Free, dataBuffer)
  --重置赔率
  self._gameModel._sceneData.cbBetItemRatioList = result.cbBetItemRatio
  --游戏状态
  self._gameView:setGameStatus(g_var(cmd).IDI_GAME_FREE)
  --重置游戏
  self._gameView:resetGame()
  --更新颜色
  self._gameView:updateColor()
  --更新赔率
  self._gameView:updateBetItemRatio()
  --下注记录清除
  self._gameView:gameClean()
  --路单记录
  self._gameView:showRouteRecord()

  if nil ~= self._gameView._bankerView  then
    self._gameView._bankerView:reloadData()
    local item = self:GetMeUserItem()
    if item.wChairID == self.m_wBankerUser then
      self._applyStatus = g_var(cmd).applyed
      self._gameView._bankerView:setApplyStatus()
    end
  end

  self._caijinStatus = 1
end

function GameLayer:onSubStartBet(dataBuffer)
  print("开始下注")

  if not self._gameView._resLoadFinish then
    return
  end

  self._gameView:playEffect("START_BET.wav")
  local result = ExternalFun.read_netdata(g_var(cmd).CMD_S_Start_Bet, dataBuffer)
  --游戏状态
  self._gameView:setGameStatus(g_var(cmd).IDI_GAME_BET)
  --重置赔率
  self._gameModel._sceneData.cbBetItemRatioList = result.cbBetItemRatio
  --彩灯颜色索引
  self._gameModel._sceneData.cbColorLightIndexList = result.cbColorLightIndexList
  --重置游戏
  self._gameView:resetGame()
  --更新颜色
  self._gameView:updateColor()
  --弹出下注层
  self._gameView:popPlaceJettonLayer()
  --刷新分数
  self._gameView:updateScoreItem()
  --更新按钮状态
  self._gameView:updateControl()
  self._gameView:initJettonIndex()
  --更新赔率
  self._gameView:updateBetItemRatio()
  --路单记录
  self._gameView:showRouteRecord()

  if nil ~= self._gameView._bankerView  then
    self._gameView._bankerView:reloadData()
    local item = self:GetMeUserItem()
    if item.wChairID == self.m_wBankerUser then
      self._applyStatus = g_var(cmd).applyed
      self._gameView._bankerView:setApplyStatus()
    end
  end
end

function GameLayer:onSubStartDraw(dataBuffer)
  print("开始派彩")
  --数据包解析
  local result = ExternalFun.read_netdata(g_var(cmd).CMD_S_Start_Draw, dataBuffer)
  self._drawData = {}
  self._drawData = result
  self._drawData.nAnimalAngle = math.mod(result.nAnimalAngle + result.nCurrAnimalAngle,g_var(cmd).BET_ITEM_TOTAL_COUNT)
  self._drawData.nPointerAngle = math.mod(result.nPointerAngle + result.nCurrPointerAngle,g_var(cmd).BET_ITEM_TOTAL_COUNT)

  if nil ~= self._gameView._loadLayer then
      return
  end

  self._gameView:playEffect("PAYOUT.wav")

   --游戏状态
  self._gameView:setGameStatus(g_var(cmd).IDI_GAME_DRAW)
  --隐藏下注层
  self._gameView:popPlaceJettonLayer(g_var(cmd).hidden)
  --摄像机
  self._gameView._camera:runAction(cc.MoveTo:create(0.5,g_var(cmd).Camera_Rotate_Vec3))

    --指针转动
  self._gameView:arrowRunAction()

  --动画初始化
  self._bAnimalAction = true
  self._rotateSpeed = g_var(cmd).RotateMin
  self._rotateStatus= g_var(cmd).Speed
  self._rotateTime  = 0

  if 0 ~=  bit:_and(self._drawData.dwAnimationFlag,g_var(cmd).ANIMATION_PAYOUTDSY) then 
     self._gameView:playEffect("DRAW_DSY_BACK.mp3")
     self._gameView:showDSYAnim()
  elseif 0 ~=  bit:_and(self._drawData.dwAnimationFlag,g_var(cmd).ANIMATION_PAYOUTDSX) then
     self._gameView:playEffect("DRAW_DSX_BACK.mp3")
     self._gameView:showDSXAnim() 
  elseif  0 ~=  bit:_and(self._drawData.dwAnimationFlag,g_var(cmd).ANIMATION_PAYOUTSD) then 
     self._gameView:playEffect("DRAW_SD_BACK.mp3")
     self._gameView:showSDAnim()  
  elseif  0 ~=  bit:_and(self._drawData.dwAnimationFlag,g_var(cmd).ANIMATION_PAYOUTMGOLD) then
     self._gameView:playEffect("DRAW_MGOLD_BACK.mp3")
     self._gameView:sohwCJAnim()
  elseif 0 ~= bit:_and(self._drawData.dwAnimationFlag,g_var(cmd).ANIMATION_PAYOUTGUN) then
     self._gameView:playEffect("DRAW_DQ_BACK.mp3")
     self._gameView:showDQAnim()
  else
     self._gameView:playEffect("DRAW_NORMAL_BACK.wav")
  end
end

function GameLayer:onSubDrawResult(dataBuffer)
  --数据包解析
  local result = ExternalFun.read_netdata(g_var(cmd).CMD_S_Draw_Result, dataBuffer)
  self.m_bPlaceRecord = false
  if nil ~= self._gameView._loadLayer then
    --插入记录
    self._gameView:insertRecord(bit:_or(result.dwDrawBetItem,result.dwDrawWeaveItem))
    return
  end

  if result.bDrawMGold  then
    self._gameView:playEffect("ANIMAL_MOVE.wav")
  else
     --[[for i=1,g_var(cmd).BET_ITEM_COUNT do
        if result.bDrawItemIndex[1][i] then
           --self._gameView:playEffect(string.format("Draw_Animal_%d.wav", math.floor(result.bDrawItemIndex[1][i]/3)))
        end
     end]]  
  end

  --游戏状态
  self._gameView:setGameStatus(g_var(cmd).IDI_GAME_DRAW_RESULT)
  --结算层
  self._gameView._rewardLayer:setVisible(true)
  self._gameView:showDrawResult(result)
  --插入记录
  self._gameView:insertRecord(bit:_or(result.dwDrawBetItem,result.dwDrawWeaveItem))

  self._gameView:resetData()
end

function GameLayer:onSubBetCountChange(dataBuffer)

  --数据包解析
  local result = ExternalFun.read_netdata(g_var(cmd).CMD_S_BetCount_Change, dataBuffer)

  if nil ~= self._gameView._loadLayer then
    return
  end

  dump(result, "the betCount change data is ===============", 6)

  --当前区域
  local itemBetIndex = result.cbBetItemIndex
  self._gameModel._sceneData.lBetTotalCount[1][itemBetIndex+1] =  result.lCurrBetCount

  --游戏状态
  self._gameView:setGameStatus(g_var(cmd).IDI_GAME_BET)
  --重置游戏
  self._gameView:resetGame()
  --更新颜色
  self._gameView:updateColor()
  --弹出下注层
  self._gameView:popPlaceJettonLayer()
  --更新按钮状态
  self._gameView:updateControl()
  --刷新分数
  self._gameView:updateScoreItem()
  --更新区域赔率
  self._gameView:updateBetItemRatio()
  --路单记录
  self._gameView:showRouteRecord()
end

function GameLayer:onSubUserBet(dataBuffer)
end

function GameLayer:onSubBetFailure(dataBuffer)
  print("下注失败")
  local failure = ExternalFun.read_netdata(g_var(cmd).CMD_S_BetFailed, dataBuffer)
  local betIndex = failure.cbBetItemIndex
  local item = self:GetMeUserItem()
  item.lScore = item.lScore + failure.lBetCount
  self._selfBetItemScore[betIndex+1] = self._selfBetItemScore[betIndex+1] - failure.lBetCount
  self._gameModel._sceneData.lBetTotalCount[1][betIndex+1] = self._gameModel._sceneData.lBetTotalCount[1][betIndex+1] - failure.lBetCount
  --更新按钮状态
  self._gameView:updateControl()
  --刷新分数
  self._gameView:updateScoreItem()
end

function GameLayer:onSubBankerOperate(dataBuffer)
  local operate = ExternalFun.read_netdata(g_var(cmd).CMD_S_Banker_Operate, dataBuffer)
  local userItem = self:GetMeUserItem()
  local operateItem = self._gameModel:getUserByChair(self:getUserList(),operate.wChairID)
  dump(operate, "the banker operate ==================", 6)
  if true == operate.bApplyBanker then
    self._gameModel:insertBankerList(operateItem)
    if operate.wChairID == userItem.wChairID then
      self._applyStatus = g_var(cmd).applyed
    end
  else
    self._gameModel:removeBankList(operateItem)
    if operate.wChairID == userItem.wChairID then
      self._applyStatus = g_var(cmd).unApply
    end
  end

  if nil ~= self._gameView._bankerView  then
    self._gameView._bankerView:reloadData()
    if operate.wChairID == userItem.wChairID then
      self._gameView._bankerView:setApplyStatus()
    end
  end

  --更新按钮状态
  self._gameView:updateControl()
end

function GameLayer:onSubSwitchBanker(dataBuffer)
  local swithInfo = ExternalFun.read_netdata(g_var(cmd).CMD_S_Switch_Banker, dataBuffer)
  self.m_wBankerUser = swithInfo.wBankerChairID
  self.m_lBankerGrade = 0

  local userItem = self:GetMeUserItem()

  --庄家列表中删除上庄信息
  local preBanker = self._gameModel:getUserByChair(self:getUserList(),self.m_wBankerUser)
  if preBanker  then
    self._gameModel:removeBankList(preBanker)
  end
  
  if nil ~= self._gameView._bankerView  then
    self._gameView._bankerView:reloadData()
    if swithInfo.wPreBankerChairID == userItem.wChairID then
       self._applyStatus = g_var(cmd).unApply
       self._gameView._bankerView:setApplyStatus()
    end
  end

   --更新按钮状态
  self._gameView:updateControl()
end

function GameLayer:onSubBankerInfoVariation(dataBuffer)
  local valueInfo = ExternalFun.read_netdata(g_var(cmd).CMD_S_BankerInfo_Variation, dataBuffer)
  self.m_lBankerGrade = valueInfo.lBankerGrade

  if nil ~= self._gameView._bankerView  then
    self._gameView._bankerView:reloadData()
  end
end

--银行 
function GameLayer:onSocketInsureEvent( sub,dataBuffer )
  print(sub)
  self:dismissPopWait()

  if sub == g_var(game_cmd).SUB_GR_USER_INSURE_SUCCESS then
      local cmd_table = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureSuccess, dataBuffer)
      self.bank_success = cmd_table
      self._gameView._bankView:onBankSuccess()
  elseif sub == g_var(game_cmd).SUB_GR_USER_INSURE_FAILURE then
      local cmd_table = ExternalFun.read_netdata(g_var(game_cmd).CMD_GR_S_UserInsureFailure, dataBuffer)
      self.bank_fail = cmd_table
      self._gameView._bankView:onBankFailure()
  else
      print("unknow gamemessage sub is ==>"..sub)
  end
end

--用户状态
function GameLayer:onEventUserStatus(useritem,newstatus,oldstatus)
  print("change user " .. useritem.wChairID .. "; nick " .. useritem.szNickName)
  if newstatus.cbUserStatus == yl.US_FREE or newstatus.cbUserStatus == yl.US_NULL then
    if (oldstatus.wTableID ~= self:GetMeUserItem().wTableID) then
        return
    end

    self._gameModel:removeUserList(useritem)
    if nil ~= self._gameView._UserView then
        self._gameView._UserView:reloadData()
    end
    print("删除")
  else
     --缓存用户
    self._gameModel:insertUserList(useritem)
    if nil ~= self._gameView._UserView  then
      self._gameView._UserView:reloadData()
    end
  end    
end

--用户进入
function GameLayer:onEventUserEnter(tableid,chairid,useritem)
  print("the table id is ================ >"..tableid)
  if tableid ~= self:GetMeUserItem().wTableID then
    return
  end

  --缓存用户
  self._gameModel:insertUserList(useritem)
  if nil ~= self._gameView._UserView  then
    self._gameView._UserView:reloadData()
  end
end

--用户分数
function GameLayer:onEventUserScore( item )
  if item.dwUserID == self:GetMeUserItem().dwUserID then
     self._gameView:updateScore(item.lScore)
  end

  --刷新用户列表
  if self._gameView._UserView then
    self._gameView._UserView:reloadData()
  end
 
  --刷新庄家列表
  if self._gameView._bankerView then
    self._gameView._bankerView:reloadData()
  end
end
return GameLayer