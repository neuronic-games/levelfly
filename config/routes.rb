Oncapus::Application.routes.draw do

  devise_for :users, :controllers => {:registrations => "registrations"}
  
  #devise_for :users
   #devise_for :users, :controllers  => {
             # :registrations => 'registrations',
             # :sessions => 'sessions'
           # }
  
  resources :users
  
  get "system/alert"
  
  get "system/new_user"
  
  post "system/edit"

  post "task/view_task"#for get task related to course
  
  get "task/view_task"
  
  get "task/list"
  
  get "task/view_setup"
   
  get "profile/index"

  get "profile/show"
  
  get "profile/show_avatar"

  get "profile/edit"

  get "profile/save"
  
  post "profile/save"

  post "profile/save_meta"
  
  post "profile/save_notes"
  
  get "profile/accept_code"
  
  get "profile/user_profile"

  get "profile/edit_wardrobe"

  get "profile/validate_code"
  
  get "profile/change_major"
  
  get "profile/change_name"

  get "profile/list_major"
  
  post "profile/change_password"
  
  post "profile/account_setup"
  
  get "task/index"

  get "task/show"
  
  get "task/new"
  
  get "task/edit"

  get "task/save" 
  
  post "task/check_priorities"

  post "task/toggle_priority"
  
  post "task/save"
  
  post "task/outcome_unchecked"
  
  post "task/member_unchecked"
  
  post "task/all_members_checked"
  
  post "task/task_complete"
  
  post "task/remove_tasks"
  
  post "task/get_task"
  
  get "task/upload_resource"
  
  post "task/upload_resource"
  
  get "task/course_peoples"
  
  get "task/course_categories"
  
  get "task/course_outcomes"
  
  get "task/remove_attachment"
  
  get "task/duplicate"
  
  post "task/points_credit"
  
  post "task/extra_credit"
  
  post "task/remove_task"
  
  get "friend/index"
  
  get "course/index"
  
  get "course/new"

  get "course/show"
  
  post "course/show_course"
  
  post "course/set_archive"
   
  post "course/toggle_priority_file"
  
  post "course/toggle_priority_message"

  get "course/view_member"
  
  post "course/course_stats"
  
  post "course/top_achivers"
  
  get "course/view_setup"
  
  post "course/check_outcomes"

  get "course/edit"

  get "course/save"
  
  post "course/add_file"
  
  post "course/send_group_invitation"
  
  get "course/add_file"
  
  get "course/view_group_setup"
  
  post "course/save"
  
  post "course/group_joinning"
  
  post "course/group_viewing"
  
  post "course/remove_course_outcomes"
  
  post "course/remove_course_files"
  
  post "course/remove_course_categories"
  
  post "course/update_course_outcomes"
  
  post "course/update_course_categories"
  
  post "course/get_participants"
  
  post "course/send_email"
  
  post "course/add_participant"
  
  post "course/delete_participant"
  
  post "course/filter" 
  
  post "course/share_outcome"
  
  post "course/download"
  
  post "course/load_files"
  
  post "course/removed"
  
  post "course/forum_member_unchecked"
  
  get "group/index"
  
  get "group/new"
  
  post "group/save"

  get "group/show"

  get "group/create"
  
  post "group/create"
  
  get "group/view_setup"
  
  post "group/show_group"
  
  post "group/get_participants"
  
  post "group/add_participant"
  
  post "group/delete_participant"
  
  get "grade_book/index"
  
  get "leader_board/index"
  
  post "leader_board/show_user_profile"

  get "leader_board/get_rows"
  
  post "grade_book/get_task"
  
  post "grade_book/load_notes"
  
  post "grade_book/save_notes"
  
  post "grade_book/course_outcomes"
  
  post "grade_book/load_outcomes"
  
  post "grade_book/grade_calculate"
  
  post "grade_book/outcomes_points"
  
  post "grade_book/grading_complete"
  
  post "grade_book/task_setup"
  
  post "grade_book/load_task_setup"
  
  post "grade_book/filter"
  
  get "wardrobe/index"
  
  get "wardrobe/new"

  get "wardrobe/show"

  get "wardrobe/edit"

  get "wardrobe/save"
  
  post "wardrobe/save"
  
  get "wardrobe/load_wardrobe_items"
  
  post "wardrobe/save_sort_order"
  
  post "wardrobe/upload_wardrobe_image"
  
  get "message/index"
  # start  added for new message funtionalites >>>  lmit>>> frinds messages
  get "message/show_all"
  
  get "message/friends_only"
  
  get "message/friends_only_all"
  
  post "message/remove_request_message"
  
  # end  added for new message funtionalites >>>  lmit>>> frinds messages
  
  post "message/save"
  
  post "message/like"
  
  post "message/unlike"
  
  post "message/add_friend_card"
  
  post "message/respond_to_friend_request"
  
  post "message/respond_to_course_request"
  
  post "message/add_note"
  
  post "message/notes"
  
  post "message/check_request"
  
  post "message/check_messages"
  
  post "message/unfriend"
  
  post "message/delete_message"
  
  post "message/confirm"
  
  post "message/save_topic"
  
  post "badge/give_badges"
  
  post "badge/save"
  
  post "badge/new_badges"
  
  post "badge/give_badge_to_student"
  
  post "badge/delete_badge"
  
  post "badge/warning_box"
  
  post "badge/badge_detail"
  
  get "users/index"
  
  get "users/show"
  
  post "users/save"
  
  get "users/new"
  
  get "reward/new"
  
  get "reward/show"
  
  post "reward/save"
  
  post "reward/delete/"
  
  get "setting/new"
  
  get "setting/show"
  
  post "setting/save"
  
  post "setting/delete/"
  
  get "course/show_forum"  

  get "course/new_forum"
  
  post "course/save_forum"
  
  post "course/view_forum_setup"
  
  
  match 'reward' => 'reward#index'

  match 'csv' => 'grade_book#export_csv', :as => 'csv'
  
  match 'task' => 'task#index'
  
  match 'grade_book' => 'grade_book#index'
  
  match 'leader_board' => 'leader_board#index'
    
  match 'main' => 'course#index'
  
  match 'course' => 'course#index'
  
  match 'group' => 'group#index'
  
  match 'wardrobe' => 'wardrobe#index'
  
  match 'message' => 'message#index'
  
  match 'friend' => 'friend#index'
  
  match 'users' => 'users#index'
  
  match 'setting' => 'setting#index'
  
  # start added for new message funtionalites >>>  lmit>>> frinds messages
  match 'message/friends_only/:friend_id' => 'message#friends_only'
  
   # start added for new notes funtionalites >>>  lmit>>> frinds messages
  match 'message/notes/:friend_id' => 'message#notes'
  
  
  match 'message/friends_only_all/:friend_id' => 'message#friends_only_all'
  
  # end  added for new message funtionalites >>>  lmit>>> frinds messages
  
  match 'course/show/:id' => 'course#show'
  
  match 'task/show/:id' => 'task#show'
  
  match 'users/show/:id' => 'users#show'
  
  match 'group/show/:id' => 'group#show'
  
  match 'reward/show/:id' => 'reward#show'
  
  match 'setting/show/:id' => 'setting#show' 
  
  match 'course/show_forum/:id' => 'course#show_forum'
  
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
  root :to => 'task#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
