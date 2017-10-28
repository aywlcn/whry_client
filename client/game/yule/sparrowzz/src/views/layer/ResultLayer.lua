local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.CMD_Game")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")
local CardLayer = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.views.layer.CardLayer")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.GameLogic")

local ResultLayer = class("ResultLayer", function(scene)
	local resultLayer = cc.CSLoader:createNode(cmd.RES_PATH.."game/gameendLayer.csb")
	return resultLayer
end)

ResultLayer.kFlagDefault = 0
ResultLayer.kFlagHuangzZhuang = 1
ResultLayer.kZiMo = 2
ResultLayer.kFangPao = 3
ResultLayer.kTaoPao = 4

ResultLayer.HANDCARDTAG = 100
ResultLayer.ZHUONIAOTAG = 200

function ResultLayer:onInitData()
end

function ResultLayer:onResetData()
	local sp_zhuaniaobg = self:getChildByName("sp_zhuaniao")
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		local result_playerbg = self:getChildByName(string.format("result_playerbg_%d", i-1))
		if result_playerbg:getChildByTag(ResultLayer.HANDCARDTAG + i) ~= nil then
			result_playerbg:removeChildByTag(ResultLayer.HANDCARDTAG + i)
		end
	end

	for nline=1, 3 do
		if sp_zhuaniaobg:getChildByTag(ResultLayer.ZHUONIAOTAG + nline) ~= nil then
			sp_zhuaniaobg:removeChildByTag(ResultLayer.ZHUONIAOTAG + nline)
		end
	end
end

function ResultLayer:ctor(scene)
	self._scene = scene
	self:onInitData()
	ExternalFun.registerTouchEvent(self, true)

	local btnShare = self:getChildByName("btn_share")
	btnShare:addClickEventListener(function(ref)
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
	end)

	local btContinue = self:getChildByName("btnContinue")
	btContinue:addClickEventListener(function(ref)
		self:hideLayer()
		self._scene:onButtonClickedEvent(self._scene.BT_START)
	end)

	local btClose = self:getChildByName("btnClose")
	btClose:addClickEventListener(function(ref)
		self:hideLayer()
		self._scene:onButtonClickedEvent(self._scene.BT_CLOSERESULTLAYER)
	end)
end

