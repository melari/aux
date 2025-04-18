require 'tty/screen'
require 'tty/cursor'
require 'tty/box'









logs = []

(0..10000).each do |i|
  logs << "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW" + i.to_s * i

  printable_lines = 3

  log_l


  box = TTY::Box.frame(title: { top_left: " AI Thoughts " }, width: TTY::Screen.width, height: printable_lines + 3, padding: 1, top: TTY::Screen.height - 10, left: 0) { logs.last(2).join("\n") }
  print box

  sleep 0.5
end

jsdklfjskldf


MOVE_UP = "\e[A"
CLEAR_LINE = "\e[K"

# Jumps to the given line index
# Lines are indexed starting from the bottom, numbered from 1
def move_to_line(i)
  print "\e[#{i}F"
end

def puts_on_line(i, str)
  move_to_line(i)
  print CLEAR_LINE
  puts str
end


@logs = []

def log(msg)
  @logs << msg
end

def draw
  puts_on_line(20, "AUX 🤖")
  puts_on_line(19, "Here are the logs:")

  amount_to_show = [@logs.length, 10].min
  @logs[-amount_to_show..-1].each do |log|
    print CLEAR_LINE
    puts log
  end
end

width = TTY::Screen.width

# claim screen space
(0..20).each do |i|
  puts i.to_s + ("■" * (width - i.to_s.length))
end

sleep 2

move_to_line(4)
puts "HI"

sleep 2

move_to_line(4)
puts "YO"

sleep 2

i = 0
loop do
  sleep 1
  draw
  log("Hello, world! #{i}")
  i += 1
end
