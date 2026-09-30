require "test_helper"

class AuthTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @raw_refresh_token = SecureRandom.urlsafe_base64(32)
    @refresh_token = create(:refresh_token, user: @user, raw_token: @raw_refresh_token)
  end

  test "signup returns a token pair" do
    email = Faker::Internet.unique.email
    post api_v1_auth_signup_path, params: { name: Faker::Name.name, email: email, password: Faker::Internet.password(min_length: 8) }, as: :json

    assert_response :created
    assert_equal email, response.parsed_body.dig("user", "email")
    assert response.parsed_body.dig("user", "name").present?
    assert response.parsed_body["access_token"].present?
    assert response.parsed_body["refresh_token"].present?
  end

  test "signup with invalid params returns validation errors" do
    post api_v1_auth_signup_path, params: { email: @user.email, password: "short" }, as: :json

    assert_response :unprocessable_content
    assert response.parsed_body.dig("details", "name").present?
    assert response.parsed_body.dig("details", "email").present?
    assert response.parsed_body.dig("details", "password").present?
  end

  test "login with valid credentials" do
    post api_v1_auth_login_path, params: { email: @user.email.upcase, password: @user.password }, as: :json

    assert_response :success
    assert_equal @user.id, response.parsed_body.dig("user", "id")
  end

  test "login with wrong password" do
    post api_v1_auth_login_path, params: { email: @user.email, password: "wrong-password" }, as: :json

    assert_response :unauthorized
    assert_equal "invalid_credentials", response.parsed_body["error"]
  end

  test "me requires a valid access token" do
    get api_v1_auth_me_path
    assert_response :unauthorized

    get api_v1_auth_me_path, headers: { "Authorization" => "Bearer not-a-jwt" }
    assert_response :unauthorized

    get api_v1_auth_me_path, headers: bearer(JsonWebToken.encode(@user))
    assert_response :success
    assert_equal @user.email, response.parsed_body.dig("user", "email")
  end

  test "expired access tokens are rejected" do
    token = JsonWebToken.encode(@user)

    travel JsonWebToken::TTL + 1.second do
      get api_v1_auth_me_path, headers: bearer(token)
      assert_response :unauthorized
    end
  end

  test "tokens signed with another secret are rejected" do
    token = JWT.encode({ sub: @user.id.to_s, exp: 5.minutes.from_now.to_i, iss: "mindboop" }, "other-secret", "HS256")

    get api_v1_auth_me_path, headers: bearer(token)
    assert_response :unauthorized
  end

  test "refresh rotates the refresh token" do
    post api_v1_auth_refresh_path, params: { refresh_token: @raw_refresh_token }, as: :json

    assert_response :success
    assert_not_equal @raw_refresh_token, response.parsed_body["refresh_token"]
    assert @refresh_token.reload.revoked_at
  end

  test "replaying a rotated refresh token revokes every session" do
    post api_v1_auth_refresh_path, params: { refresh_token: @raw_refresh_token }, as: :json
    new_token = response.parsed_body["refresh_token"]

    post api_v1_auth_refresh_path, params: { refresh_token: @raw_refresh_token }, as: :json
    assert_response :unauthorized

    post api_v1_auth_refresh_path, params: { refresh_token: new_token }, as: :json
    assert_response :unauthorized
  end

  test "refresh with an unknown or expired token" do
    post api_v1_auth_refresh_path, params: { refresh_token: "nope" }, as: :json
    assert_response :unauthorized

    @refresh_token.update!(expires_at: 1.minute.ago)
    post api_v1_auth_refresh_path, params: { refresh_token: @raw_refresh_token }, as: :json
    assert_response :unauthorized
  end

  test "logout revokes the refresh token" do
    post api_v1_auth_logout_path, params: { refresh_token: @raw_refresh_token }, as: :json

    assert_response :no_content
    assert @refresh_token.reload.revoked_at
  end

  private
    def bearer(token)
      { "Authorization" => "Bearer #{token}" }
    end
end
