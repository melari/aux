class Editor < AuthenticatedEndpoint
  TEMPLATE = File.expand_path('../templates/editor.html', __dir__)

  def index(req, res)
    res.content_type = 'text/html'
    res.body = File.read(TEMPLATE)
  end
end
