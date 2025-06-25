#!/bin/bash

# 🏆 **VIBE CODER TEST RUNNER**
# Provides fast and thorough test execution options with enhanced failure reporting

set -e

# Default values
INTEGRATION_TESTS=false
TEST_MODE=true
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --integration)
      INTEGRATION_TESTS=true
      TEST_MODE=false  # 🔧 Enable file operations for integration tests
      shift
      ;;
    --fast)
      INTEGRATION_TESTS=false
      TEST_MODE=true   # 🛡️ Disable file operations for fast tests
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option $1"
      echo "Usage: $0 [--integration|--fast] [--verbose]"
      echo "  --fast        Run only fast unit tests (default)"
      echo "  --integration Run slow integration tests too"
      echo "  --verbose     Show verbose output"
      exit 1
      ;;
  esac
done

echo "🧪 VibeCoder Test Runner"
echo "========================"

# Prepare flutter test arguments
FLUTTER_ARGS=(
  "--dart-define=IS_TEST_MODE=$TEST_MODE"
)

if [ "$INTEGRATION_TESTS" = true ]; then
  echo "🐌 Mode: THOROUGH (includes integration tests)"
  echo "📁 File Operations: ENABLED (for MCP server loading)"
  echo "⚠️  Warning: This will take 2+ minutes and may fail if MCP servers aren't running"
  FLUTTER_ARGS+=("--dart-define=MCP_INTEGRATION_TESTS=true")
else
  echo "⚡ Mode: FAST (unit tests only)"
  echo "📁 File Operations: DISABLED (for speed)"
  echo "✅ Integration tests skipped for speed"
  FLUTTER_ARGS+=("--dart-define=MCP_INTEGRATION_TESTS=false")
fi

# Add verbose debug flag if requested
DEBUG_FLAG=""
if [ "$VERBOSE" = true ]; then
  DEBUG_FLAG="--debug"
fi

echo ""
echo "🔍 Running tests with enhanced failure reporting..."
echo ""

# Run tests using the enhanced failing tests script
if ./tool/get_failing_tests.sh $DEBUG_FLAG -- "${FLUTTER_ARGS[@]}"; then
  echo ""
  echo "🏆 VICTORY! All enabled tests passed"
  echo ""
  echo "💡 To run integration tests: $0 --integration"
  echo "💡 To run fast tests only: $0 --fast"
  echo "💡 To see verbose output: $0 --verbose"
else
  echo ""
  echo "💥 DEFEAT! Some tests failed"
  echo ""
  echo "🔧 Use the commands above to run specific failing tests"
  echo "💡 Add --verbose for more debug information"
  exit 1
fi 