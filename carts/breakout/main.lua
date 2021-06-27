function _init()
  cls()
  mode = "start"
  levelnum = 1
  levels = {}
  levels[1] = "x4b"
  levels[2] = "x7b"
  debug = ""
end

function _update60()
  if mode == "game" then
    update_game()
  elseif mode == "start" then
    update_start()
  elseif mode == "gameover" then
    update_gameover()
  elseif mode == "levelover" then
    update_levelover()
  end
end

function buildbricks(lvl)
  brick_x = {}
  brick_y = {}
  brick_v = {}

  local i, j, k, chr, last

  j = 0
  for i = 1, #lvl do
    j += 1
    chr = sub(lvl, i, i)
    if chr == "b" then
      last = "b"
      add(brick_x, 4 + ((j - 1) % 11) *(brick_w + 2))
      add(brick_y, 20+flr((j - 1) / 11)*(brick_h + 2))
      add(brick_v,true)
    elseif chr == "x" then
      last = "x"

    elseif chr == "/" then
      j = (flr((j - 1) / 11) + 1) * 11
    elseif chr >= "1" and chr <= "9" then
      debug = chr
      for k = 1, chr + 0 do
        if last == "b" then
          add(brick_x, 4 + ((j - 1) % 11) *(brick_w + 2))
          add(brick_y, 20+flr((j - 1) / 11)*(brick_h + 2))
          add(brick_v,true)
        elseif last == "x" then

        end
        j += 1
      end
      j -= 1
    end
  end
end

function levelfinished()
  for i = 1, #brick_v do
    if brick_v[i] == true then
      return false
    end
  end
  return true
end

function serveball()
  ball_x = pad_x + flr(pad_w / 2)
  ball_y = pad_y - ball_r - 1
  ball_dx = 1
  ball_dy = -1
  sticky = true
  ball_ang = 1
  chain = 1
end

function setang(ang)
  ball_ang = ang
  if ang == 2 then
    ball_dx = 0.5 * sign(ball_dx)
    ball_dy = 1.3 * sign(ball_dy)
  elseif ang == 0 then
    ball_dx = 1.3 * sign(ball_dx)
    ball_dy = 0.5 * sign(ball_dy)
  else
    ball_dx = 1 * sign(ball_dx)
    ball_dy = 1 * sign(ball_dy)
  end
end

function sign(n)
  if n < 0 then
    return -1
  elseif n > 0 then
    return 1
  else
    return 0
  end
end

function gameover()
  mode = "gameover"
end

function levelover()
  mode = "levelover"
end

function update_start()
  if btnp(5) then
    startgame()
  end
end

function update_gameover()
  if btnp(5) then
    startgame()
  end
end

function update_levelover()
  if btnp(5) then
    nextlevel()
  end
end

function startgame()
  mode = "game"

  ball_r = 2

  pad_x = 52
  pad_y = 120
  pad_dx = 0
  pad_dy = 0
  pad_w = 24
  pad_h = 3

  brick_w = 9
  brick_h = 4

  levelnum = 1

  level = levels[levelnum]

  buildbricks(level)


  lives = 3
  points = 0
  bar_h = 6

  sticky = true

  chain = 1 -- combo chain multiplier

  serveball()
end

function nextlevel()
  pad_x = 52
  pad_y = 120
  pad_dx = 0
  pad_dy = 0
  pad_w = 24
  pad_h = 3
  brick_w = 9
  brick_h = 4
  levelnum += 1
  if levelnum > #levels then
    mode = "start"
    return
  end
  mode = "game"
  level = levels[levelnum]
  buildbricks(level)
  sticky = true
  chain = 1 -- combo chain multiplier
  serveball()
end

