--desc: 
Kickerdir = function()
	return CRole2BallDir("Kicker")
end
Kickerjudge=function ()
	local y 
	if CGetBallY() > 0 then
		y = -110
	else
		y =110
	end
	return y
end
gPlayTable.CreatePlay{

firstState = "initState",

["initState"] = {
	switch = function ()
		if Cbuf_cnt(CIsGetBall("Kicker"),60)  then
			return "initState1"
		end
	end,
	Kicker   = task.KickerTask("jiaoqiunaqiu"),
	Receiver = task.ReceiverTask("zhongzuo_hou"),
	
},

["initState1"] = {
	switch = function ()
		if  CIsBallKick("Kicker") then
			return "initState2"
		end
	end,
	Kicker   = task.KickerTask("cq12_8"),
	Receiver = task.ReceiverTask("jieqiu"),
	
},
["initState2"] = {
	switch = function ()
		if  Cbuf_cnt(CIsGetBall("Receiver"),60)then

			return "initState3"
		end
	end,
	Kicker   = task.KickerTask("zhongyou_hou"),
	Receiver = task.ReceiverTask("jieqiu"),
	
	
},
["initState3"] = {
	switch = function ()
		if  CIsBallKick("Receiver") then
			return "initState4"
		end
	end,
	Kicker   = task.KickerTask("jieqiu"),
	Receiver = task.ReceiverTask("cq12_8"),
	
},

["initState4"] = {
	switch = function ()
		if Cbuf_cnt(CIsGetBall("Kicker"),60)  then
			return "delay"
		end
	end,
	Kicker   = task.KickerTask("jqsm23"),
	Receiver = task.ReceiverTask("jqch_stop"),
	
},

["delay"] = {
	switch = function()
		if  CIsBallKick("Receiver") or  Cbuf_cnt(true,300) then
			return "finish"
		end
	end,
	Kicker   = task.KickerTask("jqsm23"),
    Receiver   = task.ReceiverTask("jqch_stop"),
},

name = "qcq_zj_zuoyou_12_wnq"
}