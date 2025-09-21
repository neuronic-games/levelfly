class Wall < ActiveRecord::Base
  belongs_to :parent, :polymorphic=>true
  
  def self.get_wall_id(parent_id, parent_type)
    create = true
    wall_id = nil
    begin
      @wall = Wall.where(["parent_id = ? AND parent_type = ?", parent_id, parent_type]).first
      if @wall
        wall_id = @wall.id
        create = false
      end
    rescue
    end

    begin
      if create
        @new_wall =  Wall.new
        @new_wall.parent_id  = parent_id
        @new_wall.parent_type  = parent_type
        if @new_wall.save
          wall_id = @new_wall.id
        end
      end
    rescue
    end
    return wall_id
  end
end
