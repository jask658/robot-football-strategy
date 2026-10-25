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
local BallPosX = function()
	return function()
		return CGetBallX()-90
	end
end
local BallPosY = function()
	return function()
		return CGetBallY()+70
	end
end
local RY = function()
	return function()
		local res
		if CGetBallY()>=0 then
			res = 35
		else
			res =-35
		end
		return res
	end
end
local TY = function()
	return function()
		local res
		if CGetBallY()>=0 then
			res = 148
		else
			res =-148
		end
		return res
	end
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

gPlayTable.CreatePlay{
firstState = "start",

["start"] = {
	switch = function()
		if CGetBallX() > 210 and CGetBallX()<230 and CGetBallY() > -10 and CGetBallY() < 10 then
			return "T5"
		elseif CBall2RoleDist("Kicker")<25 and CRole2TargetDist("Receiver")<5 then
			return "passball"
		end
	end,
	Kicker  = task.KickerTask("getBall2"),
	Receiver = task.GotoPos("Receiver",160,0,Receiver2Balldir()),
},

["passball"] = {
	switch = function()
		if CBall2RoleDist("Kicker")>35 or CIsBallKick("Kicker") then
			return "receive"
		end
	end,
	Kicker   = task.KickerTask("passball20"),
	Receiver = task.GotoPos("Receiver",RobotPosX("Receiver"),RobotPosY("Receiver"),Receiver2Balldir()),
},
["receive"] = {
	switch = function()
		if CBall2RoleDist("Receiver")<13 and CRole2TargetDist("Kicker")  then
			return "passball2"
		end
	end,
	Kicker   = task.GotoPos("Kicker",40,RobotPosY("Receiver"),Kicker2Balldir()),
	Receiver = task.ReceiverTask("receive"),
},
["passball2"] = {
	switch = function()
		if CBall2RoleDist("Receiver")>35 or CIsBallKick("Receiver") and COurRole_y("Kicker")>0 then
			return "Kicker"
		elseif CBall2RoleDist("Receiver")>35 or CIsBallKick("Receiver") and COurRole_y("Kicker")<0 then
			return "Kicker2"
		end
	end,
	Receiver  =  task.ReceiverTask("passball20"),
	Kicker    = task.GotoPos("Kicker",RobotPosX("Kicker"),RobotPosY("Kicker"),Kicker2Balldir()),
	--Kicker =  task.KickerTask("Kicker",RobotPosX("Kicker"),RobotPosY("Kicker"),Kicker2Balldir()),
},

["Kicker"] = {
	switch = function()
		if Cbuf_cnt(CBall2RoleDist("Kicker")<20,30) then
			return "T5"
		end
	end,
	--Receiver = task.ReceiverTask("GoToP"),
	Receiver = task.GotoPos("Receiver",230,-100,Receiver2Balldir()),
	--Receiver   = task.ReceiverTask("canShoot"),--GotoPos("Kicker",RobotPosX("Kicker"),RobotPosY("Kicker"),Receiver2Balldir()),
	Kicker = task.KickerTask("receive"),--接球后退
},
["Kicker2"] = {
	switch = function()
		if Cbuf_cnt(CBall2RoleDist("Kicker")<20,30) then
			return "T5"
		end
	end,
	--Receiver = task.ReceiverTask("GoToP"),
	Receiver = task.GotoPos("Receiver",230,100,Receiver2Balldir()),
	--Receiver   = task.ReceiverTask("canShoot"),--GotoPos("Kicker",RobotPosX("Kicker"),RobotPosY("Kicker"),Receiver2Balldir()),
	Kicker = task.KickerTask("receive"),--接球后退
},
["T5"] = {
	switch = function()
		if CIsGetBall("Kicker") then
			return "shoot2"
		end
	end,
    Kicker = task.GetBall("Kicker","Kicker"),   
},
["shoot2"] = {
	switch = function()
		--if Cbuf_cnt(CBall2RoleDist("Receiver")<12,20)  then
			return "shoot2"
		--end
	end,
	Kicker   = task.KickerTask("shoot"),
	--Receiver = task.GotoPos("Receiver",RobotPosX("Receiver"),RobotPosY("Receiver"),Receiver2Balldir())
},
name = "genshin impact"
}
