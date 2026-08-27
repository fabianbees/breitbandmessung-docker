# frozen_string_literal: true

require "gobject-introspection"

# libatspi ships no Ruby gem, so it is loaded straight from the GObject
# introspection typelib provided by the gir1.2-atspi-2.0 package.
module Atspi
  LOADER = GObjectIntrospection::Loader.new(self)
  LOADER.load("Atspi")
end

module Breitbandmessung
  # A single widget in the accessibility tree.
  #
  # Every call crosses the accessibility bus and fails with a D-Bus error when
  # the widget disappears while the tree is being walked. Lookups therefore
  # treat an unreachable node as an empty subtree instead of letting the error
  # escape into the automation loop.
  class Node
    # Role names as AT-SPI reports them;
    # a push button is also a plain "button"
    ROLE_NAMES = {
      button: "button",
      check_box: "check box",
      dialog: "dialog",
      menu_item: "menu item",
      static: "static",
    }.freeze

    attr_reader :accessible

    def initialize(accessible)
      @accessible = accessible
    end

    def name
      accessible.name.to_s
    rescue StandardError
      ""
    end

    def role_name
      accessible.role_name.to_s
    rescue StandardError
      ""
    end

    def children
      accessible.child_count.times.filter_map do |index|
        child = accessible.get_child_at_index(index)
        Node.new(child) if child
      end
    rescue StandardError
      []
    end

    # The app is a single-page application: widgets belonging to a view that
    # is not on screen stay in the tree with SHOWING cleared. Matching on that
    # state keeps lookups from returning a button on a hidden tab.
    def showing?
      state?(Atspi::StateType::SHOWING)
    end

    def checked?
      state?(Atspi::StateType::CHECKED)
    end

    # A button the app has greyed out keeps SHOWING but loses SENSITIVE. That
    # is how a waiting period between two measurements looks from here, and
    # pressing such a button does nothing at all.
    def enabled?
      state?(Atspi::StateType::SENSITIVE)
    end

    def matches?(name: nil, role: nil, showing: false)
      return false if name && self.name != name
      return false if role && role_name != ROLE_NAMES.fetch(role)
      return false if showing && !showing?

      true
    end

    def find(name: nil, role: nil, showing: false)
      return self if matches?(name: name, role: role, showing: showing)

      children.each do |child|
        found = child.find(name: name, role: role, showing: showing)
        return found if found
      end
      nil
    end

    def find_all(role:, showing: false, into: [])
      into << self if matches?(role: role, showing: showing)
      children.each { |child| child.find_all(role: role, showing: showing, into: into) }
      into
    end

    # Views swap in asynchronously after a click, so a widget that is not there
    # yet is not necessarily missing.
    def wait_for(name: nil, role: nil, showing: false, timeout: 30)
      deadline = Node.monotonic_time + timeout
      loop do
        found = find(name: name, role: role, showing: showing)
        return found if found
        return nil if Node.monotonic_time >= deadline

        sleep 1
      end
    end

    # AT-SPI exposes activation as the widget's first action, which is "click"
    # for a button and "toggle" for a check box.
    def click
      return false unless accessible.action?

      action = accessible.action
      return false unless action.n_actions.positive?

      action.do_action(0)
    rescue StandardError => e
      warn "failed to activate #{self}: #{e.message}"
      false
    end

    def to_s
      "#{role_name} #{name.inspect}"
    end

    def self.monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    private

    def state?(state)
      accessible.state_set.contains(state)
    rescue StandardError
      false
    end
  end

  # Finds the Breitbandmessung application on the accessibility bus.
  module Accessibility
    # The app registers itself under its product name
    APP_NAME = /breitbandmessung/i

    module_function

    # Returns the application node, or nil if it never showed up. The bridge
    # comes up a few seconds after the app window does, so this is retried
    # rather than probed once.
    def application(timeout: 120)
      deadline = Node.monotonic_time + timeout
      loop do
        node = desktop_children.find { |child| child.name.match?(APP_NAME) }
        return node if node
        return nil if Node.monotonic_time >= deadline

        sleep 2
      end
    end

    def desktop_children
      return [] unless connected?

      Atspi.desktop_count.times.flat_map do |index|
        desktop = Atspi.get_desktop(index)
        desktop ? Node.new(desktop).children : []
      end
    rescue StandardError => e
      warn "could not read the accessibility desktop: #{e.message}"
      []
    end

    # atspi_init reports 0 on success and 1 when it already ran; anything else
    # means the accessibility bus is not reachable (yet).
    def connected?
      Atspi.init < 2
    rescue StandardError
      false
    end
  end
end
