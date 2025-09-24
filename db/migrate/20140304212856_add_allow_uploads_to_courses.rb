class AddAllowUploadsToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :allow_uploads, :boolean
  end
end
