# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pilots routes" do
  let(:squadron) { create :squadron }

  before(:each) { login_squadron squadron }

  describe "POST /squadron/pilots/:id/merge" do
    let(:predator) { create :pilot, squadron: }
    let(:prey) { create :pilot, squadron: }

    before(:each) do
      @prey_passes        = create_list(:pass, 4, squadron:, pilot: prey)
      @red_herring_passes = [
          create(:pass, squadron:),
          create(:pass, with_pilot: true)
      ]
    end

    it "merges two pilots" do
      api_request :post, "/squadron/pilots/#{predator.to_param}/merge.json?other=#{prey.to_param}"
      expect(response).to have_http_status(:success)
      expect(@prey_passes.all? { |pass| pass.reload.pilot_id == predator.id }).to be(true)
      expect(@red_herring_passes.all? { |pass| pass.reload.pilot_id == predator.id }).to be(false)
    end

    it "responds with 404 for an unauthorized predator pilot" do
      api_request :post, "/squadron/pilots/#{create(:pilot).to_param}/merge.json?other_id=#{prey.to_param}"
      expect(response).to have_http_status(:not_found)
    end

    it "responds with 404 for an unauthorized prey pilot" do
      api_request :post, "/squadron/pilots/#{predator.to_param}/merge.json?other_id=#{create(:pilot).to_param}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /squadron/pilots/:id" do
    let(:pilot) { create :pilot, squadron: }

    it "updates a pilot" do
      api_request :patch, "/squadron/pilots/#{pilot.to_param}.json",
                  params: {pilot: attributes_for(:pilot)}
      expect(response).to have_http_status(:success)
    end

    it "renders validation errors" do
      api_request :patch, "/squadron/pilots/#{pilot.to_param}.json",
                  params: {pilot: attributes_for(:pilot).merge(name: " ")}
      expect(response.body).to match_json_expression(
                                   errors: {
                                       name: ["can’t be blank"]
                                   }
                                 )
    end

    it "responds with 404 for an unauthorized pilot" do
      api_request :patch, "/squadron/pilots/#{create(:pilot).to_param}.json",
                  params: {pilot: attributes_for(:pilot)}
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /squadron/pilots/:id" do
    let(:pilot) { create :pilot, squadron: }

    it "deletes a pilot" do
      api_request :delete, "/squadron/pilots/#{pilot.to_param}.json"
      expect(response).to have_http_status(:success)
      expect { pilot.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "responds with 404 for an unauthorized pilot" do
      pilot = create(:pilot)
      api_request :delete, "/squadron/pilots/#{pilot.to_param}.json"
      expect(response).to have_http_status(:not_found)
      expect { pilot.reload }.not_to raise_error
    end
  end
end
