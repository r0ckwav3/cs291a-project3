class Message < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :conversation
  validates :sender_role, inclusion: { in: %w(initiator expert) }
end
