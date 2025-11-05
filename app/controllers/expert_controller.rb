class ExpertController < ApplicationController
  include Authorized
  before_action :authorize

  def queue

    waiting = Conversation.left_joins(:expert_assignment).where(expert_assignments: { user: nil })
    assigned = Conversation.left_joins(:expert_assignment).where(expert_assignments: { user: @user.id })

    render json: {
      "waitingConversations": waiting.map {|c| format_conversation c},
      "assignedConversations": assigned.map {|c| format_conversation c}
    }
  end

  def claim
  end

  def unclaim
  end

  def show_profile
  end

  def edit_profile
  end

  def assignment_history
  end

  private

  # identical to the one in conversations_controller.rb
  def format_conversation(conv)
    return {
      "id": conv.id.to_s,
      "title": conv.title,
      "status": conv.status,
      "questionerId": conv.initiator.id.to_s,
      "questionerUsername": conv.initiator.username,
      "assignedExpertId": conv.assigned_expert&.id&.to_s,
      "assignedExpertUsername": conv.assigned_expert&.username,
      "createdAt": conv.created_at,
      "updatedAt": conv.updated_at,
      "lastMessageAt": conv.last_message_at,
      "unreadCount": conv.unread_count(@user)
    }
  end
end
