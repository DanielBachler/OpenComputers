--[
--  TODO
--  control from base with wireless
--  check energy for refuel
--]

--List of slots used by program and what they are
coal = 32
enderChest = 31
fortunePick = 30
shovel = 29
gravel = 28
dirt = 27
lapis = 26
diamond = 25
repairChest = 24
invStart = 23

--[Setting up needed vars --]
local robot = require("robot")
local component = require("component")
local gen = component.generator
local inv = component.inventory_controller
local sides = require("sides")

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

--Checks if any tools need repairs and puts them into an ender chest to be repaired if they do
function repairItems()
  repairHammer = false
  repairShovel = false
  repairPick = false
  --Gets durability of hammer
  temp, hammerCurrent, hammerMax = robot.durability()
  hammerRatio = hammerCurrent / hammerMax
  if hammerRatio < 0.5 then
    repairHammer = true
  end
  --Gets durability of shovel
  robot.select(shovel)
  robot.equip()
  temp, shovelCurrent, shovelMax = robot.durability()
  shovelRatio = shovelCurrent / shovelMax
  robot.equip()
  if shovelRatio < 0.5 then
    repairShovel = true
  end
  --Gets durability of fortune pick
  robot.select(fortunePick)
  robot.equip()
  temp, pickCurrent, pickMax = robot.durability()
  pickRatio = pickCurrent / pickMax
  robot.equip()
  if pickRatio < 0.5 then
    repairPick = true
  end
  --All ratios gathered, now tools needing repair are placed into ender enderChest
  --If no tools need repair nothing happens
  if repairHammer or repairShovel or repairPick then
    --Sets up ender chest platform
    robot.select(dirt)
    moveS(sides.back)
    moveS(sides.down)
    robot.place()
    moveS(sides.up)
    --Places ender chest
    robot.select(repairChest)
    robot.place()
    if repairHammer then
      --Puts the hammer into the dirt slot, and drops it into the ender chest
      robot.select(dirt)
      inv.equip()
      inv.dropIntoSlot(sides.front, 1)
      for i = 0, 1000, 1 do
        --Loops to kill time
      end
      while inv.getStackInInternalSlot(dirt) == nil do
        inv.suckFromSlot(sides.front, 1)
      end
      inv.equip()
    end
    --Puts the shovel in the ender chest and loops until it gets it back
    if repairShovel then
      robot.select(shovel)
      inv.dropIntoSlot(sides.front, 1)
      for i = 0, 1000, 1 do
        --killing time
      end
      while inv.getStackInInternalSlot(shovel) == nil do
        inv.suckFromSlot(sides.front, 1)
      end
    end
    --Puts pick into ender chest and loops until it gets it back
    if repairPick then
      robot.select(fortunePick)
      inv.dropIntoSlot(sides.front, 1)
      for i = 0, 1000, 1 do
        --killing time
      end
      while inv.getStackInInternalSlot(fortunePick) == nil do
        inv.suckFromSlot(sides.front, 1)
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
  robot.select(gravel)
  isGravel = compareS(side)
  --Checks for dirt
  robot.select(dirt)
  isDirt = compareS(side)
  --Checks for lapis and diamond
  robot.select(diamond)
  fortune = compareS(side)
  if ~fortune then
    robot.select(lapis)
    fortune = compareS(side)
  end
  --Mines with the apporiate tool
  --Digs gravel and dirt with a shovel
  if isGravel or isDirt then
    robot.select(shovel)
    inv.equip()
    robot.select(gravel)
    digS(side)
    robot.select(shovel)
    inv.equip()
  --Mines lapis and diamond with a fortune pick
  elseif fortune then
    robot.select(fortunePick)
    inv.equip()
    robot.select(1)
    digS(side)
    robot.select(fortunePick)
    inv.equip()
  --Anything else is just mined with hammer
  else
    digS(side)
  end
end

--[Refuels the robot as needed--]
function refuel()
  refillItem(coal)
  if gen.count() < 32 then
    robot.select(coal)
    temp = inv.getStackInInternalSlot(coal)
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
  refuel()
  robot.select(enderChest)
  robot.place()
  for i = 1, invStart, 1  do
    robot.select(i)
    if i < 28 then
      inv.dropIntoSlot(sides.front, i)
    else
      inv.dropIntoSlot(sides.front, math.floor(i / 2))
    end
  end
  robot.select(enderChest)
  digS(sides.forward)
end

--[Checks inventory for empty slot--]
function checkInv()
  slot = true
  for i = 1, invStart, 1 do
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
  for i = 1, size, 1 do
    for j = 0, size, 1 do
      dig(sides.front)
    end
    refuel()
  end
end

mine(arg[1])
