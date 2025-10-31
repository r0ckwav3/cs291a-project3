class ConversationsController < ApplicationController
  include Authorized
  before_action :authorize

  def index
    conv_ids = Conversation.where(initiator: @user).to_a
    conv_ids += Conversation.joins(:expert_assignment).where(expert_assignments: { user: @user }).to_a
    conv_ids = conv_ids.flatten.uniq
    render json: conv_ids.map {|c| format_conversation c}
  end

  def show
    conv = Conversation.find(params[:id])
    if !conv || (conv.initiator != @user and conv.assigned_expert != @user)
      render json: {
        "error": "Conversation not found"
      }, status: :not_found
      return
    end
    render json: format_conversation(conv), status: :ok
  end

  def create
    if !params[:title] or params[:title].length == 0
      render json: {
        "errors": ["Title can't be blank"]
      }, status: :unprocessable_entity
      return
    end

    conv = Conversation.create!(title: params[:title], initiator: @user)
    render json: format_conversation(conv), status: :created
  end

  def messages
  end

  private

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
