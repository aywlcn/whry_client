--
-- Author: luo
-- Date: 2016年12月30日 17:46:35
-- 预加载资源
local PreLoading = {}
local module_pre ="game.yule.97quanhuang.src"
local res_path =  "game/yule/97quanhuang/res/"
local cmd = module_pre .. ".models.CMD_Game"
local ExternalFun = require(appdf.EXTERNAL_SRC.."ExternalFun")
local g_var = ExternalFun.req_var
PreLoading.bLoadingFinish = false
PreLoading.loadingPer = 100
PreLoading.bFishData = false

function PreLoading.resetData()
	PreLoading.bLoadingFinish = false
	PreLoading.loadingPer = 50
	PreLoading.bFishData = false
end

function PreLoading.StopAnim(bRemove)
	local scene = cc.Director:getInstance():getRunningScene()
	local layer = scene:getChildByTag(2000) 

	if not layer  then
		return
	end

	if not bRemove then
		-- if nil ~= PreLoading.fish then
		-- 	PreLoading.fish:stopAllActions()
		-- end
	else
	
		layer:stopAllActions()
		layer:removeFromParent()
	end
end

function PreLoading.loadTextures()
	local m_nImageOffset = 0

	local totalSource = 1 

	local plists = {
                    "Game1_Terrace/Avatar_Animation/SHOWBEGIN.plist"                     ,  
                    "Game1_Terrace/ICON/QHICON.plist"                                    , 
                    
				    "Game1_Terrace/Avatar_Animation/QH_CAOBAOJIAN.plist"                 , 
                    "Game1_Terrace/Avatar_Animation/QH_DIANNAN.plist"                    ,
                    "Game1_Terrace/Avatar_Animation/QH_DAMEN.plist"                      ,
                    "Game1_Terrace/Avatar_Animation/QH_KARUI.plist"                      ,
                    "Game1_Terrace/Avatar_Animation/QH_HUOWU.plist"                      ,
                    "Game1_Terrace/Avatar_Animation/QH_CAOTIJI.plist"                    ,
                    "Game1_Terrace/Avatar_Animation/QH_CHENGUOHAN.plist"                 ,
                    "Game1_Terrace/Avatar_Animation/QH_KALEKE.plist"                     ,  
                    "Game1_Terrace/ICON/game1_itemJump.plist"                            ,
                    "Game1_Terrace/Specia_Effects/GunDongTeXiao/XT_1120_1.plist"         ,                                     -- 加速特效 
                    "Game1_Terrace/Specia_Effects/BeiShu/XT_11111.plist"                 ,   
                    "Game1_Terrace/Specia_Effects/BeiShu/XT_11111_1.plist"               ,   
                    "Game1_Terrace/Specia_Effects/BeiShu/XT_11111_2.plist"               ,                                    -- 倍数特效 
                    "Game1_Terrace/Specia_Effects/BaiShen/XT_1130_2.plist"               , 
                    "Game1_Terrace/Specia_Effects/JunNV/XT_1140_2.plist"                 ,  
                    "Game1_Terrace/Specia_Effects/TaiYangShen/XT_1150_2.plist"           ,
                    "Game1_Terrace/Specia_Effects/TaiYangShen/XT_1150_3.plist"           ,                                   -- 特殊图标特效 
                    "Game1_Terrace/Specia_Effects/Small_Game_Effects/XT-1163.plist"      ,
                    "Game1_Terrace/Specia_Effects/Small_Game_Effects/XT_1166.plist"      ,  
                    "Plist/Dai_Ji.plist"                                                 ,  
                    "Plist/BJB75.plist"                                                  ,   
                    "Plist/BZN75.plist"                                                  ,   
                    "Plist/QH_CBS75.plist"                                               ,   
                    --"Plist/CBS.plist"                                                    ,   
                    "Plist/YGPZ75.plist"                                                 ,     
                    "Plist/KUIHUA.plist"                                                 ,     
                    "Plist/QH_QYY.plist"                                                 ,     
 --                   "Plist/QYY.plist"                                                    ,      
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/X_1160.plist"     ,                               --小游戏按钮按下状态特效  
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/quang_huang_TX_1111_2.plist"     ,                              
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/quan_huang_1190.plist"     ,                              
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/quan_huang_TX_1164_3.plist"     ,                                 
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/XT_1111_1.plist"     ,                              
                    "Game1_Terrace/Small/Btn/XT_1166.plist"                              ,                               --小游戏按钮按下状态特效      quang_huang_TX_1111_2
                                                                                                                    --加载拳皇头像动画帧
																													
				   }

	local function imageLoaded(texture)--texture
		
        m_nImageOffset = m_nImageOffset + 1
		print("m_nImageOffset",m_nImageOffset)
		print("totalSource",totalSource)	
        if m_nImageOffset == totalSource then
        	
        	--加载PLIST
        	for i=1,#plists do
        		cc.SpriteFrameCache:getInstance():addSpriteFrames(res_path..plists[i])

        		local dict = cc.FileUtils:getInstance():getValueMapFromFile(res_path..plists[i])
        		local framesDict = dict["frames"]
				if nil ~= framesDict and type(framesDict) == "table" then
					for k,v in pairs(framesDict) do
						local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
						if nil ~= frame then
							frame:retain()
						end
					end
				end
        	end

        	PreLoading.readAniams()
        	PreLoading.bLoadingFinish = true

			--通知
			local event = cc.EventCustom:new(g_var(cmd).Event_LoadingFinish)
			print("发布监听通知",event)
			dump(event)
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

			PreLoading.Finish()

			if PreLoading.bFishData  then
				PreLoading.bFishData = false
				local scene = cc.Director:getInstance():getRunningScene()
				local layer = scene:getChildByTag(2000) 
				if not layer  then
					return
				end
				PreLoading.loadingPer = 100
				PreLoading.updatePercent(PreLoading.loadingPer)

				local callfunc1 = cc.CallFunc:create(function()
					PreLoading.loadingBG:loadTexture(res_path.."loading/preBg_11.png")
				end)
				local callfunc2 = cc.CallFunc:create(function()
					PreLoading.loadingBG:loadTexture(res_path.."loading/preBg_11.png")
				end)
				local callfunc3 = cc.CallFunc:create(function()
					PreLoading.loadingBG:loadTexture(res_path.."loading/preBg_11.png")
				end)
				local callfunc4 = cc.CallFunc:create(function()
					PreLoading.loadingBar:stopAllActions()
					PreLoading.loadingBar = nil
					layer:stopAllActions()
					layer:removeFromParent()
                    PreLoading.Run_Begin_Game()
				end)
				layer:stopAllActions()
				layer:runAction(cc.Sequence:create(callfunc1,cc.DelayTime:create(0.8),callfunc2,cc.DelayTime:create(0.8),callfunc3,cc.DelayTime:create(0.8),callfunc4))
			end
        	print("资源加载完成")
           
        end
    end
    local function 	loadImages()
    	cc.Director:getInstance():getTextureCache():addImageAsync(res_path.."Game1_Terrace/ICON/game1_itemCommon.png", imageLoaded)
    end
    local function createSchedule( )
    	local function update( dt )
			PreLoading.updatePercent(PreLoading.loadingPer)
		end
		local scheduler = cc.Director:getInstance():getScheduler()
		PreLoading.m_scheduleUpdate = scheduler:scheduleScriptFunc(update, 0, false)
    end
	--进度条
	PreLoading.GameLoadingView()

	loadImages()
	--createSchedule()
	--PreLoading.addEvent()
