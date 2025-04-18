require 'tty/screen'
require_relative 'indent'
require_relative 'colorize'
require_relative 'split_by_percentage'
require_relative 'wrap_text'
require_relative 'terminal_renderer'

class LayoutOverflowError < StandardError; end

class DirectionalProperty
  attr_accessor :top, :bottom, :left, :right

  def initialize(data)
    if data.is_a?(Hash)
      self.top = data[:top] || data[:y] || 0
      self.bottom = data[:bottom] || data[:y] || 0
      self.left = data[:left] || data[:x] || 0
      self.right = data[:right] || data[:x] || 0
    else
      self.top = data
      self.bottom = data
      self.left = data
      self.right = data
    end
  end

  def to_a
    [top, right, bottom, left]
  end
end

# Options:
# text_align: :left, :right, :center
# overflow: :show_first, :show_last
class TextRenderer
  include WrapText
  include TerminalRenderer

  attr_reader :text_align, :overflow

  def initialize(text_align: :left, overflow: :show_first)
    @text_align = text_align
    @overflow = overflow
  end

  def render(container)
    return if container.content.empty?

    lines = wrap_text(container.content, container.inner_w)

    # Grab the lines that are visible given the height of the container
    lines_to_show = overflow == :show_first ? lines.first(container.inner_h) : lines.last(container.inner_h)

    # Fill in any empty lines with spaces; this clears previous content if there was any
    lines_to_show << " " * container.inner_w until lines_to_show.length == container.inner_h

    # Now we actually print the lines
    lines_to_show.each_with_index do |line, i|
      move_cursor(container.l, container.u + i)
      if text_align == :left
        print line.ljust(container.inner_w)
      elsif text_align == :right
        print line.rjust(container.inner_w)
      else
        print line.center(container.inner_w)
      end
    end
  rescue ArgumentError
    raise LayoutOverflowError.new("content too large for div[#{container.id}]")
  end
end

