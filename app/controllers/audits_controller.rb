class AuditsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_audit, only: [:show, :edit, :update]

  def index
    @filtered_to = nil
    initial_scope = Audit.for_user(current_user).includes(:recipe)
    if filter_params[:recipe_id].present?
      initial_scope = initial_scope.where(recipe_id: filter_params[:recipe_id])
      @filtered_to = Recipe.find(filter_params[:recipe_id])
    end

    @audits = initial_scope.order(created_at: :desc).page(params[:page])
    @counts = initial_scope.group(:recipe).order(count: :desc).count
    # I'm bad at MVC. Should this be a method on the model?
    raw_ratings = ActiveRecord::Base.connection.execute(
      "select recipe_id, max((info->'rating'->>'star_count')::bigint) from audits where user_id = #{current_user.id} group by recipe_id;"
    )
    @ratings = raw_ratings.index_by { |r| r['recipe_id'] }
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

  def filter_params
    params.permit(:recipe_id)
  end
end