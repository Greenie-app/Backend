# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passes routes" do
  let(:squadron) { create :squadron }

  before(:each) { login_squadron squadron }

  describe "GET /squadrons/:squadron_id/passes" do
    before :each do
      create_list :pass, 10, squadron:
    end

    it "lists passes" do
      api_request :get, "/squadrons/#{squadron.to_param}/passes.json"

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("passes")
    end

    it "paginates" do
      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?page=1&per_page=5"
      expect(response).to have_http_status(:success)
      expect(response.headers["X-Page"]).to eq("1")
      expect(response.headers["X-Count"]).to eq("10")
      expect(response).to match_json_schema("passes")

      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?page=2&per_page=5"
      expect(response).to have_http_status(:success)
      expect(response.headers["X-Page"]).to eq("2")
      expect(response.headers["X-Per-Page"]).to eq("5")
      expect(response.headers["X-Count"]).to eq("10")
      expect(response).to match_json_schema("passes")
    end
  end

  describe "GET /squadrons/:squadron_id/passes/:id" do
    let(:pass) { create :pass, squadron: }

    it "shows a pass" do
      api_request :get, "/squadrons/#{squadron.to_param}/passes/#{pass.to_param}.json"

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("pass")
    end

    it "responds with 404 for an unauthorized pass" do
      other_pass = create(:pass)
      api_request :get, "/squadrons/#{squadron.to_param}/passes/#{other_pass.to_param}.json"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /squadron/passes" do
    let(:pilot) { create :pilot, squadron: }

    it "creates a pass" do
      api_request :post, "/squadron/passes.json",
                  params: {pass: attributes_for(:pass)}

      expect(response).to have_http_status(:success)
      expect(squadron.passes.count).to eq(1)
      expect(response).to match_json_schema("pass")
    end

    it "associates an existing pilot with a pass" do
      api_request :post, "/squadron/passes.json",
                  params: {pass: attributes_for(:pass).merge(pilot: pilot.name)}

      expect(response).to have_http_status(:success)
      expect(squadron.passes.count).to eq(1)
      expect(response).to match_json_schema("pass")

      expect(Pass.last.pilot).to eq(pilot)
    end

    it "creates a new pilot with a pass" do
      api_request :post, "/squadron/passes.json",
                  params: {pass: attributes_for(:pass).merge(pilot: "Newpilot")}

      expect(response).to have_http_status(:success)
      expect(squadron.passes.count).to eq(1)
      expect(response).to match_json_schema("pass")

      expect(Pass.last.pilot.name).to eq("Newpilot")
    end

    it "renders validation errors" do
      api_request :post, "/squadron/passes.json",
                  params: {pass: attributes_for(:pass).merge(time: " ")}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).
          to match_json_expression(errors: {time: ["can’t be blank"]})
    end
  end

  describe "PATCH /squadron/passes/:id" do
    let(:pass) { create :pass, squadron: }
    let(:pilot) { create :pilot, squadron: }

    it "updates a pass" do
      api_request :patch, "/squadron/passes/#{pass.to_param}.json",
                  params: {pass: attributes_for(:pass)}

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("pass")
    end

    it "creates a new pilot with an updated pass" do
      api_request :patch, "/squadron/passes/#{pass.to_param}.json",
                  params: {pass: attributes_for(:pass).merge(pilot: "Newpilot")}

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("pass")
      expect(pass.reload.pilot.name).to eq("Newpilot")
    end

    it "associates an existing pilot with an updated pass" do
      api_request :patch, "/squadron/passes/#{pass.to_param}.json",
                  params: {pass: attributes_for(:pass).merge(pilot: pilot.name)}

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("pass")
      expect(pass.reload.pilot).to eq(pilot)
    end

    it "renders validation errors" do
      api_request :patch, "/squadron/passes/#{pass.to_param}.json",
                  params: {pass: attributes_for(:pass).merge(wire: "5")}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).
          to match_json_expression(errors: {wire: ["must be less than or equal to 4"]})
    end

    it "responds with 404 for an unauthorized pass" do
      other_pass = create(:pass)
      api_request :patch, "/squadron/passes/#{other_pass.to_param}.json",
                  params: {pass: attributes_for(:pass)}
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /squadron/passes/:id" do
    let(:pass) { create :pass, squadron: }

    it "deletes a pass" do
      api_request :delete, "/squadron/passes/#{pass.to_param}.json"
      expect(response).to have_http_status(:success)
      expect { pass.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "responds with 404 for an unauthorized pass" do
      other_pass = create(:pass)
      api_request :delete, "/squadron/passes/#{other_pass.to_param}.json"
      expect(response).to have_http_status(:not_found)
      expect { other_pass.reload }.not_to raise_error
    end
  end

  describe "DELETE /squadron/passes/unknown" do
    it "deletes all passes with unknown pilots" do
      unknown_passes = create_list(:pass, 3, squadron:, pilot: nil)
      known_pass     = create(:pass, squadron:, with_pilot: true)
      other_squadron = create(:pass, with_pilot: true)

      api_request :delete, "/squadron/passes/unknown.json"
      expect(response).to have_http_status(:success)

      unknown_passes.each { |pass| expect { pass.reload }.to raise_error(ActiveRecord::RecordNotFound) }
      expect { known_pass.reload }.not_to raise_error
      expect { other_squadron.reload }.not_to raise_error
    end
  end
end
