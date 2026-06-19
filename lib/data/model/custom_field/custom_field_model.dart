class CustomFieldModel {
  int? id;
  String? name;
  List? value;
  String? type;
  String? image;
  int? required;
  int? minLength;
  int? maxLength;
  dynamic values;
  String? translatedName;
  List? translatedValue;
  List<dynamic>? translations;

  CustomFieldModel({
    this.id,
    this.name,
    this.type,
    this.values,
    this.image,
    this.required,
    this.maxLength,
    this.minLength,
    this.value,
    this.translatedName,
    this.translatedValue,
    this.translations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'values': values,
      'image': image,
      'required': required,
      'min_length': minLength,
      'max_length': maxLength,
      'value': value,
      'translated_name': translatedName,
      'translated_value': translatedValue,
      'translations': translations,
    };
  }

  factory CustomFieldModel.fromMap(Map<String, dynamic> map) {
    return CustomFieldModel(
      id: int.tryParse(map['id'].toString()),
      name: map['name']?.toString(),
      type: map['type']?.toString(),
      values: map['values'] as dynamic,
      image: map['image']?.toString(),
      required: int.tryParse(map['required'].toString()),
      maxLength: int.tryParse(map['max_length'].toString()),
      minLength: int.tryParse(map['min_length'].toString()),
      value: map['value'] is List? ? map['value'] : [map['value'] as dynamic],
      translatedName: map['translated_name']?.toString(),
      translatedValue: map['translated_value'] as List?,
      translations: map['translations'] as List<dynamic>?,
    );
  }

  @override
  String toString() {
    return 'CustomFieldModel(id: $id, name: $name, type: $type, image: $image, required: $required, minLength: $minLength, maxLength: $maxLength, values: $values, value: $value, translatedName: $translatedName, translatedValue: $translatedValue, translations: $translations)';
  }
}

class VerificationFieldModel {
  int? id;
  String? name;
  String? translatedName;
  String? type;
  int? required;
  int? minLength;
  int? maxLength;
  String? status;
  dynamic values;
  dynamic translatedValues;

  VerificationFieldModel({
    this.id,
    this.name,
    this.translatedName,
    this.type,
    this.values,
    this.translatedValues,
    this.required,
    this.maxLength,
    this.minLength,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'translated_name': translatedName,
      'type': type,
      'values': values,
      'translated_value': translatedValues,
      'required': required,
      'min_length': minLength,
      'max_length': maxLength,
      'status': status,
    };
  }

  factory VerificationFieldModel.fromMap(Map<String, dynamic> map) {
    return VerificationFieldModel(
      id: int.tryParse(map['id'].toString()),
      name: map['name']?.toString(),
      translatedName: map['translated_name']?.toString(),
      type: map['type']?.toString(),
      values: map['values'] as dynamic,
      translatedValues: map['translated_value'] as dynamic,
      required: int.tryParse(map['is_required'].toString()),
      maxLength: int.tryParse(map['max_length'].toString()),
      minLength: int.tryParse(map['min_length'].toString()),
      status: map['status']?.toString(),
    );
  }

  @override
  String toString() {
    return 'VerificationFieldModel(id: $id, name: $name, type: $type, required: $required, minLength: $minLength, maxLength: $maxLength, values: $values,status:$status)';
  }
}
