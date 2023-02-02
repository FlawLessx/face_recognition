class AddRequest {
  AddRequest({
    required this.image,
    required this.name,
  });
  late final String image;
  late final String name;

  AddRequest.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['image'] = image;
    data['name'] = name;
    return data;
  }
}
