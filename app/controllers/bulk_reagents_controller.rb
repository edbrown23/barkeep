class BulkReagentsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  # TODO: add an upsert mode
  def create
    importer = BulkReagentService.new(current_user)

    mode = params[:mode]

    if mode == 'Insert'
      errors = importer.insert(upload_params[:user_reagents])
    elsif mode == 'Upsert'
      errors = importer.upsert(upload_params[:user_reagents])
    end

    respond_to do |format|
      if errors.present?
        format.html { redirect_to '/bulk_reagents', alert: "Ran into some errors: #{errors.first(5) }" }
      else
        format.html { redirect_to '/bulk_reagents', notice: "Imported successfully" }
      end
    end
  end

  def upload_params
    params.permit(:user_reagents, :authenticity_token, :commit, :mode)
  end
end