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
    if @conv.assigned_expert != @user
      render json: {
        "error": "You are not assigned to this conversation"
      }, status: :forbidden
      return
    end

    @conv.expert_assignment.destroy
    @conv.status = "waiting"
    @conv.save

    render json: {
      "success": true
    }, status: :ok
  end

  def show_profile
    render json: format_profile(@user.expert_profile)
  end

  def edit_profile
    ep = @user.expert_profile

    if params[:bio]
      ep.bio = params[:bio]
    end
    if params[:knowledgeBaseLinks]
      ep.knowledge_base_links = params[:knowledgeBaseLinks]
    end

    ep.save

    render json: format_profile(ep)
  end

  def assignment_history
    render json: @user.expert_assignments.map{|ea| format_assignment(ea)}
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

  def format_profile(ep)
    return {
      "id": ep.id.to_s,
      "userId": ep.user_id.to_s,
      "bio": ep.bio,
      "knowledgeBaseLinks": ep.knowledge_base_links,
      "createdAt": ep.created_at,
      "updatedAt": ep.updated_at
    }
  end

  def format_assignment(ea)
    return {
      "id": ea.id.to_s,
      "conversationId": ea.conversation_id.to_s,
      "expertId": ea.user_id.to_s,
      "status": ea.conversation.status,
      "assignedAt": ea.assigned_at,
      "resolvedAt": ea.resolved_at,
      "rating": ea.rating
    }
  end
end
