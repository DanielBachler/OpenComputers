--[
--  !TODO
--  control from base with wireless
--]

--[Setting up needed vars --]
local robot = require("robot")
local component = require("component")
local gen = component.generator
local inv = component.inventory_controller
local sides = require("sides")

--Generic helper functions

--[Scans inventory at given slot and attempts to refill--]
function refillItem(slot)
  item = inv.getStackInInternalSlot(slot)
  for i = 1, 27, 1 do
    temp = inv.getStackInInternalSlot(i)
    if temp ~= nil then
      if item.name == temp.name then
        robot.select(i)
        robot.transferTo(slot)
        break
      end
    end
  end
end

--Moves the robot in the indicated direction
function moveS(side)
  moved = false
  if side == sides.forward then
    moved = robot.forward()
  elseif side == sides.up then
    moved = robot.up()
  elseif side == sides.down then
    moved = robot.down()
  elseif side == sides.right then
    moved = robot.right()
  elseif side == sides.left then
    moved = robot.left()
  elseif side == sides.back then
    moved = robot.back()
  end
  return moved
end

--Makes sure the robot moves the to the wanted block
function move(side)
  success = moveS(side)
  if success then
    --nothing
  else
    dig(side)
    move(side)
  end
end

--Digs to the side specified
function digS(side)
  if side == sides.forward then
    robot.swing()
  elseif side == sides.up then
    robot.swingUp()
  elseif side == sides.down then
    robot.swingDown()
  end
end

--Compares in given direction
function compareS(side)
  if side == sides.forward then
    return robot.compare()
  elseif side == sides.down then
    return robot.compareDown()
  elseif side == sides.up then
    return robot.compareUp()
  end
end

--[Selects the right tool to dig a block--]
function dig(side)
  --[Checks if gravel, if so equips shovel and swings then puts hammer back, otherwise just swings hammer--]
  robot.select(28)
  isGravel = robot.compareS(side)
  --Checks for dirt
  robot.select(27)
  isDirt = robot.compareS(side)
  --Mines with the apporiate tool
  if isGravel or isDirt then
    robot.select(29)
    inv.equip()
    robot.select(28)
    digS(side)
    robot.select(29)
    inv.equip()
  else
    digS(side)
  end
end

--Specific functions

--[Refuels the robot as needed--]
function refuel()
  refillItem(32)
  if gen.count() < 32 then
    robot.select(32)
    temp = inv.getStackInInternalSlot(32)
    if temp.size < 32 then
      gen.insert(temp.size - 1)
    else
      gen.insert(32)
    end
  else
    print(gen.count())
  end
end

--[Dumps items into ender chest--]
function dumpItems()
  robot.select(31)
  robot.place()
  for i = 1, 27, 1  do
    robot.select(i)
    if i < 28 then
      inv.dropIntoSlot(sides.front, i)
    else
      inv.dropIntoSlot(sides.front, i - 5)
    end
  end
  robot.select(31)
  dig(sides.forward)
end

--[Sets up enderchest--]
function setUpEnder()
  refuel()
  move(sides.back)
  move(sides.down)
  robot.select(30)
  robot.place()
  move(sides.up)
  dumpItems()
end

--[Mines a 3x3 in front--]
function threeXthree()
  dig(sides.forward)
  move(sides.forward)
  robot.turnRight()
  dig(sides.forward)
  dig(sides.down)
  dig(sides.up)
  move(sides.down)
  dig(sides.forward)
  robot.turnRight()
  robot.turnRight()
  dig(sides.forward)
  move(sides.up)
  dig(sides.forward)
  move(sides.up)
  dig(sides.forward)
  robot.turnRight()
  robot.turnRight()
  dig(sides.forward)
  robot.turnLeft()
  move(sides.down)
end

--[Resets for a new row--]
function newRow(dir)
  if dir % 2 == 0 then
    robot.back()
    robot.turnLeft()
    move(sides.forward)
    threeXthree()
    threeXthree()
    threeXthree()
    robot.back()
    robot.turnLeft()
    move(sides.forward)
  else
    robot.back()
    robot.turnRight()
    move(sides.forward)
    threeXthree()
    threeXthree()
    threeXthree()
    robot.back()
    robot.turnRight()
    move(sides.forward)
  end
end

--[Checks inventory for empty slot--]
function checkInv()
  slot = true
  for i = 1, 29, 1 do
    if inv.getStackInInternalSlot(i) == nil then
      slot = false
      break
    end
  end
  return slot
end

--[Mines a square of the given size--]
function mine(size)
  refuel()
  for y = 0, size, 3 do
    for x = 0, size, 1 do
      threeXthree()
      full = checkInv()
      if full then
        setUpEnder()
      end
    end
    newRow(y)
  end
end

mine(arg[1])
