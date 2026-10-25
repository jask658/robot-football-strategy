--desc: 

gPlayTable.CreatePlay{

firstState = "D1",

["D1"] = {
    switch = function()
		if Cbuf_cnt(true,30) then
			return "D1"
		end
	end,
	Kicker   = task.KickerTask("chuanqiutest"),
	Receiver = task.GotoPos("Receiver", 180, -30, 90),
	Goalie   = task.Goalie()

},

name = "test"

}