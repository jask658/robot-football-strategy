--desc: 

gPlayTable.CreatePlay{

firstState = "D1",

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

name = "def"

}