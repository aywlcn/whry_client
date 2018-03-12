local RoomListLayer = class("RoomListLayer", function(scene)
	local roomlist_layer = display.newLayer()
    return roomlist_layer
end)

-- 进入场景而且过渡动画结束时候触发。
function RoomListLayer:onEnterTransitionFinish()
	self._listView:reloadData()
    return self
end
-- 退出场景而且开始过渡动画时候触发。
function RoomListLayer:onExitTransitionStart()
    return self
end
function RoomListLayer:onSceneAniFinish()
end


function RoomListLayer:ctor(scene, isQuickStart)
	self._scene = scene
	local this = self
	self.m_bIsQuickStart = isQuickStart or false

	local enterGame = self._scene:getEnterGameInfo()
	--缓存资源
	local modulestr = string.gsub(enterGame._KindName, "%.", "/")
	local path = "game/" .. modulestr .. "res/roomlist/roomlist.plist"	
	if false == cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded(path) then
		if cc.FileUtils:getInstance():isFileExist(path) then
			cc.SpriteFrameCache:getInstance():addSpriteFrames(path)
		end
	end	
	self.m_fThree = yl.WIDTH / 3

	--区域设置
	self:setContentSize(yl.WIDTH,yl.HEIGHT)

	--房间列表
	self._listView = cc.TableView:create(cc.size(yl.WIDTH, 400))
	self._listView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)   
	self._listView:setPosition(cc.p(0, 160))
	self._listView:setDelegate()
	self._listView:addTo(self)
	self._listView:registerScriptHandler(handler(self, self.tableCellTouched), cc.TABLECELL_TOUCHED)
	self._listView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
	self._listView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
	self._listView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	self._listView:registerScriptHandler(self.cellHightLight, cc.TABLECELL_HIGH_LIGHT)
	self._listView:registerScriptHandler(self.cellUnHightLight, cc.TABLECELL_UNHIGH_LIGHT)

	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			this:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			this:onExitTransitionStart()
		end
	end)

	if true == self.m_bIsQuickStart then
		self:stopAllActions()
		GlobalUserItem.nCurRoomIndex = 1
		self:onStartGame()
	end

	self.m_tabRoomListInfo = {}
	for k,v in pairs(GlobalUserItem.roomlist) do
		if tonumber(v[1]) == GlobalUserItem.nCurGameKind then
			local listinfo = v[2]
			if type(listinfo) ~= "table" then
				break
			end
			local normalList = {}
			for k,v in pairs(listinfo) do
				if v.wServerType ~= yl.GAME_GENRE_PERSONAL then
					table.insert( normalList, v)
				end
			end
			self.m_tabRoomListInfo = normalList
			break
		end
	end	
end

function RoomListLayer.cellHightLight(view,cell)

end

function RoomListLayer.cellUnHightLight(view,cell)

end

--子视图大小
function RoomListLayer:cellSizeForTable(view, idx)
  	return self.m_fThree , 328
end

--子视图数目
function RoomListLayer:numberOfCellsInTableView(view)
	return #self.m_tabRoomListInfo
end

function RoomListLayer:tableCellTouched(view, cell)
	local index= cell:getIdx()+1
	local roominfo = self.m_tabRoomListInfo[index]
	if not roominfo then
		return
	end
	GlobalUserItem.nCurRoomIndex = roominfo._nRoomIndex
	GlobalUserItem.bPrivateRoom = (roominfo.wServerType == yl.GAME_GENRE_PERSONAL)
	if view:getParent()._scene:roomEnterCheck() then
		view:getParent():onStartGame()
	end	
end


