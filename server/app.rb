require 'webrick'
require 'webauthn'

WebAuthn.configure do |c|
  c.origin  = ENV.fetch('PASSKEY_ORIGIN', 'http://localhost:8080')
  c.rp_name = 'aux notes'
end

require_relative 'endpoints/session'
require_relative 'endpoints/authenticated_endpoint'
require_relative 'endpoints/auth'
require_relative 'endpoints/setup'
require_relative 'endpoints/editor'
require_relative 'endpoints/notes'

server = WEBrick::HTTPServer.new(Port: 8080, Logger: WEBrick::Log.new($stdout), AccessLog: [[$stdout, WEBrick::AccessLog::COMMON_LOG_FORMAT]])

notes_servlet = Class.new(WEBrick::HTTPServlet::AbstractServlet) do
  %w[GET PUT POST DELETE].each do |m|
    define_method("do_#{m}") { |req, res| Notes.serve_api(req, res) }
  end
end
server.mount '/api/notes', notes_servlet

server.mount_proc '/logout' do |_req, res|
  res['Set-Cookie'] = "#{Session::COOKIE}=; Path=/; HttpOnly; SameSite=Strict; Max-Age=0"
  res.status = 302
  res['Location'] = '/auth'
end

server.mount_proc '/auth'  do |req, res| Auth.serve(req, res)  end
server.mount_proc '/setup' do |req, res| Setup.serve(req, res) end

server.mount_proc '/icon.svg' do |_req, res|
  res.content_type = 'image/svg+xml'
  res.body = File.read(File.expand_path('assets/icon.svg', __dir__))
end

server.mount_proc '/manifest.json' do |_req, res|
  res.content_type = 'application/manifest+json'
  res.body = {
    name: 'aux notes',
    short_name: 'aux',
    display: 'standalone',
    background_color: '#0c0c0c',
    theme_color: '#0c0c0c',
    start_url: '/',
    icons: [{ src: '/icon.svg', sizes: 'any', type: 'image/svg+xml' }]
  }.to_json
end

server.mount_proc '/ping' do |_req, res|
  res.content_type = 'text/plain'
  res.body = 'pong'
end

server.mount_proc '/' do |req, res|
  Editor.serve(:index, req, res)
end

trap('INT')  { server.shutdown }
trap('TERM') { server.shutdown }

server.start
