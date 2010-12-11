require 'singleton'

class Point
  def real_x
    self.x
  end
  def real_y
    self.y
  end

  def game_x
    throw "Vanilla points can't calculate their game x!"
  end

  def game_y
    throw "Vanilla points can't calculate their game y!"
  end
end

module Snake
  class GameSingleton
    include Singleton
    attr_accessor :game_rectangle
    def game_rectangle
      unless @game_rectangle
        throw "Trying to access game rectangle without having found it yet!"
      end
      @game_rectangle
    end
  end

  class << self
    def real_x(x)
      Snake::Game.game_rectangle.x + x
    end

    def real_y(y)
      Snake::Game.game_rectangle.y + y 
    end
    
    def grid_x(game_x)
      (game_x / SQUARE_LENGTH).floor
    end

    def grid_y(game_y)
      (game_y / SQUARE_LENGTH).floor
    end

    def squares_sleep_time(squares)
      squares = squares - 0.25
      if squares > 0
        return squares * ONE_SQUARE_TIME
      else
        return 0
      end
    end
  end
  class GamePoint < Point
    attr_accessor :game_x, :game_y
    def initialize(a_game_x, a_game_y)
      @game_x = a_game_x
      @game_y = a_game_y
    end

    def x
      Snake::real_x(@game_x)
    end

    def y
      Snake::real_y(@game_y)
    end

    def grid_x
      Snake::grid_x(@game_x)
    end

    def grid_y
      Snake::grid_y(@game_y)
    end

    def translate(direction, squares)
      self.clone.translate!(direction, squares)
    end

    def translate!(direction, squares)
      length = squares * SQUARE_LENGTH
      case direction
      when :up
        @game_y -= length
      when :down
        @game_y += length
      when :right
        @game_x += length 
      when :left
        @game_x -= length
      end
      self
    end
  end

  class GridPoint < GamePoint
    def initialize(a_grid_x, a_grid_y)
      a_game_x = a_grid_x * SQUARE_LENGTH + 1
      a_game_y = a_grid_y * SQUARE_LENGTH + 1
      super(a_game_x, a_game_y)
    end
  end
end
