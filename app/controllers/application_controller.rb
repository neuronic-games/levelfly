class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_current_profile

  # before_filter :prepare_for_mobile
  include ApplicationHelper

  # Search people by email or name
  def search_participants
    if params[:school_id] && !params[:school_id].empty?
      search_text = "#{params[:search_text]}%"
      valueFind = false
      if is_a_valid_email(search_text)

        @user = User.where(['email = ?', params[:search_text]])
        if @user.empty?
          render partial: 'shared/send_email', locals: { search_text: params[:search_text].to_s }
        else
          @peoples = Profile.where(['user_id != ? AND school_id = ? AND user_id = ?', current_user.id,
                                    params[:school_id], @user.first.id])
          if @peoples.empty?
            render text: 'you cant add yourself'
          else
            valueFind = true
          end
        end
      else
        @peoples = Profile.where(['user_id != ? AND school_id = ? AND (name LIKE ? OR full_name LIKE ?)',
                                  current_user.id, params[:school_id], search_text, search_text])
        if @peoples.empty?
          render text: 'No match found'
        else
          valueFind = true
        end
      end
      render partial: 'shared/participant_list', locals: { peoples: @peoples, mode: 'result' } if valueFind
    else
      render text: 'Error: Parameters missing !!'
    end
  end

  private

  def set_current_profile
    if current_user
      profile = Profile.create_for_user(current_user.id, school.id)
      publish_profile(profile)
      if current_user.status == 'S'
        flash[:message] = 'Your account has been suspended.'
        sign_out current_user
      end
      # elsif current_user
      #   puts "=== user_session[:profile_id] = #{user_session[:profile_id]}"
      #   puts "=== current_user.id = #{current_user.id}"
      #   profile = Profile.create_for_user(current_user.id)
      #   puts "=== profile.id = #{profile.id}"
    end
  end

  def publish_profile(profile)
    user_session[:profile_id] = profile.id
    session[:school_id] = profile.school_id
    @profile = profile
  end

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == '1'
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end

  # Allow the user to go directly to a details page that they were working on before
  def redirect_to_last_action(profile, action_type, action_path)
    # Temporarily disabled
    profile.record_action('last', action_type)
    return false

    # Check to see if we have any info on this action
    last_action = profile.last_action('last')
    if last_action and last_action.action_param == action_type
      profile.record_action('last', action_type)
    else
      # The last page that were viewing was not a course page, so show the
      # last course page viewed instead of the course list
      action = profile.last_action(action_type)
      if action
        # This is the course that we were viewing before
        redirect_to "#{action_path}/#{action.action_param}"
        return true
      end
    end
    false
  end

  def after_sign_out_path_for(_resource_or_scope)
    session[:slug].blank? ? new_user_session_path : new_user_session_path + '/' + school.handle
  end

  def after_sign_in_path_for(_resource)
    root_path
  end

  # def set_aws_vault(vault)
  #   ENV['S3_KEY']  = vault.account
  #   ENV['S3_SECR'] = vault.secret
  #   ENV['S3_BUCK'] = vault.folder
  # end
end
