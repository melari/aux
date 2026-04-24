require 'webrick'
require_relative 'endpoints/authenticated_endpoint'
require_relative 'endpoints/editor'

server = WEBrick::HTTPServer.new(Port: 8080, Logger: WEBrick::Log.new($stdout), AccessLog: [[$stdout, WEBrick::AccessLog::COMMON_LOG_FORMAT]])

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
