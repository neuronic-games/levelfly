class AddDescrToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :descr, :string
  end
end