function update_game()
  local buttpressed = false
  local next_x, nexty

  if btn(0) then
    --left
    buttpressed = true
    pad_dx = -2.5

    if sticky then
      ball_dx = -1
    end
  end

  if btn(1) then
    --right
    buttpressed = true
    pad_dx = 2.5

    if sticky then
      ball_dx = 1
    end
  end

  if not(buttpressed) then
    pad_dx = pad_dx / 2
  end

  if sticky and btnp(4) then
    sticky = false
  end

  pad_x += pad_dx
  pad_x = mid(0, pad_x, 127 - pad_w)

  if sticky then
    ball_x = pad_x + flr(pad_w / 2)
    ball_y = pad_y - ball_r - 1
  else
    -- regular ball physics
    nextx = ball_x + ball_dx
    nexty = ball_y + ball_dy

    if nextx > 127 - ball_r or nextx < ball_r then
      nextx = mid(ball_r,nextx,127 - ball_r)
      ball_dx = -ball_dx
      sfx(0)
    end
    if nexty < bar_h + ball_r then
      nexty = mid(bar_h + ball_r, nexty, 127 - ball_r)
      ball_dy =- ball_dy
      sfx(0)
    end

    -- check if ball hit pad
    if ball_box(nextx,nexty,pad_x,pad_y,pad_w,pad_h) then
      -- deal with collision
      if deflx_ball_box(ball_x,ball_y,ball_dx,ball_dy,pad_x,pad_y,pad_w,pad_h) then
        -- ball hit pad on the side
        ball_dx = -ball_dx
        if ball_x < pad_x+pad_w/2 then
          nextx=pad_x-ball_r
        else
          nextx=pad_x+pad_w+ball_r
        end
      else
        -- ball hit pad on top/bottom
        ball_dy = -ball_dy
        if ball_y > pad_y then
          -- bottom
          nexty=pad_y+pad_h+ball_r
        else
          -- top
          nexty=pad_y-ball_r
          if abs(pad_dx) > 2 then
            -- change angle
            if sign(pad_dx) == sign(ball_dx) then
              -- ball and pad moving same direction
              -- flatten angle
              setang(mid(0, ball_ang - 1, 2))
            else
              -- raise angle
              if ball_ang == 2 then
                ball_dx = -ball_dx
              else 
                setang(mid(0, ball_ang + 1, 2))
              end
            end
          end
        end
      end
      sfx(1)
      chain = 1
    end

    -- check if ball hit brick
    brickhit = false
    for i = 1, #brick_x do
      if brick_v[i] and ball_box(nextx, nexty, brick_x[i], brick_y[i], brick_w, brick_h) then
        if not(brickhit) then
          if deflx_ball_box(ball_x, ball_y, ball_dx, ball_dy, brick_x[i], brick_y[i], brick_w, brick_h) then
            ball_dx =- ball_dx
          else
            ball_dy =- ball_dy
          end
        end
        brickhit = true
        sfx(2 + chain)
        brick_v[i] = false
        points += 10 * chain
        chain += 1
        chain = mid(1, chain, 7)
        if levelfinished() then
          _draw()
          levelover()
        end
      end
    end

    ball_x = nextx
    ball_y = nexty

    if nexty > 127 then
      sfx(2)
      lives -= 1
      if lives < 0 then
        gameover()
      else
        serveball()
      end
    end
  end
end

function _draw()
  if mode == "game" then
    draw_game()
  elseif mode == "start" then
    draw_start()
  elseif mode == "gameover" then
    draw_gameover()
  elseif mode == "levelover" then
    draw_levelover()
  end
end

function draw_game()
  cls(1)
  circfill(ball_x, ball_y, ball_r, 10)
  rectfill(pad_x, pad_y, pad_x + pad_w, pad_y + pad_h, 7)
  rectfill(0, 0, 128, bar_h, 0)


  -- serve preview
  if sticky then
    line(ball_x, ball_y, ball_x + ball_dx * 5, ball_y + ball_dy * 5, 10)
  end

  -- draw bricks
  for i = 1, #brick_x do
    if brick_v[i] then
      rectfill(brick_x[i], brick_y[i], brick_x[i] + brick_w, brick_y[i] + brick_h, 14)
    end
  end

  if debug == "" then
    print("lives:"..lives, 1, 1, 7)
    print("points:"..points, 40, 1, 7)
    print("chain:"..chain, 100, 1, 7)
  else
    print(debug, 1, 1, 7)
  end
end

function draw_start()
  cls()
  print("pico hero breakout", 30, 40, 7)
  print("press ❎ to start", 32, 80, 11)
end

function draw_gameover()
  rectfill(0, 60, 128, 76, 0)
  print("game over", 46, 62, 7)
  print("press X to restart", 27, 68, 6)
end

function draw_levelover()
  rectfill(0, 60, 128, 76, 0)
  print("stage clear!", 46, 62, 7)
  print("press X to continue", 27, 68, 6)
end

function ball_box(bx, by, box_x, box_y, box_w, box_h)
  if by-ball_r > box_y+box_h then
    return false
  end
  if by+ball_r < box_y then
    return false
  end
  if bx-ball_r > box_x+box_w then
    return false
  end
  if bx+ball_r < box_x then
    return false
  end
  return true
end

function deflx_ball_box(bx,by,bdx,bdy,tx,ty,tw,th)
  local slp = bdy / bdx
  local cx, cy
  if bdx == 0 then
    return false
  elseif bdy == 0 then
    return true
  elseif slp > 0 and bdx > 0 then
    cx = tx - bx
    cy = ty - by
    return cx > 0 and cy/cx < slp
  elseif slp < 0 and bdx > 0 then
    cx = tx - bx
    cy = ty + th - by
    return cx > 0 and cy/cx >= slp
  elseif slp > 0 and bdx < 0 then
    cx = tx + tw - bx
    cy = ty + th - by
    return cx < 0 and cy/cx <= slp
  else
    cx = tx + tw - bx
    cy = ty - by
    return cx < 0 and cy/cx >= slp
  end
end
