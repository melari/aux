require 'webrick'

server = WEBrick::HTTPServer.new(Port: 8080, Logger: WEBrick::Log.new($stdout), AccessLog: [[$stdout, WEBrick::AccessLog::COMMON_LOG_FORMAT]])

server.mount_proc '/ping' do |_req, res|
  res.content_type = 'text/plain'
  res.body = 'pong'
end

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

server.start