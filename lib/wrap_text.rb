module WrapText
  def wrap_text(text, width)
    raise ArgumentError, "Width must be a positive integer" unless width > 0

    lines = []
    until text.empty?
      # If the next explicit linebreak is within the width, take it
      if text.index("\n") && text.index("\n") < width
        lines << text[0...text.index("\n")].strip
        text = text[(text.index("\n") + 1)..]
        next
      end

      # If the text is shorter than the width, take it all
      if text.length <= width
        lines << text.strip
        break
      end

      # Try to find the last space within the limit
      breakpoint = text.rindex(' ', width)

      if breakpoint.nil? || breakpoint == 0
        # No space found — hard break at width
        lines << text[0...width]
        text = text[width..]
      else
        # Break at the space
        lines << text[0...breakpoint]
        text = text[(breakpoint + 1)..]
      end
    end

    lines
  end
end
