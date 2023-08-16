#! /bin/bash
# Check if the output of the command contains the word "not found".
if [[ "$(pip show vyper)" =~ "not found" ]]; then
  # byper was installed via pip, return 0x00
  echo -n 0x00
else
  echo -n 0x01
fi