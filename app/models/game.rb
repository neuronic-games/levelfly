class Game < ActiveRecord::Base
  validates :handle, :uniqueness => true
  
  after_create :generate_handler
  
  private
  
  def generate_handler
    md5 = Digest::MD5.new
    md5 << "#{self.id}"
    self.handle = md5.hexdigest
    save
    return self.handle
  end
end
