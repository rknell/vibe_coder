#!/bin/bash
# Simple one-liner to extract failing Flutter tests
flutter test -r json 2>&1 | grep '^{' | grep '"result":"error"\|"result":"failure"' | jq -r '"Test ID " + (.testID | tostring) + ": " + (.error // "Failed")' 