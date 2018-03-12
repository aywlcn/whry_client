
local GameViewLayer = { }
-- GameViewLayer.RES_PATH 				= device.writablePath.."game/yule/watermargin/res/"
GameViewLayer.RES_PATH = "game/yule/97quanhuang/res/"
-- 游戏一
local Game1ViewLayer = class("Game1ViewLayer", function(scene)
    local gameViewLayer = display.newLayer()
    return gameViewLayer
end )
GameViewLayer[1] = Game1ViewLayer
----	游戏二
-- local Game2ViewLayer = class("Game2ViewLayer",function(scene)
-- 	local gameViewLayer =  display.newLayer()
--    return gameViewLayer
-- end)
-- GameViewLayer[2] = Game2ViewLayer
-- 游戏三
local Game3ViewLayer = class("Game3ViewLayer", function(scene)
    local gameViewLayer = display.newLayer()
    return gameViewLayer
end )
GameViewLayer[3] = Game3ViewLayer

local module_pre = "game.yule.97quanhuang.src"
local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")
local g_var = ExternalFun.req_var
local ClipText = appdf.EXTERNAL_SRC .. "ClipText"

local cmd = module_pre .. ".models.CMD_Game"
local QueryDialog = require("app.views.layer.other.QueryDialog")

local GameItem = appdf.req(module_pre .. ".views.layer.GameItem")
local Countdown_ = appdf.req(module_pre .. ".views.CountdownNew")  -- 123 到计时 

local PRELOAD = require(module_pre .. ".views.layer.PreLoading")

local SettingLayer = appdf.req(module_pre .. ".views.layer.SettingLayer")
local HelpLayer = appdf.req(module_pre .. ".views.layer.HelpLayer")

GameViewLayer.RES_PATH = device.writablePath .. "game/yule/97quanhuang/res/"

local enGameLayer =
{
    "TAG_SETTING_MENU",-- 设置
    "TAG_QUIT_MENU",-- 退出
    "TAG_START_MENU",-- 开始按钮
    "TAG_HELP_MENU",-- 游戏帮助
    "TAG_MAXADD_BTN",-- 最大下注
    "TAG_MINADD_BTN",-- 最小下注
    "TAG_ADD_BTN",-- 加注
    "TAG_SUB_BTN",-- 减注
    "TAG_AUTO_START_BTN",-- 自动游戏
    "TAG_GAME2_BTN",-- 开始游戏2
    "TAG_HIDEUP_BTN",-- 隐藏上部菜单
    "TAG_SHOWUP_BTN",-- 显示上部菜单
    "TAG_HALF_IN",-- 半比
    "TAG_ALL_IN",-- 全比
    "TAG_DOUBLE_IN",-- 倍比
    "TAG_GAME2_EXIT",-- 取分
    "TAG_SMALL_IN",-- 押小
    "TAG_MIDDLE_IN",-- 押和
    "TAG_BIG_IN",-- 押大
    "TAG_GO_ON"-- 继续 
}
local TAG_ENUM = ExternalFun.declarEnumWithTable(GameViewLayer.TAG_START, enGameLayer);

local emGame2Actstate =
{
    "STATE_WAITTING",-- 等待
    "STATE_WAVE",-- 摇奖
    "STATE_OPEN",-- 开奖
    "STATE_RESULT"-- 结算
}
local Game2_ACTSTATE = ExternalFun.declarEnumWithTable(0, emGame2Actstate)

local emGame2State =
{
    "GAME2_STATE_WAITTING",-- 等待
    "GAME2_STATE_WAVING",-- 摇奖
    "GAME2_STATE_WAITTING_CHOICE",-- 等待下注
    "GAME2_STATE_OPEN",-- 开奖
    "GAME2_STATE_RESULT"-- 结算,等待继续或区分
}
local GAME2_STATE = ExternalFun.declarEnumWithTable(0, emGame2State)

local emGameLabel =
{
    "LABEL_COINS",-- 玩家金钱
    "LABEL_YAXIAN",-- 压线
    "LABEL_YAFEN",-- 压分
    "LABEL_TOTLEYAFEN",-- 总压分
    "LABEL_GETCOINS",-- 获取金钱
    "LABEL_GAME3_TIMES"-- 小玛丽次数  -- 小游戏
}
local GAME2_STATE = ExternalFun.declarEnumWithTable(10, emGameLabel)

function Game1ViewLayer:ctor(scene)

    -- 暂停背景音乐
    AudioEngine.pauseMusic()

    -- 注册node事件
    ExternalFun.registerNodeEvent(self)

    self._scene = scene
    -- 添加路径
    self:addPath()

    self._scene:showPopWait()
    -- 预加载资源
    PRELOAD.loadTextures()
    self._scene:dismissPopWait()

    -- 特殊图标动画开启播放以及关闭
    self.Show_GunDong_End = true

    -- 存储每列的动作动画，用于控制关闭动画
    self.Run_All_Eef_DongHua = { 0, 0, 0, 0, 0 }
    -- 存储每列的开场动画，用于控制关闭动画
    self.Run_All_Eef_KaiChang = { 0, 0, 0, 0, 0 }
    -- 存储每列的慢慢显示的动画，用于控制关闭动画
    self.Run_All_Eef_XianShi = { 0, 0, 0, 0, 0 }
    -- 在白神播放的中点击开始游戏，停止播放动画
    self.Stop_All_Eef = true
    -- 在军女播放的中点击开始游戏，停止播放动画
    self.Stop_JunNv_Eef = true
    -- 存储每列特殊图标的播放列坐标
    self.Run_TaiYangShen_View_TeXiao = { 0, 0, 0, 0, 0 }
    self.Run_JunNv_View_TeXiao = { 0, 0, 0, 0, 0 }
    self.Run_BaiShen_View_TeXiao = { 0, 0, 0, 0, 0 }
    -- 当前局是否能产生特殊符号加速
    self.Stop_All_GunDong = true
    -- 当前是否有特殊图标
    self.TeShuTuBiao = false
    -- --初始化csb界面
    self:initCsbRes();
    -- 音效ID
    self.Muis2 = 0
    -- 控制停止小头像结束
    self.DongHua_ZanTing = false
    -- 控制结算
    self.DongHua_JieSuan = false
    -- 当前是否存于免费游戏中
    self.MianFeiMu = false
    -- 免费游戏的框特效
    self.MianFeiTeXiao = nil
    -- 免费游戏金币累加变量
    self.MianFeiJinBiZhi = 0
    -- 结算播放动画时间
    self.RunEefTime = 2
    -- 免费次数显示时间
    self.MIANFEICISHUXIANSHI = false
    -- 免费游戏更新显示
    self.MianFeiCiShuGengXin = 0
    -- 当前局数是否有百搭动画播放设定百搭播放时间事件
    self.BaiDaTime = 0.5  
end

  
function Game1ViewLayer:onExit()

    PRELOAD.unloadTextures()
    PRELOAD.removeAllActions()

    PRELOAD.resetData()

    self:StopLoading(true)
    -- 停止播放所有音效
    AudioEngine.stopAllEffects()

    if self.Muis2 == 1 then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerYX)
    end

    -- 播放大厅背景音乐
    ExternalFun.playPlazzBackgroudAudio()

    -- 重置搜索路径
    local oldPaths = cc.FileUtils:getInstance():getSearchPaths();

    cc.FileUtils:getInstance():setSearchPaths(self._searchPath);
    local searchpath = cc.FileUtils:getInstance():getSearchPaths()

end

function Game1ViewLayer:StopLoading(bRemove)
    PRELOAD.StopAnim(bRemove)
end

function Game1ViewLayer:addPath()

    self._searchPath = cc.FileUtils:getInstance():getSearchPaths()
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH)
    -- cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "game1/");
    -- cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "game2/");
    -- cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "game3/");  Plist
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Plist/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Button/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/ICON/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Number/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/ViewLayer/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BaiShen/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/JunNV/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/Small_Game_Effects/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Help/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BeiShu/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/anger/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/BK/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Btn/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Head/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/");


    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "common/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "setting/");
    cc.FileUtils:getInstance():addSearchPath(GameViewLayer.RES_PATH .. "sound_res/");
    --  声音

end

---------------------------------------------------------------------------------------
-- 界面初始化
function Game1ViewLayer:initCsbRes()
    rootLayer, self._csbNode = ExternalFun.loadRootCSB(GameViewLayer.RES_PATH .. "King.csb", self);

    -- 持续按下计时
    Duration = true

    -- 特殊图标动画添加的层
    self.TeSuTuBiaoDongHuaJieDian = self._csbNode:getChildByName("show_dongzuo")
    self.TeSuTuBiaoDongHuaJieDian:setZOrder(5)

    self:runAction(
    cc.Sequence:create(
    cc.DelayTime:create(0.1 * 22 + 0.2 + 2),
    cc.CallFunc:create( function()
        PRELOAD.FatherBiZhi:setVisible(false)

        --    			初始化按钮
        self:initUI(self._csbNode)
        -- 播放背景音乐
        ExternalFun.playBackgroudAudio("QUANHUANG.mp3")
    end )
    )
    )
    -- 特殊图标是否正处于播放中
    self.szSpecial_Spirit = false
    self.XXOOSHOWDONGHUA = true

    self.count = 0
    self.isTouch = false
    self.longPress = false
    self.isMoved = false


end
-- 小游戏赢得金币
local XiaoYouXiJiBI = 0

-- 初始化按钮
function Game1ViewLayer:initUI(csbNode)
--    self.ZiDongGame = false
--    -- 是否触发自动游戏 检测按键回调与定时器回调时间不同步

--    -- 按钮回调方法
--    local function btnEvent(sender, eventType)

--        -- 持续按下开始游戏变成自动开始游戏
--        self.AutoStart = false
--        if eventType == ccui.TouchEventType.began then
--            print("当前按下")
--            ExternalFun.popupTouchFilter(1, false)

--            self.ZiDongGame = true

--            if self._scene.m_bIsAuto then
--                self._scene.m_bIsAuto = false
--            end
--            -- 按下的一瞬间开启定时器，检测当前用户数是否为持续按下
--            if sender:getTag() == TAG_ENUM.TAG_START_MENU and self.XXOOSHOWDONGHUA then 
--                local scheduler = cc.Director:getInstance():getScheduler()
--                self.schedulerID = nil
--                self.schedulerID = scheduler:scheduleScriptFunc( function()
--                    self:JIANGJINCHIJINBI()
--                end , 2, false)
--            end 
--        elseif eventType == ccui.TouchEventType.canceled then
--            print("当前移开")
--            ExternalFun.dismissTouchFilter()
--            if sender:getTag() == TAG_ENUM.TAG_START_MENU then
--                if Duration == true or self.ZiDongGame and self._scene_m_bIsAuto then
--                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID) 
--                end

--            end 
--        elseif eventType == ccui.TouchEventType.ended then
--            ExternalFun.dismissTouchFilter()

--            if sender:getTag() == TAG_ENUM.TAG_START_MENU and self.AutoStart == false and Duration ~= 100 then
--                -- 如果没有达标则运行一次
--                if Duration == true or self.ZiDongGame then
--                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
--                    self.ZiDongGame = false
--                end

--                if self.szSpecial_Spirit and self.XXOOSHOWDONGHUA then
--                    self:Show_Held_Eef()
--                    self.szSpecial_Spirit = false 
--                end

--                -- 如果小头像动画正在播放那么再次点击时结束小头像动画播放
--                -- 没有播放则发送开始请求
--                if self.DongHua_ZanTing then
--                    local a = 1
--                    AudioEngine:stopAllEffects()
--                    for i = 1, 15 do
--                        local posx = math.ceil(i / 3)
--                        local posy =(i - 1) % 3 + 1
--                        local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
--                        local node = self._csbNode:getChildByName(nodeStr)

--                        if node then
--                            local pItem = node:getChildByTag(1)
--                            if pItem then
--                                pItem:stopAllItemActionSamll()
--                                pItem:setState(0)

--                            end
--                        end 
--                    end

--                    for i = 1, 5 do
--                        if self.Run_All_Eef_DongHua[i] ~= 0 then
--                            self.Run_All_Eef_DongHua[i]:setVisible(false)
--                            self.Run_All_Eef_DongHua[i]:removeFromParent()
--                            self.Run_All_Eef_DongHua[i] = 0
--                        end
--                        if self.Run_All_Eef_KaiChang[i] ~= 0 then
--                            self.Run_All_Eef_KaiChang[i]:setVisible(false)
--                            self.Run_All_Eef_KaiChang[i]:removeFromParent()
--                            self.Run_All_Eef_KaiChang[i] = 0
--                        end
--                        if self.Run_All_Eef_XianShi[i] ~= 0 then
--                            self.Run_All_Eef_XianShi[i]:setVisible(false)
--                            self.Run_All_Eef_XianShi[i]:removeFromParent()
--                            self.Run_All_Eef_XianShi[i] = 0
--                        end
--                        self.Run_TaiYangShen_View_TeXiao[i] = 0
--                        self.Run_JunNv_View_TeXiao[i] = 0
--                        self.Run_BaiShen_View_TeXiao[i] = 0
--                    end

--                    self.DongHua_ZanTing = false
--                    self.DongHua_JieSuan = true
--                    self:ZanTingDongHua()
--                    self.Stop_All_Eef = false
--                else
--                    print("没有持续按下")
--                    self:Button_Gray(false)
--                    self:onButtonClickedEvent(sender:getTag(), sender)
--                end

--            else
--                if Duration ~= true then
--                    self:onButtonClickedEvent(sender:getTag(), sender)
--                end
--            end
--        end

--        -- 并且每次抬起清零累加值
--        Duration = true
--    end

 local function beginhandle()
--     if self.isTouch then
--         self.count = self.count + 1
--         -- 累加值，此定时器为1秒执行一次
--         print ("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!按下中")
--         if self.count >= 2 then
--             self.longPress = true
--             self.count = 0
--             self:Button_Gray(false)
--             self._scene:onAutoStart()
--             -- 进入自动游戏状态

--             cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.beginHandle )
--             -- 关闭定时器
--         end
--     end
 end
	
 
 
 local function btnEvent(ref, type)
 
            if type == ccui.TouchEventType.began then 
                print("当前按下") 
				ExternalFun.popupTouchFilter(1, false) 
--               self.isTouch = true  -- 按钮持续按下状态 
--				    if self._scene.m_bIsAuto then   -- 判定当前游戏模式是否为自动游戏中，如果为真则切换为正常游戏模式
--                        if ref:getTag() == TAG_ENUM.TAG_START_MENU  then
--					        self._scene.m_bIsAuto = false
--                        end
--				    end 
--				-- 当前按下后开启一个间隔为1秒的定时器，定时器回调主要流程是判定是否为持续按下
--				if ref:getTag() == TAG_ENUM.TAG_START_MENU and self.XXOOSHOWDONGHUA then 
--					self.beginHandle = cc.Director:getInstance():getScheduler():scheduleScriptFunc(beginhandle,1,false)    
--				end

            elseif type == ccui.TouchEventType.moved then
                --print("当前移开")
				ExternalFun.dismissTouchFilter()  
            elseif type == ccui.TouchEventType.ended then
                -- 当前抬起
                ExternalFun.dismissTouchFilter() 
--				self.count = 0
				if ref:getTag() == TAG_ENUM.TAG_START_MENU then
--                    if self.beginHandle ~= nil then
--                        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.beginHandle)
--                    end
--					if self.longPress == false then	-- 当前不是自动游戏状态

--						if self.szSpecial_Spirit and self.XXOOSHOWDONGHUA then  -- 按钮状态的设定
--							self:Show_Held_Eef()
--							self.szSpecial_Spirit = false 
--						end
						
						-- 如果小头像动画正在播放那么再次点击时结束小头像动画播放
						-- 没有播放则发送开始请求
						if self.DongHua_ZanTing then
							local a = 1
							AudioEngine:stopAllEffects()
							for i = 1, 15 do
								local posx = math.ceil(i / 3)
								local posy =(i - 1) % 3 + 1
								local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
								local node = self._csbNode:getChildByName(nodeStr)

								if node then
									local pItem = node:getChildByTag(1)
									if pItem then
										pItem:stopAllItemActionSamll()
										pItem:setState(0)

									end
								end 
							end

							for i = 1, 5 do
								if self.Run_All_Eef_DongHua[i] ~= 0 then
									self.Run_All_Eef_DongHua[i]:setVisible(false)
									self.Run_All_Eef_DongHua[i]:removeFromParent()
									self.Run_All_Eef_DongHua[i] = 0
								end
								if self.Run_All_Eef_KaiChang[i] ~= 0 then
									self.Run_All_Eef_KaiChang[i]:setVisible(false)
									self.Run_All_Eef_KaiChang[i]:removeFromParent()
									self.Run_All_Eef_KaiChang[i] = 0
								end
								if self.Run_All_Eef_XianShi[i] ~= 0 then
									self.Run_All_Eef_XianShi[i]:setVisible(false)
									self.Run_All_Eef_XianShi[i]:removeFromParent()
									self.Run_All_Eef_XianShi[i] = 0
								end
								self.Run_TaiYangShen_View_TeXiao[i] = 0
								self.Run_JunNv_View_TeXiao[i] = 0
								self.Run_BaiShen_View_TeXiao[i] = 0
							end

							self.DongHua_ZanTing = false
							self.DongHua_JieSuan = true
							self:ZanTingDongHua()
							self.Stop_All_Eef = false
                            self:Button_Gray(false)
						else
							print("没有持续按下")
							self:Button_Gray(false)
							self:onButtonClickedEvent(ref:getTag(), ref)
--						end
					end
					
