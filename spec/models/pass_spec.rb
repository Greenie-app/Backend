require 'rails_helper'

RSpec.describe Pass, type: :model do
  context '[defaults]' do
    it "sets a default value for `trap`" do
      expect(FactoryBot.create(:pass, grade: :bolter)).not_to be_trap
      expect(FactoryBot.create(:pass, grade: :fair)).to be_trap
    end

    it "sets a default value for `score`" do
      expect(FactoryBot.create(:pass, grade: :bolter).score).to eq(2.5)
      expect(FactoryBot.create(:pass, grade: :foul_deck_waveoff).score).to be_nil
    end
  end
end
