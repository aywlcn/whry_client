local ExternalFun = require(appdf.EXTERNAL_SRC .. "ExternalFun")

local cmd = "game.yule.97quanhuang.src.models.CMD_Game"

local emItemState = 
{
	"STATE_NORMAL",		--正常
	"STATE_SELECT",		--中奖
	"STATE_GREY"		--变灰
}
local ITEM_STATE = ExternalFun.declarEnumWithTable(0, emItemState);

local GameItem = class("GameItem",cc.ClippingRectangleNode)


--序列帧个数
GameItem.ACT_DADAO_NUM 					=   75    -- HuoJJ		
GameItem.ACT_LU_NUM						=   75    -- WuJJ		    
GameItem.ACT_YINQIANG_NUM				=   75    -- DaJJ		   
GameItem.ACT_FUTOU_NUM					=   75    -- JunJJ
GameItem.ACT_TITIANXINGDAO_NUM 			=   75    -- PangJJ		
GameItem.ACT_SONG_NUM					=   75    -- DianJJ		 说
GameItem.ACT_LIN_NUM					=   75    -- GangJJ		
GameItem.ACT_ZHONGYITANG_NUM			=   75    -- XiaoJJ	
--GameItem.ACT_SHUIHUZHUAN_NUM			=   57			--水浒传

GameItem.GAME_IMG_TAG = 100

function GameItem:ctor(  )

end
--初始化
function GameItem:created( nType )

	self.m_bIsEnd = false
	self.m_nType = -1
	self.m_pSprite = nil

	self:initNotice()
	self:setItemType(nType)
end

function GameItem:initNotice(  )
	self:setClippingRegion(cc.rect(0,0,210,149))
	self:setClippingEnabled(true)

end

function GameItem:setItemType( nType )
	self.m_nType = nType
end

function GameItem:getItemType( )
	return self.m_nType
end

-- 得到子类节点
function GameItem:getItemView( GameLayer)
	self.GameViewLayer = GameLayer
end


  

function GameItem:beginMove( deyTime , JiaSu_YanShi )
	if self.m_pSprite == nil then
		self.m_pSprite = cc.Sprite:create("common_MoveImg.png")
        self:addChild(self.m_pSprite,0)
	    self.m_pSprite:setPosition(cc.p(105,685))
	end  
    if  JiaSu_YanShi == 2 then 
               -- 停止滚动时间
	    self.m_pSprite:runAction(
		    cc.Sequence:create(
			    cc.DelayTime:create(deyTime), 
			    cc.CallFunc:create(function (  )
				    self:beginJump()  
			    end)
			    )
		    )
    else


	        local actMove = cc.RepeatForever:create(
		        cc.Sequence:create(
			        cc.MoveBy:create(num,cc.p(0,-1378)), -- 免费游戏小游戏滚动速度调节器 速度值为0.1 
			        cc.MoveTo:create(0.01,cc.p(105.5,689))
			        )
		        )
	        actMove:setTag(GameItem.GAME_IMG_TAG) 
	        self.m_pSprite:runAction(actMove)
              
            -- 停止滚动时间
	        self.m_pSprite:runAction(
		        cc.Sequence:create(
			        cc.DelayTime:create(deyTime), 
			        cc.CallFunc:create(function (  )
				        self:beginJump()  
			        end)
			        )
		        )
    end 
end

function GameItem:beginJump(  )
	if self.m_bIsEnd == true then
		return
	end
	local strPath = 
	{ 
		"Huo_0%d.png",
		"Wu_0%d.png", 
        "Da_0%d.png", 
        "Jun_0%d.png",
        "Pang_0%d.png",  
        "Dian_0%d.png",  
        "Gang_0%d.png",
        "Xiao_0%d.png",
        "BaiShen_0%d.png", 
		"Boss_0%d.png",
		"JunNv_0%d.png",
		
	} 
     
	if self.m_pSprite ~= nil then
		self.m_pSprite:stopAction(self.m_pSprite:getActionByTag(GameItem.GAME_IMG_TAG))
		local spriteFirstFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format(strPath[self.m_nType],1))  
		self.m_pSprite:setSpriteFrame(spriteFirstFrame)

		local animation =cc.Animation:create()
		for i=1,5 do
		    local frameName =string.format(strPath[self.m_nType],i)  

		    --print("frameName =%s",frameName)
		    local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
		   animation:addSpriteFrame(spriteFrame)
		end  
	   	animation:setDelayPerUnit(0.05)          --设置两个帧播放时间                   
	   	animation:setRestoreOriginalFrame(false)    --动画执行后还原初始状态    

	   	local action =cc.Animate:create(animation)   

	   	local seq = cc.Sequence:create(
	   		action,
	   		cc.CallFunc:create(function (  )
	   			self.m_bIsEnd = true
	   		end)
	   		)

	   	self.m_pSprite:runAction(seq)
	    self.m_pSprite:setAnchorPoint(0.5,0) 
        self.m_pSprite:setPosition(cc.p(self.m_pSprite:getContentSize().width/2 + 35 ,self.m_pSprite:getContentSize().height/2 - 72))
	end
