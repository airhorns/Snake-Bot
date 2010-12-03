require './dumb_robot'
require 'benchmark'

player = SnakePlayer.new
player.prepare_for_game
n = 1000
Benchmark.bm(20) do |x|
  # x.report("raster") do
  #   n.times do 
  #     player.get_game_rgb_ints_raster(10, 10) == SnakePlayer::SNAKE_COLOR_INTS
  #   end
  # end

  # x.report("capture") do
  #   n.times do
  #     player.get_game_rgb_capture(10, 10) == rgb
  #   end
  # end

  real_x = player.real_x(10)
  real_y = player.real_y(10)

  x.report("vanilla") do
    n.times do
      player.getPixelColor(real_x, real_y) == SnakePlayer::SNAKE_COLOR
    end
  end

  rgb = SnakePlayer::SNAKE_COLOR.getRGB
  
  x.report("vanilla with rgb") do
    n.times do
      player.getPixelColor(real_x, real_y).getRGB == rgb
    end
  end

  rgb_array = SnakePlayer::SNAKE_COLOR.rgb_array
  x.report("rgb w/ tolerance") do
    n.times do
      comp = player.getPixelColor(real_x, real_y)
      diff = 0
      diff += (comp.red - rgb_array[0]).abs
      diff += (comp.green - rgb_array[1]).abs
      diff += (comp.blue - rgb_array[2]).abs
      diff <= 32
    end
  end

  hsb_array = SnakePlayer::SNAKE_COLOR.hsb_array
  x.report("hsb w/ tolerance") do
    n.times do
      player.getPixelColor(real_x, real_y).compare_hsb_array(32, hsb_array)
    end
  end

  rx = player.real_x(10)
  ry = player.real_y(10)
  full_on = player.getPixelColor(rx, ry).hsb_array
  x.report("full on") do
    n.times do
      player.watch_coord_for_color(rx, ry, full_on)
    end
  end

  x.report("fast full on") do
    n.times do
      player.fast_watch_coord_for_color(rx, ry, full_on)
    end
  end
end
