class ConversationsController < ApplicationController
  include Authorized
  before_action :authorize
  before_action :fetch_conversation, only: [:show, :messages]

  def index
    conv_ids = Conversation.where(initiator: @user).to_a
    conv_ids += Conversation.joins(:expert_assignment).where(expert_assignments: { user: @user }).to_a
    conv_ids = conv_ids.flatten.uniq
    render json: conv_ids.map {|c| FormatterService.format_conversation(c, @user)}
  end

  def show
    render json: FormatterService.format_conversation(@conv, @user), status: :ok
  end

  def create
    if !params[:title] or params[:title].length == 0
      render json: {
        "errors": ["Title can't be blank"]
      }, status: :unprocessable_entity
      return
    end

    conv = Conversation.create!(title: params[:title], initiator: @user)
    render json: FormatterService.format_conversation(conv, @user), status: :created
  end

  def messages
    msgs = @conv.messages.order(:created_at)
    render json: msgs.map { |msg| FormatterService.format_message(msg) }, status: :ok
  end

  def post_message
    @conv = Conversation.find(params[:conversationId])
    if !@conv
      render json: {
        "error": "Conversation not found"
      }, status: :not_found
      return
    elsif @user != @conv.initiator && @user != @conv.assigned_expert
      render json: {
        "error": "You have not joined this conversation"
      }, status: :forbidden
      return
    end
    sender_role = @conv.initiator == @user ? "initiator" : "expert"
    msg = @conv.messages.create!(sender: @user, sender_role: sender_role, content: params[:content])
    render json: FormatterService.format_message(msg), status: :created
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
    if !@conv
      render json: {
        "error": "Conversation not found"
      }, status: :not_found
      return
    end

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

  def fetch_conversation
    @conv = Conversation.find(params[:id])
    if !@conv
      render json: {
        "error": "Conversation not found"
      }, status: :not_found
      return false
    end
  end
end