end


function PreLoading.Run_Begin_Game()
    local scene = cc.Director:getInstance():getRunningScene()
    local layer = scene:getChildByTag(2000) 
    local layer = display.newLayer()
	layer:setTag(2000)
	scene:addChild(layer,30)
     -- 特殊图标动画
     PreLoading.FatherBiZhi = cc.Sprite:create("Game1_Terrace/Small/blank.png")
     PreLoading.FatherBiZhi:setPosition(230,135)
     PreLoading.FatherBiZhi:setAnchorPoint(0,0)
     layer:addChild(PreLoading.FatherBiZhi,0)
      
       
    local strAnimePath = 
    {
        --"Show_%02d.png" 
        "QHSHOW_%02d.png"
    }

    local animation = cc.Animation:create()
     
    for i=1,22 do
		local frameName = string.format(strAnimePath[1],i) 
		print (frameName)
        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)  
		animation:addSpriteFrame(spriteFrame)
	end  
     
	animation:setDelayPerUnit(0.1)          --设置两个帧播放时间                   
	animation:setRestoreOriginalFrame(false)    --动画执行后还原初始状态     

	local action = cc.Animate:create(animation)
	local seq =   cc.Sequence:create(
		    action,
		    cc.CallFunc:create(function (  )
			        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format(strAnimePath[1],2))  
                    PreLoading.FatherBiZhi:setSpriteFrame(frame) 
		    end)
	    )

	    PreLoading.FatherBiZhi:runAction(action) -- 目前开启了一直重复播放呼吸动画， 使用stopAllActions()暂停播放
        --音效
        ExternalFun.playBackgroudAudio("QHLHJ_ditu.wav")
