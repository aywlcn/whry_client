--
-- Author: David
-- Date: 2016-4-11 14:07:02
--
-- 斗地主私人房创建界面
local CreateLayerModel = appdf.req(PriRoom.MODULE.PLAZAMODULE .."models.CreateLayerModel")

local PriRoomCreateLayer = class("PriRoomCreateLayer", CreateLayerModel)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local Shop = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.ShopLayer")

local BTN_HELP          = 1
local BTN_CHARGE        = 2
local BTN_MYROOM        = 3
local BTN_CREATE        = 4
local CBT_BEGIN         = 300 --局数
local CBT_CONFIG_BEGIN  = 310  --玩法
local CBT_MAGIC_BEGIN   = 330  --翻鬼
local CBT_MA_BEGIN      = 340  --摸马

function PriRoomCreateLayer:ctor( scene )
    PriRoomCreateLayer.super.ctor(self, scene)
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("room/PrivateRoomCreateLayer.csb", self )
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
    -- 局数选项
    print("局数列表个数", #PriRoom:getInstance().m_tabFeeConfigList)
    for i = 1, #PriRoom:getInstance().m_tabFeeConfigList do
        local config = PriRoom:getInstance().m_tabFeeConfigList[i]
        local checkbx = csbNode:getChildByName("check_" .. i.."_5")
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_BEGIN + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_BEGIN + i] = checkbx
        end

        local txtcount = csbNode:getChildByName("count_" .. i.."_5")
        if nil ~= txtcount then
            txtcount:setString(config.dwDrawCountLimit .. "局")
        end
    end
    -- 选择的玩法    
    self.m_nSelectIdx = CBT_BEGIN + 1
    self.m_tabSelectConfig = PriRoom:getInstance().m_tabFeeConfigList[self.m_nSelectIdx - CBT_BEGIN]
    self.m_tabCheckBox[self.m_nSelectIdx]:setSelected(true)

    -- 玩法选项
    for i = 1, 4 do
        local checkbx = csbNode:getChildByName("check_" .. i)
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_CONFIG_BEGIN + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_CONFIG_BEGIN + i] = checkbx
        end
    end
    -- 选择的玩法(可以多选)    
    self.m_nSelectConfigIdx = {0, 0, 0, 0}
    self.m_nSelectConfigIdx[3] = CBT_CONFIG_BEGIN + 3  --默认勾选可抢杠胡
    self.m_tabCheckBox[self.m_nSelectConfigIdx[3]]:setSelected(true)

    --无鬼加倍字串
    self.m_strNoMagicDouble = csbNode:getChildByName("count_2")

    -- 翻鬼选项
    for i = 1, 4 do
        local checkbx = csbNode:getChildByName("check_" .."1_".. i)
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_MAGIC_BEGIN + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_MAGIC_BEGIN + i] = checkbx
        end
    end

    -- 选择的翻鬼    
    self.m_nSelectMagicIdx = CBT_MAGIC_BEGIN + 1
    self.m_tabCheckBox[self.m_nSelectMagicIdx]:setSelected(true)
    --默认无鬼，无鬼翻倍不可选
    self.m_tabCheckBox[CBT_CONFIG_BEGIN + 2]:setEnabled(false)
    self.m_strNoMagicDouble:setColor(cc.c3b(127,127,127))

    -- 码数选项
    for i = 1, 5 do
        local checkbx = csbNode:getChildByName("check_" .."1_".. i.."_0")
        if nil ~= checkbx then
            checkbx:setVisible(true)
            checkbx:setTag(CBT_MA_BEGIN + i)
            checkbx:addEventListener(cbtlistener)
            checkbx:setSelected(false)
            self.m_tabCheckBox[CBT_MA_BEGIN + i] = checkbx
        end
    end

    -- 选择的马数    
    self.m_nSelectMaIdx = CBT_MA_BEGIN + 1
    self.m_tabCheckBox[self.m_nSelectMaIdx]:setSelected(true)



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
        local frame = cc.Sprite:create("room/priland_sp_card_tips_bean.png")
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
            --马
            local maTable = {0 , 2, 4, 6, 8}
            buffer:pushbyte(maTable[self.m_nSelectMaIdx -CBT_MA_BEGIN])
            --翻鬼模式
            local magicTable = {0 , 1, 2, 3}
            buffer:pushbyte(magicTable[self.m_nSelectMagicIdx -CBT_MAGIC_BEGIN])
            --玩法配置
            if self.m_nSelectConfigIdx[1] ~= 0  then
                buffer:pushbyte(0)
                print("创建房卡房间，没有字牌")
            else
                buffer:pushbyte(1)
                print("创建房卡房间，有字牌")
            end
            for i=2,4 do
                if self.m_nSelectConfigIdx[i] ~= 0  then
                    buffer:pushbyte(1)
                else
                    buffer:pushbyte(0)
                end
            end

            for i = 1, 93 do
                buffer:pushbyte(0)
            end
            PriRoom:getInstance():getNetFrame():sendGameServerMsg(buffer)
            return true
        end        
    end
    return false
