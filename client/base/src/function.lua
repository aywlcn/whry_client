--region *.lua
--Date
--此文件由[BabeLua]插件自动生成



--endregion

-- add by wss

function getChildFormObject(obj , childName)
    local childrenTable = obj:getChildren()

    for k,v in pairs(childrenTable) do
        if v:getName() == childName then
            return v
        else
            local child = getChildFormObject(v , childName)
            if child then
                return child
            end
        end
    end
    return nil
end

