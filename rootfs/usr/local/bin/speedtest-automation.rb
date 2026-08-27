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

# The trigger file, as an alternative to the clipboard method.
TRIGGER_FILE = "/RUN"
TRIGGER_VALUE = "RUN"

# logs without repeats
def log(message)
  return if message == $last_logged

  $last_logged = message
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

# Runs one attempt and returns what happened, as a line for the log.
#
# Everything that touches the accessibility bus happens in a short-lived child
# process. A widget the app has just discarded makes libatspi read from a null
# pointer, which is a segfault rather than an exception, so it cannot be
# rescued - only kept away from the service. The parent never speaks to the bus
# itself, so a crash costs one attempt instead of the whole automation.
def attempt_measurement
  reader, writer = IO.pipe

  pid = fork do
    reader.close
    app = Breitbandmessung::Accessibility.application(timeout: 10)
    writer.write(app ? Breitbandmessung::Measurement.start(app).to_s
                     : "the app is not on the accessibility bus")
    writer.close
    exit!(0)
  rescue StandardError => e
    writer.write("measurement failed: #{e.class}: #{e.message}")
    writer.close
    exit!(0)
  end

  writer.close
  detail = reader.read
  reader.close
  Process.waitpid(pid)

  detail.empty? ? "the app's widget tree changed mid-read, retrying" : detail
end

def main
  $stdout.sync = true

  start_time = ENV.fetch("TIME_START", "13:00")
  end_time = ENV.fetch("TIME_END", "23:00")
  window = parse_time(start_time, "TIME_START")..parse_time(end_time, "TIME_END")
  # Seconds between two checks of the trigger:
  poll_interval = Integer(ENV.fetch("POLL_INTERVAL", "60")) rescue 60
  log "automation service started, measurement window is #{start_time} - #{end_time}"

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

    # No pause after a measurement: the app greys the button out for as long as
    # it wants to wait, and hides it entirely while a measurement runs, so it
    # already states the timing far more precisely than a fixed interval could.
    log attempt_measurement
  end
end

main if $PROGRAM_NAME == __FILE__
