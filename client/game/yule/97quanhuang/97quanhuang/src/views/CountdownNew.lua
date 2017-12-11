--写一个倒计时类  

local Countdown1 = class("Countdown1")  

Countdown1.__index = Countdown1  

Countdown1.hour = nil   --小时  
Countdown1.minute = nil --分钟  
Countdown1.second = nil --秒钟  
Countdown1.func = nil  
Countdown1.showtype = true  
function Countdown1.create(scene) 

    local label = Countdown1.new()  
    return label  
end  


function Countdown1.ctor()  
    Countdown1.winsize = cc.Director:getInstance():getWinSize()  
    Countdown1.scheduler = cc.Director:getInstance():getScheduler()  
    Countdown1.schedulerID = nil  
    print("输出======Countdown1.ctor()=========")  
    print("倒计时进行中。。。。")  
end  
--设置倒计时到00:00:00时调用这个函数，传入的参数是一个函数  
function Countdown1.function_(f)    
    Countdown1.func = f      
end  

function Countdown1.settime(hour,minute,second)  
    Countdown1.hour = hour   --小时  
    Countdown1.minute = minute --分钟  d
    Countdown1.second = second --秒钟  
end  

function Countdown1.gettime()  
    return Countdown1.hour,Countdown1.minute,Countdown1.second  
end  



function Countdown1.add_0()  
    --将int类型转换为string类型  
    Countdown1.hour   = tostring(Countdown1.hour)  
    Countdown1.minute = Countdown1.minute .. ""  
    Countdown1.second = Countdown1.second .. ""  

    --当显示数字为个位数是，前位用补上  
    if string.len(Countdown1.hour) == 1 then   
        Countdown1.hour = "0" .. Countdown1.hour  
    end  

    if string.len(Countdown1.minute) == 1 then  
        Countdown1.minute = "0" .. Countdown1.minute  
    end  

    if string.len(Countdown1.second) == 1 then  
        Countdown1.second = "0" .. Countdown1.second  
    end  
end  

--创建一个Label，传入x，y坐标  
function Countdown1.Showlabel(x,y,r,g,b)  
    --Countdown1.time如果不等于空，就先remove掉  
    if Countdown1.time ~= nil then  
        Countdown1.time:getParent():removeChild(Countdown1.time,true)  
        Countdown1.time = nil  
    end    
    --创建时间标签用以显示   
    Countdown1.time = cc.LabelAtlas:_create(Countdown1.second, "Game1_Terrace/Small/View/anger/1.png",  70, 96, string.byte("0"))     -- 代码问题          
    Countdown1.time:setPosition(cc.p(x , y))  --Countdown1.winsize.width/2,Countdown1.winsize.height/2

    return Countdown1.time  
end  


--倒计时更新函数  
function Countdown1.anticlockwiseUpdate(time)  
--    Countdown1.second = Countdown1.second -1    
--加上tonumber也可以，如下面，不加也可以，lua有这个功能的  
    Countdown1.second = tonumber(Countdown1.second) -1   

    if Countdown1.second == -1 then  
        if Countdown1.minute ~= -1 or Countdown1.hour ~= -1 then  
            Countdown1.minute = Countdown1.minute - 1  
            Countdown1.second = 59  
            if Countdown1.minute == -1 then  
                if Countdown1.hour ~= -1 then  
                    Countdown1.hour = Countdown1.hour - 1  
                    Countdown1.minute = 59  

                    if Countdown1.hour == -1 then  
                        --倒计时结束停止更新  
                        if Countdown1.schedulerID ~= nil then  
                            Countdown1.scheduler:unscheduleScriptEntry(Countdown1.schedulerID)  
                            Countdown1.schedulerID = nil  

                        end  
                        Countdown1.second = 0  
                        Countdown1.minute = 0  
                        Countdown1.hour = 0  
                        --Countdown1.time:setColor(cc.c3b(0,255,0)) --以绿色标识结束  
                        Countdown1.func()  --倒计时为0时，调用这个函数  

                    end  

                end  
            end  
        end  
    end  

    Countdown1.second = tostring(Countdown1.second)  
    Countdown1.minute = tostring(Countdown1.minute)  
    Countdown1.hour = tostring(Countdown1.hour)  

    if string.len(Countdown1.second) == 1 then  
        Countdown1.second = "0" .. Countdown1.second  
    end  

    if string.len(Countdown1.minute) == 1 then  
        Countdown1.minute = "0" .. Countdown1.minute  

    end  

    if string.len(Countdown1.hour) == 1 then  
        Countdown1.hour = "0" .. Countdown1.hour  
    end  
    if Countdown1.showtype == true then  
        Countdown1.time:setString("倒计时：" .. Countdown1.hour ..":".. Countdown1.minute ..":".. Countdown1.second)  
    elseif Countdown1.showtype == false then  
        if time == 1 then
             Countdown1.time:setString(Countdown1.second)--  秒钟
        elseif time == 2 then
             Countdown1.time:setString(Countdown1.second)--  秒钟
        end
    end    
end  

--倒计时刷新函数  
function Countdown1.scheduleFunc(num)  
    --隔一秒刷新这个函数  
    if num == 1 then
        Countdown1.schedulerID = Countdown1.scheduler:scheduleScriptFunc(Countdown1.anticlockwiseUpdate,1,false)    
    elseif num == 2 then
        Countdown1.schedulerID = Countdown1.scheduler:scheduleScriptFunc(Countdown1.anticlockwiseUpdate,2,false)
    end
end  

--移除这个刷新函数  
function Countdown1.remove_scheduler()  
    if Countdown1.schedulerID ~= nil then  
        Countdown1.scheduler:unscheduleScriptEntry(Countdown1.schedulerID)  
        Countdown1.schedulerID = nil  
        
        Countdown1.time:removeFromParent()
        Countdown1.time = nil
    end  
end  

--重设  
function Countdown1.reset(hour,minute,second)  
    Countdown1.remove_scheduler()      
    Countdown1.hour = hour   --小时  
    Countdown1.minute = minute --分钟  
    Countdown1.second = second --秒钟  
    Countdown1.scheduleFunc(1)  
end  

function Countdown1.remove_hour(index)  
    if Countdown1.time ~= nil then      
            --设为分钟:秒 如09:11  
            Countdown1.time:setString( Countdown1.second)   
            Countdown1.showtype = false  
    end          
end  

return Countdown1  