--desc: 
kickerdir = function()
	return CRole2BallDir("Kicker")
end

ReceiverDir = function()
	return CRole2BallDir("Receiver")
end

oppGoalDir = function()
	return CRole2OppGoalDir("Receiver")
end

gPlayTable.CreatePlay{

firstState = "start",

-- ["start"] = {
-- 	switch = function ()
-- 		if CNormalStart() then
-- 			return "K2"
-- 		elseif CGameOn() then
-- 			return "finish"
-- 		end
-- 	end,
-- 	Kicker   = task.GotoPos(0, 90, kickerdir),
-- 	Receiver = task.GotoPos(-60, 0, ReceiverDir),
-- 	Goalie = task.Goalie()
-- },

["start"] = {
	switch = function ()
		if CIsBallKick("Receiver") then
			return "K2"
		end
	end,
	Kicker   = task.GotoPos("Kicker", -60, 0, ReceiverDir),
	Receiver = task.PassBall("Receiver", "Kicker"),
	Goalie = task.Goalie()
},

["K2"] = {
	switch = function ()
		if CIsBallKick("Receiver") then
			return "K3"
		end
	end,
	Kicker   = task.ReceiveBall("Kicker"),
	Receiver = task.PassBall("Receiver", "Kicker"),
	Goalie = task.Goalie()
},

["K3"] = {
    switch = function()
		if CIsBallKick("Kicker") then
			return "K4"
		end
	end,
	Kicker   = task.PassBall("Kicker", "Receiver"),
	Receiver = task.ReceiveBall("Receiver") ,
	Goalie = task.Goalie()
},

["K4"] = {
 	switch = function()
 		if Cbuf_cnt(true,30) then
 			return "K4"
 		end
 	end,
 	--Receiver = task.ReceiverTask("shoot_left"),
 	Kicker = task.KickerTask("shoot_left"),
 },

name = "a_kaiqiu"

}