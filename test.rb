require './dumb_robot'

player = SnakePlayer.new
player.prepare_for_game

puts player.getPixelColor(player.real_x(10), player.real_y(10)) == player.getPixelColor(player.real_x(10), player.real_y(10))  
