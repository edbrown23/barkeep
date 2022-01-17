class AuditsController < ApplicationController
  def index
    @audits = Audit.all.order(created_at: :desc)
  end

  def show
    @audit = Audit.find(params[:id])
  end
end