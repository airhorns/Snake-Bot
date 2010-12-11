
class SnakePlayer < Robot
 
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
    if (square_length > 4 ? threaded_watch_coord_for_color(real_x(watch_x), real_y(watch_y), SNAKE_COLOR_HSB) : watch_coord_for_color(real_x(watch_x), real_y(watch_y), SNAKE_COLOR_HSB))
      # sleep ONE_SQUARE_TIME if behind
      # puts "Took #{t} secs to travel #{square_length} squares, at #{t/square_length} secs/square"
      @x = dest_x
      @y = dest_y
      return true
    else
      return false
    end
  end
  
  def fast_watch_coord_for_color(watch_x, watch_y, hsb_array)
    until self.getPixelColor(watch_x, watch_y).compare_hsb_array(0.125, hsb_array)
    end
    return true
  end

  def threaded_watch_coord_for_color(watch_x, watch_y, hsb_array)
    lock = Mutex.new
    found = false
    threads = []
    4.times do |i|
      t = Thread.new do
        Thread.current.abort_on_exception = true
        old_color = false
        for j in 0..MAX_CHECKS 
          color = self.get_pixel_color(watch_x, watch_y)
          if color.compare_hsb_array(0.08, hsb_array)
            puts "#{i} found #{color} at #{watch_x}, #{watch_y} after #{j} checks"
            found = true
            break
          end
          if found == true
            break
          end
          # if old_color != color
          #   puts "thread #{i} found color change to #{color} after #{j} checks."
          #   old_color = color 
          # end
        end
        Thread.main.run          
      end
      threads.push t
    end
    self.mouseMove(watch_x, watch_y) 
    puts "Stopping main thread."
    Thread.stop unless found
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
      # Apply hack to make sure food is low enough to be gotten
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
        if food_y <= 2
          q.push[:articulate_down]
          turned_left = true
          up = 1
        else
          # Go right down and get the food.
          q.push [:down, food_y, true]
          turned_left = false
          up = food_y
        end
        q.push [:left, GAME_GRID_WIDTH-1, !turned_left]
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
        # if(action[1] < TIME_GOS_UNDER_LENGTH && next_action.length == 3 && MAKE_SHORT_GOS_TIMED)
        #   puts "Applying timed optimization"
        #   self.timed_go(action[0], action[1], action[2])
        #   self.go(next_action[0], next_action[1], next_action[2])
        #   next_action = false
        # else
          self.go(action[0], action[1], action[2])
        # end          
      end
    end
    throw "Queue empty, game over."
  end
end
