--desc: 

gPlayTable.CreatePlay{

firstState = "start",

["start"] = {
	switch = function ()
		if CNormalStart() then
			return "D1"
		elseif CGameOn() then
			return "finish"
		end
	end,
	Kicker = task.RobotHalt("Kicker"),
	Receiver = task.RobotHalt("Receiver"),
},

["D1"] = {
    switch = function()
		if Cbuf_cnt(true,30) then
			return "D1"
		end
	end,
	Kicker   = task.KickerTask("def_receiver"),
	Receiver = task.ReceiverTask("def_kicker"),
	Goalie   = task.Goalie()

},
name = "def_kaiqiu"

}