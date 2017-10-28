local GameLogic = {}

local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.CMD_Game")

--动作标志
GameLogic.WIK_NULL					= 0x00						--没有类型--0
GameLogic.WIK_LEFT					= 0x01						--左吃类型--1
GameLogic.WIK_CENTER				= 0x02						--中吃类型--2
GameLogic.WIK_RIGHT					= 0x04						--右吃类型--4
GameLogic.WIK_PENG					= 0x08						--碰牌类型--8
GameLogic.WIK_GANG					= 0x10						--杠牌类型--16
GameLogic.WIK_CHI_HU				= 0x40						--吃胡类型--64
GameLogic.WIK_REPLACE				= 0x80						--花牌替换

--胡牌定义
GameLogic.CHR_PU_TONG				= 0x00000001				--普通胡
GameLogic.CHR_PENG_PENG				= 0x00000002				--碰碰胡
GameLogic.CHR_QI_DUI				= 0x00000004				--七对
GameLogic.CHR_ZI_MO					= 0x00000008				--自摸
GameLogic.CHR_SI_HONG_ZHONG			= 0x00000010				--四红中

--显示类型
GameLogic.SHOW_NULL					= 0							--无操作
GameLogic.SHOW_CHI 					= 1 						--吃
GameLogic.SHOW_PENG					= 2 						--碰
GameLogic.SHOW_MING_GANG			= 3							--明杠 1.存在组合牌明杠 2.手牌有3张，别家打出一张为明杠
GameLogic.SHOW_AN_GANG				= 5							--暗杠 自己手牌3张，摸了一张为暗杠

GameLogic.LocalCardData = 
{
	0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
	0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
	0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
	0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37
}

GameLogic.LocalMagicIndex = 0xFF

--类型子项
GameLogic.tagKindItem = 
{
	{k = "cbWeaveKind", t = "byte"},													--组合类型
	{k = "cbCenterCard", t = "byte"},													--中心扑克					
 	{k = "cbValidIndex", t = "byte", l = {3}},											--组合数据
}

--杠牌结果
GameLogic.tagGangCardResult = 
{
	{k = "cbCardCount", t = "byte"},													--扑克数目										
 	{k = "cbCardData", t = "byte", l = {cmd.zhzmj_MAX_WEAVE}},											--扑克数据
}

--混乱扑克
function GameLogic.RandCardData(cbCardData, cbCardCount, cbRandData)
	assert(type(cbCardData) == "table")
	assert(type(cbRandData) == "table")
	assert(cbCardCount ~= 0)

	--混乱准备
	local cbCardDataTemp = clone(cbCardData)

	--混乱扑克
	local cbRandCount, cbPosition = 0, 0
	while cbRandCount < cbCardCount do
		cbPosition = math.random(cbCardCount - cbRandCount)
		cbRandData[cbRandCount + 1] = cbCardDataTemp[cbPosition]
		cbCardDataTemp[cbPosition] = cbCardDataTemp[cbCardCount - cbRandCount]
		cbRandCount = cbRandCount + 1
	end
end

--扑克转换
function GameLogic.SwitchToCardIndex(cbCardData)
	local index = 0
	for i = 1, #GameLogic.LocalCardData do
		if GameLogic.LocalCardData[i] == cbCardData then
			index = i
			break
		end
	end

	return index
end

--扑克转换
function GameLogic.SwitchToCardData(cbCardIndex)
	assert(index >= 1 and index <= 34, "The card index is error!")
	return GameLogic.LocalCardData[cbCardIndex]
end

--删除扑克
function GameLogic.RemoveCard(cbCardIndex, cbRemoveCard)
	--效验扑克
	assert(cbCardIndex[GameLogic.SwitchToCardIndex(cbRemoveCard)] > 0, "RemoveCard is error!")
	assert(type(cbCardIndex) == "table")

	--删除扑克
	local cbRemoveIndex = GameLogic.SwitchToCardIndex(cbRemoveCard)
	if cbCardIndex[cbRemoveIndex] > 0 then
		cbCardIndex[cbRemoveIndex] = cbCardIndex[cbRemoveIndex] - 1
		return true
	end

	return false
end

