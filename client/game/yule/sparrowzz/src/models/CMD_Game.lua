local cmd =  {}

cmd.RES_PATH 								= "game/yule/sparrowzz/res/"
--游戏版本
cmd.VERSION 								= appdf.VersionValue(6,7,0,1)

--游戏属性
cmd.KIND_ID									= 386                          				--游戏 I D

--组件属性
cmd.zhzmj_GAME_PLAYER						= 4                           				--游戏人数

--视图位置(1~4)
cmd.MY_VIEWID								= 1
cmd.RIGHT_VIEWID							= 2
cmd.LEFT_VIEWID								= 3
cmd.TOP_VIEWID								= 4

---------------------------------------------------------------------------------------------------

--状态定义
cmd.zhzmj_GAME_SCENE_FREE					= 0											--等待开始
cmd.zhzmj_GAME_SCENE_PLAY					= 100										--游戏进行

--常量定义
cmd.zhzmj_MAX_WEAVE							= 4											--最大组合
cmd.zhzmj_MAX_INDEX							= 34										--最大索引
cmd.zhzmj_MAX_COUNT							= 14										--最大数目
cmd.zhzmj_MAX_REPERTORY						= 136										--最大库存
cmd.zhzmj_MAX_HUA_CARD						= 0											--花牌个数

--扑克定义
cmd.zhzmj_HEAP_FULL_COUNT					= 34										--堆立全牌

cmd.zhzmj_MAX_RIGHT_COUNT				 	= 1											--最大权位DWORD个数

-- 语音动画
cmd.VOICE_ANIMATION_KEY = "voice_ani_key"

cmd.IDI_START_GAME							= 201										--开始定时器
cmd.IDI_OUT_CARD							= 202										--出牌定时器
cmd.IDI_OPERATE_CARD						= 203										--操作定时器

--组合子项
cmd.tagWeaveItem = 
{
	{k = "cbWeaveKind", t = "byte"},													--组合类型
	{k = "cbCenterCard", t = "byte"},													--中心扑克
 	{k = "cbPublicCard", t = "byte"},													--公开标志
 	{k = "wProvideUser", t = "word"},													--供应用户
 	{k = "cbCardData", t = "byte", l = {4}},											--组合数据
}

cmd.USERACHIEVEMENT = 
{
	{k = "dwUserID", t = "dword"},														--UserID
	{k = "dwGameID", t = "dword"},														--GameID
	{k = "cbZiMO", t = "byte"},															--自摸
	{k = "cbJiePao", t = "byte"},														--接炮
	{k = "cbDianPao", t = "byte"},														--点炮
	{k = "cbMingGang", t = "byte"},														--明杠
	{k = "cbAnGang", t = "byte"},														--暗杠					
}

---------------------------------------------------------------------------------------------------

--服务器命令结构
cmd.zhzmj_SUB_S_GAME_START					= 100										--游戏开始
cmd.zhzmj_SUB_S_OUT_CARD					= 101										--出牌命令
cmd.zhzmj_SUB_S_SEND_CARD					= 102										--发送扑克
cmd.zhzmj_SUB_S_OPERATE_NOTIFY				= 104										--操作提示
cmd.zhzmj_SUB_S_OPERATE_RESULT				= 105										--操作命令
cmd.zhzmj_SUB_S_GAME_END					= 106										--游戏结束
cmd.zhzmj_SUB_S_TRUSTEE						= 107										--用户托管							

--游戏空闲状态
cmd.CMD_S_StatusFree = 
{
	{k = "bHongZhong", t = "bool"},														--红中赖子

	{k = "lCellScore", t = "score"},													--基础金币
	{k = "wBankerUser", t = "word"},													--庄家用户
	{k = "bTrustee", t = "bool", l = {cmd.zhzmj_GAME_PLAYER}},							--是否托管

    --历史积分
    {k = "lTurnScore", t = "score", l = {cmd.zhzmj_GAME_PLAYER}},						--积分信息
	{k = "lCollectScore", t = "score", l = {cmd.zhzmj_GAME_PLAYER}},					--积分信息
}

