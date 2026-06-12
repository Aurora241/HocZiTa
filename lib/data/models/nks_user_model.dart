class NKSUserModel {
  final int id;
  final String? name;
  final String? firstname;
  final String? lastname;
  final String email;
  final String? phone;
  final String? avatar;
  final int gender;
  final String? dob;
  final String? intro;
  final String? website;
  final String? province;
  final String? idNumber;
  final String? idDate;
  final String? idPlace;
  final String? cccdFront;
  final String? cccdBack;
  final int? point;
  final String? accessToken;

  const NKSUserModel({
    required this.id,
    this.name,
    this.firstname,
    this.lastname,
    required this.email,
    this.phone,
    this.avatar,
    this.gender = 0,
    this.dob,
    this.intro,
    this.website,
    this.province,
    this.idNumber,
    this.idDate,
    this.idPlace,
    this.cccdFront,
    this.cccdBack,
    this.point,
    this.accessToken,
  });

  String get displayName {
    if (firstname != null || lastname != null) {
      return '${firstname ?? ''} ${lastname ?? ''}'.trim();
    }
    return name ?? email;
  }

  factory NKSUserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return NKSUserModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      firstname: json['firstname'] as String?,
      lastname: json['lastname'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      gender: (json['gender'] as int?) ?? 0,
      dob: json['dob'] as String?,
      intro: json['intro'] as String?,
      website: json['website'] as String?,
      province: json['province'] as String?,
      idNumber: json['id_number'] as String?,
      idDate: json['id_date'] as String?,
      idPlace: json['id_place'] as String?,
      cccdFront: json['cccd_front'] as String?,
      cccdBack: json['cccd_back'] as String?,
      point: json['point'] as int?,
      accessToken: token,
    );
  }

  NKSUserModel copyWith({
    String? name,
    String? firstname,
    String? lastname,
    String? phone,
    String? avatar,
    int? gender,
    String? dob,
    String? intro,
    String? website,
    String? province,
    String? idNumber,
    String? idDate,
    String? idPlace,
    String? cccdFront,
    String? cccdBack,
    int? point,
    String? accessToken,
  }) {
    return NKSUserModel(
      id: id,
      name: name ?? this.name,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      intro: intro ?? this.intro,
      website: website ?? this.website,
      province: province ?? this.province,
      idNumber: idNumber ?? this.idNumber,
      idDate: idDate ?? this.idDate,
      idPlace: idPlace ?? this.idPlace,
      cccdFront: cccdFront ?? this.cccdFront,
      cccdBack: cccdBack ?? this.cccdBack,
      point: point ?? this.point,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'gender': gender,
        'dob': dob,
        'intro': intro,
        'website': website,
        'province': province,
        'id_number': idNumber,
        'id_date': idDate,
        'id_place': idPlace,
        'cccd_front': cccdFront,
        'cccd_back': cccdBack,
        'point': point,
        'access_token': accessToken,
      };
}
