# This is a monkey patch for the ollama-ruby gem.

class Ollama::Commands::List
  include Ollama::DTO

  def self.path
    '/api/tags'
  end

  def initialize(insecure: nil, stream: true)
    @insecure, @stream = insecure, stream
  end

  attr_reader :insecure, :stream

  attr_writer :client

  def perform(handler)
    @client.request(method: :get, path: self.class.path, body: to_json, stream:, handler:)
  end
end

class Ollama::Client
  command(:list, default_handler: Single)
end
