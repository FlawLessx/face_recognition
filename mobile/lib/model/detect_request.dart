class DetectRequest {
  DetectRequest({
    required this.image,
  });
  late final String image;

  DetectRequest.fromJson(Map<String, dynamic> json) {
    image = json['image'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['image'] = image;
    return data;
  }
}
