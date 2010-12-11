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
    diff += (comp_array[0] - own_hsb[0]).abs
    diff += (comp_array[1] - own_hsb[1]).abs
    diff += (comp_array[2] - own_hsb[2]).abs
    return (diff <= tolerance)
  end

  def compare_rgb_array(tolerance, comp_array)
    throw "not implemented"
  end

  def compare_rgb_value(tolerance, comp_value)

  end
end
