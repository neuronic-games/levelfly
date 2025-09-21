class AddDescrToBadges < ActiveRecord::Migration
  def change
    add_column :badges, :descr, :string
  end
end
