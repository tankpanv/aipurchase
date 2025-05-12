class User {
  int? id;
  String? userName;
  String? name;
  String? phone;
  String? email;
  String? avatar;
  String? address;
  String? createdAt;

  User({
    this.id,
    this.userName,
    this.name,
    this.phone,
    this.email,
    this.avatar,
    this.address,
    this.createdAt,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userName = json['user_name'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    avatar = json['avatar'];
    address = json['address'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (userName != null) data['user_name'] = userName;
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (avatar != null) data['avatar'] = avatar;
    if (address != null) data['address'] = address;
    if (createdAt != null) data['created_at'] = createdAt;
    return data;
  }
} 