--获取子视图
function RoomListLayer:tableCellAtIndex(view, idx)
	local iteminfo = self.m_tabRoomListInfo[idx+1]
	local cell = view:dequeueCell()
	local wLv = (iteminfo == nil and 0 or iteminfo.wServerLevel)
	if cell == nil then
		cell = cc.TableViewCell:new()
	end
	cell:removeAllChildren()
		
	if 8 == wLv then
		--比赛场单独处理
	else
		local rule = (iteminfo == nil and 0 or iteminfo.dwServerRule)
		wLv = (bit:_and(yl.SR_ALLOW_AVERT_CHEAT_MODE, rule) ~= 0) and 10 or iteminfo.wServerLevel
		wLv = (wLv ~= 0) and wLv or 1
		local wRoom = math.mod(wLv, 3)--bit:_and(wLv, 3)
		local szName = (iteminfo == nil and "房间名称" or iteminfo.szServerName)
		local szCount = (iteminfo == nil and "0" or(iteminfo.dwOnLineCount..""))
		local szServerScore = (iteminfo == nil and "0" or iteminfo.lCellScore)
		local enterGame = self._scene:getEnterGameInfo()

        dump(iteminfo , "------------------------------------------- iteminfo")
		
		local cellpos = cc.p(self.m_fThree * 0.5, view:getViewSize().height * 0.5)

		--检查房间背景资源
--		local modulestr = string.gsub(enterGame._KindName, "%.", "/")
--		local path = "game/" .. modulestr .. "res/roomlist/icon_roomlist_" .. wRoom .. ".png"
--		local framename = enterGame._KindID .. "_icon_roomlist_" .. wRoom .. ".png"
--		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(framename)
--		if nil ~= frame then
--			local sp = cc.Sprite:createWithSpriteFrame(frame)
--			sp:setPosition(cc.p(self.m_fThree * 0.5, view:getViewSize().height * 0.5 + 10))
--			cell:addChild(sp)
--		elseif cc.FileUtils:getInstance():isFileExist(path) then
--			--房间类型
--			display.newSprite(path)
--				:setPosition(cc.p(self.m_fThree * 0.5, view:getViewSize().height * 0.5 + 10))
--				:addTo(cell)
--		end

		--背景
--		display.newSprite("RoomList/icon_roomlist_frame.png")
--			:setPosition(cellpos)
--			:addTo(cell)
        local wLvTem = wLv
        if wLvTem > 4 then
            wLvTem = 4
        end
        local spriteBg = display.newSprite("RoomList/icon_roomlist_frame".. wLvTem ..".png")
			:setPosition(cellpos)
			:addTo(cell)

        ---- add by wss
        -- 入场条件
        local ruchangWord = ccui.Text:create()
        ruchangWord:addTo(spriteBg)
        ruchangWord:setFontSize(20)
        ruchangWord:setAnchorPoint(cc.p(1,0.5))
        ruchangWord:setPosition(0.42*spriteBg:getContentSize().width , 0.42*spriteBg:getContentSize().height)
        ruchangWord:setString("入场:")

        local ruchangValue = ccui.Text:create()
        ruchangValue:addTo(spriteBg)
        ruchangValue:setAnchorPoint(cc.p(0,0.5))
        ruchangValue:setPosition(0.45*spriteBg:getContentSize().width , 0.42*spriteBg:getContentSize().height)
        ruchangValue:setFontSize(20)
        ruchangValue:setString(iteminfo.lEnterScore.."以上")

        --- 下注区间
        local xiazhuWord = ccui.Text:create()
        xiazhuWord:addTo(spriteBg)
        xiazhuWord:setFontSize(20)
        xiazhuWord:setAnchorPoint(cc.p(1,0.5))
        xiazhuWord:setPosition(0.42*spriteBg:getContentSize().width , 0.23*spriteBg:getContentSize().height)
        xiazhuWord:setString("下注:")

        local xiazhuValue = ccui.Text:create()
        xiazhuValue:addTo(spriteBg)
        xiazhuValue:setFontSize(20)
        xiazhuValue:setAnchorPoint(cc.p(0,0.5))
        xiazhuValue:setPosition(0.45*spriteBg:getContentSize().width , 0.23*spriteBg:getContentSize().height)
        --xiazhuValue:setString(iteminfo.lEnterScore)

        xiazhuValue:setString( self:getBetRange(enterGame._KindID,wLvTem) )

		--房间类型
