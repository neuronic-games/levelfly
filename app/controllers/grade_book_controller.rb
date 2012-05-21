class GradeBookController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
   def index
     render :partial => "/grade_book/list"
  end

end
