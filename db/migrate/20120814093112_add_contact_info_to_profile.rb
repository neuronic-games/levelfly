class AddContactInfoToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :contact_info, :string
  end
end
