local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local GameListLayer = class("GameListLayer", function(gamelist)
		local gamelist_layer =  display.newLayer()
    return gamelist_layer
end)

local Update = appdf.req(appdf.BASE_SRC.."app.controllers.ClientUpdate")
local QueryDialog = appdf.req(appdf.BASE_SRC.."app.views.layer.other.QueryDialog")
local LogonFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.LogonFrame")

-- 进入场景而且过渡动画结束时候触发。
function GameListLayer:onEnterTransitionFinish()
	self._listView:reloadData()
    return self
end

-- 退出场景而且开始过渡动画时候触发。
function GameListLayer:onExitTransitionStart()
    return self
end

function GameListLayer:ctor(gamelist)
	print("============= 游戏列表界面创建 =============")
	self.m_bQuickStart = false

	local this = self

    --注册node事件
    --ExternalFun.registerTouchEvent(self, true)

    local function onTouchBegan( touch, event )
        if nil == self.onTouchBegan then
            return false
        end
        return self:onTouchBegan(touch, event)
    end

    local function onTouchMoved(touch, event)
        if nil ~= self.onTouchMoved then
            self:onTouchMoved(touch, event)
        end
    end

    local function onTouchEnded( touch, event )
        if nil ~= self.onTouchEnded then
            self:onTouchEnded(touch, event)
        end       
    end

    local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	self._listener = listener
	listener:registerScriptHandler( handler(self, self.onTouchBegan ),cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(handler(self, self.onTouchMoved ) ,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(handler(self, self.onTouchEnded ) ,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	self:setContentSize(yl.WIDTH,yl.HEIGHT)

	self._gameList = gamelist

    local logonCallBack = function (result,message)
		this:onLogonCallBack(result,message)
	end

	self._logonFrame = LogonFrame:create(self,logonCallBack)
	
    

	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			this:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			this:onExitTransitionStart()
		elseif eventType == "exit" then
			if self._logonFrame:isSocketServer() then
				self._logonFrame:onCloseSocket()
			end
		end
	end)

    self._listViewSize = cc.size( GlobalUserItem.gameListRect.width , GlobalUserItem.gameListRect.height )
    self._listViewPos = cc.p( GlobalUserItem.gameListRect.x , GlobalUserItem.gameListRect.y )

    -- 每隔cell的大小
    self._cellSize = cc.size(220,220)

    -- 每隔cell 的横间隔
    self._cellHSpace = (self._listViewSize.width - self._cellSize.width * 3) / 2

	--游戏列表
	self._listView = cc.TableView:create( self._listViewSize )  -- (cc.size(yl.WIDTH, 420)) 
	self._listView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)    
	self._listView:setPosition (self._listViewPos)  -- (cc.p(0,160))  
	self._listView:setDelegate()
	self._listView:addTo(self)
	self._listView:registerScriptHandler(self.tableCellTouched, cc.TABLECELL_TOUCHED)                    -- 每行的点击事件
	self._listView:registerScriptHandler(self.cellSizeForTable, cc.TABLECELL_SIZE_FOR_INDEX)             -- 设置tableview的Cell大小
	self._listView:registerScriptHandler(self.tableCellAtIndex, cc.TABLECELL_SIZE_AT_INDEX)              -- //cell中的元素显示，即每行中要显示的元素都是在这个函数中完成载入的 
	self._listView:registerScriptHandler(self.numberOfCellsInTableView, cc.NUMBER_OF_CELLS_IN_TABLEVIEW) -- //设置tableview中cell的个数
	self._listView:registerScriptHandler(self.cellHightLight, cc.TABLECELL_HIGH_LIGHT)
	self._listView:registerScriptHandler(self.cellUnHightLight, cc.TABLECELL_UNHIGH_LIGHT)

	self._txtTips = ccui.Text:create("", "fonts/round_body.ttf", 32)
         	:setAnchorPoint(cc.p(1,0))
         	:move(yl.WIDTH,110)
         	:setTextColor(cc.c4b(0,250,0,255))
         	:addTo(self)

    self.m_fThird = yl.WIDTH / 3

    --下载提示
    self.m_spDownloadMask = nil
    self.m_szMaskSize = cc.size(0,0)
    self.m_labDownloadTip = nil
    self.m_spDownloadCycle = nil
    self.m_bGameUpdate = false

    -- 开始点击的游戏列表的ID
    self._startTouchBeginGameListId = 0

    -- 去消点击的距离
    self._touchBeginPos = cc.p(0,0)
    self._touchEndPos = cc.p(0,0)
    self._touchCancelDis = 15

end

--获取父场景节点(ClientScene)
function GameListLayer:getRootNode( )
	return self:getParent():getParent()
end

--更新游戏进入记录
function GameListLayer:updateEnterGameInfo(info)
	self:getRootNode():updateEnterGameInfo(info)
end

function GameListLayer:onEnterGame( gameinfo, isQuickStart)
	self:updateEnterGameInfo(gameinfo)
	self.m_bQuickStart = isQuickStart

	--判断房间获取
	local roomCount = GlobalUserItem.GetGameRoomCount(gameinfo._KindID)
	if not roomCount or 0 == roomCount then
		--self:onLoadGameList(gameinfo._KindID)
		print("GameListLayer 房间列表为空")		
	end
	GlobalUserItem.nCurGameKind = tonumber(gameinfo._KindID)
	GlobalUserItem.szCurGameName = gameinfo._KindName
	if PriRoom and true == PriRoom:getInstance():onLoginEnterRoomList() then
		print(" GameListLayer enter priGame ")
	else
		-- 处理锁表
		local lockRoom = GlobalUserItem.GetGameRoomInfo(GlobalUserItem.dwLockServerID)
		if GlobalUserItem.dwLockKindID == GlobalUserItem.nCurGameKind and nil ~= lockRoom then
			GlobalUserItem.nCurRoomIndex = lockRoom._nRoomIndex
			self:getParent():getParent():onStartGame()
		else
			self:getParent():getParent():onChangeShowMode(yl.SCENE_ROOMLIST, self.m_bQuickStart)
		end
	end
end

---------------------------------------------------------------------
-- listview 相关
function GameListLayer.cellHightLight(view,cell)
end

function GameListLayer.cellUnHightLight(view,cell)
end

--子视图大小
function GameListLayer.cellSizeForTable(view, idx)
  	return view:getParent()._cellSize.width + view:getParent()._cellHSpace/2 ,view:getParent()._cellSize.height * 2  -- view:getParent().m_fThird , 360  --
end

--子视图数目
function GameListLayer.numberOfCellsInTableView(view)
	if not view:getParent()._gameList then
		return 0
	else
  		return math.floor(#view:getParent()._gameList / 2 )
  	end
end

--子视图点击
function GameListLayer.tableCellTouched(view, cell)
--	if GlobalUserItem.isAngentAccount() then
--		return
--	end

--	local index = cell:getIdx() 
--	local gamelistLayer = view:getParent()

--	--获取游戏信息
--	local gameinfo = gamelistLayer._gameList[index+1]
--	if  not gameinfo then
--		showToast(gamelistLayer:getParent():getParent(),"未找到游戏信息！",2)
--		return
--	end
--	gameinfo.gameIndex = index

--	--下载/更新资源 clientscene:getApp
--	local app = gamelistLayer:getParent():getParent():getApp()
--	local version = tonumber(app:getVersionMgr():getResVersion(gameinfo._KindID))
--	if not version or gameinfo._ServerResVersion > version then
--		gamelistLayer:updateGame(gameinfo, index)
--	else
--		gamelistLayer:onEnterGame(gameinfo, false)
--	end
end
	
--获取子视图
function GameListLayer.tableCellAtIndex(view, idx)	
    -- 获得一个可用的cell
	local cell = view:dequeueCell()
	
    ------ 创建一列的上下两行
    local realGmaeListIndex1 = idx * 2 + 0
    local realGmaeListIndex2 = idx * 2 + 1

    local realHPosHeight1 = view:getParent()._cellSize.height
    local realHPosHeight2 = 0
    



        local gameinfo = view:getParent()._gameList[realGmaeListIndex1+1]
	    gameinfo.gameIndex = realGmaeListIndex1
	    local filestr = "GameList/game_"..gameinfo._KindID..".png"
	    if false == cc.FileUtils:getInstance():isFileExist(filestr) then
		    filestr = "GameList/default2.png"
	    end
        -- 2
        local gameinfo2 = view:getParent()._gameList[realGmaeListIndex2+1]
        local isHaveEndSecondHSpace = false
        local filestr2 = "GameList/default2.png"
        if gameinfo2 then
            isHaveEndSecondHSpace = true

	        gameinfo2.gameIndex = realGmaeListIndex2
	        filestr2 = "GameList/game_"..gameinfo2._KindID..".png"
	        if false == cc.FileUtils:getInstance():isFileExist(filestr2) then
		        filestr2 = "GameList/default2.png"
	        end
        end

	    local game = nil
	    local mask = nil
	    local spTip = nil
        --- 2
        local game2 = nil
	    local mask2 = nil
	    local spTip2 = nil

        -- 更新，转圈圈的位置
	    local cellpos = cc.p( view:getParent()._listViewSize.width / 3 * 0.5 , realHPosHeight1 + view:getParent()._cellSize.height/2 )  -- cc.p(view:getParent().m_fThird * 0.5,view:getViewSize().height * 0.5)
        -- 2
        local cellpos2 = cc.p( view:getParent()._listViewSize.width / 3 * 0.5 , realHPosHeight2 + view:getParent()._cellSize.height/2 )

	    if not cell then
		    cell = cc.TableViewCell:new()
		    game = ccui.ImageView:create(filestr)  --display.newSprite(filestr)
		    game:addTo(cell)
			    :setAnchorPoint(cc.p(0.5, 0))
			    :setPosition( view:getParent()._listViewSize.width / 3 * 0.5 , realHPosHeight1 )   -- (view:getParent().m_fThird * 0.5, 0)   --
			    :setTag(1)
		    local maskSp = cc.Sprite:create(filestr)
		    local pos = cc.p(0,0)
		    if nil ~= maskSp then			
			    maskSp:setColor(cc.BLACK)
			    maskSp:setOpacity(100)
			    local size = maskSp:getContentSize()
			    --maskSp:setAnchorPoint(cc.p(0, 0))
			    maskSp:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
			    maskSp:setName("download_mask_sp")

			    mask = ccui.Layout:create()
			    mask:setClippingEnabled(true)
			    mask:setAnchorPoint(cc.p(0.5,0))
			    mask:setPosition(cc.p( view:getParent()._listViewSize.width / 3 * 0.5 , realHPosHeight1 ))  -- (view:getParent().m_fThird * 0.5, 0)  --
			    mask:setContentSize(size)
			    mask:addChild(maskSp)
			    cell:addChild(mask)
			    mask:setName("download_mask")

			    spTip = cc.Label:createWithTTF("", "fonts/round_body.ttf", 32)
				    :enableOutline(cc.c4b(0,0,0,255), 1)
				    :move(cellpos)
				    :setName("download_mask_tip")
				    :addTo(cell)

			    local cycle = cc.Sprite:create("GameList/spinner_circle.png")
			    if nil ~= cycle then
				    cycle:setPosition(cellpos)
				    cycle:setVisible(false)
				    cycle:setScale(1.3)
				    cycle:setName("download_cycle")
				    cell:addChild(cycle)
			    end			
		    end	

            -- touch event
            game:setTouchEnabled(true)
            game:setSwallowTouches(false)
            game:addTouchEventListener(function(ref, tType)
                if tType == ccui.TouchEventType.began then
                    view:getParent()._startTouchBeginGameListId = realGmaeListIndex1

                    return true
                elseif tType == ccui.TouchEventType.ended then   
                    if view:getParent()._startTouchBeginGameListId ~= realGmaeListIndex1 then
                        return
                    end
                    if cc.pGetDistance(  view:getParent()._touchEndPos  ,view:getParent()._touchBeginPos ) > view:getParent()._touchCancelDis then
                        return
                    end
                    print("-=-=-=-=-=-================================ up up up ")

                    if GlobalUserItem.isAngentAccount() then
		                return
	                end
		
	                local index = cell:getIdx()  * 2 + 0 -- cell:getIdx() 
	                local gamelistLayer = view:getParent()

	                --获取游戏信息
	                local gameinfo = gamelistLayer._gameList[index+1]
	                if  not gameinfo then
		                showToast(gamelistLayer:getParent():getParent(),"未找到游戏信息！",2)
		                return
	                end
	                gameinfo.gameIndex = index

	                --下载/更新资源 clientscene:getApp
	                local app = gamelistLayer:getParent():getParent():getApp()
	                local version = tonumber(app:getVersionMgr():getResVersion(gameinfo._KindID))
	                if not version or gameinfo._ServerResVersion > version then
		                gamelistLayer:updateGame(gameinfo, index)
	                else
		                gamelistLayer:onEnterGame(gameinfo, false)
	                end


                end
            end)

            --- 2
            
            game2 = ccui.ImageView:create(filestr2) --display.newSprite(filestr2)
		    game2:addTo(cell)
			    :setAnchorPoint(cc.p(0.5, 0))
			    :setPosition( view:getParent()._listViewSize.width / 3 * 0.5 , realHPosHeight2 )   -- (view:getParent().m_fThird * 0.5, 0)   --
			    :setTag(2)

		    local maskSp2 = cc.Sprite:create(filestr2)
		    local pos = cc.p(0,0)
		    if nil ~= maskSp2 then			
			    maskSp2:setColor(cc.BLACK)
			    maskSp2:setOpacity(100)
			    local size = maskSp2:getContentSize()
			    --maskSp:setAnchorPoint(cc.p(0, 0))
			    maskSp2:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
			    maskSp2:setName("download_mask_sp2")

			    mask2 = ccui.Layout:create()
			    mask2:setClippingEnabled(true)
			    mask2:setAnchorPoint(cc.p(0.5,0))
			    mask2:setPosition(cc.p( view:getParent()._listViewSize.width / 3 * 0.5 , realHPosHeight2 ))  -- (view:getParent().m_fThird * 0.5, 0)  --
			    mask2:setContentSize(size)
			    mask2:addChild(maskSp2)
			    cell:addChild(mask2)
			    mask2:setName("download_mask2")

			    spTip = cc.Label:createWithTTF("", "fonts/round_body.ttf", 32)
			        :enableOutline(cc.c4b(0,0,0,255), 1)
			        :move(cellpos2)
			        :setName("download_mask_tip2")
			        :addTo(cell)

			    local cycle = cc.Sprite:create("GameList/spinner_circle.png")
			    if nil ~= cycle then
			        cycle:setPosition(cellpos2)
			        cycle:setVisible(false)
			        cycle:setScale(1.3)
			        cycle:setName("download_cycle2")
			        cell:addChild(cycle)
			    end			
		    end	
            
            -- 2 touch event
            game2:setTouchEnabled(true)
            game2:setSwallowTouches(false)
            game2:addTouchEventListener(function(ref, tType)
                if tType == ccui.TouchEventType.began then
                    view:getParent()._startTouchBeginGameListId = realGmaeListIndex2

                    return true
                elseif tType == ccui.TouchEventType.ended then   
                    if view:getParent()._startTouchBeginGameListId ~= realGmaeListIndex2 then
                        return
                    end
                    if cc.pGetDistance(  view:getParent()._touchEndPos  ,view:getParent()._touchBeginPos ) > view:getParent()._touchCancelDis then
                        return
                    end
                    print("-=-=-=-=-=-================================ down down down ")

                    if GlobalUserItem.isAngentAccount() then
		                return
	                end
		
	                local index = cell:getIdx()  * 2 + 1 -- cell:getIdx() 
	                local gamelistLayer = view:getParent()

	                --获取游戏信息
	                local gameinfo = gamelistLayer._gameList[index+1]
	                if  not gameinfo then
		                showToast(gamelistLayer:getParent():getParent(),"未找到游戏信息！",2)
		                return
	                end
	                gameinfo.gameIndex = index

	                --下载/更新资源 clientscene:getApp
	                local app = gamelistLayer:getParent():getParent():getApp()
	                local version = tonumber(app:getVersionMgr():getResVersion(gameinfo._KindID))
	                if not version or gameinfo._ServerResVersion > version then
		                gamelistLayer:updateGame(gameinfo, index)
	                else
		                gamelistLayer:onEnterGame(gameinfo, false)
	                end


                end
            end)


	    else-----------------------------------------------------------------------------------------------
		    game = cell:getChildByTag(1)
            dump(gameinfo,"-=-=-=-=-=-=-------------- gameinfo")
            print("-=-=-=-=-=-=-=---------------- filestr",filestr)
            dump(gameinfo2,"-=-=-=-=-=-=-------------- gameinfo2")
            print("-=-=-=-=-=-=-=---------------- filestr2",filestr2)

		    game:loadTexture(filestr)

		    mask = cell:getChildByName("download_mask")
		    if nil ~= mask then
			    local sp = mask:getChildByName("download_mask_sp")
			    if nil ~= sp then
				    local size = sp:getContentSize()
				    sp:setTexture(filestr)
				    sp:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
				    mask:setContentSize(size)
			    end

			    spTip = mask:getChildByName("download_mask_tip")
			    if nil ~= spTip then
				    local size = mask:getContentSize()
				    spTip:setPosition(cellpos)
			    end
		    end

            --- 2
            if isHaveEndSecondHSpace then
                game2 = cell:getChildByTag(2)
		        game2:loadTexture (filestr2)

		        mask2 = cell:getChildByName("download_mask2")
		        if nil ~= mask2 then
			        local sp = mask2:getChildByName("download_mask_sp2")
			        if nil ~= sp then
				        local size = sp:getContentSize()
				        sp:setTexture(filestr2)
				        sp:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
				        mask2:setContentSize(size)
			        end

			        spTip2 = mask2:getChildByName("download_mask_tip2")
			        if nil ~= spTip2 then
				        local size = mask2:getContentSize()
				        spTip2:setPosition(cellpos2)
			        end
		        end
            end
	    end	

	    if nil ~= mask then
		    mask:setVisible(not gameinfo._Active)
	    end

	    if nil ~= spTip then
		    spTip:setString("")
	    end


	cell:setVisible(true)
	--cell:setTag(gameinfo._KindID)
	return cell
end
---------------------------------------------------------------------

function GameListLayer:onTouchBegan(touch, event)
    print("-=-=-=----------------- touch being")
    local touchPos = touch:getLocation()
    self._touchBeginPos = cc.p( touchPos )
    return true
end

function GameListLayer:onTouchMoved(touch, event)
    print("-=-=-=----------------- touch move")
end

function GameListLayer:onTouchEnded(touch, event)
    local touchPos = touch:getLocation()
    self._touchEndPos = cc.p( touchPos )
end

--链接游戏
function GameListLayer:onLoadGameList(nKindID)
	if not nKindID then
		self:dismissPopWait()
		local ru = cc.Director:getInstance():getRunningScene()
		if nil ~= ru then
			showToast(ru,"游戏ID有误！",1)
		end	
		return
	end
	GlobalUserItem.nCurGameKind = tonumber(nKindID)
	--如果是有游客
	if GlobalUserItem.bVisitor then		
		if self._logonFrame:onLogonByVisitor() then
			self:showPopWait()
		end
	--如果是第三方
	elseif GlobalUserItem.bThirdPartyLogin then
		local td = GlobalUserItem.thirdPartyData
		--szAccount, szNick, cbgender, platform
		if self._logonFrame:onLoginByThirdParty(td.szAccount,td.szNick, td.cbGender, td.platform) then
			self:showPopWait()
		end
	else
		if self._logonFrame:onLogonByAccount(GlobalUserItem.szAccount,GlobalUserItem.szPassword) then
			self:showPopWait()
		end
	end
end

--链接游戏回掉
function GameListLayer:onLogonCallBack(result,message)
	self:dismissPopWait()
	if  message ~= nil  and type(message) == "string" then
		local ru = cc.Director:getInstance():getRunningScene()
		if nil ~= ru then
			showToast(ru,message,2)
		end		
	end
	if result == 0 then
		self:onUpdataNotify()
	elseif result == 1 then		
		local clientscene = self:getParent():getParent()
		--判断是否是快速开始
		if nil ~= clientscene.m_bQuickStart and true == clientscene.m_bQuickStart then
			local roominfo = GlobalUserItem.GetRoomInfo(GlobalUserItem.nCurRoomIndex)
			if nil == roominfo then
				return
			end
			if bit:_and(roominfo.wServerKind, yl.GAME_GENRE_PERSONAL) ~= 0 then
				--showToast(self, "房卡房间不支持快速开始！", 2)
				return
			end
			clientscene:onStartGame()
		else
			if PriRoom and true == PriRoom:getInstance():onLoginEnterRoomList() then
				print("GameListLayer:onLogonCallBack:GameListLayer enter priGame ")
			else
				-- 处理锁表
				local lockRoom = GlobalUserItem.GetGameRoomInfo(GlobalUserItem.dwLockServerID)
				if GlobalUserItem.dwLockKindID == GlobalUserItem.nCurGameKind and nil ~= lockRoom then
					GlobalUserItem.nCurRoomIndex = lockRoom._nRoomIndex
					clientscene:onStartGame()
				else
					clientscene:onChangeShowMode(yl.SCENE_ROOMLIST, self.m_bQuickStart)
				end
			end
		end		
	end
end

--显示等待
function GameListLayer:showPopWait(isTransparent)
	self:getParent():getParent():showPopWait(isTransparent)
end

function GameListLayer:showGameUpdateWait()
	self.m_bGameUpdate = true
	ExternalFun.popupTouchFilter(1, false, "游戏更新中,请稍候！")
end

function GameListLayer:dismissGameUpdateWait()
	self.m_bGameUpdate = false
	ExternalFun.dismissTouchFilter()
end

--关闭等待
function GameListLayer:dismissPopWait()
	self:getParent():getParent():dismissPopWait()
end

function GameListLayer:updateGame(gameinfo, index)
	local cell = nil
	if nil ~= index then
		cell = self._listView:cellAtIndex(index)
	end

	self:onGameUpdate(gameinfo)
	if nil ~= cell then		
		self.m_spDownloadMask = cell:getChildByName("download_mask")
		if nil ~= self.m_spDownloadMask then
			self.m_szMaskSize = self.m_spDownloadMask:getContentSize()			
		end
		self.m_labDownloadTip = cell:getChildByName("download_mask_tip")
		if nil ~= self.m_labDownloadTip then
			self.m_labDownloadTip:setString("0%")
		end
		self.m_spDownloadCycle = cell:getChildByName("download_cycle")
		if nil ~= self.m_spDownloadCycle then
			self.m_spDownloadCycle:stopAllActions()
			self.m_spDownloadCycle:setVisible(true)
			self.m_spDownloadCycle:runAction(cc.RepeatForever:create(cc.RotateBy:create(1.0, 360)))
		end
	end
end

--更新游戏
function GameListLayer:onGameUpdate(gameinfo)
	--失败重试
	if not gameinfo and self._update ~= nil then
		self:showGameUpdateWait()
		--self._txtTips:setString("同步服务器信息中...")
		self._update:UpdateFile()
		return 
	end

	if not gameinfo and not self._downgameinfo then 
		showToast(self,"无效游戏信息！",1)
		return
	end

	self:showGameUpdateWait()
	--self._txtTips:setString("同步服务器信息中...")
	
	--记录
	if gameinfo ~= nil then
		self._downgameinfo = gameinfo
	end

	--更新参数
	local newfileurl = self:getParent():getParent():getApp()._updateUrl.."/game/"..self._downgameinfo._Module.."/res/filemd5List.json"
	local dst = device.writablePath .. "game/" .. self._downgameinfo._Type .. "/"
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS == targetPlatform then
		dst = device.writablePath .. "download/game/" .. self._downgameinfo._Type .. "/"
	end
	
	local src = device.writablePath.."game/"..self._downgameinfo._Module.."/res/filemd5List.json"
	local downurl = self:getParent():getParent():getApp()._updateUrl .. "/game/" .. self._downgameinfo._Type .. "/"

	--创建更新
	self._update = Update:create(newfileurl,dst,src,downurl)
	self._update:upDateClient(self)
end

function GameListLayer:onUpdataNotify()
	showToast(self,"游戏版本信息错误！",1)
end

--更新进度
function GameListLayer:updateProgress(sub, msg, mainpersent)
	local permsg = string.format("%d%%", mainpersent)
	if nil ~= self.m_spDownloadMask then
		local scale = (95 - mainpersent) / 100		
		self.m_spDownloadMask:setContentSize(self.m_szMaskSize.width, self.m_szMaskSize.height * scale)
	end

	if nil ~= self.m_labDownloadTip then
		self.m_labDownloadTip:setString(permsg)
	end
end

--更新结果
function GameListLayer:updateResult(result,msg)
	if nil ~= self.m_spDownloadCycle then
		self.m_spDownloadCycle:stopAllActions()
		self.m_spDownloadCycle:setVisible(false)
	end
	self:dismissGameUpdateWait()
	
	if result == true then
		local app = self:getParent():getParent():getApp()

		--更新版本号
		for k,v in pairs(app._gameList) do
			if v._KindID == self._downgameinfo._KindID then
				app:getVersionMgr():setResVersion(v._ServerResVersion, v._KindID)
				v._Active = true
				break
			end
		end

		self._txtTips:setString("OK")
		self:onEnterGame(self._downgameinfo)
	else
		local runScene = cc.Director:getInstance():getRunningScene()
		if nil ~= runScene then			
			if nil ~= self.m_spDownloadMask then	
				self.m_spDownloadMask:setContentSize(self.m_szMaskSize.width, self.m_szMaskSize.height)
			end

			if nil ~= self.m_labDownloadTip then
				self.m_labDownloadTip:setString("")
			end

			self._txtTips:setString("")
			QueryDialog:create(msg.."\n是否重试？",function(bReTry)
					if bReTry == true then
						self:onGameUpdate(self._downgameinfo)
					end
				end)
				:addTo(runScene)
		end		
	end
end

function GameListLayer:onKeyBack()
	return self.m_bGameUpdate ~= false
end

return GameListLayer