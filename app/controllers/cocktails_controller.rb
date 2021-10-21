class CocktailsController < ApplicationController
  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render json: {hi: 'there'}, status: :ok }
    end
  end
end