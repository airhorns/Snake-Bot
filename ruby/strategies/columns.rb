module Snake
  class ColumnsStrategy < Strategy
    def run(player)
      # Program to find food
      player.prepare_for_game!
      puts "Game prepared."
      q = Queue.new

      dispatcher = Proc.new do
        puts "Scheduling next passage."
        # Thread.current.abort_on_exception = true
        food_point = player.interactor.find_food_on_grid
        # Apply hack to make sure food is low enough to be gotten
        if food_point.nil?
          throw "Couldn't find food on the grid!"
        else
          food_x = food_point.grid_x
          food_y = food_point.grid_y
          puts "Food found at #{food_x},#{food_y}"
          player.interactor.mouse_move(food_point.real_x,food_point.real_y)
        end
        # Add new actions to get to block from home state

        # Snake needs to articulate food_y times with a big enough x to get to the food
        # with everything above it on the map. Figure out how many blocks will be needed
        # in each row to get there
        adjusted_length = player.length - 65
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
            q.push [:articulate_down]
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
      player.start_game!      
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
          player.articulate_down
        when :articulate_up
          player.articulate_up
        when :got_block
          player.length += FOOD_ADDS_SQUARES
          dispatcher.call
        else
          # Try and switch to a timed sequence if the length between turns is too short
          # if(action[1] < TIME_GOS_UNDER_LENGTH && next_action.length == 3 && MAKE_SHORT_GOS_TIMED)
          #   puts "Applying timed optimization"
          #   self.timed_go(action[0], action[1], action[2])
          #   self.go(next_action[0], next_action[1], next_action[2])
          #   next_action = false
          # else
          player.go(action[0], action[1], action[2])
          # end
        end
      end
    end
  end
end
