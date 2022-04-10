class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @available_cocktails = Recipe.for_user(current_user).all_available
  end
end