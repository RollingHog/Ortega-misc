-- Simple IRC client 
-- Based on OpenComputers vanillia IRC
-- Specially for Ortega Roleplay Project
-- 
local programVersion = 20191005

local component = require("component")
local computer = require("computer")

local gpu = component.gpu
if not component.isAvailable("internet") then
  io.stderr:write("OpenIRC requires an Internet Card to run!\n")
  return
end

local event = require("event")
local shell = require("shell")
local term = require("term")
local internet = require("internet")
local text = require("text")
local unicode   = require("unicode")   

local args, options = shell.parse(...)

local host = args[1] or "irc.esper.net:6667"
-- local host = args[1] or "nonames.su:54391"
local nick = 'Itoh'
local defaultChannel = '#test'

local gpuW = 100
local gpuH = 50
gpu.setResolution(gpuW, gpuH)

local allY   = 3
local timeX  = 2
local timeW  = 1
local usersW = 15
local chatX  = timeX + timeW
local chatW  = gpuW - timeX - timeW - 1 - usersW - 1
local usersX = chatX + chatW + 2
local allH   = gpuH - allY - 1
local inputY = allY + allH
local maxW   = timeX + timeW + chatW + 1 + usersW + 1

local borderColor     = 0x002480
local stuffLineColor  = 0x996d00
local userLineColor   = 0xFF4940
local loggerColor     = 0xFFB600
local userInputColor  = 0xFF2400

-- default target for messages, so we don't have to type /msg all the time.
local target = nil
-- previous target in case current is fucked up
local prevtarget = nil

if not host:find(":") then
  host = host .. ":6667"
end
-- try to connect to server.
local sock, reason = internet.open(host)
if not sock then
  io.stderr:write(reason .. "\n")
  return
end

function split(data, pat) 
	local ret = {} 
	for i in string.gmatch(data,pat) do 
		table.insert(ret,i) 
	end 
	return ret 
end 

function mySub(s, i, j) 
    return unicode.sub(s, i, j) 
end

function clearArea(nx,ny,nw,nh,nch)
  gpu.fill(nx,ny,nw,nh,nch)
end

