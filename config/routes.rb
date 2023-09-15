Rails.application.routes.draw do
  namespace :admin do
    resources :users
    resources :audits
    resources :reagents
    resources :reagent_amounts
    resources :reagent_categories
    resources :recipes
    resources :reference_bottles
    resources :cocktail_families

    root to: "users#index"
  end
  devise_for :users
  root to: 'home#index'
  resources :recipes
  resources :reagents do
    post :refill
    post :empty
    get :add_to_list, to: 'reagents#shopping_list_show'
  end
  resources :bulk_reagents, only: [:index, :create]

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :cocktails do
    post :delete
    get :pre_make_drink
    post :make_drink
    post :toggle_favorite
    post :propose_to_share
    post :make_permanent
  end

  resources :cocktail_families, only: [:show, :create, :update]

  resources :drink_making, only: [:show, :update] do
  end

  # TODO: rename these routes
  scope :cocktails_async do
    get :drink_builder, to: 'cocktails#drink_builder'
  end

  resources :shared_cocktails, only: [:index, :show, :destroy] do
    post :add_to_account
    post :promote_to_shared
  end

  resources :shopping, only: [:index, :show, :new, :create, :destroy, :edit] do
    get :list
    post :purchase
    patch :list, to: 'shopping#update'
  end
  scope :shopping do
    put :add_to_list, to: 'shopping#add_to_list'
  end

  resources :audits, only: [:index, :show, :update, :destroy]

  resources :reagent_categories, only: [:index, :show, :edit, :update, :new, :create]

  resources :reference_bottles, only: [:new, :create, :edit, :update, :destroy]
end
