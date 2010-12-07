require 'thread'
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

Thread.abort_on_exception = true

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
    unless @hsb_array
      @hsb_array = Java::float[3].new
      self.class.RGBtoHSB(self.red, self.green, self.blue, @hsb_array)
    end
    @hsb_array
  end

  def compare_hsb_array(tolerance, comp_array)
    diff = 0
    own_hsb = self.hsb_array
    3.times do |i|
      diff += (comp_array[i] - own_hsb[i]).abs
    end
    return (diff <= tolerance)
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
  SNAKE_COLOR_RGB = SNAKE_COLOR.getRGB
  SNAKE_COLOR_HSB = SNAKE_COLOR.hsb_array
  FOOD_COLOR = Color.new(255,13,0) # The bg of the game space
  FOOD_COLOR_RGB = FOOD_COLOR.getRGB
  FOOD_COLOR_HSB = FOOD_COLOR.hsb_array
  SQUARE_LENGTH = 8
  FOOD_ADDS_SQUARES = 5
  GAME_HEIGHT = 255
  GAME_WIDTH = 510
  GAME_GRID_HEIGHT = 32
  GAME_GRID_WIDTH = 64
  MAX_CHECKS = 5000
  PATTERN_SEARCH = Rectangle.new(20, 400, 100, 100)
  ONE_SQUARE_TIME = 0.0621
  DELAYED_WATCH_MODE = false
  MAKE_SHORT_GOS_TIMED = false
  TIME_GOS_UNDER_LENGTH = 4
  attr_accessor :game_x, :game_y, :x, :y, :length

  def initialize
    @direction = :up
    @x = 252
    @y = 252
    @length = 1
  end

  def find_pattern(pattern)
    screen_size = Toolkit.get_default_toolkit.get_screen_size
    image = self.create_screen_capture Rectangle.new(screen_size.width, screen_size.height)

    Thread.new do
      self.mouseMove(PATTERN_SEARCH.x, PATTERN_SEARCH.y)
      sleep 1
      self.mouseMove(PATTERN_SEARCH.x+PATTERN_SEARCH.width, PATTERN_SEARCH.y+PATTERN_SEARCH.height)
    end

    (PATTERN_SEARCH.y..PATTERN_SEARCH.y+PATTERN_SEARCH.height).each do |y|
      (PATTERN_SEARCH.x..PATTERN_SEARCH.x+PATTERN_SEARCH.width).each do |x|
        if image.pattern_at?(pattern, x, y)
          return [x,y]
        end
      end
    end
    return false
  end
 
  def find_food_on_grid
    image = self.create_screen_capture @game_rectangle
    (0..(@game_rectangle.height/SQUARE_LENGTH).floor).each do |y|
      (0..(@game_rectangle.width/SQUARE_LENGTH).floor).each do |x|
        if Color.new(image.getRGB(x*SQUARE_LENGTH, y*SQUARE_LENGTH)).compare_hsb_array(0.125, FOOD_COLOR_HSB)
          return x, y
        end
      end
    end
    return false, false
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

  def squares_sleep_time(squares)
    squares = squares - 0.25
    if squares > 0
      return squares * ONE_SQUARE_TIME
    else
      return 0
    end
  end


  def timed_go(dir, square_length=1, turn=true)
    if turn
      self.change_direction(dir)      
    else
      @direction = dir
    end
    puts "Going #{@direction} for #{square_length} and #{turn} turning. Timed."
    
    # Figure out where to expect the snake
    dest_x = @x
    dest_y = @y
    # puts "Calcing #{watch_x},#{watch_y}, will end up at #{real_x(dest_x)}, #{real_y(dest_y)}"
    
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

    sleep squares_sleep_time(square_length)
    @x = x
    @y = y
    return true
  end


  def go(dir, square_length=1, turn=true)
    if turn
      self.change_direction(dir)      
    else
      @direction = dir
    end
    puts "Going #{@direction} for #{square_length} and #{turn} turning."

    # Figure out where to expect the snake
    watch_x = @x
    watch_y = @y
    dest_x = watch_x
    dest_y = watch_y
    # puts "Calcing #{watch_x},#{watch_y}, will end up at #{real_x(dest_x)}, #{real_y(dest_y)}"
    
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
    # t = Time.now 
    if watch_coord_for_color(real_x(watch_x), real_y(watch_y), SNAKE_COLOR_HSB) 
      # sleep ONE_SQUARE_TIME if behind
      # puts "Took #{t} secs to travel #{square_length} squares, at #{t/square_length} secs/square"
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
          puts "Color at watch point changed to #{color}"
          old_color = color
        end
      end
      # # Delay this error checking logic for just a little bit to make sure we don't make the check too slow to catch
      # # 1 block length gos, this doesnt actually work fast enough though
      # if i == 5
      #   unless @game_rectangle.contains(watch_x, watch_y)
      #     throw "Watch point #{watch_x}, #{watch_y} out of bounds!"
      #   else
      #     # puts "Watching point #{watch_x}, #{watch_y}"
      #   end
      #   self.mouse_move(watch_x, watch_y)     
      # end

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

  def threaded_watch_coord_for_color(watch_x, watch_y, hsb_array)
    return true if fast_watch_coord_for_color(watch_x, watch_y, hsb_array)
    lock = Mutex.new
    found = false
    threads = []
    3.times do |i|
      t = Thread::new do
        puts "Starting thread #{i}"
        SnakePlayer::MAX_CHECKS.times do |j|
          color = self.get_pixel_color(watch_x, watch_y)
          puts "thread #{i}: #{j} => #{color}" 
          if color.compare_hsb_array(0.08, hsb_array)
            # puts 
            puts "#{i} found #{color} at #{watch_x}, #{watch_y}"
            lock.synchronize do
              found = true
            end
            break
          else
            # print i
            # puts "#{i} is waiting, has #{color}"
          end
        end
        Thread.main.wakeup          
      end
      threads.push t
    end
    # self.mouseMove(watch_x, watch_y) 
    puts "Stopping main thread."
    Thread.stop unless found
    puts "Main thread resuming. Killing others."
    threads.each do |t|
      t.exit
    end
    return found
  end

  def articulate_counter_clockwise(sleep_time)
   self.change_direction(@direction.next_counter_clockwise)
   sleep sleep_time
   self.change_direction(@direction.next_counter_clockwise)
  end

  def articulate_clockwise(sleep_time)
   self.change_direction(@direction.next_clockwise)
   sleep sleep_time
   self.change_direction(@direction.next_clockwise)     
  end
  
  def articulate_down(sleep_squares=nil)
    sleep_squares ||= 1
    sleep_time = squares_sleep_time(sleep_squares)
    case @direction
    when :left then articulate_counter_clockwise(sleep_time)
    when :right then articulate_clockwise(sleep_time)
    when :up then articulate_clockwise(sleep_time)
    when :down then throw "Cant articulate down when going down"
    end
    @y += SQUARE_LENGTH * sleep_squares
    return true
  end

  def articulate_up(sleep_squares=nil)
    sleep_squares ||= 1
    sleep_time = squares_sleep_time(sleep_squares)
    case @direction
    when :left then articulate_clockwise(sleep_time)
    when :right then articulate_counter_clockwise(sleep_time)
    when :down then articulate_clockwise(sleep_time)
    when :up then throw "Cant articulate up when going up"
    end
    @y -= SQUARE_LENGTH * sleep_squares
    return true
  end

  def articulate_down_with_space
    self.articulate_down(2)
  end

  def change_direction(dir)
    @direction = dir
    self.click_key!(mask_for_direction(dir))
  end

  def click!(x,y)
    self.mouse_move(x,y)
    self.mouse_press(InputEvent::BUTTON1_MASK)
    sleep 0.2
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
  
  def prepare_for_game!
    unless self.prepare_for_game
      throw "Couldn't find a the game space!"
    end
    return true
  end

  def highlight_game
    click!(@game_rectangle.get_center_x, @game_rectangle.get_center_y)
    sleep 0.25
  end
  
  def start_game!
    space!
    sleep 0.1 # Wait for old game to clear for sure
  end 

  def play_dumb
    self.prepare_for_game!
    self.start_game!
    go(:up, 31)
    go(:right, 32)
    loop do
      15.times do
        articulate_down
        go(:left, 62, false)
        articulate_down
        go(:right, 62, false)
      end
      articulate_down
      go(:left, 63, false)
      go(:up, 31)
      go(:right, 63)

    end
  end

  def circle_in_center
    if self.prepare_for_game
      self.start_game!
      go(:up, 31)
      go(:left)
      loop do
        self.articulate_down
      end
    end
  end

  def play_in_columns
    # Program to find food
    self.prepare_for_game!
    puts "Game prepared."
    q = Queue.new

    dispatcher = Proc.new do
      puts "Scheduling next passage."
      Thread.current.abort_on_exception = true
      @length += FOOD_ADDS_SQUARES 
      food_x,food_y = self.find_food_on_grid
      if food_x == false
        puts "Couldn't find food!"
        throw "Couldn't find food on the grid!"
      else
        puts "Food found at #{food_x},#{food_y}"
        self.mouseMove(real_x(food_x*SQUARE_LENGTH),real_y(food_y*SQUARE_LENGTH))
      end
      # Add new actions to get to block from home state

      # Snake needs to articulate food_y times with a big enough x to get to the food
      # with everything above it on the map. Figure out how many blocks will be needed
      # in each row to get there
      adjusted_length = @length - 65
      if adjusted_length < 0
        # The whole snake fits in the return journey, no need to make a column.
        adjusted_length = 0
        row_width = 0
      elsif food_y > 2
        row_width = (adjusted_length / food_y).ceil # Estimate how wide we'll have to be to get the food. This gets changed later.
      else
        row_width = GAME_GRID_WIDTH # Do big rows to get the snake out of the way asap
      end

      # If the rows will fit, do them, then go back to the top.
      if row_width < (GAME_GRID_WIDTH - 2)
        puts "Rows will fit. Food is down #{food_y} rows, so we go down #{food_y}"
        rows = food_y
      else
        # The rows are too big, so either the snake is too long or the food is too high up.
        # Figure out how fast we can turn around doing full row traverses
        row_width = (GAME_GRID_WIDTH - 2)
        rows = (adjusted_length / row_width).ceil
        puts "Rows won't fit. Food is down #{food_y} rows, but we go down #{rows} so we fit before turning around."
      end
    
      # Move the column over if the food isn't in range. row_offset is the squares
      # from the right the column needs to be.
      if (row_width < (GAME_GRID_WIDTH - food_x))
        row_offset = (GAME_GRID_WIDTH - food_x) - row_width
      else
        row_offset = 0
      end

      if row_width == 0
        # Snake is short still, lets just go down and get the food, and then come back up.
        puts "Going straight down to #{food_x},#{food_y}"
        # Articulate and go left if the food isn't in the first column
        if row_offset > 0
          q.push [:articulate_down]
          q.push [:left, row_offset - 1, false]
        end
        # Go right down and get the food.
        q.push [:down, food_y-1, true] if food_y > 2
        q.push [:left, GAME_GRID_WIDTH-row_offset, true]
        up = food_y
      else 
        puts "Going down #{rows} at #{row_width} row width, #{row_offset} row offset."         
        q.push [:articulate_down]
        q.push [:left, row_offset, false] if row_offset > 0
        ((rows/2).ceil).times do
          q.push [:left, row_width, false]
          q.push [:articulate_down]
          q.push [:right, row_width, false]
          q.push [:articulate_down]               
        end
        # Add actions to return to home state.
        q.push [:left, GAME_GRID_WIDTH-1-row_offset, false]
        up = 1 + (rows/2).ceil*2      
      end


      # We've now eaten the block. Lets go back to the base state and do it again.
      # We went down one row at the top, and then (rows/2).ceil*2 times after that. Go back up that
      if up > 1
        q.push [:up, up, true]
      else
        q.push [:articulate_up]
      end
      q.push [:right, 0, true]
      q.push [:got_block]
      q.push [:right, GAME_GRID_WIDTH-1, true]        
    end

    q.push [:up, 31, true]
    q.push [:right, 32, true]
    self.start_game!      
    sleep 0.1 # Allow new food position to make itself seen
    dispatcher.call
    next_action = false

    until q.empty?
      if next_action
        action = next_action
        next_action = q.pop
      else
        action = q.pop
        next_action = q.pop
      end
      case action[0]
      when :articulate_down
        self.articulate_down
      when :articulate_up
        self.articulate_up
      when :got_block
        dispatcher.call
      else
        # Try and switch to a timed sequence if the length between turns is too short
        if(action[1] < TIME_GOS_UNDER_LENGTH && next_action.length == 3 && MAKE_SHORT_GOS_TIMED)
          puts "Applying timed optimization"
          self.timed_go(action[0], action[1], action[2])
          self.go(next_action[0], next_action[1], next_action[2])
          next_action = false
        else
          self.go(action[0], action[1], action[2])
        end          
      end
    end
    throw "Queue empty, game over."
  end
end
