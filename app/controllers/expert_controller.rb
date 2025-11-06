class ExpertController < ApplicationController
  include Authorized
  before_action :authorize
  before_action :fetch_conversation, only: [:claim, :unclaim]

  def queue
    waiting = Conversation.left_joins(:expert_assignment).where(expert_assignments: { user: nil })
    assigned = Conversation.left_joins(:expert_assignment).where(expert_assignments: { user: @user.id })

    render json: {
      "waitingConversations": waiting.map {|c| format_conversation c},
      "assignedConversations": assigned.map {|c| format_conversation c}
    }
  end

  def claim
    if @conv.assigned_expert
      render json: {
        "error": "Conversation is already assigned to an expert"
      }, status: :unprocessable_entity
      return
    end

    @conv.assigned_expert = @user
    @conv.status = "active"
    @conv.save

    render json: {
      "success": true
    }, status: :ok
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


  # copied from conversations_controller.rb
  def fetch_conversation
    @conv = Conversation.find(params[:id])
    if !@conv
      render json: {
        "error": "Conversation not found"
      }, status: :not_found
      return false
    end
  end

  # copied conversations_controller.rb
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
