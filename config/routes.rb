Rails.application.routes.draw do
  resources :recipes
  resources :reagents
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get :cocktails, to: 'cocktails#show'
end
