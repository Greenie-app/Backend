# frozen_string_literal: true

require "rails_helper"

RSpec.describe Squadron do
  describe "#boarding_rate" do
    let(:squadron) { create :squadron }

    it "returns the number of traps over the number of attempts" do
      create_list :pass, 3, squadron:, trap: true
      create_list :pass, 2, squadron:, trap: false
      create_list :pass, 1, squadron:, trap: nil
      Pass.last.update trap: nil

      expect(squadron.boarding_rate).to eq(0.6)
    end

    it "returns nil if there are no attempts" do
      expect(squadron.boarding_rate).to be_nil
    end
  end
end
