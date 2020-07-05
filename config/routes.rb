# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :discussions do
  resources :answers, except: [:new, :index, :show]
end


