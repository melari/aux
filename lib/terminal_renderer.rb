module TerminalRenderer
  # The terminal uses 1-based indexing
  def move_cursor(x, y)
    print "\e[#{y+1};#{x+1}H"
  end
end
