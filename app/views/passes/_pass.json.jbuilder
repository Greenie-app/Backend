# frozen_string_literal: true

json.call pass, :id, :time, :ship_name, :aircraft_type, :grade, :score, :trap,
          :wire, :notes, :destroyed?

json.pilot pass.pilot&.name

if defined?(include_squadron) && include_squadron
  json.squadron do
    json.partial! "squadrons/squadron",
                  locals: {
                      squadron:           pass.squadron,
                      unknown_pass_count: defined?(unknown_pass_count) ? unknown_pass_count : nil
                  }
  end
end
