--Учётная программа для реализации "Электронного правительства". Ну, прообраз.
--library should always return an object with func-props
local event = require("event")
local fs = require("filesystem")
local component = require("component")
local term = require("term")
local unicode   = require("unicode") 
local internet = require("internet")
local serialization   = require("serialization") 

local prn = component.openprinter
local writer = component.os_cardwriter
local rfidreader = component.os_rfidreader
component.motion_sensor.setSensitivity(0.1)

local exit_raw = os.exit
os.exit = function()
  os.exit = exit_raw()
  os.exit()
end

local operator_nick =' '

local dicts = {}
dicts.ordered={}

function createOrderedDict(nName, nDict)
  dicts[nName] = nDict
  local tt={}
  for k in pairs(dicts[nName]) do table.insert(tt, k) end
  table.sort(tt)
  dicts.ordered[nName] = tt
end

createOrderedDict('guild_names', {
  ["Э"] = "Энваль"
  ,["Н"] = "Нихтиль"
  ,["М"] = "Мериум"
  ,["У"] = "Урбус"
  ,["И"] = "Инрад"
  ,["+"] = "гражданин"
  ,["-"] = "номель"
})

createOrderedDict('citizen_positions', {
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
})

createOrderedDict("building_owner_types", {
  ['Г']='Город',
  ['Ц']='цил',
  ['К']='компания'})

createOrderedDict('races', {
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
  ,["-"] = "Нет"
})

createOrderedDict('acc_types', {
  ['Д']='дебет',
  ['К']='кредит',
  ['К']='кроу'
})

createOrderedDict('currency_types', {
  ['1']='главная',
  ['2']='свободная'
})

createOrderedDict('acc_owner_types', {
  ['Ц']='цил', 
  ['К']='компания'
})

createOrderedDict('building_types', {
  ["-"]="другое",
  ["+"]="жильё",
  ["А"]="азартные игры",
  ["Е"]="едальня",
  ["З"]="зрелища",
  ["М"]="медицина",
  ["О"]="офис",
  ["П"]="производство",
  ["Р"]="развлечения",
  ["С"]="склад",
  ["Т"]="торговля",
  ["У"]="учёба",
  ["Ф"]="финансы"
})

function pt(ndict) for k,v in pairs(ndict) do print(k,":",v) end end

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
      error("readKey interruption")
    else
      break
    end
  end
  -- print(specCode, code)
  local c = unicode.char(specCode) 
  print(c)
  return c, playerName
end

