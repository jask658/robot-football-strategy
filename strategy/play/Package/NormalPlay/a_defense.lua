--desc: 
local RobotPosX = function(role)
	return function()
		return (COurRole_x(role) * 9 + CGetBallX(role)) / 10
	end
end
local RobotPosY = function(role)
	return function()
		return (COurRole_y(role) * 9 + CGetBallY(role)) / 10
	end
end

local RobotPosX1 = function(role)
	return function()
		return COurRole_x(role)
	end
end
local RobotPosY1 = function(role)
	return function()
		return COurRole_y(role)
	end
end

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
local Goalie2Balldir = function()
	return function()
		return CRole2BallDir("Goalie")
	end
end

local opp2ball = function(id)
	local ball_x = CGetBallX()
	local ball_y = CGetBallY()
	local opp_x = COppNum_x(id)
	local opp_y = COppNum_y(id)
	return math.sqrt((ball_x - opp_x)^2 + (ball_y - opp_y)^2)
end

gPlayTable.CreatePlay{

firstState = "K1",

["K0"] = {
	switch = function()
		if RobotPosX1("Receiver") > -125 and  RobotPosX1("Receiver") < -115 then
			return "shoot"
		 -- elseif CBall2OppNumDist(1) < 35 or CBall2OppNumDist(2) < 35 then
		 -- 	return "defense"
		end
	end,
	Kicker   = task.KickerTask("getBall2"),
	Receiver = task.GotoPos("Receiver",-120,0,Receiver2Balldir()),
	Goalie   = task.GotoPos("Goalie",-300,0,Goalie2Balldir()),
},

["shoot"] = {
	switch = function()
		if opp2ball(1) < 35 or opp2ball(2) < 35 then
			return "D1"
		end
	end,
	Kicker = task.KickerTask("shoot"),
	--Receiver = task.GotoPos("Receiver",RobotPosX("Receiver"),RobotPosY("Receiver"),Receiver2Balldir())
	Receiver = task.GotoPos("Receiver",-120,0,Receiver2Balldir()),

},

["K1"] = {
	switch = function()
		if CBall2RoleDist("Kicker")>35 or CIsBallKick("Kicker") then
			return "K2"
		 -- elseif CBall2OppNumDist(1) < 35 or CBall2OppNumDist(2) < 35 then
		 -- 	return "defense"
		elseif opp2ball(1) < 35 or opp2ball(2) < 35 then
			return "D1"
		end
	end,
	Kicker   = task.KickerTask("passball20"),
	Receiver = task.GotoPos("Receiver",RobotPosX1("Receiver"),RobotPosY1("Receiver"),Receiver2Balldir()),
},

["K2"] = {
	switch = function()
		if CBall2RoleDist("Receiver")>35 or CIsBallKick("Receiver") then
			return "K1"
		 -- elseif CBall2OppNumDist(1) < 35 or CBall2OppNumDist(2) < 35 then
		 -- 	return "defense"
		elseif opp2ball(1) < 35 or opp2ball(2) < 35 then
			return "D1"
		end
	end,
	Receiver  =  task.ReceiverTask("passball20"),
	Kicker    = task.GotoPos("Kicker",RobotPosX1("Kicker"),RobotPosY1("Kicker"),Kicker2Balldir()),
	--Kicker =  task.KickerTask("Kicker",RobotPosX("Kicker"),RobotPosY("Kicker"),Kicker2Balldir()),
},

["D1"] = {
    switch = function()
		if CBall2RoleDist("Kicker")<20 then
			return "shoot"
		end
	end,
	Kicker   = task.GotoPos("Kicker",RobotPosX("Kicker"),RobotPosY("Kicker"),Kicker2Balldir()),
	Receiver = task.GotoPos("Receiver",RobotPosX("Receiver"),RobotPosY("Receiver"),Receiver2Balldir()),
	Goalie   = task.GotoPos("Goalie",-300,0,Goalie2Balldir()),

},

name = "a_defense"

}