--					self.isTouch = false  -- 重置按钮状态
				else
					self:onButtonClickedEvent(ref:getTag(), ref)
				end  
            end 
    end 

    -- 最大押注
    self.Button_Max = csbNode:getChildByName("Button_Max");
    self.Button_Max:setTag(TAG_ENUM.TAG_MAXADD_BTN);
    self.Button_Max:addTouchEventListener(btnEvent);
    self.Button_Max:setZOrder(3)
    -- 减少
    self.Button_Sub = csbNode:getChildByName("Button_Sub");
    self.Button_Sub:setTag(TAG_ENUM.TAG_SUB_BTN);
    self.Button_Sub:addTouchEventListener(btnEvent);
    self.Button_Sub:setZOrder(3)
    -- 减少
    self.Button_Add = csbNode:getChildByName("Button_Add");
    self.Button_Add:setTag(TAG_ENUM.TAG_ADD_BTN);
    self.Button_Add:addTouchEventListener(btnEvent);
    self.Button_Add:setZOrder(3)
    -- 开始
    self.Button_Start = csbNode:getChildByName("Button_Start");
    self.Button_Start:setTag(TAG_ENUM.TAG_START_MENU);
    self.Button_Start:addTouchEventListener(btnEvent);
    self.Button_Start:setZOrder(3)

    -- 自动加注
    self.Button_Auto = csbNode:getChildByName("Button_2");
    self.Button_Auto :setTag(TAG_ENUM.TAG_AUTO_START_BTN);
    self.Button_Auto :addTouchEventListener(btnEvent);

    self.Button_Auto:setZOrder(3)

    local Button_Show = csbNode:getChildByName("QH_ZIDONG_1_2");
    Button_Show:setVisible(false)
    Button_Show:setZOrder(4)

    local Button_Show = csbNode:getChildByName("QH_MIAOFEI_1"); 
    Button_Show:setZOrder(3)

    -- 显示菜单
    local Button_Show = csbNode:getChildByName("Button_Show");
    Button_Show:setTag(TAG_ENUM.TAG_SHOWUP_BTN);
    Button_Show:addTouchEventListener(btnEvent);
    Button_Show:setZOrder(3)

    self.m_textScore = self._scene:GetMeUserItem().lScore
    self.m_textYaxian = g_var(cmd).YAXIANNUM
    self.m_textYafen = 10
    self.m_textAllyafen = 90
    self.m_textGetScore = 0
    self.m_textFreeNum = 0

    ------
    -- 菜单
    self.m_nodeMenu = csbNode:getChildByName("Node_Menu");
    self.m_nodeMenu:setZOrder(11)
    -- 返回
    local Button_back = self.m_nodeMenu:getChildByName("Button_back");
    Button_back:setTag(TAG_ENUM.TAG_QUIT_MENU);
    Button_back:addTouchEventListener(btnEvent);
     
    -- 帮助
    local Button_Help = self.m_nodeMenu:getChildByName("Button_Help");
    Button_Help:setTag(TAG_ENUM.TAG_HELP_MENU);
    Button_Help:addTouchEventListener(btnEvent);
    -- 设置
    local Button_Set = self.m_nodeMenu:getChildByName("Button_Set");
    Button_Set:setTag(TAG_ENUM.TAG_SETTING_MENU);
    Button_Set:addTouchEventListener(btnEvent);
    -- 隐藏
    local Button_Hide = self.m_nodeMenu:getChildByName("Button_Hide"); -- 
    Button_Hide:setTag(TAG_ENUM.TAG_HIDEUP_BTN);
    Button_Hide:addTouchEventListener(btnEvent);
     

    -- 头像
    self.LeftHead = csbNode:getChildByName("Head_1");
    self.RightHead = csbNode:getChildByName("Head_2");
    self.LeftHead:setZOrder(3)
    self.RightHead:setZOrder(3)

    -- 人物壁纸
    self.Head_Wallpaper_Left = csbNode:getChildByName("Left_The_Player_1_21");
    self.Head_Wallpaper_Right = csbNode:getChildByName("Right_The_Players_1_22");
    self.Head_Wallpaper_Left:setZOrder(2)
    self.Head_Wallpaper_Right:setZOrder(2)
    -- 地图背景
    self.Game_Wallpaper_Map = csbNode:getChildByName("Base_Map_1_7");
    -- 123123
    self.Game_Wallpaper_Map:setZOrder(-2)
    -- 记录押注次数
    self.Max_YaFen_Sp = 0

    -- 玩家血条
    self.Blood_Left_Self = csbNode:getChildByName("blood_1_5");
    -- 奖金池血条
    self.Blood_Right_Spawning = csbNode:getChildByName("blood_2_6");
    self.Blood_Left_Self:setZOrder(3)
    self.Blood_Right_Spawning:setZOrder(3)

    -- 玩家名字
    self.UserName = csbNode:getChildByName("Text_1");

    local KuangTu = csbNode:getChildByName("Game_Box_1_9");
    KuangTu:setZOrder(2)
    local KuangTu = csbNode:getChildByName("Title_3");
    KuangTu:setZOrder(3)
    local KuangTu = csbNode:getChildByName("Gold_4");
    KuangTu:setZOrder(3)
    local KuangTu = csbNode:getChildByName("ZeiZhao_10");
    KuangTu:setZOrder(4)

    local UserName = csbNode:getChildByName("Text_1");
    UserName:setString(self._scene:GetMeUserItem().szNickName)

    -- 当前玩家满血条金币数量
    self._User_Gold = self._scene:GetMeUserItem().lScore * 2

    self:SetNumber_And_Meney(1, self.m_textScore)
    -- 1 : 玩家金币   Game_Box_1_9
    if self._scene.m_JiangJin_Score == nil then
        self._scene.m_JiangJin_Score = 0
    end

    self:SetNumber_And_Meney(2, self._scene.m_JiangJin_Score)
    -- 2 ：奖金池金币
    self:SetNumber_And_Meney(3, self.m_textGetScore)
    -- 3 ：赢得金币
    -- self:SetNumber_And_Meney(4,self.m_textAllyafen )    -- 4 ：总下注金币
    -- self:SetNumber_And_Meney(5,self.m_textYafen )       -- 5 ：下注积分
    self:SetNumber_And_Meney(6, self.m_textFreeNum)
    -- 6 ：免费次数数字
    self:SetNumber_And_Meney(7, self.m_textYaxian)
    -- 7 ：压线

    -- 预加载特效
    self:beginMove_Effects()

    -- 记录下注倍数
    self.BeiShu = 1

    -- 设置滚动图标的初始层
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
        local node = self._csbNode:getChildByName(nodeStr)
        node:setZOrder(3)
    end
    -- 特殊图标动画
    self.FatherBiZhi = cc.Sprite:create("Game1_Terrace/Small/blank.png")
    self.FatherBiZhi:setPosition(0, 0)
    self.FatherBiZhi:setAnchorPoint(0, 0)
    self:addChild(self.FatherBiZhi, 0)

end
 

-- 创建玩家金币艺术字
function Game1ViewLayer:UserMeneyUpdate(All_meney_User)
    local Meney = string.formatNumberThousands(All_meney_User, true, "/")
    local endScoreStr = "base_Meney.png"
    -- 金币切图
    if self.myRankNum1 == nil then

        local JieDian = self._csbNode:getChildByName("Node_1_3")
        JieDian:setZOrder(5)
        self.myRankNum1 = cc.LabelAtlas:_create(Meney, GameViewLayer.RES_PATH .. "Game1_Terrace/Number/" .. endScoreStr, 20, 25, string.byte("/"))
        -- :move(176,688)
        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(JieDian)
    else
        self.myRankNum1:setString(Meney)
    end

    local Gold = All_meney_User / self._User_Gold
    Gold = 414 * Gold
    self.Blood_Left_Self:setTextureRect(cc.rect(0, 0, Gold, 31))
end 
-- 创建奖金池金币艺术字
function Game1ViewLayer:AllMeneySeverUpdate(All_meney_Sever)
    local Meney = string.formatNumberThousands(All_meney_Sever, true, "/")
    local endScoreStr = "base_Meney.png"
    -- 金币切图
    if self.myRankNum2 == nil then

        local JieDian = self._csbNode:getChildByName("Node_1")
        JieDian:setZOrder(5)
        self.myRankNum2 = cc.LabelAtlas:_create(Meney, GameViewLayer.RES_PATH .. "Game1_Terrace/Number/" .. endScoreStr, 20, 25, string.byte("/"))
        -- :move(920,688)
        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(JieDian)
    else
        self.myRankNum2:setString(Meney)
    end
    --    local Gold = All_meney_User / self._User_Gold
    --    Gold = 414 * Gold
    --    self.Blood_Right_Spawning:setTextureRect(cc.rect(0,0,Gold,31))
end 
-- 创建赢得金币艺术字
function Game1ViewLayer:UserWinMeneyUpdate(All_meney_Win)
    local Meney = string.formatNumberThousands(All_meney_Win, true, "/")
    local endScoreStr = "base_Number_2.png"
    -- 金币切图
    if self.myRankNum3 == nil then

        local JieDian = self._csbNode:getChildByName("Node_7")
        JieDian:setZOrder(5)
        self.myRankNum3 = cc.LabelAtlas:_create(Meney, GameViewLayer.RES_PATH .. "Game1_Terrace/Number/" .. endScoreStr, 21, 28, string.byte("/"))
        -- :move(570,588)
        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(JieDian)
    else
        self.myRankNum3:setString(Meney)
    end
end 
-- 创建线数金币艺术字
function Game1ViewLayer:UserWireUpdate(Number)
    local Meney = string.formatNumberThousands(Number, true, "/")
    local endScoreStr = "base_Number_1.png"
    -- 线数数字切图
    if self.myRankNum4 == nil then

        local JieDian = self._csbNode:getChildByName("Node_1_3_0")
        JieDian:setZOrder(5)
        self.myRankNum4 = cc.LabelAtlas:_create(Meney, GameViewLayer.RES_PATH .. "Game1_Terrace/Number/" .. endScoreStr, 23, 27, string.byte("/"))
        -- :move(176,63)

        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(JieDian)
    else
        self.myRankNum4:setString(Meney)
    end
end 
-- 创建总下注金币艺术字
function Game1ViewLayer:UserALLMultipleUpdate(AllMeney)
    local Meney = string.formatNumberThousands(AllMeney, true, "/")
    local endScoreStr = "base_Number_1.png"
    -- 金币切图
    if self.myRankNum7 == nil then

        local JieDian = self._csbNode:getChildByName("Node_1_3_0_0")
        JieDian:setZOrder(5)
        self.myRankNum7 = cc.LabelAtlas:_create(Meney, GameViewLayer.RES_PATH .. "Game1_Terrace/Number/" .. endScoreStr, 23, 27, string.byte("/"))
        -- :move(176,23)
        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(JieDian)
    else
        self.myRankNum7:setString(Meney)
    end
end 
-- 创建倍数金币艺术字
function Game1ViewLayer:UserMultipleUpdate(Yafen)
    local Meney = string.formatNumberThousands(Yafen, true, "/")
    local endScoreStr = "base_Number_1.png"
    -- 金币切图
    if self.myRankNum5 == nil then

        local JieDian = self._csbNode:getChildByName("Node_1_3_0_0_0")
        JieDian:setZOrder(5)
        self.myRankNum5 = cc.LabelAtlas:_create(Meney, GameViewLayer.RES_PATH .. "Game1_Terrace/Number/" .. endScoreStr, 23, 27, string.byte("/"))
        -- move(556,42)
        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(JieDian)
    else
        self.myRankNum5:setString(Meney)
    end
end 
-- 创建免费次数金币艺术字
function Game1ViewLayer:UserChargeUpdate(Number)
    local Meney = string.formatNumberThousands(Number, true, "/")
    local endScoreStr = "base_Number_1.png"
    -- 金币切图
    if self.myRankNum6 == nil then

        local JieDian = self._csbNode:getChildByName("Node_1_3_0_0_0_0")
        JieDian:setZOrder(5)
        self.myRankNum6 = cc.LabelAtlas:_create(Meney, GameViewLayer.RES_PATH .. "Game1_Terrace/Number/" .. endScoreStr, 23, 27, string.byte("/"))
        -- :move(994,45)
        :setAnchorPoint(cc.p(0, 0.5))
        :addTo(JieDian)
    else
        self.myRankNum6:setString(Meney)
    end
end 
-- 创建血池艺术字
function Game1ViewLayer:XUECHIWireUpdate(Number)

    local endScoreStr = "base_Number_1.png"
    -- 金币切图
    if self.myRankNum8 == nil then
        self.myRankNum8 = ccui.Text:create(Number, "fonts/round_body.ttf", 32)
        :setAnchorPoint(cc.p(0, 0.5))
        :move(81, 563)
        :setTextColor(cc.c4b(255, 0, 0, 255))
        :addTo(self)
    else
        self.myRankNum8:setString(Number)
    end
end 
-- 创建索引艺术字
function Game1ViewLayer:SUOYINUserWireUpdate(Number)

    local endScoreStr = "base_Number_1.png"
    -- 金币切图
    if self.myRankNum9 == nil then
        self.myRankNum9 = ccui.Text:create(Number, "fonts/round_body.ttf", 32)
        :setAnchorPoint(cc.p(0, 0.5))
        :move(81, 463)
        :setTextColor(cc.c4b(255, 0, 0, 255))
        :addTo(self)
    else
        self.myRankNum9:setString(Number)
    end
end  

--[[
  -- SetNumber_And_Meney 函数
  -- Index 下标，incident 事件
  -- 1 : 玩家金币变幻
  -- 2 ：奖金池金币变幻
  -- 3 ：赢得金币变幻
  -- 4 ：总下注金币变幻
  -- 5 ：下注积分变幻
  -- 6 ：免费次数数字变幻
  -- 7 ：压线
]]
function Game1ViewLayer:SetNumber_And_Meney(Index, incident)
    if Index == 1 then
        self:UserMeneyUpdate(incident)
    elseif Index == 2 then
        self:AllMeneySeverUpdate(incident)
    elseif Index == 3 then
        self:UserWinMeneyUpdate(incident)
    elseif Index == 4 then
        self:UserALLMultipleUpdate(incident)
    elseif Index == 5 then
        self:UserMultipleUpdate(incident)
    elseif Index == 6 then
        self:UserChargeUpdate(incident)
    elseif Index == 7 then
        self:UserWireUpdate(incident)
    elseif Index == 8 then
        self:XUECHIWireUpdate(incident)
    elseif Index == 9 then
        self:SUOYINUserWireUpdate(incident)
    end
end 

-- 出现小游戏免费游戏添加滚动特效
function Game1ViewLayer:Effects()
    self.MianFei_Game_Effects = 0
    self.Small_Game_Effects = 0
    self.Show_Effects_JunNv = { 0, 0, 0, 0, 0 }
    self.Show_Effects_TaiYangShen = { 0, 0, 0, 0, 0 }

    local Number1 = 1
    local Number2 = 1
    local Number3 = 1
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1

        if nType == 9 then
            Number3 = Number3 + 1
        elseif nType == 10 then
            Number1 = Number1 + 1
            self.MianFei_Game_Effects = self.MianFei_Game_Effects + 1
            local pos = math.ceil(i / 3)
            self.Show_Effects_JunNv[pos] = 1
        elseif nType == 11 then
            local pos = math.ceil(i / 3)
            self.Small_Game_Effects = self.Small_Game_Effects + 1
            self.Show_Effects_TaiYangShen[pos] = 1
            Number2 = Number2 + 1
        end
    end
    if Number2 >= 3 or Number1 >= 3 or Number3 >= 3 then
        self.Stop_All_GunDong = false
        -- self.szSpecial_Spirit = true
        -- self.TeShuTuBiao = true
    end

    for i = 1, 5 do
        if self.Run_All_Eef_DongHua[i] ~= 0 then
            self.Run_All_Eef_DongHua[i]:setVisible(false)
            self.Run_All_Eef_DongHua[i]:removeFromParent()
            self.Run_All_Eef_DongHua[i] = 0
        end
        if self.Run_All_Eef_KaiChang[i] ~= 0 then
            self.Run_All_Eef_KaiChang[i]:setVisible(false)
            self.Run_All_Eef_KaiChang[i]:removeFromParent()
            self.Run_All_Eef_KaiChang[i] = 0
        end
        if self.Run_All_Eef_XianShi[i] ~= 0 then
            self.Run_All_Eef_XianShi[i]:setVisible(false)
            self.Run_All_Eef_XianShi[i]:removeFromParent()
            self.Run_All_Eef_XianShi[i] = 0
        end
        self.Run_TaiYangShen_View_TeXiao[i] = 0
        self.Run_JunNv_View_TeXiao[i] = 0
        self.Run_BaiShen_View_TeXiao[i] = 0
    end
    self.RunEefTime = 1
    self.BaiDaTime = 0.5
    if self.MianFeiCiShuGengXin > self._scene.m_bNumber_of_Free then
        self:SetNumber_And_Meney(6, self._scene.m_bNumber_of_Free)
    end
    if self._scene.m_bNumber_of_Free == 0 and not self._scene.MianFeiGame_End then
        self:SetNumber_And_Meney(3, self.m_textGetScore)
    end
    
	if self._scene.m_bIsAuto then 
        self:Button_Gray(false)
    end
end
 
-- 游戏状态更换时间
local time = 0 
-- 三个特效的开始滚动时间
local BeginTimeView_One = 0
local BeginTimeView_Two = 0
local BeginTimeView_Three = 0

-- 三个特效的停止滚动时间
local EndTimeView_One = 0
local EndTimeView_Two = 0
local EndTimeView_Three = 0
-- 滚动帧数初始0.5秒一帧
num = 0.5

-- 加倍减倍最大押注设置不可点击 
function Game1ViewLayer:Button_Gray(Gray)
    self.Button_Max:setTouchEnabled(Gray)
    self.Button_Sub:setTouchEnabled(Gray)
    self.Button_Add:setTouchEnabled(Gray)
    self.Button_Max:setBright(Gray)
    self.Button_Sub:setBright(Gray)
    self.Button_Add:setBright(Gray)

end

