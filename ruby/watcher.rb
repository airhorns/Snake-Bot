import javax.imageio.ImageIO
module Snake
  module Watcher
    # Finds a pattern (given as a 2D array)
    def find_pattern(pattern, rectangle=nil)
      rectangle ||= PATTERN_SEARCH
      screen_size = Toolkit.get_default_toolkit.get_screen_size
      image = self.create_screen_capture Rectangle.new(screen_size.width, screen_size.height)

      # Move the mouse around so the user knows where is being looked
      Thread.new do
        self.mouse_move(rectangle.x, rectangle.y)
        sleep 1
        self.mouse_move(rectangle.x+rectangle.width, rectangle.y+rectangle.height)
      end

      (rectangle.y..rectangle.y+rectangle.height).each do |y|
        (rectangle.x..rectangle.x+rectangle.width).each do |x|
          if image.pattern_at?(pattern, x, y)
            return Point.new(x, y) 
          end
        end
      end
      return false
    end

    # Finds the food on the grid
    def find_food_on_grid
      image = self.create_screen_capture Snake::Game.game_rectangle
      for y in 0..(Snake::Game.game_rectangle.height/SQUARE_LENGTH).floor
        for x in 0..(Snake::Game.game_rectangle.width/SQUARE_LENGTH).floor
          if Color.new(image.getRGB(x*SQUARE_LENGTH, y*SQUARE_LENGTH)).compare_hsb_array(0.125, FOOD_COLOR_HSB)
            return GridPoint.new(x, y)
          end
        end
      end
      return nil
    end

    def watch_point_for_color(point, color, max_checks=nil)
      max_checks ||= MAX_CHECKS
      x = point.real_x + 3
      y = point.real_y + 3
      hsb = color.hsb_array
      for i in 0..max_checks 
        found_color = self.get_pixel_color(x, y)
        if found_color.compare_hsb_array(0.2, hsb)
          puts "Found color after #{i} checks"
          return true
        end
      end
      throw "Color never appeared at #{point.real_x}, #{point.real_y}"
    end

    def test_watch_point_for_color(point, color, max_checks=nil)
      old_color = false
      images = []
      colors = []
      max_checks ||= MAX_CHECKS
      x = point.real_x + 3
      y = point.real_y + 3
      hsb = color.hsb_array

      for i in 0..max_checks 
        found_color = self.get_pixel_color(x, y)
        if found_color.compare_hsb_array(0.2, hsb)
          puts "Found #{found_color} at watch point #{x}, #{y} after #{i} checks."
          return true
        else
          if found_color != old_color
            puts "Color at watch point changed to #{found_color} after #{i} checks."
            old_color = found_color
          end
        end

        if i % 5 == 0
          images << self.create_screen_capture(Snake::Game.game_rectangle)
          colors << found_color
        end

        # Delay this error checking logic for just a little bit to make sure we don't make the check too slow to catch
        # 1 block length gos, this doesnt actually work fast enough though
        if i == 5
          unless Snake::Game.game_rectangle.contains(x, y)
            throw "Watch point #{x}, #{y} out of bounds!"
          end
          self.mouse_move(x,y)     
        end
      end
      render_debug_images(x, y, images, colors)
      throw "Color never appeared at #{point.real_x}, #{point.real_y}"
    end

    def watch_point_for_color_with_lookback(point, lookback_point, hsb_array)
      i = 0
      old_color = false
      dest_x = point.real_x + 3
      dest_y = point.real_y + 3
      wait_x = lookback_point.real_x + 3 
      wait_y = lookback_point.real_y + 3
      images = []
      colors = []

      for i in 0..MAX_CHECKS 
        color = self.getPixelColor(wait_x, wait_y)
        if color.compare_hsb_array(0.125, hsb_array)
          # puts "Found #{color} at wait point after #{i} at #{Time.now}"
          # images << self.create_screen_capture(Snake::Game.game_rectangle)
          # colors << color
          # Magic number 6 for the number of checks at the lookback point
          for j in 0..5  
            color = self.getPixelColor(dest_x, dest_y)
            puts "Color at dest is #{color}"
            if color.compare_hsb_array(0.125, hsb_array)
              break 
            end
          end
          # images << self.create_screen_capture(Snake::Game.game_rectangle)
          # colors << color
          # render_debug_images(dest_x, dest_y, images, colors)
          return true
        # else
        #   if color != old_color
        #     puts "Color at watch point changed to #{color} after #{i} checks."
        #     old_color = color
        #   end
        end
        # Delay this error checking logic for just a little bit to make sure we don't make the check too slow to catch
        # 1 block length gos, this doesnt actually work fast enough though
        if i == 5
          unless Snake::Game.game_rectangle.contains(point.real_x, point.real_y)
            throw "Watch point #{point.real_x}, #{ point.real_y} out of bounds!"
          end
          self.mouse_move(point.real_x,  point.real_y)     
        end
      end
      throw "Color never appeared at #{point.real_x}, #{point.real_y}"
    end

    def render_debug_images(x, y, images, colors)
      images.each_with_index do |image, index|
        (-1..1).each do |i|
          (-1..1).each do |j|
            image.setRGB(x - Snake::Game.game_rectangle.x - i, y - Snake::Game.game_rectangle.y - j, BLACK.getRGB) if (i != 0 && j != 0)
          end
        end
        (0..5).each do |i|
          (0..5).each do |j|
            image.setRGB(i, j, colors[index].getRGB)
          end
        end
        ImageIO.write(image, "png", java.io.File.new("./test#{index}.png"))
      end
    end
  end
end