--游戏进行状态
cmd.CMD_S_StatusPlay = 
{
    --游戏配置
    {k = "bHongZhong", t = "bool"},														--红中赖子
    {k = "bQiDui", t = "bool"},															--可胡七对

    --游戏变量
    {k = "lCellScore", t = "score"},													--单元积分
    {k = "wBankerUser", t = "word"},													--庄家用户
    {k = "wCurrentUser", t = "word"},													--当前用户

	--状态变量
	{k = "cbActionCard", t = "byte"},													--动作扑克
	{k = "cbActionMask", t = "byte"},													--动作掩码
	{k = "cbLeftCardCount", t = "byte"},												--剩余数目
	{k = "bTrustee", t = "bool", l = {cmd.zhzmj_GAME_PLAYER}},							--是否托管

    --出牌信息
    {k = "wOutCardUser", t = "word"},													--出牌用户
    {k = "cbOutCardData", t = "byte"},													--出牌扑克
 	{k = "cbDiscardCount", t = "byte", l = {cmd.zhzmj_GAME_PLAYER}},					--丢弃数目			
 	{k = "cbDiscardCard", t = "byte", l = {60, 60, 60, 60}},							--丢弃记录						--出牌扑克
    
    --扑克数据
    {k = "cbCardCount", t = "byte"},													--扑克数目
	{k = "cbCardData", t = "byte", l = {cmd.zhzmj_MAX_COUNT}},							--扑克列表
	{k = "cbSendCardData", t = "byte"},													--发送扑克
    {k = "cbCardIndex", t = "byte", l = {34, 34, 34, 34}},								--用户扑克

    --组合扑克
    {k = "cbWeaveCount", t = "byte", l = {cmd.zhzmj_GAME_PLAYER}},						--组合数目
    {k = "WeaveItemArray", t = "table", d = cmd.tagWeaveItem, l = {4, 4, 4, 4}},		--组合扑克

	--堆立信息
	{k = "wHeapHead", t = "word"},														--堆立头部
	{k = "wHeapTail", t = "word"},														--堆立尾部
	{k = "cbHeapCardInfo", t = "byte", l = {2, 2, 2, 2}},								--堆牌信息
    
    --历史积分
    {k = "lTurnScore", t = "score", l = {cmd.zhzmj_GAME_PLAYER}},						--积分信息
    {k = "lCollectScore", t = "score", l = {cmd.zhzmj_GAME_PLAYER}},					--积分信息
}

--游戏开始
cmd.CMD_S_GameStart = 
{
    --游戏配置
    {k = "bHongZhong", t = "bool"},														--红中赖子
    {k = "bQiDui", t = "bool"},															--可胡七对

    {k = "wBankerUser", t = "word"},													--庄家用户
    {k = "wCurrentUser", t = "word"},													--当前用户
    {k = "cbUserAction", t = "byte"},													--用户动作
	{k = "cbLianZhuangCount", t = "byte"},												--连庄计数
	{k = "cbCardData", t = "byte", l = {cmd.zhzmj_MAX_COUNT * cmd.zhzmj_GAME_PLAYER}},	--扑克列表											--连庄计数

 	--堆立信息
	{k = "wHeapHead", t = "word"},														--堆立头部
	{k = "wHeapTail", t = "word"},														--堆立尾部
	{k = "cbHeapCardInfo", t = "byte", l = {2, 2, 2, 2}},								--堆牌信息
   	
   	{k = "cbLeftCardCount", t = "byte"},												--剩余数目
    
    --骰子
    {k = "cbSick", t = "byte", l = {2}},												--骰子
}

--出牌命令
cmd.CMD_S_OutCard = 
{
	{k = "wOutCardUser", t = "word"},													--出牌用户
    {k = "cbOutCardData", t = "byte"},													--出牌扑克
}

