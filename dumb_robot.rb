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

require 'benchmark'
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

class Color
  def rgb_array
    [self.getRed, self.getBlue, self.getGreen].to_java(:int)
  end

  def hsb_array
    comp_array = Java::float[3].new
    self.class.RGBtoHSB(self.red, self.green, self.blue, comp_array)
    comp_array
  end

  def compare_hsb_array(tolerance, comp_array)      
    diff = 0
    own_hsb = hsb_array
   # puts "Seeing: "+comp_array[0].to_s+" "+comp_array[1].to_s+" "+comp_array[2].to_s+", looking for: "+own_hsb[0].to_s+" "+own_hsb[1].to_s+" "+own_hsb[2].to_s
    3.times do |i|
      diff += (comp_array[i] - own_hsb[i]).abs
    end
    diff <= tolerance
  end
end


class Symbol
  DIRECTION_LIST = [:up, :right, :down, :left]

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
  BLACK = Color.new(0,0,0)
  WHITE = Color.new(255, 255, 255) 
  PAGE_BACKGROUND_COLOR = WHITE # The background of the page where the game is
  GAME_BORDER_COLOR = BLACK # The 1px border around the game space
  GAME_BACKGROUND_COLOR = Color.new(238,238,238) # The bg of the game space
  SNAKE_COLOR = Color.new(85,85,136) # The bg of the game space
  SNAKE_COLOR_RGB = SNAKE_COLOR.rgb_array
  SNAKE_COLOR_HSB = SNAKE_COLOR.hsb_array
  FOOD_COLOR = Color.new(255,13,0) # The bg of the game space
  SQUARE_LENGTH = 8
  GAME_HEIGHT = 255
  GAME_WIDTH = 510
  MAX_CHECKS = 5000
  PATTERN_SEARCH = Rectangle.new(45, 450, 10, 50)
  ONE_SQUARE_TIME = 0.016
  DELAYED_WATCH_MODE = false
  attr_accessor :game_x, :game_y, :x, :y

  def initialize
    @direction = :up
    @x = 252
    @y = 252
  end

  def find_pattern(pattern)
    screen_size = Toolkit.get_default_toolkit.get_screen_size
    image = self.create_screen_capture Rectangle.new(screen_size.width, screen_size.height)

    (PATTERN_SEARCH.y..PATTERN_SEARCH.y+PATTERN_SEARCH.height).each do |y|
      (PATTERN_SEARCH.x..PATTERN_SEARCH.x+PATTERN_SEARCH.width).each do |x|
        self.mouseMove(x, y)
        if image.pattern_at?(pattern, x, y)
          return [x,y]
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

  def mask_for_direction(dir)
    case dir
      when :up then KeyEvent::VK_UP
      when :down then KeyEvent::VK_DOWN
      when :left then KeyEvent::VK_LEFT
      when :right then KeyEvent::VK_RIGHT
    end
  end
 
  # raster implementation of get pixel
  def get_game_rgb_ints_raster(x, y)
    img = self.createScreenCapture(@game_rectangle)
    data = img.getData # Raster
    data.getPixel(x, y, Java::int[3].new)    
  end

  # faster implementation of get pixel
  def get_game_rgb_capture(x, y)
    img = self.createScreenCapture(@game_rectangle)
    img.getRGB(x, y)
  end
  
  def fast_go(dir, square_length=1)
    self.change_direction(dir)
    # Figure out where to expect the snake
    dest_x = @x
    dest_y = @y
    length = square_length * SQUARE_LENGTH
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
  
    if fast_watch_coord_for_color(real_x(dest_x), real_y(dest_y), SNAKE_COLOR_HSB) 
      @x = dest_x
      @y = dest_y
      return true
    else
     return false
    end
  end

  def go(dir, square_length=1, turn=true)
    if turn
      self.change_direction(dir)      
    else
      @direction = dir
    end
    puts "Going #{@direction}"
    # Figure out where to expect the snake
    watch_x = @x
    watch_y = @y
    dest_x = watch_x
    dest_y = watch_y
    # puts "Calcing #{watch_x},#{watch_y}, will end up at #{dest_x}, #{dest_y}"
    
    length = square_length * SQUARE_LENGTH
    if square_length > 1 && DELAYED_WATCH_MODE
      behind = true
      watch_length = (square_length - 1) * SQUARE_LENGTH
    else
      behind = false
      watch_length = length
    end

    case dir
    when :up
      watch_y -= watch_length
      dest_y -= length
    when :down
      watch_y += watch_length
      dest_y += length
    when :right
      watch_x += watch_length
      dest_x += length 
    when :left
      watch_x -= watch_length
      dest_x -= length
    end
    
    if watch_coord_for_color(real_x(watch_x), real_y(watch_y), SNAKE_COLOR_HSB) 
      # sleep ONE_SQUARE_TIME if behind
      @x = dest_x
      @y = dest_y
      return true
    else
     return false
    end
  end
  
  def watch_coord_for_color(watch_x, watch_y, hsb_array)
    i = 0
    old_color = false
    loop do
      color = self.getPixelColor(watch_x, watch_y)
      if color.compare_hsb_array(0.125, hsb_array)
        puts "Found #{color} at watch point #{watch_x}, #{watch_y} after #{i} checks."
        return true
      else
        if color != old_color
          puts color
          old_color = color
        end
      end
      # Delay this error checking logic for just a little bit to make sure we don't make the check too slow to catch
      # 1 block lengths
      if i == 3
        unless @game_rectangle.contains(watch_x, watch_y)
          throw "Watch point #{watch_x}, #{watch_y} out of bounds!"
        else
          puts "Watching point #{watch_x}, #{watch_y}"
        end
        self.mouse_move(watch_x, watch_y)     
      end
      if (i += 1) > MAX_CHECKS
        throw "Snake never appeared at #{watch_x}, #{watch_y}"
      end
    end
  end

  def fast_watch_coord_for_color(watch_x, watch_y, hsb_array)
    until self.getPixelColor(watch_x, watch_y).compare_hsb_array(0.125, hsb_array)
    end
    return true
  end

  def articulate_counter_clockwise
   self.change_direction(@direction.next_counter_clockwise)
   sleep ONE_SQUARE_TIME
   self.change_direction(@direction.next_counter_clockwise)
  end

  def articulate_clockwise
   self.change_direction(@direction.next_clockwise)
   sleep ONE_SQUARE_TIME
   self.change_direction(@direction.next_clockwise)     
  end
  
  def articulate_down
    case @direction
    when :left then articulate_counter_clockwise
    when :right then articulate_clockwise
    when :up then articulate_clockwise
    when :down then throw "Cant articulate down when going down"
    end
    @y += SQUARE_LENGTH
    return true
  end

  def change_direction(dir)
    @direction = dir
    self.click_key!(mask_for_direction(dir))
  end

  def click!(x,y)
    self.mouse_move(x,y)
    self.mouse_press(InputEvent::BUTTON1_MASK)
    sleep 0.01
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
   # sleep 0.2
   self.key_release(code)      
  end
  
  def prepare_for_game
     game_pattern = [
      [PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BORDER_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BACKGROUND_COLOR]
    ]
    game_pattern = game_pattern.map {|row| row.map {|point| point.getRGB }}

    play_again_pattern = [
      [WHITE, WHITE, WHITE],
      [WHITE, BLACK, BLACK],
      [WHITE, BLACK, BLACK]
    ]

    play_again_pattern = play_again_pattern.map {|row| row.map {|point| point.getRGB }}
    play_again = false
    game_coord = self.find_pattern(game_pattern)

    unless game_coord
      game_coord = self.find_pattern(play_again_pattern)
      if game_coord
        # Play again triggering
        play_again = true
      else
        return false
      end
    end
    if game_coord
      @game_x = game_coord[0]+2
      @game_y = game_coord[1]+2 # Game is in the lower right hand corner of the pattern
      @game_rectangle = Rectangle.new(real_x(0), real_y(0), GAME_WIDTH, GAME_HEIGHT)
      self.highlight_game
      if play_again
        click!(@game_rectangle.get_center_x, @game_rectangle.get_center_y)
        unless watch_coord_for_color(real_x(10), real_y(10), GAME_BACKGROUND_COLOR.hsb_array)
          throw "Couldn't activate play again, taking too long to load!"
        end
      end
      return true
    else
      return false
    end
  end
    
  def highlight_game
    click!(@game_rectangle.get_center_x, @game_rectangle.get_center_y)
    sleep 0.25
    puts "Game highlighted"
  end
  
  def start_game!
    space!
    sleep 0.05 # Wait for old game to clear for sure
  end 

  def play_slithery
    if self.prepare_for_game
      puts "Game found at #{game_x}, #{game_y}"
      start_game!
      # Going up, get to top
      go(:up, 31)
      fast_go(:right, 32)
      15.times do
        go(:down) #articulate_down
        go(:left, 63)
        go(:down) #articulate_down
        go(:right, 63)
      end
    else
      puts "Couldn't find game space!"
    end
  end
  def play_dumb
    if self.prepare_for_game
      self.start_game!
      go(:up, 31)
      go(:right, 32)
      loop do
        15.times do
          articulate_down
          go(:left, 62, true)
          articulate_down
          go(:right, 62, true)
        end
        articulate_down
        go(:left, 63, true)
        go(:up, 31)
        go(:right, 63)
        # go(:left)
        # go(:down)
        # go(:right)
        # go(:up)
      end
    end
  end
end
