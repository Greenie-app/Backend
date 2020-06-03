json.call squadron, :id, :name, :username, :email, :created_at, :updated_at

json.boarding_rate(defined?(boarding_rate) && boarding_rate ?
                       boarding_rate : squadron.boarding_rate)
json.unknown_pass_count(defined?(unknown_pass_count) && unknown_pass_count ?
                            unknown_pass_count : squadron.unknown_pass_count)

if squadron.image.attached?
  json.image do
    json.url polymorphic_url(squadron.image.variant(resize_to_limit: [300, 300]))
  end
else
  json.image nil
end
