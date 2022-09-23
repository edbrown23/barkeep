module Lib
  extend self

  def to_external_id(str)
    str.strip.parameterize.underscore
  end
end