end

function GameItem:stopAllItemAction(  )
	self.m_bIsEnd = true
	if self.m_pSprite ~= nil then
		self.m_pSprite:stopAllActions()
	else
		print("不存在这个GameItem")
	end
	self:setState(ITEM_STATE.STATE_NORMAL)

    self:beginJump()

	--self:stopAllActions()
end

function GameItem:stopAllItemActionSamll(  )
	self.m_bIsEnd = true
	if self.m_pSprite ~= nil then
		self.m_pSprite:stopAllActions()
	else
		print("不存在这个GameItem")
	end
	--self:setState(ITEM_STATE.STATE_NORMAL)
     
	--self:stopAllActions()
end


function GameItem:setState( nState)
	self.m_bIsEnd = true
	local strPath = 
	{
		"ICON_NUM_01.png",
		"ICON_NUM_02.png", 
        "ICON_NUM_03.png",  
		"ICON_NUM_04.png",
		"ICON_NUM_05.png",
		"ICON_NUM_06.png",
		"ICON_NUM_07.png",  
		"ICON_NUM_08.png", 
	}              
	local strAnimePath = 
	{              
        "CaoTiJing_%02d.png",
		"HuoWu_%02d.png",
		"KaRui_%02d.png", 
		"KELAKE_%02d.png", 
		"ChenGuoHan_%02d.png",
		"DianNan_%02d.png",
		"DaMen_%02d.png", 
        "XiaoJJ_%02d.png"
		--"action_shz_%02d.png",
	} 
     
    local strGrayness = 
	{
		"FREE_ICON_01.png",
        "FREE_ICON_02.png",
		"FREE_ICON_03.png",
        "FREE_ICON_04.png",
		"FREE_ICON_05.png",
		"FREE_ICON_06.png",
		"FREE_ICON_07.png",
		"FREE_ICON_08.png",
        "FREE_ICON_09.png",
        "FREE_ICON_10.png",
        "FREE_ICON_11.png"
		--"action_shz_%02d.png",
	} 
                                              
	--序列帧数目
	local nAnimeNum = 
	{
		GameItem.ACT_DADAO_NUM 			    ,
		GameItem.ACT_LU_NUM				    ,
		GameItem.ACT_YINQIANG_NUM		    ,
		GameItem.ACT_FUTOU_NUM			    ,
		GameItem.ACT_TITIANXINGDAO_NUM 	    ,
		GameItem.ACT_SONG_NUM			    ,
		GameItem.ACT_LIN_NUM			    ,
		GameItem.ACT_ZHONGYITANG_NUM	
		
	} 
	if nState == ITEM_STATE.STATE_NORMAL then
        if self.m_nType <= 8 then
		    --正常纹理
		    local frameName = strPath[self.m_nType]
		    --print(frameName)
		    --print(strPath[self.m_nType])
	        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
	        if self.m_pSprite then
            if spriteFrame == nil then 
                    local a = 1
                end
			    self.m_pSprite:setSpriteFrame(spriteFrame)
		    else
			    self.m_pSprite = cc.Sprite:create()
			    self.m_pSprite:setSpriteFrame(spriteFrame)
	        end
        else
             if self.m_nType == 9 then
                --print("更换图片：八神庵图片")
                local frameName = "ICON_NUM_09.png"
                local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
                if self.m_pSprite then
			        self.m_pSprite:setSpriteFrame(spriteFrame)
		        else
			        self.m_pSprite = cc.Sprite:create()
			        self.m_pSprite:setSpriteFrame(spriteFrame)
	            end
            elseif self.m_nType == 10 then
                --print("更换图片：太阳神图片") 
                local frameName = "ICON_NUM_10.png"
                local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
                if self.m_pSprite then
			        self.m_pSprite:setSpriteFrame(spriteFrame)
		        else
			        self.m_pSprite = cc.Sprite:create()
			        self.m_pSprite:setSpriteFrame(spriteFrame)
                end
            elseif self.m_nType == 11 then
                --print("更换图片：军娘图片") 
                local frameName = "ICON_NUM_11.png"
                local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName) 
                if self.m_pSprite then
			        self.m_pSprite:setSpriteFrame(spriteFrame)
		        else
			        self.m_pSprite = cc.Sprite:create()
			        self.m_pSprite:setSpriteFrame(spriteFrame)
                end
            end
        end

	elseif	nState == ITEM_STATE.STATE_SELECT then
		--播放序列帧动画 
       if self.m_nType <= 8 then
		    local animation = cc.Animation:create()
		    for i=1,nAnimeNum[self.m_nType] do
		        local frameName = string.format(strAnimePath[self.m_nType],i) 
		        --print("frameName =%s",frameName .. "    播放动画帧数的所属图片")
		        local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)

                if spriteFrame == nil then 
                    local a = 1
                end

                if spriteFrame~= nil then 
		   	        animation:addSpriteFrame(spriteFrame)
                end
		    end  
	   	    animation:setDelayPerUnit(3/nAnimeNum[self.m_nType])          --设置两个帧播放时间                   
	   	    animation:setRestoreOriginalFrame(false)    --动画执行后还原初始状态    

	   	    local action =cc.Animate:create(animation)
	   	    local seq =   cc.Sequence:create(
	   			    action,
	   			    cc.CallFunc:create(function (  )
					    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format(strPath[self.m_nType],2))  

	   				    self.m_pSprite:setSpriteFrame(frame)
	   			    end)
	   		    )
	   	    self.m_pSprite:runAction(action)

             if self.m_nType == 1 then
                --print("播放动画序列帧动画：军男")
                --self.GameViewLayer:Run_TaiYangShen()
            elseif self.m_nType == 2 then
                --print("播放动画序列帧动画：小JJ")
                --self.GameViewLayer:Run_JunNiang()
            elseif self.m_nType == 3 then
                --print("播放动画序列帧动画：帅男") 
                --self.GameViewLayer:Run_BaiShen()
            elseif self.m_nType == 4 then
                --print("播放动画序列帧动画：火男") 
                --self.GameViewLayer:Run_BaiShen()
            elseif self.m_nType == 5 then
                --print("播放动画序列帧动画：火舞") 
                --self.GameViewLayer:Run_BaiShen()
            elseif self.m_nType == 6 then
                --print("播放动画序列帧动画：大门") 
                --self.GameViewLayer:Run_BaiShen()
            elseif self.m_nType == 7 then
                --print("播放动画序列帧动画：电男") 
                --self.GameViewLayer:Run_BaiShen()
            elseif self.m_nType == 8 then
                --print("播放动画序列帧动画：胖子") 
                --self.GameViewLayer:Run_BaiShen() 
            end

        else
            self.GameViewLayer.szSpecial_Spirit = true 

            if self.m_nType == 9 then
                --print("播放动画序列帧动画：太阳神动画")
                --self.GameViewLayer:Run_TaiYangShen()
            elseif self.m_nType == 10 then
                --print("播放动画序列帧动画：军娘动画")
                --self.GameViewLayer:Run_JunNiang()
            elseif self.m_nType == 11 then
                --print("播放动画序列帧动画：八神庵动画") 
                --self.GameViewLayer:Run_BaiShen()
            end
        end

	elseif	nState == ITEM_STATE.STATE_GREY then
		--灰色纹理
		local frameName = strGrayness[self.m_nType] 
		--print("frameName =%s",frameName)                
	    local spriteFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)

		self.m_pSprite:setSpriteFrame(spriteFrame)
	end
	self.m_pSprite:setAnchorPoint(0.5,0)
	self.m_pSprite:setPosition(cc.p(self.m_pSprite:getContentSize().width/2 + 35 ,self.m_pSprite:getContentSize().height/2 - 72))

end

return GameItem