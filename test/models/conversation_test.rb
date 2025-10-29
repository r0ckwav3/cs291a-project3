require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "unassigned conversation associations work" do
    user1 = User.create!(username: "Alice", password: "abc123")
    conversation = Conversation.create!(initiator: user1, title: "test convo")
    message = conversation.messages.create!(content: "hi!", sender: user1, sender_role: "initiator")

    assert(conversation.initiator == user1)
    assert(user1.conversations.size == 1)
    assert(user1.conversations[0] == conversation)

    assert(message.conversation == conversation)
    assert(conversation.messages.size == 1)
    assert(conversation.messages[0] == message)

    assert(message.sender == user1)
    assert(user1.messages.size == 1)
    assert(user1.messages[0] == message)
  end

  test "assigned conversation associations work" do
    user1 = User.create!(username: "Alice", password: "abc123")
    user2 = User.create!(username: "Bob", password: "pass")
    conversation = Conversation.create!(initiator: user1, title: "test convo")
    message1 = conversation.messages.create!(content: "hi!", sender: user1, sender_role: "initiator")
    eassign = ExpertAssignment.create!(user: user2, conversation: conversation, assigned_at: Time.current())
    message2 = conversation.messages.create!(content: "what's the issue", sender: user2, sender_role: "expert")

    assert(conversation.initiator == user1)
    assert(user1.conversations.size == 1)
    assert(user1.conversations[0] == conversation)

    assert(user2.expert_assignments.size == 1)
    assert(user2.expert_assignments[0] == eassign)
    assert(eassign.user == user2)

    assert(eassign.conversation == conversation)
    assert(conversation.expert_assignment == eassign)

    assert(message1.conversation == conversation)
    assert(message2.conversation == conversation)
    assert(conversation.messages.size == 2)
    assert(conversation.messages[0] == message1)
    assert(conversation.messages[1] == message2)

    assert(message1.sender == user1)
    assert(user1.messages.size == 1)
    assert(user1.messages[0] == message1)

    assert(message2.sender == user2)
    assert(user2.messages.size == 1)
    assert(user2.messages[0] == message2)
end
end
