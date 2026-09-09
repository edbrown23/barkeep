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
    post :delete, to: "cocktails#destroy", defaults: { deletion_scope: "owned" }
    post :toggle_favorite
    post :add_to_account
    post :promote_to_shared
    post :propose_to_share
    post :make_permanent
    get :nearest_neighbors
  end

  resources :cocktail_families, only: [:show, :create, :update]

  resources :drink_making, only: [:show, :update] do
  end

  # TODO: rename these routes
  scope :cocktails_async do
    get :drink_builder, to: 'cocktails#drink_builder'
  end

  # Compatibility for bookmarked pages and older clients. New links use /cocktails.
  get '/shared_cocktails', to: redirect(status: 302) { |_params, request|
    query = request.query_parameters.slice('search_term', 'search_tags', 'makeable', 'page', 'family_ids')
    "/cocktails?#{query.merge('ownership' => 'shared').to_query}"
  }, as: :shared_cocktails
  get '/shared_cocktails/:id', to: redirect('/cocktails/%{id}', status: 302), as: :shared_cocktail
  post '/shared_cocktails/:shared_cocktail_id/add_to_account', to: 'cocktails#add_to_account', as: :shared_cocktail_add_to_account
  post '/shared_cocktails/:shared_cocktail_id/promote_to_shared', to: 'cocktails#promote_to_shared', as: :shared_cocktail_promote_to_shared
  delete '/shared_cocktails/:id', to: 'cocktails#destroy', defaults: { deletion_scope: 'shared' }

  resources :shopping, only: [:index, :show, :new, :create, :destroy, :edit] do
    get :list
    post :purchase
    patch :list, to: 'shopping#update'
  end
  scope :shopping do
    put :add_to_list, to: 'shopping#add_to_list'
  end

  resources :shopping_list_items, only: [:destroy]

  resources :audits, only: [:index, :show, :update, :destroy]

  resources :reagent_categories, only: [:index, :show, :edit, :update, :new, :create]

  resources :reference_bottles, only: [:new, :create, :edit, :update, :destroy]
end
