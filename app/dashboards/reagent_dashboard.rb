require "administrate/base_dashboard"

class ReagentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    cost: Field::String.with_options(searchable: false),
    current_volume_unit: Field::String,
    current_volume_value: Field::String.with_options(searchable: false),
    description: Field::Text,
    external_id: Field::String,
    max_volume_unit: Field::String,
    max_volume_value: Field::String.with_options(searchable: false),
    name: Field::String,
    purchase_location: Field::String,
    tags: Field::String,
    user: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    cost
    current_volume_unit
    current_volume_value
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    cost
    current_volume_unit
    current_volume_value
    description
    external_id
    max_volume_unit
    max_volume_value
    name
    purchase_location
    tags
    user
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    cost
    current_volume_unit
    current_volume_value
    description
    external_id
    max_volume_unit
    max_volume_value
    name
    purchase_location
    tags
    user
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how reagents are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(reagent)
  #   "Reagent ##{reagent.id}"
  # end
end
