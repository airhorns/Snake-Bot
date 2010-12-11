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
