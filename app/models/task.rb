class Task < ActiveRecord::Base
  has_many :group
  belongs_to :category
  belongs_to :school
  belongs_to :task
  belongs_to :course
  belongs_to :group
  has_many :task_participants
  #has_many :participants, :as => :object
  has_many :attachments, :as => :object
  has_many :messages, :as => :parent
  has_many :outcome_tasks
  has_attached_file :image,
    :storage => :s3,
    :s3_credentials => { :access_key_id => School.vault.account, :secret_access_key => School.vault.secret },
    :path => "schools/:school/courses/:course/tasks/:id/:filename",
    :bucket => School.vault.folder
    
  def image_file
    return image_file_name ? image.url : Course.default_image_file
  end 

  def show_date_format(the_date)
    return the_date.strftime('%d/%m/%Y')
  end
  
  def self.filter_by(profile_id, filter, period)
    conditions = ["task_participants.profile_id = ? and archived = ?", profile_id, false]

    if filter == "starred"
      conditions[0] += " and task_participants.priority = ?"
      conditions << 'H'
    elsif !filter.to_s.empty?
      conditions[0] += " and course_id = ?"
      conditions << filter.to_i
    end
    
    if period == "current"
      conditions[0] += " and task_participants.complete_date is null"
    elsif period == "past"
      conditions[0] += " and task_participants.complete_date is not null"
    end

    tasks = Task.find(
      :all, 
      :include => [:task_participants], 
      :conditions => conditions,
      :order => "due_date"
    )
  end
  
end
