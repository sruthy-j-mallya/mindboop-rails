require "test_helper"

class RefreshTokenTest < ActiveSupport::TestCase
  test "stores only a digest of the issued token" do
    record, raw = RefreshToken.issue_for(create(:user))
    assert_not_equal raw, record.token_digest
    assert_equal record, RefreshToken.find_by_raw(raw)
  end

  test "is inactive once expired or revoked" do
    assert create(:refresh_token).active?
    assert_not create(:refresh_token, :expired).active?
    assert_not create(:refresh_token, :revoked).active?
  end

  test "revoke! marks the token revoked" do
    token = create(:refresh_token)
    token.revoke!
    assert_not token.reload.active?
  end
end
