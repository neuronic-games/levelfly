require 'digest'

class Game < ActiveRecord::Base
  validates :handle, :uniqueness => true

  has_many :feats
  
  after_create :generate_handle
  
  def get_score(profile_id)
    # This assumes that feat records are ordered chronologically
    feat = Game.where(profile_id: profile_id, game_id: self.id).last
    return feat.progress if feat
    return 0
  end
  
  private
  
  def generate_handle
    md5 = Digest::MD5.new
    md5 << "#{self.id}"
    self.handle = md5.hexdigest
    save
    return self.handle
  end
end
