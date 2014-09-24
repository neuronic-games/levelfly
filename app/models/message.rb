require 'pusher'

class Message < ActiveRecord::Base
  extend MessageHelper
  belongs_to :profile
  belongs_to :parent, :polymorphic => true
  belongs_to :target, :polymorphic => true
  belongs_to :wall
  has_many :message_viewers

  after_create :push

  scope :invites, lambda {|type, profile_id, message_ids| where("message_type = ? AND parent_id = ? AND (archived is NULL or archived = ?) and id in(?)", type, profile_id, false, message_ids).order('created_at DESC')}
  scope :starred, :conditions => ['starred = ?', true]
  scope :active, :conditions => {:archived => [false, nil]}
  scope :involving, lambda {|profile_id| where('profile_id = ? or parent_id = ?', profile_id, profile_id)}
  scope :interesting, :conditions => ["(message_type = 'Message' and target_type = 'Profile' and parent_type = 'Profile') or parent_type = 'Message'"]
  scope :respond_to_course, lambda {|profile_id, message_ids|where("target_type in('Course','Notification') AND message_type = 'Message' AND parent_type='Profile' AND parent_id = ? AND archived = ? and id in(?)", profile_id ,false,message_ids).order('created_at DESC') }
  scope :school_invites, lambda { |message_ids| find(:all, :conditions => ["message_type = 'school_invite' AND (archived is NULL OR archived = ?) AND id IN (?)", false, message_ids], :order => "created_at DESC") }

  scope :between, (lambda do |ids, id2|
    snippets = ids.map do |id|
      "((parent_id = :other and profile_id = :current_user) or (parent_id = :current_user and profile_id = :other))".gsub(/:other/, "#{id}")
    end

    where(snippets.join(' or '), {:current_user => id2})
  end)

  def self.send_friend_request(profile_id,parent_id,wall_id,target_id)
    @message = Message.new
    @message.profile_id = profile_id
    @message.parent_id = parent_id
    @message.target_id = target_id
    @message.target_type = "Course"
    @message.parent_type = "Course"
    @message.message_type = "course_invite"
    @message.content = "I'd like to be your friend. Please accept my invite."
    @message.wall_id = Wall.get_wall_id(parent_id, "Course")
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    return @message
  end

  def self.send_course_request(profile_id, parent_id, wall_id, target_id,section_type,message_type,content)
    course = Course.find(target_id)
    @message = Message.new
    @message.profile_id = profile_id
    @message.parent_id = parent_id
    @message.target_id = target_id
    @message.target_type = section_type
    @message.parent_type = section_type
    @message.message_type = message_type
    @message.content = content
    @message.wall_id = wall_id#Wall.get_wall_id(parent_id, "Course")
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    MessageViewer.invites(profile_id, @message.id,parent_id)
    return @message
  end

  def self.send_school_invitations(user, sender)
    @message = Message.new
    @message.parent = @message.profile = sender
    @message.target = sender.school
    @message.message_type = 'school_invite'
    @message.content = "Please join #{sender.school.code} (#{sender.school.name})"
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save

    user.profiles.each do |profile|
      MessageViewer.create(
          :message_id => @message.id,
          :poster_profile_id => sender.id,
          :viewer_profile_id => profile.id,
          :archived => false,
          :viewed => false
      )
    end
  end

  def self.respond_to_course_invitation(parent_id,profile_id,target_id,content,section_type)
    course = Course.find(target_id)
    @message = Message.new
    @message.profile_id = parent_id
    @message.parent_id = profile_id
    @message.target_id = target_id
    # Needs the wall id for the recipient
    @message.target_type = section_type
    @message.parent_type = "Profile"
    @message.message_type = "Message"
    @message.content = content
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    MessageViewer.invites(parent_id, @message.id,profile_id)
    return @message
  end

  def formatted_content
    return self.content.gsub(/\n/, '<br/>').html_safe
  end

  def self.send_notification(current_user,content,profile_id)
    @message = Message.new
    @message.profile_id = current_user
    @message.parent_id = profile_id
    @message.target_type = "Notification"
    @message.parent_type = "Profile"
    @message.message_type = "Message"
    # @message.content = "Congratulation! You have achieved level #{level}"
    @message.content = content;
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    MessageViewer.invites(current_user, @message.id,profile_id)

  end

  def self.save_message(current_profile,parent,parent_type,content,message_type,course = nil)
    wall_id = Wall.get_wall_id(parent.id, parent_type)
    message = Message.new
    message.profile_id = current_profile.id
    message.parent_id = parent.id
    message.parent_type = parent_type
    message.content = content
    message.target_id = parent.id
    message.target_type = parent_type
    message.message_type = message_type
    message.wall_id = wall_id
    message.post_date = DateTime.now

    if message.save
      MessageViewer.add(current_profile.id,message.id,parent_type,parent.id)
      UserMailer.private_message(parent.user.email,current_profile,current_profile.school,content).deliver unless course
      UserMailer.course_private_message(parent.user.email,current_profile,current_profile.school,course,content).deliver if course
      feed = Feed.find(:first,:conditions=>["profile_id = ? and wall_id = ?",current_profile.id,wall_id])
      if feed.nil?
        Feed.create(:profile_id => current_profile.id,:wall_id =>wall_id)
      end
    end
  end

  def set_as_viewed(friend_id, profile_id)
    message_viewer =MessageViewer.find(:first, :conditions => ["(archived is NULL or archived = ?) AND message_id = ? AND poster_profile_id = ? AND viewer_profile_id = ?",false, id, friend_id, profile_id], :order => "created_at DESC")
    message_viewer.update_attribute("viewed",true) if message_viewer
    comments = Message.comment_list(id).collect(&:id)
    if comments
      comments.each do |comment_id|
        comment_message_viewer = MessageViewer.find(:first, :conditions => ["(archived is NULL or archived = ?) AND message_id = ? AND poster_profile_id = ? AND viewer_profile_id = ?",false,comment_id, friend_id, profile_id], :order => "created_at DESC")
        comment_message_viewer.update_attribute("viewed",true) if comment_message_viewer
      end
    end
  end

  def self.push_board_message(message_id)
    msg = find(message_id)

    ids = MessageViewer.where(message_id: message_id).map(&:viewer_profile_id) - [msg.profile_id]
    courseMaster = nil
    partial = 'message/pusher/message'
    channel = 'board_message'

    ids.each do |push_id|
      locals = {:message => msg, :course_id=> msg.profile_id, user_session_profile_id: push_id, course_master_of: courseMaster, chanel: channel}
      pusher_content = Message.get_view.render(partial: partial, :locals =>locals)
      Pusher.trigger_async("private-my-channel-#{push_id}", 'message', pusher_content)
      Pusher.trigger_async("private-my-channel-#{push_id}", 'new_message',{})
    end
  end

  def self.board_message?(message_id)
    message = find(message_id)
    message.message_type == Message.to_s and message.parent_type == '' and message.target_type == ''
  end

  def self.send_if_board_comment(message_id)
    msg = find(message_id)

    if msg.parent_type == Message.to_s and msg.message_type == Message.to_s
      parent = find(msg.parent_id)
      if parent.parent_type == '' and parent.target_type == ''
        ids = MessageViewer.where(message_id: parent.id).map(&:viewer_profile_id) - [msg.profile_id]
        partial = 'message/pusher/comment'
        channel = 'private_comment'
        ids.each do |push_id|
          locals = {:comment => msg, :course_id=> msg.profile_id, user_session_profile_id: push_id, chanel: channel}
          pusher_content = Message.get_view.render(partial: partial, :locals =>locals)
          Pusher.trigger_async("private-my-channel-#{push_id}", 'message', pusher_content)
          Pusher.trigger_async("private-my-channel-#{push_id}", 'new_message',{})
        end
      end
    end
  end

  def self.send_to_forum(message_id)
    msg = find(message_id)
    if msg.parent_type == 'F' and msg.message_type == Message.to_s and msg.target_type == 'F'
      ids = MessageViewer.where(message_id: message_id).map(&:viewer_profile_id) - [msg.profile_id]
      courseMaster = Profile.find(
          :first,
          :include => [:participants],
          :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", msg.parent_id]
      )
      partial = 'message/pusher/message'
      channel = 'forum_message'
      ids.each do |push_id|
        locals = {:message => msg, :course_id=> msg.profile_id, user_session_profile_id: push_id, course_master_of: courseMaster, chanel: channel}
        pusher_content = Message.get_view.render(partial: partial, :locals =>locals)
        Pusher.trigger_async("private-my-channel-#{push_id}", 'message', pusher_content)
      end
    elsif msg.parent_type == Message.to_s and msg.message_type == Message.to_s and msg.target_type == Message.to_s
      parent = find(msg.parent_id)
      if parent.parent_type == 'F' and parent.target_type == 'F'
        ids = MessageViewer.where(message_id: parent.id).map(&:viewer_profile_id) - [msg.profile_id]

        partial = 'message/pusher/comment'
        channel = 'private_comment'
        ids.each do |push_id|
          locals = {:comment => msg, :course_id=> msg.profile_id, user_session_profile_id: push_id, chanel: channel}
          pusher_content = Message.get_view.render(partial: partial, :locals =>locals)
          Pusher.trigger_async("private-my-channel-#{push_id}", 'message', pusher_content)
        end
      end
    end
  end

  private

  def push
    if parent_type == Message.to_s and message_type == Message.to_s
      push_comment()
    elsif parent_type == Profile.to_s and message_type == Message.to_s
      push_private_message()
    elsif parent_type == Profile.to_s and message_type == 'Friend'
      push_friend_request()
    elsif message_type == 'school_invite'
      push_school_request()
    elsif ['Course'].include?(target_type) and ['course_invite', 'group_invite'].include?(message_type) and parent_type == 'Course'
      push_course_request()
    elsif  ['C', 'G'].include?(parent_type) and message_type == Message.to_s and ['C', 'G'].include?(target_type)
      push_course_message()
    elsif parent_type == Profile.to_s and message_type == Message.to_s and target_type == 'Notification'
      push_notification()
    end
  end

  def push_course_message
    courseMaster = Profile.find(
        :first,
        :include => [:participants],
        :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", parent_id]
    )
    receivers = Profile.course_participants(parent_id, 'Course').map(&:id) + [courseMaster.id] - [profile_id]
    partial = 'message/pusher/message'
    channel = target_type == 'C' ? "course_message" : 'group_message'
    return if receivers.nil? or receivers.empty?
    receivers.each do |receiver_id|
      pusher_content = Message.get_view.render(partial: partial, :locals =>{
          :message => self,
          :course_id=> 0,
          user_session_profile_id: receiver_id,
          course_master: courseMaster,
          chanel: channel})
      Pusher.trigger_async("private-my-channel-#{receiver_id}", 'message', pusher_content)
    end
  end

  def push_notification
    receiver = parent_id

    partial = 'message/pusher/respond_to_course'
    channel = "notification"
    locals = {:request => self, :course_id=> profile_id, chanel: channel}

    pusher_content = Message.get_view.render(partial: partial, :locals =>locals)

    Pusher.trigger_async("private-my-channel-#{receiver}", 'message', pusher_content)
    Pusher.trigger_async("private-my-channel-#{receiver}", 'new_message',{})
  end

  def push_private_message
    msg = self
    receiver = msg.profile_id == profile_id ? msg.target_id : msg.profile_id
    friend = msg.profile_id == receiver ? msg.target_id : msg.profile_id
    courseMaster = nil #Profile.find(
    #    :first,
    #    :include => [:participants],
    #    :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", parent_id]
    #)
    partial = 'message/pusher/message'
    channel = "private_message"
    locals = {:message => self, :course_id=> friend, user_session_profile_id: receiver, course_master: courseMaster, chanel: channel}

    pusher_content = Message.get_view.render(partial: partial, :locals =>locals)

    Pusher.trigger_async("private-my-channel-#{receiver}", 'message', pusher_content)
    Pusher.trigger_async("private-my-channel-#{receiver}", 'new_message',{sender: profile_id})
  end

  def push_comment
    msg = Message.find(parent_id)
    receiver = msg.profile_id == profile_id ? msg.target_id : msg.profile_id
    return if ['', 'F'].include?(msg.parent_type) and ['', 'F'].include?(msg.target_type)
    friend = msg.profile_id == receiver ? msg.target_id : msg.profile_id

    partial = 'message/pusher/comment'
    channel = "private_comment"
    locals = {:comment => self, :course_id=> friend, user_session_profile_id: receiver, chanel: channel}

    pusher_content = Message.get_view.render(partial: partial, :locals =>locals)
    new_message_hash = {}
    new_message_hash = {sender: msg.profile_id} if msg.target_type == Profile.to_s
    Pusher.trigger_async("private-my-channel-#{receiver}", 'message', pusher_content)
    Pusher.trigger_async("private-my-channel-#{receiver}", 'new_message',new_message_hash)
  end

  def push_friend_request
    msg = self
    receiver = msg.profile_id == profile_id ? msg.target_id : msg.profile_id
    friend = msg.profile_id == receiver ? msg.target_id : msg.profile_id
    courseMaster = nil
    partial = 'message/pusher/friend_request'
    channel = "new_friend"
    locals = {:request => self, :course_id=> friend, chanel: channel}

    pusher_content = Message.get_view.render(partial: partial, :locals =>locals)

    Pusher.trigger_async("private-my-channel-#{receiver}", 'message', pusher_content)
    Pusher.trigger_async("private-my-channel-#{receiver}", 'new_message',{})

  end

  def push_school_request
    msg = self
    receiver = msg.profile_id == profile_id ? msg.target_id : msg.profile_id
    friend = msg.profile_id == receiver ? msg.target_id : msg.profile_id
    courseMaster = nil #Profile.find(
    #    :first,
    #    :include => [:participants],
    #    :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", parent_id]
    #)
    partial = 'message/pusher/friend_request'
    channel = "school_request"
    locals = {:request => self, :course_id=> friend, chanel: channel}

    pusher_content = Message.get_view.render(partial: partial, :locals =>locals)

    Pusher.trigger_async("private-my-channel-#{receiver}", 'message', pusher_content)
    Pusher.trigger_async("private-my-channel-#{receiver}", 'new_message',{})
  end

  def push_course_request

    receiver = parent_id

    partial = 'message/pusher/respond_to_course'
    channel = "course_request"
    locals = {:request => self, :course_id=> profile_id, chanel: channel}

    pusher_content = Message.get_view.render(partial: partial, :locals =>locals)

    Pusher.trigger_async("private-my-channel-#{receiver}", 'message', pusher_content)
    Pusher.trigger_async("private-my-channel-#{receiver}", 'new_message',{})
  end

  def self.get_view
    view = ActionView::Base.new('app/views', {}, ActionController::Base.new)
    view.extend(MessageHelper)
    return view
  end

end