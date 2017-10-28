--设置界面
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")
local cmd = appdf.req(appdf.GAME_SRC.."yule.sparrowzz.src.models.CMD_Game")

local GameEffectLayer = class("GameEffectLayer", cc.Layer)

GameEffectLayer.kGAME_TIP_BLANK = 1
GameEffectLayer.kGAME_TIP_OUTCARD = 2
GameEffectLayer.kGAME_TIP_WAIT = 3

--构造
function GameEffectLayer:ctor( parent )

    --加载csb资源
    local csbNode = ExternalFun.loadCSB("game/GameEffectLayer.csb", self)

    self.spGameTip = csbNode:getChildByName("game_tip")

end

--
function GameEffectLayer:showGameTip(tip)
    local pFrame = nil

    self:setVisible(true)

    if tip == GameEffectLayer.kGAME_TIP_BLANK then
        pFrame = cc.Sprite:create(cmd.RES_PATH.."game/blank.png"):getSpriteFrame()
    elseif  tip == GameEffectLayer.kGAME_TIP_OUTCARD then
        pFrame = cc.Sprite:create(cmd.RES_PATH.."game/sp_gametip_2.png"):getSpriteFrame()
    elseif  tip == GameEffectLayer.kGAME_TIP_WAIT then
        pFrame = cc.Sprite:create(cmd.RES_PATH.."game/sp_gametip_1.png"):getSpriteFrame()
    else
        pFrame = cc.Sprite:create(cmd.RES_PATH.."game/blank.png"):getSpriteFrame()
    end
    print("pFrame", pFrame)
    self.spGameTip:setSpriteFrame(pFrame)
end

function GameEffectLayer:reSet()
    self.spGameTip:setSpriteFrame(cc.Sprite:create(cmd.RES_PATH.."game/blank.png"):getSpriteFrame())
end

return GameEffectLayer