end


function PreLoading.unloadTextures( )

	local plists = {
					"Game1_Terrace/Avatar_Animation/SHOWBEGIN.plist"                     ,  
                    "Game1_Terrace/ICON/QHICON.plist"                                    , 
                    
				    "Game1_Terrace/Avatar_Animation/QH_CAOBAOJIAN.plist"                 , 
                    "Game1_Terrace/Avatar_Animation/QH_DIANNAN.plist"                    ,
                    "Game1_Terrace/Avatar_Animation/QH_DAMEN.plist"                      ,
                    "Game1_Terrace/Avatar_Animation/QH_KARUI.plist"                      ,
                    "Game1_Terrace/Avatar_Animation/QH_HUOWU.plist"                      ,
                    "Game1_Terrace/Avatar_Animation/QH_CAOTIJI.plist"                    ,
                    "Game1_Terrace/Avatar_Animation/QH_CHENGUOHAN.plist"                 ,
                    "Game1_Terrace/Avatar_Animation/QH_KALEKE.plist"                     ,  
                    "Game1_Terrace/ICON/game1_itemJump.plist"                            ,
                    "Game1_Terrace/Specia_Effects/GunDongTeXiao/XT_1120_1.plist"         ,                                     -- 加速特效 
                    "Game1_Terrace/Specia_Effects/BeiShu/XT_11111.plist"                 ,   
                    "Game1_Terrace/Specia_Effects/BeiShu/XT_11111_1.plist"               ,   
                    "Game1_Terrace/Specia_Effects/BeiShu/XT_11111_2.plist"               ,                                    -- 倍数特效 
                    "Game1_Terrace/Specia_Effects/BaiShen/XT_1130_2.plist"               , 
                    "Game1_Terrace/Specia_Effects/JunNV/XT_1140_2.plist"                 ,  
                    "Game1_Terrace/Specia_Effects/TaiYangShen/XT_1150_2.plist"           ,
                    "Game1_Terrace/Specia_Effects/TaiYangShen/XT_1150_3.plist"           ,                                   -- 特殊图标特效 
                    "Game1_Terrace/Specia_Effects/Small_Game_Effects/XT-1163.plist"      ,
                    "Game1_Terrace/Specia_Effects/Small_Game_Effects/XT_1166.plist"      ,  
                    "Plist/Dai_Ji.plist"                                                 ,  
                    "Plist/BJB75.plist"                                                  ,   
                    "Plist/BZN75.plist"                                                  ,   
                    "Plist/CBS75.plist"                                                  ,   
                    "Plist/YGPZ75.plist"                                                 ,     
                    "Plist/KUIHUA.plist"                                                 ,     
                    "Plist/QYY.plist"                                                    ,      
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/X_1160.plist"     ,                               --小游戏按钮按下状态特效  
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/quang_huang_TX_1111_2.plist"     ,                              
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/quan_huang_1190.plist"     ,                              
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/quan_huang_TX_1164_3.plist"     ,                                 
                    "Game1_Terrace/Small/Specia_Effects/User_Operation/XT_1111_1.plist"     ,                              
                    "Game1_Terrace/Small/Btn/XT_1166.plist"                              ,                               --小游戏按钮按下状态特效      quang_huang_TX_1111_2
                                                                                                                    --加载拳皇头像动画帧
																													
				   }

	for i=1,#plists do
		local dict = cc.FileUtils:getInstance():getValueMapFromFile(res_path..plists[i]) 
		local framesDict = dict["frames"]
		if nil ~= framesDict and type(framesDict) == "table" then
			for k,v in pairs(framesDict) do
				local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(k)
				if nil ~= frame then
					frame:release()
				end
			end
		end
        if plists[i] == nil then
            local a = 1 
        end
		cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(res_path..plists[i])
	end

	--cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(res_path .. "game1/gameAction/dagu.plist")
    --cc.Director:getInstance():getTextureCache():removeTextureForKey("gameAction/dagu.png.png")
    
 	cc.Director:getInstance():getTextureCache():removeTextureForKey(res_path.."Game1_Terrace/ICON/game1_itemCommon.png")

    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end

