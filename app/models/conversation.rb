class Conversation < ApplicationRecord
  belongs_to :initiator, class_name: "User"
  has_many :messages
  has_one :expert_assignment

  def unread_count(user)
    messages.where(is_read: false).where.not(sender: user).count
  end

  def assigned_expert=(expert)
    ea = ExpertAssignment.find_or_create_by(conversation: self)
    ea.user = expert
    ea.assigned_at = Time.current()
  end

  def assigned_expert
    expert_assignment&.user
  end
end
