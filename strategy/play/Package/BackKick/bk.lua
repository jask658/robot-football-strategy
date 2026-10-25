--desc: 
gPlayTable.CreatePlay{

firstState = "K1",

["K1"] = {
    switch = function()
		if Cbuf_cnt(CRole2TargetDist("Receiver")< 5 ,30)then
			return "K2"
		end
	end,
	Kicker   = task.KickerTask("gotopos"),
	Receiver = task.ReceiverTask("POS_01"),
	Goalie = task.Goalie()
},

["K2"] = {
    switch = function()
		if Cbuf_cnt(CBall2RoleDist("Kicker")> 25 ,30)then
			return "K3"
		end
	end,
	Kicker   = task.KickerTask("getball_1.0"),
	Receiver = task.ReceiverTask("POS_01") ,
	Goalie = task.Goalie()
},

["K3"]={
	switch =function()
		if Cbuf_cnt(CBall2RoleDist("Receiver")<15,30) then
			return "K4"
		end
	end,
	Kicker = task.KickerTask("POS_02"),
	Receiver = task.ReceiverTask("receiveball_1.0"),
	Goalie = task.Goalie()
},

["K4"]={
	switch =function()
		if Cbuf_cnt(CRole2TargetDist("Kicker")<3,50) then
			return "K5"
		end
	end,
	Kicker = task.KickerTask("POS_02"),
	Receiver = task.ReceiverTask("gotopos"),
	Goalie = task.Goalie()
},

["K5"]={
	switch =function()
		if Cbuf_cnt(CBall2RoleDist("Receiver")>20,20) then
			return "K6"
		end
	end,
	Kicker=task.KickerTask("POS_02"),
	Receiver=task.ReceiverTask("getball_1.0"),
	Goalie = task.Goalie()
},

["K6"]={
	switch =function()
		if Cbuf_cnt(CBall2RoleDist("Kicker")<15,30) then
			return "K7"
		end
	end,
	Kicker=task.KickerTask("receiveball_1.0"),
	Receiver=task.RobotHalt("Receiver"),
	Goalie = task.Goalie()
},

["K7"] ={
	switch = function()
		if Cbuf_cnt(true,50)  then
 			return "K8"
 		end
	end,
	Receiver =task.RobotHalt("Receiver"),
	Kicker= task.KickerTask("ready_shoot"),
	Goalie = task.Goalie()
},

["K8"] = {
 	switch = function()
 		if Cbuf_cnt(true,30) then
 			return "shoot"
 		end
 	end,
 	Kicker = task.KickerTask("shoot_left"),
 	--Kicker = task.KickerTask("fire3.0"),
 	Goalie = task.Goalie()
 },

name = "bk"

}