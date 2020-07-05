# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
resources :projects do
  resources :discussions do
    resources :answers, except: [:new, :index, :show]
  end
end


