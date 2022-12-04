# frozen_string_literal: true

# A Squadron is an account that can log into the website, create Passes flown by
# Pilots, and view those passes on a greenie board. Squadron authentication is
# handled by Devise. There is one account shared by the whole squadron,
# represented by this model.
#
# Squadrons are authenticated using the `username` property and their password.
# They can also be uniquely identified by `email`, but that is only used for
# reset-password links.
#
# Associations
# ------------
#
# | `pilots` | The {Pilot}s in this squadron. |
# | `passes` | The {Pass}es flown by the pilots in this squadron. |
# | `logfiles` | The {Logfile}s uploaded for this squadron. |
#
# Properties
# ----------
#
# | `name` | The human-facing name for the squadron. |
# | `username` | The username used to log in as this squadron. |
# | `email` | An email address to use for emailing reset-password links. |

class Squadron < ApplicationRecord
  #noinspection RubyConstantNamingConvention
  Devise::Models::JWTAuthenticatable = Devise::Models::JwtAuthenticatable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JWTBlacklist

  has_many :pilots, dependent: :delete_all
  has_many :passes, dependent: :delete_all
  has_many :logfiles, dependent: :destroy

  has_one_attached :image

  validates :name,
            presence: true,
            length:   {maximum: 100}
  validates :username,
            presence:   true,
            uniqueness: {case_sensitive: false},
            length:     {maximum: 20},
            format:     {with: /\A[a-z0-9_-]+\z/i}
  validates :image,
            content_type: %r{\Aimage/.*\z},
            size:         {less_than: 100.megabytes}

  # @private
  def jwt_payload
    {u: username}
  end

  def boarding_rate(days=50)
    matching_passes = passes.where(Pass.arel_table[:time].gteq(days.days.ago.beginning_of_day))

    attempts = matching_passes.where(Pass.arel_table[:trap].not_eq(nil)).count
    return nil if attempts.zero?

    traps = matching_passes.where(trap: true).count

    return traps.to_f / attempts
  end

  def unknown_pass_count
    passes.where(pilot_id: nil).count
  end

  def to_param = username
end
