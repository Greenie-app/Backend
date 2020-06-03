require 'rails_helper'

RSpec.describe Logfile, type: :model do
  include ActiveJob::TestHelper

  describe '#process!' do
    let(:squadron) { FactoryBot.create :squadron }
    let(:logfile) { FactoryBot.create :logfile, squadron: squadron }

    it "processes log files and creates passes" do
      logfile.tap do |logfile|
        perform_enqueued_jobs { logfile.process! }
      end

      expect(squadron.passes.count).to eq(12)

      first_pass = squadron.passes.order(time: :asc).first!
      expect(first_pass).to be_technique_waveoff
      expect(first_pass).not_to be_trap
      expect(first_pass.score).to eq(1)
      expect(first_pass.wire).to be_nil
      expect(first_pass.notes).to eq("GRADE:WO  (DRIM)  (LURIM)  WO(AFU)IC")
      expect(first_pass.pilot).to be_nil
      expect(first_pass.aircraft_type).to be_nil
      expect(first_pass.ship_name).to be_nil

      last_pass = squadron.passes.order(time: :desc).first!
      expect(last_pass).to be_cut
      expect(last_pass).to be_trap
      expect(last_pass.score).to eq(0)
      expect(last_pass.wire).to eq(3)
      expect(last_pass.notes).to eq("GRADE:C : (DLX)  _LULX_  _FX_  _LULIM_  (DLIM)  _LULIC_  _LOIC_  _PIC_  _PPPIC_  _LOAR_  WO(AFU)TL  3PTSIW  _EGIW_  WIRE# 3[BC]")
      expect(last_pass.pilot.name).to eq("Jambo72nd")
      expect(last_pass.pilot.squadron).to eq(squadron)
      expect(last_pass.aircraft_type).to be_nil
      expect(last_pass.ship_name).to eq("CVN-73")
    end
  end

  describe '#recalculate_state!' do
    let :logfile do
      FactoryBot.create :logfile, files: [
          Rails.root.join('spec', 'fixtures', 'dcs.log'),
          Rails.root.join('spec', 'fixtures', 'dcs.log'),
          Rails.root.join('spec', 'fixtures', 'dcs.log')
      ]
    end

    it "returns pending if no jobs have been completed yet" do
      logfile.recalculate_state!
      expect(logfile.state).to eq('pending')
    end

    it "returns in_progress if some jobs have been completed" do
      logfile.update_column :completed_files, 1
      logfile.recalculate_state!
      expect(logfile.state).to eq('in_progress')
    end

    it "returns complete if all jobs have been completed" do
      logfile.update_column :completed_files, 3
      logfile.recalculate_state!
      expect(logfile.state).to eq('complete')
    end

    it "returns failed if any job failed" do
      logfile.update_column :failed_files, 1
      logfile.recalculate_state!
      expect(logfile.state).to eq('failed')
    end
  end

  describe '#progress' do
    let :logfile do
      FactoryBot.create :logfile, files: [
          Rails.root.join('spec', 'fixtures', 'dcs.log'),
          Rails.root.join('spec', 'fixtures', 'dcs.log'),
          Rails.root.join('spec', 'fixtures', 'dcs.log'),
          Rails.root.join('spec', 'fixtures', 'dcs.log')
      ]
    end

    it "returns the progress as a fraction" do
      logfile.update_column :completed_files, 3
      expect(logfile.progress).to eq(0.75)
    end
  end
end
