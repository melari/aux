class String
  def indent(level)
    ' ' * level + self.gsub(/\n/, "\n" + ' ' * level)
  end
end
