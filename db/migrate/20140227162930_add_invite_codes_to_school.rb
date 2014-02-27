class AddInviteCodesToSchool < ActiveRecord::Migration
  def change
    add_column :schools, :student_code, :string
    add_column :schools, :teacher_code, :string
  end
end
