# frozen_string_literal: true

require_relative "accessibility"

module Breitbandmessung
  # Starts one measurement of the "Messkampagne".
  #
  # The app is expected to already sit on the campaign screen, showing the
  # "Messung durchführen" button. Accepting the terms of use and entering the
  # tariff details is a one-off the user does by hand before arming the
  # automation, so none of that is handled here.
  module Measurement
    START_LABEL = "Messung durchführen"
    CONFIRM_LABEL = "Messung starten"

    Result = Struct.new(:started, :detail) do
      def started? = started

      def to_s = detail
    end

    module_function

    def start(app)
      button = app.find(name: START_LABEL, role: :button, showing: true)
      unless button
        return Result.new(false, "no '#{START_LABEL}' button on screen, " \
                                 "leave the app on the Messkampagne screen")
      end

      # While the app counts down the waiting period between two measurements the button is greyed out.
      return Result.new(false, "waiting period, '#{START_LABEL}' is greyed out") unless button.enabled?

      button.click

      confirm = app.wait_for(name: CONFIRM_LABEL, role: :button, showing: true, timeout: 15)
      return Result.new(false, "the requirements screen did not open") unless confirm

      tick_requirements(app)
      confirm.click

      # The requirements screen closes once the measurement is under way. It
      # stays open while the app is still counting down a waiting period,
      # which is the case the old script silently clicked into.
      if gone?(app, CONFIRM_LABEL)
        Result.new(true, "measurement started")
      else
        Result.new(false, "still on the requirements screen, probably a waiting period")
      end
    end

    # The requirement checkboxes are toggles: clicking one that is already
    # ticked would clear it again, so only the unticked ones are touched.
    def tick_requirements(app)
      boxes = app.find_all(role: :check_box, showing: true)
      pending = boxes.reject(&:checked?)
      puts "confirming #{pending.size} of #{boxes.size} requirement checkboxes"
      pending.each(&:click)
    end

    def gone?(app, label, timeout: 15)
      deadline = Node.monotonic_time + timeout
      loop do
        return true unless app.find(name: label, role: :button, showing: true)
        return false if Node.monotonic_time >= deadline

        sleep 1
      end
    end
  end
end
