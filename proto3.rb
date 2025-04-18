require 'debug'
require_relative 'lib/div'

Div.new(id: 'outer-wrapper', border: { x: 5, y: 2 }, margin: 8, flex: :horizontal, children: [
  Div.new(id: 'left', width: '25%', padding: 1, border: { right: 1 }, flex: :vertical, children: [
    Div.new(content: "W" * 200, border: 1, border_style: :thin, margin: { bottom: 1 }),
    Div.new(content: "X" * 200, border: 1, border_style: :thick, margin: { bottom: 1 }),
    Div.new(content: "J" * 200, border: 1, border_style: :thin, margin: { bottom: 1 }),
    Div.new(content: "8" * 200, border: 1, border_style: :thick, margin: { bottom: 1 }),
    Div.new(content: "0" * 200, border: 1, border_style: :thin, margin: { bottom: 1 }),
    Div.new(content: "~" * 200, border: 1, border_style: :thick, margin: { bottom: 1 }),
  ]),
  Div.new(id: 'center', border: { right: 1 }, flex: :vertical, padding: 1, children: [
    Div.new(id: 'title', height: 2, content_renderer: TextRenderer.new(text_align: :center), content: "Check out this counter:"),
    Div.new(id: 'counter', content_renderer: TextRenderer.new(text_align: :center), height: 1, content: "0"),
  ]),
  Div.new(flex: :vertical, padding: { x: 1 }, children: [
    Div.new(height: 2, content_renderer: TextRenderer.new(text_align: :center), content: "Logs"),
    Div.new(id: 'logs', content_renderer: TextRenderer.new(overflow: :show_last))
  ])
])
Div['outer-wrapper'].start!

def log(msg)
  Div['logs'].content += msg + "\n"
end

i = 0
loop do
  i += 1
  sleep 0.1
  log("This is log number #{i}")

  if i == 100
    Div['logs'].content = "The content should be reset now\n"
  end

  Div['counter'].content = "#{i}"
end
