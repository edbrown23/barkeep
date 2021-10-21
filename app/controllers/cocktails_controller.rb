class CocktailsController < ApplicationController
  def show
    @cocktails = Cocktails.all_available

    respond_to do |format|
      format.html { render :show }
      format.json { render json: {hi: 'there'}, status: :ok }
    end
  end
end