--		framename = enterGame._KindID .. "_title_icon_" .. wLv .. ".png"
--		frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(framename)
--		path = "game/" .. modulestr .. "res/roomlist/title_icon_" .. wLv .. ".png"
--		if nil ~= frame then
--			local sp = cc.Sprite:createWithSpriteFrame(frame)
--			sp:setPosition(cc.p(self.m_fThree * 0.5,100))
--			cell:addChild(sp)
--		elseif cc.FileUtils:getInstance():isFileExist(path) then		
--			display.newSprite(path)
--				:setPosition(cc.p(self.m_fThree * 0.5,100))
--				:addTo(cell)
--		else
--			local default = "RoomList/title_icon_" .. wLv .. ".png"
--			if cc.FileUtils:getInstance():isFileExist(default) then
--				--默认资源
--				display.newSprite(default)
--					:setPosition(cc.p(self.m_fThree * 0.5,100))
--					:addTo(cell)
--			end			
--		end

--		--底注
--		display.newSprite("RoomList/text_roomlist_cellscore.png")
--			:setPosition(cc.p(self.m_fThree * 0.5 - 10,338))
--			:setAnchorPoint(cc.p(1.0,0.5))
--			:addTo(cell)

--		cc.LabelAtlas:_create(szServerScore, "RoomList/num_roomlist_cellscore.png", 14, 19, string.byte("0")) 
--			:move(self.m_fThree * 0.5 - 10,338)
--			:setAnchorPoint(cc.p(0,0.5))
--			:addTo(cell)
	end

	return cell
end

--- 获取下注区间
function RoomListLayer:getBetRange(gameKind,lv)
    if tonumber( gameKind ) == 6 or tonumber( gameKind ) == 102 or tonumber( gameKind ) == 508 or tonumber( gameKind ) == 503 or tonumber( gameKind ) == 510 or tonumber( gameKind ) == 511 then
        if lv == 1 then
            return "10-100"
        elseif lv == 2 then
            return "100-1千"
        elseif lv == 3 then
            return "1千-1万"
        elseif lv == 4 then
            return "1万-10万"
        else
            return "10-100"
        end
    elseif tonumber( gameKind ) == 122 or tonumber( gameKind ) == 104 or tonumber( gameKind ) == 140 or tonumber( gameKind ) == 123 then
        if lv == 1 then
            return "100-1000万"
        elseif lv == 2 then
            return "100-1000万"
        elseif lv == 3 then
            return "100-5000万"
        elseif lv == 4 then
            return "100-5000万"
        else
            return "10-100"
        end
    elseif tonumber( gameKind ) == 516 or tonumber( gameKind ) == 519 or tonumber( gameKind ) == 502 then
        if lv == 1 then
            return "10-80"
        elseif lv == 2 then
            return "100-800"
        elseif lv == 3 then
            return "1千-8千"
        elseif lv == 4 then
            return "1万-8万"
        else
            return "10-100"
        end
    else
        if lv == 1 then
            return "10-80"
        elseif lv == 2 then
            return "100-800"
        elseif lv == 3 then
            return "1千-8千"
        elseif lv == 4 then
            return "1万-8万"
        else
            return "10-100"
        end
    end

end

--显示等待
function RoomListLayer:showPopWait()
	if self._scene then
		self._scene:showPopWait()
	end
end

--关闭等待
function RoomListLayer:dismissPopWait()
	if self._scene then
		self._scene:dismissPopWait()
	end
end


function RoomListLayer:onStartGame(index)
	local iteminfo = GlobalUserItem.GetRoomInfo(index)
	if iteminfo ~= nil then
		self._scene:onStartGame(index)
	end
end

return RoomListLayer