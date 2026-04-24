require 'openssl'
require 'securerandom'

module Session
  SECRET  = ENV.fetch('SESSION_SECRET') { SecureRandom.hex(32) }
  COOKIE  = 'aux_session'
  TTL     = 30 * 24 * 3600

  def self.create_token
    expiry = (Time.now.to_i + TTL).to_s
    sig    = OpenSSL::HMAC.hexdigest('SHA256', SECRET, expiry)
    "#{expiry}.#{sig}"
  end

  def self.valid?(token)
    return false unless token&.include?('.')
    expiry, sig = token.split('.', 2)
    return false if Time.now.to_i > expiry.to_i
    expected = OpenSSL::HMAC.hexdigest('SHA256', SECRET, expiry)
    secure_compare(expected, sig)
  end

  def self.set_cookie(res, token)
    res['Set-Cookie'] = "#{COOKIE}=#{token}; Path=/; HttpOnly; SameSite=Strict; Max-Age=#{TTL}"
  end

  def self.from_request(req)
    return nil unless req['Cookie']
    req['Cookie'].split(';').each do |pair|
      k, v = pair.strip.split('=', 2)
      return v if k == COOKIE
    end
    nil
  end

  def self.secure_compare(a, b)
    return false unless a.bytesize == b.bytesize
    l = a.unpack('C*')
    r = 0
    b.each_byte { |byte| r |= byte ^ l.shift }
    r.zero?
  end
end
