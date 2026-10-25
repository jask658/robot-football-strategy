--desc: 

local Receiver2Balldir = function()
	return function()
		return CRole2BallDir("Receiver")
	end
end
local Kicker2Balldir = function()
	return function()
		return CRole2BallDir("Kicker")
	end
end
local RobotPosX = function(role)
	return function()
		return COurRole_x(role)
	end
end
local RobotPosY = function(role)
	return function()
		return COurRole_y(role)
	end
end
-- 路径检测函数：检查两点之间是否有敌方机器人阻挡
-- 参数：startX, startY - 起点坐标
--       endX, endY - 终点坐标
--       threshold - 阻挡判定阈值（机器人半径）
-- 返回：true表示路径被阻挡，false表示畅通
local isPathBlocked = function(startX, startY, endX, endY, threshold)
    -- 计算路径向量
    local pathVecX = endX - startX
    local pathVecY = endY - startY
    local pathLength = math.sqrt(pathVecX^2 + pathVecY^2)
    
    -- 标准化向量
    if pathLength > 0 then
        pathVecX = pathVecX / pathLength
        pathVecY = pathVecY / pathLength
    end
    
    -- 检查每个敌方机器人
    for id = 0, 2 do  -- 假设有3个敌方机器人
        local oppX = COppNum_x(id)  -- 获取敌方位置 API
        local oppY = COppNum_y(id)  -- 获取敌方位置 API
        
        -- 计算敌方到路径的最短距离
        local toStartX = oppX - startX
        local toStartY = oppY - startY
        local dotProduct = toStartX * pathVecX + toStartY * pathVecY
        
        local distance
        if dotProduct < 0 then
            -- 敌方在起点后方
            distance = math.sqrt(toStartX^2 + toStartY^2)
        elseif dotProduct > pathLength then
            -- 敌方在终点后方
            local toEndX = oppX - endX
            local toEndY = oppY - endY
            distance = math.sqrt(toEndX^2 + toEndY^2)
        else
            -- 计算垂直距离
            local projectionX = startX + dotProduct * pathVecX
            local projectionY = startY + dotProduct * pathVecY
            distance = math.sqrt((oppX - projectionX)^2 + (oppY - projectionY)^2)
        end
        
        -- 如果距离小于阈值则判定为阻挡
        if distance < threshold then
            return true
        end
    end
    
    return false
end

local _getDynamicSupportPosition = function (passerX, passerY, ballX, ballY)
    -- 候选位置：传球者周围8个方向
    local positions = {
        {x = passerX + 50, y = passerY},      -- 右
        {x = passerX - 50, y = passerY},      -- 左
        {x = passerX, y = passerY + 50},      -- 上
        {x = passerX, y = passerY - 50},      -- 下
        {x = passerX + 40, y = passerY + 40}, -- 右上
        {x = passerX + 40, y = passerY - 40}, -- 右下
        {x = passerX - 40, y = passerY + 40}, -- 左上
        {x = passerX - 40, y = passerY - 40}  -- 左下
    }
    
    -- 最佳位置和分数
    local bestPos = {x = passerX, y = passerY}
    local bestScore = -math.huge
    
    for _, pos in ipairs(positions) do
        local score = 0
        
        -- 1. 与传球者距离评分 (理想距离40-60cm)
        local distToPasser = math.sqrt((pos.x - passerX)^2 + (pos.y - passerY)^2)
        if distToPasser > 60 then
            score = score - (distToPasser - 60) * 0.5
        elseif distToPasser < 40 then
            score = score - (40 - distToPasser) * 0.5
        else
            score = score + 20
        end
        
        -- 2. 球门方向评分 (位置越靠前分越高)
        local goalDist = math.sqrt((300 - pos.x)^2 + (0 - pos.y)^2)
        score = score + (300 - goalDist) * 0.2
        
        -- 3. 路径畅通评分
        if not isPathBlocked(ballX, ballY, pos.x, pos.y, 25) then
            score = score + 30
        end
        
        -- 4. 远离敌方评分
        -- for oppId = 0, 2 do
        --     local oppX = COppNum_x(oppId)
        --     local oppY = COppNum_y(oppId)
        --     local dist = math.sqrt((pos.x - oppX)^2 + (pos.y - oppY)^2)
        --     score = score + math.min(dist, 50) * 0.3
        -- end
        
        -- 更新最佳位置
        if score > bestScore then
            bestScore = score
            bestPos = pos
        end
    end
    return bestPos
