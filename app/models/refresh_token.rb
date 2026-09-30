# Opaque, long-lived token used to obtain new access tokens. Only a SHA-256
# digest is stored, and each token is single-use: refreshing revokes it and
# issues a replacement. Presenting an already-revoked token is treated as
# theft and revokes every token the user holds.
class RefreshToken < ApplicationRecord
  TTL = 30.days

  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  class << self
    # Returns [record, raw_token]. The raw token is only available here.
    def issue_for(user)
      raw = SecureRandom.urlsafe_base64(32)
      record = user.refresh_tokens.create!(token_digest: digest(raw), expires_at: TTL.from_now)
      [ record, raw ]
    end

    def find_by_raw(raw)
      find_by(token_digest: digest(raw)) if raw.present?
    end

    def digest(raw)
      OpenSSL::Digest::SHA256.hexdigest(raw)
    end
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current) if revoked_at.nil?
  end
end
