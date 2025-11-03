require "test_helper"

class ConversationsTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", password: "password123")
    @token = JwtService.encode(@user)
    @expert = User.create!(username: "expertuser", password: "password123")
    @expert_token = JwtService.encode(@expert)
    ExpertProfile.create!(user: @expert, bio: "Expert developer", knowledge_base_links: [])
  end

  test "/messages returns all messages" do
    conversation = Conversation.create!(title: "Test Conversation", initiator: @user, assigned_expert: @expert, status: "assigned")
    msg1 = conversation.messages.create!(sender: @user, sender_role: "initiator", content:"How do I deploy a Rails application?", is_read: true)
    msg2 = conversation.messages.create!(sender: @expert, sender_role: "expert", content:"You can use Heroku, AWS, or DigitalOcean...", is_read: false)
    get "/conversations/#{conversation.id}/messages", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :ok
    response_data = JSON.parse(response.body)

    assert_equal msg1.id.to_s, response_data[0]["id"]
    assert_equal conversation.id.to_s, response_data[0]["conversationId"]
    assert_equal @user.id.to_s, response_data[0]["senderId"]
    assert_equal @user.username, response_data[0]["senderUsername"]
    assert_equal "initiator", response_data[0]["senderRole"]
    assert_equal "How do I deploy a Rails application?", response_data[0]["content"]
    assert_not_nil response_data[0]["timestamp"]
    assert response_data[0]["isRead"]

    assert_equal msg2.id.to_s, response_data[1]["id"]
    assert_equal conversation.id.to_s, response_data[1]["conversationId"]
    assert_equal @expert.id.to_s, response_data[1]["senderId"]
    assert_equal @expert.username, response_data[1]["senderUsername"]
    assert_equal "expert", response_data[1]["senderRole"]
    assert_equal "You can use Heroku, AWS, or DigitalOcean...", response_data[1]["content"]
    assert_not_nil response_data[1]["timestamp"]
    assert_not response_data[1]["isRead"]
  end
end
