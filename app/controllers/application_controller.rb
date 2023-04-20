class ApplicationController < ActionController::Base
  include Turbo::Redirection
  # Constants file?
  POSSIBLE_UNITS = ['oz', 'ml', 'tsp', 'tbsp', 'dash', 'cup', 'unknown']

  private

  def validate_admin!
    redirect_to '/' unless current_user.admin?
  end
end