function ResultLayer:showLayer(resultList, resultbuf, m_enFlag)
	assert(type(resultList) == "table")

	--约战
	if GlobalUserItem.bPrivateRoom then
		local btClose = self:getChildByName("btnClose")
		btClose:setVisible(false)
		--约战最后一局禁用
		if PriRoom:getInstance().m_tabPriData.dwPlayCount == PriRoom:getInstance().m_tabPriData.dwDrawCountLimit then
			local btContinue = self:getChildByName("btnContinue")
			local btShare = self:getChildByName("btn_share")

			if btContinue ~= nil and btContinue:isVisible() then
				btContinue:setVisible(false)

				--分享按钮居中
				btShare:setPosition(cc.p(1334 / 2, 60))

				--最后一局3秒后关闭结算框，显示约战总结算
				self:runAction(cc.Sequence:create(cc.DelayTime:create(3.0),
			    cc.CallFunc:create(function()
			        self:hideLayer()
			    end)))
			end
		end
	end

	LogAsset:getInstance():logData("spResultSp",true)
	print("spResultSp", spResultSp)
	print("resultbuf", resultbuf)
	print("m_enFlag", m_enFlag)
	local spResultSp = self:getChildByName("title_gameend_result")
	if spResultSp ~= nil then
		spResultSp:setTexture(cmd.RES_PATH.."game/".. string.format("title_result_%d.png", m_enFlag))
	end
	
	local textresultdescrip = self:getChildByName("text_resultdescrip")
	if textresultdescrip ~= nil then
		textresultdescrip:setString(resultbuf)
	end

    --用户昵称,金币结算
    local atlas_coin = nil
    local GangCount = nil
    local spBanker = nil
    local spCoin = nil
    local text_nickname = ""
	for i = 1, cmd.zhzmj_GAME_PLAYER do
		if resultList[i].useritem then
			local result_playerbg = self:getChildByName(string.format("result_playerbg_%d", i-1))
			if result_playerbg then

				result_playerbg:setVisible(true)

				--昵称
				local text_nickname = result_playerbg:getChildByName(string.format("text_nickname_%d", i-1))
				if text_nickname then
					text_nickname:setString(resultList[i].sznickname)
				end

				--玩家携带金币
                local text_userscore = result_playerbg:getChildByName(string.format("text_userscore_%d", i-1))
                if text_userscore then
					text_userscore:setString(string.format("%d", resultList[i].useritem.lScore))
				end

				--杠分
                local GangCount = result_playerbg:getChildByName(string.format("atlas_gang_%d", i-1))
                if GangCount then
                	GangCount:setProperty(string.format("/%d", resultList[i].lGangCount), cmd.RES_PATH.."game/atlas_gameendgang_num.png", 26, 36, ".")
                end

                --庄家标识
                local spBanker = result_playerbg:getChildByName(string.format("sp_banker_%d", i-1))
                if spBanker then
                	spBanker:setVisible(resultList[i].bBanker)
                end

                --输赢积分
                local coins = result_playerbg:getChildByName(string.format("atlas_coin_%d", i-1))
                if coins then
                	if resultList[i].score >= 0 then
                		coins:setProperty(string.format("/%d", resultList[i].score), cmd.RES_PATH.."game/atlas_gameendadd_coin_num.png", 26, 36, ".")
                	else 
                		coins:setProperty(string.format("/%d", resultList[i].score), cmd.RES_PATH.."game/atlas_gameendsub_coin_num.png", 26, 36, ".")
                	end
                end

                --结算标识
                print("sp_flagprev", sp_flagprev)
                print("enFlag", resultList[i].enFlag)
                local sp_flagprev = result_playerbg:getChildByName(string.format("sp_flag_%d", i-1))
                if sp_flagprev then
                	--自摸
                	if resultList[i].enFlag == self.kZiMo then
                		sp_flagprev:setVisible(true)
                		sp_flagprev:setTexture("cmd.RES_PATH..game/result_zimo.png")
                	elseif resultList[i].enFlag == self.kFangPao then
                 		sp_flagprev:setVisible(true)
                		sp_flagprev:setTexture("cmd.RES_PATH..game/result_dianpaoflag.png")               	
                	else 
                		sp_flagprev:setVisible(false)
                	end
                end
			end


		end
	end

	LogAsset:getInstance():logData("setVisible",true)
	self:setVisible(true)
	self:setLocalZOrder(yl.MAX_INT)
end

