require 'digest'

has_many :feats

class Game < ActiveRecord::Base
  validates :handle, :uniqueness => true
  
  after_create :generate_handle
  
  private
  
  def generate_handle
    md5 = Digest::MD5.new
    md5 << "#{self.id}"
    self.handle = md5.hexdigest
    save
    return self.handle
  end
end
