require 'rails_helper'

RSpec.describe 'Pilots routes', type: :request do
  let(:squadron) { FactoryBot.create :squadron }

  before(:each) { login_as squadron }

  describe 'POST /squadron/pilots/:id/merge' do
    let(:predator) { FactoryBot.create :pilot, squadron: squadron }
    let(:prey) { FactoryBot.create :pilot, squadron: squadron }

    before(:each) do
      @prey_passes        = FactoryBot.create_list(:pass, 4, squadron: squadron, pilot: prey)
      @red_herring_passes = [
          FactoryBot.create(:pass, squadron: squadron),
          FactoryBot.create(:pass, with_pilot: true)
      ]
    end

    it "merges two pilots" do
      api_request :post, "/squadron/pilots/#{predator.to_param}/merge.json?other=#{prey.to_param}"
      expect(response).to have_http_status(:success)
      expect(@prey_passes.all? { |pass| pass.reload.pilot_id == predator.id }).to eq(true)
      expect(@red_herring_passes.all? { |pass| pass.reload.pilot_id == predator.id }).to eq(false)
    end

    it "responds with 404 for an unauthorized predator pilot" do
      api_request :post, "/squadron/pilots/#{FactoryBot.create(:pilot).to_param}/merge.json?other_id=#{prey.to_param}"
      expect(response).to have_http_status(:not_found)
    end

    it "responds with 404 for an unauthorized prey pilot" do
      api_request :post, "/squadron/pilots/#{predator.to_param}/merge.json?other_id=#{FactoryBot.create(:pilot).to_param}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /squadron/pilots/:id' do
    let(:pilot) { FactoryBot.create :pilot, squadron: squadron }

    it "updates a pilot" do
      api_request :patch, "/squadron/pilots/#{pilot.to_param}.json",
                  params: {pilot: FactoryBot.attributes_for(:pilot)}
      expect(response).to have_http_status(:success)
    end

    it "renders validation errors" do
      api_request :patch, "/squadron/pilots/#{pilot.to_param}.json",
                  params: {pilot: FactoryBot.attributes_for(:pilot).merge(name: ' ')}
      expect(response.body).to match_json_expression(
                                   errors: {
                                       name: ["can’t be blank"]
                                   }
)
    end

    it "responds with 404 for an unauthorized pilot" do
      api_request :patch, "/squadron/pilots/#{FactoryBot.create(:pilot).to_param}.json",
                  params: {pilot: FactoryBot.attributes_for(:pilot)}
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /squadron/pilots/:id' do
    let(:pilot) { FactoryBot.create :pilot, squadron: squadron }

    it "deletes a pilot" do
      api_request :delete, "/squadron/pilots/#{pilot.to_param}.json"
      expect(response).to have_http_status(:success)
      expect { pilot.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "responds with 404 for an unauthorized pilot" do
      pilot = FactoryBot.create(:pilot)
      api_request :delete, "/squadron/pilots/#{pilot.to_param}.json"
      expect(response).to have_http_status(:not_found)
      expect { pilot.reload }.not_to raise_error
    end
  end
end
