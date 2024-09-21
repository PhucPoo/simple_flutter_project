import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Cấu hình các routes
final _router = Router(notFoundHandler: _notFoundHandler)
  ..get('/', _rootHandler)
  ..get('/api/v1/check', _checkHandler)
  ..get('/echo/<message>', _echoHandler)
  ..post('/api/v1/submit', _submitHandler);

// Header mặc định cho dữ liệu trả về dưới dạng JSON
final _headers = {'Contents-Type': 'application/json'};

// Xử lý các yêu cầu đến các đường dẫn không được định nghĩa (404 Not Found).
Response _notFoundHandler(Request reg) {
  return Response.notFound('Không tìm thấy đường dẫn "${reg.url}" trên server');
}

// Hàm xử lý các yêu cầu gốc tại đường dẫn '/'
//
// Trả về một phản hồi với thồn điệp 'Hello, World!' dưới dạng JSON
//
// `reg`: Đối tượng yêu caauftuwf client
//
// Trả về: Một đối tượng `Response` với mã trạng thái 200 nội dung JSON
Response _rootHandler(Request req) {
  // Constructor `oke` của Response có statusCode là 200
  return Response.ok(
    json.encode({'message': 'Hello, World!'}),
    headers: _headers,
  );
}

// Hàm xử lý yêu cầu tại đường dẫn '/api/v1/check'
Response _checkHandler(Request reg) {
  return Response.ok(
    json.encode({'message': 'Chào mừng bạn đến với ứng dụng web di đông'}),
    headers: _headers,
  );
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<Response> _submitHandler(Request req) async {
  try {
    // Đọc payload từ request
    final payload = await req.readAsString();

    // Giải mã JSON từ payload
    final data = json.decode(payload);

    // Lấy giá trị 'name' từ data, ép kiểu về String? nếu có
    final name = data['name'] as String?;

    // Kiểu tra nếu 'name' hợp lệ
    if (name != null && name.isNotEmpty) {
      // Tạo phản hồi chào mừng
      final response = {'message': 'Chào mừng $name'};

      // Trả về phản hồi với statusCode 200 và nội dung JSON
      return Response.ok(
        json.encode(response),
        headers: _headers,
      );
    } else {
      // Tạo phản hồi yêu cầu cung cấp tên
      final response = {'message': 'Server không phải tên của bạn.'};

      // Trả về phản hồi với statusCode 400 và nội dung JSON
      return Response.badRequest(
        body: json.encode(response),
        headers: _headers,
      );
    }
  } catch (e) {
    // Xử lý ngoại lệ khi giải mã JSON
    final response = {'message': 'Yêu cầu không ngoại lệ. Lỗi ${e.toString()}'};

    // Trả về phản hồi với statusCode 400
    return Response.badRequest(
      body: json.encode(response),
      headers: _headers,
    );
  }
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
