local CreateLayerModel = appdf.req(PriRoom.MODULE.PLAZAMODULE .."models.CreateLayerModel")

local PriRoomCreateLayer = class("PriRoomCreateLayer", CreateLayerModel)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local Shop = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ShopLayer")

local BTN_HELP          = 1
local BTN_CHARGE        = 2
local BTN_MYROOM        = 3
local BTN_CREATE        = 4

local CBT_CONFIG_GAMERULE       = 310   --玩法
local CBT_CONFIG_PLAYERCOUNT    = 320   --人数
local CBT_CONFIG_GAMECONFIG     = 330   --配置
local CBT_CONFIG_ZHUONIAO       = 340   --捉鸟        
local CBT_CONFIG_GAMECOUNT      = 350   --局数

function PriRoomCreateLayer:ctor( scene )
    PriRoomCreateLayer.super.ctor(self, scene)
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("privateroom/room/PrivateRoomCreateLayer.csb", self )
    self.m_csbNode = csbNode

    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end
    -- 帮助按钮
    local btn = csbNode:getChildByName("btn_help")
    btn:setTag(BTN_HELP)
    btn:addTouchEventListener(btncallback)

    -- 充值按钮
    btn = csbNode:getChildByName("btn_cardcharge")
    btn:setTag(BTN_CHARGE)
    btn:addTouchEventListener(btncallback)    

    -- 房卡数
    self.m_txtCardNum = csbNode:getChildByName("txt_cardnum")
    self.m_txtCardNum:setString(GlobalUserItem.lRoomCard .. "")

    -- 我的房间
    btn = csbNode:getChildByName("btn_myroom")
    btn:setTag(BTN_MYROOM)
    btn:addTouchEventListener(btncallback)

   
    local cbtlistener = function (sender,eventType)
        self:onSelectedEvent(sender:getTag(),sender)
    end
    self.m_tabCheckBox = {}

    -- 玩法选项
    for i = 1, 2 do
        local checkbx = csbNode:getChildByName("check_" .. i)
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_CONFIG_GAMERULE + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_CONFIG_GAMERULE + i] = checkbx
        end
    end

    -- 选择的玩法(只能单选)    
    -- 默认勾选点炮胡
    self.m_nSelectConfigGameRuleIdx = CBT_CONFIG_GAMERULE + 1  
    self.m_tabCheckBox[self.m_nSelectConfigGameRuleIdx]:setSelected(true)

    -- 人数选项
    for i = 1, 3 do
        local checkbx = csbNode:getChildByName("check_1_" .. i)
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_CONFIG_PLAYERCOUNT + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_CONFIG_PLAYERCOUNT + i] = checkbx
        end
    end

    -- 选择人数(只能单选)    
    -- 默认勾选2人
    self.m_nSelectPlayerCountIdx = CBT_CONFIG_PLAYERCOUNT + 1  
    self.m_tabCheckBox[self.m_nSelectPlayerCountIdx]:setSelected(true)

    -- 配置 (可以多选)
    for i = 1, 3 do
        local checkbx = csbNode:getChildByName("check_1_1_" .. i)
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_CONFIG_GAMECONFIG + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_CONFIG_GAMECONFIG + i] = checkbx
        end
    end

    -- 选择的配置(可以多选)    
    self.m_nSelectConfigGameConfigIdx = {1, 0, 0}
    self.m_nSelectConfigGameConfigIdx[1] = CBT_CONFIG_GAMECONFIG + 1
    self.m_tabCheckBox[self.m_nSelectConfigGameConfigIdx[1]]:setSelected(true)

    -- 捉鸟选项
    for i = 1, 3 do
        local checkbx = csbNode:getChildByName("check_1_1_1_" .. i)
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_CONFIG_ZHUONIAO + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_CONFIG_ZHUONIAO + i] = checkbx
        end
    end

    -- 选择捉鸟(只能单选)    
    -- 默认勾选2鸟
    self.m_nSelectZhuoNiaoIdx = 0  

    -- 房间局数
    print("局数列表个数", #PriRoom:getInstance().m_tabFeeConfigList)
    for i = 1, #PriRoom:getInstance().m_tabFeeConfigList do
        local config = PriRoom:getInstance().m_tabFeeConfigList[i]
        local checkbx = csbNode:getChildByName("check_" .. i.."_5")
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_CONFIG_GAMECOUNT + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_CONFIG_GAMECOUNT + i] = checkbx
        end

        local txtcount = csbNode:getChildByName("count_" .. i.."_5")
        if nil ~= txtcount then
            txtcount:setString(config.dwDrawCountLimit .. "局")
        end
    end

    -- 选择的局数    
    self.m_nSelectIdx = CBT_CONFIG_GAMECOUNT + 1
    self.m_tabSelectConfig = PriRoom:getInstance().m_tabFeeConfigList[self.m_nSelectIdx - CBT_CONFIG_GAMECOUNT]
    self.m_tabCheckBox[self.m_nSelectIdx]:setSelected(true)

    self.m_bLow = false
    -- 创建费用
    self.m_txtFee = csbNode:getChildByName("txt_fee")
    self.m_txtFee:setString("")
    if GlobalUserItem.lRoomCard < self.m_tabSelectConfig.lFeeScore then
        self.m_bLow = true
    end
    local feeType = "房卡"
    if nil ~= self.m_tabSelectConfig then        
        if PriRoom:getInstance().m_tabRoomOption.cbCardOrBean == 0 then
            feeType = "游戏豆"
            self.m_bLow = false
            if GlobalUserItem.dUserBeans < self.m_tabSelectConfig.lFeeScore then
                self.m_bLow = true
            end
        end
        self.m_txtFee:setString(self.m_tabSelectConfig.lFeeScore .. feeType)
    end

    -- 提示
    self.m_spTips = csbNode:getChildByName("priland_sp_card_tips")
    self.m_spTips:setVisible(self.m_bLow)
    if PriRoom:getInstance().m_tabRoomOption.cbCardOrBean == 0 then
        local frame = cc.Sprite:create("privateroom/room/priland_sp_card_tips_bean.png")
        if nil ~= frame then
            self.m_spTips:setSpriteFrame(frame:getSpriteFrame())
        end
    end

    -- 创建按钮
    btn = csbNode:getChildByName("btn_createroom")
    btn:setTag(BTN_CREATE)
    btn:addTouchEventListener(btncallback)
