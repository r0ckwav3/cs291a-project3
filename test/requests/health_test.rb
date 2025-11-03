require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "healthcheck works" do
    get "/health"
    assert_response :ok
    response_data = JSON.parse(response.body)
    assert_equal "ok", response_data["status"]
    assert_not_nil response_data["timestamp"]
  end
end
