require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email" do
    user = create(:user, email: "  Bob@Example.COM ")
    assert_equal "bob@example.com", user.email
  end

  test "rejects duplicate email regardless of case" do
    existing = create(:user)
    user = build(:user, email: existing.email.upcase)
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires a name" do
    assert_not build(:user, name: "   ").valid?
  end

  test "requires a password of at least 8 characters" do
    assert_not build(:user, password: "short").valid?
  end
end
