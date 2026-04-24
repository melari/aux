require_relative 'session'

class AuthenticatedEndpoint
  def self.serve(endpoint_name, req, res)
    unless Session.valid?(Session.from_request(req))
      res.status = 302
      res['Location'] = '/auth'
      return
    end
    self.new.send(endpoint_name, req, res)
  end
end
