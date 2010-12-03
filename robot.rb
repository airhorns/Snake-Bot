include Java

import java.awt.Robot
import java.awt.Color
import java.awt.image.BufferedImage
import java.awt.Toolkit
import java.awt.Rectangle
import javax.imageio.ImageIO
import java.awt.Graphics2D


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

class SnakePlayer
  attr_accessor :robot, :game_x, :game_y
  def initialize
    @robot = Robot.new
  end

  def find_game_space
    pattern = [
      [PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR, PAGE_BACKGROUND_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BORDER_COLOR],
      [PAGE_BACKGROUND_COLOR, GAME_BORDER_COLOR, GAME_BACKGROUND_COLOR]
    ]
    screen_size = Toolkit.getDefaultToolkit.getScreenSize
    image = @robot.createScreenCapture Rectangle.new(screen_size.width, screen_size.height)

    (400...500).each do |y|
      (40...50).each do |x|
        # puts "checking #{x},#{y}"
        if image.pattern_at?(pattern, x, y)
          @game_x = x
          @game_y = y
          return true
        end
      end
    end
    return false
  end

end

puts player = SnakePlayer.new
puts player.find_game_space
frame = javax.swing.JFrame.new("test")
# frame.setVisible(true)
com.sun.awt.AWTUtilities.setWindowOpacity(frame, 0.5)
frame.setSize(java.awt.Dimension.new(512, 258))
frame.setLocation(59, 461)

loop do
  input = gets.chomp
  if input == "test"
    puts frame.getLocation
    puts frame.getgetSize
  elsif input =~ /(\d+),(\d+)/
    screen_size = Toolkit.getDefaultToolkit.getScreenSize    
    image = player.robot.createScreenCapture Rectangle.new(screen_size.width, screen_size.height)    
    puts image.getRGB($1.to_i, $2.to_i)
  end
end

