class AddContactInfoToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :contact_info, :string
  end
end
