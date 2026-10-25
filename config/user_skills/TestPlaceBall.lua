gPlayTable.CreatePlay{ 
    firstState = "A",   --起始状态拿球“GetBall”
    times = 0,
    ["A"] = {
        switch = function()
            if COurRole_x("Receiver") == 0 and COurRole_y("Receiver") == 0 then -- 判断“Receiver”离球距离是否为0
                return "B" 
            end 
        end, 
        --Kicker = task.KickerTask("mypassball"), -- “Kicker”前锋跑到接球点
        Receiver = task.ReceiverTask("receive_ball"), -- “Receiver”中场去拿球
        --Goalie  = task.Goalie() -- “Goalie”守门员守门
    }, -- “PassBall”传球状态 

    ["B"] = {
        switch = function()
            if CBall2RoleDist("Receiver") < 30 then -- 判断“Receiver”离球距离是否小于 30
                return "C" 
            end 
        end, 
        Kicker = task.KickerTask("get_ball_simplified"),
        --Kicker = task.KickerTask("passball2"), -- “Kicker”前锋跑到接球点
        --Receiver = task.ReceiverTask("receive02"), -- “Receiver”中场去拿球
        --Goalie  = task.Goalie() -- “Goalie”守门员守门
    },

    ["C"] = {
        switch = function()
            if CBall2RoleDist("Receiver") < 30 then -- 判断“Receiver”离球距离是否小于 30
                return "C" 
            end 
        end, 
        Kicker = task.Shoot("Kicker"),
        Receiver = task.ReceiverTask("receive02"), -- “Receiver”中场去拿球
        --Goalie  = task.Goalie() -- “Goalie”守门员守门
    },

    name = "shootballtest"  -- 脚本名称
}
