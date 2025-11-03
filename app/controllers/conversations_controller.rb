class ConversationsController < ApplicationController
  include Authorized
  before_action :authorize
  before_action :fetch_authorize_conversation, only: [:show, :messages]

  def index
    conv_ids = Conversation.where(initiator: @user).to_a
    conv_ids += Conversation.joins(:expert_assignment).where(expert_assignments: { user: @user }).to_a
    conv_ids = conv_ids.flatten.uniq
    render json: conv_ids.map {|c| format_conversation c}
  end

  def show
    render json: format_conversation(@conv), status: :ok
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
    msgs = @conv.messages.order(:created_at)
    render json: msgs.map { |msg| format_message(msg) }, status: :ok
  end

  def post_message
    @conv = Conversation.find(params[:conversationId])
    return unless authorize_conversation()
    sender_role = @conv.initiator == @user ? "initiator" : "expert"
    msg = @conv.messages.create!(sender: @user, sender_role: sender_role, content: params[:content])
    render json: format_message(msg), status: :created
  end

  def mark_message_read
    msg = Message.find(params[:id])
    if !msg
      render json: {
        "error": "Message not found"
      }, status: :not_found
      return
    end

    @conv = msg.conversation
    return unless authorize_conversation()

    if msg.sender == @user
      render json: {
        "error": "Cannot mark your own messages as read"
      }, status: :forbidden
      return
    end

    msg.is_read = true
    msg.save

    render json: { "success": true }, status: :ok
  end

  private

  def fetch_authorize_conversation
    @conv = Conversation.find(params[:id])
    authorize_conversation()
  end

  def authorize_conversation
    if !@conv || (@conv.initiator != @user and @conv.assigned_expert != @user)
      render json: {
        "error": "Conversation not found"
      }, status: :not_found
      return false
    end
    return true
  end

  def format_message(msg)
    return {
      "id": msg.id.to_s,
      "conversationId": msg.conversation_id.to_s,
      "senderId": msg.sender_id.to_s,
      "senderUsername": msg.sender.username,
      "senderRole": msg.sender_role,
      "content": msg.content,
      "timestamp": msg.created_at,
      "isRead": msg.is_read
    }
  end

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
