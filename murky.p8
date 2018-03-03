pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- murky
-- draconis

-- MIT license

-- global vars
debug=true
screenwidth = 127
screenheight = 127
speed = 6
speeds = { "vfast", "fast", "vfast", "fast", "vfast", "normal" }
monsters = {}
projectiles = {}
mapsize_y = 36
mapsize_x = 72
tiles = {}
dirs = {{0,-1}, {0,1}, {1,0}, {-1,0}}
turns = 0
shooting = false
arrows = 5
freeze = 5

entity = {}
entity.__index = entity

function entity.create(x,y,spr)
	local new_entity = {}
	setmetatable(new_entity, entity)

	new_entity.x = x
	new_entity.y = y
  new_entity.spr = spr
  new_entity.spd = "normal"

	return new_entity
end

function entity:draw()
  spr(self.spr, self.x * 8, self.y * 8)
end

-- game loop

function _init()
  -- title_init()
  game_init()
end

function _update()
  update()
end

function _draw()
  draw()
end

-- title scene

function title_init()
  update=title_update
  draw=title_draw
end

function title_update()
	if btnp(4) then
		game_init()
	end
end

function title_draw()
	local titletxt = "murky"
	local starttxt = "press z to start"
	rectfill(0,0,screenwidth, screenheight, 3)
	print(titletxt, hcenter(titletxt), screenheight/4, 10)
	print(starttxt, hcenter(starttxt), (screenheight/4)+(screenheight/2),7)
end

function title_init()
  update=title_update
  draw=title_draw
end

-- game scene

function game_init()
  player = entity.create(10,10,1)
  map_gen()

  update=game_update
  draw=game_draw
end

function game_update()
  if player_control() then
    turns += 1
    repeat
      tick()
      speed += 1
      if speed > #speeds then
        speed = 1
      end
    until should_move(player)
  end
end

-- handle button inputs
function player_control()
  local action = move
  if shooting then
    action = shoot
  end

  if (btnp(0)) then
    return action(-1,0)
  elseif (btnp(1)) then
    return action(1,0)
  elseif (btnp(2)) then
    return action(0,-1)
  elseif (btnp(3)) then
    return action(0,1)
  elseif (btnp(4)) then
    shooting = not shooting
  elseif (btnp(5)) then
    if player.spd == "normal" then
      player.spd = "vfast"
    else
      player.spd = "normal"
    end
  end
  return false
end

function should_move(entity)
  return entity.spd == speeds[speed]
end

function tick()
  foreach(monsters, function(monster)
    if should_move(monster) then
      monster_move(monster)
    end
  end)
  foreach(projectiles, function(projectile)
    if should_move(projectile) then
      projectile_move(projectile)
    end
  end)
end

function game_draw()
	rectfill(0,0,screenwidth, screenheight, 0)
  cx = player.x*8-64
  cy = player.y*8-64
  camera(cx, cy)

  map_draw()

  palt(0, false) -- make black opaque
  foreach(monsters, function(monster)
    monster:draw()
  end)
  foreach(projectiles, function(projectile)
    projectile_sprite(projectile)
    projectile:draw()
  end)
	player:draw()
  palt(0, true) -- reset black to transparent

  camera() -- reset camera

  if debug then
    minimap_draw()
  end

  -- draw ui
  rectfill(0,screenheight-6,screenwidth, screenheight, 7)
  if debug then
    print(player.x .. "," .. player.y .. " spd: " .. speed .. " tur: " .. turns, 2, screenheight-5, 0)
  elseif shooting then
    print("\x8b\x91\x94\x83 to fire", 2, screenheight-5, 0)
  elseif player.spd != "normal" then
    print("z to aim, x to cancel", 2, screenheight-5, 0)
  else
    print("z to aim, x for elven speed", 2, screenheight-5, 0)
  end
end

function map_draw()
  local ox = cx%8
  local oy = cy%8
  for my=cy/8,cy/8+16 do
		if my < mapsize_y and my >= 0 then
			for mx=cx/8,cx/8+16 do
				if mx < mapsize_x and mx >= 0 then
					local t = mget(mx,my)
          if t != 0 then
  					spr(t, mx*8-ox, my*8-oy)
          end
				end
			end
		end
	end
end

function projectile_move(projectile)
  if not projectile.hit then
    local x = projectile.x + projectile.dx
    local y = projectile.y + projectile.dy
    if walkable(x,y) then
      projectile.x = x
      projectile.y = y
    -- TODO elseif entity() -- enemy / player
    --
    else
      projectile.hit = true -- stop projectiles when they hit something
    end
  end
