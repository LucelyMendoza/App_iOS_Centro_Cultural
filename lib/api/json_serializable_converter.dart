// lib/api/json_serializable_converter.dart
import 'dart:convert';
import 'package:chopper/chopper.dart';
import 'package:mi_app/models/post_model.dart';

class JsonSerializableConverter extends Converter {
  @override
  Request convertRequest(Request request) {
    // CORRECCIÓN: No llames a super.convertRequest()
    return request.copyWith(
      headers: {...request.headers, 'Content-Type': 'application/json'}
    );
  }

  @override
  Response<BodyType> convertResponse<BodyType, InnerType>(Response response) {
    return Response<BodyType>(
      response.base,
      _decode<BodyType>(response.body),
      error: response.error,
    );
  }

  dynamic _decode<BodyType>(dynamic body) {
    try {
      if (body is String) {
        body = jsonDecode(body);
      }
      
      if (BodyType == List<PostModel>) {
        return (body as List).map<PostModel>((item) => PostModel.fromJson(item)).toList();
      }
      
      if (BodyType == PostModel) {
        return PostModel.fromJson(body);
      }
      
      return body;
    } catch (e) {
      throw FormatException('Failed to decode: ${e.toString()}');
    }
  }
}