function readPlusMinus(prompt)
  print(prompt.." (+/-)")
  local res = readKey()
  if(res=='+' or #res==0) then
    return true
  else
    return false
  end
end

function readStr(prompt, default)
  io.write(prompt..": ")
  local t = io.read()
  if (#t~=0) then
    return t
  else
    return default
  end
end

function readFromDict(nDictName, prompt)
  print("\n"..prompt..": ")
  for _, k in pairs(dicts.ordered[nDictName]) do 
    print(k..": "..dicts[nDictName][k]) 
  end
  print(">")
  local c1, tNick = readKey()
  c1 = unicode.upper(c1)
  local res
  if(dicts[nDictName][c1]==nil)then
    c1 = c1..readKey()
    res = dicts[nDictName][cq]
  else
    res = dicts[nDictName][c1]
  end
  if(res == nil) then
    print("Ключ не найден, ещё раз!")
    return readFromDict(nDictName, prompt)
  end
  print(res.."\n---------")
  return res, tNick, c1
end

function cutByPrevSpace(nstr, nlen) 
  local res = unicode.sub(nstr, 1, nlen)
  
  for i = 1, nlen do 
    if(unicode.sub(res, i,i)=="\n")then
      res = unicode.sub(res,1,i-1)
      return res, unicode.sub(nstr, unicode.len(res)+2)
    end
  end
  
  if(unicode.len(nstr) <= nlen)then
    return nstr, ""
  end
  
  for i = nlen, 1, -1 do 
    if(unicode.sub(res, i,i)==" " or unicode.sub(res, i,i)=="\n")then
      res = unicode.sub(res,1,i-1)
      break
    end
  end
  if(unicode.len(res) == nlen) then
    return res, unicode.sub(nstr, unicode.len(res)+1)
  else
    return res, unicode.sub(nstr, unicode.len(res)+2)
  end
end

function cutAndPrint(ntitle,  nstr)
  local i=nstr
  local t=""
  prn.setTitle("§r"..ntitle)
  while(i~="")do
    t, i = cutByPrevSpace(i, 30)
    prn.writeln(t)
  end
  prn.print()
end

function getRace() 
  return readFromDict('races', "Раса")
end

function getGuild() 
  return readFromDict('guild_names', "Дом")
end

function getCitizenPosition() 
  return readFromDict('citizen_positions', "Должность")
end

function saveToDir(ndir, nfilename, ndata)
  if (ndir == "") then
    ndir = "tmp_dir"
  end
  ndir = "/home/"..ndir
  if(not fs.exists(ndir)) then
    fs.makeDirectory(ndir)
    local file = io.open(ndir.."/.lastid", "w")
    file:write("0")
    file:close()
  end
  
  if (nfilename == "") then --filename need to be taken from lastid
    local file = io.open(ndir.."/.lastid", "r")
    nfilename = file:read(10)
    print("Имя файла: "..nfilename)
    file:close()
    local file = io.open(ndir.."/.lastid", "w")
    file:write(nfilename+1)
    file:close()
  end
  
  local file = io.open(ndir.."/"..nfilename, "w")
  file:write(ndata)
  file:close()

  local file = io.open(ndir.."/.tosubmit", "a")
  file:write(nfilename)
  file:close()
  
  return ndir.."/"..nfilename
end

function sendFile() 
  
end

function submitCmd(naddr, ntable, nfolder, nfilename)
  local ok, res = pcall(function () internet.request('http://localhost:8084'..naddr, serialization.serialize(ntable))() end)
  local tid = "000"
  if(not ok) then 
    local tfn = saveToDir(nfolder, nfilename, naddr.."\n"..serialization.serialize(ntable))
    print("Нет связи с сервером, данные сохранены локально: "..tfn)
  end
  return ok, res, tid
end

function getNickFromInput(nprompt)
  local t = event.pull("key_up")
  print("Проверка биометрии, внимание на второй экран!")  
  for k,_ in pairs(component.list("screen")) do
    if(k ~= component.screen.address) then
      component.gpu.bind(k)
    end
  end
  term.clear()
  if(nprompt ~= nil) then
    print(nprompt)
  end
  print("Нажмите любую клавишу для биометрической идентификации")
  _, _, _, _, tNick = event.pull("key_up")
  print("Биометрия считана")
  os.sleep(0.6)
  term.clear()
  component.gpu.bind(component.screen.address)
  term.clear()
  print("Биометрия считана: "..tNick)
  return tNick
end

function getNickFromMotion()
  print("Встаньте на красный квадрат")
  local _, _, nx, ny, nz, nNick = event.pull(30, "motion")
  print("Считано: "..nNick)
  return nNick
end

function splitBySymbol(nstr, nchar)
  local res={}
  local t="_"
  local cnt=0
  while (true) do
    t=""
    for i = 1, unicode.len(nstr) do 
      if(unicode.sub(nstr, i,i)==nchar) then
        t = unicode.sub(nstr, 1,i-1)
        nstr = unicode.sub(nstr, i+1)
        break
      end
    end
    if(t=="")then
      break
    end
    res[cnt]=t
    cnt = cnt+1
  end
  res[cnt]=nstr
  return res
end 

function getNickFromRFID()
  rfidreader.scan(5)
  local _,_,nick0,dist,data,id = event.pull(1, "rfidData")
  local card_type
  local nick
  local other
  if(data ~= nil) then
    card_type, nick, other = table.unpack(splitBySymbol(data, "/"))
  end
  return nick, other
end

function makeCard(nNick, nName, nRace, nRace2, nGuild, nCivilType) 
  local nstr
  print(nRace, nName, nGuild, nCivilType)
  
  --*оттиснуто*
  if (nGuild ~= "номель") then
    nstr = nRace.." "..nName..", дом "..nGuild
  else
    nstr = nRace.." "..nName..", номель"
  end
  if (nCivilType ~= "нет") then
    nstr = nstr..", "..nCivilType..""
  end 
  local ok=false
  local res=""
  while (not ok) do
    ok, res = writer.write("CID/"..nNick.."/"..nstr, "§r §2[УИК]§r Владелец: "..nstr, true)
    if(ok) then
      print("Создание карты завершено!\n")
      return
    end
    print(res.."\nУстраните проблему и нажмите любую клавишу для продолжения")
    io.read()
  end
end

function newCivil()
  term.clear()
  print("Регистрация гражданина")
  
  local njson = {
      nick = getNickFromInput("Биометрическое сканирование регистрируемого"),
      full_name = readStr("ФИО"),
      race = getRace(),
      race2 = "",
      guild = getGuild(),
      registrator_id = operator_nick,
      position = getCitizenPosition()
    }
  local res = submitCmd('/user/new', njson, 'user', njson.nick)
  
  print("Создание новой Универсальной Идентификационной Карты:")
  makeCard(njson.nick, njson.full_name, njson.race, njson.race2, njson.guild, njson.position)  
  
  newBankAccount('дебет', 'цил', njson.nick, 1, 0)
  newBankAccount('дебет', 'цил', njson.nick, 2, 0)
  
  if(readPlusMinus("Зарегистрировать жилой дом в собственности?")) then
    newHouse("Цил", njson.nick)
  end
end 

function newCompany()

end

function newHouse(nowner_type, nowner_id)
  print("Регистрация нового здания: ")
  local njson = {      
    name = readStr("Название дома",""), 
    building_type = readFromDict('building_types',"Назначение здания"),
    owner_type = nowner_type,
    owner_id = nowner_id,
    x = tonumber(readStr("Координаты:\nX", -1)), 
    y = tonumber(readStr("Y", -1)), 
    z = tonumber(readStr("Z", -1)),
    registrator_id = operator_nick,
  }
  if(nowner_type == nil) then
    njson.owner_type = readFromDict('building_owner_types', "Тип владельца")
  end
  if(nowner_id == nil) then
    if (readPlusMinus("Зарегистрировать владельца через биометрию?")) then
      njson.owner_id = getNickFromInput()
    else
      njson.owner_id = readStr("ID владельца")
    end
  end
  local isOk, res, tid = submitCmd('/building/new', njson, 'building', "")
  print("Печать  свидетельства о праве собственности...")
  cutAndPrint("СВИДЕТЕЛЬСТВО О ПРАВЕ СОБСТВЕННОСТИ", 
    "§oСВИДЕТЕЛЬСТВО №000\n§oО ПРАВЕ СОБСТВЕННОСТИ§r\n\n"
    .."Настоящим заверяется, что \n"..njson.owner_type.." "..njson.owner_id
    .."\nвладеет недвижимостью "
    .."расположенной в координатах:\n"
    ..njson.x.."/"..njson.y.."/"..njson.z..";\n"
    .."целевое назначение:\n"..njson.building_type
    .."\n\nПодпись регистратора:\n"
    ..operator_nick    
    )
  print("Свидетельство о праве собственности отпечатано!")
end

-- newHouse()

function newBankAccount(nacc_type, nowner_type, nowner_id, ncurrency_type, ncurrency_amount)
  print("Регистрация нового банковского аккаунта: ")
  pcall(function() 
    print(nacc_type.." "..nowner_type.." "..nowner_id.." "..ncurrency_type.." "..ncurrency_amount)
  end)
 
  local njson = {      
    acc_type = nacc_type,
    owner_type = nowner_type,
    owner_id = nowner_id,
    currency_type = ncurrency_type,
    currency_amount = ncurrency_amount,
    registrator_id = operator_nick,
  }
  
  if(nacc_type == nil) then
    njson.acc_type = readFromDict('acc_types', "Тип аккаунта")
  end
  if(nowner_type == nil) then
    njson.owner_type = readFromDict('acc_owner_types', "Тип владельца аккаунта")
  end
  if(nowner_id == nil) then
    njson.owner_id = readStr("ID владельца счёта", 0)
  end
  if(ncurrency_type == nil) then
    njson.currency_type = readFromDict('currency_types', "Тип валюты")
  end
  if(ncurrency_amount == nil) then
    njson.currency_amount = 0
  end
  -- if()then
    -- njson.additional = 
  -- end
  
  local res = submitCmd('/account/new', njson, 'account', 
    njson.acc_type.."_"..njson.owner_type.."_"..njson.owner_id.."_"..njson.currency_type)
end

function showHelp() 
  print("help me")
end

-- function printConfirmationDoc()
-- local header = "§r§3ЗАВЕРЕНИЕ§r"

createOrderedDict('prog_options', {
  ["-"] = "-Выход"
  , ["П"] = "Паспорт (регистрация гражданина с выдачей карты)"
  , ["Д"] = "Регистрация здания"
})

local cmdkey

function mainCycle() 
  while true do
    _, operator_nick, cmdkey = readFromDict('prog_options', "Выберите режим")
    if(cmdkey=="-" or cmdkey=="/") then
      os.exit()
    elseif(cmdkey=="П") then
      newCivil() 
    elseif(cmdkey=="Д") then
      newHouse()
    else
      showHelp()
    end
  end
end

while(true) do
  local _, res = pcall(mainCycle)
  if(type(res)~="string") then
    os.exit()
  end  
  print(res)
end
-----------------------------------------------------
-- unicode = require("unicode")

-- проверка актуальности по номеру документа
-- cutAndPrint("Настоящим заверяю, что для расследования взрыва в больнице и степени виновности Винсента Урсеи была сформирована комиссия в составе:  Хеля, сына Индры; Гатора; Портера Энстанда.  Кваак", 36)

-- op = require("component").openprinter
-- op.setTitle("Заверение Z0001")
-- op.writeln("")
-- op.print()

-- event = require("event")
-- entity = require("component").os_entdetector
-- function pt(ndict) for k,v in pairs(ndict) do print(k,":",v) end end

-- local e = entity.scanPlayers(10)
-- -- while e ~= nil do
  -- pt(e)
-- -- end

-- local component = require("component")
-- local term = require("term")

-- for k,_ in pairs(component.list("screen")) do
  -- if(k ~= component.screen.address) then
    -- term.clear()
    -- component.gpu.bind(k)
    -- component.setPrimary("screen", k)
    -- term.clear()
    -- file = io.open("default_monitor", "w")
    -- file:write(k)
    -- file:close()
    -- exit()
  -- end
-- end