end

function projectile_sprite(projectile)
  if projectile.hit then
    projectile.spr = 22
  else
    if projectile.dx == 0 then
      if projectile.dy < 0 then
        projectile.spr = 6
      else
        projectile.spr = 38
      end
    else
      if projectile.dx > 0 then
        projectile.spr = 23
      else
        projectile.spr = 21
      end
    end
  end
end

function monster_move(monster)
  local dir = dirs[ range(1,4) ]
  if walkable(dir[1],dir[2]) then
    monster.x += dir[1]
    monster.y += dir[2]
  end
end

function minimap_draw()
  for x=0, mapsize_x-1 do
    for y=0, mapsize_y-1 do
      if walkable(x,y) then
        pset(x, y, mget(x,y) % 15 + 1)
      else
        pset(x, y, 0)
      end
    end
  end
  -- draw rooms
  -- for x=0, rooms_w-1 do
  --   for y=0, rooms_h-1 do
  --     local room = at(rooms, x, y)
  --     if #room.connections == 0 then
  --       for i=room.x, room.x + room.width do
  --         for j=room.y, room.y + room.height do
  --           pset(i, j, 4)
  --         end
  --       end
  --     end
  --   end
  -- end

  foreach(monsters, function(monster)
    pset(monster.x,monster.y,9)
  end)

  foreach(projectiles, function(projectile)
    pset(projectile.x,projectile.y,9)
  end)

  pset(player.x,player.y,8)
end

function mset(x,y,t)
	tiles[flr(y)*mapsize_x+flr(x)] = t
end

function mget(x,y)
	return tiles[flr(y)*mapsize_x+flr(x)]
end

function walkable(x,y)
  return not fget(mget(x,y),0)
end

function move(dx,dy)
  local x = player.x + dx
  local y = player.y + dy
  if(walkable(x,y) or debug) then
    player.x = x
    player.y = y
    return true
  else
    sfx(1)
    return false
  end
end

function shoot(dx, dy)
  local x = player.x + dx
  local y = player.y + dy
  if(walkable(x,y) or debug) then
    local projectile = entity.create(x,y,6)
    projectile.spd = "vfast"
    projectile.dx = dx
    projectile.dy = dy
    projectile.hit = false
    add(projectiles, projectile)
    shooting = false
    return true
  else
    sfx(1)
    return false
  end
end

function map_gen()
  mapseed = rnd(1000)
  genperms()
  local x, y

  for x=0, mapsize_x-1 do
    for y=0, mapsize_y-1 do

      local n = noise(x,y)
      if n > 0.3 then
        mset(x, y, 24)
      elseif n > 0.1 then
        mset(x, y, 8)
      elseif n > 0.0 then

        if (range(1,20)) == 1 then
          local monster = entity.create(x,y,3)
          add(monsters, monster)
        end

        mset(x, y, 40)
      else
        mset(x, y, 0)
      end
    end
  end
end

