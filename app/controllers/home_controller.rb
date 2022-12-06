class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @users_available = Recipe.for_user(current_user).all_available(current_user)
    @shared_available = Recipe.for_user(nil).all_available(current_user)

    @available_cocktails = @users_available + @shared_available
  end
end