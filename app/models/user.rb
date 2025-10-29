class User < ApplicationRecord
  has_one :expert_profile
  has_many :expert_assignments
  has_many :messages, foreign_key: "sender_id"
  has_many :conversations, foreign_key: "initiator_id"
  has_secure_password
end
