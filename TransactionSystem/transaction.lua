local fs        = require 'filesystem'
local unicode   = require 'unicode'
local event     = require 'event'

local dir = '/home/transactions'
local shift = 0
local balance = 0
local userName = 'Неизвестно'
local file

print('[ИНФО] Учётная система ГнГ запущена!\nДобро пожаловать!\n')

event.listen('magData', function(eventName, userID, newUserName, dataTag, UUID, locked, index)
  userName = newUserName
  print('[ИНФО] Новый пользователь идентифицирован: ', newUserName)
end)

if (not fs.exists(dir)) then
  fs.makeDirectory(dir)
end

function getFileName()
  return os.date('%y%m%d')..'_'..shift..'.trs'
end

function startShift()
  shift = shift + 1
  file = io.open(dir..'/'..getFileName(), 'w')
end

function readBalance()
  print('Введите текущую сумму:')
  local input = io.read()
  local newBalance = tonumber(input)

  print('Баланс:', balance)
  
  balance = newBalance

  file:write('Начальный баланс: ', balance, '\n')
end

function waitForInput()
  local input = io.read()
  local symbol = input:sub(1, 1)

  if (symbol == '=') then
    finishShift()
  elseif (symbol == '+' or symbol == '-') then
    processTransaction(input, symbol)
  elseif (symbol == '0') then
    return
  end

  waitForInput()
end

function processTransaction(input, symbol)
  local numStr = symbol..input:match('%d+')
  local note = unicode.sub(input, numStr:len() + 2)
  local num = tonumber(numStr)

  balance = balance + num

  local outputLine = '['..os.date('%X')..'] '..numStr..'; От: '..userName..'; Прим.: '..note..'\n'

  file:write(outputLine)
  print(outputLine)
end

function finishShift()
  file:write('Конечный баланс: ', balance, '\n')
  file:close()

  file = io.open(dir..'/'..getFileName(), 'r')
    print(file:read('*a'))
  file:close()

  startShift()
end

function showHelp()
  print('+<сумма> <примечание> - добавить сумму к балансу. Пример: +100 Продажа товара\n')
  print('-<сумма> <примечание> - отнять сумму от баланса. Пример: -100 Покупка товара\n')
  print('= - завершить смену и вывести историю тразакций.\n')
  print('0 - завершить работу.\n')
end

startShift()
readBalance()
showHelp()
waitForInput()
