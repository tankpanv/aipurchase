class User {
  int? id;
  String? userName;
  String? name;
  String? phone;
  String? email;
  String? avatar;
  String? address;
  String? createdAt;
  String? bio;
  List<String>? tags;
  List<String>? interests;
  String? updatedAt;

  User({
    this.id,
    this.userName,
    this.name,
    this.phone,
    this.email,
    this.avatar,
    this.address,
    this.createdAt,
    this.bio,
    this.tags,
    this.interests,
    this.updatedAt,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userName = json['user_name'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    
    // 注意字段名映射:
    // 服务器返回 'avatar_url'，但本地模型使用 'avatar'
    // 这里兼容两种情况，优先使用 'avatar'，如果不存在则使用 'avatar_url'
    avatar = json['avatar'] ?? json['avatar_url'];
    
    address = json['address'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    bio = json['bio'];
    
    // 处理标签数组，支持列表或字符串格式
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tags = List<String>.from(json['tags']);
      } else if (json['tags'] is String) {
        try {
          final tagsStr = json['tags'] as String;
          if (tagsStr.isNotEmpty) {
            tags = tagsStr.split(',');
          } else {
            tags = [];
          }
        } catch (_) {
          tags = [];
        }
      } else {
        tags = [];
      }
    } else {
      tags = [];
    }
    
    if (json['interests'] != null) {
      if (json['interests'] is List) {
        interests = List<String>.from(json['interests']);
      } else if (json['interests'] is String) {
        try {
          final interestsStr = json['interests'] as String;
          if (interestsStr.isNotEmpty) {
            interests = interestsStr.split(',');
          } else {
            interests = [];
          }
        } catch (_) {
          interests = [];
        }
      } else {
        interests = [];
      }
    } else {
      interests = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (userName != null) data['user_name'] = userName;
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    
    // 注意: 在服务器端，头像字段名为'avatar_url'，而不是'avatar'
    // 本地模型使用'avatar'字段，但序列化为JSON时需使用'avatar_url'
    if (avatar != null) data['avatar_url'] = avatar;
    
    if (address != null) data['address'] = address;
    if (createdAt != null) data['created_at'] = createdAt;
    if (updatedAt != null) data['updated_at'] = updatedAt;
    if (bio != null) data['bio'] = bio;
    if (tags != null) data['tags'] = tags;
    if (interests != null) data['interests'] = interests;
    return data;
  }
} 