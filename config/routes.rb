Oncapus::Application.routes.draw do
  # devise_for :users, :controllers => {:registrations => "registrations", :sessions => "sessions", :confirmations => "confirmations"}
  # devise_scope :users do
  #   match '/users/sign_in/:slug' => 'sessions#new'
  #   match '/confirm/:confirmation_token', :controller => 'confirmations', :action => 'show', :as => 'confirmation'
  #   match '/confirm', :controller => 'confirmations', :action => 'new', :as => 'new_confirmation'
  # end
  devise_for :users, controllers: {
    registrations: 'registrations',
    sessions: 'sessions'
  }
  devise_scope :user do
    match '/users/sign_in/:slug' => 'sessions#new', :via => %i[get post]
    resource :confirmation,
             only: %i[show new],
             path: 'confirm',
             controller: 'confirmations'
  end

  post 'auth' => 'profile#auth'
  get 'message/read_message' => 'message#read_message'
  # devise_for :users
  # devise_for :users, :controllers  => {
  # :registrations => 'registrations',
  # :sessions => 'sessions'
  # }

  resources :users do
    collection do
      get 'load_permissions',     action: 'load_permissions'
      get 'load_users/:id/:page', action: 'load_users', as: 'load_users'
      get 'load_user_emails/:id', action: 'load_user_emails', as: 'load_user_emails'
      post 'set_invite_codes', action: 'set_invite_codes'
      get 'load_csv/:id', action: 'load_csv', as: 'load_csv'
    end
  end

  get 'system/alert'

  get 'system/new_user'

  post 'system/edit'

  post 'task/view_task' # for get task related to course

  get 'task/view_task'

  get 'task/list'

  get 'task/view_setup'

  get 'profile/index'

  get 'profile/show'

  get 'profile/show_avatar'

  get 'profile/edit'

  get 'profile/save'

  post 'profile/save'

  post 'profile/save_meta'

  post 'profile/save_notes'

  get 'profile/accept_code'

  get 'profile/user_profile'

  get 'profile/edit_wardrobe'

  get 'profile/validate_code'

  get 'profile/change_major'

  get 'profile/change_name'

  get 'profile/list_major'

  post 'profile/change_password'

  post 'profile/account_setup'

  post 'profile/show_comments'

  post 'profile/update_show_date'

  post 'profile/change_school'

  post 'profile/check_email'

  post 'profile/change_extended_logout_preference'

  post 'profile/save_privacy_settings'

  get 'task/index'

  get 'task/show'

  get 'task/new'

  get 'task/edit'

  get 'task/save'

  post 'task/check_priorities'

  post 'task/toggle_priority'

  post 'task/save'

  post 'task/outcome_unchecked'

  post 'task/member_unchecked'

  post 'task/all_members_checked'

  post 'task/task_complete'

  post 'task/remove_tasks'

  post 'task/get_task'

  get 'task/upload_resource'

  post 'task/upload_resource'

  get 'task/course_peoples'

  get 'task/course_categories'

  get 'task/course_outcomes'

  get 'task/remove_attachment'

  get 'task/duplicate'

  post 'task/points_credit'

  post 'task/extra_credit'

  post 'task/remove_task'

  get 'friend/index'

  get 'course/index'

  get 'course/new'

  get 'course/show'

  post 'course/show_course'

  post 'course/set_archive'

  post 'course/toggle_priority_file'

  post 'course/toggle_priority_message'

  get 'course/view_member'

  post 'course/course_stats'

  post 'course/top_achivers'

  post 'course/task_outcomes'

  get 'course/view_setup'

  get 'course/edit'

  get 'course/save'

  post 'course/add_file'

  post 'course/send_group_invitation'

  get 'course/add_file'

  get 'course/view_group_setup'

  post 'course/save'

  post 'course/group_joinning'

  post 'course/group_viewing'

  post 'course/remove_course_outcomes'

  post 'course/remove_course_files'

  post 'course/remove_course_categories'

  post 'course/update_course_outcomes'

  post 'course/update_course_categories'

  # TODO: This seems to just return data, should it be a `get`?
  post 'course/get_participants'

  post 'course/send_email'

  post 'course/add_participant'

  post 'course/delete_participant'

  # TODO: This seems to just return data, should it be a `get`?
  post 'course/filter'

  post 'course/share_outcome'

  post 'course/download'

  post 'course/load_files'

  post 'course/removed'

  post 'course/forum_member_unchecked'

  post 'course/send_email_to_all_participants'

  post 'course/duplicate'

  post 'users/send_message_to_all_users'

  get 'group/index'

  get 'group/new'

  post 'group/save'

  get 'group/show'

  get 'group/create'

  post 'group/create'

  get 'group/view_setup'

  post 'group/show_group'

  post 'group/get_participants'

  post 'group/add_participant'

  post 'group/delete_participant'

  get 'grade_book/index'

  get 'leader_board/index'

  post 'leader_board/show_user_profile'

  get 'leader_board/get_rows'

  post 'grade_book/get_task'

  post 'grade_book/load_notes'

  post 'grade_book/load_achievements'

  post 'grade_book/save_notes'

  post 'grade_book/course_outcomes'

  post 'grade_book/show_outcomes'

  post 'grade_book/load_outcomes'

  post 'grade_book/grade_calculate'

  post 'grade_book/outcomes_points'

  post 'grade_book/grading_complete'

  post 'grade_book/task_setup'

  post 'grade_book/load_task_setup'

  # TODO: This seems to just return data, should it be a `get`?
  post 'grade_book/filter'

  get 'wardrobe/index'

  get 'wardrobe/new'

  get 'wardrobe/show'

  get 'wardrobe/edit'

  get 'wardrobe/save'

  post 'wardrobe/save'

  get 'wardrobe/load_wardrobe_items'

  post 'wardrobe/save_sort_order'

  post 'wardrobe/upload_wardrobe_image'

  get 'message/index'
  # start  added for new message funtionalites >>>  lmit>>> frinds messages
  get 'message/show_all'

  get 'message/friends_only'

  get 'message/friends_only_all'

  post 'message/remove_request_message'

  # end  added for new message funtionalites >>>  lmit>>> frinds messages

  post 'message/save'

  post 'message/like'

  post 'message/unlike'

  get 'message/alert_badge'

  post 'message/add_friend_card'

  post 'message/respond_to_friend_request'

  post 'message/respond_to_course_request'

  post 'message/add_note'

  post 'message/notes'

  post 'message/check_request'

  post 'message/check_messages'

  post 'message/unfriend'

  post 'message/delete_message'

  post 'message/confirm'

  post 'message/save_topic'

  post 'badge/give_badges'

  post 'badge/save'

  post 'badge/new_badges'

  post 'badge/give_badge_to_student'

  post 'badge/delete_badge'

  post 'badge/warning_box'

  post 'badge/badge_detail'

  get 'users/index'

  get 'users/show'

  post 'users/save'

  post 'users/login_as'

  post 'users/remove'

  get 'users/new'

  get 'reward/new'

  get 'reward/show'

  post 'reward/save'

  post 'reward/delete'

  get 'setting/new'

  get 'setting/show'

  post 'setting/save'

  post 'setting/delete'

  get 'course/show_forum'

  get 'course/new_forum'

  post 'course/save_forum'

  post 'course/view_forum_setup'

  match 'reward' => 'reward#index', :via => %i[get post]

  match 'export_course_grade_csv/:course_id' => 'grade_book#export_course_grade_csv', :as => 'grade_csv',
        :via => %i[get post]
  match 'export_course_sectioned_csv/:course_id' => 'grade_book#export_course_sectioned_csv', :as => 'sectioned_csv',
        :via => %i[get post]
  match 'export_game_csv/:game_id' => 'gamecenter#export_game_csv', :via => %i[get post]
  match 'export_game_activity_csv/:game_id' => 'gamecenter#export_game_activity_csv', :via => %i[get post]

  match 'profile' => 'profile#index', :via => %i[get post]

  match 'task' => 'task#index', :via => %i[get post]

  match 'grade_book' => 'grade_book#index', :via => %i[get post]

  match 'leader_board' => 'leader_board#index', :via => %i[get post]

  match 'main' => 'course#index', :via => %i[get post]

  match 'course' => 'course#index', :via => %i[get post]

  match 'group' => 'group#index', :via => %i[get post]

  match 'wardrobe' => 'wardrobe#index', :via => %i[get post]

  match 'message' => 'message#index', :via => %i[get post]

  match 'friend' => 'friend#index', :via => %i[get post]

  match 'users' => 'users#index', :via => %i[get post]

  match 'setting' => 'setting#index', :via => %i[get post]

  # start added for new message funtionalites >>>  lmit>>> frinds messages
  match 'message/friends_only/:friend_id' => 'message#friends_only', :via => %i[get post]

  # start added for new notes funtionalites >>>  lmit>>> frinds messages
  match 'message/notes/:friend_id' => 'message#notes', :via => %i[get post]

  match 'message/friends_only_all/:friend_id' => 'message#friends_only_all', :via => %i[get post]

  # end  added for new message funtionalites >>>  lmit>>> frinds messages

  match 'course/show/:id' => 'course#show', :via => %i[get post]

  match 'task/show/:id' => 'task#show', :via => %i[get post]

  match 'users/show/:id' => 'users#show', :via => %i[get post]

  match 'group/show/:id' => 'group#show', :via => %i[get post]

  match 'reward/show/:id' => 'reward#show', :via => %i[get post]

  match 'setting/show/:id' => 'setting#show', :via => %i[get post]

  match 'course/show_forum/:id' => 'course#show_forum', :via => %i[get post]

  match 'course/export_activity_csv/:id' => 'course#export_activity_csv', :via => %i[get post]

  # Game Center API

  match 'gamecenter' => 'gamecenter#index', :via => %i[get post]
  match 'games/:id' => 'gamecenter#show', :via => %i[get post]

  # TODO: Great code-golf possibilities here. The context is replacing this line, which relies on behaviour removed in Rails 5.2:
  # get 'gamecenter/:handle/:action' => 'gamecenter#:action'

  get 'gamecenter/:handle/authenticate' => 'gamecenter#authenticate'
  get 'gamecenter/:handle/connect' => 'gamecenter#connect'
  get 'gamecenter/:handle/get_current_user' => 'gamecenter#get_current_user'
  get 'gamecenter/:handle/get_current_dur' => 'gamecenter#get_current_dur'
  get 'gamecenter/:handle/get_top_users' => 'gamecenter#get_top_users'
  get 'gamecenter/:handle/get_rewards' => 'gamecenter#get_rewards'
  get 'gamecenter/:handle/add_checkpoint' => 'gamecenter#add_checkpoint'
  get 'gamecenter/:handle/get_checkpoint' => 'gamecenter#get_checkpoint'
  get 'gamecenter/:handle/add_progress' => 'gamecenter#add_progress'
  get 'gamecenter/:handle/add_game_badge' => 'gamecenter#add_game_badge'
  get 'gamecenter/:handle/list_leaders' => 'gamecenter#list_leaders'
  get 'gamecenter/:handle/list_progress' => 'gamecenter#list_progress'


  get 'gamecenter/status'
  get 'gamecenter/connect'
  get 'gamecenter/get_rows'
  get 'gamecenter/add_game'
  post 'gamecenter/save_game'
  get 'gamecenter/view_game'
  get 'gamecenter/edit_game'
  put 'gamecenter/update_game'
  patch 'gamecenter/update_game'
  get 'gamecenter/view_game_stats'
  get 'gamecenter/download'
  get 'gamecenter/support'
  get 'gamecenter/all_badges'
  get 'gamecenter/achivements'
  get 'gamecenter/leaderboard'
  get 'gamecenter/get_active_dur'
  get 'gamecenter/get_top_users'
  get 'gamecenter/get_rewards'
  get 'gamecenter/add_badge'
  get 'gamecenter/edit_badge'
  post 'gamecenter/save_badge'
  get 'people/load_filtered_courses' => 'users#load_filtered_courses'
  get 'people/load_course_codes' => 'users#load_course_codes'
  get 'gamecenter/game_details'
  get 'gamecenter/add_checkpoint'
  get 'gamecenter/get_checkpoint'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root to: 'course#index'
  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