-- 游戏1动画开始
function Game1ViewLayer:game1Begin()
    print("############  game1Begin  ##############") 
     
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
        local node = self._csbNode:getChildByName(nodeStr) 
        local pItemLast = node:getChildByTag(1)
        if pItemLast then
            pItemLast:stopAllItemAction()
            pItemLast:removeFromParent()
            pItemLast = nil
        end
    end



    self:Effects()
    local JiaSu_YanShi = 1
    local posx = 0

    -- 得到当前特殊图片的个数
    local Index = 1
    local Index2 = 1

    -- 设置特殊图标大于等于2的时候滚动时间间隔
    local True1 = 1

    -- 判定下标是否重复
    local Num = 0
    local Num1 = 0

    local zhengchangshijian1 = 0.6
    local zhengchangdianchengshijian = 0.2
    time = 3.8
    -- 正常播放滚动效果时间
    if self._scene.m_bIsAuto or self.MianFeiMu then
        zhengchangshijian1 = 0.3
        -- 0.025
        zhengchangdianchengshijian = 0.1
        -- 0.05
        time = 2
    end

    for i = 1, 15 do

        if i == 4 or i == 7 or i == 10 or i == 13 then
            JiaSu_YanShi = JiaSu_YanShi + 1
        end

        posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
        local node = self._csbNode:getChildByName(nodeStr)
        if node ~= nil then
            local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1
            -- self._scene.m_cbItemInfo 得到最终显示的结果
            if nType < 0 or nType > 12 then
                nType = 0
            end
            local pItem = GameItem:create()
            pItem:getItemView(self)
            if pItem then
                pItem:created(nType)
                local pItemLast = node:getChildByTag(1)
                if pItemLast then
                    -- 				pItemLast:stopAllItemAction()
                    -- 				pItemLast:removeFromParent()
                    -- 				pItemLast = nil
                end

                node:addChild(pItem, 0, 1)
                pItem:setAnchorPoint(0.5, 0)
                pItem:setContentSize(cc.size(138, 144))
                pItem:setPosition(32, 0)


                if self.Show_Effects_TaiYangShen[JiaSu_YanShi] == 1 and i < 13 and JiaSu_YanShi ~= Num then
                    -- 滚动下标有错误带修正
                    Index = Index + 1
                    Num = JiaSu_YanShi
                end

                if self.Show_Effects_JunNv[JiaSu_YanShi] == 1 and i < 13 and JiaSu_YanShi ~= Num1 then
                    -- 滚动下标有错误带修正
                    Index2 = Index2 + 1
                    Num1 = JiaSu_YanShi
                end

                if Index >= 3 or Index2 >= 3 then

                    if i < 7 and True1 == 1 then
                        self:Roll_Game_List(zhengchangshijian1 + i * zhengchangdianchengshijian, pItem, node, 0, i)
                        if i == 6 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        elseif i == 9 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        elseif i == 12 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        end
                    elseif i < 10 and True1 == 1 then
                        self:Roll_Game_List(zhengchangshijian1 + i * zhengchangdianchengshijian, pItem, node, 0, i)
                        if i == 6 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        elseif i == 9 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        elseif i == 12 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        end
                    elseif i < 13 and True1 == 1 then
                        self:Roll_Game_List(zhengchangshijian1 + i * zhengchangdianchengshijian, pItem, node, 0, i)
                        if i == 6 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        elseif i == 9 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        elseif i == 12 then
                            BeginTimeView_One = zhengchangshijian1 + i * zhengchangdianchengshijian
                            -- 记录第一个滚动加速时间产生时间
                            self:Run_Action(node, 1, JiaSu_YanShi + 1)
                            True1 = 2
                        end
                    else
                        if True1 == 2 then
                            EndTimeView_One = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.2)
                            -- 记录第一个滚动加速时间结束时间
                            self:RunEnd_Action(node, 1, JiaSu_YanShi)
                            self:Roll_Game_List(zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.2), pItem, node, JiaSu_YanShi, i)

                            if i == 6 then
                                True1 = 3
                                BeginTimeView_Two = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.2)
                                -- 记录第二个滚动加速时间产生时间
                                self:Run_Action(node, 2, JiaSu_YanShi + 1)
                            elseif i == 9 then
                                True1 = 3
                                BeginTimeView_Two = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.2)
                                -- 记录第二个滚动加速时间产生时间
                                self:Run_Action(node, 2, JiaSu_YanShi + 1)
                            elseif i == 12 then
                                True1 = 3
                                BeginTimeView_Two = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.2)
                                -- 记录第二个滚动加速时间产生时间
                                self:Run_Action(node, 2, JiaSu_YanShi + 1)
                            end
                        elseif True1 == 3 then
                            -- self:Run_Action(node,BeginTime[JiaSu_YanShi])

                            EndTimeView_Two = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.4)
                            -- 记录第二个滚动加速时间结束时间
                            self:RunEnd_Action(node, 2, JiaSu_YanShi)

                            self:Roll_Game_List(zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.4), pItem, node, JiaSu_YanShi, i)

                            if i == 9 then
                                BeginTimeView_Three = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.4)
                                -- 记录第三个滚动加速时间产生时间
                                self:Run_Action(node, 3, JiaSu_YanShi)
                                True1 = 4
                            elseif i == 12 then
                                BeginTimeView_Three = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.4)
                                -- 记录第三个滚动加速时间产生时间
                                self:Run_Action(node, 3, JiaSu_YanShi + 1)
                                True1 = 4
                            end
                        elseif True1 == 4 then

                            EndTimeView_Three = zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.6)
                            -- 记录第个滚动加速时间结束时间
                            self:RunEnd_Action(node, 3, JiaSu_YanShi)
                            self:Run_Action(node, 3, JiaSu_YanShi)
                            self:Roll_Game_List(zhengchangshijian1 + i *(zhengchangdianchengshijian + 0.6), pItem, node, JiaSu_YanShi, i)
                            if i == 12 then
                                True1 = 5
                            end
                        end
                    end
                else
                    -- 没有特殊图标的正常游戏速度时间为：0.5 + i * 0.1
                    -- 没有特殊图标的自动游戏速度时间为：0.25 + i * 0.05
                    self:Roll_Game_List(zhengchangshijian1 + i * zhengchangdianchengshijian, pItem, node, 0, i)
                end
            end
        end
    end
    -- 开始转动音效
    -- ExternalFun.playSoundEffect("QHLHJ_90002(changuizhuandong).wav")
    self.Stop_All_Eef = false
    self.Stop_JunNv_Eef = false

    if Index > 2 or Index2 > 2 then
        if EndTimeView_One ~= 0 then
            time = EndTimeView_One + 0.5
        end
        if EndTimeView_Two ~= 0 then
            time = EndTimeView_Two + 0.5
        end
        if EndTimeView_Three ~= 0 then
            time = EndTimeView_Three + 0.5
        end
    end
     
    self:runAction(
    cc.Sequence:create(
    cc.DelayTime:create(time),
    cc.CallFunc:create( function()
        if self._scene:getGameMode() == 2 then
            -- 表达GAME_STATE_MOVING 
            self:game1GetLineResult()
        end
    end )
    )
    )
end

function Game1ViewLayer:YXPOFANG()
    ExternalFun.playSoundEffect("QHLHJ_90003(dajiangzhuandong).wav")
     
end

-- 指定时间内播放指定区域的特效
function Game1ViewLayer:Show_E(Index_Lie)
    -- 播放有大奖的音效
    -- 停止播放所有音效
    -- AudioEngine.stopAllEffects()
    ExternalFun.playSoundEffect("QHLHJ_90003.wav")
    if self.Muis2 == 0 then
        -- self.Muis2 = ExternalFun.playSoundEffect_lobby("QHLHJ_90032.wav",true)
        print("创建音效")
        local scheduler = cc.Director:getInstance():getScheduler()
        self.schedulerYX = nil
        self.schedulerYX = scheduler:scheduleScriptFunc( function()
            self:YXPOFANG()
        end , 1, false)
        self.Muis2 = 1
    end

    --    else--if  self.Muis2 ~= 0 then
    --        --AudioEngine:playMusic("QHLHJ_90032.mp3",false)
    --        print ("已有音效")
    --    end

    if Index_Lie == 3 then

        -- 播放第一个滚动特效
        local Show_1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "XT_1120_1.csb")
        -- 123123 播放特效
        ExternalFun.SAFE_RETAIN(Show_1)
        self.Index_View_One:stopAllActions()
        Show_1:gotoFrameAndPlay(0, true)
        self.Index_View_One:runAction(Show_1)
        self.Index_View_One:setZOrder(1)
        self.Index_View_One:setVisible(true)
    elseif Index_Lie == 4 then
        -- 播放第二个滚动特效
        local Show_1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "XT_1120_1.csb")
        -- 123123 播放特效
        ExternalFun.SAFE_RETAIN(Show_1)
        self.Index_View_Two:stopAllActions()
        Show_1:gotoFrameAndPlay(0, true)
        self.Index_View_Two:runAction(Show_1)
        self.Index_View_Two:setZOrder(1)
        self.Index_View_Two:setVisible(true)
    elseif Index_Lie == 5 then
        -- 播放第二个滚动特效
        local Show_1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "XT_1120_1.csb")
        -- 123123 播放特效
        ExternalFun.SAFE_RETAIN(Show_1)
        self.Index_View_Three:stopAllActions()
        Show_1:gotoFrameAndPlay(0, true)
        self.Index_View_Three:runAction(Show_1)
        self.Index_View_Three:setZOrder(1)
        self.Index_View_Three:setVisible(true)
    end
end
-- 播放滚动加速特效时间控制函数
function Game1ViewLayer:Run_Action(node, IndexView, Index_Lie)

    if IndexView == 1 then
        if BeginTimeView_One == 0 then
            return
        end
        node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(BeginTimeView_One + 0.1),
        cc.CallFunc:create( function()
            -- self:beginMove_Effects(1020 , true)   -- 开始播放特效时间
            num = 0.1
            if self.Show_GunDong_End then
                self:Show_E(Index_Lie)
            end
        end )
        )
        )

    elseif IndexView == 2 then
        if BeginTimeView_Two == 0 then
            return
        end
        node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(BeginTimeView_Two + 0.2),
        cc.CallFunc:create( function()
            -- self:beginMove_Effects(1020 , true)   -- 开始播放特效时间
            AudioEngine.playEffect(sound_path, true)
            num = 0.1
            if self.Show_GunDong_End then
                self:Show_E(Index_Lie)
            end
        end )
        )
        )
    elseif IndexView == 3 then
        if BeginTimeView_Three == 0 then
            return
        end
        node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(BeginTimeView_Three + 0.2),
        cc.CallFunc:create( function()
            -- self:beginMove_Effects(1020 , true)   -- 开始播放特效时间
            AudioEngine.playEffect(sound_path, true)
            num = 0.1
            if self.Show_GunDong_End then
                self:Show_E(Index_Lie)
            end
        end )
        )
        )
    end
end
-- 指定时间内关闭指定区域加速滚动特效
function Game1ViewLayer:Show_End(IndexView)
    if IndexView == 3 then

        -- 停止播放第一个滚动特效
        self.Index_View_One:setVisible(false)
    elseif IndexView == 4 then

        -- 停止播放第二个滚动特效
        self.Index_View_Two:setVisible(false)
    elseif IndexView == 5 then

        -- 停止播放第三个滚动特效
        self.Index_View_Three:setVisible(false)
    end
end

-- 停止滚动加速特效时间控制函数
function Game1ViewLayer:RunEnd_Action(node, IndexView, Index_Lie)
    -- 停止播放所有音效
    AudioEngine.stopAllEffects()
    local EndTime = 0.5
    if self._scene.m_bIsAuto then
        EndTime = 0
    end
    if IndexView == 1 then
        if EndTimeView_One == 0 then
            return
        end
        node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(EndTimeView_One + EndTime),
        cc.CallFunc:create( function()
            -- self:beginMove_Effects(1020 , true)   -- 开始播放特效时间
            self:Show_End(Index_Lie)
        end )
        )
        )

    elseif IndexView == 2 then
        if EndTimeView_Two == 0 then
            return
        end
        node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(EndTimeView_Two + EndTime),
        cc.CallFunc:create( function()
            -- self:beginMove_Effects(1020 , true)   -- 开始播放特效时间
            self:Show_End(Index_Lie)
        end )
        )
        )
    elseif IndexView == 3 then
        if EndTimeView_Three == 0 then
            return
        end
        node:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(EndTimeView_Three + EndTime),
        cc.CallFunc:create( function()
            -- self:beginMove_Effects(1020 , true)   -- 开始播放特效时间
            self:Show_End(Index_Lie)
        end )
        )
        )
    end
end 
-- 预先创建三列滚动加速特效，设置为不显示状态
-- 预先创建三种不同倍数倍数特效，设置为不显示状态
function Game1ViewLayer:beginMove_Effects()
    print("预设滚动特效")
    self.Index_View_One = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "XT_1120_1.csb", self);
    self.Index_View_Two = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "XT_1120_1.csb", self);
    self.Index_View_Three = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "XT_1120_1.csb", self);

    self.Index_View_One:setPosition(667, 375)
    self.Index_View_Two:setPosition(843, 375)
    self.Index_View_Three:setPosition(1020, 375)

    self.Index_View_One:setVisible(false)
    self.Index_View_Two:setVisible(false)
    self.Index_View_Three:setVisible(false)

    self.Refuel_One = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BeiShu/" .. "XT_11111.csb", self.Game_Wallpaper_Map);
    -- 5 倍
    self.Refuel_Two = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BeiShu/" .. "XT_11111_1.csb", self.Game_Wallpaper_Map);
    -- 3 倍
    self.Refuel_Three = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BeiShu/" .. "XT_11111_2.csb", self.Game_Wallpaper_Map);
    -- 4 倍

    self.Refuel_One:setPosition(668, 659)
    self.Refuel_Two:setPosition(668, 679)
    self.Refuel_Three:setPosition(668, 669)

    self.Refuel_One:setVisible(false)
    self.Refuel_Two:setVisible(false)
    self.Refuel_Three:setVisible(false)
    --          self.Refuel_One   :setZOrder(1)
    --          self.Refuel_Two   :setZOrder(1)
    --          self.Refuel_Three :setZOrder(1)
end

-- 滚动时间控制器
--[[
    Index_List : 图标下标
    Roll       : 滚动时间比例
]]
function Game1ViewLayer:Roll_Game_List(Roll, pItem1, node1, True1, i)
    if nType ~= 0 then
        nType = node1
    end

    node1:runAction(
    cc.Sequence:create(
    cc.CallFunc:create( function()
        pItem1:beginMove(Roll, True1)
        -- 设置滚动时间  JiaSu_YanShi 特效播放下标
        if i == 15 then
            self._scene:setGameMode(2)
            -- 表达GAME_STATE_MOVING
        end
    end )
    )
    )
end

-- 手动停止滚动
function Game1ViewLayer:game1End() 
--    if not self._scene.m_bIsAuto then
--        self.Button_Start:loadTextureNormal("Game1_Terrace/Button/BeginGame1.png")
--        self.Button_Start:setTouchEnabled(false)
--        self.Button_Start:setBright(false)
--    end 

    self.Button_Start   :setTouchEnabled(false)
    self.Button_Start   :setBright(false)

    if self.Stop_All_GunDong then 
        local EndTime = 0
        for i = 1, 15 do
            local posx = math.ceil(i / 3)
            local posy =(i - 1) % 3 + 1
            local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
            local node = self._csbNode:getChildByName(nodeStr)

            if node then
                local pItem = node:getChildByTag(1)
                if pItem then
                    node:runAction(
                    cc.Sequence:create(
                    cc.CallFunc:create( function()
                        EndTime = 0.25 + i * 0.05 
                        pItem:beginMove(EndTime, 2)
                        -- 设置滚动时间  JiaSu_YanShi 特效播放下标   --  待修改（添加滚动闪电特效） 
                        if i == 15 then
                            self._scene:setGameMode(2)
                            -- 表达GAME_STATE_MOVING
                        end
                    end )
                    )
                    )
                end
            end
        end  
        self:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(2),
        cc.CallFunc:create( function()
            self:stopAllActions()
            if self._scene:getGameMode() == 2 then
                -- 表达GAME_STATE_MOVING 
                self:game1GetLineResult() 
            end
        end )
        )
        ) 
    end

end
  
