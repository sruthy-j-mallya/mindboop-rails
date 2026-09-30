FactoryBot.define do
  factory :refresh_token do
    user

    transient do
      raw_token { SecureRandom.urlsafe_base64(32) }
    end

    token_digest { RefreshToken.digest(raw_token) }
    expires_at { RefreshToken::TTL.from_now }

    trait :expired do
      expires_at { 1.minute.ago }
    end

    trait :revoked do
      revoked_at { 1.minute.ago }
    end
  end
end
