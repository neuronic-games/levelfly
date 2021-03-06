require 'digest'

# Defines the playable games that show up under teh GameCenter
class Game < ActiveRecord::Base
  
  serialize :download_links, Hash
  PLATFORMS = ['ios', 'android', 'windows', 'mac', 'linux', 'guide']
  validates :handle, :uniqueness => true
  belongs_to :school  # This is the school of the game's creator's profile. If a new user sign up for Levelfly from the app,
                      # their account will be created in this school by default.
  has_many :feats
  has_many :game_score_leaders
  has_many :game_schools  # In addition to the main school, the same game can be used in other schools
  has_many :outcomes, :dependent => :destroy, :order => 'id'
  has_many :screen_shots, :dependent => :destroy
  belongs_to :course  # This is not an actual course. It uses the forums of a course as a support forum.
  belongs_to :profile
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
  
  def get_badge_count(profile_id, badge_id = nil)
    return self.feats.where(profile_id: profile_id, progress_type: Feat.badge, progress: badge_id).count if badge_id
    return self.feats.where(profile_id: profile_id, progress_type: Feat.badge).count
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
  
  # Returns the list of learning outcomes
  def get_outcomes()
    rewards = []
    outcomes = Outcome.where(game_id: self.id).order(:id)
    outcomes.each do |outcome|
      rewards << outcome.name
    end
    return rewards
  end

  # Returns the list of badges
  def get_badges()
    rewards = []
    badges = Badge.where(quest_id: self.id, archived: false).order(:name)
    badges.each do |badge|
      rewards << badge.name
    end
    return rewards
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
  
  def list_outcome_ratings(profile_id)
    @profile = Profile.find(profile_id)
    feat_list = Feat.where(game_id: self.id, profile_id: profile_id, progress_type: Feat.rating)
      
    outcome_list = {}
    outcome_total_grade = {}
    outcome_feat_count = {}

    self.outcomes.each do |outcome|
      outcome_list[outcome] = 0 if outcome.name.present?
    end
    
    feat_list.each do | feat |
      outcome = feat.outcome
      if !outcome_total_grade.include?(outcome)
        outcome_total_grade[outcome] = 0.0
        outcome_feat_count[outcome] = 0
      end

      outcome_total_grade[outcome] += feat.outcome_feat.rating
      outcome_feat_count[outcome] += 1
    end

    outcome_total_grade.each do | outcome, total_rating |
      outcome_list[outcome] = total_rating / outcome_feat_count[outcome]
    end

    return outcome_list
  end
  
  # Show login time, time spent, score per login session. This is meant to be a memory efficient routine.
  def list_sessions_to_csv

    user_csv = CSV.generate do |csv|
    
      row = []

      row << "Player ID"
      row << "Player"
      row << "Login"
      row << "Score"
      row << "Duration (sec)"
    
      csv << row

      login_list = {}
      score_list = {}
      
      # Process in batches for efficiency
      Feat.where(game_id: self.id).find_each do |feat|
        # A player's activity starts with a login...
        if feat.progress_type == Feat.login
          login_list[feat.profile_id] = feat.created_at
        elsif feat.progress_type == Feat.score
          # The latest score record is always assumed to be your accumulative score for the game
          score_list[feat.profile_id] = feat.progress
        elsif feat.progress_type == Feat.duration
          # and ends with a logout with a duration record
          
          # read and delete the records to conserve memory
          created_at = login_list.delete(feat.profile_id)
          score = score_list.delete(feat.profile_id)
          if created_at.present?
            profile = feat.profile
            row = []
          
            row << profile.id
            row << profile.full_name
            row << Setting.default_date_time_format(created_at)
            row << (score.present? ? score : '-')
            row << feat.progress

            csv << row
          end
        end
      end
    end

    return user_csv
  end
  
  # Count the number of active players from the number of unique people that have logged in
  def update_player_count
    self.player_count = Feat.where(game_id: self.id, progress_type: Feat.login).select(:profile_id).count(distinct: true)
    save
  end

  # Update player count or all games
  def self.update_player_count
    games = Game.all
    games.each do |game|
      game.update_player_count
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
