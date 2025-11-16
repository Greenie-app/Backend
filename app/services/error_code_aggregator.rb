# frozen_string_literal: true

# Aggregates technique errors by code and calculates weighted scores.
#
# Errors are scored based on their intensity:
# - Low intensity: 0.5 points
# - Medium intensity: 1.0 points
# - High intensity: 2.0 points
#
# @example Aggregate errors from multiple passes
#   errors = [
#     TechniqueError.new(code: "LUL", intensity: :high, phase: "IM", modifiers: []),
#     TechniqueError.new(code: "LUL", intensity: :medium, phase: "IC", modifiers: []),
#     TechniqueError.new(code: "F", intensity: :low, phase: nil, modifiers: [])
#   ]
#   aggregator = ErrorCodeAggregator.new(errors)
#   aggregator.aggregate
#   # => [
#   #      { code: "LUL", score: 3.0, count: 2 },
#   #      { code: "F", score: 0.5, count: 1 }
#   #    ]
#
# @example Get top 3 errors
#   aggregator.top(3)
#   # => [first 3 errors sorted by score descending]
class ErrorCodeAggregator
  # @api private
  INTENSITY_SCORES = {
      low:    0.5,
      medium: 1.0,
      high:   2.0
  }.freeze
  private_constant :INTENSITY_SCORES

  # Creates a new aggregator for the given technique errors.
  #
  # @param technique_errors [Array<RemarksParser::TechniqueError>, nil] The errors to aggregate
  def initialize(technique_errors)
    @technique_errors = technique_errors || []
  end

  # Aggregates errors by code, calculating total score and count for each.
  #
  # @return [Array<Hash>] Array of hashes with :code, :score, and :count keys,
  #   sorted by score in descending order
  def aggregate
    @technique_errors.
        group_by(&:code).
        transform_values do |errors|
      {
          score: errors.sum { |e| INTENSITY_SCORES[e.intensity] || 1.0 },
          count: errors.size
      }
    end.
        map do |code, data|
      {
          code:,
          **data
      }
    end.
        sort_by { |item| -item[:score] }
  end

  # Returns the top N errors by score.
  #
  # @param n [Integer] The number of top errors to return
  # @return [Array<Hash>] The top N aggregated errors
  def top(n=5) = aggregate.first(n)
end
