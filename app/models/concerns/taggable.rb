module Taggable
  extend ActiveSupport::Concern
  
  included do
    scope :with_tags, ->(tags_array) do
      where("tags && ARRAY[?]::varchar[]", tags_array)
    end
  end
end