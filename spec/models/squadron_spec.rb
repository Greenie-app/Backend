# frozen_string_literal: true

require "rails_helper"

RSpec.describe Squadron do
  describe "#boarding_rate" do
    let(:squadron) { create :squadron }
    let(:start_date) { 1.week.ago }
    let(:end_date) { Time.current }

    it "returns the number of traps over the number of attempts within date range" do
      create_list :pass, 3, squadron:, trap: true, time: 1.day.ago
      create_list :pass, 2, squadron:, trap: false, time: 1.day.ago
      create_list :pass, 1, squadron:, trap: nil, time: 1.day.ago
      Pass.last.update! trap: nil

      expect(squadron.boarding_rate(start_date:, end_date:)).to eq(0.6)
    end

    it "returns nil if there are no attempts" do
      expect(squadron.boarding_rate(start_date:, end_date:)).to be_nil
    end

    it "excludes passes outside the date range" do
      create_list :pass, 3, squadron:, trap: true, time: 1.day.ago
      create_list :pass, 2, squadron:, trap: false, time: 2.weeks.ago

      expect(squadron.boarding_rate(start_date:, end_date:)).to eq(1.0)
    end
  end
end
