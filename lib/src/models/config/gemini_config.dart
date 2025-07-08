/// Every prompt you send to the model includes parameter values that control how the model generates a response.
/// The model can generate different results for different parameter values.
/// This class is used to create a instance of a Generation Config to control the model
class GenerationConfig {
  double temperature;
  int? maxOutputTokens;
  double? topP;
  int? topK;
  List<String>? stopSequences;
  String? responseMimeType;
  Map<String, dynamic>? responseSchema;

  GenerationConfig({
    required this.temperature,
    this.maxOutputTokens,
    this.topP,
    this.topK,
    this.stopSequences,
    this.responseMimeType,
    this.responseSchema,
  });

  /// from json
  factory GenerationConfig.fromJson(Map<String, dynamic> json) {
    return GenerationConfig(
      temperature: json['temperature'],
      maxOutputTokens: json['maxOutputTokens'],
      topP: json['topP'],
      topK: json['topK'],
      stopSequences: json['stopSequences'],
      responseMimeType: json['responseMimeType'],
      responseSchema: json['responseSchema'],
    );
  }

  /// to json
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
      if (topP != null) 'topP': topP,
      if (topK != null) 'topK': topK,
      if (stopSequences != null) 'stopSequences': stopSequences,
      if (responseMimeType != null) 'responseMimeType': responseMimeType,
      if (responseSchema != null) 'responseSchema': responseSchema
    };
  }
}
