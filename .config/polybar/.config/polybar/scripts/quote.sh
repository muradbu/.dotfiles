#!/bin/sh
echo $(curl -s "https://stoic-quotes.com/api/quote" | jq -r '"\(.author) | \(.text)"')
