require './dumb_robot'

player = SnakePlayer.new
player.prepare_for_game
player.start_game!
player.go(:up, 20)
player.go(:left, 10)
5.times do 
  player.articulate_down_with_space
end
