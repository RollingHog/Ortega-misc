--Учётная программа для реализации "Электронного правительства". Ну, прообраз.
local unicode   = require("unicode") 
local event = require("event")
local component = require("component")
local term = require("term")
local prn = component.openprinter

local writer = require("component").os_cardwriter
component.motion_sensor.setSensitivity(0.1)
term.clear()

function pt(ndict) for k,v in pairs(ndict) do print(k) end end

local prog_options = {
  ["У"] = "Универсальный Идентификатор"
  , [""] = "Выход"
  , ["-"] = "Выход"
}

local guilds = {
  ["Э"] = "Энваль"
  ,["Н"] = "Нихтиль"
  ,["М"] = "Мериум"
  ,["У"] = "Урбус"
  ,["И"] = "Инрад"
  ,["+"] = "гражданин"
  ,["-"] = "номель"
}

local civil_types = {
  ["Д+"] = "Дикторум"
  , ["Д-"] = "Помощник Дикторума"
  , ["И"] = "Инцилиам"
  , ["М"] = "Мелит"
  , ["Н"] = "Номекунор"
  , ["П"] = "Представитель"
  , ["С"] = "Стратег"
  , ["Х+"] = "Хранитель"
  , ["Х-"] = "Коллегия Хранителя"
  , ["-"] = "нет"
}

local races={
  ["Ав"] = "Алварий"
  ,["Ач"] = "Алчущий"
  ,["Ах"] = "Ах'нэр"
  ,["Б"] = "Буфон"
  ,["Гз"] = "Гизка"
  ,["Гн"] = "Гинерия"
  ,["Гл"] = "Глорания"
  ,["Гк"] = "Гонканин"
  ,["Гп"] = "Гоплон"
  ,["Гу"] = "Гуркх"
  ,["Ж"] = "Железорожденный"
  ,["Ка"] = "Кандорец"
  ,["Ки"] = "Киннал"
  ,["Л"] = "Лунд"
  ,["Ме"] = "Мергер"
  ,["Ми"] = "Минил"
  ,["Но"] = "Нордим"
  ,["НГ"] = "Немический гибрид"
  ,["Ор"] = "Орхан"
  ,["Ос"] = "Оставленный"
  ,["Р"] = "Рыболюд"
  ,["Св"] = "Серв"
  ,["Ск"] = "Серка"
  ,["Фа"] = "Фамм"
  ,["Фе"] = "Фенх"
  ,["Хи"] = "Химера"
  ,["Хо"] = "Хорданец"
  ,["Ци"] = "Цифириал"
  ,["Че"] = "Человек"
  ,["ЧП"] = "Человек-птица"
  ,["Ши"] = "Шифтер"
  ,["Шу"] = "Шурп"
  ,["Э"] = "Энлимиец"
}	

function readKey()
  local specCode, code, playerName
  while true do
    if code == nil
      or code == 15 and specCode == 9 
      or code == 42 and specCode == 0
      or code == 56 and specCode == 0
      or code == 58 and specCode == 0
      or code == 28 and specCode == 13
    then
      _, _, specCode, code, playerName = event.pull(15, "key_down")
    elseif code == 46 and specCode == 3 then
      os.exit()
    else
      break
    end
  end
    print(specCode, code)
    local c = unicode.char(specCode)
    print(c)
  return c
end

function readFromDict(ndict, prompt)
  print("---------\n"..prompt..": ")
  for k,v in pairs(ndict) do 
    print(k..": "..v) 
  end
  print(">")
  local c1 = unicode.upper(readKey())
  local res
  if(ndict[c1]==nil)then
    res = ndict[c1..readKey()]
  else
    res = ndict[c1]
  end
  if(res == nil) then
    print("Ключ не найден, ещё раз!")
    return readFromDict(ndict, prompt)
  end
  print(res)
  return res
end

function getRace() 
  return readFromDict(races, "Раса")
end

function getGuild() 
  return readFromDict(guilds, "Дом")
end

function getCivilType() 
  return readFromDict(civil_types, "Должность")
end

function readStr(prompt, default)
  io.write(prompt..": ")
  local t = io.read()
  if (t~=nil) then
    return t
  else
    return default
  end
end
-- event.listen("motion", onMotion)

-- while true do

function makeCard(nRace, nGuild, nType) 
  local nstr
  local nName = readStr("ФИО")
  print(nRace, nName, nGuild, nType)
  print("Встаньте на красный квадрат")
  local _, _, nx, ny, nz, nNick = event.pull(30, "motion")
  print("Считано: "..nNick)
  --*оттиснуто*
  if (nGuild ~= "номель") then
    nstr = nRace.." "..nName..", дом "..nGuild
  else
    nstr = nRace.." "..nName..", номель"
  end
  if (nType ~= "нет") then
    nstr = nstr..", "..nType..""
  end
  writer.write("CID/"..nNick.."/"..nstr, "§r §2[УИК]§r Владелец: "..nstr, true)
  
  file = io.open(nNick..".uid", "w")
	file:write(nstr.."\n")
	file:close()
  
  print("Создание карты завершено!\n")
end

function makeNewCard()
  term.clear()
  print("Создание новой Универсальной Идентификационной Карты:")
  makeCard(getRace(), getGuild(), getCivilType())
end 

function showHelp() 
  print("help me")
end

-- function printConfirmationDoc()
function printHouseDoc()
  local header = "§r§3ЗАВЕРЕНИЕ§r"
  local text = {
    ["0"] = "Настоящим заверяется, что "
    , ["1"] = "яляется владельцем дома, расположенного по адресу"
  }
  prn.setTitle(header)
  for k,v in pairs(text) do
    print(k) 
  end
  
end

local cmdkey

printHouseDoc()

-- while true do
  -- io.write("/пд>")
  -- cmdkey = unicode.lower(readKey())
  -- if(cmdkey=="\\" or cmdkey=="/") then
    -- os.exit()
  -- elseif(cmdkey=="п") then
    -- makeNewCard() 
  -- elseif(cmdkey=="д") then
    -- printHouseDoc() 
-- -- require("os").sleep(0.8)
  -- else
    -- showHelp()
  -- end
-- end