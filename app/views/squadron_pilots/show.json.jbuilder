# frozen_string_literal: true

json.pilot do
  json.name @pilot.name
end

json.passes @passes do |pass|
  json.call pass, :id, :time, :ship_name, :aircraft_type, :grade, :score, :trap,
            :wire, :notes, :destroyed?
end

json.boarding_rate @boarding_rate

json.error_statistics @error_statistics do |stat|
  json.code stat[:code]
  json.description t("error_codes.#{stat[:code]}", default: nil)
  json.score stat[:score]
  json.count stat[:count]
end
