class ApplicationController < ActionController::Base
  include Turbo::Redirection
  # Constants file?
  POSSIBLE_UNITS = ['oz', 'ml', 'tsp', 'tbsp', 'dash', 'cup', 'unknown']
  # so dumb to do it this way. bottles want to be ml first, drinks want to be oz first
  POSSIBLE_UNITS_ML = ['ml', 'oz', 'tsp', 'tbsp', 'dash', 'cup', 'unknown']

  private

  def validate_admin!
    redirect_to '/' unless current_user.admin?
  end
end
