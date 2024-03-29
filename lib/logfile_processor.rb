# frozen_string_literal: true

# This class processes dcs.log files, detecting grades generated by the AI LSO
# and creating {Pass}es for them, associating them with {Pilot}s if possible.
#
# See {file:README.md} for limitations.

class LogfileProcessor

  # @return [Logfile] record The Logfile record that the dcs.log file belongs to.
  attr_reader :record

  # @return [ActiveStorage::Attachment] file The dcs.log file to process.
  attr_reader :file

  # Creates a new processor instance to process a dcs.log file.
  #
  # @param [Logfile] record The Logfile record that the dcs.log file belongs to.
  # @param [ActiveStorage::Attachment] file The dcs.log file to process.

  def initialize(record, file)
    @file     = file
    @record = record
  end

  # Processes the dcs.log file, creating Passes and Pilots as necessary. They
  # will be associated with the same Squadron as the Logfile given to this
  # processor.

  def process!
    @pilot_names    = {}
    @aircraft_types = {}

    @last_landing = nil

    Rails.logger.tagged("LogfileProcessor:#{record.id}") do
      file.open do |opened_file|
        File.read(opened_file.path).each_line(chomp: true).with_index do |line, index|
          (parts = parse_line(line, index + 1)) or next
          process_line(*parts)
        end
      end
    end
  end

  private

  def parse_line(line, _num)
    timestamp = Time.zone.strptime(line[0, 23], "%Y-%m-%d %H:%M:%S.%L")
    level     = line[24, 7].strip
    message   = line[32..]

    return [timestamp, level, message]
  rescue ArgumentError
    return nil
  end

  def process_line(timestamp, _level, message)
    process_spawn_line(message)
    process_under_control_line(message)
    process_landing_line(timestamp, message)
    process_lso_line(timestamp, message)
  end

  def process_spawn_line(message)
    matches = message.match(/^DCS: MissionSpawn:spawnLocalPlayer (?<id>\d+),(?<type>.+)$/) or return
    @aircraft_types[matches[:id].to_i] = matches[:type]
  end

  def process_under_control_line(message)
    matches = message.match(/^Scripting: event:type=under control,initiatorPilotName=(?<name>.+?),target=.+?,t=.+?,targetMissionID=(?<id>\d+),$/) or return
    @pilot_names[matches[:id].to_i] = matches[:name]
  end

  def process_landing_line(timestamp, message)
    if (matches = message.match(/^Scripting: event:type=land,initiatorPilotName=(?<name>.+?),place=(?<ship>.+?),t=[0-9.]+,initiatorMissionID=(?<id>\d+),$/))
      @last_landing = {timestamp:, name: matches[:name], ship: matches[:ship], id: matches[:id].to_i}
    elsif /^Scripting: event:place=.+?,t=[0-9.]+,type=land,initiatorMissionID=\d+,$/.match?(message)
      @last_landing = {timestamp:, ai: true}
    end
  end

  def process_lso_line(timestamp, message)
    matches = message.match(/^Scripting: event:place=LSO: (?<grade>.+),t=[0-9.]+,type=comment,$/) or return
    process_grade timestamp, matches[:grade].strip
  end

  def process_grade(timestamp, grade)
    landing = (@last_landing && @last_landing[:timestamp] > timestamp - 5.seconds) ? @last_landing : nil
    return if landing && landing[:ai]

    pilot    = landing ? landing[:name] : nil
    aircraft = landing ? @aircraft_types[landing[:id]] : nil

    Pass.create_from_log_entry record.squadron,
                               timestamp, grade,
                               pilot:,
                               ship:     landing ? landing[:ship] : nil,
                               aircraft:
  end
end
