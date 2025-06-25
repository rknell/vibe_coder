#!/bin/bash

# Script to extract failing Flutter tests from JSON output
# Usage: ./get_failing_tests.sh [--debug] [-- flutter_test_args...]
# 
# This script runs Flutter tests with JSON output and extracts only the failing ones.
# It handles the line-delimited JSON format that Flutter outputs and provides
# clear information about which tests failed and in which files.
# Additional arguments after -- are passed directly to flutter test.

set -euo pipefail

DEBUG=false
FLUTTER_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG=true
            shift
            ;;
        --)
            shift
            FLUTTER_ARGS=("$@")
            break
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--debug] [-- flutter_test_args...]"
            echo "  --debug                Show debug information"
            echo "  -- flutter_test_args   Additional arguments passed to flutter test"
            exit 1
            ;;
    esac
done

echo "🔍 Running Flutter tests and extracting failures..."

# Create temporary files
JSON_RAW=$(mktemp)
FAILURES=$(mktemp)
trap "rm -f $JSON_RAW $FAILURES" EXIT

# Run flutter test and capture output, filtering out non-JSON lines
echo "⏳ Running tests..."
if $DEBUG; then
    echo "Debug: Running with args: ${FLUTTER_ARGS[*]}"
fi

flutter test -r json "${FLUTTER_ARGS[@]}" 2>&1 | grep '^{' > "$JSON_RAW" || true

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
        
        # Find the test name from the testStart event
        test_name=$(grep "\"type\":\"testStart\"" "$JSON_RAW" | grep "\"id\":$testid" | jq -r '.test.name' 2>/dev/null | head -1)
        
        # Find the test start event to get suite ID, then get the file path
        suite_id=$(grep "\"type\":\"testStart\"" "$JSON_RAW" | grep "\"id\":$testid" | jq -r '.test.suiteID' 2>/dev/null | head -1)
        file_path=""
        if [ -n "$suite_id" ] && [ "$suite_id" != "null" ] && [ "$suite_id" != "" ]; then
            file_path=$(grep "\"type\":\"suite\"" "$JSON_RAW" | grep "\"id\":$suite_id" | jq -r '.suite.path' 2>/dev/null | head -1)
        fi
        
        echo "• Test ID: $testid"
        if [ -n "$test_name" ] && [ "$test_name" != "null" ] && [ "$test_name" != "" ]; then
            echo "  Test Name: $test_name"
        fi
        if [ -n "$file_path" ] && [ "$file_path" != "null" ] && [ "$file_path" != "" ]; then
            echo "  File: $file_path"
        fi
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

# Exit with non-zero code if there were failures
if [ -s "$FAILURES" ]; then
    exit 1
fi 