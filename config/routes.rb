Rails.application.routes.draw do
  devise_for :users
  root to: 'home#index'
  resources :recipes
  resources :reagents do
    post :refill
  end
  resources :bulk_reagents, only: [:index, :create]

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :cocktails do
    post :delete
    post :make_drink
    post :toggle_favorite
  end

  scope :cocktails_async do
    get :available_counts, to: 'cocktails#available_counts'
  end

  resources :shared_cocktails, only: [:index, :show] do
    post :add_to_account
  end

  scope :shared_cocktails_async do
    get :available_counts, to: 'shared_cocktails#available_counts'
  end

  resources :shopping, only: [:index]

  resources :audits, only: [:index, :show]

  resources :reagent_categories, only: [:index, :show, :edit, :update, :new, :create]
end