end

------
-- 继承/覆盖
------
-- 刷新界面
function PriRoomCreateLayer:onRefreshInfo()
    -- 房卡数更新
    self.m_txtCardNum:setString(GlobalUserItem.lRoomCard .. "")
end

function PriRoomCreateLayer:onLoginPriRoomFinish()
    local meUser = PriRoom:getInstance():getMeUserItem()
    if nil == meUser then
        return false
    end
    -- 发送创建桌子
    if ((meUser.cbUserStatus == yl.US_FREE or meUser.cbUserStatus == yl.US_NULL or meUser.cbUserStatus == yl.US_PLAYING)) then
        if PriRoom:getInstance().m_nLoginAction == PriRoom.L_ACTION.ACT_CREATEROOM then
            -- 创建登陆
            local buffer = CCmd_Data:create(188)
            buffer:setcmdinfo(self._cmd_pri_game.MDM_GR_PERSONAL_TABLE,self._cmd_pri_game.SUB_GR_CREATE_TABLE)
            buffer:pushscore(1)
            buffer:pushdword(self.m_tabSelectConfig.dwDrawCountLimit)
            buffer:pushdword(self.m_tabSelectConfig.dwDrawTimeLimit)
            buffer:pushword(3)
            buffer:pushdword(0)
            buffer:pushstring("", yl.LEN_PASSWORD)

            --游戏额外规则
            buffer:pushbyte(1)

            --人数
            buffer:pushbyte(self.m_nSelectPlayerCountIdx - CBT_CONFIG_PLAYERCOUNT + 1)

            --胡牌类型 1自摸 2点炮
            local cbHuType = 2
            if self.m_nSelectConfigGameRuleIdx - CBT_CONFIG_GAMERULE == 1 then 
                cbHuType = 2
            elseif self.m_nSelectConfigGameRuleIdx - CBT_CONFIG_GAMERULE == 2 then
                cbHuType = 1
            end

            buffer:pushbyte(cbHuType)

            --闲庄算分
            local cbZhuangxian = 0
            if self.m_nSelectConfigGameConfigIdx[1] == 0 then
                cbZhuangxian = 0
            elseif self.m_nSelectConfigGameConfigIdx[1] == CBT_CONFIG_GAMECONFIG + 1 then
                cbZhuangxian = 1
            end

            buffer:pushbyte(cbZhuangxian)

            --七对
            local cbQiDui = 0
            if self.m_nSelectConfigGameConfigIdx[2] == 0 then
                cbQiDui = 0
            elseif self.m_nSelectConfigGameConfigIdx[2] == CBT_CONFIG_GAMECONFIG + 2 then
                cbQiDui = 1
            end      

            buffer:pushbyte(cbQiDui)    

            --红中癞子
            local cbHongZhong = 0
            if self.m_nSelectConfigGameConfigIdx[3] == 0 then
                cbHongZhong = 0
            elseif self.m_nSelectConfigGameConfigIdx[3] == CBT_CONFIG_GAMECONFIG + 3 then
                cbHongZhong = 1
            end 

            buffer:pushbyte(cbHongZhong)       

            --捉鸟 
            local cbZhuoNiao = 0
            if self.m_nSelectZhuoNiaoIdx == 0 then
                cbZhuoNiao = 0
            elseif self.m_nSelectZhuoNiaoIdx ~= 0 then
                cbZhuoNiao = (self.m_nSelectZhuoNiaoIdx - CBT_CONFIG_ZHUONIAO) * 2
            end

            buffer:pushbyte(cbZhuoNiao)

            for i = 1, 93 do
                buffer:pushbyte(0)
            end

            print("sendGameServerMsg")
            PriRoom:getInstance():getNetFrame():sendGameServerMsg(buffer)
            return true
        end        
    end
    return false
