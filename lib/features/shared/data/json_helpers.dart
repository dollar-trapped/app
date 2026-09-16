typedef Json = Map<String, dynamic>;

DateTime jsonDate(Json json, String key) =>
    DateTime.parse(json[key] as String).toUtc();
String? jsonString(Json json, String key) => json[key] as String?;