function ResultLayer:addCards(resultCardList, winchairid)
	local ProvideCard = resultCardList[1].cbProvideCard

	local width = 44
	local height = 67

	for i = 1, cmd.zhzmj_GAME_PLAYER do
		if resultCardList[i].useritem then
			local result_playerbg = self:getChildByName(string.format("result_playerbg_%d", i-1))
			if result_playerbg then
				--麻将节点
				local mahjongHolder = cc.Node:create()
				mahjongHolder:setPosition(result_playerbg:getChildByName(string.format("sp_mj_%d", i-1)):getPosition())
				mahjongHolder:setTag(ResultLayer.HANDCARDTAG + i)
				result_playerbg:addChild(mahjongHolder)

				--赢家手牌(正常渠道赢)
				if i == winchairid and ProvideCard ~= 0 then
					print("ProvideCard", ProvideCard)
					print("resultCardList.cbCardCount", resultCardList[i].cbCardCount)
					--手牌 （剔除手牌中的供应牌）
					
					for k=1, resultCardList[i].cbCardCount do
						print("resultCardList.cbCardData", resultCardList[i].cbCardData[k])
						if resultCardList[i].cbCardData[k] == ProvideCard then
						   resultCardList[i].cbCardData[k] = 0
						   break
						end
					end

					local handcarddata = {}
					local handcardcount = 1
					for k=1, resultCardList[i].cbCardCount do
						if resultCardList[i].cbCardData[k] ~=0 then
						   handcarddata[handcardcount] = resultCardList[i].cbCardData[k]
						   handcardcount = handcardcount + 1
						end
					end

					--显示手牌
					local pos = cc.p(0, 0)
					handcardcount = handcardcount - 1
					print("handcardcount", handcardcount)
					for j=1, handcardcount do
						print("handcarddata", handcarddata[j])
						local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, handcarddata[j], false)
						if nil ~= sprCard then
							mahjongHolder:addChild(sprCard)
							pos = cc.p(pos.x + width, 0)
							sprCard:setPosition(pos)
						end
					end

					--显示供应牌
					pos = cc.p(pos.x + 5, 0)
					local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, ProvideCard, false)
					if nil ~= sprCard then
						mahjongHolder:addChild(sprCard)
						pos = cc.p(pos.x + width, 0)
						sprCard:setPosition(pos)
					end

					--杠牌数量
					local cbGangCount = 0
					if nil ~=  resultCardList[i].cbActiveCardData then
						for j=1,#resultCardList[i].cbActiveCardData do
							local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
							if tagAvtiveCard.cbType == GameLogic.SHOW_MING_GANG or tagAvtiveCard.cbType == GameLogic.SHOW_AN_GANG then
								cbGangCount = cbGangCount + 1
							end
						end
					end

					--组合牌
					pos = cc.p(pos.x + 5, 0)

					--杠牌有4组叠在上面
					if cbGangCount == 4 then
						if nil ~=  resultCardList[i].cbActiveCardData then
							for j=1,#resultCardList[i].cbActiveCardData do
								local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
								for num=1,tagAvtiveCard.cbCardNum do
									local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, tagAvtiveCard.cbCardValue[1], false)
									if nil ~= sprCard then
										mahjongHolder:addChild(sprCard)

										--第3张和第2张一张的横坐标
										if num == 3 then
											local temppos = pos
											temppos = cc.p(temppos.x, 10)
											sprCard:setPosition(temppos)
										else
											pos = cc.p(pos.x + width, 0)
											sprCard:setPosition(pos)
										end
									end
								end

								pos = cc.p(pos.x + 4, 0)
							end
						end
					else
						if nil ~=  resultCardList[i].cbActiveCardData then
							for j=1,#resultCardList[i].cbActiveCardData do
								local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
								for num=1,tagAvtiveCard.cbCardNum do
									local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, tagAvtiveCard.cbCardValue[1], false)
									if nil ~= sprCard then
										mahjongHolder:addChild(sprCard)
										pos = cc.p(pos.x + width, 0)
										sprCard:setPosition(pos)
									end
								end

								pos = cc.p(pos.x + 4, 0)
							end
						end
					end

				--对方逃跑而赢
				elseif i == winchairid and ProvideCard == 0 then
					--显示手牌
					local pos = cc.p(0, 0)
					print("手牌 ", #resultCardList[i].cbCardData)
					for j=1,#resultCardList[i].cbCardData do
						print("kevin5")
						local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, resultCardList[i].cbCardData[j], false)
						if nil ~= sprCard then
							print("kevin6")
							mahjongHolder:addChild(sprCard)
							pos = cc.p(pos.x + width, 0)
							sprCard:setPosition(pos)
						end
					end

					--杠牌数量
					local cbGangCount = 0
					if nil ~=  resultCardList[i].cbActiveCardData then
						for j=1,#resultCardList[i].cbActiveCardData do
							local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
							if tagAvtiveCard.cbType == GameLogic.SHOW_MING_GANG or tagAvtiveCard.cbType == GameLogic.SHOW_AN_GANG then
								cbGangCount = cbGangCount + 1
							end
						end
					end

					--组合牌
					print("kevin1")
					pos = cc.p(pos.x + 5, 0)
					--杠牌有4组叠在上面
					if cbGangCount == 4 then
						if nil ~=  resultCardList[i].cbActiveCardData then
							for j=1,#resultCardList[i].cbActiveCardData do
								local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
								for num=1,tagAvtiveCard.cbCardNum do
									local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, tagAvtiveCard.cbCardValue[1], false)
									if nil ~= sprCard then
										mahjongHolder:addChild(sprCard)

										--第3张和第2张一张的横坐标
										if num == 3 then
											local temppos = pos
											temppos = cc.p(temppos.x, 10)
											sprCard:setPosition(temppos)
										else
											pos = cc.p(pos.x + width, 0)
											sprCard:setPosition(pos)
										end
									end
								end

								pos = cc.p(pos.x + 4, 0)
							end
						end
					else
						if nil ~=  resultCardList[i].cbActiveCardData then
							for j=1,#resultCardList[i].cbActiveCardData do
								local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
								for num=1,tagAvtiveCard.cbCardNum do
									local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, tagAvtiveCard.cbCardValue[1], false)
									if nil ~= sprCard then
										mahjongHolder:addChild(sprCard)
										pos = cc.p(pos.x + width, 0)
										sprCard:setPosition(pos)
									end
								end

								pos = cc.p(pos.x + 4, 0)
							end
						end
					end

				--输的玩家
				else
					print("手牌 ", #resultCardList[i].cbCardData)
					local pos = cc.p(0, 0)
					--显示手牌
					for j=1,#resultCardList[i].cbCardData do
						local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, resultCardList[i].cbCardData[j], false)
						if nil ~= sprCard then
							mahjongHolder:addChild(sprCard)
							pos = cc.p(pos.x + width, 0)
							sprCard:setPosition(pos)
						end
					end

					--杠牌数量
					local cbGangCount = 0
					if nil ~=  resultCardList[i].cbActiveCardData then
						for j=1,#resultCardList[i].cbActiveCardData do
							local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
							if tagAvtiveCard.cbType == GameLogic.SHOW_MING_GANG or tagAvtiveCard.cbType == GameLogic.SHOW_AN_GANG then
								cbGangCount = cbGangCount + 1
							end
						end
					end

					--组合牌
					print("kevin2.5")
					pos = cc.p(pos.x + 5, 0)
					--杠牌有4组叠在上面
					if cbGangCount == 4 then
						if nil ~=  resultCardList[i].cbActiveCardData then
							for j=1,#resultCardList[i].cbActiveCardData do
								local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
								for num=1,tagAvtiveCard.cbCardNum do
									local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, tagAvtiveCard.cbCardValue[1], false)
									if nil ~= sprCard then
										mahjongHolder:addChild(sprCard)

										--第3张和第2张一张的横坐标
										if num == 3 then
											local temppos = pos
											temppos = cc.p(temppos.x, 10)
											sprCard:setPosition(temppos)
										else
											pos = cc.p(pos.x + width, 0)
											sprCard:setPosition(pos)
										end
									end
								end

								pos = cc.p(pos.x + 4, 0)
							end
						end
					else
						if nil ~=  resultCardList[i].cbActiveCardData then
							for j=1,#resultCardList[i].cbActiveCardData do
								local tagAvtiveCard = resultCardList[i].cbActiveCardData[j]
								for num=1,tagAvtiveCard.cbCardNum do
									local sprCard = self._scene._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, tagAvtiveCard.cbCardValue[1], false)
									if nil ~= sprCard then
										mahjongHolder:addChild(sprCard)
										pos = cc.p(pos.x + width, 0)
										sprCard:setPosition(pos)
									end
								end

								pos = cc.p(pos.x + 4, 0)
							end
						end
					end
				end
			end
		end
	end
