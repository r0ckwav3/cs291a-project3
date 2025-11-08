require "test_helper"

class UpdatesTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", password: "password123")
    @token = JwtService.encode(@user)
    @other_user = User.create!(username: "eviluser", password: "password123")
    @other_token = JwtService.encode(@other_user)
    @expert = User.create!(username: "expertuser", password: "password123")
    @expert_token = JwtService.encode(@expert)
    ExpertProfile.create!(user: @expert, bio: "Expert developer", knowledge_base_links: [])
  end

  test "api/conversations/updates gets updated conversations" do
    conversation1 = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "assigned")
    conversation2 = Conversation.create!(title: "Test Conversation 2", initiator: @expert, status: "waiting")

    get "/api/conversations/updates",
      params: {"userId": @expert.id, "since": Time.new(2024,1,1)},
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 2, response_data.length
  end


  test "api/conversations/updates doesnt need since param" do
    conversation1 = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "assigned")
    conversation2 = Conversation.create!(title: "Test Conversation 2", initiator: @expert, status: "waiting")

    get "/api/conversations/updates",
      params: {"userId": @expert.id},
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 2, response_data.length
  end

  test "api/conversations/updates doesn't get old conversations" do
    conversation1 = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "assigned")
    conversation2 = Conversation.create!(title: "Test Conversation 2", initiator: @expert, status: "waiting")

    get "/api/conversations/updates",
      params: {"userId": @expert.id, "since": Time.current() + 86400},
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 0, response_data.length
  end

  test "api/conversations/updates doesn't get other conversations" do
    conversation1 = Conversation.create!(title: "Test Conversation", initiator: @user, status: "waiting")

    get "/api/conversations/updates",
      params: {"userId": @expert.id, "since": Time.new(2024,1,1)},
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 0, response_data.length
  end

  test "api/messages/updates gets new messages" do
    conversation1 = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "assigned")
    conversation2 = Conversation.create!(title: "Test Conversation 2", initiator: @expert, assigned_expert: @other_user, status: "assigned")
    message1 = conversation1.messages.create!(sender: @user, sender_role: "initiator", content:"test1")
    message2 = conversation1.messages.create!(sender: @expert, sender_role: "expert", content:"test2")
    message3 = conversation2.messages.create!(sender: @expert, sender_role: "initiator", content:"test3")
    message4 = conversation2.messages.create!(sender: @other_user, sender_role: "expert", content:"test4")

    get "/api/messages/updates",
      params: {"userId": @expert.id, "since": Time.new(2024,1,1)},
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 4, response_data.length
  end

  test "api/messages/updates doesnt get old messages" do
    conversation1 = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "assigned")
    message1 = conversation1.messages.create!(sender: @user, sender_role: "initiator", content:"test1")

    get "/api/messages/updates",
      params: {"userId": @expert.id, "since": Time.current() + 86400},
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 0, response_data.length
  end


  test "api/messages/updates doesnt need since param" do
    conversation1 = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "assigned")
    message1 = conversation1.messages.create!(sender: @user, sender_role: "initiator", content:"test1")

    get "/api/conversations/updates",
      params: {"userId": @expert.id},
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 1, response_data.length
  end
end
