# frozen_string_literal: true

require "rails_helper"

RSpec.describe FileProcessorJob do
  let(:logfile) { create :logfile }

  it "processes the file and increments completed_count" do
    expect(logfile.completed_files).to eq(0)
    described_class.new.perform(logfile.files.first)
    expect(logfile.completed_files).to eq(1)
  end

  it "processes increments failed_count for errors" do
    skip "No support in GoodJob"
  end
end
