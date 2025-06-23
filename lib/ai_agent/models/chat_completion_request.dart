import 'package:vibe_coder/ai_agent/models/ai_agent_enums.dart';
import 'package:vibe_coder/ai_agent/models/chat_message_model.dart';
import 'package:vibe_coder/ai_agent/models/response_format.dart';
import 'package:vibe_coder/ai_agent/models/tool_choice.dart';

/// Represents the chat completion request parameters.
///
/// Creates a model response for the given chat conversation.
class ChatCompletionRequest {
  /// A list of messages comprising the conversation so far.
  /// Must contain at least 1 message.
  final List<ChatMessage> messages;

  /// ID of the model to use. You can use deepseek-chat.
  /// Possible values: deepseek-chat, deepseek-reasoner
  final String model;

  /// Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far,
  /// decreasing the model's likelihood to repeat the same line verbatim.
  /// Default value: 0
  final double? frequencyPenalty;

  /// Integer between 1 and 8192. The maximum number of tokens that can be generated in the chat completion.
  /// The total length of input tokens and generated tokens is limited by the model's context length.
  /// If max_tokens is not specified, the default value 4096 is used.
  final int? maxTokens;

  /// Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far,
  /// increasing the model's likelihood to talk about new topics.
  /// Default value: 0
  final double? presencePenalty;

  /// An object specifying the format that the model must output.
  final ResponseFormat? responseFormat;

  /// Up to 16 sequences where the API will stop generating further tokens.
  final List<String>? stop;

  /// If set, partial message deltas will be sent. Tokens will be sent as data-only server-sent events (SSE)
  /// as they become available, with the stream terminated by a data: [DONE] message.
  final bool stream;

  /// Options for streaming response. Only set this when you set stream: true.
  final Map<String, dynamic>? streamOptions;

  /// What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random,
  /// while lower values like 0.2 will make it more focused and deterministic.
  /// Default value: 1
  /// We generally recommend altering this or top_p but not both.
  final double? temperature;

  /// An alternative to sampling with temperature, called nucleus sampling, where the model considers the results
  /// of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.
  /// Default value: 1
  /// We generally recommend altering this or temperature but not both.
  final double? topP;

  /// A list of tools the model may call. Currently, only functions are supported as a tool.
  /// Use this to provide a list of functions the model may generate JSON inputs for. A max of 128 functions are supported.
  final List<Map<String, dynamic>>? tools;

  /// Controls which (if any) tool is called by the model.
  ///
  /// Can be specified in two formats:
  /// 1. A string value: "none", "auto", or "required"
  /// 2. An object specifying a particular tool: {"type": "function", "function": {"name": "my_function"}}
  ///
  /// none is the default when no tools are present. auto is the default if tools are present.
  final ToolChoice? toolChoice;

  /// Whether to return log probabilities of the output tokens or not. If true, returns the log probabilities
  /// of each output token returned in the content of message.
  final bool? logprobs;

  /// An integer between 0 and 20 specifying the number of most likely tokens to return at each token position,
  /// each with an associated log probability. logprobs must be set to true if this parameter is used.
  final int? topLogprobs;

  ChatCompletionRequest({
    required this.messages,
    required this.model,
    this.frequencyPenalty,
    this.maxTokens,
    this.presencePenalty,
    this.responseFormat,
    this.stop,
    this.stream = false,
    this.streamOptions,
    this.temperature,
    this.topP,
    this.tools,
    this.toolChoice,
    this.logprobs,
    this.topLogprobs,
  }) {
    // If response format is JSON, append a system message to instruct the model
    if (responseFormat?.type == ResponseFormatType.jsonObject) {
      final hasSystemMessage =
          messages.any((m) => m.role == MessageRole.system);
      if (hasSystemMessage) {
        // Find the first system message and append JSON instruction
        final systemMessageIndex =
            messages.indexWhere((m) => m.role == MessageRole.system);
        final systemMessage = messages[systemMessageIndex];
        messages[systemMessageIndex] = ChatMessage(
          role: MessageRole.system,
          content:
              '${systemMessage.content}\n\nIMPORTANT: You must respond in valid JSON format.',
        );
      } else {
        // Add a new system message with JSON instruction
        messages.insert(
            0,
            ChatMessage(
              role: MessageRole.system,
              content: 'You must respond in valid JSON format.',
            ));
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'messages': messages.map((m) => m.toJson()).toList(),
        'model': model,
        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
        if (maxTokens != null) 'max_tokens': maxTokens,
        if (presencePenalty != null) 'presence_penalty': presencePenalty,
        ...(() {
          final responseFormatValue = responseFormat;
          if (responseFormatValue != null) {
            return {'response_format': responseFormatValue.toJson()};
          }
          return <String, dynamic>{};
        })(),
        if (stop != null) 'stop': stop,
        'stream': stream,
        if (streamOptions != null) 'stream_options': streamOptions,
        if (temperature != null) 'temperature': temperature,
        if (topP != null) 'top_p': topP,
        if (tools != null) 'tools': tools,
        ...(() {
          final toolChoiceValue = toolChoice;
          if (toolChoiceValue != null) {
            return {'tool_choice': toolChoiceValue.toJson()};
          }
          return <String, dynamic>{};
        })(),
        if (logprobs != null) 'logprobs': logprobs,
        if (topLogprobs != null) 'top_logprobs': topLogprobs,
      };
}
