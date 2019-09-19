STARTING_PLAYER = 1

PLAYER_WIDTH = 8
PLAYER_HEIGHT = 90
PLAYER_MOVE_SPEED = 10
PLAYER_MARGIN = 10

BALL_RADIUS = 8
BALL_VELOCITY = 10

players = {}
ball = {
   x = 0,
   y = 0,
   vx = 0,
   vy = 0,
   held_by = nil
}

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

function update_ball()
   -- Shoot the ball or update it's velocity
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

   -- Player collision check
   -- TODO: This is a bit crude
   local player_size = PLAYER_MARGIN + PLAYER_WIDTH
   if     ball.x + BALL_RADIUS > love.graphics.getWidth() - player_size
      and ball.y >= players[2].y 
      and ball.y < players[2].y + PLAYER_HEIGHT 
   then
      calculate_ball_reflected_velocity(players[2])
   end

   if     ball.x - BALL_RADIUS < player_size
      and ball.y >= players[1].y 
      and ball.y < players[1].y + PLAYER_HEIGHT 
   then
      calculate_ball_reflected_velocity(players[1])
   end

   -- Check the bounds
   if ball.x < 0 then
      players[2].score = players[2].score + 1
      ball.held_by = players[1]
   elseif ball.x >= love.graphics.getWidth() then
      players[1].score = players[1].score + 1
      ball.held_by = players[2]
   end

   if    ball.y - BALL_RADIUS < 0
      or ball.y + BALL_RADIUS >= love.graphics.getHeight()
   then
      ball.vy = -ball.vy
      ball.y = ball.y + ball.vy
   end
end

function love.load()
   init_player(PLAYER_MARGIN, 1, "w", "s", "d")
   init_player(love.graphics.getWidth() - PLAYER_MARGIN - PLAYER_WIDTH, -1, "up", "down", "left")
   
   ball.held_by = players[STARTING_PLAYER]

   local font = love.graphics.newFont(50)
   love.graphics.setFont(font)

   love.window.setTitle("P.O.N.G")
end

function love.update() 
   for i,player in ipairs(players) do
      check_player_input(player)
      check_player_bounds(player)
   end

   update_ball()
end

function love.draw()
   -- Draw players
   for i,player in ipairs(players) do
      love.graphics.rectangle("fill", 
         player.x, player.y,
         player.w, player.h)
   end

   love.graphics.circle("fill", ball.x, ball.y, BALL_RADIUS)

   love.graphics.printf(players[1].score, 25, 25, 50, "left")
   love.graphics.printf(players[2].score, love.graphics.getWidth() - 75, 25, 50, "right")
end