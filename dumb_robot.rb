include Java

import java.awt.Robot
import java.awt.Color
import java.awt.image.BufferedImage
import java.awt.Toolkit
import java.awt.Rectangle
import javax.imageio.ImageIO
import java.awt.Graphics2D
import java.awt.event.InputEvent
import java.awt.event.KeyEvent

class Fixnum
  def squares
    self * 0.05
  end
end

class BufferedImage
  def pattern_at?(pattern,x,y)
    pattern.each_with_index do |row, dx|
      row.each_with_index do |point, dy|
        return false unless self.getRGB(x+dx, y+dy) == point
      end
    end
    return true
  end
end

class Symbol
  DIRECTION_LIST = [:up, :left, :down, :right]

  def opposite
    case self
      when :up then :down
      when :down then :up
      when :left then :right
      when :right then :left
    end
  end

  def next_clockwise
    DIRECTION_LIST[(DIRECTION_LIST.index(self)+1)%4]
  end

  def next_counter_clockwise
    DIRECTION_LIST[(DIRECTION_LIST.index(self)-1)%4]
  end

end
class SnakePlayer < Robot
  PAGE_BACKGROUND_COLOR = Color.new(255, 255, 255).getRGB # The background of the page where the game is
  GAME_BORDER_COLOR = Color.new(0,0,0).getRGB # The 1px border around the game space
  GAME_BACKGROUND_COLOR = Color.new(238,238,238).getRGB # The bg of the game space
  SNAKE_COLOR = Color.new(84,84,140).getRGB # The bg of the game space
  FOOD_COLOR = Color.new(255,13,0).getRGB # The bg of the game space
  SQUARE_LENGTH = 8
  GAME_HEIGHT = 255
  GAME_WIDTH = 510
  MAX_CHECKS = 5000
  attr_accessor :game_x, :game_y, :x, :y
  def initialize
    @direction = :up
    @x = 252
    @y = 252
  end

  def find_game_space
    pattern = [
      [PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BORDER_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BACKGROUND_COLOR]
    ]
    screen_size = Toolkit.getDefaultToolkit.getScreenSize
    image = self.create_screen_capture Rectangle.new(screen_size.width, screen_size.height)

    (450...500).each do |y|
      (45...60).each do |x|
        self.mouseMove(x, y)
        if image.pattern_at?(pattern, x, y)
          @game_x = x+2
          @game_y = y+2 # Game is in the lower right hand corner of the pattern
          return true
        end
      end
    end
    return false
  end
  
  def real_x(x)
    self.game_x + x
  end

  def real_y(y)
    self.game_y + y
  end

  def calc_corner_points
    @top_left ||= [real_x(0), real_y(0)]
    @bottom_right ||= [real_x(GAME_WIDTH), real_y(GAME_HEIGHT)]
  end 

  def relative_in_game_bounds(x, y)
    self.calc_corner_points
    self.in_game_bounds(real_x(x), real_y(y))
  end

  def in_game_bounds(x, y)
    self.calc_corner_points
    (x > @top_left[0] && x < @bottom_right[0]) && (y > @top_left[1] && y < @bottom_right[1])
  end

  def mask_for_direction(dir)
    case dir
      when :up then KeyEvent::VK_UP
      when :down then KeyEvent::VK_DOWN
      when :left then KeyEvent::VK_LEFT
      when :right then KeyEvent::VK_RIGHT
    end
  end
  
  def go(dir, length=1)
    self.quick_go(dir)    
    # Figure out where to expect the snake
    dest_x = @x
    dest_y = @y
    length = length * SQUARE_LENGTH
    case dir
    when :up
      dest_y -= length
    when :down
      dest_y += length
    when :right
      dest_x += length
    when :left
      dest_x -= length
    end
    i = 0
    watch_x = real_x(dest_x)
    watch_y = real_y(dest_y) 
    loop do
      if self.get_pixel_color(watch_x, watch_y).getRGB == SNAKE_COLOR
        puts "Found at watch point #{watch_x}, #{watch_y}"
        @x = dest_x
        @y = dest_y
        return true
      end
      # Delay this error checking logic for just a little bit to make sure we don't make the check too slow to catch
      # 1 block lengths
      if i == 3
        unless in_game_bounds(watch_x, watch_y)
          throw "Watch point #{watch_x}, #{watch_y} out of bounds!"
        else
          puts "Watching point #{watch_x}, #{watch_y}"
        end
        self.mouse_move(watch_x, watch_y)     
      end
      if (i += 1) > MAX_CHECKS
        throw "Snake never appeared at #{dest_x}, #{dest_y}"
      end
    end
  end
  
  def articulate_counter_clockwise(direction)
    self.quick_go(direction)
    self.quick_go(direction.next_counter_clockwise)
  end

  def articulate_clockwise(direction)
    self.quick_go(direction)
    self.quick_go(direction.next_clockwise)
  end

  def quick_go(dir)
    @direction = dir
    self.click_key!(mask_for_direction(dir))
  end

  def click!(x,y)
    self.mouse_move(x,y)
    self.mouse_press(InputEvent::BUTTON1_MASK)
    sleep 0.05
    self.mouse_release(InputEvent::BUTTON1_MASK)
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

  def click_key!(code)
   self.key_press(code)
   sleep 0.05
   self.key_release(code)      
  end

  def play
    if self.find_game_space
      puts "Game found at #{game_x}, #{game_y}"
      2.times do
       click!(game_x + (GAME_WIDTH / 2), game_y + (GAME_HEIGHT/2))
       sleep 0.25
      end
      puts "Game highlighted"
      self.mouse_move(real_x(@x), real_y(@y))
      puts "Watching #{real_x(@x)},#{real_y(@y)}"
      space!
      sleep 0.05 # Wait for old game to clear for sure
      # Going up, get to top
      go(:up, 31)
      go(:right, 32)
      15.times do
        go(:down)
        go(:left, 63)
        go(:down)
        go(:right, 63)
      end
    else
      puts "Couldn't find game space!"
    end
  end
end

player = SnakePlayer.new
player.play