function widthedPrint(x, y, s, w) 
  -- return number of lines
  if(#s > w) then 
    gpu.set(x,y,mySub(s,1,w)) 
    return widthedPrint(x,y+1,mySub(s,w+1,#s),w)+1 
  else 
    gpu.set(x,y,s) 
    return 0
  end 
end 

function shiftedPrint(nx, ny, nwidth, nheight, nstr, nshift)
  gpu.copy (nx, ny, nwidth, nheight, 0, -nshift)
  clearArea(nx, ny+nheight-nshift, nwidth, nshift+1, ' ')
  widthedPrint(nx, ny+nheight-nshift, nstr, nwidth)
end

function centerPrint(nx,ny,nw,nstr)
  gpu.set(nx+math.ceil(nw/2)-math.ceil(unicode.wlen(nstr)/2),ny,nstr)
end

function printHeader()
  gpu.setForeground(stuffLineColor)  
  gpu.setBackground(borderColor)

  gpu.fill(1,1,1,timeX+allH+1,' ')
  gpu.fill(usersX-1,3,1,inputY-1,' ')
  gpu.fill(maxW,3,1,inputY-1,' ')
  
  gpu.fill(1,1,maxW,2,' ')
  gpu.fill(1,inputY+1, maxW, 1, ' ')
  
  centerPrint(1,1,maxW,'Инфосфера-Клиент v.'..programVersion)
  centerPrint(timeX,2,timeW+chatW,'Сервер:'..host..' / Ник:'..nick.." / Канал:"..(target or "_"))
  centerPrint(usersX,2,usersW,'Пользователи')
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
end

function printNewMessage(nuser,nstr)
  -- local str = nuser..': '..nstr
  local str = nstr
  local user = nuser
  local nshift = math.ceil(unicode.wlen(str)/chatW)
  if (nuser == nick) then
    gpu.setForeground(userLineColor)
  elseif (nuser == 'logger') then
    user = ''
  else
    gpu.setForeground(stuffLineColor)
  end
  --shiftedPrint(timeX, allY, timeW, allH, '['..unicode.wlen(str)..':00:00] ', nshift)
  -- shiftedPrint(timeX, allY, timeW, allH, ' '..user, nshift)
  if (nuser == nick) then
    gpu.setForeground(userLineColor)
  elseif (nuser == 'logger') then
    gpu.setForeground(loggerColor) 
  elseif (nuser == 'special') then
    gpu.setForeground(userInputColor)
  else
    gpu.setForeground(0xFFFFFF)
  end
  shiftedPrint(chatX, allY, chatW, allH, str, nshift)
  printHeader()
end

function printUsers(nlist)
  clearArea(usersX, allY, usersW, allH+1, ' ')
  if(type(nlist) == "string") then
    nlist = nlist.." "
    local ta = split(nlist,"[^ ]+ ")
    for _,i in pairs(ta) do
      if(i:gsub("(.*) $", "%1") == nick) then
        gpu.setForeground(userLineColor)
      end
      shiftedPrint(usersX+1, allY+1, usersW, allH-1, i, 1)
      gpu.setForeground(0xFFFFFF)
    end
  else
    for _,i in pairs(nlist) do
      shiftedPrint(usersX+1, allY+1, usersW, allH-1, i, 1)
    end
  end
  printHeader()
end

local function requestUsers(ntarget)
  sock:write("NAMES "..ntarget.."\r\n")
  sock:flush()
end
----------------------------------------------------------/MINE

-- custom print that uses all except the last line for printing.
local function print(message, nuser)
  -- io.write(message)
  printNewMessage(nuser,message)
  term.setCursor(chatX, inputY)
end

  -- local w, h = component.gpu.getResolution()
  -- local line
  -- repeat
    -- line, message = text.wrap(text.trim(message), w, w)
    -- if not overwrite then
      -- component.gpu.copy(1, 1, w, h - 1, 0, -1)
    -- end
    -- overwrite = false
    -- component.gpu.fill(1, h - 1, w, 1, " ")
    -- component.gpu.set(1, h - 1, line)
  -- until not message or message == ""

-- utility method for reply tracking tables.
function autocreate(ntable, key)
  ntable[key] = {}
  return ntable[key]
end

-- extract nickname from identity.
local function name(identity)
  return identity and identity:match("^[^!]+") or identity or "Anonymous"
end

-- user defined callback for messages (via `lua function(msg) ... end`)
local callback = nil

-- list of whois info per user (used to accumulate whois replies).
local whois = setmetatable({}, {__index=autocreate})

-- list of users per channel (used to accumulate names replies).
local names = setmetatable({}, {__index=autocreate, __pairs=metpairs})

-- timer used to drive socket reading.
local timer

-- ignored commands, reserved according to RFC.
-- http://tools.ietf.org/html/rfc2812#section-5.3
local ignore = {
  [213]=true, [214]=true, [215]=true, [216]=true, [217]=true,
  [218]=true, [231]=true, [232]=true, [233]=true, [240]=true,
  [241]=true, [244]=true, [244]=true, [246]=true, [247]=true,
  [250]=true, [300]=true, [316]=true, [361]=true, [362]=true,
  [363]=true, [373]=true, [384]=true, [492]=true,
  -- custom ignored responses.
  [265]=true, [266]=true, [330]=true
}

-- command numbers to names.
local commands = {
--Replys
  RPL_WELCOME = "001",
  RPL_YOURHOST = "002",
  RPL_CREATED = "003",
  RPL_MYINFO = "004",
  RPL_BOUNCE = "005",
  RPL_LUSERCLIENT = "251",
  RPL_LUSEROP = "252",
  RPL_LUSERUNKNOWN = "253",
  RPL_LUSERCHANNELS = "254",
  RPL_LUSERME = "255",
  RPL_AWAY = "301",
  RPL_UNAWAY = "305",
  RPL_NOWAWAY = "306",
  RPL_WHOISUSER = "311",
  RPL_WHOISSERVER = "312",
  RPL_WHOISOPERATOR = "313",
  RPL_WHOISIDLE = "317",
  RPL_ENDOFWHOIS = "318",
  RPL_WHOISCHANNELS = "319",
  RPL_CHANNELMODEIS = "324",
  RPL_NOTOPIC = "331",
  RPL_TOPIC = "332",
  RPL_NAMREPLY = "353",
  RPL_ENDOFNAMES = "366",
  RPL_MOTDSTART = "375",
  RPL_MOTD = "372",
  RPL_ENDOFMOTD = "376",
  RPL_WHOISSECURE = "671",
  RPL_HELPSTART = "704",
  RPL_HELPTXT = "705",
  RPL_ENDOFHELP = "706",
  RPL_UMODEGMSG = "718",
  
--Errors
  ERR_BANLISTFULL = "478",
  ERR_CHANNELISFULL = "471",
  ERR_UNKNOWNMODE = "472",
  ERR_INVITEONLYCHAN = "473",
  ERR_BANNEDFROMCHAN = "474",
  ERR_CHANOPRIVSNEEDED = "482",
  ERR_UNIQOPRIVSNEEDED = "485",
  ERR_USERNOTINCHANNEL = "441",
  ERR_NOTONCHANNEL = "442",
  ERR_NICKCOLLISION = "436",
  ERR_NICKNAMEINUSE = "433",
  ERR_ERRONEUSNICKNAME = "432",
  ERR_WASNOSUCHNICK = "406",
  ERR_TOOMANYCHANNELS = "405",
  ERR_CANNOTSENDTOCHAN = "404",
  ERR_NOSUCHCHANNEL = "403",
  ERR_NOSUCHNICK = "401",
  ERR_MODELOCK = "742"
}

-- main command handling callback.
local function handleCommand(prefix, command, args, message)
  ---------------------------------------------------
  -- Keepalive
  if command == "PING" then
    sock:write(string.format("PONG :%s\r\n", message))
    sock:flush()

  ---------------------------------------------------
  -- General commands
  elseif command == "NICK" then
    local oldNick, newNick = name(prefix), tostring(args[1] or message)
    if oldNick == nick then
      nick = newNick
    end
    print(oldNick .. " is now known as " .. newNick .. ".", "logger")
  elseif command == "MODE" then
    if #args == 2 then
      print("[" .. args[1] .. "] " .. name(prefix) .. " set mode".. ( #args[2] > 2 and "s" or "" ) .. " " .. tostring(args[2] or message) .. ".", "logger")
    else
      local setmode = {}
      local cumode = "+"
      args[2]:gsub(".", function(char)
        if char == "-" or char == "+" then
          cumode = char
        else
          table.insert(setmode, {cumode, char})
        end
      end)
      local d = {}
      local users = {}
      for i = 3, #args do
        users[i-2] = args[i]
      end
      users[#users+1] = message
      local last
      local ctxt = ""
      for c = 1, #users do
        if not setmode[c] then
          break
        end
        local mode = setmode[c][2]
        local pfx = setmode[c][1]=="+"
        local key = mode == "o" and (pfx and "opped" or "deoped") or
          mode == "v" and (pfx and "voiced" or "devoiced") or
          mode == "q" and (pfx and "quieted" or "unquieted") or
          mode == "b" and (pfx and "banned" or "unbanned") or
          "set " .. setmode[c][1] .. mode .. " on"
        if last ~= key then
          if last then
            print(ctxt, "logger")
          end
          ctxt = "[" .. args[1] .. "] " .. name(prefix) .. " " .. key
          last = key
        end
        ctxt = ctxt .. " " .. users[c]
      end
      if #ctxt > 0 then
        print(ctxt)
      end
    end
  elseif command == "QUIT" then
    print(name(prefix) .. " quit (" .. (message or "Quit") .. ").", "logger")
  elseif command == "JOIN" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " entered the room.", "logger")
  elseif command == "PART" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " has left the room (quit: " .. (message or "Quit") .. ").", "logger")
  elseif command == "TOPIC" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " has changed the topic to: " .. message, "logger")
  elseif command == "KICK" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " kicked " .. args[2], "logger")
  elseif command == "PRIVMSG" then
    local ctcp = message:match("^\1(.-)\1$")
    if ctcp then
      local orig_ctcp, param = ctcp:match("^(%S+) ?(.-)$")
      ctcp = orig_ctcp:upper()
      if ctcp == "TIME" then
        sock:write("NOTICE " .. name(prefix) .. " :\001TIME " .. os.date() .. "\001\r\n")
        sock:flush()
      elseif ctcp == "VERSION" then
        sock:write("NOTICE " .. name(prefix) .. " :\001VERSION Minecraft/OpenComputers Lua 5.2\001\r\n")
        sock:flush()
      elseif ctcp == "PING" then
        sock:write("NOTICE " .. name(prefix) .. " :\001PING " .. param .. "\001\r\n")
        sock:flush()
      elseif ctcp == "ACTION" then
        print("[" .. args[1] .. "] * " .. name(prefix) .. string.gsub(string.gsub(message, "\001ACTION", ""), "\001", ""), args[1])
      else
        -- Here we print the CTCP message if it was unhandled...
        print("[" .. name(prefix) .. "] CTCP " .. orig_ctcp, name(prefix))
      end
    else
      if string.find(message, nick) then
        computer.beep()
      end
      print("[" .. args[1] .. "] " .. name(prefix) .. ": " .. message, args[1])
    end
  elseif command == "NOTICE" then
    print("[NOTICE] " .. message, "logger")
  elseif command == "ERROR" then
    print("[ERROR] " .. message, "special")

  ---------------------------------------------------
  -- Ignored reserved numbers
  -- -- http://tools.ietf.org/html/rfc2812#section-5.3

  elseif tonumber(command) and ignore[tonumber(command)] then
    -- ignore

  ---------------------------------------------------
  -- Command replies
  -- http://tools.ietf.org/html/rfc2812#section-5.1

  elseif command == commands.RPL_WELCOME then
    print(message, "logger")
  elseif command == commands.RPL_YOURHOST then -- ignore
  elseif command == commands.RPL_CREATED then -- ignore
  elseif command == commands.RPL_MYINFO then -- ignore
  elseif command == commands.RPL_BOUNCE then -- ignore
  elseif command == commands.RPL_LUSERCLIENT then
    print(message, "logger")
  elseif command == commands.RPL_LUSEROP then -- ignore
  elseif command == commands.RPL_LUSERUNKNOWN then -- ignore
  elseif command == commands.RPL_LUSERCHANNELS then -- ignore
  elseif command == commands.RPL_LUSERME then
    print(message, "logger")
  elseif command == commands.RPL_AWAY then
    print(string.format("%s is away: %s", name(args[1]), message))
  elseif command == commands.RPL_UNAWAY or command == commands.RPL_NOWAWAY then
    print(message, "logger")
  elseif command == commands.RPL_WHOISUSER then
    local nick = args[2]:lower()
    whois[nick].nick = args[2]
    whois[nick].user = args[3]
    whois[nick].host = args[4]
    whois[nick].realName = message
  elseif command == commands.RPL_WHOISSERVER then
    local nick = args[2]:lower()
    whois[nick].server = args[3]
    whois[nick].serverInfo = message
  elseif command == commands.RPL_WHOISOPERATOR then
    local nick = args[2]:lower()
    whois[nick].isOperator = true
  elseif command == commands.RPL_WHOISIDLE then
    local nick = args[2]:lower()
    whois[nick].idle = tonumber(args[3])
  elseif command == commands.RPL_WHOISSECURE then
    local nick = args[2]:lower()
    whois[nick].secureconn = "Is using a secure connection"
  elseif command == commands.RPL_ENDOFWHOIS then
    local nick = args[2]:lower()
    local info = whois[nick]
    if info.nick then print("Nick: " .. info.nick, "logger") end
    if info.user then print("User name: " .. info.user, "logger") end
    if info.realName then print("Real name: " .. info.realName, "logger") end
    if info.host then print("Host: " .. info.host, "logger") end
    if info.server then print("Server: " .. info.server .. (info.serverInfo and (" (" .. info.serverInfo .. ")") or ""), "logger") end
    if info.secureconn then print(info.secureconn, "logger") end
    if info.channels then print("Channels: " .. info.channels, "logger") end
    if info.idle then print("Idle for: " .. info.idle, "logger") end
    whois[nick] = nil
  elseif command == commands.RPL_WHOISCHANNELS then
    local nick = args[2]:lower()
    whois[nick].channels = message
  elseif command == commands.RPL_CHANNELMODEIS then
    print("Channel mode for " .. args[1] .. ": " .. args[2] .. " (" .. args[3] .. ")", "logger")
  elseif command == commands.RPL_NOTOPIC then
    print("No topic is set for " .. args[1] .. ".", "logger")
  elseif command == commands.RPL_TOPIC then
    print("Topic for " .. args[1] .. ": " .. message, "logger")
  elseif command == commands.RPL_NAMREPLY then
    local channel = args[3]
    table.insert(names[channel], message)
  elseif command == commands.RPL_ENDOFNAMES then
    local channel = args[2]
    --print("[Info] User list updated")
    --print("Users on " .. channel .. ": " .. (#names[channel] > 0 and table.concat(names[channel], " ") or "none"))
    printUsers(table.concat(names[channel], " "))
    names[channel] = nil
  elseif command == commands.RPL_MOTDSTART then
    if options.motd then
      print(message .. args[1], "logger")
    end
  elseif command == commands.RPL_MOTD then
    if options.motd then
      print(message, "logger")
    end
  elseif command == commands.RPL_ENDOFMOTD then
    if(target == nil) then
      print("Нажмите Enter, чтобы присоединиться к каналу по умолчанию \""..defaultChannel..'"', "special")
    end
  elseif command == commands.RPL_HELPSTART or 
  command == commands.RPL_HELPTXT or 
  command == commands.RPL_ENDOFHELP then
    print(message, "logger")
  elseif command == commands.ERR_NOSUCHCHANNEL then
    print("[ERROR]: " .. message, "logger")
    target = prevtarget
  elseif command == commands.ERR_BANLISTFULL or
  command == commands.ERR_BANNEDFROMCHAN or
  command == commands.ERR_CANNOTSENDTOCHAN or
  command == commands.ERR_CHANNELISFULL or
  command == commands.ERR_CHANOPRIVSNEEDED or
  command == commands.ERR_ERRONEUSNICKNAME or
  command == commands.ERR_INVITEONLYCHAN or
  command == commands.ERR_NICKCOLLISION or
  command == commands.ERR_NOSUCHNICK or
  command == commands.ERR_NOTONCHANNEL or
  command == commands.ERR_UNIQOPRIVSNEEDED or
  command == commands.ERR_UNKNOWNMODE or
  command == commands.ERR_USERNOTINCHANNEL or
  command == commands.ERR_WASNOSUCHNICK or
  command == commands.ERR_MODELOCK then
    print("[ERROR]: " .. message, "logger")
  elseif tonumber(command) and (tonumber(command) >= 200 and tonumber(command) < 400) then
    print("[Response " .. command .. "] " .. table.concat(args, ", ") .. ": " .. message, "logger")

  ---------------------------------------------------
  -- Error messages. No real point in handling those manually.
  -- http://tools.ietf.org/html/rfc2812#section-5.2

  elseif tonumber(command) and (tonumber(command) >= 400 and tonumber(command) < 600) then
    print("[Error] " .. table.concat(args, ", ") .. ": " .. message, "logger")

  ---------------------------------------------------
  -- Unhandled message.

  else
    print("Unhandled command: " .. command .. ": " .. message, "logger")
  end
end

-- catch errors to allow manual closing of socket and removal of timer.
local result, reason = pcall(function()
  term.clear()
  print("Царствуй, Эларий!", "special")

  -- avoid sock:read locking up the computer.
  sock:setTimeout(0.05)

  sock:write(string.format("NICK %s\r\n", nick))
  sock:write(string.format("USER %s 0 * :%s [OpenComputers]\r\n", nick:lower(), nick))
  sock:flush()

  timer = event.timer(0.5, function()
    if not sock then
      return false
    end
    repeat
      local ok, line = pcall(sock.read, sock)
      if ok then
        if not line then
          print("Connection lost.", "logger")
          sock:close()
          sock = nil
          os.execute("sleep 2")
          term.clear()
          return false
        end
        line = text.trim(line) -- get rid of trailing \r
        local match, prefix = line:match("^(:(%S+) )")
        if match then line = line:sub(#match + 1) end
        local match, command = line:match("^(([^:]%S*))")
        if match then line = line:sub(#match + 1) end
        local args = {}
        repeat
          local match, arg = line:match("^( ([^:]%S*))")
          if match then
            line = line:sub(#match + 1)
            table.insert(args, arg)
          end
        until not match
        local message = line:match("^ :(.*)$")

        if callback then
          local result, reason = pcall(callback, prefix, command, args, message)
          if not result then
            print("Error in callback: " .. tostring(reason), "logger")
          end
        end
        handleCommand(prefix, command, args, message)
      end
    until not ok
  end, math.huge)

  -- command history.
  local history = {}

  repeat   
    local w, h = component.gpu.getResolution()
    term.setCursor(chatX-1, inputY)
    term.write(">")
    local line = term.read(history)
    if sock and line and line ~= "" then
      if(target == nil) then
        line = ""
        target = defaultChannel
        sock:write("JOIN "..defaultChannel.."\r\n")
        sock:flush()
      end 
      requestUsers(target)
      
      line = text.trim(line)
      if line:lower():sub(1,4) == "/me " then
        print("[" .. (target or "?") .. "] " .. nick .. " " .. line:sub(5), nick)
      elseif line~="" then
        print("[" .. (target or "?") .. "] " .. nick .. ": " .. line, nick)
      end
      if line:lower():sub(1, 5) == "/msg " then
        local user, message = line:sub(6):match("^(%S+) (.+)$")
        if message then
          message = text.trim(message)
        end
        if not user or not message or message == "" then
          print("Invalid use of /msg. Usage: /msg nick|channel message.", "logger")
          line = ""
        else
          prevtarget = target
          target = user
          line = "PRIVMSG " .. target .. " :" .. message
        end
      elseif line:lower():sub(1, 6) == "/join " then
        local channel = text.trim(line:sub(7))
        if not channel or channel == "" then
          print("Invalid use of /join. Usage: /join channel.", "logger")
          line = ""
        else
          prevtarget = target
          target = channel
          line = "JOIN " .. channel
        end
      elseif line:lower():sub(1, 5) == "/lua " then
        local script = text.trim(line:sub(6))
        local result, reason = load(script, "=stdin", nil, setmetatable({print=print, socket=sock, nick=nick}, {__index=_G}))
        if not result then
          result, reason = load("return " .. script, "=stdin", nil, setmetatable({print=print, socket=sock, nick=nick}, {__index=_G}))
        end
        line = ""
        if not result then
          print("Error: " .. tostring(reason), "logger")
        else
          result, reason = pcall(result)
          if not result then
            print("Error: " .. tostring(reason), "logger")
          elseif type(reason) == "function" then
            callback = reason
          elseif reason then
            line = tostring(reason)
          end
        end
      elseif line:lower():sub(1,4) == "/me " then
        if not target then
          print("No default target set. Use /msg or /join to set one.", "logger")
          line = ""
        else
          line = "PRIVMSG " .. target .. " :\001ACTION " .. line:sub(5) .. "\001"
        end
      elseif line:sub(1, 1) == "/" then
        line = line:sub(2)
      elseif line ~= "" then
        if not target then
          print("No default target set. Use /msg or /join to set one.", "logger")
          line = ""
        else
          line = "PRIVMSG " .. target .. " :" .. line
        end
      end
      if line and line ~= "" then
        sock:write(line .. "\r\n")
        sock:flush()
      end
    end
  until not sock or not line
end)

if sock then
  sock:write("QUIT\r\n")
  sock:close()
end
if timer then
  event.cancel(timer)
end

if not result then
  error(reason, 0)
end
return reason