-- 游戏1结果
function Game1ViewLayer:game1Result()
    print(" ###    游戏1结果    ###")

    if not self._scene.m_bEnterGame4 and not self._scene.m_bEnterGame3 then
        self.Button_Start:setTouchEnabled(true)
        self.Button_Start:setBright(true)
        --self:Button_Gray(true)
    end

    self._scene:setGameMode(3)
    -- GAME_STATE_RESULT
    if self.m_textGetScore > 0 or(self._scene.MianFeiGame_End and self._scene.m_bEnterGame3 == false) then

        -- 此时正在播放小头像动画
        self.DongHua_ZanTing = true

        -- 免费游戏结束时播放免费游戏结束专有的结束奖励特效  quan_huang_1190
        if self._scene.MianFeiGame_End then
            if self.MianFeiJinBiZhi > 0 and self._scene.m_bEnterGame3 == false then -- 免费游戏结束且不进入小游戏的结算
                self:JINBITEXIAO("quan_huang_1190", "XT_JinBi", self.MianFeiJinBiZhi + self._scene.m_lGetCoins + XiaoYouXiJiBI, "QHLHJ_90006dajiangjiesuan)",750)
                self.m_textScore = self.m_textScore + self.MianFeiJinBiZhi + self._scene.m_lGetCoins + XiaoYouXiJiBI
                self:SetNumber_And_Meney(1, self.m_textScore)
                self.MianFeiJinBiZhi = 0
                self._scene.m_lCoins = self.m_textScore
                XiaoYouXiJiBI = 0
                self:SetNumber_And_Meney(3, 0)
                self.QINGKONGYINGDEZHI = 0 
            elseif self.MianFeiJinBiZhi > 0 then -- 免费游戏结束准备进入小游戏
                self.MianFeiJinBiZhi = self.MianFeiJinBiZhi + self._scene.m_lGetCoins

                if self.m_textGetScore >= self.m_textAllyafen * 4 then
                    self:JINBITEXIAO("quan_huang_TX_1111_2", "XT_JinBi", self.MianFeiJinBiZhi, "QHLHJ_90006dajiangjiesuan)",750)
                else
                    self:JINBITEXIAO("XT_1180", "XT_1180_1", self.MianFeiJinBiZhi, "QHLHJ_90007putongjiesuan)",375)
                end
                self:SetNumber_And_Meney(3, self.MianFeiJinBiZhi)
                self.MIANFEICISHUXIANSHI = false
            end
            if self.MianFeiTeXiao ~= nil then
                self.MianFeiTeXiao:setVisible(false)
                self.MianFeiTeXiao:removeFromParent()
                self.MianFeiTeXiao = nil
            end
            self._scene.MianFeiGame_End = false
            self.MIANFEICISHUXIANSHI = false
            self.Button_Start:setTouchEnabled(true)
            self.Button_Start:setBright(true)
            self:Button_Gray(true)
            -- 免费游戏每局获得的金币数量
        elseif self._scene.m_bNumber_of_Free >=  1 then
            --  self._scene.m_bEnterGame4 and and self.MianFeiMu 

            if self.m_textGetScore >= self.m_textAllyafen * 4 then
                self:JINBITEXIAO("quan_huang_TX_1111_2", "XT_JinBi", self._scene.m_lGetCoins, "QHLHJ_90006dajiangjiesuan)",750)
            else
                self:JINBITEXIAO("XT_1180", "XT_1180_1", self._scene.m_lGetCoins, "QHLHJ_90007putongjiesuan)",375)
            end
            -- 免费游戏中获得的金币不直接累加到玩家金币中，累加在赢得金币区域，免费游戏结束在一次性给与玩家
            self.MianFeiJinBiZhi = self.MianFeiJinBiZhi + self._scene.m_lGetCoins
            print("免费游戏中: 获得免费金币累加值：:::::::::::::::::::::::::::;   " .. self.MianFeiJinBiZhi)

            self:SetNumber_And_Meney(3, self.MianFeiJinBiZhi)

            -- 正常游戏结束过程
        else
            if self.m_textGetScore >= self.m_textAllyafen * 4 then
                self:JINBITEXIAO("quan_huang_TX_1111_2", "XT_JinBi", self._scene.m_lGetCoins, "QHLHJ_90006dajiangjiesuan)",750)
            else
                self:JINBITEXIAO("XT_1180", "XT_1180_1", self._scene.m_lGetCoins, "QHLHJ_90007putongjiesuan)",375)
            end

            self.m_textGetScore = self._scene.m_lGetCoins
            self:SetNumber_And_Meney(3, self.m_textGetScore)

            self.m_textScore = self.m_textScore + self.m_textGetScore
            self:SetNumber_And_Meney(1, self.m_textScore)
        end
    end

    if self._scene.m_lGetCoins > 0 then
        for i = 1, 15 do
            local posx = math.ceil(i / 3)
            local posy =(i - 1) % 3 + 1
            local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
            local node = self._csbNode:getChildByName(nodeStr)
            if node then
                local pItem = node:getChildByTag(1)
                if pItem then
                    if self._scene.m_lGetCoins > 0 then
                        if self._scene.tagActionOneKaiJian.bZhongJiang[posy][posx] == true then

                            -- pItem:setState(0) --STATE_NORMAL
                            self:runAction(
                            cc.Sequence:create(
                            cc.DelayTime:create(0),
                            cc.CallFunc:create( function() 
                            print ("》》》》》》》》》》》》》》》》》》》》：：：：播放动画延迟时间：：：：：：》》》》》》》》》》》》》"..self.BaiDaTime ) 
                                self:runAction(
                                cc.Sequence:create(
                                cc.DelayTime:create(self.BaiDaTime),
                                cc.CallFunc:create( function()
                                    -- 显示中奖的动画
                                    pItem:setState(1)
                                    -- STATE_SELECT
                                    -- 对应音效
                                    self:Game1ZhongxianAudio(pItem.m_nType)
                                end )
                                )
                                )
                            end ),
                            cc.DelayTime:create(3.0),
                            cc.CallFunc:create( function()

                                -- 判定奖金池大派奖
                                if self._scene.JiangJinChiDaPaiJiang ~= nil and self._scene.JiangJinChiDaPaiJiang == true then
                                    self:Show_BigBang(self._scene.m_lGetCoins)
                                end

                            end )
                            )
                            )
                        else
                            pItem:setState(2) -- 抹灰图标
                        end
                    else
                        pItem:setState(0) -- 高亮图标
                    end
                end
            end
        end
    end

    if self._scene.m_bEnterGame3 == true then
        -- 设置小玛丽状态
        self._scene.m_cbGameStatus = g_var(cmd).SHZ_GAME_SCENE_THREE
    end

    -- 如果有特殊图标在播放，那么就等待特殊图标播放完毕之后播放
    if self.m_textGetScore > 0 then
        self.RunEefTime = self.RunEefTime + 3
    end

    print("》》》》》》》》》》》》》》》》》：：：：：下一局开始时间为：》》》》》》》》》》》" .. self.RunEefTime)

    -- 即将进入小玛丽
    if g_var(cmd).SHZ_GAME_SCENE_THREE == self._scene.m_cbGameStatus then

        self.Button_Start:setTouchEnabled(false)
        self.Button_Start:setBright(false)
        self.MianFeiCiShuGengXin = self._scene.m_bNumber_of_Free
        self:SetNumber_And_Meney(6, self._scene.m_bNumber_of_Free)
        if self.m_textGetScore == 0 then
            self:TuBiaoXianShi()
        end 
        self:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(self.RunEefTime),
        cc.CallFunc:create( function()
            self:Run_TaiYangShen() 
        end ),
        cc.DelayTime:create(10),
        cc.CallFunc:create( function()
            self._scene.m_bIsItemMove = false
             
            -- 游戏模式
            self._scene:setGameMode(5)
            -- GAME_STATE_END
            self._scene:SendUserReady()
            -- 即将进入小玛丽
            print("即将进入小玛丽")
            self._scene:onEnterGame3()

        end )
        )
        ) 
    else
        if self._scene.m_bEnterGame4 == true and self._scene.m_bNumber_of_Free ~= 0 then
            -- 免费游戏中，将有3秒时间让玩家选择是否进入比倍
            self.Button_Start:setTouchEnabled(false)
            self.Button_Start:setBright(false)

            self.TeShuTuBiao = false

            local JunNvEefTime = 1
             
            local number = 0 
            for i = 1, 15 do
                local posx = math.ceil(i / 3)
                local posy =(i - 1) % 3 + 1
                local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1
                if nType == 11 then
                    number = number + 1
                end
            end 
            if number >= 3 then
                JunNvEefTime = 7
            end
             
            self.Stop_JunNv_Eef = true
            self:runAction(
            cc.Sequence:create(
            cc.DelayTime:create(self.RunEefTime),
            cc.CallFunc:create( function()

                -- 当前是否存于免费游戏中
                self.MianFeiMu = true
                if number >= 3 then
                    if self.m_textGetScore == 0 then
                        self:TuBiaoXianShi()
                    end
                    self:Run_JunNiang()
                    self.MianFeiCiShuGengXin = self._scene.m_bNumber_of_Free
                    self:SetNumber_And_Meney(6, self._scene.m_bNumber_of_Free)
                end
            end ),
            cc.DelayTime:create(JunNvEefTime),
            cc.CallFunc:create( function()
                print("自动游戏中，将有3秒时间进行免费次数")

                if self._scene.m_bReConnect1 == true then
                    local useritem = self._scene:GetMeUserItem()
                    if useritem.cbUserStatus ~= yl.US_READY then
                        print("---框架准备 断线重连后")
                        --self._scene:SendUserReady()
                    end
                    -- 发送准备消息
                    self._scene:sendReadyMsgFree()

                    self._scene.m_cbGameStatus = g_var(cmd).SHZ_GAME_SCENE_FREE
                    self._scene:setGameMode(5)
                    self._scene.m_bReConnect1 = false
                    print(" ---断线重连 over") 
                    return
                end

                self._scene:setGameMode(5)
                -- GAME_STATE_END
                -- 断线重连后
                if self._scene.m_bEnterGame4 == true then
                    local useritem = self._scene:GetMeUserItem()

                    self._scene.m_bIsItemMove = false
                    -- 切换按钮状态
                    self:updateStartButtonState(true)
                    
                    if self.MianFeiTeXiao == nil then
                        -- 播放免费游戏音乐
                        ExternalFun.playBackgroudAudio("MianFeiGame.mp3")
                        self.MianFeiTeXiao = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "quan_huang_TX_1170.csb", self);
                        self.MianFeiTeXiao:setPosition(667, 375)
                        self.MianFeiTeXiao:setZOrder(20)
                        local czEffects = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/GunDongTeXiao/" .. "quan_huang_TX_1170.csb")
                        -- 123123 播放排行特效
                        ExternalFun.SAFE_RETAIN(czEffects)
                        self.MianFeiTeXiao:stopAllActions()
                        --- 123123
                        czEffects:gotoFrameAndPlay(0, true)
                        self.MianFeiTeXiao:runAction(czEffects)
                    end


                    self._scene.m_cbGameStatus = g_var(cmd).SHZ_GAME_SCENE_FREE
                    self._scene:setGameMode(5)
                    self._scene.m_bReConnect1 = false
                     
                    -- 发送免费准备消息
                    self._scene:sendReadyMsgFree()

                    self.MIANFEICISHUXIANSHI = true
                    return
                end
            end ) 
            )
            )
        elseif self._scene.m_bIsAuto == true then
            -- 自动游戏中
            self.TeShuTuBiao = false

            self:runAction(
            cc.Sequence:create(
            cc.DelayTime:create(self.RunEefTime),
            cc.CallFunc:create( function()
              if self._scene.m_bReConnect1 == true then
                    local useritem = self._scene:GetMeUserItem()
                    if useritem.cbUserStatus ~= yl.US_READY then
                        print("---框架准备 断线重连后")
                        self._scene:SendUserReady()
                    end
                    -- 发送准备消息
                    self._scene:sendReadyMsg()

                    self._scene.m_cbGameStatus = g_var(cmd).SHZ_GAME_SCENE_FREE
                    self._scene:setGameMode(1)
                    self._scene.m_bReConnect1 = false
                    print(" ---断线重连 over") 
                    return
                end

                self._scene:setGameMode(5)
                self._scene:sendEndGame1Msg() 
                -- 切换按钮状态
                self:updateStartButtonState(true)
                 
            end )
            )
            ) 
        else 
            self.TeShuTuBiao = false
            -- 重新设定当前回合是否有特殊图标
            self:Button_Gray(true)
            self:runAction(
            cc.Sequence:create(
            cc.DelayTime:create(0.5),
            cc.CallFunc:create( function()
                self._scene.m_bIsItemMove = false
                self._scene:setGameMode(5) 
                 self._scene:sendEndGame1Msg()
                -- 切换按钮状态
                self:updateStartButtonState(true)
            end ),
            cc.DelayTime:create(0.5),
            cc.CallFunc:create( function()
                -- 断线重连后
                if self._scene.m_bReConnect1 == true then
                    local useritem = self._scene:GetMeUserItem()
                    if useritem.cbUserStatus ~= yl.US_READY then
                        print(" ---框架准备 断线重连后")
                        self._scene:SendUserReady()
                    end
                    -- 发送准备消息
                    self._scene:sendReadyMsg()

                    self._scene.m_cbGameStatus = g_var(cmd).SHZ_GAME_SCENE_FREE
                    self._scene:setGameMode(1)
                    self._scene.m_bReConnect1 = false
                    print(" ---断线重连 over")
                    return
                end 
                -- 发送消息
                self._scene:setGameMode(5)  
                self.DongHua_ZanTing = false
                self.DongHua_JieSuan = false

            end )
            )
            )

        end
    end
    -- self.Stop_All_Eef = true
    -- 当前是否有特殊图标
    self.TeShuTuBiao = false

--    self.DongHua_ZanTing = false
--    self.DongHua_JieSuan = false
    if self.MianFeiMu and self._scene.m_bNumber_of_Free == 0 then
        -- 播放免费游戏音乐
        ExternalFun.playBackgroudAudio("QUANHUANG.mp3")
        self.MianFeiMu = false
    end
end  
 
function Game1ViewLayer:Show_Free_View()
print("免费游戏最后一次进入的小游戏，小游戏退出后展示小游戏结算金币特效！！！！！！！！！！！") 
    self:runAction(
    cc.Sequence:create(
    cc.DelayTime:create(0.5),
    cc.CallFunc:create( function()
        self:JINBITEXIAO("quan_huang_1190", "XT_JinBi", self.MianFeiJinBiZhi + self._scene.m_lGetCoins + XiaoYouXiJiBI, "QHLHJ_90006dajiangjiesuan)")
        self.m_textScore = self.m_textScore + self.MianFeiJinBiZhi + self._scene.m_lGetCoins + XiaoYouXiJiBI
        self:SetNumber_And_Meney(1, self.m_textScore)
        self.MianFeiJinBiZhi = 0
        self.MianFeiTeXiao:setVisible(false)
        self.MianFeiTeXiao:removeFromParent()
        self.MianFeiTeXiao = nil
        XiaoYouXiJiBI = 0
        self:SetNumber_And_Meney(3, 0)
        self.QINGKONGYINGDEZHI = 0
        self._scene.MianFeiGame_End = false
    end )
    )
    )
end

function Game1ViewLayer:TuBiaoXianShi()
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
        local node = self._csbNode:getChildByName(nodeStr)
        if node then
            local pItem = node:getChildByTag(1)
            if pItem then
                pItem:setState(2) 
            end
        end
    end
end

function Game1ViewLayer:JINBITEXIAO(jinbiname, liziname, jinbi, effect , pos)
    -- 高额金币播放
    local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. jinbiname .. ".csb", self);
    self.Show_BigBang_JB = Boss
    self.Show_BigBang_JB:setPosition(667, 375)
    self.Show_BigBang_JB:setZOrder(100)

    -- 播放金币雨
    local emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. liziname .. ".plist")
    emitter2:setAutoRemoveOnFinish(true)
    -- 设置播放完毕之后自动释放内存
    emitter2:setScale(1.5, 1.5)
    
    emitter2:setPosition(667, pos)
    self:addChild(emitter2, 5)


    local Gold = self.Show_BigBang_JB:getChildByName("AtlasLabel_1")
    -- 设置艺术字体
    Gold:setString(jinbi)
    -- 播放金币雨音效
    ExternalFun.playSoundEffect(effect .. ".wav")

    self._czEffects_Show_BigBang = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. jinbiname .. ".csb")
    ExternalFun.SAFE_RETAIN(self._czEffects_Show_BigBang)
    local Incident = function(frame)
        if nil == frame then
            return
        elseif frame:getEvent() == "end" then
            self.Show_BigBang_JB:setVisible(false)
            self.Show_BigBang_JB:removeFromParent()
            self.Show_BigBang_JB = nil
        end
    end
    self._czEffects_Show_BigBang:setFrameEventCallFunc(Incident)
    self.Show_BigBang_JB:stopAllActions()
    self._czEffects_Show_BigBang:gotoFrameAndPlay(0, false)
    self.Show_BigBang_JB:runAction(self._czEffects_Show_BigBang)
end


function Game1ViewLayer:ZanTingDongHua()
    if self.DongHua_JieSuan then
        self._scene:setGameMode(5)
        self._scene.m_bIsItemMove = false
        self.DongHua_ZanTing = false
        -- 切换按钮状态
        self:updateStartButtonState(true)

        -- 发送下一局游戏开始

        self._scene:sendEndGame1Msg()
        --self._scene:sendReadyMsg()
        self.DongHua_ZanTing = false
        self.DongHua_JieSuan = false
        self.Stop_All_Eef = false
    end
end

-- 游戏连线结果
function Game1ViewLayer:game1GetLineResult()
    print("游戏连线结果")

    self._scene:setGameMode(3)
    -- GAME_STATE_RESULT
    self.m_textGetScore = self._scene.m_lGetCoins


    if self.Muis2 == 1 then
        -- cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerYX)
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(self.schedulerYX)
    end



    -- 画中奖线
    -- 中奖线路径
    local pathLine =
    {
        "AtlasLabel_1",
        "AtlasLabel_2",
        "AtlasLabel_3",
        "AtlasLabel_4",
        "AtlasLabel_5",
        "AtlasLabel_6",
        "AtlasLabel_7",
        "AtlasLabel_8",
        "AtlasLabel_9",
    }

    -- 游戏中奖线是否有百搭
    if self._scene.m_lGetCoins > 0 then
        for k = 1, 15 do
            local posx = math.ceil(k / 3)
            local posy =(k - 1) % 3 + 1
            local nodeStr = string.format("Node_%d_%d", posx - 1, posy - 1)
            if self._scene.tagActionOneKaiJian.bZhongJiang[posy][posx] == true then
                local GENGHUANBAIDA = false
                for i = 1, 3 do
                    if self._scene.m_cbItemInfo[i][posx] == 8 then
                        --  判定当前连线
                        self.szSpecial_Spirit = true
                        self.TeShuTuBiao = true
                        self.Stop_All_Eef = true
                        GENGHUANBAIDA = true
                        break
                    end
                end
                if GENGHUANBAIDA then
                    for i = 1, 3 do
                        if self._scene.m_cbItemInfo[i][posx] ~= 8 then
                            self._scene.m_cbItemInfo[i][posx] = 8
                        end
                    end
                end

            end
        end
        if self.TeShuTuBiao then
            -- self.szSpecial_Spirit = true
            self.RunEefTime = 5
            self.BaiDaTime = 3
            self:Run_BaiShen()
            print("退出播放函数啦！！！！！！！！！！！！！！！！！！！！！！！！！！")
        end
    end
     

    print("进入连线判定啦！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！")
      
    -- 绘制中奖线
    if self._scene.m_lGetCoins > 0 then 
        local delayTime = 1.5
        for lineIndex = 1, #self._scene.m_UserActionYaxian do
            local pActionOneYaXian = self._scene.m_UserActionYaxian[lineIndex]
            if pActionOneYaXian then
                self:runAction(
                cc.Sequence:create(
                cc.DelayTime:create(0),
                cc.CallFunc:create( function()
                    -- 音效
                    -- ExternalFun.playSoundEffect("gundong_1.mp3")
                    -- 如果是最后一个，进入结算界面
                    if lineIndex == #self._scene.m_UserActionYaxian then
                        self:runAction(
                        cc.Sequence:create(
                        cc.DelayTime:create(0),
                        cc.CallFunc:create( function()
                            print("进入游戏结果啦！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！")
                            self:game1Result()
                        end )
                        )
                        )
                    end
                    -- 中奖显示对应的是数字
                    print("连线目标：" .. pathLine[pActionOneYaXian.nZhongJiangXian])
                    local sp = self._csbNode:getChildByName(pathLine[pActionOneYaXian.nZhongJiangXian])
                    sp:setVisible(true)
                    sp:setZOrder(10)
                    sp:runAction(cc.Sequence:create(cc.FadeTo:create(1, 0), cc.FadeTo:create(3, 255)))
                    self:runAction(
                    cc.Sequence:create(
                    cc.DelayTime:create(0),
                    cc.CallFunc:create( function()
                        sp:runAction(cc.Sequence:create(cc.FadeTo:create(2, 255), cc.FadeTo:create(3, 0)))
                    end )
                    )
                    )


                    if isOnLine == false then
                        pItem:setState(2)
                        -- STATE_GREY
                    end

                end )
                )
                )
            end
            if #self._scene.m_UserActionYaxian == lineIndex then
                return
            end
        end
        self:game1Result()
    else
        self:game1Result()
    end
