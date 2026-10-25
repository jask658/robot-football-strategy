--desc: 
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

-- 计算两点之间的角度
local getAngle = function(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

-- 动态计算最佳接应位置
local calculateDynamicPosition = function(passerX, passerY, ballX, ballY)
    -- 计算传球者到球门的方向
    local goalX, goalY = 300, 0  -- 球门位置
    local goalAngle = getAngle(passerX, passerY, goalX, goalY)
    
    -- 计算传球者到球的方向
    local ballAngle = getAngle(passerX, passerY, ballX, ballY)
    
    -- 确定主要方向（球门方向和球方向的平均值）
    local mainAngle = (goalAngle + ballAngle) / 2
    
    -- 设置初始搜索区域参数
    local minDist = 40  -- 最小距离
    local maxDist = 150 -- 最大距离
    local angleRange = math.pi / 3  -- 60度范围
    
    -- 创建可行区域点集
    local candidatePoints = {}
    
    -- 在主要方向附近生成候选点
    for dist = minDist, maxDist, 20 do  -- 距离步长20cm
        for angleOffset = -angleRange, angleRange, math.pi/12 do  -- 角度步长15度
            local angle = mainAngle + angleOffset
            local x = passerX + dist * math.cos(angle)
            local y = passerY + dist * math.sin(angle)
            
            -- 只考虑前场位置（越靠前越好）
            if x > passerX then
                table.insert(candidatePoints, {x = x, y = y})
            end
        end
    end
    
    -- 如果没有候选点，使用默认位置
    if #candidatePoints == 0 then
        return passerX + minDist, passerY
    end
    
    -- 寻找最佳位置（路径畅通且最靠前）
    local bestPoint = candidatePoints[1]
    local bestScore = -math.huge
    
    for _, point in ipairs(candidatePoints) do
        local score = 0
        
        -- 决定性因素：路径是否畅通
        local pathClear = not isPathBlocked(ballX, ballY, point.x, point.y, 25)
        if pathClear then
            score = score + 1000  -- 畅通路径给予极高权重
        end
        
        -- 位置越靠前越好（x坐标越大越好）
        score = score + point.x * 0.5
        
        -- 远离敌方机器人
        for oppId = 0, 2 do
            local oppX = COppNum_x(oppId)
            local oppY = COppNum_y(oppId)
            local dist = math.sqrt((point.x - oppX)^2 + (point.y - oppY)^2)
            score = score + math.min(dist, 50) * 0.3
        end
        
        -- 与传球者保持合理距离
        local distToPasser = math.sqrt((point.x - passerX)^2 + (point.y - passerY)^2)
        if distToPasser < 40 then
            score = score - (40 - distToPasser) * 0.5
        elseif distToPasser > 120 then
            score = score - (distToPasser - 120) * 0.5
        else
            score = score + 20
        end
        
        -- 更新最佳位置
        if score > bestScore then
            bestScore = score
            bestPoint = point
        end
    end
    
    return bestPoint.x, bestPoint.y
end

-- 获取最佳位置函数（封装为适合任务调用的格式）
local getDynamicSupportPosition_x = function(passer, receiver)
    return function()
        local passerX = COurRole_x(passer)
        local passerY = COurRole_y(passer)
        local ballX = CGetBallX()
        local ballY = CGetBallY()
        
        local x, _ = calculateDynamicPosition(passerX, passerY, ballX, ballY)
        return x
    end
end

local getDynamicSupportPosition_y = function(passer, receiver)
    return function()
        local passerX = COurRole_x(passer)
        local passerY = COurRole_y(passer)
        local ballX = CGetBallX()
        local ballY = CGetBallY()
        
        local _, y = calculateDynamicPosition(passerX, passerY, ballX, ballY)
        return y
    end
end

-- 计算角色到角色的方向
local Role2RoleDir = function(role1, role2)
    return function()
        return COurRole2RoleDir(role1, role2)
    end
end

-- 测试状态机
gPlayTable.CreatePlay{
firstState = "kicker_get_ball",
["kicker_get_ball"] = {
    switch = function()
        local kickerX = COurRole_x("Kicker")
        local kickerY = COurRole_y("Kicker")
        -- 可以添加状态切换逻辑
        if CIsGetBall("Kicker") then
            return "kicker_pass_ball"
        elseif not isPathBlocked(kickerX, kickerY, 300, 0, 5) then
            return "kicker_shoot"
        end
    end,
    Kicker = task.KickerTask("getBall2"),

    Receiver = task.GotoPos(
        "Receiver", 
        getDynamicSupportPosition_x("Kicker", "Receiver"), 
        getDynamicSupportPosition_y("Kicker", "Receiver"), 
        Role2RoleDir("Receiver", "Kicker")
    ),
    
    Goalie = task.Goalie()
},
["kicker_pass_ball"] = {
    switch = function()
        -- 可以添加状态切换逻辑
        if CIsBallKick("Kicker") then
            return "receiver_receive_ball"
        end
    end,
    Kicker = task.KickerTask("chuanqiu7_7_20"),
    Receiver = task.GotoPos(
        "Receiver", 
        getDynamicSupportPosition_x("Kicker", "Receiver"), 
        getDynamicSupportPosition_y("Kicker", "Receiver"), 
        Role2RoleDir("Receiver", "Kicker")
    ),
    Goalie = task.Goalie()
},
["receiver_receive_ball"] = {
    switch = function()
        local receiverX = COurRole_x("Receiver")
        local receiverY = COurRole_y("Receiver")
        -- 可以添加状态切换逻辑
        if CIsGetBall("Receiver") then
            return "receiver_pass_ball"
        elseif not isPathBlocked(receiverX, receiverY, 300, 0, 5) then
            return "receiver_shoot"
        end
    end,
    Kicker = task.GotoPos(
        "Kicker", 
        getDynamicSupportPosition_x("Receiver", "Kicker"), 
        getDynamicSupportPosition_y("Receiver", "Kicker"), 
        Role2RoleDir("Kicker", "Receiver")
    ),
    Receiver = task.ReceiveBall('Receiver'),
    Goalie = task.Goalie()
},
["receiver_pass_ball"] = {
    switch = function()
        -- 可以添加状态切换逻辑
        if CIsBallKick("Receiver") then
            return "kicker_receive_ball"
        end
    end,
    Kicker = task.GotoPos(
        "Kicker", 
        getDynamicSupportPosition_x("Receiver", "Kicker"), 
        getDynamicSupportPosition_y("Receiver", "Kicker"), 
        Role2RoleDir("Kicker", "Receiver")
    ),
    Receiver = task.ReceiverTask("chuanqiu7_7_20"),
    Goalie = task.Goalie()
},
['kicker_receive_ball'] = {
    switch = function()
        local kickerX = COurRole_x("Kicker")
        local kickerY = COurRole_y("Kicker")
        -- 可以添加状态切换逻辑
        if CIsGetBall("Kicker") then
            return "kicker_pass_ball"
        elseif not isPathBlocked(kickerX, kickerY, 300, 0, 5) then
            return "kicker_shoot"
        end
    end,
    Kicker = task.GetBall("Kicker", "Kicker"),
    Receiver = task.GotoPos(
        "Receiver", 
        getDynamicSupportPosition_x("Kicker", "Receiver"), 
        getDynamicSupportPosition_y("Kicker", "Receiver"), 
        Role2RoleDir("Receiver", "Kicker")
    ),
    Goalie = task.Goalie()
},
['kicker_shoot'] = {
    switch = function()
        -- 可以添加状态切换逻辑
        if CIsBallKick("Kicker") then
            return "kicker_get_ball"
        end
    end,
    Kicker = task.KickerTask("shemen"),
    Receiver = task.ReceiverTask("stop1"),
    Goalie = task.Goalie()
},
['receiver_shoot'] = {
    switch = function()
        -- 可以添加状态切换逻辑
        if CIsBallKick("Receiver") then
            return "kicker_get_ball"
        end
    end,
    Kicker = task.KickerTask("stop1"),
    Receiver = task.ReceiverTask("shemen"),
    Goalie = task.Goalie()
},
name = "a_test"
}