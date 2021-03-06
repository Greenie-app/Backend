FactoryBot.define do
  factory :pilot do
    association :squadron

    sequence(:name) { |i| "pilot-#{i}" }
  end
end
