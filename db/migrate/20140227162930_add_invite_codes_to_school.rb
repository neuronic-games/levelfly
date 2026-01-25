class AddInviteCodesToSchool < ActiveRecord::Migration[4.2]
  def change
    add_column :schools, :student_code, :string
    add_column :schools, :teacher_code, :string
  end
end
