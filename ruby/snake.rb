require './setup.rb'
strategies = [:dumb, :columns, :test]
options = {:strategy => :columns}

OptionParser.new do |opts|
  opts.banner = "Usage: snake.rb [options]"

  opts.on("-s", "--strategy [STRATEGY]", strategies, "Use snake playing strategy") do |s|
    options[:strategy] = s
  end
end.parse!

player = Snake::Player.new()
player.play(options)