-- function PreLoading.addEvent()
--    --通知监听
--   local function eventListener(event)
--   	cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners(g_var(cmd).Event_LoadingFinish)
-- 	PreLoading.Finish()
--   end
--   local listener = cc.EventListenerCustom:create(g_var(cmd).Event_LoadingFinish, eventListener)
--   cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)
-- end

function PreLoading.Finish()
	PreLoading.bFishData = true
	if  PreLoading.bLoadingFinish then
		local scene = cc.Director:getInstance():getRunningScene()
		local layer = scene:getChildByTag(2000) 
		if nil ~= layer then
			local callfunc = cc.CallFunc:create(function()
				PreLoading.loadingBar:stopAllActions()
				PreLoading.loadingBar = nil
				layer:stopAllActions()
				layer:removeFromParent()
			end)
			layer:stopAllActions()
			layer:runAction(cc.Sequence:create(cc.DelayTime:create(3.3),callfunc))
		end
	end
end

function PreLoading.GameLoadingView()
	local scene = cc.Director:getInstance():getRunningScene()
	local layer = display.newLayer()
	layer:setTag(2000)
	scene:addChild(layer,30)

	PreLoading.loadingBG = ccui.ImageView:create(res_path.."loading/preBg_11.png")
	PreLoading.loadingBG:setTag(1)
	PreLoading.loadingBG:setTouchEnabled(true)
	PreLoading.loadingBG:setPosition(cc.p(yl.WIDTH/2,yl.HEIGHT/2))
	layer:addChild(PreLoading.loadingBG)

	local loadingBarBG = ccui.ImageView:create(res_path.."loading/progress_bar_bg.png")
	loadingBarBG:setTag(2)
	loadingBarBG:setPosition(cc.p(yl.WIDTH/2,12))
	layer:addChild(loadingBarBG)

	PreLoading.loadingBar = cc.ProgressTimer:create(cc.Sprite:create(res_path.."loading/progress_bar.png"))
	PreLoading.loadingBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
	PreLoading.loadingBar:setMidpoint(cc.p(0.0,0.5))
	PreLoading.loadingBar:setBarChangeRate(cc.p(1,0))
    PreLoading.loadingBar:setPosition(cc.p(loadingBarBG:getContentSize().width/2,loadingBarBG:getContentSize().height/2))
    PreLoading.loadingBar:runAction(cc.ProgressTo:create(0.2,20))
    loadingBarBG:addChild(PreLoading.loadingBar)
end

function PreLoading.updatePercent(percent )
	if nil ~= PreLoading.loadingBar then
		local dt = 1.0
		if percent == 100 then
			dt = 2.0
		end
		PreLoading.loadingBar:runAction(cc.ProgressTo:create(dt,percent))
	end

	if PreLoading.bLoadingFinish  then
		if nil ~= PreLoading.m_scheduleUpdate then
    		local scheduler = cc.Director:getInstance():getScheduler()
			scheduler:unscheduleScriptEntry(PreLoading.m_scheduleUpdate)
			PreLoading.m_scheduleUpdate = nil
		end
	end
end

--[[
@function : readAnimation
@file : 资源文件
@key  : 动作 key
@num  : 幀数
@time : float time 
@formatBit 
]]
function PreLoading.readAnimation(file, key, num, time,formatBit)
   	local animation =cc.Animation:create()
	for i=1,num do
		local frameName
		if formatBit == 1 then
			frameName = string.format(file.."%d.png", i)
		elseif formatBit == 2 then
		 	frameName = string.format(file.."%02d.png", i)
		end
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
		animation:addSpriteFrame(frame)
	end
	animation:setDelayPerUnit(time)
   	cc.AnimationCache:getInstance():addAnimation(animation, key)
end

function PreLoading.readAniByFileName( file,width,height,rownum,linenum,savename)
	local frames = {}
	for i=1,rownum do
		for j=1,linenum do
			local frame = cc.SpriteFrame:create(file,cc.rect(width*(j-1),height*(i-1),width,height))
			table.insert(frames, frame)
		end
	end
	local  animation =cc.Animation:createWithSpriteFrames(frames,0.03)
   	cc.AnimationCache:getInstance():addAnimation(animation, savename)
end

