--shows RFID card data
--[[
local shell = require("shell")
shell.setWorkingDirectory("/mnt/335/");
shell.execute("crd")
]]--

local event = require("event")
local term = require("term")
local unicode = require("unicode") 
local rfidreader = require("component").os_rfidreader

require("component").gpu.setResolution(48,12)

function split(data, pat) 
  local ret = {} 
  for i in unicode.gmatch(data,pat) do 
    table.insert(ret,i) 
  end 
  return ret 
end 

function pt(ndict) for k,v in pairs(ndict) do print(k) end end

function scanRfid(ndist)
  rfidreader.scan(ndist)
  local _,_,nick,dist,data,id = event.pull(0.2, "rfidData")
  term.clear()
  if(data ~= nil) then
    -- ,"\n",
    pt(split(data,"/+"))
  -- type/nick/data
    -- print(nick)
    -- print(data)
  end
  return nick, data
end

term.clear()
-- while true do
  scanRfid(4)
  -- require("os").sleep(0.5)
-- end