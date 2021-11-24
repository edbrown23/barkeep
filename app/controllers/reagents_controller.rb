class ReagentsController < ApplicationController
  before_action :set_reagent, only: [:show, :edit, :update, :destroy]

  def index
    search_term = search_params['search_term']

    if search_term.present? && search_term.size > 0
      @reagents = Reagent.where('name ILIKE ?', "%#{search_term}%").order(:id)
    else
      @reagents = Reagent.all.order(:id)
    end
  end

  def new
    @reagent = Reagent.new
  end

  def show
  end

  def edit
  end

  def refill
    # I don't know why this route sends the id as "reagent_id" instead of "id". probably some nested route magic
    reagent = Reagent.find_by(id: params['reagent_id'])
    reagent.update!(current_volume_percentage: 100.0) if reagent.present?
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
          .permit(:name, :cost, :purchase_location, :max_volume, :current_volume_percentage)
    end

    def search_params
      params.permit(:search_term)
    end
end