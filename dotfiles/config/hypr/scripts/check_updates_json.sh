#!/bin/bash

count=$(checkupdates 2>/dev/null | wc -l)

if [ "$count" -gt 0 ]; then
  icon_class="has-updates"
else
  icon_class="updated"
fi

echo "{\"text\": \"$count\", \"class\": \"$icon_class\"}"
