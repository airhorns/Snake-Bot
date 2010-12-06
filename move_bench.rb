require './dumb_robot'
require 'benchmark'

player = SnakePlayer.new
player.prepare_for_game

player.x = 252
player.y = 4
n = 100
Benchmark.bm(15) do |x|

  x.report "sequential" do
    n.times do
      player.go(:up, 0)
      player.go(:right, 0)
    end
  end

  q = Queue.new
  n.times do
    q.push [:up, 0]
    q.push [:right, 0]
  end

  x.report "queue" do
    until q.empty?
      action = q.pop
      # puts "Got action #{action}"
      case action[0]
      when :articulate_down then player.articulate_down
      when :got_block then blocks.pop
      else
        player.go(action[0], action[1], action[2])
      end
    end
  end
end