end

function PriRoomCreateLayer:getInviteShareMsg( roomDetailInfo )
    local shareTxt = "转转麻将约战 房间ID:" .. roomDetailInfo.szRoomID .. " 局数:" .. roomDetailInfo.dwPlayTurnCount
    local friendC = "转转麻将房间ID:" .. roomDetailInfo.szRoomID .. " 局数:" .. roomDetailInfo.dwPlayTurnCount
    return {title = "转转麻将约战", content = shareTxt .. " 转转麻将精彩刺激, 一起来玩吧! ", friendContent = friendC}
end

function PriRoomCreateLayer:onExit()

end

------
-- 继承/覆盖
------
function PriRoomCreateLayer:onButtonClickedEvent( tag, sender)
    if BTN_HELP == tag then
        self._scene:popHelpLayer2(391, 1)
        --self._scene:popHelpLayer(yl.HTTP_URL .. "/Mobile/Introduce.aspx?kindid=391&typeid=1")
    elseif BTN_CHARGE == tag then
        local feeType = "房卡"
        if PriRoom:getInstance().m_tabRoomOption.cbCardOrBean == 0 then
            feeType = "游戏豆"
        end
        if feeType == "游戏豆" then
            self._scene:onChangeShowMode(yl.SCENE_SHOP, Shop.CBT_BEAN)
        else
            self._scene:onChangeShowMode(yl.SCENE_SHOP, Shop.CBT_PROPERTY)
        end
    elseif BTN_MYROOM == tag then
        self._scene:onChangeShowMode(PriRoom.LAYTAG.LAYER_MYROOMRECORD)
    elseif BTN_CREATE == tag then 
        if self.m_bLow then
            local feeType = "房卡"
            if PriRoom:getInstance().m_tabRoomOption.cbCardOrBean == 0 then
                feeType = "游戏豆"
            end

            local QueryDialog = appdf.req("app.views.layer.other.QueryDialog")
            local query = QueryDialog:create("您的" .. feeType .. "数量不足，是否前往商城充值！", function(ok)
                if ok == true then
                    if feeType == "游戏豆" then
                        self._scene:onChangeShowMode(yl.SCENE_SHOP, Shop.CBT_BEAN)
                    else
                        self._scene:onChangeShowMode(yl.SCENE_SHOP, Shop.CBT_PROPERTY)
                    end                    
                end
                query = nil
            end):setCanTouchOutside(false)
                :addTo(self._scene)
            return
        end
        if nil == self.m_tabSelectConfig or table.nums(self.m_tabSelectConfig) == 0 then
            showToast(self, "未选择玩法配置!", 2)
            return
        end
        PriRoom:getInstance():showPopWait()
        PriRoom:getInstance():getNetFrame():onCreateRoom()
    end
end

