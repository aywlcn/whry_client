--
-- Author: David
-- Date: 2017-4-11 11:13:57
--
-- 私人房游戏顶层
local PrivateLayerModel = appdf.req(PriRoom.MODULE.PLAZAMODULE .."models.PrivateLayerModel")
local PriGameLayer = class("PriGameLayer", PrivateLayerModel)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local PopupInfoHead = appdf.req(appdf.EXTERNAL_SRC .. "PopupInfoHead")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.CMD_Game")
local HeadSprite = appdf.req(appdf.EXTERNAL_SRC .. "HeadSprite")
local cmd_private = appdf.req(appdf.CLIENT_SRC .. "privatemode.header.CMD_Private")
local BTN_DISMISS = 101
local BTN_INVITE = 102
local BTN_SHARE = 103
local BTN_QUIT = 104
local BTN_ZANLI = 105
local BTN_CLOSE = 106
function PriGameLayer:ctor( gameLayer )
    PriGameLayer.super.ctor(self, gameLayer)
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("privateroom/game/PrivateGameLayer.csb", self )
    self.m_rootLayer = rootLayer

    local bfind = cc.FileUtils:getInstance():isFileExist("game/bt_dismiss1.png")
    print("PriGameLayer", bfind)

    --
    local image_bg = csbNode:getChildByName("Image_bg")

    -- 房间ID
    self.m_atlasRoomID = image_bg:getChildByName("num_roomID")
    self.m_atlasRoomID:setString("000000")

    -- 局数
    self.m_atlasCount = image_bg:getChildByName("num_count")
    self.m_atlasCount:setString("0 / 0")

    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end
    -- 解散按钮
    self.btndismiss = image_bg:getChildByName("bt_dismiss")
    self.btndismiss:setTag(BTN_DISMISS)
    self.btndismiss:addTouchEventListener(btncallback)

    -- 暂离按钮
    self.btnzanli = image_bg:getChildByName("bt_zanli")
    self.btnzanli:setTag(BTN_ZANLI)
    self.btnzanli:addTouchEventListener(btncallback)

    -- 邀请按钮
    self.m_btnInvite = csbNode:getChildByName("bt_invite")
    self.m_btnInvite:setTag(BTN_INVITE)
    self.m_btnInvite:addTouchEventListener(btncallback)
end

function PriGameLayer:onButtonClickedEvent( tag, sender )
    if BTN_DISMISS == tag then              -- 请求解散游戏
        PriRoom:getInstance():queryDismissRoom()
    elseif BTN_INVITE == tag then
        PriRoom:getInstance():getPlazaScene():popTargetShare(function(target, bMyFriend)
            bMyFriend = bMyFriend or false
            local function sharecall( isok )
                if type(isok) == "string" and isok == "true" then
                    showToast(self, "分享成功", 2)
                end
                GlobalUserItem.bAutoConnect = true
            end
            local shareTxt = "转转麻将约战 房间ID:" .. self.m_atlasRoomID:getString() .. " 局数:" .. PriRoom:getInstance().m_tabPriData.dwDrawCountLimit
            local friendC = "转转麻将房间ID:" .. self.m_atlasRoomID:getString() .. " 局数:" .. PriRoom:getInstance().m_tabPriData.dwDrawCountLimit
            local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
            if bMyFriend then
                PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_FRIENDLIST, function( frienddata )
                    local serverid = tonumber(PriRoom:getInstance().m_tabPriData.szServerID) or 0                    
                    PriRoom:getInstance():priInviteFriend(frienddata, GlobalUserItem.nCurGameKind, serverid, yl.INVALID_TABLE, friendC)
                end)
            elseif nil ~= target then
                GlobalUserItem.bAutoConnect = false
                MultiPlatform:getInstance():shareToTarget(target, sharecall, "转转麻将约战", shareTxt .. " 转转麻将精彩刺激, 一起来玩吧! ", url, "")
            end
        end)
    elseif BTN_SHARE == tag then
        PriRoom:getInstance():getPlazaScene():popTargetShare(function(target, bMyFriend)
            bMyFriend = bMyFriend or false
            local function sharecall( isok )
                if type(isok) == "string" and isok == "true" then
                    showToast(self, "分享成功", 2)
                end
                GlobalUserItem.bAutoConnect = true
            end
            local url = GlobalUserItem.szWXSpreaderURL or yl.HTTP_URL
            -- 截图分享
            local framesize = cc.Director:getInstance():getOpenGLView():getFrameSize()
            local area = cc.rect(0, 0, framesize.width, framesize.height)
            local imagename = "grade_share.jpg"
            if bMyFriend then
                imagename = "grade_share_" .. os.time() .. ".jpg"
            end
            ExternalFun.popupTouchFilter(0, false)
            captureScreenWithArea(area, imagename, function(ok, savepath)
                ExternalFun.dismissTouchFilter()
                if ok then
                    if bMyFriend then
                        PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_FRIENDLIST, function( frienddata )
                            PriRoom:getInstance():imageShareToFriend(frienddata, savepath, "分享我的约战房战绩")
                        end)
                    elseif nil ~= target then
                        GlobalUserItem.bAutoConnect = false
                        MultiPlatform:getInstance():shareToTarget(target, sharecall, "我的约战房战绩", "分享我的约战房战绩", url, savepath, "true")
                    end            
                end
            end)
        end)
    elseif BTN_QUIT == tag then
        GlobalUserItem.bWaitQuit = false
        self._gameLayer:onExitRoom()
    elseif BTN_CLOSE == tag then
        GlobalUserItem.bWaitQuit = false
        self._gameLayer:onExitRoom()
    elseif BTN_ZANLI == tag then
        PriRoom:getInstance():tempLeaveGame()
        self._gameLayer:onExitRoom()
    end

   
