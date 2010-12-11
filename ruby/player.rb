module Snake
  class Player
    attr_accessor :location, :length, :direction, :interactor

    def initialize
      @interactor = Interactor.new      
    end

    def play(options)
      if @interactor.prepare_for_game
        strategy = case options[:strategy]
                   when :dumb then Snake::DumbStrategy
                   when :columns then Snake::ColumnsStrategy
                   when :test then Snake::TestStrategy
                   end
        strategy = strategy.new(options)
        strategy.run(self)
      else
        throw "Couldn't find the game to play! Aborting."
      end
    end

    def prepare_for_game!
      @interactor.prepare_for_game!
    end

    def start_game!
      @direction = :up
      @length = 1
      @location = GridPoint.new(31, 31)      
      @interactor.start_game!
    end

    def go(direction, length=1, apply_turn=true)
      # Turn ourselves in the direction we need to go in
      self.turn(direction)
      return true if length == 0
      # Figure out where we need to go and then go there.
      destination = @location.translate(direction, length)

      if @interactor.test_watch_point_for_color(destination, SNAKE_COLOR)
      #if @interactor.watch_point_for_color(destination, SNAKE_COLOR)
      # if @interactor.watch_point_for_color_with_lookback(destination, destination.translate(direction.opposite, 1), SNAKE_COLOR_HSB)
        @location = destination
      end
    end
  
    def turn(direction)
      @direction = direction
      @interactor.click_direction!(direction) # if apply_turn
      true
    end

    def articulate_counter_clockwise(sleep_time)
      self.turn(@direction.next_counter_clockwise)
      sleep sleep_time
      self.turn(@direction.next_counter_clockwise)
    end

    def articulate_clockwise(sleep_time)
      self.turn(@direction.next_clockwise)
      sleep sleep_time
      self.turn(@direction.next_clockwise)     
    end

    def articulate_down(sleep_squares=nil)
      sleep_squares ||= 1
      sleep_time = Snake::squares_sleep_time(sleep_squares)
      case @direction
      when :left then articulate_counter_clockwise(sleep_time)
      when :right then articulate_clockwise(sleep_time)
      when :up then throw "Can't articulate down when going up"
      when :down then throw "Cant articulate down when going down"
      end
      @location.translate!(:down, sleep_squares)
      return true
    end

    def articulate_up(sleep_squares=nil)
      sleep_squares ||= 1
      sleep_time = squares_sleep_time(sleep_squares)
      case @direction
      when :left then articulate_clockwise(sleep_time)
      when :right then articulate_counter_clockwise(sleep_time)
      when :up then throw "Cant articulate up when going up"
      when :down then throw "Cant articulate up when going down"
      end
      @location.translate!(:up, sleep_squares)
      return true
    end
  end
end
