# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Squadron Pilots routes" do
  let(:squadron) { create :squadron }
  let(:pilot) { create :pilot, squadron: squadron }
  let(:today) { Time.zone.now }
  let(:start_date) { (today - 4.weeks).iso8601 }
  let(:end_date) { today.iso8601 }

  describe "GET /squadrons/:squadron_id/pilots/:id" do
    it "requires start_date and end_date parameters" do
      get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match_json_expression(error: "start_date and end_date parameters are required")

      get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match_json_expression(error: "start_date and end_date parameters are required")

      get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?end_date=#{end_date}"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to match_json_expression(error: "start_date and end_date parameters are required")
    end

    it "validates date format" do
      get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=invalid&end_date=#{end_date}"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("Invalid date format")

      get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=invalid"
      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("Invalid date format")
    end

    it "returns 404 for non-existent squadron" do
      get "/squadrons/nonexistent/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for non-existent pilot" do
      get "/squadrons/#{squadron.to_param}/pilots/nonexistent.json?start_date=#{start_date}&end_date=#{end_date}"
      expect(response).to have_http_status(:not_found)
    end

    context "with passes" do
      before :each do
        # Create passes with different dates and errors
        create :pass, squadron: squadron, pilot: pilot, time: today - 5.weeks,
               notes: "GRADE:WO  (DRIM)  (LURIM)  WO(AFU)IC", trap: false # Outside range

        create :pass, squadron: squadron, pilot: pilot, time: today - 3.weeks,
               notes: "GRADE:C : (DLX)  _LULX_  _FX_  WIRE# 3", trap: false

        create :pass, squadron: squadron, pilot: pilot, time: today - 2.weeks,
               notes: "GRADE:B  _LULIM_  (DLIM)  3PTSIW  BIW", trap: true

        create :pass, squadron: squadron, pilot: pilot, time: today - 1.week,
               notes: "GRADE:_OK_ : WIRE# 2", trap: true

        create :pass, squadron: squadron, pilot: pilot, time: today,
               notes: "GRADE:WO  _LULX_  WO(AFU)IC", trap: false

        # Pass for different pilot
        other_pilot = create :pilot, squadron: squadron
        create :pass, squadron: squadron, pilot: other_pilot, time: today - 1.week,
               notes: "GRADE:C : _HX_ WIRE# 2", trap: true
      end

      it "returns pilot information" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        expect(response).to have_http_status(:success)
        body = response.parsed_body

        expect(body["pilot"]["name"]).to eq(pilot.name)
      end

      it "returns passes within date range for the pilot only" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        expect(response).to have_http_status(:success)
        body = response.parsed_body

        expect(body["passes"].count).to eq(4) # Only passes within range for this pilot
      end

      it "orders passes by time descending" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        body = response.parsed_body
        times = body["passes"].map { |p| Time.zone.parse(p["time"]) }
        expect(times).to eq(times.sort.reverse)
      end

      it "calculates boarding rate for pilot's passes in range" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        body = response.parsed_body
        # 2 traps out of 4 passes = 0.5
        expect(body["boarding_rate"]).to eq(0.5)
      end

      it "returns aggregated error statistics with overall top 3" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        body = response.parsed_body
        stats = body["error_statistics"]

        expect(stats).to be_a(Hash)
        expect(stats).to include("overall", "by_phase")

        overall = stats["overall"]
        expect(overall).to be_an(Array)
        expect(overall.length).to be <= 3 # Top 3 only

        # LUL should be the top error (appears 3 times with high intensity)
        lul_stat = overall.find { |s| s["code"] == "LUL" }
        expect(lul_stat).not_to be_nil
        expect(lul_stat["description"]).to eq("Lined up left")
        expect(lul_stat["score"]).to eq(6.0) # 3 * 2.0 (high intensity)
        expect(lul_stat["count"]).to eq(3)
      end

      it "returns error statistics grouped by phase" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        body = response.parsed_body
        by_phase = body["error_statistics"]["by_phase"]

        expect(by_phase).to be_a(Hash)

        # X phase should have LUL and F errors
        expect(by_phase).to have_key("X")
        expect(by_phase["X"]["phase_description"]).to eq("At the start")
        x_errors = by_phase["X"]["errors"]
        expect(x_errors).to be_an(Array)
        expect(x_errors.length).to be <= 3

        lul_in_x = x_errors.find { |e| e["code"] == "LUL" }
        expect(lul_in_x).not_to be_nil

        # IM phase should have LUL and DL errors
        expect(by_phase).to have_key("IM")
        expect(by_phase["IM"]["phase_description"]).to eq("In the middle")

        # IC phase should have AFU errors
        expect(by_phase).to have_key("IC")
        expect(by_phase["IC"]["phase_description"]).to eq("In close")

        # IW phase should have 3PTS and B errors
        expect(by_phase).to have_key("IW")
        expect(by_phase["IW"]["phase_description"]).to eq("In the wires")
      end

      it "sorts overall error statistics by score descending" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        body = response.parsed_body
        stats = body["error_statistics"]["overall"]

        scores = stats.pluck("score")
        expect(scores).to eq(scores.sort.reverse)
      end

      it "includes all required fields in error statistics" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        body = response.parsed_body
        overall = body["error_statistics"]["overall"]
        by_phase = body["error_statistics"]["by_phase"]

        expect(overall).to all(include("code", "description", "score", "count"))
        by_phase.each_value do |phase_data|
          expect(phase_data).to include("phase_description", "errors")
          expect(phase_data["errors"]).to all(include("code", "description", "score", "count"))
        end
      end
    end

    context "with no passes" do
      it "returns empty passes array" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        expect(response).to have_http_status(:success)
        body = response.parsed_body

        expect(body["passes"]).to be_empty
        expect(body["boarding_rate"]).to eq(0.0)
        expect(body["error_statistics"]["overall"]).to be_empty
        expect(body["error_statistics"]["by_phase"]).to be_empty
      end
    end

    context "with passes having no errors" do
      before :each do
        create :pass, squadron: squadron, pilot: pilot, time: today - 1.week,
               notes: "GRADE:_OK_ : WIRE# 3", trap: true
        create :pass, squadron: squadron, pilot: pilot, time: today,
               notes: "GRADE:(OK) : WIRE# 2", trap: true
      end

      it "returns empty error statistics" do
        get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

        body = response.parsed_body
        expect(body["error_statistics"]["overall"]).to be_empty
        expect(body["error_statistics"]["by_phase"]).to be_empty
      end
    end

    it "handles passes with nil notes" do
      create :pass, squadron: squadron, pilot: pilot, time: today - 1.week, notes: nil

      get "/squadrons/#{squadron.to_param}/pilots/#{pilot.to_param}.json?start_date=#{start_date}&end_date=#{end_date}"

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["passes"].count).to eq(1)
      expect(body["error_statistics"]["overall"]).to be_empty
      expect(body["error_statistics"]["by_phase"]).to be_empty
    end
  end
end