end

local getDynamicSupportPosition_x = function(passer, receiver)
    return function()
            -- 获取传球者位置
        local passerX = COurRole_x(passer)  -- 获取传球者位置
        local passerY = COurRole_y(passer)
        local ballX = CGetBallX()  -- 获取球位置
        local ballY = CGetBallY()

        local bestPos = _getDynamicSupportPosition(passerX, passerY, ballX, ballY) -- 获取最佳位置
        return bestPos.x
    end
end

local getDynamicSupportPosition_y = function(passer, receiver)
    return function()
            -- 获取传球者位置
        local passerX = COurRole_x(passer)  -- 获取传球者位置
        local passerY = COurRole_y(passer)
        local ballX = CGetBallX()  -- 获取球位置
        local ballY = CGetBallY()

        local bestPos = _getDynamicSupportPosition(passerX, passerY, ballX, ballY) -- 获取最佳位置
        return bestPos.y
    end
end

gPlayTable.CreatePlay{
firstState = "init",

["init"] = {
    switch = function()
        if CBall2RoleDist("Kicker") < 20 then
            return "kicker_with_ball"
        elseif CBall2RoleDist("Receiver") < 20 then
            return "receiver_with_ball"
        else
            return "get_ball"
        end
    end,
    Kicker  = task.GotoPos("Kicker", CGetBallX(), CGetBallY(), Kicker2Balldir()),
    Receiver = task.GotoPos("Receiver", 100, 0, Receiver2Balldir()),
    Goalie = task.Goalie()
},

["get_ball"] = {
    switch = function()
        if CBall2RoleDist("Kicker") < 20 then
            return "kicker_with_ball"
        elseif CBall2RoleDist("Receiver") < 20 then
            return "receiver_with_ball"
        end
    end,
    Kicker  = task.KickerTask("getBall2"),
    -- Receiver = task.GotoPos("Receiver",  CGetBallX() - 40,  CGetBallY(), Receiver2Balldir()),
    Goalie = task.Goalie()
},

["kicker_with_ball"] = {
    switch = function()
        local kickerX = COurRole_x("Kicker")
        local kickerY = COurRole_y("Kicker")
        
        -- 检查射门机会
        if not isPathBlocked(kickerX, kickerY, 300, 0, 25) then
            return "shoot_kicker"
        end
        
        -- 检查传球机会
        local receiverX = COurRole_x("Receiver")
        local receiverY = COurRole_y("Receiver")
        if not isPathBlocked(kickerX, kickerY, receiverX, receiverY, 25) then
            return "pass_to_receiver"
        end
        
        -- 路径被阻挡，需要调整位置
        return "reposition_kicker"
    end,
    Kicker = task.KickerTask("getBall2"),
    -- Receiver = function()
    --     local x, y = getDynamicSupportPosition("Kicker", "Receiver")
    --     return task.GotoPos("Receiver", x, y, Receiver2Balldir())
    -- end,
    Receiver = task.GotoPos("Receiver", getDynamicSupportPosition_x("Kicker", "Receiver"), getDynamicSupportPosition_y("Kicker", "Receiver"), Receiver2Balldir()),
    Goalie = task.Goalie()
},

["receiver_with_ball"] = {
    switch = function()
        local receiverX = COurRole_x("Receiver")
        local receiverY = COurRole_y("Receiver")
        
        -- 检查射门机会
        if not isPathBlocked(receiverX, receiverY, 300, 0, 25) then
            return "shoot_receiver"
        end
        
        -- 检查传球机会
        local kickerX = COurRole_x("Kicker")
        local kickerY = COurRole_y("Kicker")
        if not isPathBlocked(receiverX, receiverY, kickerX, kickerY, 25) then
            return "pass_to_kicker"
        end
        
        -- 路径被阻挡，需要调整位置
        return "reposition_receiver"
    end,
    Receiver = task.KickerTask("getBall2"),
    -- Kicker = function()
    --     local x, y = getDynamicSupportPosition("Receiver", "Kicker")
    --     return task.GotoPos("Kicker", x, y, Kicker2Balldir())
    -- end,
    Kicker = task.GotoPos("Kicker", getDynamicSupportPosition_x("Receiver", "Kicker"), getDynamicSupportPosition_y("Receiver", "Kicker"), Kicker2Balldir()),
    Goalie = task.Goalie()
},

["pass_to_receiver"] = {
    switch = function()
        if CIsBallKick("Kicker") then
            return "receiving_pass_receiver"
        end
        
        -- 超时或丢球
        if CBall2RoleDist("Kicker") > 35 then
            return "init"
        end
    end,
    Kicker = task.KickerTask("passball"),
    Receiver = task.GotoPos("Receiver",RobotPosX("Receiver"),RobotPosY("Receiver"),Receiver2Balldir()),
    Goalie = task.Goalie()
},

["pass_to_kicker"] = {
    switch = function()
        if CIsBallKick("Receiver") then
            return "receiving_pass_kicker"
        end
        
        -- 超时或丢球
        if  CBall2RoleDist("Receiver") > 35 then
            return "init"
        end
        
        return "pass_to_kicker"
    end,
    Receiver = task.ReceiverTask("passball"),
    Kicker = task.GotoPos("Kicker",RobotPosX("Kicker"),RobotPosY("Kicker"),Kicker2Balldir()),
    Goalie = task.Goalie()
},

["receiving_pass_receiver"] = {
    switch = function()
        if CBall2RoleDist("Receiver") < 15 then
            return "receiver_with_ball"
        end
        
        -- -- 超时处理
        -- if Cbuf_cnt(true, 50) then
        --     return "init"
        -- end
        
        return "receiving_pass_receiver"
    end,
    -- Kicker = function()
    --     -- Kicker 在传球后调整位置
    --     local x, y = getDynamicSupportPosition("Receiver", "Kicker")
    --     return task.GotoPos("Kicker", x, y, Kicker2Balldir())
    -- end,
    Kicker = task.GotoPos("Kicker", getDynamicSupportPosition_x("Receiver", "Kicker"), getDynamicSupportPosition_y("Receiver", "Kicker"), Kicker2Balldir()),
    Receiver = task.ReceiverTask("receive"),
    Goalie = task.Goalie()
},

["receiving_pass_kicker"] = {
    switch = function()
        if CBall2RoleDist("Kicker") < 15 then
            return "kicker_with_ball"
        end
        
        -- -- 超时处理
        -- if Cbuf_cnt(true, 50) then
        --     return "init"
        -- end
        
        return "receiving_pass_kicker"
    end,
    Kicker = task.KickerTask("receive"),
    -- Receiver = function()
    --     -- Receiver 在传球后调整位置
    --     local x, y = getDynamicSupportPosition("Kicker", "Receiver")
    --     return task.GotoPos("Receiver", x, y, Receiver2Balldir())
    -- end,
    Receiver = task.GotoPos("Receiver", getDynamicSupportPosition_x("Kicker", "Receiver"), getDynamicSupportPosition_y("Kicker", "Receiver"), Receiver2Balldir()),
    Goalie = task.Goalie()
},

["reposition_kicker"] = {
    switch = function()
        local kickerX = COurRole_x("Kicker")
        local kickerY = COurRole_y("Kicker")
        local receiverX = COurRole_x("Receiver")
        local receiverY = COurRole_y("Receiver")
        
        -- 检查传球机会
        if not isPathBlocked(kickerX, kickerY, receiverX, receiverY, 25) then
            return "pass_to_receiver"
        end
        
        -- 检查射门机会
        if not isPathBlocked(kickerX, kickerY, 300, 0, 25) then
            return "shoot_kicker"
        end
        
        -- -- 超时处理
        -- if Cbuf_cnt(true, 50) then
        --     return "init"
        -- end
        
        return "reposition_kicker"
    end,
    Kicker = task.KickerTask("getBall2"),
    -- Receiver = function()
    --     local x, y = getDynamicSupportPosition("Kicker", "Receiver")
    --     return task.GotoPos("Receiver", x, y, Receiver2Balldir())
    -- end,
    Receiver = task.GotoPos("Receiver", getDynamicSupportPosition_x("Kicker", "Receiver"), getDynamicSupportPosition_y("Kicker", "Receiver"), Receiver2Balldir()),
    Goalie = task.Goalie()
},

["reposition_receiver"] = {
    switch = function()
        local receiverX = COurRole_x("Receiver")
        local receiverY = COurRole_y("Receiver")
        local kickerX = COurRole_x("Kicker")
        local kickerY = COurRole_y("Kicker")
        
        -- 检查传球机会
        if not isPathBlocked(receiverX, receiverY, kickerX, kickerY, 25) then
            return "pass_to_kicker"
        end
        
        -- 检查射门机会
        if not isPathBlocked(receiverX, receiverY, 300, 0, 25) then
            return "shoot_receiver"
        end
        
        -- 超时处理
        if Cbuf_cnt(true, 50) then
            return "init"
        end
        
        return "reposition_receiver"
    end,
    Receiver = task.KickerTask("getBall2"),
    -- Kicker = function()
    --     local x, y = getDynamicSupportPosition("Receiver", "Kicker")
    --     return task.GotoPos("Kicker", x, y, Kicker2Balldir())
    -- end,
    Kicker = task.GotoPos("Kicker", getDynamicSupportPosition_x("Receiver", "Kicker"), getDynamicSupportPosition_y("Receiver", "Kicker"), Kicker2Balldir()),
    Goalie = task.Goalie()
},

["shoot_kicker"] = {
    switch = function()
        if CIsBallKick("Kicker") then
            return "init"
        end
        
        if Cbuf_cnt(true, 30) then
            return "kicker_with_ball"
        end
        
        return "shoot_kicker"
    end,
    Kicker = task.KickerTask("shoot"),
    -- Receiver = function()
    --     local x, y = getDynamicSupportPosition("Kicker", "Receiver")
    --     return task.GotoPos("Receiver", x, y, Receiver2Balldir())
    -- end,
    Receiver = task.GotoPos("Receiver", getDynamicSupportPosition_x("Kicker", "Receiver"), getDynamicSupportPosition_y("Kicker", "Receiver"), Receiver2Balldir()),
    Goalie   = task.Goalie()
},

["shoot_receiver"] = {
    switch = function()
        if CIsBallKick("Receiver") then
            return "init"
        end
        
        if Cbuf_cnt(true, 30) then
            return "receiver_with_ball"
        end
        
        return "shoot_receiver"
    end,
    Receiver = task.ReceiverTask("shoot"),
    -- Kicker = function()
    --     local x, y = getDynamicSupportPosition("Receiver", "Kicker")
    --     return task.GotoPos("Kicker", x, y, Kicker2Balldir())
    -- end,
    Kicker = task.GotoPos("Kicker", getDynamicSupportPosition_x("Receiver", "Kicker"), getDynamicSupportPosition_y("Receiver", "Kicker"), Kicker2Balldir()),
    Goalie  = task.Goalie() 
},

["defense"] = {
    switch = function()
        if CIsGetBall("Kicker") then
            return "kicker_with_ball"
        elseif CIsGetBall("Receiver") then
            return "receiver_with_ball"
        end
    end,
    Kicker   = task.KickerTask("def_receiver"),
    Receiver = task.ReceiverTask("def_kicker"),
    Goalie   = task.Goalie() 
},

name = "a_normalplay"
}