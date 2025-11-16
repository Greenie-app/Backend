# frozen_string_literal: true

# Parses LSO (Landing Signal Officer) remarks strings into structured error objects.
#
# LSO remarks follow a specific format where technique errors are encoded with:
# - Error codes (e.g., "LUL" for "Lined up left")
# - Intensity markers: parentheses for low `(XXX)`, underscores for high `_XXX_`, none for medium
# - Phase suffixes (e.g., "IM" for "In the middle", "IC" for "In close")
# - Modifiers (e.g., "WO" for waveoff)
#
# @example Parse a simple remark
#   parser = RemarksParser.new("GRADE:WO  (DRIM)  _LULX_  WO(AFU)IC")
#   errors = parser.parse
#   # => [TechniqueError(code: "DR", intensity: :low, phase: "IM", modifiers: []),
#   #     TechniqueError(code: "LUL", intensity: :high, phase: "X", modifiers: []),
#   #     TechniqueError(code: "AFU", intensity: :low, phase: "IC", modifiers: ["WO"])]
#
class RemarksParser

  # Represents a single technique error extracted from LSO remarks.
  #
  # @!attribute code
  #   @return [String] The error code (e.g., "LUL", "F", "H")
  # @!attribute intensity
  #   @return [Symbol] The intensity level (:low, :medium, or :high)
  # @!attribute phase
  #   @return [String, nil] The flight phase code (e.g., "X", "IM", "IC")
  # @!attribute modifiers
  #   @return [Array<String>] Additional modifiers (e.g., ["WO"])
  TechniqueError = Struct.new(:code, :intensity, :phase, :modifiers, keyword_init: true)

  ERROR_CODES = %w[
      / \\ ^ 3PTS AA ACC AFU B C CB CD CH CO CU DD DEC DL DN DR DU EG F FD GLI H HO
      LIG LL LLU LLWD LNF LO LR LRWD LTR LU LUL LUR LWD N NC ND NEA NEP NERD NERR
      NESA NH NSU OR OS OSCB P PD PNU PPP ROT RR RTL RUD RUF RWD S SD SHT SKD SLO
      SRD ST TCA TMA TMP TMRD TMRR TTL TTS TWA W WU XCTL
  ].freeze
  private_constant :ERROR_CODES

  PHASE_CODES = %w[X BC IM IC AR TL IW AW].freeze
  private_constant :PHASE_CODES

  MODIFIERS = %w[WO].freeze
  private_constant :MODIFIERS

  # Creates a new parser for the given LSO remarks string.
  #
  # @param remarks [String, nil] The raw LSO remarks string to parse
  def initialize(remarks)
    @remarks = remarks || ""
  end

  # Parses the remarks string into an array of technique errors.
  #
  # @return [Array<TechniqueError>] The parsed technique errors
  def parse
    extract_content(@remarks).
        scan(/\S+/).
        filter_map { |token| parse_token(token) }
  end

  private

  def extract_content(remarks)
    remarks.sub(/\AGRADE:[^:\s]*\s*:?\s*/, ""). # Remove "GRADE:XXX :" prefix if present (with optional colon separator)
        sub(/\s*WIRE#.*\z/, ""). # Remove "WIRE# X" suffix and anything after
        sub(/\s*\[BC\]\s*\z/, ""). # Remove trailing [BC] markers
        strip
  end

  def parse_token(token)
    # Skip pure grade tokens like "WO", "B", "C", etc. at the start
    return nil if token.match?(/\A(WO|B|C|OK|_OK_|\(OK\)|---|NC)\z/)

    # Check for high intensity (underscores): _XXXPHASE_
    if (match = token.match(/\A_([^_]+)_\z/))
      return parse_error_phase(match[1], :high)
    end

    # Check for low intensity (parentheses): (XXXPHASE)
    if (match = token.match(/\A\(([^)]+)\)\z/))
      return parse_error_phase(match[1], :low)
    end

    # Check for modifier + low intensity with phase suffix: WO(XXX)PHASE
    if (match = token.match(/\A(\w+)\(([^)]+)\)(\w+)\z/))
      modifier     = match[1]
      inner_code   = match[2]
      phase_suffix = match[3]
      if MODIFIERS.include?(modifier)
        return parse_error_phase("#{modifier}#{inner_code}#{phase_suffix}", :low)
      end
    end

    # Check for modifier + low intensity: WO(XXXPHASE)
    if (match = token.match(/\A(\w+)\(([^)]+)\)\z/))
      modifier = match[1]
      if MODIFIERS.include?(modifier)
        return parse_error_phase("#{modifier}#{match[2]}", :low)
      end
    end

    # Check for medium intensity (no decoration)
    # But skip WIRE#, grades, and other non-error tokens
    return nil if token.match?(/\A(WIRE#|GRADE:)/i)

    # Medium intensity error code with phase
    parse_error_phase(token, :medium)
  end

  def parse_error_phase(code_with_phase, intensity)
    modifiers = []

    # Extract modifiers like WO at the beginning
    remaining = code_with_phase
    MODIFIERS.each do |mod|
      if remaining.start_with?(mod)
        modifiers << mod
        remaining = remaining[mod.length..]
      end
    end

    # Try to match error code + phase
    # Sort error codes by length (longest first) to match correctly
    sorted_codes = ERROR_CODES.sort_by { |k| -k.length }

    error_code = nil
    phase      = nil

    sorted_codes.each do |code|
      next unless remaining.start_with?(code)

      error_code = code
      phase_part = remaining[code.length..]

      # Check if the remaining part is a valid phase
      if phase_part.empty?
        phase = nil
        break
      elsif PHASE_CODES.include?(phase_part)
        phase = phase_part
        break
      else
        # Try to find a matching phase (for partial matches)
        PHASE_CODES.sort_by { |k| -k.length }.each do |p|
          if phase_part == p
            phase = p
            break
          end
        end
        break if phase
      end
    end

    return nil unless error_code

    TechniqueError.new code:      error_code,
                       intensity: intensity,
                       phase:     phase,
                       modifiers: modifiers
  end
end
