class ShoppingListItemsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    @item = Reagent.find(params[:id])
    @list = @item.shopping_list

    @item.destroy if @item.present?

    respond_to do |format|
      format.html { redirect_to shopping_path(@list), alert: "#{@item.name} removed from list!" }
    end
  end
end