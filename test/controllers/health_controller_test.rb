require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "should get up" do
    get health_up_url
    assert_response :success
  end
end
