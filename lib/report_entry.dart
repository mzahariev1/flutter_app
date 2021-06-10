class ReportEntry {
  DateTime start;
  DateTime end;
  String duration;
  double distance;
  double averageSpeed;
  double maxSpeed;

  ReportEntry(this.start, this.end, this.duration, this.distance,
      this.averageSpeed, this.maxSpeed);

  ReportEntry.fromJson(Map<String, dynamic> json)
      : start = DateTime.parse(json['start']),
        end = DateTime.parse(json['end']),
        duration = json['duration'],
        distance = json['distance'],
        averageSpeed = json['averageSpeed'],
        maxSpeed = json['maxSpeed'];

  Map<String, dynamic> toJson() => {
        'start': start.toString(),
        'end': end.toString(),
        'duration': duration,
        'distance': distance,
        'averageSpeed': averageSpeed,
        'maxSpeed': maxSpeed
      };
}
