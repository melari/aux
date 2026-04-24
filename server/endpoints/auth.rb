require 'json'
require 'base64'
require 'webauthn'
require_relative 'session'

class Auth
  CREDENTIAL_FILE = File.expand_path('../passkey.json', __dir__)
  CHALLENGES      = {}

  def self.serve(req, res)
    case req.path
    when '/auth'        then page(res)
    when '/auth/challenge' then challenge(res)
    when '/auth/verify'    then verify(req, res)
    else
      res.status = 404
    end
  end

  def self.page(res)
    res.content_type = 'text/html'
    res.body = File.read(File.expand_path('../templates/auth.html', __dir__))
  end

  def self.challenge(res)
    unless File.exist?(CREDENTIAL_FILE)
      return json(res, 409, error: 'no passkey registered — visit /setup first')
    end

    cred    = JSON.parse(File.read(CREDENTIAL_FILE))
    options = WebAuthn::Credential.options_for_get
    challenge_b64 = Base64.urlsafe_encode64(options.challenge, padding: false)
    CHALLENGES[:auth] = { challenge: challenge_b64, expires: Time.now.to_i + 300 }

    json(res, 200,
      challenge:        challenge_b64,
      timeout:          options.timeout,
      allowCredentials: [{ type: 'public-key', id: cred['id'] }],
      userVerification: 'preferred'
    )
  end

  def self.verify(req, res)
    stored = CHALLENGES.delete(:auth)
    return json(res, 400, error: 'no pending challenge') unless stored
    return json(res, 400, error: 'challenge expired')    if Time.now.to_i > stored[:expires]
    return json(res, 409, error: 'no passkey registered') unless File.exist?(CREDENTIAL_FILE)

    cred_data  = JSON.parse(File.read(CREDENTIAL_FILE))
    credential = WebAuthn::Credential.from_get(JSON.parse(req.body))
    credential.verify(
      stored[:challenge],
      public_key: cred_data['public_key'],
      sign_count: cred_data['sign_count'].to_i
    )

    cred_data['sign_count'] = credential.sign_count.to_i
    File.write(CREDENTIAL_FILE, cred_data.to_json)

    Session.set_cookie(res, Session.create_token)
    json(res, 200, ok: true)
  rescue => e
    json(res, 401, error: e.message)
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
