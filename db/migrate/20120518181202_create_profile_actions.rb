class CreateProfileActions < ActiveRecord::Migration[4.2]
  def change
    create_table :profile_actions do |t|
      t.integer       :profile_id
      t.string        :action_type, limit: 10
      t.string        :action_param
      t.timestamps
    end
  end
end
