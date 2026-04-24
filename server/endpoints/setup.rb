require 'json'
require 'base64'
require 'securerandom'
require 'webauthn'
require_relative 'session'

class Setup
  CREDENTIAL_FILE  = File.expand_path('../passkey.json', __dir__)
  SETUP_PASSWORD   = ENV['PASSKEY_SETUP_PASSWORD']
  CHALLENGES       = {}

  def self.serve(req, res)
    case req.path
    when '/setup'             then page(res)
    when '/setup/challenge'   then challenge(req, res)
    when '/setup/verify'      then verify(req, res)
    else
      res.status = 404
    end
  end

  def self.page(res)
    res.content_type = 'text/html'
    res.body = File.read(File.expand_path('../templates/setup.html', __dir__))
  end

  def self.challenge(req, res)
    unless SETUP_PASSWORD
      return json(res, 503, error: 'PASSKEY_SETUP_PASSWORD is not configured on this server')
    end

    params = JSON.parse(req.body)
    unless Session.secure_compare(SETUP_PASSWORD, params['password'].to_s)
      return json(res, 401, error: 'incorrect password')
    end

    options = WebAuthn::Credential.options_for_create(
      user: { id: SecureRandom.random_bytes(16), name: 'user', display_name: 'user' }
    )
    challenge_b64 = Base64.urlsafe_encode64(options.challenge, padding: false)
    CHALLENGES[:setup] = { challenge: challenge_b64, expires: Time.now.to_i + 300 }

    json(res, 200,
      challenge:        challenge_b64,
      timeout:          options.timeout,
      rp:               { name: WebAuthn.configuration.rp_name },
      user:             { id: Base64.urlsafe_encode64(options.user.id, padding: false), name: 'user', displayName: 'user' },
      pubKeyCredParams: [{ type: 'public-key', alg: -7 }, { type: 'public-key', alg: -257 }],
      attestation:      'none'
    )
  end

  def self.verify(req, res)
    stored = CHALLENGES.delete(:setup)
    return json(res, 400, error: 'no pending challenge') unless stored
    return json(res, 400, error: 'challenge expired')    if Time.now.to_i > stored[:expires]

    credential = WebAuthn::Credential.from_create(JSON.parse(req.body))
    credential.verify(stored[:challenge])

    File.write(CREDENTIAL_FILE, utf8({
      id:         credential.id,
      public_key: credential.public_key,
      sign_count: credential.sign_count
    }).to_json)

    Session.set_cookie(res, Session.create_token)
    json(res, 200, ok: true)
  rescue => e
    json(res, 400, error: e.message)
  end

  def self.json(res, status, data)
    res.status = status
    res.content_type = 'application/json'
    res.body = utf8(data).to_json
  end

  def self.utf8(obj)
    case obj
    when String then obj.encode('UTF-8', 'binary', invalid: :replace, undef: :replace)
    when Hash   then obj.transform_keys { |k| utf8(k) }.transform_values { |v| utf8(v) }
    when Array  then obj.map { |v| utf8(v) }
    else obj
    end
  end
end
