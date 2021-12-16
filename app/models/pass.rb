# A pass is an attempt by a pilot at landing at a carrier. A pass can result in
# either a trap (where a wire is caught and the airplane stops) or a miss. A
# miss is either a bolter (where the aircraft touches down on the deck but does
# not catch a wire, or does not stop after catching a wire) or a waveoff (where
# the aircraft is commanded by the LSO to reject the approach). A waveoff can be
# a technique waveoff (caused by poor pilot technique), a foul-deck waveoff
# (which is not the fault of the pilot), or an own waveoff (where the pilot
# elects to reject the approach without having been told to do so by the LSO).
#
# Each pass is given a grade, depending on the quality of the pilot's approach.
# The grades for a trap are, from best to worst: `_OK_`, `OK`, `(OK)`, `—`, and
# `C`. If the pilot waves off, the grade would be `WO` or `OWO`. A bolter would
# be graded as `B`.
#
# These grades all have associated scores. `_OK_` is five points, down to `C`
# which is zero points. A wave-off is 1 point and a bolter is 2.5 points.
# Foul-deck waveoffs do not count towards the point total. Own waveoffs are at
# the discretion of the LSO.
#
# To that end, this model calculates scores automatically, but all scores and
# other values can be adjusted by the LSO.
#
# Along with calculating score, this model also calculates squadron boarding
# rate. Boarding rate is the fraction of successful traps compared to the total
# number of qualifying passes. Only some passes are used as part of the boarding
# rate calculation. (For example, a foul-deck waveoff would not help or hurt
# boarding rate.)
#
# Passes should typically be associated with a Pilot, but not all dcs.log files
# properly record which pilots flew which passes. To that end, it is possible to
# have passes not associated with any pilot. The website user has the
# opportunity to properly assign these unassigned passes after the logfile is
# uploaded.
#
# Associations
# ------------
#
# | `squadron` | The {Squadron} this pass belongs to. |
# | `pilot` | The {Pilot} that flew this pass (or `nil` if the logfile processor was unable to determine the pilot). |
#
# Properties
# ----------
# | `time` | The UTC time when the pass was flown. |
# | `ship_name` | The name of the aircraft carrier the pass was flown for. |
# | `aircraft_type` | The type of aircraft flown. This must match the DCS internal name for the aircraft (as used in the `Input` directory) to properly link to the front-end image. |
# | `grade` | The pass grade (such as "fair"). |
# | `score` | The point score for the pass (such as 3.0). |
# | `trap` | `true` if this pass counts in favor of boarding rate, `false` if it counts against, or `nil` if it doesn't apply to boarding rate. |
# | `wire` | Which wire was caught. |
# | `notes` | Additional LSO notes. Typically formatted using the standard LSO shorthand. |

class Pass < ApplicationRecord
  enum grade: {cut: 0, no_grade: 1, bolter: 2, fair: 3, ok: 4, perfect: 5, technique_waveoff: 6, foul_deck_waveoff: 7, pattern_waveoff: 8, own_waveoff: 9}

  belongs_to :squadron
  belongs_to :pilot, optional: true

  validates :time, presence: true
  validates :ship_name,
            length:    {maximum: 20},
            allow_nil: true
  validates :aircraft_type,
            length:    {maximum: 20},
            allow_nil: true
  validates :grade,
            presence: true
  validates :score,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 5},
            allow_nil:    true
  validates :wire,
            numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 4},
            allow_nil:    true
  validates :notes,
            length:    {maximum: 200},
            allow_nil: true
  validate :pilot_must_be_same_squadron

  extend SetNilIfBlank
  set_nil_if_blank :ship_name, :aircraft_type, :notes

  before_validation :set_defaults, on: :create
  after_commit { PassesChannel.broadcast_to squadron, PassesChannel::Coder.encode(self) }
  after_destroy_commit { PassesChannel.broadcast_to squadron, PassesChannel::Coder.encode(self) }

  # @private
  def self.create_from_log_entry(squadron, timestamp, grade, pilot: nil, ship: nil, aircraft: nil)
    pilot_record = pilot ? squadron.pilots.find_or_create_by!(name: pilot) : nil
    squadron.passes.create!(pilot_id:      pilot_record&.id,
                            squadron:      squadron,
                            time:          timestamp,
                            ship_name:     ship,
                            aircraft_type: aircraft,
                            grade:         grade_for_notes(grade),
                            wire:          wire_for_notes(grade),
                            notes:         grade)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.info "Couldn't create Pass from log entry: #{e.record.errors.full_messages.inspect}"
  end

  private

  def set_defaults
    self.trap  = default_trap if self.trap.nil?
    self.score ||= default_score
  end

  def default_trap
    !bolter? &&
      !technique_waveoff? && !foul_deck_waveoff? && !pattern_waveoff? &&
      !own_waveoff?
  end

  def default_score
    case grade
      when 'perfect' then 5.0
      when 'ok' then 4.0
      when 'fair' then 3.0
      when 'bolter' then 2.5
      when 'no_grade' then 2.0
      when 'technique_waveoff' then 1.0
      when 'cut' then 0.0
      else nil
    end
  end

  def self.grade_for_notes(notes)
    matches = notes.match(/GRADE:(.+?)\s/) or return nil
    case matches[1].strip
      when '_OK_' then :perfect
      when 'OK' then :ok
      when '(OK)' then :fair
      when 'B' then :bolter
      when '---' then :no_grade
      when 'WO' then waveoff_grade(notes)
      when 'C' then :cut
      else nil
    end
  end
  private_class_method :grade_for_notes

  def self.waveoff_grade(notes)
    matches = notes.match(/WO\((.+?)\)/) or return :technique_waveoff
    return matches[1] == 'FD' ? :foul_deck_waveoff : :technique_waveoff
  end
  private_class_method :waveoff_grade

  def self.wire_for_notes(notes)
    matches = notes.match(/WIRE# (\d)/) or return nil
    return matches[1].to_i
  end
  private_class_method :wire_for_notes

  def pilot_must_be_same_squadron
    return unless pilot

    if pilot.squadron_id != squadron_id
      errors.add :pilot_id, :unknown
    end
  end
end