# width and height are the intended size of the div (could be :full, '50%', 100)
# x, y, w, h are the actual calculated size of the div (always a precise integer)
# The bounds of the div (ie from x to x+w and y to y+h) INCLUDE the margin, border, and padding.
class Div
  include SplitByPercentage
  include TerminalRenderer

  @@primary_index = {}

  @@main_wrapper = nil
  @@render_lock = false
  @@redraw_required = false

  attr_reader :parent, :children, :id, :width, :height, :padding, :margin, :border, :flex, :border_style
  attr_reader :x, :y, :w, :h
  attr_reader :content, :content_renderer

  def boilerplate(direction)
    margin.send(direction) + border.send(direction) + padding.send(direction)
  end

  def l; x + boilerplate(:left); end
  def u; y + boilerplate(:top); end
  def r; x + w - boilerplate(:right); end
  def d; y + h - boilerplate(:bottom); end
  def inner_w; r - l; end
  def inner_h; d - u; end

  def initialize(id: nil, children: [], width: :full, height: :full, padding: 0, margin: 0, border: 0, border_style: :auto, flex: :horizontal, content: '', content_renderer: TextRenderer.new())
    @@primary_index[id] = self if id

    @id = id
    @width = width
    @height = height
    @padding = DirectionalProperty.new(padding)
    @margin = DirectionalProperty.new(margin)
    @border = DirectionalProperty.new(border)
    @border_style = border_style
    @flex = flex

    @x = 0
    @y = 0
    @w = 0
    @h = 0

    @content = content
    @content_renderer = content_renderer

    @parent = nil
    @children = []
    children.each { |child| add_child(child) }

    calculate! if parent.nil?
  end

  def add_child(child)
    @children << child
    child.parent = self
  end

  # Start! should be called on the main outer wrapper once you're read to start rendering.
  # This performs the initial render and sets up a signal trap for window resize events.
  def start!
    calculate!
    render!

    @@main_wrapper = self
    Signal.trap("WINCH") do
      calculate!
      if @@render_lock
        @@redraw_required = true
      else
        render!
      end
    end
  end

  # The render lock is used to prevent multiple threads (main thread & screen resize signal thread) from rendering at the same time.
  # If the lock is already held when the WINCH signal is received, we set the @@redraw_required flag instead of immediately redrawing.
  # It is then up to the holder of the lock to check this flag and redraw if necessary.
  def with_render_lock(&block)
    return block.call if @@render_lock

    @@render_lock = true
    block.call
    @@render_lock = false

    if @@redraw_required
      @@redraw_required = false
      @@main_wrapper.render!
    end
  end

  # Calculates the position and size of the children within this container
  # Assumes that the size and position of THIS container is already correct
  def calculate!
    # If this is the top level element, we have to manually grab the dims from the screen
    if parent.nil? && (@w != TTY::Screen.width || @h != TTY::Screen.height)
      @w = TTY::Screen.width
      @h = TTY::Screen.height
    end

    flex_dim = flex == :horizontal ? :w : :h
    flex_dim_intent = flex == :horizontal ? :width : :height
    flex_pos = flex == :horizontal ? :x : :y
    flex_inner_pos = flex == :horizontal ? :l : :u
    flex_inner_dim = flex == :horizontal ? :inner_w : :inner_h

    fixed_dim = flex == :horizontal ? :h : :w
    fixed_pos = flex == :horizontal ? :y : :x
    fixed_inner_pos = flex == :horizontal ? :u : :l
    fixed_inner_dim = flex == :horizontal ? :inner_h : :inner_w

    # Update the position and size along the fixed (non-flex) dimension
    children.each do |child|
      child.send("#{fixed_pos}=", self.send(fixed_inner_pos))
      child.send("#{fixed_dim}=", self.send(fixed_inner_dim))
    end

    # We keep track of the total remaining space that will be used up for the children
    unused_space = self.send(flex_inner_dim)

    # First we calculate any percentage based children
    # We are careful to do integer division without over-allocation
    # Ie a space of 13 divided between two 50% children will be 6 and 7
    percentage_based_children = children.select do |child|
      child.send(flex_dim_intent).is_a?(String) && child.send(flex_dim_intent).end_with?('%')
    end
    if percentage_based_children.any?
      percentages = percentage_based_children.map { |child| child.send(flex_dim_intent).to_i }
      percentages << 100 - percentages.sum if percentages.sum < 100 # ie if there's a single 25% child, percentages will be [25, 75]
      splits = split_by_percentage(unused_space, percentages)
      percentage_based_children.each_with_index do |child, i|
        child.send("#{flex_dim}=", splits[i])
        unused_space -= splits[i]
      end
    end
    raise LayoutOverflowError.new("at Div[#{id}]") if unused_space < 0

    # Next we calculate any fixed size children
    fixed_width_children = children.select { |child| child.send(flex_dim_intent).is_a?(Integer) }
    fixed_width_children.each do |child|
      child.send("#{flex_dim}=", child.send(flex_dim_intent))
      unused_space -= child.send(flex_dim_intent)
    end
    raise LayoutOverflowError.new("at Div[#{id}]") if unused_space < 0

    # Finally, any remaining space is used equally among any remaining children
    remaining_children = children.select { |child| child.send(flex_dim_intent) == :full }
    if remaining_children.any?
      splits = split_by_percentage(unused_space, [100.0 / remaining_children.length] * remaining_children.length)
      remaining_children.each_with_index do |child, i|
        child.send("#{flex_dim}=", splits[i])
        unused_space -= splits[i]
      end
    end
    raise LayoutOverflowError.new("at Div[#{id}]") if unused_space < 0

    # Now that we now the sizes of all the children, we can calculate their positions
    pos = self.send(flex_inner_pos)
    children.each do |child|
      child.send("#{flex_pos}=", pos)
      pos += child.send(flex_dim)
    end

    children.each { |child| child.calculate! }
  end

  # Resets the canvas to border-only, ready to draw content
  def clear!
    if border_style == :auto
      border.to_a.any? { |b| b > 1 } ? draw_thick_border : draw_thin_border
    elsif border_style == :thin
      draw_thin_border
    elsif border_style == :thick
      draw_thick_border
    else
      raise ArgumentError.new("Invalid border style: #{border_style}")
    end
  end

  def draw_thick_border
    (0...h).each do |i|
      move_cursor(x, y + i)
      if (i >= margin.top && i < margin.top + border.top) || (i >= h - margin.bottom - border.bottom && i < h - margin.bottom)
        print(
          " " * margin.left +
          "█" * (border.left + + padding.left + inner_w + padding.right + border.right) +
          " " * margin.right
        )
      elsif i < margin.top || i >= h - margin.bottom
        print(" " * w)
      else
        print(
          " " * margin.left +
          "█" * border.left + 
          " " * (padding.left + inner_w + padding.right) +
          "█" * border.right +
          " " * margin.right
        )
      end
    end
  end

  def draw_thin_border
    (0...h).each do |i|
      move_cursor(x, y + i)
      if i >= margin.top && i < margin.top + border.top
        print(
          " " * margin.left +
          "┌" * border.left +
          "─" * padding.left +
          "─" * inner_w +
          "─" * padding.right +
          "┐" * border.right +
          " " * margin.right
        )
      elsif i >= h - margin.bottom - border.bottom && i < h - margin.bottom
        print(
          " " * margin.left +
          "└" * border.left +
          "─" * padding.left +
          "─" * inner_w +
          "─" * padding.right +
          "┘" * border.right +
          " " * margin.right
        )
      elsif i < margin.top || i >= h - margin.bottom
        print(" " * w)
      else
        print(
          " " * margin.left +
          "│" * border.left + 
          " " * padding.left +
          " " * inner_w +
          " " * padding.right +
          "│" * border.right +
          " " * margin.right
        )
      end
    end
  end

  # The default render method renders the text from top to bottom
  def render!(clear: true)
    with_render_lock do
      clear! if clear
      children.each { |child| child.render! }
      content_renderer.render(self)
    end
  end

  def content=(value)
    @content = value
    render!(clear: false)
  end

  def to_s
    str = "<div#'#{id}' (#{x}, #{y}):(#{w}, #{h}) - Intent:(#{width}, #{height})>"
    str += "\n#{children.map(&:to_s).join("\n")}\n" if children.any?
    str += "</div>"
    str = str.indent(2) unless parent.nil?
    str
  end

  def self.[](id)
    @@primary_index[id]
  end

  protected def parent=(parent); @parent = parent; end
  protected def x=(x); @x = x; end
  protected def y=(y); @y = y; end
  protected def w=(w); @w = w; end
  protected def h=(h); @h = h; end
end
