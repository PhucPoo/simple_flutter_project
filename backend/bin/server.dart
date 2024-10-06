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
final _headers = {'Content-Type': 'application/json'};

// Xử lý các yêu cầu đến các đường dẫn không được định nghĩa (404 Not Found).
Response _notFoundHandler(Request reg) {
  return Response.notFound('Không tìm thấy đường dẫn "${reg.url}" trên server');
}

// Hàm xử lý các yêu cầu gốc tại đường dẫn '/'
//
// Trả về một phản hồi với thông điệp 'Hello, World!' dưới dạng JSON
//
// `reg`: Đối tượng yêu cầu t client
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
    final yearOfBirth = data['yearOfBirth'] as int?;
    final Address = data['Address'] as String?;

    // Kiểu tra nếu 'name' hợp lệ
    if (name != null && name.isNotEmpty) {
      // Nếu năm sinh không có, chỉ trả về thông báo chào mừng
      if (yearOfBirth == null || yearOfBirth <= 0) {
        if (Address == null || Address.isNotEmpty) {}
        return Response.ok(
          json.encode({'message': 'Chào mừng $name!'}),
          headers: _headers,
        );
      }

      // Nếu năm sinh hợp lệ, tính toán tuổi và trả về
      final currentYear = DateTime.now().year;
      final age = currentYear - yearOfBirth;

      return Response.ok(
        json.encode(
            {'message': 'Chào mừng $name!', 'age': age, 'Adress': Address}),
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
  // Lắng nghe các địa chỉ IPv4
  final ip = InternetAddress.anyIPv4;

  final corsHeader = createMiddleware(
    requestHandler: (req) {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: {
          // Cho phép mọi nguồn truy cập (trong môi trường dev ). Trong môi trường prodution chúng ta nên thay bằng domain cụ thể.
          'Access-Control-Allow-Origin': 'http://localhost:8081',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, HEAD',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        });
      }
      return null;
    },
    responseHandler: (res) {
      return res.change(headers: {
        'Access-Control-Allow-Origin': 'http://localhost:8081',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, HEAD',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
    },
  );

  // Cấu hình một pipeline để logs các requests và middleware
  final handler = Pipeline()
      // Thêm middleware xử lý CORS
      .addMiddleware(corsHeader)
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // Để chạy trong cacsc container, chúng ta xử dugnj biến môi trường PORT.
  // Nếu biến môi trường không được thiết lập nó sẽ sử dụng giá trị từ biến
  // môi trường này; nếu không, nó sẽ sử dụng giá trị mặc đinh là 8080
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  // Khởi chạy server tại địa chỉ và cổng chỉ định
  final server = await serve(handler, ip, port);
  print('Server đang chạy tại http://${server.address.host}: ${server.port}');
}
