# frozen_string_literal: true

IRB.conf[:SAVE_HISTORY] = false if ENV['IS_CONTAINERIZED'].present?
IRB.conf[:USE_AUTOCOMPLETE] = false
