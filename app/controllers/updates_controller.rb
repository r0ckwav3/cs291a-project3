class UpdatesController < ApplicationController
  include Authorized
  before_action :authorize
  before_action :get_user_and_since

  def conversations
    conversations = Conversation
      .left_outer_joins(:expert_assignment)
      .where('conversations.updated_at >= ?', @since)
      .where(
        'conversations.initiator_id = :user_id OR expert_assignments.user_id = :user_id',
        user_id: @target_user.id
      ).distinct

    render json: conversations.map { |conv| FormatterService.format_conversation(conv, @user) }, status: :ok
  end

  def messages
    messages = Message
      .left_outer_joins(:conversation)
      .joins("LEFT OUTER JOIN expert_assignments ON expert_assignments.conversation_id = conversations.id")
      .where('messages.updated_at >= ?', @since)
      .where(
        'conversations.initiator_id = :user_id OR expert_assignments.user_id = :user_id',
        user_id: @target_user.id
      ).distinct
    render json: messages.map { |msg| FormatterService.format_message(msg) }, status: :ok
  end

  def queue
    waiting = Conversation
      .left_joins(:expert_assignment)
      .where(expert_assignments: { user: nil })
      .where('conversations.updated_at >= ?', @since)
    assigned = Conversation
      .left_joins(:expert_assignment)
      .where(expert_assignments: { user: @target_user.id })
      .where('conversations.updated_at >= ?', @since)

    render json: {
      "waitingConversations": waiting.map {|c| FormatterService.format_conversation(c, @user)},
      "assignedConversations": assigned.map {|c| FormatterService.format_conversation(c, @user)}
    }
  end

  private

  def get_user_and_since
    @since = params[:since] ? Time.parse(params[:since]) : Time.at(0)

    user_id = params[:userId] ? params[:userId] : params[:expertId]
    @target_user = User.find(user_id)
    if @target_user == nil
      render json: {
        "error": "User not found"
      }, status: :not_found
      return
    end
  end
end
