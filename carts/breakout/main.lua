
function _init()
  cls()
  mode = "start"
end

function _update60()
  if mode == "game" then
    update_game()
  elseif mode == "start" then
    update_start()
  elseif mode == "gameover" then
    update_gameover()
  end
end

function buildbricks()
  brick_x = {}
  brick_y = {}
  brick_v = {}

  local i

  for i = 1, 8 do
    add(brick_x, 5 + (i - 1) * (brick_w + 2))
    add(brick_y, 20)
    add(brick_v, true)
  end
end


function serveball()
  ball_r = 8
  ball_x = 10
  ball_dx = 1
  ball_y = 33
  ball_dy = 1
end

function gameover()
  mode = "gameover"
end

function update_start()
  if btn(5) then
    startgame()
  end
end

function update_gameover()
  if btn(5) then
    startgame()
  end
end

function startgame()
  mode = "game"
  pad_x = 52
  pad_y = 120
  pad_dx = 0
  pad_dy = 0
  pad_w = 24
  pad_h = 3

  brick_w = 13
  brick_h = 4

  buildbricks()


  lives = 3
  points = 0
  bar_h = 6

  serveball()
end

function update_game()
  local buttpressed = false
  local next_x, nexty

  if btn(0) then
    --left
    buttpressed = true
    pad_dx = -2
  end

  if btn(1) then
    --right
    buttpressed = true
    pad_dx = 2
  end

  if not(buttpressed) then
    pad_dx = pad_dx / 2
  end

  pad_x += pad_dx
  pad_x = mid(0, pad_x, 127 - pad_w)

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

  if nexty > 127 - ball_r then
    if (lives == 1) then
      gameover()
    else
      sfx(2)
      lives -= 1
      serveball()
      return
    end
  end

  -- check if ball hit pad
  if ball_box(nextx, nexty, pad_x, pad_y, pad_w, pad_h) then
    if deflx_ballbox(ball_x, ball_y, ball_dx, ball_dy, pad_x, pad_y, pad_w, pad_h) then
      ball_dx =- ball_dx
    else
      ball_dy =- ball_dy
    end
    sfx(1)
    points += 1
  end

  -- check if ball hit brick
  for i = 1, #brick_x do
    if brick_v[i] and ball_box(nextx, nexty, brick_x[i], brick_y[i], brick_w, brick_h) then
      if deflx_ballbox(ball_x, ball_y, ball_dx, ball_dy, brick_x[i], brick_y[i], brick_w, brick_h) then
        ball_dx =- ball_dx
      else
        ball_dy =- ball_dy
      end
      sfx(3)
      points += 1
      brick_v[i] = false
    end
  end

  ball_x = nextx
  ball_y = nexty
end

function _draw()
  if mode == "game" then
    draw_game()
  elseif mode == "start" then
    draw_start()
  elseif mode == "gameover" then
    draw_gameover()
  end
end

function draw_game()
  cls(1)
  circfill(ball_x, ball_y, ball_r, 10)
  rectfill(pad_x, pad_y, pad_x + pad_w, pad_y + pad_h, 7)
  rectfill(0, 0, 128, bar_h, 0)

  -- draw bricks
  for i = 1, #brick_x do
    if brick_v[i] then
      rectfill(brick_x[i], brick_y[i], brick_x[i] + brick_w, brick_y[i] + brick_h, 14)
    end
  end

  print("lives:"..lives, 1, 1, 7)
  print("points:"..points, 40, 1, 7)
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

function deflx_ballbox(bx, by, bdx, bdy, tx, ty, tw, th)
  -- calculate wether to deflect the ball
  -- horizontally or vertically when it hits a box
  if bdx == 0 then
    -- moving vertically
    return false
  elseif bdy == 0 then
    -- moving horizontally
    return true
  else
    -- moving diagonally
    -- calculate slope
    local slp = bdy / bdx
    local cx, cy
    -- check variants
    if slp > 0 and bdx > 0 then
      -- moving down right
      cx = tx - bx
      cy = ty - by
      if cx <= 0 then
        return false
      elseif cy / cx < slp then
        return true
      else
        return false
      end
    elseif slp < 0 and bdx > 0 then
      -- moving up right
      cx = tx - bx
      cy = ty + th - by
      if cx <= 0 then
        return false
      elseif cy / cx < slp then
        return false
      else
        return true
      end
    elseif slp > 0 and bdx < 0 then
      -- moving left up
      cx = tx + tw - bx
      cy = ty + th - by
      if cx >= 0 then
        return false
      elseif cy / cx > slp then
        return false
      else
        return true
      end
    else
      -- moving left down
      cx = tx + tw -bx
      cy = ty - by
      if cx >= 0 then
        return false
      elseif cy / cx < slp then
        return false
      else
        return true
      end
    end
  end
  return false
end
