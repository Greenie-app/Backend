# frozen_string_literal: true

FactoryBot.define do
  factory :pass do
    transient do
      with_pilot { false }
    end

    squadron

    time { rand(1.month).seconds.ago }

    ship_name { "CVN-#{rand(68..77)}" }
    aircraft_type { %w[FA-18C_hornet F14].sample }

    grade { Pass.grades.keys.sample }
    wire { grade.to_s.include?("waveoff") ? nil : rand(1..4) }
    notes { "WO  (DRIM)  (LURIM)  WO(AFU)IC" }

    after :build do |pass, evaluator|
      pass.pilot = FactoryBot.build(:pilot, squadron: pass.squadron) if evaluator.with_pilot
    end
  end
end
