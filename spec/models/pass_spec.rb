# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pass do
  context "[defaults]" do
    it "sets a default value for `trap`" do
      expect(create(:pass, grade: :bolter)).not_to be_trap
      expect(create(:pass, grade: :fair)).to be_trap
    end

    it "sets a default value for `score`" do
      expect(create(:pass, grade: :bolter).score).to eq(2.5)
      expect(create(:pass, grade: :foul_deck_waveoff).score).to be_nil
    end
  end
end
