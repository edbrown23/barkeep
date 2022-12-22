require 'csv'

class BulkReagentService
  REQUIRED_HEADERS = ['Name', 'Tags', 'Max Volume', 'Max Volume Unit', 'Current Volume', 'Current Volume Unit'].freeze
  REQUIRED_VALUES = ['Name', 'Tags', 'Max Volume', 'Current Volume'].freeze

  def initialize(current_user)
    @current_user = current_user
  end

  def insert(reagents_file)
    Reagent.transaction do
      iterate_csv(reagents_file) do |attrs, running_errors|
        begin
          reagent = Reagent.new(attrs)
          reagent.save
          reagent.errors.full_messages
        rescue ActiveRecord::RecordNotUnique => e
          [e.message]
        end
      end
    end
  end

  def upsert(reagents_file)
    Reagent.transaction do
      iterate_csv(reagents_file) do |attrs|
        Reagent.find_or_create_by(name: attrs[:name], external_id: attrs[:external_id], user_id: attrs[:user].id) do |model|
          model.update(
            max_volume_value: attrs[:max_volume_value],
            max_volume_unit: attrs[:max_volume_unit],
            current_volume_value: attrs[:current_volume_value],
            current_volume_unit: attrs[:current_volume_unit],
            tags: parsed_tags
          )
        end
        []
      end
    end
  end

  private

  def iterate_csv(reagents_file)
    errors = []

    CSV.parse(reagents_file.read, headers: true) do |row|
      if row.headers != REQUIRED_HEADERS
        errors << "Required Headers are incorrect. Must have #{REQUIRED_HEADERS} in that order"
        break
      end

      if REQUIRED_VALUES.any? { |value| row[value].blank? }
        next
      end

      parsed_tags = (row['Tags'] || '').split(';').map { |t| Lib.to_external_id(t) }

      model_attributes = {
        user: @current_user,
        name: row['Name'],
        external_id: Lib.to_external_id(row['Name']),
        max_volume_value: row['Max Volume'],
        max_volume_unit: row['Max Volume Unit'] || 'ml',
        current_volume_value: row['Current Volume'],
        current_volume_unit: row['Current Volume Unit'] || 'ml',
        tags: parsed_tags
      }

      errors.concat(yield model_attributes)
    end

    errors
  end
end