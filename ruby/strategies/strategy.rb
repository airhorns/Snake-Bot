module Snake
  class Strategy
    def initialize(options)
      @options = options
    end
    def run(player)
      player.start_game!
    end
  end
end
