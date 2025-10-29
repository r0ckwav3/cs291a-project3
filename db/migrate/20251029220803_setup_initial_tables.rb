class SetupInitialTables < ActiveRecord::Migration[8.1]
  def change
    # create_table :users, id: :bigint do |t|
    #   t.string :username, null: false, unique: true
    #   t.string :password_digest, null: false
    #   t.datetime :last_active_at
    #   t.timestamps
    # end
    # add_index :users, :username, unique: true

    create_table :conversations, id: :bigint do |t|
      t.string :title, null: false
      t.string :status, null: false, default: 'waiting'
      t.bigint :initiator_id, null: false
      t.bigint :assigned_expert_id
      t.datetime :last_message_at
      t.timestamps
    end
    add_foreign_key :conversations, :users, column: :initiator_id
    add_foreign_key :conversations, :users, column: :assigned_expert_id

    create_table :messages, id: :bigint do |t|
      t.bigint :conversation_id, null: false
      t.bigint :sender_id, null: false
      t.string :sender_role, null: false
      t.text :content, null: false
      t.boolean :is_read, null: false, default: false
      t.timestamps
    end
    add_foreign_key :messages, :conversations
    add_foreign_key :messages, :users, column: :sender_id

    create_table :expert_profiles, id: :bigint do |t|
      t.bigint :user_id, null: false
      t.text :bio
      t.json :knowledge_base_links
      t.timestamps
    end
    add_foreign_key :expert_profiles, :users
    add_index :expert_profiles, :user_id, unique: true

    create_table :expert_assignments, id: :bigint do |t|
      t.bigint :conversation_id, null: false
      t.bigint :expert_id, null: false
      t.string :status, null: false, default: 'active'
      t.datetime :assigned_at, null: false
      t.datetime :resolved_at
      t.timestamps
    end
    add_foreign_key :expert_assignments, :conversations
    add_foreign_key :expert_assignments, :users, column: :expert_id
  end
end