end

------
-- 继承/覆盖
------
-- 刷新界面
function PriGameLayer:onRefreshInfo()
    -- 房间ID
    self.m_atlasRoomID:setString(PriRoom:getInstance().m_tabPriData.szServerID or "000000")

    -- 局数
    local strcount = PriRoom:getInstance().m_tabPriData.dwPlayCount .. " / " .. PriRoom:getInstance().m_tabPriData.dwDrawCountLimit
    self.m_atlasCount:setString(strcount)

    self:onRefreshInviteBtn()
end

function PriGameLayer:onRefreshInviteBtn()
    if self._gameLayer.m_cbGameStatus ~= 0 then --空闲场景
        self.m_btnInvite:setVisible(false)
        return
    end

    -- 邀请按钮
    if nil ~= self._gameLayer.onGetSitUserNum then
        local chairCount = PriRoom:getInstance():getChairCount()
        print("邀请按钮,系统下发，坐下人数",chairCount, self._gameLayer:onGetSitUserNum())
        if self._gameLayer:onGetSitUserNum() == chairCount then
            self.m_btnInvite:setVisible(false)
            return
        end
    end
    self.m_btnInvite:setVisible(true)
end

-- 私人房游戏结束
function PriGameLayer:onPriGameEnd(cmd_table, dataBuffer)
    self._gameLayer.m_bPriEnd = true
    self.btndismiss:setEnabled(false)
    self.btnzanli:setEnabled(false)

    self._gameLayer._gameView:removeChildByName("private_end_layer")
    local csbNode = ExternalFun.loadCSB("game/gameprEndLayer.csb", self._gameLayer._gameView)
    csbNode:setVisible(false)
    csbNode:setName("private_end_layer")
    csbNode:setLocalZOrder(90)
    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

    local cmd_pri_game = cmd_private.game
    print("dataBuffer", dataBuffer)
    -- 读数据流
    PriGameLayer.USERACHIEVEMENT = 
    {
        {k = "userachievement", t = "table", d = cmd.USERACHIEVEMENT, l = {cmd.zhzmj_GAME_PLAYER}},
    }

    local cmd_data = ExternalFun.read_netdata(PriGameLayer.USERACHIEVEMENT, dataBuffer);
    print("cbZiMO11", cmd_data.userachievement[1][1].cbZiMO)
    print("cbZiMO21", cmd_data.userachievement[1][1].cbJiePao)
    print("cbZiMO31", cmd_data.userachievement[1][1].cbDianPao)
    print("cbZiMO41", cmd_data.userachievement[1][1].cbAnGang)


    local chairCount = PriRoom:getInstance():getChairCount()
    -- 玩家成绩
    local scoreList = cmd_table.lScore[1]

    print("chairCount", chairCount)
    for i = 1, chairCount do
        local useritem = self._gameLayer:getUserInfoByChairID(i - 1)
        print("onPriGameEnd", useritem)
        --用户信息不为空
        if useritem ~= nil then
            --用户结算框架
            print("sp_effect_", i-1)
            local sp_effect = csbNode:getChildByName(string.format("sp_effect_%d", i-1))
            sp_effect:setVisible(true)

            --头像
            local sp_headim = sp_effect:getChildByName(string.format("sp_headim_%d", i-1))
            local head = HeadSprite:createClipHead(useritem, 110)
            head:setPosition(54.5, 54.5)
            head:setVisible(true)
            sp_headim:addChild(head)

            --昵称
            local text_resultnickname = sp_effect:getChildByName(string.format("text_resultnickname_%d", i-1))
            local strNickname = string.EllipsisByConfig(useritem.szNickName, 190, string.getConfig("fonts/round_body.ttf", 21))
            text_resultnickname:setString(strNickname)

            --总成绩
            local text_resultscore = sp_effect:getChildByName(string.format("text_resultscore_%d", i-1))
            text_resultscore:setString(scoreList[i])

            --自摸
            local text_zimo = sp_effect:getChildByName(string.format("text_zimo_%d", i-1))
            text_zimo:setString(cmd_data.userachievement[1][i].cbZiMO)
      
            --接炮
            local text_jiepao = sp_effect:getChildByName(string.format("text_jiepao_%d", i-1))
            text_jiepao:setString(cmd_data.userachievement[1][i].cbJiePao)

            --点炮
            local text_dianpao = sp_effect:getChildByName(string.format("text_dianpao_%d", i-1))
            text_dianpao:setString(cmd_data.userachievement[1][i].cbDianPao)

            --暗杠
            local text_angang = sp_effect:getChildByName(string.format("text_angang_%d", i-1))
            text_angang:setString(cmd_data.userachievement[1][i].cbAnGang)    

            --明杠
            local text_minggang = sp_effect:getChildByName(string.format("text_minggang_%d", i-1))
            text_minggang:setString(cmd_data.userachievement[1][i].cbMingGang)    

        end
    end

    -- 分享按钮
    local btn = csbNode:getChildByName("bt_share")
    btn:setTag(BTN_SHARE)
    btn:addTouchEventListener(btncallback)

    -- 退出按钮
    btn = csbNode:getChildByName("bt_qiut")
    btn:setTag(BTN_QUIT)
    btn:addTouchEventListener(btncallback)

    --关闭按钮
    btn = csbNode:getChildByName("bt_close_result")
    btn:setTag(BTN_CLOSE)
    btn:addTouchEventListener(btncallback)
    
    csbNode:runAction(cc.Sequence:create(cc.DelayTime:create(3.0),
        cc.CallFunc:create(function()
            csbNode:setVisible(true)
        end)))
end

function PriGameLayer:onExit()

end

return PriGameLayer