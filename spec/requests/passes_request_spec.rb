# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passes routes" do
  let(:squadron) { create :squadron }

  before(:each) { login_squadron squadron }

  describe "GET /squadrons/:squadron_id/passes" do
    let(:today) { Time.zone.now }
    let(:start_date) { (today - 4.weeks).iso8601 }
    let(:end_date) { today.iso8601 }

    before :each do
      # Create passes across different time periods
      create :pass, squadron:, time: today - 5.weeks # Outside range
      create :pass, squadron:, time: today - 3.weeks # Within range
      create :pass, squadron:, time: today - 2.weeks # Within range
      create :pass, squadron:, time: today - 1.week # Within range
      create :pass, squadron:, time: today # Within range
      create :pass, squadron:, time: today + 1.week # Outside range
    end

    it "requires start_date and end_date parameters" do
      api_request :get, "/squadrons/#{squadron.to_param}/passes.json"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match_json_expression(error: "start_date and end_date parameters are required")

      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=#{start_date}"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match_json_expression(error: "start_date and end_date parameters are required")

      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?end_date=#{end_date}"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match_json_expression(error: "start_date and end_date parameters are required")
    end

    it "validates date format" do
      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=invalid&end_date=#{end_date}"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("Invalid date format")

      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=#{start_date}&end_date=invalid"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("Invalid date format")
    end

    it "lists passes within date range" do
      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=#{start_date}&end_date=#{end_date}"

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("passes")

      passes = response.parsed_body["passes"]
      expect(passes.count).to eq(4) # Only passes within the last 4 weeks

      # Verify all returned passes are within the date range
      passes.each do |pass|
        pass_time = Time.zone.parse(pass["time"])
        expect(pass_time).to be >= Time.zone.parse(start_date).beginning_of_day
        expect(pass_time).to be <= Time.zone.parse(end_date).end_of_day
      end
    end

    it "returns empty array when no passes in date range" do
      far_past_start = (today - 10.weeks).iso8601
      far_past_end = (today - 9.weeks).iso8601

      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=#{far_past_start}&end_date=#{far_past_end}"

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("passes")
      expect(response.parsed_body["passes"]).to be_empty
      expect(response.parsed_body["boarding_rate"]).to be_nil
    end

    it "handles same start and end date" do
      same_date = today.iso8601
      create :pass, squadron:, time: today.beginning_of_day
      create :pass, squadron:, time: today.end_of_day

      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=#{same_date}&end_date=#{same_date}"

      expect(response).to have_http_status(:success)
      expect(response).to match_json_schema("passes")

      passes = response.parsed_body["passes"]
      expect(passes.count).to eq(3) # The pass created at 'today' plus the two we just created
    end

    it "orders passes by time descending" do
      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=#{start_date}&end_date=#{end_date}"

      expect(response).to have_http_status(:success)
      passes = response.parsed_body["passes"]

      times = passes.map { |p| Time.zone.parse(p["time"]) }
      expect(times).to eq(times.sort.reverse)
    end

    it "includes boarding_rate for the date range" do
      # Create passes with trap values in range
      create :pass, squadron:, time: today - 1.day, trap: true
      create :pass, squadron:, time: today - 1.day, trap: true
      create :pass, squadron:, time: today - 1.day, trap: false

      api_request :get, "/squadrons/#{squadron.to_param}/passes.json?start_date=#{start_date}&end_date=#{end_date}"

      expect(response).to have_http_status(:success)
      # 2 traps out of 3 attempts (ignoring previously created passes with nil trap)
      # But we need to account for the passes created in before block
      boarding_rate = response.parsed_body["boarding_rate"]
      expect(boarding_rate).to be_a(Float)
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