function PreLoading.removeAllActions()
--    cc.AnimationCache:getInstance():removeAnimation("daguAnim")
--    cc.AnimationCache:getInstance():removeAnimation("titleAnim")
--    cc.AnimationCache:getInstance():removeAnimation("wYaoqiAnim")
--    cc.AnimationCache:getInstance():removeAnimation("rYaoqiAnim")
--    cc.AnimationCache:getInstance():removeAnimation("flashAnim")

--    cc.AnimationCache:getInstance():removeAnimation("game1BoxAnim")
--    cc.AnimationCache:getInstance():removeAnimation("lightAnim")

--    cc.AnimationCache:getInstance():removeAnimation("dealerComAnim")
--    cc.AnimationCache:getInstance():removeAnimation("leftComAnim")
--    cc.AnimationCache:getInstance():removeAnimation("rightComAnim")
--    cc.AnimationCache:getInstance():removeAnimation("deskAnim")
--    cc.AnimationCache:getInstance():removeAnimation("goldAnim")

--    cc.AnimationCache:getInstance():removeAnimation("dealerDiceAnim")
--    cc.AnimationCache:getInstance():removeAnimation("leftCheerAnim")
--    cc.AnimationCache:getInstance():removeAnimation("rightCheerAnim")

--    cc.AnimationCache:getInstance():removeAnimation("dealerOpenAnim")
--    cc.AnimationCache:getInstance():removeAnimation("dealerAngerAnim")
--    cc.AnimationCache:getInstance():removeAnimation("dealerHappyAnim")

--    cc.AnimationCache:getInstance():removeAnimation("leftHappyAnim")
--    cc.AnimationCache:getInstance():removeAnimation("leftCryAnim")
--    cc.AnimationCache:getInstance():removeAnimation("rightHappyAnim")
--    cc.AnimationCache:getInstance():removeAnimation("rightCryAnim")
end

function PreLoading.readAniams()
-- 	--game1
--    PreLoading.readAnimation("action_dagu_", "daguAnim", g_var(cmd).ACT_DAGU_NUM,0.1,2);
--    PreLoading.readAnimation("action_title_", "titleAnim", g_var(cmd).ACT_TITLE_NUM,0.3,2);
-- 	PreLoading.readAnimation("action_wyaoqi_", "wYaoqiAnim", g_var(cmd).ACT_QIZHIWAIT_NUM,0.1,2);
--	PreLoading.readAnimation("action_ryaoqi_", "rYaoqiAnim", g_var(cmd).ACT_QIZHI_NUM,0.1,2);
--	PreLoading.readAnimation("game1_flash_", "flashAnim", 10,0.1,2);
--	PreLoading.readAnimation("game1_box_", "game1BoxAnim",6,0.1,1);
--	PreLoading.readAnimation("common_light_", "lightAnim",9,0.1,2);
--	--game2
--	PreLoading.readAnimation("dealer_common_0","dealerComAnim",8,0.1,1);
--	PreLoading.readAnimation("left_common_", "leftComAnim",27,0.1,2);
--	PreLoading.readAnimation("right_common_", "rightComAnim",25,0.5,2);
--	PreLoading.readAnimation("desk_", "deskAnim",5,0.1,1);
--	PreLoading.readAnimation("game2_Gold_", "goldAnim",4,0.1,1);

--	PreLoading.readAnimation("dealer_dice_", "dealerDiceAnim",29,0.1,2);
--	PreLoading.readAnimation("left_cheer_", "leftCheerAnim",29,0.1,2);
--	PreLoading.readAnimation("right_cheer_", "rightCheerAnim",29,0.1,2);
--	PreLoading.readAnimation("desk_", "deskAnim",5,0.1,1);
--	PreLoading.readAnimation("game2_Gold_", "goldAnim",4,0.1,1);

--	PreLoading.readAnimation("dealer_open_", "dealerOpenAnim",14,0.1,2);
--	PreLoading.readAnimation("dealer_anger_", "dealerAngerAnim",25,0.1,2);
--	PreLoading.readAnimation("dealer_happy_0", "dealerHappyAnim",7,0.3,1);

--	PreLoading.readAnimation("left_happy_", "leftHappyAnim",55,0.1,2);
--	PreLoading.readAnimation("left_cry_", "leftCryAnim",36,0.1,2);

--	PreLoading.readAnimation("right_happy_", "rightHappyAnim",18,0.1,2);
--	PreLoading.readAnimation("right_cry_", "rightCryAnim",26,0.1,2);
end

return PreLoading