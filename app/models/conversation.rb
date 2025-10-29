class Conversation < ApplicationRecord
  belongs_to :user, foreign_key: "initiator_id"
  has_many :messages
  has_one :expert_assignment
end
