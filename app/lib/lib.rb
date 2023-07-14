module Lib
  extend self

  def to_external_id(str)
    # I have no idea why I need to do this. strings coming from file uploads seem to be ascii-8bit
    str.force_encoding('UTF-8') if str.encoding == Encoding::ASCII_8BIT
    str.strip.parameterize.underscore
  end

  def format_volume(volume, unit)
    volume.convert_to(unit).format("%.2<value>f %<unit>s", with_conversion_string: false)
  end
end