class CreateMessageChats < ActiveRecord::Migration
  create_table :message_chats do |t|
    t.integer  :uid, :default => 0
    t.integer  :channel_id, :default => 0
    t.string   :content
    t.datetime :created_at
    t.timestamps
  end
  add_index :message_chats, [:channel_id, :created_at]

  create_table :message_channels do |t|
    t.string     :name
    t.timestamps
  end
  add_index :message_channels, [:name], :unique => true
end