-- library functions
--- center align from: pico-8.wikia.com/wiki/centering_text
function hcenter(s)
	-- string length time			s the
	-- pixels in a char's width
	-- cut in half and rounded down
	return (screenwidth / 2)-flr((#s*4)/2)
end

function vcenter(s)
	-- string char's height
	-- cut in half and rounded down
	return (screenheight /2)-flr(5/2)
end

--- collision check
-- function iscolliding(obj1, obj2)
-- 	local x1 = obj1.x
-- 	local y1 = obj1.y
-- 	local w1 = obj1.w
-- 	local h1 = obj1.h
--
-- 	local x2 = obj2.x
-- 	local y2 = obj2.y
-- 	local w2 = obj2.w
-- 	local h2 = obj2.h
--
-- 	if(x1 < (x2 + w2)  and (x1 + w1)  > x2 and y1 < (y2 + h2) and (y1 + h1) > y2) then
-- 		return true
-- 	else
-- 		return false
-- 	end
-- end

function assert(a,text)
	if not a then
		error(text or "assertion failed")
	end
end

function error(text)
	cls()
	print(text)
	_update = function() end
	_draw = function() end
end

function range(min,max)
  return flr(rnd(max)) + min
end

function push(stack,item)
	stack[#stack+1]=item
end

function pop(stack)
	local r = stack[#stack]
	stack[#stack]=nil
	return r
end

function top(stack)
	return stack[#stack]
end

function at(array, x, y)
  local one = array[x]
  if one then
    return one[y]
  else
    return nil
  end
end

-- noise from tempest.p8

function noise(x,y)
	return fractal_noise_2d(6,0.65,0.025,x+mapseed,y+mapseed)
	-- local d = distance(x/2-mapsize_x/4,y-mapsize_y/2)
	-- if x < 2 or x > mapsize_x - 2 then return 0 end
	-- if y < 2 or y > mapsize_y - 2 then return 0 end
	-- return v - d*d*0.00015
end

function fractal_noise_2d(octaves,persistence,scale,x,y)
	local total = 0
	local freq = scale
	local amp = 1
	local maxamp = 0

	for i=1,octaves do
		total += perlin_noise_2d(x * freq, y * freq) * amp
		freq *= 2
		maxamp += amp
		amp *= persistence
	end

	return total / maxamp
end

permutation = {}

function genperms()
	local p = {}
	for i=0,255 do
		add(p,i)
	end
	for i=0,255 do
		add(p,i)
	end
	shuffle(p)
	permutation = p
end

function perlin_noise_2d(x,y)
	local xi = flr(x) % 255
	local yi = flr(y) % 255
	local xf = x-flr(x)
	local yf = y-flr(y)

	local u = fade(xf)
	local v = fade(yf)

	local p = permutation

	local aa = p[p[xi+1]+yi+1]
	local ab = p[p[xi+1]+yi+2]
	local ba = p[p[xi+2]+yi+1]
	local bb = p[p[xi+2]+yi+2]

	local x1,y1,x2,y2

	x1 = lerp(grad(aa,xf,yf),grad(ba,xf-1,yf),u)
	x2 = lerp(grad(ab,xf,yf-1),grad(bb,xf-1,yf-1),u)
	return lerp(x1,x2,v)
end

function grad(hash,x,y)
	local h = band(hash,0x7)
	local v={x+y,-x+y,x-y,-x-y,-x,-y,x,y}
	return v[hash%8+1]
end

function fade(t)
	return t*t*t*(t*(t*6-15)+10)
end

function shuffle(a)
	local n = count(a)
	for i=1,n do
		local k = -flr(-rnd(n))
		a[i],a[k] = a[k],a[i]
	end
	return a
end

function lerp(a,b,t)
	return (1-t)*a+t*b
end

__gfx__
00000000000000000000000000000000000000000000000000006000000000000033330000000000000000000000000000000000000000000000000000000000
000000000f0eee0050000050002227200000000000000000000565000000000003bb333000040040000000000000000000000000000000000000000000000000
0000000000f9faa05500055000202220000000000000000000004000000000003bb3333304040400000000000000000000000000000000000000000000000000
00000000008fff400555550000200000000000000000000000004000000000003333333304004400000000000000000000000000000000000000000000000000
00000000000fff0400555000002eeee0000000000000000000004000000000003333333300404040000000000000000000000000000000000000000000000000
0000000000f000f400050000000002e0000000000000000000004000000000000333333000044400000000000000000000000000000000000000000000000000
0000000000f3bbf40000000000e22e20000000000000000000074700000000000033330000004000000000000000000000000000000000000000000000000000
00000000002022400000000000000000000000000000000000070700000000000054400000004000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000077777777000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000560000000000000000007007777000000000000000000000000000000000000000000000000
00000000000000000555555500000000000000000500007700000450770000500000000007777077000000000000000000000000000000000000000000000000
00000000000000005505500500000000000000006644444000004000044444660000000077700777000000000000000000000000000000000000000000000000
00000000000000005000500500000000000000000500007700040000770000500006500070770707000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000007400000000000000065550000077707000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000700000000000000655555000077777000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000555555000070007000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000070700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000074700000000000404040400000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000004000000000004040404000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000004000000000000404040400000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000056500000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000006000000000004040404000000000000000000000000000000000000000000000000000000000
__gff__
0000040400000200010100000000000000000400000202020100000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000808080808000000080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008282828282808000808080000032800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008282828022808000800002828280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008082828282808080800282828280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000080000002828280028280828280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000080808080828282803080828280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000800000828080808080028280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000808080000000028000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100001a05026750257502375022750087502175008750207501f7501f7501f7501e7501e7501d7501d7501d7501d7501e7501f750207502175022750237500675022750017502675015650166501865018650
001000000905001040090000900009000090000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000100501f0501f0701d050240500000019050290502a05015050110502c0500e0502e0500a050080502e0502e0500000000000000000000000000000000000000000000000000000000
__music__
00 01424344
00 57424344
