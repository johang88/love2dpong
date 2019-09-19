STARTING_PLAYER = 1

PLAYER_WIDTH = 12
PLAYER_HEIGHT = 90
PLAYER_MOVE_SPEED = 10
PLAYER_MARGIN = 10

BALL_RADIUS = 8
BALL_VELOCITY = 12.5

PLAYER_HIT_SHAKE_DURATION = 0.3
PLAYER_HIT_SHAKE_MAGNITUDE= 5

RESTART_TIME = 2.0

players = {}
ball = {
   x = 0,
   y = 0,
   vx = 0,
   vy = 0,
   held_by = nil
}

screen_shake = {
   t = 0,
   duration = 0,
   magnitude = 0
}

restart_timer = 0
init_done = false

sounds = {}

function start_screen_shake(duration, magnitude)
   screen_shake.t = 0
   screen_shake.duration = duration
   screen_shake.magnitude = magnitude
end

function update_screen_shake(dt)
   if screen_shake.t < screen_shake.duration then
      screen_shake.t = screen_shake.t + dt
   end
end

function apply_screen_shake()
   if screen_shake.t < screen_shake.duration then
      local dx = love.math.random(-screen_shake.magnitude, screen_shake.magnitude)
      local dy = love.math.random(-screen_shake.magnitude, screen_shake.magnitude)

      love.graphics.translate(dx, dy)
  end
end

