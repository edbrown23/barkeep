class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @available_cocktails = Cocktails.all_available
  end
end