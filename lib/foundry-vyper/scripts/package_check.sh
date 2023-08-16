#! /bin/bash
# Check if the output of the command contains the word "not found".
if [[ "$(pip show vyper)" =~ "not found" ]]; then
  echo -n 0x00
else
  echo -n 0x01
fi