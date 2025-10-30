require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  self.use_instantiated_fixtures = :no_instances
  def setup
    @user = User.create!(username: "existinguser", password: "password123")
  end

  test "allows good register" do
    post auth_register_url, params: {username: "newuser", password: "abcdefg"}
    assert_response :success

    user2 = User.find_by(username: "newuser")
    assert_not_nil user2

    json = JSON.parse(response.body)
    assert json["user"].is_a?(Hash)
    assert_equal user2.id, json["user"]["id"]
    assert_equal user2.username, json["user"]["username"]
    assert json["token"].is_a?(String)
    assert_not_empty json["token"]
  end

  test "blocks bad register" do
    post auth_register_url, params: {username: "existinguser", password: "abcdefg"}
    assert_response :unprocessable_entity
  end

  test "allows good login" do
    post auth_login_url, params: { username: "existinguser", password: "password123" }
    assert_response :success

    json = JSON.parse(response.body)
    assert json["user"].is_a?(Hash)
    assert_equal @user.id, json["user"]["id"]
    assert_equal @user.username, json["user"]["username"]
    assert json["token"].is_a?(String)
    assert_not_empty json["token"]
  end

  test "blocks bad login" do
    post auth_login_url, params: { username: "existinguser", password: "thisisabadpassword" }
    assert_response :unauthorized
  end

  test "me works when logged in" do
    post auth_login_url, params: { username: "existinguser", password: "password123" }
    assert_response :success
    get auth_me_url
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @user.id, json["id"]
    assert_equal @user.username, json["username"]
  end

  test "me fails when not logged in" do
    get auth_me_url
    assert_response :unauthorized
  end

  test "me fails when logged out" do
    post auth_login_url, params: { username: "existinguser", password: "password123" }
    assert_response :success
    post auth_logout_url
    assert_response :success
    get auth_me_url
    assert_response :unauthorized
  end

  test "me accepts jwt token after logout" do
    post auth_login_url, params: { username: "existinguser", password: "password123" }
    assert_response :success
    token = JSON.parse(response.body)["token"]
    post auth_logout_url
    assert_response :success

    # The issue is likely that setting @request.headers does not work as expected in Rails integration tests.
    # Instead, you should pass the headers as an argument to the `get` method, like this:
    get auth_me_url, headers: { 'Authorization' => token }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @user.id, json["id"]
    assert_equal @user.username, json["username"]
  end

  test "refresh gives a unique valid token" do
    post auth_login_url, params: { username: "existinguser", password: "password123" }
    assert_response :success
    token1 = JSON.parse(response.body)["token"]

    sleep 2

    post auth_refresh_url
    assert_response :success
    token2 = JSON.parse(response.body)["token"]

    post auth_logout_url
    assert_response :success
    get auth_me_url, headers: { 'Authorization' => token2 }
    assert_response :success

    assert_not_equal token1, token2
  end
end
