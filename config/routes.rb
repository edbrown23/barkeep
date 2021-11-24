Rails.application.routes.draw do
  root to: 'home#index'
  resources :recipes
  resources :reagents do
    post :refill
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get :cocktails, to: 'cocktails#show'
end
