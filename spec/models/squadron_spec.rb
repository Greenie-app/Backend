require 'rails_helper'

RSpec.describe Squadron, type: :model do
  describe '#boarding_rate' do
    let(:squadron) { FactoryBot.create :squadron }

    it "returns the number of traps over the number of attempts" do
      FactoryBot.create_list :pass, 3, squadron: squadron, trap: true
      FactoryBot.create_list :pass, 2, squadron: squadron, trap: false
      FactoryBot.create_list :pass, 1, squadron: squadron, trap: nil
      Pass.last.update trap: nil

      expect(squadron.boarding_rate).to eq(0.6)
    end

    it "returns nil if there are no attempts" do
      expect(squadron.boarding_rate).to be_nil
    end
  end
end
