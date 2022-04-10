class AuditsController < ApplicationController
  before_action :authenticate_user!

  def index
    @audits = Audit.for_user(current_user).all.order(created_at: :desc)
  end

  def show
    @audit = Audit.for_user(current_user).find(params[:id])
  end
end