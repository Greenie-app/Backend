# A pilot is a member of a Squadron that flies Passes. Pilots are uniquely
# identified by their name and have no other characteristics.
#
# Associations
# ------------
#
# | `squadron` | The {Squadron} this pilot belongs to. |
# | `passes` | The {Pass}es this pilot flew. |
#
# Properties
# ----------
#
# | `name` | The pilot name. If generated from a dcs.log file, it will be the pilot's DCS multiplayer callsign. |

class Pilot < ApplicationRecord
  belongs_to :squadron
  has_many :passes, dependent: :delete_all

  validates :name,
            presence:   true,
            length:     {maximum: 100},
            uniqueness: {scope: :squadron_id}

  # @private
  def to_param() name end
end
