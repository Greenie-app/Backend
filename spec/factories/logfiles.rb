FactoryBot.define do
  factory :logfile do
    transient do
      files { [Rails.root.join('spec', 'fixtures', 'dcs.log')] }
    end

    association :squadron

    after :build do |logfile, evaluator|
      evaluator.files.each do |file|
        logfile.files.attach(io: file.open, filename: 'dcs.log', content_type: 'text/plain')
      end
    end
  end
end
