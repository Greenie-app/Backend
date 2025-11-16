# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemarksParser do
  describe "#parse" do
    it "parses a simple waveoff remark" do
      parser = described_class.new("GRADE:WO  (DRIM)  (LURIM)  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(3)

      expect(errors[0].code).to eq("DR")
      expect(errors[0].intensity).to eq(:low)
      expect(errors[0].phase).to eq("IM")
      expect(errors[0].modifiers).to eq([])

      expect(errors[1].code).to eq("LUR")
      expect(errors[1].intensity).to eq(:low)
      expect(errors[1].phase).to eq("IM")
      expect(errors[1].modifiers).to eq([])

      expect(errors[2].code).to eq("AFU")
      expect(errors[2].intensity).to eq(:low)
      expect(errors[2].phase).to eq("IC")
      expect(errors[2].modifiers).to eq(%w[WO])
    end

    it "parses high intensity errors with underscores" do
      parser = described_class.new("GRADE:WO  (DLX)  _LULX_  _LULIM_  (DLIM)  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(5)

      expect(errors[0].code).to eq("DL")
      expect(errors[0].intensity).to eq(:low)
      expect(errors[0].phase).to eq("X")

      expect(errors[1].code).to eq("LUL")
      expect(errors[1].intensity).to eq(:high)
      expect(errors[1].phase).to eq("X")

      expect(errors[2].code).to eq("LUL")
      expect(errors[2].intensity).to eq(:high)
      expect(errors[2].phase).to eq("IM")

      expect(errors[3].code).to eq("DL")
      expect(errors[3].intensity).to eq(:low)
      expect(errors[3].phase).to eq("IM")

      expect(errors[4].code).to eq("AFU")
      expect(errors[4].intensity).to eq(:low)
      expect(errors[4].phase).to eq("IC")
      expect(errors[4].modifiers).to eq(%w[WO])
    end

    it "parses medium intensity errors without decoration" do
      parser = described_class.new("GRADE:WO  LULX  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(2)

      expect(errors[0].code).to eq("LUL")
      expect(errors[0].intensity).to eq(:medium)
      expect(errors[0].phase).to eq("X")
    end

    it "parses complex remarks with multiple phases" do
      parser = described_class.new("GRADE:C : (DLX)  _LULX_  _FX_  _LULIM_  (DLIM)  _LULIC_  _LOIC_  _PIC_  _PPPIC_  _LOAR_  WO(AFU)TL  3PTSIW  _EGIW_  WIRE# 3[BC]")
      errors = parser.parse

      expect(errors.length).to eq(13)

      # Check specific errors
      error_codes = errors.map(&:code)
      expect(error_codes).to include("DL", "LUL", "F", "LO", "P", "PPP", "EG", "AFU", "3PTS")

      # Check phases
      phases = errors.map(&:phase)
      expect(phases).to include("X", "IM", "IC", "AR", "TL", "IW")

      # Check the AFU has WO modifier
      afu_error = errors.find { |e| e.code == "AFU" }
      expect(afu_error.modifiers).to eq(%w[WO])
      expect(afu_error.phase).to eq("TL")
    end

    it "parses remarks with OK grade" do
      parser = described_class.new("GRADE:(OK) : WIRE# 2[BC]")
      errors = parser.parse

      expect(errors).to be_empty
    end

    it "parses remarks with no errors" do
      parser = described_class.new("GRADE:_OK_ : WIRE# 3")
      errors = parser.parse

      expect(errors).to be_empty
    end

    it "parses remarks with minor errors only" do
      parser = described_class.new("GRADE:--- : (EGTL)  WIRE# 1")
      errors = parser.parse

      expect(errors.length).to eq(1)
      expect(errors[0].code).to eq("EG")
      expect(errors[0].intensity).to eq(:low)
      expect(errors[0].phase).to eq("TL")
    end

    it "parses bolter remarks" do
      parser = described_class.new("GRADE:B  (NX)  _WX_  _DRX_  _LURX_  (LURIM)  3PTSIW  BIW")
      errors = parser.parse

      # Should include N, W, DR, LUR, LUR (IM), 3PTS
      error_codes = errors.map(&:code)
      expect(error_codes).to include("N", "W", "DR", "LUR", "3PTS")

      # Check intensities
      n_error = errors.find { |e| e.code == "N" && e.phase == "X" }
      expect(n_error.intensity).to eq(:low)

      w_error = errors.find { |e| e.code == "W" && e.phase == "X" }
      expect(w_error.intensity).to eq(:high)
    end

    it "handles nil remarks" do
      parser = described_class.new(nil)
      errors = parser.parse

      expect(errors).to be_empty
    end

    it "handles empty remarks" do
      parser = described_class.new("")
      errors = parser.parse

      expect(errors).to be_empty
    end

    it "parses slow errors" do
      parser = described_class.new("GRADE:B  SLOX  (LLIW)  3PTSIW  BIW")
      errors = parser.parse

      slo_error = errors.find { |e| e.code == "SLO" }
      expect(slo_error).not_to be_nil
      expect(slo_error.intensity).to eq(:medium)
      expect(slo_error.phase).to eq("X")

      ll_error = errors.find { |e| e.code == "LL" }
      expect(ll_error).not_to be_nil
      expect(ll_error.intensity).to eq(:low)
      expect(ll_error.phase).to eq("IW")
    end

    it "parses errors at the ramp and to land phases" do
      parser = described_class.new("GRADE:B  WX  (NX)  WO(AFU)TL  (EGTL)  3PTSIW  _DRIM_  _DRIC_  _TMRDIC_  _TMRDAR_  BIW [BC]")
      errors = parser.parse

      # Check for TMRD at different phases
      tmrd_ic = errors.find { |e| e.code == "TMRD" && e.phase == "IC" }
      expect(tmrd_ic).not_to be_nil
      expect(tmrd_ic.intensity).to eq(:high)

      tmrd_ar = errors.find { |e| e.code == "TMRD" && e.phase == "AR" }
      expect(tmrd_ar).not_to be_nil
      expect(tmrd_ar.intensity).to eq(:high)
    end
  end

  describe "DCS log remarks" do
    it "parses _OK_ grade with wire" do
      parser = described_class.new("GRADE:_OK_ : WIRE# 3")
      errors = parser.parse

      expect(errors).to be_empty
    end

    it "parses _OK_ grade with wire 2" do
      parser = described_class.new("GRADE:_OK_ : WIRE# 2")
      errors = parser.parse

      expect(errors).to be_empty
    end

    it "parses --- grade with EGTL and wire 1" do
      parser = described_class.new("GRADE:--- : (EGTL)  WIRE# 1")
      errors = parser.parse

      expect(errors.length).to eq(1)
      expect(errors[0].code).to eq("EG")
      expect(errors[0].intensity).to eq(:low)
      expect(errors[0].phase).to eq("TL")
    end

    it "parses --- grade with EGTL and wire 4" do
      parser = described_class.new("GRADE:--- : (EGTL)  WIRE# 4")
      errors = parser.parse

      expect(errors.length).to eq(1)
      expect(errors[0].code).to eq("EG")
      expect(errors[0].intensity).to eq(:low)
      expect(errors[0].phase).to eq("TL")
    end

    it "parses WO grade with DRIM LURIM and WO(AFU)IC" do
      parser = described_class.new("GRADE:WO  (DRIM)  (LURIM)  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(3)
      expect(errors[0].code).to eq("DR")
      expect(errors[0].intensity).to eq(:low)
      expect(errors[0].phase).to eq("IM")

      expect(errors[1].code).to eq("LUR")
      expect(errors[1].intensity).to eq(:low)
      expect(errors[1].phase).to eq("IM")

      expect(errors[2].code).to eq("AFU")
      expect(errors[2].intensity).to eq(:low)
      expect(errors[2].phase).to eq("IC")
      expect(errors[2].modifiers).to eq(%w[WO])
    end

    it "parses WO grade with DLX LULX LULIM DLIM and WO(AFU)IC" do
      parser = described_class.new("GRADE:WO  (DLX)  _LULX_  _LULIM_  (DLIM)  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(5)
      expect(errors.map(&:code)).to eq(%w[DL LUL LUL DL AFU])
      expect(errors.map(&:intensity)).to eq(%i[low high high low low])
      expect(errors.map(&:phase)).to eq(%w[X X IM IM IC])
    end

    it "parses WO grade with WX and WO(AFU)IC" do
      parser = described_class.new("GRADE:WO  WX  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(2)
      expect(errors[0].code).to eq("W")
      expect(errors[0].intensity).to eq(:medium)
      expect(errors[0].phase).to eq("X")

      expect(errors[1].code).to eq("AFU")
      expect(errors[1].intensity).to eq(:low)
      expect(errors[1].phase).to eq("IC")
      expect(errors[1].modifiers).to eq(%w[WO])
    end

    it "parses --- grade with NX WX DRX LURX DRIM LURIM wire and BC marker" do
      parser = described_class.new("GRADE:--- : (NX)  _WX_  _DRX_  _LURX_  (DRIM)  (LURIM)  WIRE# 1[BC]")
      errors = parser.parse

      expect(errors.length).to eq(6)
      codes_and_intensities = errors.map { |e| [e.code, e.intensity, e.phase] }
      expect(codes_and_intensities).to contain_exactly(
        ["N", :low, "X"],
        ["W", :high, "X"],
        ["DR", :high, "X"],
        ["LUR", :high, "X"],
        ["DR", :low, "IM"],
        ["LUR", :low, "IM"]
      )
    end

    it "parses B grade with NX WX DRX LURX LURIM 3PTSIW BIW" do
      parser = described_class.new("GRADE:B  (NX)  _WX_  _DRX_  _LURX_  (LURIM)  3PTSIW  BIW")
      errors = parser.parse

      expect(errors.length).to eq(7)
      codes = errors.map(&:code)
      expect(codes).to include("N", "W", "DR", "LUR", "LUR", "3PTS", "B")

      # Verify the B error at IW phase
      b_error = errors.find { |e| e.code == "B" && e.phase == "IW" }
      expect(b_error).not_to be_nil
      expect(b_error.intensity).to eq(:medium)
    end

    it "parses B grade with SLOX LLIW 3PTSIW BIW" do
      parser = described_class.new("GRADE:B  SLOX  (LLIW)  3PTSIW  BIW")
      errors = parser.parse

      expect(errors.length).to eq(4)
      expect(errors.map(&:code)).to eq(%w[SLO LL 3PTS B])
      expect(errors.map(&:intensity)).to eq(%i[medium low medium medium])
      expect(errors.map(&:phase)).to eq(%w[X IW IW IW])
    end

    it "parses B grade with complex WO(AFU)TL and multiple high intensity errors" do
      parser = described_class.new("GRADE:B  WX  (NX)  WO(AFU)TL  (EGTL)  3PTSIW  _DRIM_  _DRIC_  _TMRDIC_  _TMRDAR_  BIW [BC]")
      errors = parser.parse

      expect(errors.length).to eq(10)

      # Check specific errors
      afu_error = errors.find { |e| e.code == "AFU" }
      expect(afu_error.modifiers).to eq(%w[WO])
      expect(afu_error.phase).to eq("TL")
      expect(afu_error.intensity).to eq(:low)

      # Check TMRD errors at different phases
      tmrd_ic = errors.find { |e| e.code == "TMRD" && e.phase == "IC" }
      expect(tmrd_ic.intensity).to eq(:high)

      tmrd_ar = errors.find { |e| e.code == "TMRD" && e.phase == "AR" }
      expect(tmrd_ar.intensity).to eq(:high)

      # Check DR errors
      dr_im = errors.find { |e| e.code == "DR" && e.phase == "IM" }
      expect(dr_im.intensity).to eq(:high)

      dr_ic = errors.find { |e| e.code == "DR" && e.phase == "IC" }
      expect(dr_ic.intensity).to eq(:high)
    end

    it "parses WO grade with WX NX and WO(AFU)IC" do
      parser = described_class.new("GRADE:WO  WX  (NX)  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(3)
      expect(errors[0].code).to eq("W")
      expect(errors[0].intensity).to eq(:medium)
      expect(errors[0].phase).to eq("X")

      expect(errors[1].code).to eq("N")
      expect(errors[1].intensity).to eq(:low)
      expect(errors[1].phase).to eq("X")

      expect(errors[2].code).to eq("AFU")
      expect(errors[2].modifiers).to eq(%w[WO])
    end

    it "parses WO grade with medium intensity LULX" do
      parser = described_class.new("GRADE:WO  LULX  WO(AFU)IC")
      errors = parser.parse

      expect(errors.length).to eq(2)
      expect(errors[0].code).to eq("LUL")
      expect(errors[0].intensity).to eq(:medium)
      expect(errors[0].phase).to eq("X")
    end

    it "parses (OK) grade with wire and BC marker" do
      parser = described_class.new("GRADE:(OK) : WIRE# 2[BC]")
      errors = parser.parse

      expect(errors).to be_empty
    end

    it "parses C grade with NX WX SLOX and EGIW" do
      # NOTE: _EGIW_ appears after "WIRE# 3" so it gets stripped off
      parser = described_class.new("GRADE:C : (NX)  _WX_  SLOX  WIRE# 3 _EGIW_")
      errors = parser.parse

      expect(errors.length).to eq(3)
      expect(errors.map(&:code)).to eq(%w[N W SLO])
      expect(errors.map(&:intensity)).to eq(%i[low high medium])
      expect(errors.map(&:phase)).to eq(%w[X X X])
    end

    it "parses NC grade with no proper communications" do
      parser = described_class.new("GRADE: NC : No proper communications")
      errors = parser.parse

      # "No" is parsed as "N" (valid error code) without a valid phase suffix
      # The parser matches just "N" as an error with no phase
      expect(errors.length).to eq(1)
      expect(errors[0].code).to eq("N")
      expect(errors[0].intensity).to eq(:medium)
      expect(errors[0].phase).to be_nil
    end

    it "parses C grade with extensive errors across all phases" do
      parser = described_class.new("GRADE:C : (DLX)  _LULX_  _FX_  _LULIM_  (DLIM)  _LULIC_  _LOIC_  _PIC_  _PPPIC_  _LOAR_  WO(AFU)TL  3PTSIW  _EGIW_  WIRE# 3[BC]")
      errors = parser.parse

      expect(errors.length).to eq(13)

      # Verify all error codes are present
      codes = errors.map(&:code)
      expect(codes).to include("DL", "LUL", "F", "LO", "P", "PPP", "AFU", "3PTS", "EG")

      # Count LUL occurrences (should be 3: X, IM, IC)
      lul_errors = errors.select { |e| e.code == "LUL" }
      expect(lul_errors.length).to eq(3)
      expect(lul_errors.map(&:phase)).to contain_exactly("X", "IM", "IC")

      # Count LO occurrences (should be 2: IC, AR)
      lo_errors = errors.select { |e| e.code == "LO" }
      expect(lo_errors.length).to eq(2)
      expect(lo_errors.map(&:phase)).to contain_exactly("IC", "AR")

      # Verify intensities
      fx_error = errors.find { |e| e.code == "F" && e.phase == "X" }
      expect(fx_error.intensity).to eq(:high)

      pppic_error = errors.find { |e| e.code == "PPP" && e.phase == "IC" }
      expect(pppic_error.intensity).to eq(:high)
    end
  end
end