end  

-- 奖金池大派奖
function Game1ViewLayer:Show_BigBang(meney)

    local emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1160_1.plist")
    emitter2:setAutoRemoveOnFinish(true)
    -- 设置播放完毕之后自动释放内存
    emitter2:setScale(1.5, 1.5)
    emitter2:setPosition(667, 777)
    self:addChild(emitter2, 5)
    local emitter3 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1160_2.plist")
    emitter3:setAutoRemoveOnFinish(true)
    -- 设置播放完毕之后自动释放内存
    emitter3:setScale(1.5, 1.5)
    emitter3:setPosition(667, 777)
    self:addChild(emitter3, 5)
    -- 播放金币雨音效
    ExternalFun.playSoundEffect("QHLHJ_90006dajiangjiesuan).wav")


    local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1160.csb", self);
    local czEffects = Boss
    czEffects:setPosition(617, 375)
    czEffects:setZOrder(10)
    local czEffects_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1160.csb")
    -- 123123 播放获得金币特效
    ExternalFun.SAFE_RETAIN(czEffects_Run)
    local Incident = function(frame)
        if nil == frame then
            return
        elseif frame:getEvent() == "GaiBianZiTi" then
            -- 展现数字
            local EEF = czEffects:getChildByName("Sprite_1")
            local Gold = EEF:getChildByName("AtlasLabel_1")
            -- 设置艺术字体
            Gold:setString(meney)
            -- 重置奖金池大派奖文字

        elseif frame:getEvent() == "Show_JiBiYu" then
            -- 播放金币雨特效
            --                 emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .."Game1_Terrace/Small/Specia_Effects/User_Operation/" .."XT_1160_1.plist")
            --                 emitter2:setAutoRemoveOnFinish(true)    --设置播放完毕之后自动释放内存
            --                 emitter2:setPosition(667,777)
            --                 self:addChild(emitter2,5)
            --                 emitter3 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .."Game1_Terrace/Small/Specia_Effects/User_Operation/" .."XT_1160_2.plist")
            --                 emitter3:setAutoRemoveOnFinish(true)    --设置播放完毕之后自动释放内存
            --                 emitter3:setPosition(667,777)

        elseif frame:getEvent() == "End_Show_Times" then
            -- 关闭当前特效
            czEffects:setVisible(false)
        end

    end
    czEffects_Run:setFrameEventCallFunc(Incident)
    -- 动画的使用事件
    czEffects:stopAllActions()
    czEffects_Run:gotoFrameAndPlay(0, false)
    czEffects:runAction(czEffects_Run)
end

  
-- 对应倍数播放对应的特效
function Game1ViewLayer:Refuel_Effects(Index_Effects)

    if Index_Effects == 5 then
        self.Refuel_Three:setVisible(false)
        local Show_1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BeiShu/" .. "XT_11111.csb")
        -- 123123 播放特效
        ExternalFun.SAFE_RETAIN(Show_1)
        self.Refuel_One:stopAllActions()
        Show_1:gotoFrameAndPlay(0, true)
        -- self.Refuel_One   :setLocalZOrder(-1)
        -- self.Refuel_One   :setZOrder(0)
        local a = self.Refuel_One:getLocalZOrder()

        self.Refuel_One:runAction(Show_1)
        self.Refuel_One:setVisible(true)
    elseif Index_Effects == 3 then
        self.Refuel_Three:setVisible(false)
        self.Refuel_One:setVisible(false)
        local Show_1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BeiShu/" .. "XT_11111_1.csb")
        -- 123123 播放特效
        ExternalFun.SAFE_RETAIN(Show_1)
        self.Refuel_Two:stopAllActions()
        Show_1:gotoFrameAndPlay(0, true)
        -- self.Refuel_Two   :setLocalZOrder(-1)
        self.Refuel_Two:runAction(Show_1)

        self.Refuel_Two:setVisible(true)
    elseif Index_Effects == 4 then
        self.Refuel_One:setVisible(false)
        local Show_1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BeiShu/" .. "XT_11111_2.csb")
        -- 123123 播放特效
        ExternalFun.SAFE_RETAIN(Show_1)
        self.Refuel_Three:stopAllActions()
        Show_1:gotoFrameAndPlay(0, true)
        self.Refuel_Three:runAction(Show_1)
        -- self.Refuel_Three :setZOrder(-1)
        self.Refuel_Three:setVisible(true)
    elseif Index_Effects == 1 or Index_Effects == 2 then
        self.Refuel_Three:setVisible(false)
        self.Refuel_Two:setVisible(false)
        self.Refuel_One:setVisible(false)
    end
end

-- 此函数作用为当特殊图标动画正处于播放时，让这个动画不再显示
function Game1ViewLayer:Show_Held_Eef()
    --    --存储每列的动作动画，用于控制关闭动画
    --    self.Run_All_Eef_DongHua = {0,0,0,0,0}
    --    --存储每列的开场动画，用于控制关闭动画
    --    self.Run_All_Eef_KaiChang = {0,0,0,0,0}
    --    --存储每列的慢慢显示的动画，用于控制关闭动画
    --    self.Run_All_Eef_XianShi = {0,0,0,0,0}
    for i = 1, 5 do
        if self.Run_All_Eef_DongHua[i] ~= 0 then
            self.Run_All_Eef_DongHua[i]:setVisible(false)
            self.Run_All_Eef_DongHua[i]:removeFromParent()
            self.Run_All_Eef_DongHua[i] = 0
        end
        if self.Run_All_Eef_KaiChang[i] ~= 0 then
            self.Run_All_Eef_KaiChang[i]:setVisible(false)
            self.Run_All_Eef_KaiChang[i]:removeFromParent()
            self.Run_All_Eef_KaiChang[i] = 0
        end
        if self.Run_All_Eef_XianShi[i] ~= 0 then
            self.Run_All_Eef_XianShi[i]:setVisible(false)
            self.Run_All_Eef_XianShi[i]:removeFromParent()
            self.Run_All_Eef_XianShi[i] = 0
        end

        self.Run_TaiYangShen_View_TeXiao[i] = 0
        self.Run_JunNv_View_TeXiao[i] = 0
        self.Run_BaiShen_View_TeXiao[i] = 0

    end 
end

function Game1ViewLayer:onButtonClickedEvent(tag, ref)
    if tag == TAG_ENUM.TAG_QUIT_MENU then
        -- 退出
        self._scene.m_bIsLeave = true
        self._scene:onExitTable()
        ExternalFun.playClickEffect()
        -- 播放点击音效 ExternalFun.playClickEffect()    qweqwe
    elseif tag == TAG_ENUM.TAG_START_MENU then 
        self._scene:onGameStart() 
        ExternalFun.playClickEffect()
    elseif tag == TAG_ENUM.TAG_SETTING_MENU then
        -- 设置
        self:onSetLayer()
        ExternalFun.playClickEffect()
    elseif tag == TAG_ENUM.TAG_HELP_MENU then
        -- 游戏帮助
        local Help = HelpLayer:create(self)
        Help:setZOrder(100)
        self:addChild(Help)
        self:onHelpLayer(self)
        ExternalFun.playClickEffect()

    elseif tag == TAG_ENUM.TAG_MAXADD_BTN then
        -- 最大加注
        -- 最大加注则直接播放最大倍数对应特效
        self.BeiShu = 5
        self:Refuel_Effects(self.BeiShu)

        self._scene:onAddMaxScore()
    elseif tag == TAG_ENUM.TAG_MINADD_BTN then
        -- 最小减注
        self._scene:onAddMinScore()
        -- 声音
        ExternalFun.playSoundEffect("shangfen1.mp3")
    elseif tag == TAG_ENUM.TAG_ADD_BTN then
        -- 加注

        -- 最大加注则直接播放最大倍数对应特效
        if self.BeiShu <= 5 then
            self.BeiShu = self.BeiShu + 1
            self:Refuel_Effects(self.BeiShu)
        end
        self._scene:onAddScore()
    elseif tag == TAG_ENUM.TAG_SUB_BTN then
        -- 减注
        -- 最大加注则直接播放最大倍数对应特效
        if self.BeiShu > 0 then
            self.BeiShu = self.BeiShu - 1
            self:Refuel_Effects(self.BeiShu)
        end
        self._scene:onSubScore()  
    elseif tag == TAG_ENUM.TAG_AUTO_START_BTN then
        -- 自动游戏
        self._scene:onAutoStart()
        ExternalFun.playClickEffect()
    elseif tag == TAG_ENUM.TAG_GAME2_BTN then
        -- 开始游戏2
        -- self._scene:onEnterGame2()
        -- ExternalFun.playClickEffect()
    elseif tag == TAG_ENUM.TAG_HIDEUP_BTN then
        -- 隐藏上部菜单
        self:onHideTopMenu()
        ExternalFun.playClickEffect()
    elseif tag == TAG_ENUM.TAG_SHOWUP_BTN then
        -- 显示上部菜单
        self:onShowTopMenu()
        ExternalFun.playClickEffect()
    else
        showToast(self, "功能尚未开放！", 1)
    end
end 

-- 切换押注相对应的特效   -- 123123
function Game1ViewLayer:Show_YaZhu_View(index, True)
    if index == 0 then
        self.Game_Wallpaper_Map:setTexture("Game1_Terrace/ViewLayer/Base_Map_1.jpg")
        -- 声音
        ExternalFun.playBackgroudAudio("QUANHUANG.mp3")
    elseif index == 1 then
        self.Game_Wallpaper_Map:setTexture("Game1_Terrace/ViewLayer/Base_Map_2.jpg")
        -- 声音
        ExternalFun.playBackgroudAudio("multiple_2.mp3")
    elseif index == 2 then
        self.Game_Wallpaper_Map:setTexture("Game1_Terrace/ViewLayer/Base_Map_3.jpg")
        -- 声音
        ExternalFun.playBackgroudAudio("multiple_3.mp3")
    elseif index == 3 then
        if True then
            self.Game_Wallpaper_Map:setTexture("Game1_Terrace/ViewLayer/Base_Map_4.jpg")
            -- 声音
            ExternalFun.playBackgroudAudio("multiple_4.mp3")
        else
            self:Head_Wallpaper_View_Hide_Left(True)
            self:Head_Wallpaper_View_Show_Right(True)
            self.LeftHead:setTexture("Game1_Terrace/head/1.png")
            self.RightHead:setTexture("Game1_Terrace/head/2.png")
            -- 声音
            ExternalFun.playBackgroudAudio("multiple_4.mp3")
        end
    elseif index == 4 then
        self.LeftHead:setTexture("Game1_Terrace/head/3.png")
        self.RightHead:setTexture("Game1_Terrace/head/4.png")
        -- 更换角色壁纸
        self:Head_Wallpaper_View_Hide_Left(True)
        self:Head_Wallpaper_View_Show_Right(True)
        -- 声音
        ExternalFun.playBackgroudAudio("multiple_5.mp3")
    end
end

function Game1ViewLayer:Head_Wallpaper_View_Hide_Left(True)
    if True then
        local actMove = cc.MoveTo:create(0.2, cc.p(-650, 0))
        local Sequence = cc.Sequence:create(
        actMove,
        cc.CallFunc:create( function()
            local actMove = cc.MoveTo:create(0.2, cc.p(0, 0))
            local Sequence = cc.Sequence:create(
            actMove,
            cc.CallFunc:create( function()
                self.Head_Wallpaper_Left:setTexture("Game1_Terrace/ViewLayer/Left_The_Player_2.png")
            end )
            )
            self.Head_Wallpaper_Left:runAction(Sequence)

        end )
        )
        self.Head_Wallpaper_Left:runAction(Sequence)
    else
        local actMove = cc.MoveTo:create(0.2, cc.p(-650, 0))
        local Sequence = cc.Sequence:create(
        actMove,
        cc.CallFunc:create( function()
            local actMove = cc.MoveTo:create(0.2, cc.p(0, 0))
            local Sequence = cc.Sequence:create(
            actMove,
            cc.CallFunc:create( function()
                self.Head_Wallpaper_Left:setTexture("Game1_Terrace/ViewLayer/Left_The_Player_1.png")
            end )
            )
            self.Head_Wallpaper_Left:runAction(Sequence)

        end )
        )
        self.Head_Wallpaper_Left:runAction(Sequence)
    end
    print("左边移动完毕")
end
function Game1ViewLayer:Head_Wallpaper_View_Show_Right(True)
    if True then
        local actMove = cc.MoveTo:create(0.2, cc.p(1334, 0))
        local Sequence = cc.Sequence:create(
        actMove,
        cc.CallFunc:create( function()
            local actMove = cc.MoveTo:create(0.2, cc.p(939, 0))
            local Sequence = cc.Sequence:create(
            actMove,
            cc.CallFunc:create( function()
                self.Head_Wallpaper_Right:setTexture("Game1_Terrace/ViewLayer/Right_The_Players_2.png")
            end )
            )
            self.Head_Wallpaper_Right:runAction(Sequence)

        end )
        )
        self.Head_Wallpaper_Right:runAction(Sequence)
    else
        local actMove = cc.MoveTo:create(0.2, cc.p(1334, 0))
        local Sequence = cc.Sequence:create(
        actMove,
        cc.CallFunc:create( function()
            local actMove = cc.MoveTo:create(0.2, cc.p(616, 0))
            local Sequence = cc.Sequence:create(
            actMove,
            cc.CallFunc:create( function()
                self.Head_Wallpaper_Right:setTexture("Game1_Terrace/ViewLayer/Right_The_Players_1.png")
            end )
            )
            self.Head_Wallpaper_Right:runAction(Sequence)

        end )
        )
        self.Head_Wallpaper_Right:runAction(Sequence)
    end
    print("右边移动完毕")
end
-- 隐藏上部菜单
function Game1ViewLayer:onHideTopMenu()
    if self.m_nodeMenu:getPositionX() == 1334 then
        return
    end
    local actMove = cc.MoveTo:create(0.5, cc.p(1334, 128))
    local Sequence = cc.Sequence:create(
    actMove,
    cc.CallFunc:create( function()
        local Button_Show = self._csbNode:getChildByName("Button_Show")
        if Button_Show then
            Button_Show:setVisible(true)
        end
    end )
    )
    self.m_nodeMenu:runAction(Sequence)
end
-- 显示上部菜单
function Game1ViewLayer:onShowTopMenu()
    if self.m_nodeMenu:getPositionX() == 1110 then
        return
    end
    local actMove = cc.MoveTo:create(0.5, cc.p(1110, 128))
    local spawn = cc.Spawn:create(
    cc.CallFunc:create( function()
        local Button_Show = self._csbNode:getChildByName("Button_Show")
        if Button_Show then
            Button_Show:setVisible(false)
        end
    end ),
    actMove
    )
    self.m_nodeMenu:runAction(spawn) 
end

-- 得到每个特殊图标在具体的每列
function Game1ViewLayer:View_Run_Eef()
    --
    local Index = 0
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1

        if i == 1 or i == 4 or i == 7 or i == 10 or i == 13 then
            Index = Index + 1
        end

        if nType == 10 and self.Run_TaiYangShen_View_TeXiao[Index] ~= 2 and self._scene.tagActionOneKaiJian.bZhongJiang[posy][posx] == true then
            self.Run_TaiYangShen_View_TeXiao[Index] = 1 == true
        elseif nType == 11 and self.Run_JunNv_View_TeXiao[Index] ~= 2 and self._scene.tagActionOneKaiJian.bZhongJiang[posy][posx] == true then
            self.Run_JunNv_View_TeXiao[Index] = 1 == true
        elseif nType == 9 and self.Run_BaiShen_View_TeXiao[Index] ~= 2 and self._scene.tagActionOneKaiJian.bZhongJiang[posy][posx] == true then
            self.Run_BaiShen_View_TeXiao[Index] = 1
        end
    end
end


-- 得到每个特殊图标在具体的每列
function Game1ViewLayer:View_Run_DS_LAN_Eef()
    --
    local Index = 0
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1

        if i == 1 or i == 4 or i == 7 or i == 10 or i == 13 then
            Index = Index + 1
        end

        if nType == 10 and self.Run_TaiYangShen_View_TeXiao[Index] ~= 2 then
            self.Run_TaiYangShen_View_TeXiao[Index] = 1
        elseif nType == 11 and self.Run_JunNv_View_TeXiao[Index] ~= 2 then
            self.Run_JunNv_View_TeXiao[Index] = 1
        elseif nType == 9 and self.Run_BaiShen_View_TeXiao[Index] ~= 2 then
            self.Run_BaiShen_View_TeXiao[Index] = 1
        end
    end
