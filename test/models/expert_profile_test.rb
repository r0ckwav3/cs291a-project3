require "test_helper"

class ExpertProfileTest < ActiveSupport::TestCase
  test "profile associations work" do
    user = User.create!(username: "Alice", password: "abc123")
    profile = ExpertProfile.create!(user: user)

    assert(user.expert_profile == profile)
    assert(profile.user == user)
  end
end