end

function ResultLayer:addZhuoNiaoCards(ZhuoNiaoCards)
	assert(type(ZhuoNiaoCards) == "table")

	--捉鸟背景
	local sp_zhuaniaobg = self:getChildByName("sp_zhuaniao")
	assert(sp_zhuaniaobg ~= nil)
	sp_zhuaniaobg:setVisible(true)

	local cbZhuoNiaoCount = 0
	for i=1, 6 do
		if ZhuoNiaoCards[i] ~= 0 then
			cbZhuoNiaoCount = cbZhuoNiaoCount + 1
		end
	end

	assert(cbZhuoNiaoCount % 2 == 0)
	local nlinecount = cbZhuoNiaoCount / 2
	local width = 80
	local pos = cc.p(0, 0)
	for nline=1, nlinecount do
		pos = cc.p(0, 0)
		--麻将节点
		local mahjongHolder = cc.Node:create()
		mahjongHolder:setPosition(sp_zhuaniaobg:getChildByName(string.format("sp_zhuaniao_%d", nline-1)):getPosition())
		mahjongHolder:setTag(ResultLayer.ZHUONIAOTAG + nline)
		sp_zhuaniaobg:addChild(mahjongHolder)
		for i=1, 2 do
			local sprCard = self._scene._cardLayer:createMyActiveCardSprite(ZhuoNiaoCards[(nline-1)*2+i], false)
			if nil ~= sprCard then
				mahjongHolder:addChild(sprCard)
				sprCard:setPosition(pos)
				pos = cc.p(pos.x + width, 0)
			end
		end
	end
end

function ResultLayer:hideLayer()
	if not self:isVisible() then
		return
	end
	self:onResetData()
	self:setVisible(false)
	self._scene.btStart:setVisible(true)
end
return ResultLayer