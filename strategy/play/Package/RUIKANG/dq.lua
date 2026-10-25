--desc: 
kickerdir = function()
	return CRole2BallDir("Kicker")
end

ReceiverDir = function()
	return CRole2BallDir("Receiver")
end

gPlayTable.CreatePlay{
firstState = "dianqiu",


["dianqiu"] = {
	switch = function()
		if CIsBallKick("Kicker") or CGameOn() then
			return "finish"
		end
	end,
	Kicker   = task.KickerTask("shoot111"),
},
	
name = "dq"
}