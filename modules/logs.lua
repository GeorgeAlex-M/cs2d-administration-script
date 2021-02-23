logs = {}

function logs.mutePlayer(id,name,usgn,steam,duration,toggle)
    -- open save file with read properties
    local fileUSGN = io.open(directory.."users/"..usgn..".txt", "r")
    local fileSTEAM = io.open(directory.."users/"..steam..".txt", "r")

    -- check if save file exists
    local fd
    if fileUSGN then
        fd = fileUSGN
    else
        if fileSTEAM then
            fd = fileSTEAM
        else
            msg2(id,cloud.tags.server.."Player "..name.." has no data saved!")

        -- no save file found, return void
        return end
    end

    -- read save file contents (deserialize) and parse its contents into a table
    local tbl_saved_data = {}
    tbl_saved_data = table.deserialize(fd:read("*a"))

    -- close the file
    fd:close()
    fd = nil

    -- open save file with write properties
    local file
    if fileUSGN then
        file = io.open(directory.."users/"..usgn..".txt", "w")
    elseif fileSTEAM then
        file = io.open(directory.."users/"..steam..".txt", "w")
    end
    if file then
        -- assign saved table values + toggle and duration value
        local tbl = {
            var_level = tbl_saved_data.var_level,
            var_level_name = tbl_saved_data.var_level_name,
            var_tag_name = tbl_saved_data.var_tag_name,
            var_tag_color = tbl_saved_data.var_tag_color,
            var_tag_toggle = tbl_saved_data.var_tag_toggle,
            var_god_toggle = tbl_saved_data.var_god_toggle,
            var_tele_toggle = tbl_saved_data.var_tele_toggle,
            var_bigears_toggle = tbl_saved_data.var_bigears_toggle,
            var_mute_toggle = toggle,
            var_mute_duration = duration,
            var_usgn_password = tbl_saved_data.var_usgn_password,
            var_login = tbl_saved_data.var_login,
            var_grab_toggle = tbl_saved_data.var_grab_toggle,
            var_grab_targetID = tbl_saved_data.var_grab_targetID,
            var_commands = tbl_saved_data.var_commands,
        }
        -- write table values inside the file and close the file
        file:write(table.serialize(tbl))
        file:flush()
        file:close()
        file = nil
    end

    -- print custom message for the player who issued the action
    if tbl_saved_data.var_mute_toggle and toggle then
        msg2(id,cloud.tags.server.."Player "..name.." is allready muted!")
    end

    if not tbl_saved_data.var_mute_toggle and toggle then
        msg2(id,cloud.tags.server.."Player "..name.." will be muted for "..duration.." minutes next time he rejoins the server.")
    end

    if not tbl_saved_data.var_mute_toggle and tbl_saved_data.var_mute_duration == 0 then
        msg2(id,cloud.tags.server.."Player "..name.." is allready unmuted!")
    else
        if not toggle and duration == 0 then
            msg2(id,cloud.tags.server.."Player "..name.." has been unmuted!")
        end
    end
end

local function generateLogItem(l_menu, line, i, line_index)
    local time, ip, steam, usgn, id, team, name, log = string.match(line, "(%d+%-%d+%-%d+ %d+:%d+ [AP]M) %- %[IP: ([%d%.]+)%] %[STEAM: (%d+)%] %[USGN: (%d+)%] %[ID: (%d+)%] %[Team: (%d+)%] %[Name: (.+)%]: ([%w%p ]+)")

    local ban_menu = {
        title = name.." - "..ip,
        items = {
            {"Ban Name","",function(id) parse("banname " ..name) end},
            {"Ban IP","",function(id) parse("banip " .. ip) end},
            {"Ban U.S.G.N.","",function(id) parse("banusgn " ..usgn) end},
            {"Ban STEAM","",function(id) parse("bansteam " ..steam) end}
        },
        fixedItems = {[7] = {"<< Return", "", function(id) unimenu.historyBack(id) end}}
    }

    local mute_menu = {
        title = name.." - "..ip,
        items = {
            {"5 Minutes","",function(id)
                local toggle = true
                local duration = 5*60
                logs.mutePlayer(id,name,usgn,steam,duration,toggle)
            end},
            {"30 Minutes","",function(id)
                local toggle = true
                local duration = 30*60
                logs.mutePlayer(id,name,usgn,steam,duration,toggle)
            end},
            {"1 Hour","",function(id)
                local toggle = true
                local duration = 60*60
                logs.mutePlayer(id,name,usgn,steam,duration,toggle)
            end},
            {"24 Hours","",function(id)
                local toggle = true
                local duration = 86400*60
                logs.mutePlayer(id,name,usgn,steam,duration,toggle)
            end},
            {"","",function(id) end},
            {"Unmute","",function(id)
                local toggle = false
                local duration = 0
                logs.mutePlayer(id,name,usgn,steam,duration,toggle)
            end}
        },
        fixedItems = {[7] = {"<< Return", "", function(id) unimenu.historyBack(id) end}}
    }

    local info_menu = {
        title = "Info - Click on an info button to print in chat.",
        items = {
            {"Name",name,function(id) unimenu.historyBack(id) end},
            {"IP",ip,function(id) unimenu.historyBack(id) end},
            {"STEAM",steam,function(id) unimenu.historyBack(id) end},
            {"USGN",usgn,function(id) unimenu.historyBack(id) end}
        },
        fixedItems = {[7] = {"<< Return", "", function(id) unimenu.historyBack(id) end}},
        big = true
    }

    local action_menu = {
        title = name.." - "..ip,
        items = {
            {"Issue a Ban",">",function(id) unimenu.open(id, ban_menu) end},
            {"Mute Player",">",function(id) unimenu.open(id, mute_menu) end},
            {"","",function(id) end},
            {"Show player info","",function(id) unimenu.open(id, info_menu) msg2(id,cloud.tags.server..time.." - "..name.." - "..ip.." - USGN: "..usgn.." - STEAM: "..steam.." - ID: "..id.." - Team: "..team.." - Log: "..log) end},
            {"Delete Log","",
            function(id)
                local tbl = {}
                for k, v in ipairs(l_menu.logs) do
                    if k ~= line_index then
                        table.insert(tbl,v)
                    end
                end
                local content = table.concat(tbl,"\n")
                local fd = io.open(directory.."data/logs.txt", "w")
                fd:write(content)
                fd:close()
                -- return this menu after deletion
                unimenu.open(id, logs.retrieve_logs())
            end
            },
            {"Erase all Logs","",
            function(id)
                local fd = io.open(directory.."data/logs.txt", "w")
                fd:write()
                fd:close()
                -- return this menu after deletion
                unimenu.open(id, logs.retrieve_logs())
            end}
        },
        fixedItems = {[7] = {"<< Return", "", function(id) unimenu.historyBack(id) end}}
    }

    return {time.." - "..name, log, function(id) unimenu.open(id, action_menu) end}
end

function logs.retrieve_logs()
    local l_menu = {
        title = "Logs",
        items = {},
        fixedItems = {[7] = {"<< Return", "", function(id) unimenu.historyBack(id) end}},
        big = true,
        logs = {},
	}

    local file = io.open(directory.."data/logs.txt", "r")
    if not file then return end
    local i = 1
    for line in file:lines() do
        local line_index = i
        l_menu.logs[line_index] = line

        table.insert(l_menu.items, generateLogItem(l_menu, line, i, line_index))
        i = i + 1
    end
    file:close()
    file = nil

    return l_menu
end
