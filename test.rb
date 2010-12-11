require './dumb_robot'

t = Thread.new do
  puts "Here"

  100000.times do |i|
    if i % 10000 == 0
      puts i
      Thread.pass
    end
  end
  Thread.main.run
end

Thread.stop

puts "Below"