function PriRoomCreateLayer:onSelectedEvent(tag, sender)
    
    -- 房间玩法，只能单选
    if tag > CBT_CONFIG_GAMERULE and tag < CBT_CONFIG_PLAYERCOUNT then 
        if self.m_nSelectConfigGameRuleIdx == tag then
            sender:setSelected(true)
            return
        end
        self.m_nSelectConfigGameRuleIdx = tag

        -- 泛型for循环
        for k,v in pairs(self.m_tabCheckBox) do
            if k ~= tag and k > CBT_CONFIG_GAMERULE and k < CBT_CONFIG_PLAYERCOUNT then
                v:setSelected(false)
            end
        end
    end

    -- 人数选项，只能单选
    if tag > CBT_CONFIG_PLAYERCOUNT and tag < CBT_CONFIG_GAMECONFIG then 
        if self.m_nSelectPlayerCountIdx == tag then
            sender:setSelected(true)
            return
        end
        self.m_nSelectPlayerCountIdx = tag

        -- 2人没有红中癞子
        if tag == CBT_CONFIG_PLAYERCOUNT + 1 then
            self.m_tabCheckBox[CBT_CONFIG_GAMECONFIG +3]:setEnabled(false)
            self.m_tabCheckBox[CBT_CONFIG_GAMECONFIG +3]:setSelected(false)
            self.m_nSelectConfigGameConfigIdx[3] = 0
        elseif tag == CBT_CONFIG_PLAYERCOUNT + 2 or tag == CBT_CONFIG_PLAYERCOUNT + 3 then
            self.m_tabCheckBox[CBT_CONFIG_GAMECONFIG +3]:setEnabled(true)
            self.m_tabCheckBox[CBT_CONFIG_GAMECONFIG +3]:setSelected(true)
            self.m_nSelectConfigGameConfigIdx[3] = CBT_CONFIG_GAMECONFIG +3
        end

        -- 2人3人没有捉鸟
        if tag == CBT_CONFIG_PLAYERCOUNT + 1 or tag == CBT_CONFIG_PLAYERCOUNT + 2 then
            for i = 1, 3 do
                self.m_tabCheckBox[CBT_CONFIG_ZHUONIAO +i]:setEnabled(false)
                self.m_tabCheckBox[CBT_CONFIG_ZHUONIAO +i]:setSelected(false)
                self.m_nSelectZhuoNiaoIdx = 0
            end
        elseif tag == CBT_CONFIG_PLAYERCOUNT + 3 then
            for i = 1, 3 do
                self.m_tabCheckBox[CBT_CONFIG_ZHUONIAO +i]:setEnabled(true)
                self.m_tabCheckBox[CBT_CONFIG_ZHUONIAO +i]:setSelected(false)
                self.m_nSelectZhuoNiaoIdx = 0
            end
        end

        -- 泛型for循环
        for k,v in pairs(self.m_tabCheckBox) do
            if k ~= tag and k > CBT_CONFIG_PLAYERCOUNT and k < CBT_CONFIG_GAMECONFIG then
                v:setSelected(false)
            end
        end


    end

    -- 配置选项，可以多选
    if tag > CBT_CONFIG_GAMECONFIG and tag < CBT_CONFIG_ZHUONIAO then --玩法，可以多选
        local num = #self.m_nSelectConfigGameConfigIdx
        local isSelect = false
        for i=1, num do
            if self.m_nSelectConfigGameConfigIdx[i] == tag then
                self.m_nSelectConfigGameConfigIdx[i] = 0
                self.m_tabCheckBox[tag]:setSelected(false)
                isSelect = true
            end
        end
        if not isSelect then --之前没有选
            self.m_nSelectConfigGameConfigIdx[tag - CBT_CONFIG_GAMECONFIG] = tag
            self.m_tabCheckBox[tag]:setSelected(true)
        end
    end

    -- 捉鸟选项，只能单选
    if tag > CBT_CONFIG_ZHUONIAO and tag < CBT_CONFIG_GAMECOUNT then 
        if self.m_nSelectZhuoNiaoIdx == tag then
            sender:setSelected(true)
            return
        end
        self.m_nSelectZhuoNiaoIdx = tag

        -- 泛型for循环
        for k,v in pairs(self.m_tabCheckBox) do
            if k ~= tag and k > CBT_CONFIG_ZHUONIAO and k < CBT_CONFIG_GAMECOUNT then
                v:setSelected(false)
            end
        end
    end

    -- 局数选项
    if tag > CBT_CONFIG_GAMECOUNT and tag < CBT_CONFIG_GAMECOUNT + 10 then --局数
        if self.m_nSelectIdx == tag then
            sender:setSelected(true)
            return
        end
        self.m_nSelectIdx = tag

        -- 泛型for循环
        for k,v in pairs(self.m_tabCheckBox) do
            if k ~= tag and k > CBT_CONFIG_GAMECOUNT and k < CBT_CONFIG_GAMECOUNT + 10 then
                v:setSelected(false)
            end
        end

        self.m_tabSelectConfig = PriRoom:getInstance().m_tabFeeConfigList[tag - CBT_CONFIG_GAMECOUNT]
        if nil == self.m_tabSelectConfig then
            return
        end

        self.m_bLow = false
        if GlobalUserItem.lRoomCard < self.m_tabSelectConfig.lFeeScore then
            self.m_bLow = true
        end
        local feeType = "房卡"
        if PriRoom:getInstance().m_tabRoomOption.cbCardOrBean == 0 then
            feeType = "游戏豆"
            self.m_bLow = false
            if GlobalUserItem.dUserBeans < self.m_tabSelectConfig.lFeeScore then
                self.m_bLow = true
            end
        end
        self.m_txtFee:setString(self.m_tabSelectConfig.lFeeScore .. feeType)
        self.m_spTips:setVisible(self.m_bLow)
        if self.m_bLow then
            local frame = nil
            if PriRoom:getInstance().m_tabRoomOption.cbCardOrBean == 0 then
                frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("priland_sp_card_tips_bean.png")   
            else
                frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("priland_sp_card_tips.png")   
            end
            if nil ~= frame then
                self.m_spTips:setSpriteFrame(frame)
            end
        end
    end
end

return PriRoomCreateLayer