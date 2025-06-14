/// Represents the role of a message author in the chat completion request.
enum MessageRole {
  /// Provides instructions to the model
  system,

  /// Contains user input
  user,

  /// Contains model responses
  assistant,

  /// Contains tool responses
  tool,
}

/// Represents the type of response format.
enum ResponseFormatType {
  /// Regular text output
  text,

  /// JSON object output
  jsonObject,
}

/// Represents the type of tool choice for chat completion requests.
enum ToolChoiceType {
  /// The model will not call any tool and instead generates a message.
  none,

  /// The model can pick between generating a message or calling one or more tools.
  auto,

  /// The model must call one or more tools.
  required,
}

/// Represents the reason why the model stopped generating tokens.
enum FinishReason {
  /// The model hit a natural stop point or a provided stop sequence
  stop,

  /// The maximum number of tokens specified in the request was reached
  length,

  /// Content was omitted due to a flag from our content filters
  contentFilter,

  /// The model called a tool
  toolCalls,

  /// The request is interrupted due to insufficient resource of the inference system
  insufficientSystemResource,
}

/// Represents a currency type for balance information
enum Currency {
  /// Chinese Yuan
  cny,

  /// US Dollar
  usd,
}
