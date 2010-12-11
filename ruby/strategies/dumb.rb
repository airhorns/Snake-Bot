module Snake
  class DumbStrategy < Strategy
    def run(player)
      player.start_game! 
      player.go(:up, 31)
      player.go(:right, 32)
      loop do
        15.times do
          player.articulate_down
          player.go(:left, 62, false)
          player.articulate_down
          player.go(:right, 62, false)
        end
        player.articulate_down
        player.go(:left, 63, false)
        player.go(:up, 31)
        player.go(:right, 63)

      end
    end
  end
end
