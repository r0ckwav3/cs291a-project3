require "test_helper"

class ExpertTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", password: "password123")
    @token = JwtService.encode(@user)
    @other_user = User.create!(username: "eviluser", password: "password123")
    @other_token = JwtService.encode(@other_user)
    @expert = User.create!(username: "expertuser", password: "password123")
    @expert_token = JwtService.encode(@expert)
    ExpertProfile.create!(user: @expert, bio: "Expert developer", knowledge_base_links: [])
  end

  test "GET /queue returns assigned conversations" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "waiting")
    get "/expert/queue", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 1, response_data["assignedConversations"].length
    assert_equal 0, response_data["waitingConversations"].length

    assert_equal conversation.id.to_s, response_data["assignedConversations"][0]["id"]
  end


  test "GET /queue returns waiting conversations" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, status: "waiting")
    get "/expert/queue", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 0, response_data["assignedConversations"].length
    assert_equal 1, response_data["waitingConversations"].length

    assert_equal conversation.id.to_s, response_data["waitingConversations"][0]["id"]
  end

  test "GET /queue does not return conversations assigned to others" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "waiting")
    get "/expert/queue", headers: { "Authorization" => "Bearer #{@other_token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal 0, response_data["assignedConversations"].length
    assert_equal 0, response_data["waitingConversations"].length
  end

  test "can claim an unclaimed conversation" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, status: "waiting")
    post "/expert/conversations/#{conversation.id}/claim", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :ok

    conversation.reload

    assert_equal @expert, conversation.assigned_expert
    assert_equal "active", conversation.status
  end

  test "cannot claim a claimed conversation" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @other_user, status: "active")
    post "/expert/conversations/#{conversation.id}/claim", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :unprocessable_entity
  end


  test "can unclaim a conversation" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "active")
    post "/expert/conversations/#{conversation.id}/unclaim", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :ok

    conversation.reload

    assert_nil conversation.assigned_expert
    assert_equal "waiting", conversation.status
    # make sure we actually deleted the row in the expert assignments table
    assert_equal 0, ExpertAssignment.count
  end

  test "cannot unclaim an unclaimed conversation" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @other_user, status: "active")
    post "/expert/conversations/#{conversation.id}/unclaim", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :forbidden

    conversation2 = Conversation.create!(title: "Test Conversation", initiator: @user, status: "waiting")
    post "/expert/conversations/#{conversation2.id}/unclaim", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :forbidden
  end
end
