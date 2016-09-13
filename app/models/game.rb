require 'digest'
class Game < ActiveRecord::Base
  serialize :download_links, Hash
  PLATFORMS = ['ios', 'android', 'windows', 'mac', 'linux']
  validates :handle, :uniqueness => true
  belongs_to :school
  has_many :feats
  has_many :game_score_leaders
  has_many :outcomes, :dependent => :destroy
  has_many :screen_shots, :dependent => :destroy
  belongs_to :course
  accepts_nested_attributes_for :outcomes, :allow_destroy => true
  accepts_nested_attributes_for :screen_shots, :allow_destroy => true

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
  
  # Returns a list of all player scores in descending order
  def get_all_scores_in_order(limit = 50)
    all_score = self.feats.where(progress_type: Feat.score).group(:profile_id).maximum(:progress)
    top_score = all_score.sort_by { |profile_id, score| score }.reverse.first(limit)
    top_score.each do |profile_score|
      profile = Profile.find(profile_score[0])  # profile_id
      profile_score << profile.full_name
      profile_score << profile.image_file_name
      profile_score << profile.xp
    end
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

  # Returns the total time that a player has been active in a game
  def get_duration(profile_id)
    dur = Feat.where(game_id: self.id, profile_id: profile_id, progress_type: Feat.duration).sum(:progress)
    return dur
  end

  # Returns the last level achieved
  def get_level(profile_id)
    feat = Feat.where(game_id: self.id, profile_id: profile_id).where("level is not null").last
    return feat ? feat.level : ""
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
  
  # Owns the game or have played the game
  def my_game?(profile_id)
    return true if profile_id == self.profile_id
    feat = Feat.where(:profile_id => profile_id).first
    return true if feat
    return false
  end
  
  def list_feats(profile_id, limit = 100)
    @feats = []
    @profile = Profile.find(profile_id)
    feat_list = Feat.where(game_id: self.id, profile_id: profile_id)
      .order("created_at desc")
      .limit(limit)

    feat_list.each do |feat|
      case feat.progress_type
      when Feat.login
        @feats << "[#{feat.created_at}] #{@profile.full_name} logged into #{self.name}"
      when Feat.xp
        @feats << "[#{feat.created_at}] #{@profile.full_name} has a current XP of #{feat.progress}"
      when Feat.score
        @feats << "[#{feat.created_at}] #{@profile.full_name} has a current score of #{feat.progress}"
      when Feat.badge
        badge = Badge.find_by_id(feat.progress)
        if badge
          @feats << "[#{feat.created_at}] #{@profile.full_name} acquired #{badge ? badge.name : 'unknown'} badge"
        end
      when Feat.rating
        @feats << "[#{feat.created_at}] #{@profile.full_name} acquired a #{feat.outcome_feat.rating} rating in '#{feat.outcome.name}'"
      when Feat.game_level
        @feats << "[#{feat.created_at}] #{@profile.full_name}"
      when Feat.duration
        @feats << "[#{feat.created_at}] #{@profile.full_name} was active for #{feat.progress} seconds"
      else
        @feats << "[#{feat.created_at}] #{@profile.full_name} received #{feat.progress} in type #{feat.progress_type}"
      end
      @feats.last << " on #{feat.level}" if !feat.level.nil?
    end
    
    return @feats
  end
  
  def list_outcomes(profile_id)
    @profile = Profile.find(profile_id)
    feat_list = Feat.where(game_id: self.id, profile_id: profile_id, progress_type: Feat.rating)
      
    outcome_list = {}
    
    feat_list.each do | feat |
      outcome = feat.outcome
      outcome_list[outcome] = [] unless outcome_list.include?(outcome)
      outcome_list[outcome] << feat
    end

    return outcome_list
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
