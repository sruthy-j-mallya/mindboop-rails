module JsonWebToken
  ALGORITHM = "HS256"
  ISSUER = "mindboop"
  TTL = 15.minutes

  class InvalidToken < StandardError; end

  module_function

  def encode(user)
    now = Time.current.to_i
    payload = { sub: user.id.to_s, iat: now, exp: now + TTL.to_i, iss: ISSUER, jti: SecureRandom.uuid }
    JWT.encode(payload, secret, ALGORITHM)
  end

  def decode(token)
    payload, _header = JWT.decode(token, secret, true, algorithm: ALGORITHM, iss: ISSUER, verify_iss: true, required_claims: %w[sub exp])
    payload
  rescue JWT::DecodeError => e
    raise InvalidToken, e.message
  end

  def secret
    Rails.application.credentials.jwt_secret || Rails.application.secret_key_base
  end
end
