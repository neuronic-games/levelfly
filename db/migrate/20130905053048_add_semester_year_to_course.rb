class AddSemesterYearToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :semester, :string
    add_column :courses, :year, :integer
  end
end