end
  
  
-- 播放动画序列帧动画：太阳神动画
function Game1ViewLayer:Run_TaiYangShen()

    --    --存储每列的动作动画，用于控制关闭动画
    --    self.Run_All_Eef_DongHua = {0,0,0,0,0}
    --    --存储每列的开场动画，用于控制关闭动画
    --    self.Run_All_Eef_KaiChang = {0,0,0,0,0}
    --    --存储每列的慢慢显示的动画，用于控制关闭动画
    --    self.Run_All_Eef_XianShi = {0,0,0,0,0}

    -- 设置按钮图片变成开始游戏
    -- self:updateStartButtonState(true)
    -- 播放特殊图标时先先得到具体坐标
    self:View_Run_DS_LAN_Eef()

    -- 得到播放的具体X,Y坐标
    local PosX_In_TaiYangShen =
    {
        316,
        490,
        668,
        842,
        1018
    }
    -- 播放动画的Y坐标
    local PosY_In_TaiYangShen = 355
    for i = 1, 5 do
        if self.Run_TaiYangShen_View_TeXiao[i] == 1 then
            print("准备播放动画啦~~~~~~！！！！！")
            -- 播放闪电劈下时音效
            ExternalFun.playSoundEffect("QHLHJ_90018(lashen).wav")
            -- 开场动画
            self.Run_All_Eef_KaiChang[i] = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_3.csb", self.TeSuTuBiaoDongHuaJieDian);
            self.Run_All_Eef_KaiChang[i]:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
            self._czEffects_BaiShen_Kuang_m_actAni1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_3.csb")
            -- 123123 播放排行特效

            ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni1)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                -- if self.Stop_All_Eef then
                -- 暴光粒子效果
                local emitter1 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_5.plist")
                emitter1:setAutoRemoveOnFinish(true)
                -- 设置播放完毕之后自动释放内存
                emitter1:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
                self.TeSuTuBiaoDongHuaJieDian:addChild(emitter1, 102)
                -- self:setVisible(false)
                -- 延迟定时器
                -- if self.Stop_All_Eef then
                self.FatherBiZhi:runAction(
                cc.Sequence:create(
                cc.DelayTime:create(0.5),
                cc.CallFunc:create( function()
                    -- if self.Stop_All_Eef then
                    -- 收光粒子特效
                    local emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_5_1.plist")
                    emitter2:setAutoRemoveOnFinish(true)
                    -- 设置播放完毕之后自动释放内存
                    emitter2:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
                    self.TeSuTuBiaoDongHuaJieDian:addChild(emitter2, 103)
                    -- if self.Stop_All_Eef then
                    -- 延时定时器
                    self.FatherBiZhi:runAction(
                    cc.Sequence:create(
                    cc.DelayTime:create(0.5),
                    cc.CallFunc:create( function()
                        -- if self.Stop_All_Eef then
                        -- 若隐若现动画
                        local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_4.csb", self.TeSuTuBiaoDongHuaJieDian);
                        self.Run_All_Eef_XianShi[i] = Boss
                        self.Run_All_Eef_XianShi[i]:setPosition(PosX_In_TaiYangShen[i] -50, PosY_In_TaiYangShen)
                        self._czEffects_BaiShen_Kuang_m_actAni12 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_4.csb")
                        -- 123123 播放排行特效
                        ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni12)
                        local Incident = function(frame)
                            if nil == frame then
                                return
                            end
                            -- if self.Stop_All_Eef then
                            -- 动作动画
                            -- 播放对应特殊动作音效
                            ExternalFun.playSoundEffect("QHLHJ_90021(dashebianshen).wav")
                            local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_2_.csb", self.TeSuTuBiaoDongHuaJieDian);
                            self.Run_All_Eef_DongHua[i] = Boss
                            self.Run_All_Eef_DongHua[i]:setPosition(PosX_In_TaiYangShen[i] -10, PosY_In_TaiYangShen)
                            self._czEffects_BaiShen_Kuang_m_actAni123 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_2_.csb")
                            -- 123123 播放排行特效
                            ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni123)

                            self.Run_All_Eef_DongHua[i]:stopAllActions()
                            --- 123123
                            self._czEffects_BaiShen_Kuang_m_actAni123:gotoFrameAndPlay(0, false)
                            self.Run_All_Eef_DongHua[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni123)

                            -- end
                        end
                        self._czEffects_BaiShen_Kuang_m_actAni12:setFrameEventCallFunc(Incident)
                        -- 动画的使用事件
                        self.Run_All_Eef_XianShi[i]:stopAllActions()
                        self._czEffects_BaiShen_Kuang_m_actAni12:gotoFrameAndPlay(0, false)
                        self.Run_All_Eef_XianShi[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni12)
                        -- end
                    end )
                    )
                    )
                    -- end
                    -- end
                end )
                )
                )
                -- end
                -- end
            end
            self._czEffects_BaiShen_Kuang_m_actAni1:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Run_All_Eef_KaiChang[i]:stopAllActions()
            self._czEffects_BaiShen_Kuang_m_actAni1:gotoFrameAndPlay(0, false)
            self.Run_All_Eef_KaiChang[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni1)
        end
    end
    local Index = 0
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1

        if i == 1 or i == 4 or i == 7 or i == 10 or i == 13 then
            Index = Index + 1
        end

        if self.Run_TaiYangShen_View_TeXiao[Index] == 1 then
            self.Run_TaiYangShen_View_TeXiao[Index] = 2
        elseif self.Run_JunNv_View_TeXiao[Index] == 1 then
            self.Run_JunNv_View_TeXiao[Index] = 2
        elseif self.Run_BaiShen_View_TeXiao[Index] == 1 then
            self.Run_BaiShen_View_TeXiao[Index] = 2
        end
    end
end
-- 播放动画序列帧动画：军娘动画
function Game1ViewLayer:Run_JunNiang()

    --    --存储每列的动作动画，用于控制关闭动画
    --    self.Run_All_Eef_DongHua = {0,0,0,0,0}
    --    --存储每列的开场动画，用于控制关闭动画
    --    self.Run_All_Eef_KaiChang = {0,0,0,0,0}
    --    --存储每列的慢慢显示的动画，用于控制关闭动画
    --    self.Run_All_Eef_XianShi = {0,0,0,0,0}

    -- 设置按钮图片变成开始游戏
    -- self:updateStartButtonState(true)
    -- 播放特殊图标时先先得到具体坐标
    self:View_Run_DS_LAN_Eef()

    -- 得到播放的具体X,Y坐标
    local PosX_In_TaiYangShen =
    {
        316,
        490,
        668,
        842,
        1018
    }
    -- 播放动画的Y坐标
    local PosY_In_TaiYangShen = 355
    for i = 1, 5 do
        if self.Run_JunNv_View_TeXiao[i] == 1 then
            print("准备播放动画啦~~~~~~！！！！！")
            -- 播放闪电劈下时音效
            ExternalFun.playSoundEffect("QHLHJ_90018(lashen).wav")
            -- 开场动画
            self.Run_All_Eef_KaiChang[i] = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_3.csb", self.TeSuTuBiaoDongHuaJieDian);
            self.Run_All_Eef_KaiChang[i]:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
            self._czEffects_BaiShen_Kuang_m_actAni1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_3.csb")
            -- 123123 播放排行特效

            ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni1)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                if self.Stop_JunNv_Eef then
                    -- 暴光粒子效果
                    local emitter1 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/JunNV/" .. "XT_1140_5.plist")
                    emitter1:setAutoRemoveOnFinish(true)
                    -- 设置播放完毕之后自动释放内存
                    emitter1:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
                    self.TeSuTuBiaoDongHuaJieDian:addChild(emitter1, 102)
                    -- self:setVisible(false)
                    -- 延迟定时器
                    if self.Stop_JunNv_Eef then
                        self.FatherBiZhi:runAction(
                        cc.Sequence:create(
                        cc.DelayTime:create(0.5),
                        cc.CallFunc:create( function()
                            if self.Stop_JunNv_Eef then
                                -- 收光粒子特效
                                local emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/JunNV/" .. "XT_1140_5_1.plist")
                                emitter2:setAutoRemoveOnFinish(true)
                                -- 设置播放完毕之后自动释放内存
                                emitter2:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
                                self.TeSuTuBiaoDongHuaJieDian:addChild(emitter2, 103)
                                if self.Stop_JunNv_Eef then
                                    -- 延时定时器
                                    self.FatherBiZhi:runAction(
                                    cc.Sequence:create(
                                    cc.DelayTime:create(0),
                                    cc.CallFunc:create( function()
                                        if self.Stop_JunNv_Eef then
                                            -- 若隐若现动画
                                            local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/JunNV/" .. "XT_1140_3.csb", self.TeSuTuBiaoDongHuaJieDian);
                                            self.Run_All_Eef_XianShi[i] = Boss
                                            self.Run_All_Eef_XianShi[i]:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen - 50)
                                            self._czEffects_BaiShen_Kuang_m_actAni12 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/JunNV/" .. "XT_1140_3.csb")
                                            -- 123123 播放排行特效
                                            ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni12)
                                            local Incident = function(frame)
                                                if nil == frame then
                                                    return
                                                end
                                                if self.Stop_JunNv_Eef then
                                                    -- 动作动画
                                                    -- 播放对应特殊动作音效
                                                    ExternalFun.playSoundEffect("QHLHJ_90020(lianabianshen).wav")
                                                    local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/JunNV/" .. "XT_1140_2.csb", self.TeSuTuBiaoDongHuaJieDian);
                                                    self.Run_All_Eef_DongHua[i] = Boss
                                                    self.Run_All_Eef_DongHua[i]:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen - 50)
                                                    self._czEffects_BaiShen_Kuang_m_actAni123 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/JunNV/" .. "XT_1140_2.csb")
                                                    -- 123123 播放排行特效
                                                    ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni123)

                                                    self.Run_All_Eef_DongHua[i]:stopAllActions()
                                                    self._czEffects_BaiShen_Kuang_m_actAni123:gotoFrameAndPlay(0, true)
                                                    self.Run_All_Eef_DongHua[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni123)
                                                    -- 执行完毕后关闭控制动画隐藏
                                                    -- self.szSpecial_Spirit = false
                                                end
                                            end
                                            self._czEffects_BaiShen_Kuang_m_actAni12:setFrameEventCallFunc(Incident)
                                            -- 动画的使用事件
                                            self.Run_All_Eef_XianShi[i]:stopAllActions()
                                            self._czEffects_BaiShen_Kuang_m_actAni12:gotoFrameAndPlay(0, false)
                                            self.Run_All_Eef_XianShi[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni12)
                                        end
                                    end )
                                    )
                                    )
                                end
                            end
                        end )
                        )
                        )
                    end
                end
            end
            self._czEffects_BaiShen_Kuang_m_actAni1:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Run_All_Eef_KaiChang[i]:stopAllActions()
            self._czEffects_BaiShen_Kuang_m_actAni1:gotoFrameAndPlay(0, false)
            self.Run_All_Eef_KaiChang[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni1)
        end
    end
    local Index = 0
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1

        if i == 1 or i == 4 or i == 7 or i == 10 or i == 13 then
            Index = Index + 1
        end

        if self.Run_TaiYangShen_View_TeXiao[Index] == 1 then
            self.Run_TaiYangShen_View_TeXiao[Index] = 2
        elseif self.Run_JunNv_View_TeXiao[Index] == 1 then
            self.Run_JunNv_View_TeXiao[Index] = 2
        elseif self.Run_BaiShen_View_TeXiao[Index] == 1 then
            self.Run_BaiShen_View_TeXiao[Index] = 2
        end
    end
end
 
-- 播放动画序列帧动画：八神庵动画
function Game1ViewLayer:Run_BaiShen()
    --    --存储每列的动作动画，用于控制关闭动画
    --    self.Run_All_Eef_DongHua = {0,0,0,0,0}
    --    --存储每列的开场动画，用于控制关闭动画
    --    self.Run_All_Eef_KaiChang = {0,0,0,0,0}
    --    --存储每列的慢慢显示的动画，用于控制关闭动画
    --    self.Run_All_Eef_XianShi = {0,0,0,0,0}

    -- 设置按钮图片变成开始游戏
    -- self:updateStartButtonState(true)
    -- 播放特殊图标时先先得到具体坐标
    self:View_Run_Eef()

    -- 得到播放的具体X,Y坐标
    local PosX_In_TaiYangShen =
    {
        316,
        490,
        668,
        842,
        1018
    }
    -- 播放动画的Y坐标
    local PosY_In_TaiYangShen = 355
    for i = 1, 5 do
        if self.Run_BaiShen_View_TeXiao[i] == 1 then
            print("准备播放动画啦~~~~~~！！！！！")
            -- 播放闪电劈下时音效
            ExternalFun.playSoundEffect("QHLHJ_90018(lashen).wav")
            -- 开场动画
            self.Run_All_Eef_KaiChang[i] = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_3.csb", self.TeSuTuBiaoDongHuaJieDian);
            self.Run_All_Eef_KaiChang[i]:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
            self._czEffects_BaiShen_Kuang_m_actAni1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/TaiYangShen/" .. "XT_1150_3.csb")
            -- 123123 播放排行特效

            ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni1)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                if self.Stop_All_Eef then
                    -- 暴光粒子效果
                    local emitter1 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BaiShen/" .. "XT_1130_5.plist")
                    emitter1:setAutoRemoveOnFinish(true)
                    -- 设置播放完毕之后自动释放内存
                    emitter1:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
                    self.TeSuTuBiaoDongHuaJieDian:addChild(emitter1, 102)
                    -- self:setVisible(false)
                    -- 延迟定时器
                    if self.Stop_All_Eef then
                        self.FatherBiZhi:runAction(
                        cc.Sequence:create(
                        cc.DelayTime:create(0.5),
                        cc.CallFunc:create( function()
                            if self.Stop_All_Eef then
                                -- 收光粒子特效
                                local emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BaiShen/" .. "XT_1130_5_1.plist")
                                emitter2:setAutoRemoveOnFinish(true)
                                -- 设置播放完毕之后自动释放内存
                                emitter2:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen)
                                self.TeSuTuBiaoDongHuaJieDian:addChild(emitter2, 103)
                                if self.Stop_All_Eef then
                                    -- 延时定时器
                                    self.FatherBiZhi:runAction(
                                    cc.Sequence:create(
                                    cc.DelayTime:create(0.5),
                                    cc.CallFunc:create( function()
                                        if self.Stop_All_Eef then
                                            -- 若隐若现动画
                                            local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BaiShen/" .. "XT_1130_3.csb", self.TeSuTuBiaoDongHuaJieDian);
                                            self.Run_All_Eef_XianShi[i] = Boss
                                            self.Run_All_Eef_XianShi[i]:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen - 80)
                                            self._czEffects_BaiShen_Kuang_m_actAni12 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BaiShen/" .. "XT_1130_3.csb")
                                            -- 123123 播放排行特效
                                            ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni12)
                                            local Incident = function(frame)
                                                if nil == frame then
                                                    return
                                                end
                                                if self.Stop_All_Eef then
                                                    -- 动作动画
                                                    -- 播放对应特殊动作音效
                                                    ExternalFun.playSoundEffect("QHLHJ_90019(bashenbianshen).wav")
                                                    local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BaiShen/" .. "XT_1130_2.csb", self.TeSuTuBiaoDongHuaJieDian);
                                                    self.Run_All_Eef_DongHua[i] = Boss
                                                    self.Run_All_Eef_DongHua[i]:setPosition(PosX_In_TaiYangShen[i], PosY_In_TaiYangShen - 80)
                                                    self._czEffects_BaiShen_Kuang_m_actAni123 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/BaiShen/" .. "XT_1130_2.csb")
                                                    -- 123123 播放排行特效
                                                    ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni123)

                                                    self.Run_All_Eef_DongHua[i]:stopAllActions()
                                                    self._czEffects_BaiShen_Kuang_m_actAni123:gotoFrameAndPlay(0, true)
                                                    self.Run_All_Eef_DongHua[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni123)
                                                    -- 执行完毕后关闭控制动画隐藏
                                                    -- self.szSpecial_Spirit = false
                                                end
                                            end
                                            self._czEffects_BaiShen_Kuang_m_actAni12:setFrameEventCallFunc(Incident)
                                            -- 动画的使用事件
                                            self.Run_All_Eef_XianShi[i]:stopAllActions()
                                            self._czEffects_BaiShen_Kuang_m_actAni12:gotoFrameAndPlay(0, false)
                                            self.Run_All_Eef_XianShi[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni12)
                                        end
                                    end )
                                    )
                                    )
                                end
                            end
                        end )
                        )
                        )
                    end
                end
            end
            self._czEffects_BaiShen_Kuang_m_actAni1:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Run_All_Eef_KaiChang[i]:stopAllActions()
            self._czEffects_BaiShen_Kuang_m_actAni1:gotoFrameAndPlay(0, false)
            self.Run_All_Eef_KaiChang[i]:runAction(self._czEffects_BaiShen_Kuang_m_actAni1)
        end
    end
    local Index = 0
    for i = 1, 15 do
        local posx = math.ceil(i / 3)
        local posy =(i - 1) % 3 + 1
        local nType = tonumber(self._scene.m_cbItemInfo[posy][posx]) + 1

        if i == 1 or i == 4 or i == 7 or i == 10 or i == 13 then
            Index = Index + 1
        end

        if self.Run_TaiYangShen_View_TeXiao[Index] == 1 then
            self.Run_TaiYangShen_View_TeXiao[Index] = 2
        elseif self.Run_JunNv_View_TeXiao[Index] == 1 then
            self.Run_JunNv_View_TeXiao[Index] = 2
        elseif self.Run_BaiShen_View_TeXiao[Index] == 1 then
            self.Run_BaiShen_View_TeXiao[Index] = 2
        end
    end
end

-- 声音设置界面
function Game1ViewLayer:onSetLayer()
    self:onHideTopMenu()
    local mgr = self._scene._scene:getApp():getVersionMgr()
    local verstr = mgr:getResVersion(g_var(cmd).KIND_ID) or "0"
    verstr = "游戏版本:" .. appdf.BASE_C_VERSION .. "." .. verstr
    local set = SettingLayer:create(verstr)
    set:setZOrder(100)
    self._csbNode:addChild(set)
end

function Game1ViewLayer:onHelpLayer()
    self:onHideTopMenu()
    --    local help = HelpLayer:create()
    --    self._csbNode:addChild(help)
    --    help:setLocalZOrder(9)
end

-- 自动游戏
function Game1ViewLayer:setAutoStart(bisShow)
     --显示勾
     local spSelect = self._csbNode:getChildByName("QH_ZIDONG_1_2")
     if spSelect then
     	spSelect:setVisible(bisShow) 
     end 
--     if bisShow then
        self:Button_Gray( not bisShow)
        self:updateStartButtonState(true)
--     else
--        self:Button_Gray(bisShow)
--     end
end

-- 改变比倍按钮和
function Game1ViewLayer:enableGame2Btn(isEnable)
    -- if self.Node_btnEffet then
    -- 	self.Node_btnEffet:setVisible(isEnable)		
    -- end
    -- local Button_Game2 = self._csbNode:getChildByName("Button_Game2");
    -- Button_Game2:setEnabled(isEnable)
end

