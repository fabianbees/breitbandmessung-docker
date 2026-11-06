#!/usr/bin/env ruby
# frozen_string_literal: true

# Makes the app's operating system check pass, so measurements also run on
# architectures it does not officially support.
#
# At startup the app decides whether the system is supported and keeps the
# answer in its state as validOs; while false, the whole measurement menu
# stays disabled. Every Linux entry in its support table allows "x64" as the
# only architecture:
#
#   h.supported.linux.ubuntu.architectures = ["x64"]
#   ...
#   "ubuntu" === d.toLowerCase() && <release checks>
#     && h.supported.linux.ubuntu.architectures.indexOf(u) > -1
#     && (h.allowed = !0)
#
# and a single reducer copies that verdict into validOs:
#
#   case APP_START:
#     return Object.assign({}, e, {validOs: t.validOs, is32BitOs: ..., ...})
#
# Pinning that one value to true is enough and app.asar holds
# no native code, so there is nothing "x86-only" to emulate.
#
# The replacement is padded with spaces to the exact length of what it
# replaces, keeping every asar offset valid without unpacking and repacking
# the 250 MB archive on the target device.

ASAR = ARGV[0] || "/opt/Festnetz-Check/resources/app.asar"

# The action variable is minified, so the pattern matches whatever it is called
# in this release rather than hardcoding the current name.
UNPATCHED = /validOs:[A-Za-z_$][\w$]{0,3}\.validOs/n
REPLACEMENT = "validOs:!0"
# What the line looks like afterwards: the constant plus its padding.
PATCHED = /validOs:!0[ ]{1,16}/n

CHUNK_SIZE = 8 * 1024 * 1024
# Longest possible match, so one straddling a chunk boundary is still seen when
# the tail of a chunk is carried into the next.
OVERLAP = 64

def log(message)
  puts "[os-check-patch] #{message}"
end

# Byte ranges of every match of `pattern`, scanning in chunks so the file is
# never held in memory in full.
def find_sites(path, pattern)
  sites = []

  File.open(path, "rb") do |io|
    window = +""
    window_start = 0

    while (chunk = io.read(CHUNK_SIZE))
      window << chunk.force_encoding(Encoding::BINARY)

      position = 0
      while (match = pattern.match(window, position))
        sites << [window_start + match.begin(0), match[0].bytesize]
        position = match.end(0)
      end

      next unless window.bytesize > OVERLAP

      dropped = window.bytesize - OVERLAP
      window = window.byteslice(dropped, OVERLAP)
      window_start += dropped
    end
  end

  # The carried-over tail is scanned twice, so a match inside it is found twice.
  sites.uniq
end

def main
  unless File.file?(ASAR)
    warn "[os-check-patch] #{ASAR} does not exist"
    exit 1
  end

  sites = find_sites(ASAR, UNPATCHED)

  if sites.empty?
    unless find_sites(ASAR, PATCHED).empty?
      log "already patched, nothing to do"
      return
    end

    warn "[os-check-patch] found no operating system check to patch in #{ASAR}."
    warn "[os-check-patch] The app's bundle has changed shape; this patch needs " \
         "to be revisited before it can run on #{`uname -m`.strip}."
    exit 1
  end

  File.open(ASAR, "r+b") do |io|
    sites.each do |offset, length|
      io.seek(offset)
      io.write(REPLACEMENT.ljust(length))
    end
  end

  log "patched the operating system check, the app now runs on #{`uname -m`.strip}"
end

main if $PROGRAM_NAME == __FILE__
