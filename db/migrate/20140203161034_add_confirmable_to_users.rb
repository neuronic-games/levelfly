class AddConfirmableToUsers < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      User.update_all(:confirmed_at => Time.now)
    end
  end

  def down
    change_table :users do |t|
      remove_column :users, :confirmation_token
      remove_column :users, :confirmed_at
      remove_column :users, :confirmation_sent_at
    end
  end
end