-- 切换开始按钮和停止按钮的纹理
function Game1ViewLayer:updateStartButtonState(bIsStart)
    local Button_Start = self._csbNode:getChildByName("Button_Start");
    if bIsStart == true then
        if self._scene.m_bIsAuto == false then
            Button_Start:loadTextureNormal("Game1_Terrace/Button/QH_BEGIN.png")
            Button_Start:loadTexturePressed("Game1_Terrace/Button/QH_BEGIN.png")
            --       else
            --            Button_Start:loadTextureNormal("Game1_Terrace/Button/BeginGame3.png")QH_SPOT
            --            Button_Start:loadTexturePressed("Game1_Terrace/Button/BeginGame3_1.png")
        end
--        self.XXOOSHOWDONGHUA = true
    else
--        if self._scene.m_bIsAuto then
--            Button_Start:loadTextureNormal("Game1_Terrace/Button/BeginGame2.png")
--            Button_Start:loadTexturePressed("Game1_Terrace/Button/BeginGame2_1.png")
--        else
            Button_Start:loadTextureNormal("Game1_Terrace/Button/QH_SPOT.png")
            Button_Start:loadTexturePressed("Game1_Terrace/Button/QH_SPOT.png")
--        end
--        self.XXOOSHOWDONGHUA = false
    end
end

function Game1ViewLayer:game1ActionBanner(bIsWait)
    -- local qizhi1 = self.Node_top:getChildByName("Sprite_piaoqi")
    -- qizhi1:setVisible(bIsWait)
    -- local qizhi2 = self.Node_top:getChildByName("Sprite_piaoqi2")
    -- qizhi2:setVisible(not bIsWait)
end

function Game1ViewLayer:Game1ZhongxianAudio(bIndex)
    if bIndex <= 8 then
        local soundPath =
        {
            "QHLHJ_90010(caozijingzhongjiang).wav",
            "QHLHJ_90011(buzhihuowuzhongjiang).wav",
            "QHLHJ_90012(teruizhongjiang).wav",
            "QHLHJ_90013(kelakezhongjiang).wav",
            "QHLHJ_90014(chenguohanzhongjiang).wav",
            "QHLHJ_90015(tanghongwanzhongjiang).wav",
            "QHLHJ_90016(damenzhongjiang).wav",
            "QHLHJ_90017(caibaojianzhongjiang).wav"
        }
        ExternalFun.playSoundEffect(soundPath[bIndex])
    end
end
-- ---------------------------------------------------------------------------------------
------						游戏2 小游戏
------------------------------------------------------------------------------------ 
function Game3ViewLayer:ctor(scene)
    -- 注册node事件
    ExternalFun.registerNodeEvent(self)
    self.DongZuo = nil

    self._scene = scene

    self._All_Win_Meney = 0

    self.BtnAnXia = 1
    -- 记录节拍条运动次数初始为1 最高为5
    self._Globe = 0
    -- 对比球体按下状态后重新规划球体运动终点

    self._scene:game3DataInit();
    self:initCsbRes();
    -- 播放背景音乐
    ExternalFun.playBackgroudAudio("Freegame.mp3")
    -- self._scene:sendReadyMsg3()   --发送准备消息
end


-- 最后展示游戏特效
function Game3ViewLayer:Win_Loser_EFF(BOOL)
    ExternalFun.playSoundEffect("QHLHJ_90032(ko).wav")
    if BOOL then
        local ShowKO = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1163.csb", self);
        -- 播放KO动画
        ShowKO_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1163.csb")
        ExternalFun.SAFE_RETAIN(ShowKO_Run)
        local Incident = function(frame)
            if nil == frame then
                return
            end

            -- 播放金币雨音效
            ExternalFun.playSoundEffect("QHLHJ_90034(jiesuanchenggong).wav")

            local emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_JinBi.plist")
            emitter2:setAutoRemoveOnFinish(true)
            -- 设置播放完毕之后自动释放内存
            emitter2:setScale(1.5, 1.5)
            emitter2:setPosition(667, 777)
            self:addChild(emitter2, 103)



            local bad = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "quan_huang_TX_1164_3.csb", self);
            self.Bad = bad
            self.Bad:setPosition(667, 375)

            local Gold = self.Bad:getChildByName("AtlasLabel_1")
            -- 设置艺术字体
            Gold:setString(self._All_Win_Meney)

            self.Bad_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "quan_huang_TX_1164_3.csb")
            -- 123123 播放排行特效
            ExternalFun.SAFE_RETAIN(self.Bad_Run)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                -- 在指定时间内结束小游戏
                self.schedulerID = 2
                -- 即将退出小游戏赋值为2
                -- 结束小游戏游戏
                self:backOneGame()
            end
            self.Bad_Run:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Bad:stopAllActions()
            self.Bad_Run:gotoFrameAndPlay(0, false)
            self.Bad:runAction(self.Bad_Run)
        end
        ShowKO_Run:setFrameEventCallFunc(Incident)
        -- 动画的使用事件
        ShowKO:stopAllActions()
        ShowKO_Run:gotoFrameAndPlay(0, false)
        ShowKO:runAction(ShowKO_Run)
    else
        local ShowKO = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1163.csb", self);
        -- 播放KO动画
        ShowKO_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1163.csb")
        ExternalFun.SAFE_RETAIN(ShowKO_Run)
        local Incident = function(frame)
            if nil == frame then
                return
            end

            -- 播放金币雨音效
            ExternalFun.playSoundEffect("QHLHJ_90034(jiesuanshibai).wav")

            local emitter2 = cc.ParticleSystemQuad:create(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1165_1.plist")
            emitter2:setAutoRemoveOnFinish(true)
            -- 设置播放完毕之后自动释放内存
            emitter2:setPosition(667, 777)
            emitter2:setScale(1.5, 1.5)
            self:addChild(emitter2, 103)

            -- 玩家操作失败
            local bad = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1165.csb", self);
            self.Bad = bad
            self.Bad:setPosition(667, 375)
            self.Bad_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1165.csb")
            -- 123123 播放排行特效
            ExternalFun.SAFE_RETAIN(self.Bad_Run)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                local EEF = self.Bad:getChildByName("Sprite_1")
                local Gold = EEF:getChildByName("AtlasLabel_1")
                -- 设置艺术字体
                Gold:setString(self._All_Win_Meney)

                -- 在指定时间内结束小游戏
                self._csbNode:runAction(
                cc.Sequence:create(
                cc.DelayTime:create(5),
                cc.CallFunc:create( function()
                    self.schedulerID = 2
                    -- 即将退出小游戏赋值为2
                    -- 结束小游戏游戏
                    self:backOneGame()

                end )
                )
                )

            end
            self.Bad_Run:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Bad:stopAllActions()
            self.Bad_Run:gotoFrameAndPlay(0, false)
            self.Bad:runAction(self.Bad_Run)

        end
        ShowKO_Run:setFrameEventCallFunc(Incident)
        -- 动画的使用事件
        ShowKO:stopAllActions()
        ShowKO_Run:gotoFrameAndPlay(0, false)
        ShowKO:runAction(ShowKO_Run)
    end
end
 
-- 隐藏显示节拍器
function Game3ViewLayer:Show_YinChang(BOOL)
    self._czJiePaiQi = self._csbNode:getChildByName("Sprite_22")
    self._czJiePaiQi:setVisible(BOOL)

    -- 节拍器背景图片
    local JIEPAIQIBK = self._csbNode:getChildByName("Sprite_21")
    JIEPAIQIBK:setVisible(BOOL)
    -- 节拍器终点图片
    local JiePaiQiZD = self._csbNode:getChildByName("Sprite_23")
    JiePaiQiZD:setVisible(BOOL)


end

-- 界面初始化
function Game3ViewLayer:initCsbRes()
    rootLayer, self._csbNode = ExternalFun.loadRootCSB(GameViewLayer.RES_PATH .. "Small.csb", self);
    -- 初始化按钮
    self:initUI(self._csbNode)

    -- 播放动画的基准节点
    self.DongHuaJiDian = self._csbNode:getChildByName("Node_1")

    self:Show_YinChang(false)
    -- 得到对应的能量块 并设置层级
    self.NengLiangKuai = { 0, 0, 0, 0, 0, 0 }
    self.NengLiangKuai[1] = self._csbNode:getChildByName("Sprite_14")
    self.NengLiangKuai[1]:setZOrder(10)
    self.NengLiangKuai[2] = self._csbNode:getChildByName("Sprite_15")
    self.NengLiangKuai[2]:setZOrder(10)
    self.NengLiangKuai[3] = self._csbNode:getChildByName("Sprite_16")
    self.NengLiangKuai[3]:setZOrder(10)
    self.NengLiangKuai[4] = self._csbNode:getChildByName("Sprite_18")
    self.NengLiangKuai[4]:setZOrder(10)
    self.NengLiangKuai[5] = self._csbNode:getChildByName("Sprite_19")
    self.NengLiangKuai[5]:setZOrder(10)
    self.NengLiangKuai[6] = self._csbNode:getChildByName("Sprite_20")
    self.NengLiangKuai[6]:setZOrder(10)
    -- 设置能量块背景层级
    local NengLiangBK = self._csbNode:getChildByName("Sprite_17")
    NengLiangBK:setZOrder(9)
    local NengLiangBK = self._csbNode:getChildByName("Sprite_13")
    NengLiangBK:setZOrder(9)

    self.NengLiangKuaiQieHuan = false
    -- 得到玩家血条，大蛇血条
    self.UserBold = self._csbNode:getChildByName("blood_1_24")
    self.DaSheBold = self._csbNode:getChildByName("blood_2_25")


    -- 延迟1.5秒显示GO
    self._csbNode:runAction(
    cc.Sequence:create(
    cc.DelayTime:create(1.5),
    cc.CallFunc:create( function()
        -- self:beginMove_Effects(1020 , true)   -- 开始播放特效时间
        -- 播放对应动画动作音效
        ExternalFun.playSoundEffect("QHLHJ_90030(readygo).wav")

        local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/Small_Game_Effects/" .. "XT_1161.csb", self);
        self._czEffects_BaiShen_Kuang = Boss
        self._czEffects_BaiShen_Kuang_m_actAni1 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Specia_Effects/Small_Game_Effects/" .. "XT_1161.csb")
        -- 123123 播放排行特效
        ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_Kuang_m_actAni1)
        local Incident = function(frame)
            if nil == frame then
                return
            end
            Countdown_.remove_scheduler()
            -- 如果有刷新，就先删除，赋值为nil
            Countdown_.ctor()
            Countdown_.settime(0, 0, 60)
            -- 设置时间： 时钟，分钟，秒钟 rotatePara["Scoreinterval"]
            Countdown_.add_0()
            -- 将传入的时间，全部转成string类型的
            local ttF = Countdown_.Showlabel(596., 645, 0, 0, 0)
            -- 传入x，y坐标值，创建一个label显示
            Countdown_.remove_hour(2)
            -- 移除时钟的显示
            Countdown_.scheduleFunc(1)
            -- 创建一个刷新函数
            self._scene:addChild(ttF, 3)
            local function call_f()
                -- 这里是倒计时结束后，要调用的函数
                print("时间到了结束小游戏")
                --                                    if self.BtnAnXia ~= 5 then
                --                                        self:Win_Loser_EFF(false)
                --                                    end
            end
            Countdown_.function_(call_f)
            -- 我们把函数作为参数，传到这个类中


            self.Btn:setVisible(true)
            self:Show_YinChang(true)
            -- 得到节拍器移动球体
            self._czJiePaiQi:setZOrder(1)
            self._czJiePaiQi:setPosition(491, 323)



            -- 播放没有按下按钮的动画
            local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Btn/" .. "XT_1166.csb", self);
            self._czEffects_BaiShen = Boss
            self._czEffects_BaiShen_actAni12 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Btn/" .. "XT_1166.csb")
            ExternalFun.SAFE_RETAIN(self._czEffects_BaiShen_actAni12)
            self._czEffects_BaiShen:stopAllActions()
            self._czEffects_BaiShen_actAni12:gotoFrameAndPlay(0, true)
            -- 设置是否循环播放
            self._czEffects_BaiShen:runAction(self._czEffects_BaiShen_actAni12)
            -- 开启定时器
            local scheduler = cc.Director:getInstance():getScheduler()
            self.schedulerID = nil
            self.schedulerID = scheduler:scheduleScriptFunc( function()
                self:Move_QiuTi()
                -- 定时器执行的函数
            end , 0, false)
        end
        self._czEffects_BaiShen_Kuang_m_actAni1:setFrameEventCallFunc(Incident)
        -- 动画的使用事件
        self._czEffects_BaiShen_Kuang:stopAllActions()
        self._czEffects_BaiShen_Kuang_m_actAni1:gotoFrameAndPlay(0, false)
        self._czEffects_BaiShen_Kuang:runAction(self._czEffects_BaiShen_Kuang_m_actAni1)
    end )
    )
    )


    self:Run_DaTing_JueSe(1)
end
 

local ij = 1
local Run_QiuTi = true
function Game3ViewLayer:Run_DaTing_JueSe(Index)

    if Index == 1 then
        -- 待机动画播放
        if self.RunDaiJi == nil then
            local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "QUANHUANG_DJ.csb", self.DongHuaJiDian);
            self.RunDaiJi = Boss
            self.RunDaiJi:setZOrder(0)
            self.RunDaiJi:setPosition(667, 375)
            self._czEffects = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "QUANHUANG_DJ.csb")
            -- 123123 播放排行特效
            ExternalFun.SAFE_RETAIN(self._czEffects)
            self.RunDaiJi:stopAllActions()
            --- 123123
            self._czEffects:gotoFrameAndPlay(0, true)
            self.RunDaiJi:runAction(self._czEffects)
        else
            self.RunDaiJi:setVisible(true)
        end
    else
        -- 每次进入播放动画的时候进行一次获得金币的累加
        self._All_Win_Meney = self._All_Win_Meney + self._scene.m_lGetCoins3

        local Music_DongZuo =
        {
            "QHLHJ_90104(KUIHUA).wav",
            "QHLHJ_90105(QYY).wav",
            "QHLHJ_90102(bzn).wav",
            "QHLHJ_90101(bjb).wav",
            "QHLHJ_90103(CBS).wav",
            "QHLHJ_90106(YGPZ).wav"
        }
        ExternalFun.playSoundEffect(Music_DongZuo[Index - 1])
        -- 播放对应动画动作音效
        --         ExternalFun.playSoundEffect(Music_DongZuo[Index - 1])
        --          if Index == 7 then
        --                ExternalFun.playSoundEffect("QHLHJ_90106(YGPZ).wav")
        --          else
        --                ExternalFun.playSoundEffect(Music_DongZuo[Index - 1])
        --          end

        if Index == 2 then
            -- 第一招动画播放
            self:Run_DongZuo("Dongzuo_KUIHUA.csb")
        elseif Index == 3 then
            -- 第二招动画播放  QH_QYY Dongzuo_KUIHUA
            self:Run_DongZuo("Dongzuo_QYY.csb")
        elseif Index == 4 then
            -- 第三招动画播放
            self:Run_DongZuo("DongzuoBZN.csb")
        elseif Index == 5 then
            -- 第四招动画播放
            self:Run_DongZuo("QHBJB.csb")
        elseif Index == 6 then
            -- 第五招动画播放
            self:Run_DongZuo("Dongzuo_CBS.csb")
        elseif Index == 7 then
            -- 大蛇攻击动画播放 DONGZUOYGPT
            self:Run_DongZuo("DONGZUOYGPT.csb")
        end

        --        if Index == 2 then  -- 第一招动画播放
        --            self:Run_DongZuo("DongzuoBZN.csb")
        --        elseif Index == 3 then  -- 第四招动画播放
        --            self:Run_DongZuo("QHBJB.csb")
        --        elseif Index == 4 then  -- 第五招动画播放
        --            self:Run_DongZuo("Dongzuo_CBS.csb")
        --        elseif Index == 7 then  -- 大蛇攻击动画播放 DONGZUOYGPT
        --            self:Run_DongZuo("DONGZUOYGPT.csb")
        --        end


        local Time = 3.75
        --        local Time = 5.2
        if Index == 2 then
            Time = 3.5
        elseif Index > 3 then
            Time = 5
        end

        self._csbNode:runAction(
        cc.Sequence:create(
        cc.DelayTime:create(Time),
        cc.CallFunc:create( function()


            if Index ~= 7 then
                -- 大蛇的减少血条
                -- 大蛇血条减少至零结束游戏
                local ShowLong = 414 -(82 * ij)
                self.DaSheBold:setTextureRect(cc.rect(0, 0, ShowLong, 31))
                ij = ij + 1

                if Index == 6 then
                    -- 播放完超必杀之后
                    self:Win_Loser_EFF(true)
                else
                    -- 当前不是结束动画比如 大蛇攻击玩家，或者玩家最后一招攻击大蛇，那么切换回待机动画，否则该动画停留
                    self.DongZuo:setVisible(false)
                    self.RunDaiJi:setVisible(true)
                    Run_QiuTi = true
                    local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1180.csb", self);
                    self._czEffects_XiaoJiBi = Boss
                    self._czEffects_XiaoJiBi:setPosition(617, 375)
                    self._czEffects_XiaoJiBiShiJian = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "XT_1180.csb")
                    -- 123123 播放获得金币特效
                    ExternalFun.SAFE_RETAIN(self._czEffects_XiaoJiBiShiJian)
                    local Incident = function(frame)
                        if nil == frame then
                            return
                        elseif frame:getEvent() == "Show_Num" then
                            -- 展现数字
                            local Gold = self._czEffects_XiaoJiBi:getChildByName("AtlasLabel_1")
                            -- 设置艺术字体 -- 每次获得金币数量
                            if self._scene.m_lGetCoins3 == nil then -- 针对切换后台之后切回游戏的重新连接服务器 写死数据  HZ~~~~~~
                                self._scene.m_lGetCoins3 = 0
                            end
                            Gold:setString(self._scene.m_lGetCoins3)
                            --                                                 self:addChild(emitter2,103)
                        elseif frame:getEvent() == "End_begin" then
                            -- 关闭当前特效

                            -- 检测完成度 -- ：
                            -- self._scene.m_lGetTpye 根据服务器返回的小游戏可点击的次数判定当前小游戏玩耍的次数
                            --  self:Win_Loser_EFF(变量) --》》 正常退出小游戏为true
                            if self._scene.m_lGetTpye == nil then -- 针对切换后台之后切回游戏的重新连接服务器 写死数据  HZ~~~~~~
                                self._scene.m_lGetTpye = 0
                            end
                            if (self.BtnAnXia - self._scene.m_lGetTpye) == self.BtnAnXia then
                                self:Win_Loser_EFF(true)
                            else
                                self.Btn:setVisible(true)
                                self:Show_YinChang(true)
                                -- 按钮按下动画播放完毕之后让没有操作的按钮动画显示
                                self._czEffects_BaiShen:setVisible(true)

                                local scheduler = cc.Director:getInstance():getScheduler()
                                self.schedulerID = nil
                                self.schedulerID = scheduler:scheduleScriptFunc( function()
                                    self:Move_QiuTi()
                                    -- 定时器执行的函数
                                end , 0, false)
                            end


                        end

                    end
                    self._czEffects_XiaoJiBiShiJian:setFrameEventCallFunc(Incident)
                    -- 动画的使用事件
                    self._czEffects_XiaoJiBi:stopAllActions()
                    self._czEffects_XiaoJiBiShiJian:gotoFrameAndPlay(0, false)
                    self._czEffects_XiaoJiBi:runAction(self._czEffects_XiaoJiBiShiJian)
                end

            else
                -- 减少玩家的血条
                -- 玩家血条一次性减少至零结束游戏
                self.UserBold:setVisible(false)
                -- 设置可见矩形 setTextureRect()
                self:Win_Loser_EFF(false)
            end

        end )
        )
        )
    end
