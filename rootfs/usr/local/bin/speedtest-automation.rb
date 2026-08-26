#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs a speedtest every few minutes while the automation is armed.
#
# The app is driven through the AT-SPI accessibility bus: widgets are looked up
# by their label and activated directly.
#
# The automation runs while the clipboard holds "RUN" or the file /RUN exists,
# and only between TIME_START and TIME_END.

$LOAD_PATH.unshift("/usr/local/lib")

require "breitbandmessung/measurement"

# Seconds to wait after a measurement was started. A measurement itself takes
# about a minute, the app enforces a waiting period before the next one.
MEASUREMENT_PAUSE = 360
# The trigger file, as an alternative to the clipboard method.
TRIGGER_FILE = "/RUN"
TRIGGER_VALUE = "RUN"

def log(message)
  puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
end

# Reads the X11 primary selection, which is what the noVNC clipboard panel writes into.
def clipboard
  value = IO.popen(["xclip", "-o"], err: File::NULL, &:read)
  $?&.success? ? value.to_s.strip : ""
rescue SystemCallError
  ""
end

def armed?
  File.exist?(TRIGGER_FILE) || clipboard == TRIGGER_VALUE
end

def parse_time(value, name)
  hours, minutes = value.to_s.split(":", 2)
  unless /\A\d{1,2}\z/.match?(hours) && /\A\d{1,2}\z/.match?(minutes)
    abort "#{name} is #{value.inspect}, expected HH:MM"
  end

  Integer(hours, 10) * 60 + Integer(minutes, 10)
end

def within_window?(now, window)
  minutes = now.hour * 60 + now.min
  window.cover?(minutes)
end

def main
  $stdout.sync = true

  start_time = ENV.fetch("TIME_START", "13:00")
  end_time = ENV.fetch("TIME_END", "23:00")
  window = parse_time(start_time, "TIME_START")..parse_time(end_time, "TIME_END")
  # Seconds between two checks of the trigger:
  poll_interval = Integer(ENV.fetch("POLL_INTERVAL", "15")) rescue 15
  log "automation service started, measurement window is #{start_time} - #{end_time}"

  app = nil

  loop do
    sleep poll_interval

    unless armed?
      log "not armed. Put #{TRIGGER_VALUE.inspect} in the clipboard or create #{TRIGGER_FILE} to start."
      next
    end

    now = Time.now
    unless within_window?(now, window)
      log "outside the measurement window of #{start_time} - #{end_time}, not measuring."
      next
    end

    # Looked up once and reused; the reference stays valid until the app
    # restarts, which is when the next lookup is needed anyway. The app is
    # already running by the time the automation is armed, so a short timeout
    # is enough and keeps the loop responsive.
    app ||= Breitbandmessung::Accessibility.application(timeout: 10)
    unless app
      log "the app is not on the accessibility bus, retrying."
      next
    end

    log "starting a measurement"
    begin
      result = Breitbandmessung::Measurement.start(app)
    rescue StandardError => e
      log "measurement failed: #{e.class}: #{e.message}"
      app = nil
      next
    end

    if result.started?
      log "#{result}, waiting #{MEASUREMENT_PAUSE / 60} minutes"
      sleep MEASUREMENT_PAUSE
    else
      log "could not start a measurement: #{result}"
    end
  end
end

main if $PROGRAM_NAME == __FILE__