--设置财神
function GameLogic.SetMagicIndex(cbMagicIndex)
	GameLogic.LocalMagicIndex = cbMagicIndex
end

--排序,根据牌值排序
function GameLogic.SortCardList(cbCardData, cbCardCount)
	--校验
	assert(type(cbCardData) == "table" and #cbCardData > 0)

	if cbCardCount == 0 or cbCardCount > cmd.zhzmj_MAX_COUNT then
		return false
	end 

	--排序操作
	local bSorted = false
	local cbLast = cbCardCount - 1
	while bSorted == false do
		bSorted = true
		for i = 1, cbLast do
			if cbCardData[i] > cbCardData[i + 1] then
				bSorted = false
				cbCardData[i], cbCardData[i + 1] = cbCardData[i + 1], cbCardData[i]
			end
		end
		cbLast = cbLast - 1
	end
end

--获取组合
function GameLogic.GetWeaveCard(cbWeaveKind, cbCenterCard, cbCardBuffer)
	--校验
	assert(type(cbCardBuffer) == "table")

	--上牌操作
	if cbWeaveKind == GameLogic.WIK_LEFT then
		--设置变量
		cbCardBuffer[1] = cbCenterCard
		cbCardBuffer[2] = cbCenterCard + 1
		cbCardBuffer[3] = cbCenterCard + 2

		return 3
	elseif cbWeaveKind == GameLogic.WIK_RIGHT then
		--设置变量
		cbCardBuffer[1] = cbCenterCard - 2
		cbCardBuffer[2] = cbCenterCard - 1
		cbCardBuffer[3] = cbCenterCard	

		return 3
	elseif cbWeaveKind == GameLogic.WIK_CENTER then
		--设置变量
		cbCardBuffer[1] = cbCenterCard - 1
		cbCardBuffer[2] = cbCenterCard 
		cbCardBuffer[3] = cbCenterCard + 1	

		return 3		
	elseif cbWeaveKind == GameLogic.WIK_PENG then
		--设置变量
		cbCardBuffer[1] = cbCenterCard
		cbCardBuffer[2] = cbCenterCard 
		cbCardBuffer[3] = cbCenterCard

		return 3	
	elseif cbWeaveKind == GameLogic.WIK_GANG then
		--设置变量
		cbCardBuffer[1] = cbCenterCard
		cbCardBuffer[2] = cbCenterCard 
		cbCardBuffer[3] = cbCenterCard
		cbCardBuffer[4] = cbCenterCard

		return 4	
	else
		assert(false, "GetWeaveCard")
	end

	return 0
end

--杠牌分析
function GameLogic.AnalyseGangCard(cbCardIndex, WeaveItem, cbWeaveCount, GangCardResult)
	--校验
	assert(type(cbCardIndex) == "table")	
	assert(type(WeaveItem) == "table")	
	assert(type(GangCardResult) == "table")	

	--设置变量
	local cbActionMask = GameLogic.WIK_NULL
	GangCardResult = {}

	--手上杠牌
	for i=1, cmd.zhzmj_MAX_INDEX do
		repeat
			if i == LocalMagicIndex then
				break
			end
		until true

		if cbCardIndex[i] == 4 then
			cbActionMask = bit:_or(cbActionMask, GameLogic.WIK_GANG)
			GangCardResult[1].cbCardData[GangCardResult[1].cbCardCount + 1] = GameLogic.SwitchToCardData(i);
			GangCardResult[1].cbCardCount = GangCardResult[1].cbCardCount + 1;
		end
	end

	--组合杠牌
	for i=1, cbWeaveCount do
		if WeaveItem[i].cbWeaveKind == GameLogic.WIK_PENG then
			if cbCardIndex[GameLogic.SwitchToCardIndex(WeaveItem[i].cbCenterCard)] == 1 then
				cbActionMask = bit:_or(cbActionMask, GameLogic.WIK_GANG)
				GangCardResult[1].cbCardData[GangCardResult[1].cbCardCount + 1] = WeaveItem[i].cbCenterCard;
				GangCardResult[1].cbCardCount = GangCardResult[1].cbCardCount + 1;
			end
		end
	end

	return cbActionMask
end

return GameLogic