class HomeController < ApplicationController
  def index
    @available_cocktails = Cocktails.all_available
  end
end