function play_hit_sound()
	love.audio.play(sounds.hit[math.random(#sounds.hit)])
end

function init_player(x, direction, key_up, key_down, key_fire)
   local y = love.graphics.getHeight() / 2 - PLAYER_HEIGHT / 2

   table.insert(players, {
      x = x,
      y = y,
      w = PLAYER_WIDTH,
      h = PLAYER_HEIGHT,
      direction = direction,
      key_up = key_up,
      key_down = key_down,
      key_fire = key_fire,
      score = 0
   })
end

player_a = { y = 0 }

function check_player_input(player)
   local movement_y = 0

   if love.keyboard.isDown(player.key_up) then
      movement_y = -1
   elseif love.keyboard.isDown(player.key_down) then
      movement_y = 1
   end

   player.y = player.y + PLAYER_MOVE_SPEED * movement_y

   if love.keyboard.isDown(player.key_fire) and ball.held_by == player then
      shoot_ball(player.direction)
   end
end

function shoot_ball(direction)
   ball.vx = BALL_VELOCITY * direction
   ball.vy = 0
   ball.held_by = nil
end

function check_player_bounds(player)
   if player.y < 0 then
      player.y = 0
   elseif player.y >= love.graphics.getHeight() - PLAYER_HEIGHT then
      player.y = love.graphics.getHeight() - PLAYER_HEIGHT
   end
end

function calculate_ball_reflected_velocity(player)
   -- TODO: This is very much physically correct
   ball.vx = -ball.vx

   local distance_from_center = (player.y + PLAYER_HEIGHT / 2.0) - ball.y
   ball.vy = ball.vy + distance_from_center * 0.3

   -- Normalize
   local length = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
   ball.vx = ball.vx / length
   ball.vy = ball.vy / length

   ball.vx = ball.vx * BALL_VELOCITY
   ball.vy = ball.vy * BALL_VELOCITY

   -- Move the ball slightly
   ball.x = ball.x + ball.vx
end

function update_ball_position()
   if ball.held_by ~= nil then
      local x = PLAYER_MARGIN + PLAYER_WIDTH + BALL_RADIUS

      if ball.held_by.direction == -1 then
         x = love.graphics.getWidth() - x
      end

      ball.x = x
      ball.y = ball.held_by.y + PLAYER_HEIGHT / 2
   else
      ball.x = ball.x + ball.vx
      ball.y = ball.y + ball.vy
   end
end

function update_ball()
   update_ball_position()

   -- Player collision check
   -- TODO: This is a bit crude
   local player_size = PLAYER_MARGIN + PLAYER_WIDTH
   if     ball.x + BALL_RADIUS > love.graphics.getWidth() - player_size
      and ball.y >= players[2].y 
      and ball.y < players[2].y + PLAYER_HEIGHT 
   then
      calculate_ball_reflected_velocity(players[2])
      start_screen_shake(PLAYER_HIT_SHAKE_DURATION, PLAYER_HIT_SHAKE_MAGNITUDE)
      play_hit_sound()
   end

   if     ball.x - BALL_RADIUS < player_size
      and ball.y >= players[1].y 
      and ball.y < players[1].y + PLAYER_HEIGHT 
   then
      calculate_ball_reflected_velocity(players[1])
      start_screen_shake(PLAYER_HIT_SHAKE_DURATION, PLAYER_HIT_SHAKE_MAGNITUDE)
      play_hit_sound()
   end

   -- Check the bounds
   if ball.x < 0 then
      players[2].score = players[2].score + 1
      ball.held_by = players[1]

      restart_timer = RESTART_TIME
      love.audio.play(sounds.dead)
   elseif ball.x >= love.graphics.getWidth() then
      players[1].score = players[1].score + 1
      ball.held_by = players[2]

      restart_timer = RESTART_TIME
      love.audio.play(sounds.dead)
   end

   if    ball.y - BALL_RADIUS < 0
      or ball.y + BALL_RADIUS >= love.graphics.getHeight()
   then
      ball.vy = -ball.vy
      ball.y = ball.y + ball.vy

      love.audio.play(sounds.hit_env[math.random(#sounds.hit_env)])
   end
end

function love.load()
   love.window.setMode(1280, 720)

   init_player(PLAYER_MARGIN, 1, "w", "s", "d")
   init_player(love.graphics.getWidth() - PLAYER_MARGIN - PLAYER_WIDTH, -1, "up", "down", "left")
   
   ball.held_by = players[STARTING_PLAYER]

   local font = love.graphics.newFont(50)
   love.graphics.setFont(font)

   love.window.setTitle("P.O.N.G")

   restart_timer = RESTART_TIME
   init_done = true

   background = love.graphics.newImage("background.png")

   sounds.dead = love.audio.newSource("dead.wav", "static")
   sounds.start_game = love.audio.newSource("start_game.wav", "static")

   sounds.hit = {}
   table.insert(sounds.hit, love.audio.newSource("hit_1.wav", "static"))
   table.insert(sounds.hit, love.audio.newSource("hit_2.wav", "static"))
   table.insert(sounds.hit, love.audio.newSource("hit_3.wav", "static"))

   sounds.hit_env = {}
   table.insert(sounds.hit_env, love.audio.newSource("hit_env_1.wav", "static"))
   table.insert(sounds.hit_env, love.audio.newSource("hit_env_2.wav", "static"))
   table.insert(sounds.hit_env, love.audio.newSource("hit_env_3.wav", "static"))
end

function love.update(dt)
   if restart_timer > 0 then
      restart_timer = restart_timer - dt

      if restart_timer <= 0 then
         update_ball_position() 
         love.audio.play(sounds.start_game)
      end
   else
      for i,player in ipairs(players) do
         check_player_input(player)
         check_player_bounds(player)
      end
   
      update_ball()
      update_screen_shake(dt)
   end
end

function draw_centered_text(text, x, y)
   local font = love.graphics.getFont()
   local w = font:getWidth(text)
   local h = font:getHeight()

   local tx = x - w / 2
   local ty = y - h / 2

   love.graphics.print(text, tx, ty)
end

function love.draw()
   love.graphics.draw(background, 0, 0)

   apply_screen_shake()

   for i,player in ipairs(players) do
      love.graphics.setColor(1.0, 0.38, 0.11, 0.6)
      love.graphics.rectangle("fill", player.x, player.y, player.w, player.h, 3, 5)

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("line", player.x, player.y, player.w, player.h, 3, 5)
   end

   if restart_timer > 0 then
      local text = string.format("%.2f", restart_timer)
      draw_centered_text(text, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
   end

   if restart_timer <= 0 then
      love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS)
   end

   draw_centered_text(players[1].score, 50, 50)
   draw_centered_text(players[2].score, love.graphics.getWidth() - 50, 50)
end