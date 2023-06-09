class AuditsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_audit, only: [:show, :edit, :update]

  def index
    @audits = Audit.for_user(current_user).includes(:recipe).order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def update
    @audit.set_rating(update_params[:star_rating])
    @audit.set_notes(update_params[:notes])

    respond_to do |format|
      if @audit.save
        format.html { redirect_to audit_path(@audit), notice: 'Audit updated!' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def update_params
    params
      .require(:audit)
        .permit(:notes, :star_rating)
  end

  def set_audit
    @audit = Audit.for_user(current_user).find(params[:id])
  end
end