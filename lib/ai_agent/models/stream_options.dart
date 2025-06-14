/// Options for streaming response in FIM completion requests.
class StreamOptions {
  /// If set, an additional chunk will be streamed before the data: [DONE] message.
  /// The usage field on this chunk shows the token usage statistics for the entire request,
  /// and the choices field will always be an empty array.
  /// All other chunks will also include a usage field, but with a null value.
  final bool includeUsage;

  StreamOptions({this.includeUsage = false});

  Map<String, dynamic> toJson() => {
        'include_usage': includeUsage,
      };
}
