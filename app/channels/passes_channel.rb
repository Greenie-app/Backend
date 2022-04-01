# Action Cable channel for transmitting changes to {Pass} records.

class PassesChannel < ApplicationCable::Channel

  # @private
  def subscribed
    stream_for current_squadron, coder: nil
  end

  # @private
  module Coder
    extend self

    # @private
    def encode(pass, boarding_rate: nil, unknown_pass_count: nil)
      ApplicationController.render partial: 'passes/pass',
                                   locals:  {
                                       pass:,
                                       include_squadron:   true,
                                       boarding_rate:,
                                       unknown_pass_count:
                                   }
    end
  end
end
