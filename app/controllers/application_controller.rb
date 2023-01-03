class ApplicationController < ActionController::Base
  private

  def validate_admin!
    redirect_to '/' unless current_user.admin?
  end
end
