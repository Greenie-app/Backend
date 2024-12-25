# frozen_string_literal: true

require "rails_helper"

RSpec.describe PassesChannel do
  let(:squadron) { create :squadron }

  before :each do
    @pass = create(:pass, with_pilot: true, squadron:)

    stub_connection current_squadron: squadron
    subscribe
  end

  it "confirms the subscription" do
    expect(subscription).to be_confirmed
  end

  it "streams pass creates" do
    expect { create :pass, with_pilot: true, squadron: }.
        to(have_broadcasted_to(squadron).with do |payload|
             expect(payload).to match_json_expression(
                                  id:            Integer,
                                  time:          String,
                                  ship_name:     String,
                                  aircraft_type: String,
                                  grade:         String,
                                  score:         Object,
                                  trap:          Boolean,
                                  wire:          Object,
                                  notes:         String,
                                  destroyed?:    false,
                                  pilot:         String,
                                  squadron:      {
                                      id:                 squadron.id,
                                      name:               squadron.name,
                                      username:           squadron.username,
                                      email:              squadron.email,
                                      created_at:         String,
                                      updated_at:         String,
                                      boarding_rate:      squadron.boarding_rate,
                                      unknown_pass_count: squadron.unknown_pass_count,
                                      image:              {
                                          url: String
                                      }
                                  }
                                )
           end)
  end

  it "streams pass updates" do
    expect { @pass.update! notes: "new notes" }.
        to(have_broadcasted_to(squadron).with do |payload|
             expect(payload).to match_json_expression(
                                  id:            @pass.id,
                                  time:          String,
                                  ship_name:     @pass.ship_name,
                                  aircraft_type: @pass.aircraft_type,
                                  grade:         @pass.grade,
                                  score:         @pass.score&.to_s,
                                  trap:          @pass.trap,
                                  wire:          @pass.wire,
                                  notes:         "new notes",
                                  destroyed?:    false,
                                  pilot:         @pass.pilot&.name,
                                  squadron:      {
                                      id:                 squadron.id,
                                      name:               squadron.name,
                                      username:           squadron.username,
                                      email:              squadron.email,
                                      created_at:         String,
                                      updated_at:         String,
                                      boarding_rate:      squadron.boarding_rate,
                                      unknown_pass_count: squadron.unknown_pass_count,
                                      image:              {
                                          url: String
                                      }
                                  }
                                )
           end)
  end

  it "streams pass deletes" do
    expect { @pass.destroy! }.
        to(have_broadcasted_to(squadron).with do |payload|
             expect(payload).to match_json_expression(
                                  {
                                      id:         @pass.id,
                                      destroyed?: true
                                  }.ignore_extra_keys!
                                )
           end)
  end
end
