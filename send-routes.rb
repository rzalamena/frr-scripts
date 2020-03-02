#!/usr/bin/env ruby

# frozen_string_literal: true

# Copyright (c) 2020 Rafael F. Zalamena
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# Maximum number of routes we can generate with: A.B.C.D/32 with fixed `A`.
routes_maximum = 16_516_351

# First parameter of the ruby script: our local address to point with next-hop.
our_address = ARGV[0]
# Second parameter: amount of routes to send.
route_number = ARGV[1].to_i

if route_number >= routes_maximum
  $stderr.puts "route number exceeded: #{routes_maximum}"
  exit 1
end

# Prefix network configuration.
# Format: anet.bnet.cnet.dnet
# Rules: bnet/cnet go from 0 to 254, dnet goes from 1 to 254.
anet = 11
bnet = 0
cnet = 0
dnet = 1

while route_number > 0
  # Try to announce the route.
  $stdout.puts "announce route #{anet}.#{bnet}.#{cnet}.#{dnet} " \
    "next-hop #{our_address};\n"
  $stdout.flush

  input = $stdin.gets
  unless input.match?(/done/i)
    # If we got error, then retry it.
    $stdout.puts "Got: '#{input}'"
    sleep 1
    next
  end

  # Prefix got announced successfully, go to the next one.
  route_number -= 1

  dnet += 1
  if dnet == 255
    dnet = 1
    cnet += 1
    if cnet == 255
      cnet = 0
      bnet += 1
      if bnet == 255
        raise 'reached maximum number of routes'
      end
    end
  end
end

# Wait forever so exabgp doesn't quit or restart us.
sleep

exit 0
