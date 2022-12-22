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

  # something would tell me this logic should go in a service or somewhere else more testable
  def import_reagents(reagents_file)
    errors = []

    Reagent.transaction do
      CSV.parse(reagents_file.read, headers: true) do |row|
        if row.headers != REQUIRED_HEADERS
          errors << "Required Headers are incorrect. Must have #{REQUIRED_HEADERS} in that order"
          break
        end

        parsed_tags = (row['Tags'] || '').split(';').map { |t| Lib.to_external_id(t) }

        model_attributes = {
          user: current_user,
          name: row['Name'],
          external_id: Lib.to_external_id(row['Name']),
          max_volume_value: row['Max Volume'],
          max_volume_unit: row['Max Volume Unit'] || 'ml',
          current_volume_value: row['Current Volume'],
          current_volume_unit: row['Current Volume Unit'] || 'ml',
          tags: parsed_tags
        }

        begin
          reagent = Reagent.new(model_attributes)
          errors.concat(reagent.errors.full_messages) unless reagent.save
        rescue ActiveRecord::RecordNotUnique => e
          errors << e.message
        end
      end
    end

    errors
  end

  def upload_params
    params.permit(:user_reagents, :authenticity_token, :commit, :mode)
  end
end