--发送扑克
cmd.CMD_S_SendCard = 
{
	{k = "cbCardData", t = "byte"},														--扑克数据
	{k = "cbActionMask", t = "byte"},													--动作掩码
   
	{k = "wCurrentUser", t = "word"},													--当前用户
	{k = "wSendCardUser", t = "word"},													--发牌用户

	{k = "bTail", t = "bool"},															--末尾发牌
	{k = "cbLeftCardCount", t = "byte"},												--剩余数目
}

--操作提示
cmd.CMD_S_OperateNotify = 
{
	{k = "wProvideUser", t = "word"},
	{k = "wResumeUser", t = "word"},													--还原用户
	{k = "cbActionMask", t = "byte"},													--动作掩码
	{k = "cbActionCard", t = "byte"},													--动作扑克
	{k = "wCurrentUser", t = "word"},													--当前玩家

}

--操作命令
cmd.CMD_S_OperateResult = 
{
	{k = "wOperateUser", t = "word"},													--操作用户
	{k = "cbActionMask", t = "byte"},													--动作掩码
	{k = "wProvideUser", t = "word"},													--供应用户
	{k = "cbOperateCode", t = "byte"},													--操作代码
	{k = "cbOperateCard", t = "byte", l = {3}},											--操作扑克
}

--游戏结束
cmd.CMD_S_GameEnd = 
{
	{k = "lGameTax", t = "score"},														--游戏税收

    --结束信息
    {k = "wProvideUser", t = "word"},													--供应用户
	{k = "cbProvideCard", t = "byte"},													--供应扑克
	{k = "dwChiHuKind", t = "dword", l = {cmd.zhzmj_GAME_PLAYER}},						--胡牌类型
	{k = "dwChiHuRight", t = "dword", l = {1, 1, 1, 1}},	
	{k = "cbChiHuType", t = "byte"},													--当前吃胡类型
	{k = "wCurrentIdx", t = "word"},													--当前吃胡ChairID
    
    --积分信息
    {k = "lGameScore", t = "score", l = {cmd.zhzmj_GAME_PLAYER}},						--游戏积分
    {k = "lGangScore", t = "score", l = {cmd.zhzmj_GAME_PLAYER}},						--杠牌得分

    --扑克信息
    {k = "cbCardCount", t = "byte", l = {cmd.zhzmj_GAME_PLAYER}},						--扑克数目
    {k = "cbCardData", t = "byte", l = {14, 14, 14, 14}},								--扑克数据
    
    {k = "wLeftUser", t = "word"},														--玩家逃跑
    {k = "bZhuaNiao", t = "bool"},														--捉鸟标识
    {k = "cbZhuaNiaoCardArray", t = "byte", l = {6}},									--最多抓6鸟
    {k = "lGangCount", t = "score", l = {cmd.zhzmj_GAME_PLAYER}},						--杠牌次数
}

--用户托管
cmd.CMD_S_Trustee = 
{
	{k = "bTrustee", t = "bool"},														--是否托管
	{k = "wChairID", t = "word"},														--托管用户
}

---------------------------------------------------------------------------------------------------

--客户端命令结构
cmd.zhzmj_SUB_C_OUT_CARD					= 1											--出牌命令
cmd.zhzmj_SUB_C_OPERATE_CARD				= 3											--操作扑克
cmd.zhzmj_SUB_C_TRUSTEE				    	= 4											--用户托管

--出牌命令
cmd.CMD_C_OutCard = 
{
	{k = "cbCardData", t = "byte"},														--扑克数据
}

--操作命令
cmd.CMD_C_OperateCard = 
{
	{k = "cbOperateCode", t = "byte"},													--操作代码
	{k = "cbOperateCard", t = "byte", l = {3}},											--操作扑克
}

--用户托管
cmd.CMD_C_Trustee = 
{
 	{k = "bTrustee", t = "bool"},														--是否托管
}

return cmd