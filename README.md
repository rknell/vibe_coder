# VibeCoder - AI-Powered Flutter Development Assistant

**🏆 LEGENDARY STATUS ACHIEVED** - Complete AI conversation system with MCP integration!

## ⚡ Features

- **🤖 AI Conversation Interface**: Real-time chat with DeepSeek AI assistant
- **⚔️ Model Context Protocol (MCP)**: Multi-server tool integration
- **🚀 Production-Ready UI**: Auto-scroll, typing indicators, error handling
- **🛡️ Robust Architecture**: Stream-based messaging with comprehensive error recovery
- **🔧 Developer Tools**: File system access, web search, GitHub integration

## 🎯 Quick Start

### 1. **API Configuration**
Create a `.env` file in your project root:

```bash
# Copy the example file and edit it
cp .env.example .env
```

Edit `.env` file with your API key:
```env
DEEPSEEK_API_KEY=your_actual_api_key_here
```

Get your API key from [DeepSeek Platform](https://platform.deepseek.com/).

**🔐 SECURITY**: The `.env` file is automatically ignored by git to protect your secrets.

### 2. **MCP Server Setup** (Optional)
Configure MCP servers in `mcp.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "/your/project/path"]
    }
  }
}
```

### 3. **Run the App**
```bash
flutter run
```

## 🏛️ Architecture Overview

### **Core Components**

| Component | Responsibility | Performance |
|-----------|---------------|-------------|
| `ChatService` | AI conversation orchestration | O(1) message processing |
| `MessagingUI` | Production chat interface | O(n) message rendering |
| `Agent` | MCP tool integration + context | O(1) tool delegation |
| `ConversationManager` | API communication + history | O(n) history management |

### **Message Flow**
```
User Input → ChatService → Agent → ConversationManager → DeepSeek API
                ↓                                                ↑
           Stream Updates ←←←← Response Processing ←←←←←←←←←←←←←←←←
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
flutter test

# Run specific service tests
flutter test test/services/chat_service_test.dart

# Run with coverage
flutter test --coverage
```

## 🔧 Development

### **Key Services**

- **`ChatService`**: Main conversation interface
  - Real-time message streaming
  - State management (ready/processing/error)
  - Error recovery and retry logic

- **`Agent`**: AI assistant orchestration
  - MCP tool integration
  - Context file management
  - Conversation history

- **`MessagingUI`**: Chat interface component
  - Auto-scroll and focus management
  - Expandable input (1-10 lines)
  - Ctrl+Enter to send

### **Configuration**

| Setting | Configuration File | Default | Purpose |
|---------|-------------------|---------|---------|
| API Key | `.env` file: `DEEPSEEK_API_KEY` | Required | DeepSeek API authentication |
| MCP Config | `mcp.json` | Tool servers | External tool configuration |
| Log Level | `.env` file: `LOG_LEVEL` | `INFO` | Logging verbosity |

## 🛡️ Security

- **🔐 API Key Management**: Secure `.env` file with git-ignore protection
- **🚫 No Hardcoded Secrets**: All sensitive data externalized from code
- **🛡️ Input Validation**: Message sanitization and length limits
- **⚠️ Error Boundaries**: Graceful failure handling
- **🔒 Multi-layer Loading**: `.env` file → system environment → fallback

## 📚 Usage Examples

### **Basic Chat**
```dart
final chatService = ChatService();
await chatService.initialize();
await chatService.sendMessage('Help me optimize this Flutter widget');
```

### **Stream Listening**
```dart
chatService.messageStream.listen((message) {
  print('${message.role}: ${message.content}');
});
```

### **Error Handling**
```dart
chatService.stateStream.listen((state) {
  if (state == ChatServiceState.error) {
    print('Error: ${chatService.lastError}');
  }
});
```

## 🚀 Performance Characteristics

- **Message Processing**: O(1) - Direct API delegation
- **UI Updates**: O(n) where n = visible messages
- **Memory Usage**: Optimized with stream-based architecture
- **Network**: Async, non-blocking API calls

## 🔄 State Management

| State | Description | UI Impact |
|-------|-------------|-----------|
| `uninitialized` | Service not started | Loading spinner |
| `initializing` | Setting up API/MCP | Loading spinner |
| `ready` | Ready for messages | Input enabled |
| `processing` | AI generating response | Input disabled, "AI thinking..." |
| `error` | Failed operation | Error banner + retry options |

## 📖 Contributing

Follow the **ELITE CODING WARRIOR PROTOCOL**:

1. **🔍 Reconnaissance**: Understand existing architecture
2. **🧪 Test-First**: Write failing tests before implementation  
3. **📋 Documentation**: Document architectural decisions
4. **⚡ Performance**: Annotate complexity in comments
5. **🛡️ Security**: Use environment variables for secrets

## 🏆 Victory Conditions

- ✅ Real-time AI conversation
- ✅ MCP tool integration  
- ✅ Production-ready UI
- ✅ Comprehensive error handling
- ✅ Environment-based configuration
- ✅ Full test coverage
- ✅ Performance optimizations
- ✅ Security best practices

**🎯 MISSION ACCOMPLISHED - LEGENDARY STATUS ACHIEVED!**
