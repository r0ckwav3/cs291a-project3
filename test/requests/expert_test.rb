require "test_helper"

class ExpertTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", password: "password123")
    @token = JwtService.encode(@user)
    @other_user = User.create!(username: "eviluser", password: "password123")
    @other_token = JwtService.encode(@other_user)
    @expert = User.create!(username: "expertuser", password: "password123")
    @expert_token = JwtService.encode(@expert)
    ExpertProfile.create!(user: @expert, bio: "Expert developer", knowledge_base_links: ["lists","examples","reflexivity"])
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
    assert_not_nil conversation.expert_assignment.assigned_at
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

  test "can get profile" do
    get "/expert/profile", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    ep = @expert.expert_profile
    assert_equal ep.id.to_s, response_data["id"]
    assert_equal @expert.id.to_s, response_data["userId"]
    assert_equal ep.bio, response_data["bio"]
    assert_equal ep.knowledge_base_links, response_data["knowledgeBaseLinks"]
  end

  test "can update profile" do
    put "/expert/profile",
         params: {
           "bio": "Expert at testing",
           "knowledgeBaseLinks": ["unit tests", "integration tests"]
         }, headers: {
           "Authorization" => "Bearer #{@expert_token}"
         }
    assert_response :ok
    response_data = JSON.parse(response.body)

    @expert.reload
    @expert.expert_profile.reload

    assert_equal "Expert at testing", @expert.expert_profile.bio
    assert_equal "Expert at testing", response_data["bio"]
    assert_equal ["unit tests", "integration tests"], response_data["knowledgeBaseLinks"]
  end

  test "can get expert assignments" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "active")
    get "/expert/assignments/history", headers: { "Authorization" => "Bearer #{@expert_token}" }
    assert_response :ok

    response_data = JSON.parse(response.body)

    assert_equal 1, response_data.length
    assert_equal conversation.expert_assignment.id.to_s, response_data[0]["id"]
    assert_equal conversation.expert_assignment.user_id.to_s, response_data[0]["expertId"]
    assert_equal conversation.id.to_s, response_data[0]["conversationId"]
    assert_equal conversation.expert_assignment.status, response_data[0]["status"]
    assert_not_nil response_data[0]["assignedAt"]
    assert_nil response_data[0]["resolvedAt"]
    assert_equal conversation.expert_assignment.rating, response_data[0]["rating"]
  end
end
