--desc: 
-- local Kickerdir2Tierdir = function()
-- 	return COurRole2RoleDir("Kicker", "Tier")
-- end

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


local opp2ball = function(id)
	local ball_x = CGetBallX()
	local ball_y = CGetBallY()
	local opp_x = COppNum_x(id)
	local opp_y = COppNum_y(id)
	return math.sqrt((ball_x - opp_x)^2 + (ball_y - opp_y)^2)
end
-- local Receiver2Kickerdir = function()
-- 	return COurRole2RoleDir("Receiver", "Kicker")
-- end

-- local Kickerdir2Receiverdir = function()
-- 	return COurRole2RoleDir("Kicker", "Receiver")
-- end

-- local Tierdir2Receiverdir = function()
-- 	return COurRole2RoleDir("Tier", "Receiver")
-- end
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

-- 动态选择接应位置
-- 参数：passer - 传球者角色名
--       receiver - 接球者角色名
local getDynamicSupportPosition = function(passer, receiver)
    local passerX = COurRole_x(passer)  -- 获取传球者位置
    local passerY = COurRole_y(passer)
    local ballX = CGetBallX()  -- 获取球位置
    local ballY = CGetBallY()
    
    -- 候选位置：传球者周围8个方向
    local positions = {
        {x = passerX + 40, y = passerY},      -- 右
        {x = passerX - 40, y = passerY},      -- 左
        {x = passerX, y = passerY + 40},      -- 上
        {x = passerX, y = passerY - 40},      -- 下
        {x = passerX + 30, y = passerY + 30}, -- 右上
        {x = passerX + 30, y = passerY - 30}, -- 右下
        {x = passerX - 30, y = passerY + 30}, -- 左上
        {x = passerX - 30, y = passerY - 30}  -- 左下
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
        for oppId = 0, 2 do
            local oppX = COppNum_x(oppId)
            local oppY = COppNum_y(oppId)
            local dist = math.sqrt((pos.x - oppX)^2 + (pos.y - oppY)^2)
            score = score + math.min(dist, 50) * 0.3
        end
        
        -- 更新最佳位置
        if score > bestScore then
            bestScore = score
            bestPos = pos
        end
    end
    
    return bestPos.x, bestPos.y
end

local getBallHolder = function ()
	if CIsGetBall("Kicker") then
		return "Kicker"
	elseif CIsGetBall("Receiver") then
		return "Receiver"
	end	
	return nil
end
gPlayTable.CreatePlay{
firstState = "start",

["start"] = {
    switch = function()
        -- 检查射门机会
        -- if not isPathBlocked(holderX, holderY, 300, 0, 25) then
        --     return "shoot"
        -- if CBall2RoleDist("Kicker")<25 then
        --     return "passball"
        -- end
		if CIsGetBall("Kicker") then
            return "passball"
        end
    end,
    Kicker  = task.KickerTask("getBall2"),
    Receiver = function()
        -- 初始位置：Kicker后方
        local kickerX = COurRole_x("Kicker")
        local kickerY = COurRole_y("Kicker")
        return task.GotoPos("Receiver", kickerX - 40, kickerY, Receiver2Balldir())
    end,
},

["passball"] = {
    switch = function()
        local holder = getBallHolder()
        if not holder then return "start" end
        
        local holderX = COurRole_x(holder)
        local holderY = COurRole_y(holder)
        local receiver = (holder == "Kicker") and "Receiver" or "Kicker"
        local receiverX = COurRole_x(receiver)
        local receiverY = COurRole_y(receiver)
        
        -- 检查射门机会
        if not isPathBlocked(holderX, holderY, 300, 0, 25) then
            return "shoot"
        end
        
        -- 检查传球路径
        if not isPathBlocked(holderX, holderY, receiverX, receiverY, 25) then
            return "execute_pass"
        end
        
        -- 路径被阻挡，需要调整位置
        return "reposition"
    end,
    Kicker = function()
        local holder = getBallHolder()
        if holder == "Kicker" then
            return task.KickerTask("getBall2")  -- 保持控球
        else
            -- 如果Receiver持球，Kicker变为接应者
            return task.GotoPos("Kicker", RobotPosX("Kicker"), RobotPosY("Kicker"), Kicker2Balldir())
        end
    end,
    Receiver = function()
        local holder = getBallHolder()
        if holder == "Receiver" then
            return task.KickerTask("getBall2")  -- 保持控球
        else
            -- 如果Kicker持球，Receiver保持位置
            return task.GotoPos("Receiver", RobotPosX("Receiver"), RobotPosY("Receiver"), Receiver2Balldir())
        end
    end
},

["reposition"] = {
    switch = function()
        local holder = getBallHolder()
        if not holder then return "start" end
        
        local receiver = (holder == "Kicker") and "Receiver" or "Kicker"
        local holderX = COurRole_x(holder)
        local holderY = COurRole_y(holder)
        local receiverX = COurRole_x(receiver)
        local receiverY = COurRole_y(receiver)
        
        -- 检查射门机会
        if not isPathBlocked(holderX, holderY, 300, 0, 25) then
            return "shoot"
        end
        
        -- 检查新位置是否畅通
        if not isPathBlocked(holderX, holderY, receiverX, receiverY, 25) then
            return "execute_pass"
        end
        
        -- 超时返回
        if Cbuf_cnt(true, 50) then
            return "start"
        end
        
        return "reposition"
    end,
    Kicker = function()
        local holder = getBallHolder()
        if holder == "Kicker" then
            return task.KickerTask("getBall2")  -- 保持控球
        else
            -- Kicker作为接应者，重新选择位置
            local passer = "Receiver"
            local x, y = getDynamicSupportPosition(passer, "Kicker")
            return task.GotoPos("Kicker", x, y, Kicker2Balldir())
        end
    end,
    Receiver = function()
        local holder = getBallHolder()
        if holder == "Receiver" then
            return task.KickerTask("getBall2")  -- 保持控球
        else
            -- Receiver作为接应者，重新选择位置
            local passer = "Kicker"
            local x, y = getDynamicSupportPosition(passer, "Receiver")
            return task.GotoPos("Receiver", x, y, Receiver2Balldir())
        end
    end
},


["execute_pass"] = {
    switch = function()
        local holder = getBallHolder()
        if not holder then return "start" end
        
        if CIsBallKick(holder) then
            return "receive"
        end
        
        -- 超时或丢球
        if Cbuf_cnt(true, 30) or CBall2RoleDist(holder) > 20 then
            return "start"
        end
        
        return "execute_pass"
    end,
    Kicker = function()
        local holder = getBallHolder()
        if holder == "Kicker" then
            local receiver = "Receiver"
            local receiverX = COurRole_x(receiver)
            local receiverY = COurRole_y(receiver)
            return task.KickerTask("passball", receiverX, receiverY)
        else
            return task.GotoPos("Kicker", RobotPosX("Kicker"), RobotPosY("Kicker"), Kicker2Balldir())
        end
    end,
    Receiver = function()
        local holder = getBallHolder()
        if holder == "Receiver" then
            local receiver = "Kicker"
            local receiverX = COurRole_x(receiver)
            local receiverY = COurRole_y(receiver)
            return task.KickerTask("passball", receiverX, receiverY)
        else
            return task.ReceiverTask("receive")
        end
    end
},

["receive"] = {
    switch = function()
        local holder = getBallHolder()
        if holder then
            return "passball"  -- 成功接球后回到传球状态
        end
        
        -- 超时或丢球
        if Cbuf_cnt(true, 50) then
            return "start"
        end
        
        return "receive"
    end,
    Kicker = function()
        if getBallHolder() == "Kicker" then
            return task.KickerTask("getBall2")  -- 保持控球
        else
            return task.ReceiverTask("receive")
        end
    end,
    Receiver = function()
        if getBallHolder() == "Receiver" then
            return task.KickerTask("getBall2")  -- 保持控球
        else
            return task.ReceiverTask("receive")
        end
    end
},

["shoot"] = {
    switch = function()
        if CIsBallKick(getBallHolder() or "Kicker") then
            return "start"
        end
        
        if Cbuf_cnt(true, 30) then
            return "passball"
        end
        
        return "shoot"
    end,
    Kicker = function()
        if getBallHolder() == "Kicker" then
            return task.KickerTask("shoot")
        else
            -- 如果不是持球者，选择有利位置
            local passer = getBallHolder() or "Receiver"
            local x, y = getDynamicSupportPosition(passer, "Kicker")
            return task.GotoPos("Kicker", x, y, Kicker2Balldir())
        end
    end,
    Receiver = function()
        if getBallHolder() == "Receiver" then
            return task.KickerTask("shoot")
        else
            -- 如果不是持球者，选择有利位置
            local passer = getBallHolder() or "Kicker"
            local x, y = getDynamicSupportPosition(passer, "Receiver")
            return task.GotoPos("Receiver", x, y, Receiver2Balldir())
        end
    end
},

["defense"] = {
    switch = function()
        if CIsGetBall("Kicker") or CIsGetBall("Receiver") then
            return "passball"
        elseif CBall2RoleDist("Kicker") < 35 then
            return "start"
        elseif CBall2RoleDist("Receiver") < 35 then 
            return "start"
        end
    end,
    Kicker   = task.KickerTask("def_receiver"),
    Receiver = task.ReceiverTask("def_kicker"),
    Goalie   = task.Goalie() 
},
name = "a_normalplay"
}
