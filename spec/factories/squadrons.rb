# frozen_string_literal: true

FactoryBot.define do
  factory :squadron do
    transient do
      image { Rails.root.join("spec", "fixtures", "files", "image.png") }
    end

    sequence(:username) { |i| "squadron-#{i}" }
    email { "#{username}@squadron.com" }
    name { "Test Squadron" }
    password { "password123" }
    password_confirmation { "password123" }

    after :build do |squadron, evaluator|
      squadron.image.attach(io: evaluator.image.open, filename: "patch.png", content_type: "image/png") if evaluator.image
    end
  end
end
