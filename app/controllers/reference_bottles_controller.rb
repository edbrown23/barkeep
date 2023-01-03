class ReferenceBottlesController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :new, :create, :destroy]
  before_action :validate_admin!, only: [:edit, :update, :new, :create, :destroy]

  def new
    @reference_bottle = ReferenceBottle.new
  end

  def create
    @reference_bottle = ReferenceBottle.new(change_params)

    respond_to do |format|
      if @reference_bottle.save
        format.html { redirect_to reagent_category_path(@reference_bottle.reagent_category) || reagent_categories_path, notice: "#{@reference_bottle.name} created!" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @reference_bottle = ReferenceBottle.find(params[:id])
  end

  def update
    @reference_bottle = ReferenceBottle.find(params[:id])
  end

  def destroy
    reference_bottle = ReferenceBottle.find(params[:id])
    reference_bottle.destroy if reference_bottle.present?

    respond_to do |format|
      format.html { redirect_to reagent_category_path(reference_bottle.reagent_category), alert: "#{reference_bottle.name} was destroyed" }
    end
  end

  private

  def change_params
    params
      .require(:reference_bottle)
        .permit(:name, :description, :main_image_url, :cost_reference, :reagent_category_id)
  end

  def reagent_category
    ReagentCategory.find_by(id: params[:reagent_category_id])
  end
end