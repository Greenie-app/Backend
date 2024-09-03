# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogfilesChannel do
  let(:squadron) { create :squadron }

  before :each do
    @logfile = create(:logfile, squadron:)

    stub_connection current_squadron: squadron
    subscribe
  end

  it "confirms the subscription" do
    expect(subscription).to be_confirmed
  end

  it "streams logfile creates" do
    expect { create :logfile, squadron: }.
        to(have_broadcasted_to(squadron).exactly(:twice).with do |payload|
             expect(payload).to match_json_expression(
                                  id:         Integer,
                                  state:      "pending",
                                  progress:   0.0,
                                  created_at: String,
                                  destroyed?: false,
                                  files:      [{
                                      filename:  "dcs.log",
                                      byte_size: Integer
                                  }]
                                )
           end)
  end
end
