require './setup.rb'

watcher = Snake::Interactor.new
p = Point.new(10, 10)
color = watcher.getPixelColor(13, 13).hsb_array

for i in 0..1000
  watcher.watch_point_for_color(p, color)
end