end

function Game3ViewLayer:Run_DongZuo(Name)
    self.RunDaiJi:setVisible(false)

    self.DongZuo = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. Name, self.DongHuaJiDian);
    self.DongZuo:setPosition(667, 375)
    self.DongZuo:setZOrder(0)
    local czEffects = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. Name)
    -- 123123 播放排行特效
    ExternalFun.SAFE_RETAIN(czEffects)
    self.DongZuo:stopAllActions()
    --- 123123
    czEffects:gotoFrameAndPlay(0, false)
    self.DongZuo:runAction(czEffects)
end



-- 按下效果状态动画
function Game3ViewLayer:DianZhong_And_MeiDianZhong(EEF_Name)
    -- 按下效果动画
    local bad = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. EEF_Name, self);
    self.Bad = bad
    self.Bad:setPosition(208.57, 153.24)
    self.Bad_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. EEF_Name)
    -- 123123 播放排行特效
    ExternalFun.SAFE_RETAIN(self.Bad_Run)
    self.Bad:stopAllActions()
    self.Bad_Run:gotoFrameAndPlay(0, false)
    self.Bad:runAction(self.Bad_Run)
end

-- 播放对应的用户操作的动画事件
function Game3ViewLayer:beginMove_Effects(Win_Loser, Index)
    -- 用户操作失败以及成功
    if Win_Loser then
        -- 用户操作后的各种结果
        -- 播放完毕之后重新播放角色呼吸动作
        if Index == 1 then
            -- 播放Miss动画
            -- 进入大蛇攻击玩家帧动画
            -- 特效初始化
            --            local Miss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .."Game1_Terrace/Small/Specia_Effects/User_Operation/"  .. "X_1160_5.csb", self);
            --            self.Miss = Miss
            --            self.Miss_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .."Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_5.csb") -- 123123 播放排行特效
            --            ExternalFun.SAFE_RETAIN(self.Miss_Run )
            --            local a = function (frame)
            --                 if nil == frame then
            --                    return
            --                 end
            --                 self:ShowEffects(self.BtnAnXia)
            --                 -- 玩家死亡播放完动画此处退出小游戏  hz@1
            --                 -- 清空血槽
            --            end
            --            self.Miss_Run:setFrameEventCallFunc(a)  --动画的使用事件
            --            self.Miss:stopAllActions()
            --            self.Miss_Run:gotoFrameAndPlay(0, false)
            --            self.Miss:runAction(self.Miss_Run )
        elseif Index == 2 then
            -- Bad 动画
            self:DianZhong_And_MeiDianZhong("X_1160.csb")

            local bad = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_4.csb", self);
            self.Bad = bad
            self.Bad_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_4.csb")
            -- 123123 播放排行特效
            ExternalFun.SAFE_RETAIN(self.Bad_Run)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                self:ShowEffects(self.BtnAnXia)

            end
            self.Bad_Run:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Bad:stopAllActions()
            self.Bad_Run:gotoFrameAndPlay(0, false)
            self.Bad:runAction(self.Bad_Run)

        elseif Index == 3 then
            -- Good 动画
            self:DianZhong_And_MeiDianZhong("X_1160.csb")

            local good = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_3.csb", self);
            self.Good = good
            self.Good_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_3.csb")
            -- 123123 播放排行特效
            ExternalFun.SAFE_RETAIN(self.Good_Run)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                self:ShowEffects(self.BtnAnXia)
            end
            self.Good_Run:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Good:stopAllActions()
            self.Good_Run:gotoFrameAndPlay(0, false)
            self.Good:runAction(self.Good_Run)

        elseif Index == 4 then
            -- perfect 动画
            self:DianZhong_And_MeiDianZhong("X_1160.csb")
            local perfect = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_3.csb", self);
            self.Perfect = perfect
            self.Perfect_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_3.csb")
            -- 123123 播放排行特效
            ExternalFun.SAFE_RETAIN(self.Perfect_Run)
            local Incident = function(frame)
                if nil == frame then
                    return
                end
                self:ShowEffects(self.BtnAnXia)
            end
            self.Perfect_Run:setFrameEventCallFunc(Incident)
            -- 动画的使用事件
            self.Perfect:stopAllActions()
            self.Perfect_Run:gotoFrameAndPlay(0, false)
            self.Perfect:runAction(self.Perfect_Run)
        end
    else

        -- 播放Miss动画
        self:DianZhong_And_MeiDianZhong("X_1160_1.csb")
        -- 进入大蛇攻击玩家帧动画
        -- 特效初始化
        local Miss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_5.csb", self);
        self.Miss = Miss
        self.Miss_Run = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Specia_Effects/User_Operation/" .. "X_1160_5.csb")
        -- 123123 播放排行特效
        ExternalFun.SAFE_RETAIN(self.Miss_Run)
        local Incident = function(frame)
            if nil == frame then
                return
            end
            self:ShowEffects(7)
            -- 玩家死亡播放完动画此处退出小游戏  hz@1
            -- 清空血槽
        end
        self.Miss_Run:setFrameEventCallFunc(Incident)
        -- 动画的使用事件
        self.Miss:stopAllActions()
        self.Miss_Run:gotoFrameAndPlay(0, false)
        self.Miss:runAction(self.Miss_Run)
    end
end

-- 对应下标状态播放对应的动画
function Game3ViewLayer:ShowEffects(Index)
    if Index == 1 then
        self:Run_DaTing_JueSe(Index)
    elseif Index == 2 then
        self:Run_DaTing_JueSe(Index)
    elseif Index == 3 then
        self:Run_DaTing_JueSe(Index)
    elseif Index == 4 then
        self:Run_DaTing_JueSe(Index)
    elseif Index == 5 then
        self:Run_DaTing_JueSe(Index)
    elseif Index == 6 then
        self:Run_DaTing_JueSe(Index)
    elseif Index == 7 then
        -- Miss产生的动画播放效果 ： 播放完毕之后结束小游戏
        self:Run_DaTing_JueSe(7)
    end
end

-- 更换能量体图片的转换
function Game3ViewLayer:NengLiangKuaiHanShu(Bool)
    if Bool then
        for i = 1, 6 do
            self.NengLiangKuai[i]:setTexture("Game1_Terrace/Small/View/anger/11732.png")
        end
        self.NengLiangKuaiQieHuan = not self.NengLiangKuaiQieHuan
    else
        for i = 1, 6 do
            self.NengLiangKuai[i]:setTexture("Game1_Terrace/Small/View/anger/11731.png")
        end
        self.NengLiangKuaiQieHuan = not self.NengLiangKuaiQieHuan
    end
end
 
function Game3ViewLayer:Move_QiuTi()

    -- 移动球体
    if self._czJiePaiQi:getPositionX() ~= 850 and self._czJiePaiQi:getPositionX() ~= self._Globe and Run_QiuTi then
        local Speed = 2

        if self.BtnAnXia == 2 then
            Speed = 4
        elseif self.BtnAnXia == 3 then
            Speed = 6
        elseif self.BtnAnXia == 4 then
            Speed = 8
        elseif self.BtnAnXia == 5 then
            Speed = 10
        end

        local Pos = self._czJiePaiQi:getPositionX() + Speed
        self._czJiePaiQi:setPositionX(Pos)
    end

    -- 更换能量图片的展示
    self._csbNode:runAction(
    cc.Sequence:create(
    cc.DelayTime:create(2),
    cc.CallFunc:create( function()
        if not self.NengLiangKuaiQieHuan then
            self:NengLiangKuaiHanShu(true)
        else
            self:NengLiangKuaiHanShu(false)
        end
    end )
    )
    )


    if self._czJiePaiQi:getPositionX() >= 850 then
        -- 播放对应文字动画效果
        -- 如果根据次数播放不同的动画时间 区分为第一次以及后面的次数
        -- 如果是后面几次出现没有操作成功则播放大蛇攻击玩家动画，玩家死亡退出小游戏

        -- 停止定时器
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
        -- 测试数据
        self._czJiePaiQi:setPosition(491, 323)
        self._czJiePaiQi:setVisible(false)
        self._Globe = 0
        self.Btn:setVisible(false)
        self:Show_YinChang(false)
        self._czEffects_BaiShen:setVisible(false)
        self._scene:SeedDataGame3(0)
        -- 发送对应的数据

        if self.BtnAnXia == 1 then
            self.BtnAnXia = self.BtnAnXia + 1
            self:beginMove_Effects(true, 2)
        else
            self:beginMove_Effects(false, 1)
        end



    elseif self._czJiePaiQi:getPositionX() == self._Globe then
        -- - 5 and self._czJiePaiQi:getPositionX() <= self._Globe + 5
        -- 玩家操作：
        -- 1： 获得玩家操作之后球体停止的位置
        local Pos = self._czJiePaiQi:getPositionX()
        -- 2： 根据球体停止位置判定是否为中奖区域
        if Pos <= 739 and Pos >= 719 then
            -- 左边缘
            self._scene:SeedDataGame3(1)
            -- 发送对应的数据
            self:beginMove_Effects(true, 2)
            -- 3： 对应中奖区域，播放对应的动画
        elseif Pos <= 750 and Pos >= 739 then
            -- 左中间
            self._scene:SeedDataGame3(3)
            -- 发送对应的数据
            self:beginMove_Effects(true, 3)
        elseif Pos <= 760 and Pos >= 750 then
            -- 中间大奖
            self._scene:SeedDataGame3(5)
            -- 发送对应的数据
            self:beginMove_Effects(true, 4)
        elseif Pos <= 770 and Pos >= 760 then
            -- 右中间
            self._scene:SeedDataGame3(4)
            -- 发送对应的数据
            self:beginMove_Effects(true, 3)
        elseif Pos <= 782 and Pos >= 770 then
            -- 右边缘
            self._scene:SeedDataGame3(2)
            -- 发送对应的数据
            self:beginMove_Effects(true, 2)
        elseif Pos <= 719 or Pos >= 782 then
            -- 不沾边
            self._scene:SeedDataGame3(0)
            -- 发送对应的数据
            if self.BtnAnXia == 1 then
                self:beginMove_Effects(true, 2)

            else
                self:beginMove_Effects(false, 1)
            end
        end
        --          -- 重新设置球体滚动
        self._czJiePaiQi:setPosition(491, 323)
        self._czJiePaiQi:setVisible(false)
        self._Globe = 0
        Run_QiuTi = false
    end



end
-- 传送玩家操作球体移动的变量
--[[
   球体移动区域判定：
   0：不沾边
   1：左边缘
   2：右边缘
   3：左中间
   4：右中间
   5：中间大奖
]]
-- function Game3ViewLayer:SeedData(SeedData)
--     -- 创建字节数量
--     local  dataBuffer= CCmd_Data:create(1)  -- CMD_C_TRHEE_SMALL_OK
--     dataBuffer:pushbyte(SeedData)
--     self._scene:SendData(g_var(cmd).CMD_C_TRHEE_SMALL_OK, dataBuffer)
-- end 

 
Game3ViewLayer.Btn = 1050
-- 控制节拍器球体运动终点 设置按钮事件
function Game3ViewLayer:initUI()

    local function btnEvent(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(sender:getTag(), sender)
        end
    end
    -- 节拍器按钮
    self.Btn = self._csbNode:getChildByName("Button_1")
    self.Btn:setVisible(false)

    self.Btn:setTag(Game3ViewLayer.Btn)
    self.Btn:addTouchEventListener(btnEvent);
end

function Game3ViewLayer:onButtonClickedEvent(touch, event)

    print("按下节拍器次数：" .. self.BtnAnXia)

    if touch == Game3ViewLayer.Btn then
        -- 停止定时器
        if self.schedulerID ~= 2 then
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
        end
        -- 按钮按下时音效
        ExternalFun.playSoundEffect("QHLHJ_90031(jiepaiqidianji).wav")

        self.Btn:setVisible(false)
        self:Show_YinChang(false)

        -- 当按钮按下让按钮没有操作的动画消失
        self._czEffects_BaiShen:setVisible(false)
        -- 播放没有按下按钮的动画
        local Boss = ExternalFun.loadCSB(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Btn/" .. "XT_1166_1.csb", self);
        self._czAnXia = Boss
        self._czAnXia_actAni12 = ExternalFun.loadTimeLine(GameViewLayer.RES_PATH .. "Game1_Terrace/Small/Btn/" .. "XT_1166_1.csb")
        ExternalFun.SAFE_RETAIN(self._czAnXia_actAni12)
        local Incident = function(frame)
            if nil == frame then
                return
            end

        end
        self._czAnXia_actAni12:setFrameEventCallFunc(Incident)
        -- 动画的使用事件
        self._czAnXia:stopAllActions()
        self._czAnXia_actAni12:gotoFrameAndPlay(0, false)
        -- 设置是否循环播放
        self._czAnXia:runAction(self._czAnXia_actAni12)

        -- 获得用户操作球体停止位置坐标
        self._Globe = self._czJiePaiQi:getPositionX()
        -- 此处判定球体坐标以及发送球体停止时间协议包
        self:Move_QiuTi()

        self.BtnAnXia = self.BtnAnXia + 1
        -- 按一次记录一次事件

    end
end
  
-- 改变分数
function Game3ViewLayer:showPrize(lScore)
    self.m_textGetScore:setString(tonumber(self.m_textGetScore:getString()) + lScore)
end
 

function Game3ViewLayer:backOneGame()

    ij = 1
    Run_QiuTi = true


    -- 切换回第一个游戏
    local gameview = self._scene._gameView
    gameview:setPosition(0, 0)
    gameview:setVisible(true)

    -- 声音
    ExternalFun.playBackgroudAudio("QUANHUANG.mp3")
    Countdown_.remove_scheduler()
    -- 停止定时器
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)

    self._scene:setGameMode(5)
    -- GAME_STATE_WAITTING


    self._scene:sendThreeEnd()-- 结束小游戏

    if gameview._scene.m_bNumber_of_Free > 0 then
        -- 如果免费游戏还有次数，那么退出小游戏就切换回免费游戏状态
         
            gameview.Button_Start:loadTextureNormal("Game1_Terrace/Button/BeginGame2.png")
            -- XiaoYouXiJiBI = self._All_Win_Meney
            gameview.MianFeiJinBiZhi = gameview.MianFeiJinBiZhi + self._All_Win_Meney
            gameview:SetNumber_And_Meney(3, gameview.MianFeiJinBiZhi)
            gameview:Button_Gray(false)
            gameview._scene:sendReadyMsgFree()
            self:removeFromParent()
             

    elseif gameview._scene.m_bIsAuto == true then
     
            -- 如果是自动游戏进入
            if self._All_Win_Meney > 0 then
                gameview.m_textScore = self._scene.m_lCoins + self._All_Win_Meney
                self._scene.m_lCoins = gameview.m_textScore
                gameview._scene:GetMeUserItem().lScore = gameview.m_textScore

                print("当前玩家金币数量：》》》》》》》》》》》》gameview._scene:GetMeUserItem().lScore" .. gameview._scene:GetMeUserItem().lScore)
                print("当前玩家金币数量：》》》》》》》》》》》》gameview.m_textScore" .. gameview.m_textScore)

                -- 更新玩家赢得金币
                gameview:SetNumber_And_Meney(1, gameview.m_textScore)
            end
            gameview.Button_Start:loadTextureNormal("Game1_Terrace/Button/BeginGame2.png")
            gameview:Button_Gray(false)
            gameview.Button_Start:setTouchEnabled(false)
            gameview.Button_Start:setBright(false) 
            self._scene:sendEndGame1Msg()
            self:removeFromParent()
            gameview._scene.m_cbGameStatus = g_var(cmd).SHZ_GAME_SCENE_FREE 

        
    elseif gameview._scene.MianFeiGame_End then
        -- 如果是免费游戏最后一次触发小游戏状态，那么切换回去主游戏界面时播放免费游戏结算动画
        gameview._scene:GetMeUserItem().lScore = gameview.m_textScore
        XiaoYouXiJiBI = self._All_Win_Meney
        gameview.Button_Start:loadTextureNormal("Game1_Terrace/Button/BeginGame1.png")
        gameview.Button_Start:setTouchEnabled(true)
        gameview.Button_Start:setBright(true)
        gameview:Button_Gray(true)
        gameview:Show_Free_View()
        self:removeFromParent()
    else
        if self._All_Win_Meney > 0 then
            gameview.m_textScore = self._scene.m_lCoins + self._All_Win_Meney
            self._scene.m_lCoins = gameview.m_textScore
            gameview._scene:GetMeUserItem().lScore = gameview.m_textScore
            -- 更新玩家赢得金币
            gameview:SetNumber_And_Meney(1, gameview.m_textScore)
        end
        gameview.Button_Start:loadTextureNormal("Game1_Terrace/Button/BeginGame1.png")
        gameview.Button_Start:setTouchEnabled(true)
        gameview.Button_Start:setBright(true)
        gameview:Button_Gray(true)
        gameview.XXOOSHOWDONGHUA = true
        self._scene:sendEndGame1Msg()
        self:removeFromParent()
    end
end

 
return GameViewLayer 