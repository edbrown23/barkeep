class ReagentsController < ApplicationController
  before_action :set_reagent, only: [:show, :edit, :update, :destroy]

  def index
    @reagents = Reagent.all
  end

  def new
    @reagent = Reagent.new
  end

  def show
  end

  def edit
  end

  def create
    @reagent = Reagent.new(reagent_params)

    respond_to do |format|
      if @reagent.save
        # TODO: handle the notice
        format.html { redirect_to @reagent, notice: "#{@reagent.name} was successfully created" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @reagent.update(reagent_params)
        # TODO: handle the notice
        format.html { redirect_to @reagent, notice: "#{@reagent.name} was successfully updated" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_reagent
      # TODO: handle 404
      @reagent = Reagent.find(params[:id])
    end

    def reagent_params
      # I bet we could pull this from the model, that would be cool
      params
        .require(:reagent)
        .permit(:name)
        .permit(:cost)
        .permit(:purchase_location)
        .permit(:max_volume)
        .permit(:current_volume_percentage)
    end
end