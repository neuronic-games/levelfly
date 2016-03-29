require 'digest'

class Game < ActiveRecord::Base
  validates :handle, :uniqueness => true

  has_many :feats
  has_many :game_score_leaders

  has_attached_file :image,
   :storage => :s3,
   :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
   :path => "games/:id/:filename",
   :bucket => ENV['S3_PATH'],
   :s3_protocol => ENV['S3_PROTOCOL'],
   :default_url => "/assets/:style/missing.jpg"
  
  after_create :generate_handle
  
  # Returns the player's score for the game. It is assumed that the last score
  # in the list is the final score. Thus scores would normally be in increasing
  # order, although it is possible for the score to go down.
  def get_score(profile_id)
    # This assumes that feat records are ordered chronologically
    feat = self.feats.where(profile_id: profile_id, progress_type: Feat.score).last
    return feat.progress if feat
    return 0
  end

  # Returns the player's xp for the game. It is assumed that the last xp
  # in the list is the final xp. XP cannot go back down because it is tied
  # to level rewards.
  def get_xp(profile_id)
    # This assumes that feat records are ordered chronologically
    feat = self.feats.where(profile_id: profile_id, progress_type: Feat.xp).last
    return feat.progress if feat
    return 0
  end
  
  # Add the score feat to the leaderboard, if the user is not already on it
  def self.add_score_leader(feat, count = 50)
    add_new = true
    
    # Update the leader if they are already in the leaderboard
    leader = GameScoreLeader.where(game_id: feat.game_id, profile_id: feat.profile_id).first
    if leader and leader.score < feat.progress
      leader.score = feat.progress
      leader.full_name = feat.profile.full_name  # In case the name has changed
      leader.save
      return
    end
    
    # Else, check to see if the person should be added
    leaders = GameScoreLeader.where(game_id: feat.game_id).order("score desc")
    last_leader = leaders.last
    if leaders.length > count 
      if last_leader.score < feat.progress
        # Remove the last person in the list
        last_leader.delete
      else
        add_new = false
      end
    end

    if add_new
      leader = GameScoreLeader.new
      leader.game_id = feat.game_id
      leader.profile_id = feat.profile_id
      leader.full_name = feat.profile.full_name
      leader.score = feat.progress
      leader.save
    end
  end
  
  private
  
  # Generate a unique game handle. The game developer will use this handle to
  # connect to Levelfly. The handle is a hash of the object ID, so it is
  # important that the object is stored first before calling this.
  def generate_handle
    md5 = Digest::MD5.new
    md5 << "#{self.id}"
    self.handle = md5.hexdigest
    save
    return self.handle
  end
end
