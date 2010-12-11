module Snake
  class Interactor < Robot
    include Watcher

    GAME_PATTERN = [
      [PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BORDER_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BACKGROUND_COLOR]
    ]

    PLAY_AGAIN_PATTERN = [
      [WHITE, WHITE, WHITE],
      [WHITE, BLACK, BLACK],
      [WHITE, BLACK, BLACK]
    ]

    def mask_for_direction(dir)
      case dir
      when :up then KeyEvent::VK_UP
      when :down then KeyEvent::VK_DOWN
      when :left then KeyEvent::VK_LEFT
      when :right then KeyEvent::VK_RIGHT
      end
    end

    def click_real!(x, y)
      self.click!(x, y)
    end

    def click!(game_point_or_x, y)
      if y
        self.mouse_move(game_point_or_x, y)
      else
        self.mouse_move(game_point_or_x.real_x, game_point_or_x.real_y)
      end

      self.mouse_press(InputEvent::BUTTON1_MASK)
      sleep 0.2
      self.mouse_release(InputEvent::BUTTON1_MASK)
    end

    def click_key!(code)
      self.key_press(code)
      self.key_release(code)      
    end

    def click_direction!(direction)
      self.click_key!(mask_for_direction(direction))
    end

    def right!
      self.click_key!(mask_for_direction(:right))
    end

    def left!
      self.click_key!(mask_for_direction(:left))
    end

    def up!
      self.click_key!(mask_for_direction(:up))
    end

    def down!
      self.click_key!(mask_for_direction(:down))
    end

    def space!
      self.click_key!(KeyEvent::VK_SPACE)
    end

    def prepare_for_game
      play_again = false
      game_point = self.find_pattern(GAME_PATTERN, PATTERN_SEARCH)

      unless game_point
        game_point = self.find_pattern(PLAY_AGAIN_PATTERN, PATTERN_SEARCH)
        if game_point
          play_again = true
        else
          return false
        end
      end

      if game_point
        puts "Found game at #{game_point}"
        Snake::Game.game_rectangle = Rectangle.new(game_point, Dimension.new(GAME_WIDTH, GAME_HEIGHT))
        self.highlight_game
        if play_again
          self.click!(Snake::Game.game_rectangle.get_center_x, Snake::Game.game_rectangle.get_center_y)
          unless self.watch_point_for_color(GamePoint.new(10, 10), GAME_BACKGROUND_COLOR, 10000)
            throw "Couldn't activate play again, taking too long to load!"
          end
        end
        return true
      else
        return false
      end
    end

    def prepare_for_game!
      unless self.prepare_for_game
        throw "Couldn't find the game space!"
      end
      return true
    end

    def highlight_game
      self.click_real!(Snake::Game.game_rectangle.get_center_x, Snake::Game.game_rectangle.get_center_y)
      sleep 0.25
    end

    def start_game!
      self.space!
      sleep 0.1 # Wait for old game to clear for sure
    end 
  end
end
