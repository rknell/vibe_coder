#!/bin/bash

# 🏆 **VIBE CODER TEST RUNNER**
# Provides fast and thorough test execution options

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

if [ "$INTEGRATION_TESTS" = true ]; then
  echo "🐌 Mode: THOROUGH (includes integration tests)"
  echo "📁 File Operations: ENABLED (for MCP server loading)"
  echo "⚠️  Warning: This will take 2+ minutes and may fail if MCP servers aren't running"
  flutter test --dart-define=MCP_INTEGRATION_TESTS=true --dart-define=IS_TEST_MODE=$TEST_MODE
else
  echo "⚡ Mode: FAST (unit tests only)"
  echo "📁 File Operations: DISABLED (for speed)"
  echo "✅ Integration tests skipped for speed"
  flutter test --dart-define=MCP_INTEGRATION_TESTS=false --dart-define=IS_TEST_MODE=$TEST_MODE
fi

echo ""
echo "🏆 VICTORY! All enabled tests passed"
echo ""
echo "💡 To run integration tests: $0 --integration"
echo "💡 To run fast tests only: $0 --fast" 