require 'webrick'
require_relative 'endpoints/authenticated_endpoint'
require_relative 'endpoints/editor'
require_relative 'endpoints/notes'

server = WEBrick::HTTPServer.new(Port: 8080, Logger: WEBrick::Log.new($stdout), AccessLog: [[$stdout, WEBrick::AccessLog::COMMON_LOG_FORMAT]])

notes_servlet = Class.new(WEBrick::HTTPServlet::AbstractServlet) do
  %w[GET PUT POST DELETE].each do |m|
    define_method("do_#{m}") { |req, res| Notes.serve_api(req, res) }
  end
end
server.mount '/api/notes', notes_servlet

server.mount_proc '/ping' do |_req, res|
  res.content_type = 'text/plain'
  res.body = 'pong'
end

server.mount_proc '/' do |req, res|
  Editor.serve(:index, req, res)
end

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

server.start
