class AuthenticatedEndpoint
  def self.serve(endpoint_name, req, res)
    ensure_authenticated!
    self.new.send(endpoint_name, req, res)
  end

  def self.ensure_authenticated!
    #TODO check keypass session
  end
end
