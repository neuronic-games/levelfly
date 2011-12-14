class AddLikeAndPostCountToProfile < ActiveRecord::Migration
  def change
    change_table :profiles do |t|
      t.integer :like_given
      t.integer :like_received
      t.integer :post_count
    end
  end
end
