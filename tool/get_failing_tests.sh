#!/bin/bash

# Script to extract failing Flutter tests from JSON output
# Usage: ./get_failing_tests.sh [--debug]
# 
# This script runs Flutter tests with JSON output and extracts only the failing ones.
# It handles the line-delimited JSON format that Flutter outputs and provides
# clear information about which tests failed and in which files.

set -euo pipefail

DEBUG=false
if [[ "${1:-}" == "--debug" ]]; then
    DEBUG=true
fi

echo "🔍 Running Flutter tests and extracting failures..."

# Create temporary files
JSON_RAW=$(mktemp)
FAILURES=$(mktemp)
trap "rm -f $JSON_RAW $FAILURES" EXIT

# Run flutter test and capture output, filtering out non-JSON lines
echo "⏳ Running tests..."
flutter test -r json 2>&1 | grep '^{' > "$JSON_RAW" || true

if $DEBUG; then
    echo "Debug: Total JSON lines captured: $(wc -l < "$JSON_RAW")"
fi

echo ""
echo "📊 Analyzing test results..."

# Extract just the failing test results
grep '"result":"error"\|"result":"failure"' "$JSON_RAW" > "$FAILURES" || true

if [ ! -s "$FAILURES" ]; then
    echo "✅ All tests passed! No failures found."
    
    if $DEBUG; then
        total_tests=$(grep '"type":"testDone"' "$JSON_RAW" | wc -l)
        echo "📈 Total tests run: $total_tests"
        echo ""
        echo "Test completion summary:"
        grep '"type":"testDone"' "$JSON_RAW" | jq -r '.result' | sort | uniq -c
    fi
else
    failure_count=$(wc -l < "$FAILURES")
    echo "❌ Found $failure_count failing test(s):"
    echo ""
    
    # Show details of failed tests
    while IFS= read -r line; do
        testid=$(echo "$line" | jq -r '.testID')
        error=$(echo "$line" | jq -r '.error // empty')
        echo "• Test ID: $testid"
        if [ -n "$error" ]; then
            echo "  Error: $error"
        fi
        echo ""
    done < "$FAILURES"
    
    echo "📁 Test files containing failures:"
    
    # Find corresponding test files by looking for suite information
    while IFS= read -r failure_line; do
        test_id=$(echo "$failure_line" | jq -r '.testID')
        
        # Find the test start event to get suite ID
        suite_id=$(grep "\"type\":\"testStart\"" "$JSON_RAW" | grep "\"id\":$test_id" | jq -r '.test.suiteID' 2>/dev/null | head -1)
        
        if [ -n "$suite_id" ] && [ "$suite_id" != "null" ] && [ "$suite_id" != "" ]; then
            # Find the suite path
            suite_path=$(grep "\"type\":\"suite\"" "$JSON_RAW" | grep "\"id\":$suite_id" | jq -r '.suite.path' 2>/dev/null | head -1)
            if [ -n "$suite_path" ] && [ "$suite_path" != "null" ] && [ "$suite_path" != "" ]; then
                echo "$suite_path"
            fi
        fi
    done < "$FAILURES" | sort -u | sed 's/^/• /'
    
    echo ""
    echo "🔧 To run only specific failing tests:"
    while IFS= read -r failure_line; do
        test_id=$(echo "$failure_line" | jq -r '.testID')
        suite_id=$(grep "\"type\":\"testStart\"" "$JSON_RAW" | grep "\"id\":$test_id" | jq -r '.test.suiteID' 2>/dev/null | head -1)
        
        if [ -n "$suite_id" ] && [ "$suite_id" != "null" ] && [ "$suite_id" != "" ]; then
            suite_path=$(grep "\"type\":\"suite\"" "$JSON_RAW" | grep "\"id\":$suite_id" | jq -r '.suite.path' 2>/dev/null | head -1)
            if [ -n "$suite_path" ] && [ "$suite_path" != "null" ] && [ "$suite_path" != "" ]; then
                echo "flutter test $suite_path"
            fi
        fi
    done < "$FAILURES" | sort -u
fi

if $DEBUG && [ -s "$FAILURES" ]; then
    echo ""
    echo "Debug: Raw failure data:"
    cat "$FAILURES"
fi 