end

function PriRoomCreateLayer:getInviteShareMsg( roomDetailInfo )
    local shareTxt = "广东麻将约战 房间ID:" .. roomDetailInfo.szRoomID .. " 局数:" .. roomDetailInfo.dwPlayTurnCount
    local friendC = "广东麻将房间ID:" .. roomDetailInfo.szRoomID .. " 局数:" .. roomDetailInfo.dwPlayTurnCount
    return {title = "广东麻将约战", content = shareTxt .. " 广东麻将精彩刺激, 一起来玩吧! ", friendContent = friendC}
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
    if tag > CBT_BEGIN and tag < CBT_CONFIG_BEGIN then --局数
        if self.m_nSelectIdx == tag then
            sender:setSelected(true)
            return
        end
        self.m_nSelectIdx = tag
        for k,v in pairs(self.m_tabCheckBox) do
            if k ~= tag and k > CBT_BEGIN and k < CBT_CONFIG_BEGIN then
                v:setSelected(false)
            end
        end
        self.m_tabSelectConfig = PriRoom:getInstance().m_tabFeeConfigList[tag - CBT_BEGIN]
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
    if tag > CBT_CONFIG_BEGIN and tag < CBT_MAGIC_BEGIN then --玩法，可以多选
        local num = #self.m_nSelectConfigIdx
        local isSelect = false
        for i=1, num do
            if self.m_nSelectConfigIdx[i] == tag then
                self.m_nSelectConfigIdx[i] = 0
                self.m_tabCheckBox[tag]:setSelected(false)
                isSelect = true
            end
        end
        if not isSelect then --之前没有选
            self.m_nSelectConfigIdx[tag - CBT_CONFIG_BEGIN] = tag
            self.m_tabCheckBox[tag]:setSelected(true)
        end
    end

    if tag > CBT_MAGIC_BEGIN and tag < CBT_MA_BEGIN then --鬼牌，可以多选
        if self.m_nSelectMagicIdx == tag then
            sender:setSelected(true)
            return
        end
        self.m_nSelectMagicIdx = tag
        if self.m_nSelectMagicIdx -CBT_MAGIC_BEGIN == 1 then  --第一项，无鬼，选择则无鬼加倍不可选
            self.m_nSelectConfigIdx[2] = 0  --如果之前已经选择，变为未选
            self.m_tabCheckBox[CBT_CONFIG_BEGIN +2]:setSelected(false)
            self.m_tabCheckBox[CBT_CONFIG_BEGIN +2]:setEnabled(false)
            self.m_strNoMagicDouble:setColor(cc.c3b(127,127,127))
        else
            self.m_tabCheckBox[CBT_CONFIG_BEGIN +2]:setEnabled(true)
            self.m_strNoMagicDouble:setColor(cc.c3b(0xde,0xdd,0x0c))
        end
        for k,v in pairs(self.m_tabCheckBox) do
            if k ~= tag  and  k > CBT_MAGIC_BEGIN and k < CBT_MA_BEGIN then
                v:setSelected(false)
            end
        end
    end

    if tag > CBT_MA_BEGIN then --码数，可以多选
        if self.m_nSelectMaIdx == tag then
            sender:setSelected(true)
            return
        end
        self.m_nSelectMaIdx = tag
        for k,v in pairs(self.m_tabCheckBox) do
            if k ~= tag  and  k > CBT_MA_BEGIN  then
                v:setSelected(false)
            end
        end
    end
end

return PriRoomCreateLayer