class Conversation < ApplicationRecord
  belongs_to :initiator, class_name: "User"
  has_many :messages
  has_one :expert_assignment
end
