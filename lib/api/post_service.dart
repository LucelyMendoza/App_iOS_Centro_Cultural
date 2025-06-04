// lib/api/post_service.dart
import 'package:chopper/chopper.dart';
import 'package:mi_app/models/post_model.dart';
import 'json_serializable_converter.dart';
part 'post_service.chopper.dart';

@ChopperApi()
abstract class PostService extends ChopperService {
  @Get(path: '/posts')
  Future<Response<List<PostModel>>> getPosts();

  static PostService create() {
  final client = ChopperClient(
    baseUrl: Uri.parse('https://jsonplaceholder.typicode.com'), // Convertir a Uri
    services: [_$PostService()],
    converter: JsonSerializableConverter(),
    interceptors: [HttpLoggingInterceptor()],
  );
  return _$PostService(client);
}
}