class ReagentsController < ApplicationController

  def index
    @reagents = Reagent.all
  end
end