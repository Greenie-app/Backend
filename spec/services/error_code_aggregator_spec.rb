# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorCodeAggregator do
  let(:technique_error) { RemarksParser::TechniqueError }

  describe "#aggregate" do
    it "aggregates errors by code with correct scoring" do
      errors = [
          technique_error.new(code: "LUL", intensity: :low, phase: "X", modifiers: []),
          technique_error.new(code: "LUL", intensity: :medium, phase: "IM", modifiers: []),
          technique_error.new(code: "LUL", intensity: :high, phase: "IC", modifiers: []),
          technique_error.new(code: "F", intensity: :high, phase: "X", modifiers: [])
      ]

      aggregator = described_class.new(errors)
      result = aggregator.aggregate

      expect(result.length).to eq(2)

      lul_result = result.find { |r| r[:code] == "LUL" }
      expect(lul_result[:score]).to eq(3.5) # 0.5 + 1.0 + 2.0
      expect(lul_result[:count]).to eq(3)

      f_result = result.find { |r| r[:code] == "F" }
      expect(f_result[:score]).to eq(2.0)
      expect(f_result[:count]).to eq(1)
    end

    it "sorts results by score in descending order" do
      errors = [
          technique_error.new(code: "F", intensity: :low, phase: "X", modifiers: []),
          technique_error.new(code: "LUL", intensity: :high, phase: "X", modifiers: []),
          technique_error.new(code: "LUL", intensity: :high, phase: "IM", modifiers: []),
          technique_error.new(code: "H", intensity: :medium, phase: "X", modifiers: [])
      ]

      aggregator = described_class.new(errors)
      result = aggregator.aggregate

      expect(result[0][:code]).to eq("LUL") # 4.0
      expect(result[1][:code]).to eq("H")   # 1.0
      expect(result[2][:code]).to eq("F")   # 0.5
    end

    it "handles empty errors array" do
      aggregator = described_class.new([])
      result = aggregator.aggregate

      expect(result).to be_empty
    end

    it "handles nil errors" do
      aggregator = described_class.new(nil)
      result = aggregator.aggregate

      expect(result).to be_empty
    end

    it "uses low intensity score of 0.5" do
      errors = [
          technique_error.new(code: "DR", intensity: :low, phase: "X", modifiers: [])
      ]

      aggregator = described_class.new(errors)
      result = aggregator.aggregate

      expect(result[0][:score]).to eq(0.5)
    end

    it "uses medium intensity score of 1.0" do
      errors = [
          technique_error.new(code: "DR", intensity: :medium, phase: "X", modifiers: [])
      ]

      aggregator = described_class.new(errors)
      result = aggregator.aggregate

      expect(result[0][:score]).to eq(1.0)
    end

    it "uses high intensity score of 2.0" do
      errors = [
          technique_error.new(code: "DR", intensity: :high, phase: "X", modifiers: [])
      ]

      aggregator = described_class.new(errors)
      result = aggregator.aggregate

      expect(result[0][:score]).to eq(2.0)
    end
  end

  describe "#top" do
    it "returns top N errors by score" do
      errors = [
          technique_error.new(code: "LUL", intensity: :high, phase: "X", modifiers: []),
          technique_error.new(code: "LUL", intensity: :high, phase: "IM", modifiers: []),
          technique_error.new(code: "F", intensity: :high, phase: "X", modifiers: []),
          technique_error.new(code: "H", intensity: :medium, phase: "X", modifiers: []),
          technique_error.new(code: "LO", intensity: :low, phase: "X", modifiers: []),
          technique_error.new(code: "DR", intensity: :low, phase: "IM", modifiers: [])
      ]

      aggregator = described_class.new(errors)
      result = aggregator.top(3)

      expect(result.length).to eq(3)
      expect(result[0][:code]).to eq("LUL") # 4.0
      expect(result[1][:code]).to eq("F")   # 2.0
      expect(result[2][:code]).to eq("H")   # 1.0
    end

    it "defaults to top 5" do
      errors = (1..10).map do |_i|
        technique_error.new(code: "LUL", intensity: :medium, phase: "X", modifiers: [])
      end

      aggregator = described_class.new(errors)
      result = aggregator.top

      # Only 1 unique code, so should return 1 result
      expect(result.length).to eq(1)
    end

    it "returns all errors if fewer than N unique codes" do
      errors = [
          technique_error.new(code: "LUL", intensity: :high, phase: "X", modifiers: []),
          technique_error.new(code: "F", intensity: :medium, phase: "X", modifiers: [])
      ]

      aggregator = described_class.new(errors)
      result = aggregator.top(5)

      expect(result.length).to eq(2)
    end
  end

  describe "integration with RemarksParser" do
    it "aggregates errors from parsed remarks" do
      remarks = "GRADE:WO  (DLX)  _LULX_  _LULIM_  (DLIM)  WO(AFU)IC"
      parser = RemarksParser.new(remarks)
      errors = parser.parse

      aggregator = described_class.new(errors)
      result = aggregator.aggregate

      # Should have LUL (2 high = 4.0), DL (2 low = 1.0), AFU (1 low = 0.5)
      expect(result[0][:code]).to eq("LUL")
      expect(result[0][:score]).to eq(4.0)

      expect(result[1][:code]).to eq("DL")
      expect(result[1][:score]).to eq(1.0)

      expect(result[2][:code]).to eq("AFU")
      expect(result[2][:score]).to eq(0.5)
    end

    it "aggregates errors from multiple passes" do
      remarks1 = "GRADE:WO  (DRIM)  (LURIM)  WO(AFU)IC"
      remarks2 = "GRADE:B  (NX)  _WX_  _DRX_  _LURX_  (LURIM)  3PTSIW  BIW"

      all_errors = []
      all_errors += RemarksParser.new(remarks1).parse
      all_errors += RemarksParser.new(remarks2).parse

      aggregator = described_class.new(all_errors)
      result = aggregator.aggregate

      # Check that errors from both passes are combined
      lur_result = result.find { |r| r[:code] == "LUR" }
      expect(lur_result).not_to be_nil
      expect(lur_result[:count]).to eq(3) # 2 from remarks2, 1 from remarks1

      dr_result = result.find { |r| r[:code] == "DR" }
      expect(dr_result).not_to be_nil
      expect(dr_result[:count]).to eq(2) # 1 from each remarks
    end
  end
end
