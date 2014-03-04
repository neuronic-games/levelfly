class AddAllowUploadsToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :allow_uploads, :boolean
  end
end
