import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jame/services/api_client.dart';
import 'package:jame/services/jame_api.dart';
import 'package:jame/services/jame_repository.dart';

void main() {
  test('repository maps products without trusting a client user id', () async {
    final repository = JameRepository(
      api: JameApi(
        client: ApiClient(
          baseUri: Uri.parse('https://api.example.test/api/v1'),
          isWeb: true,
          httpClient: MockClient(
            (_) async => http.Response(
              jsonEncode([
                {
                  'id': 5,
                  'name': 'Coffee',
                  'price': 12.5,
                  'quantity': 8,
                  'low_stock': 2,
                  'code': 'COFFEE-1',
                  'category': 'Drinks',
                  'unit': 'pcs',
                  'image': null,
                  'created_at': '2026-11-23T12:00:00Z',
                  'updated_at': '2026-11-23T12:00:00Z',
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      ),
    );

    final products = await repository.getProducts();

    expect(products, hasLength(1));
    expect(products.single.id, 5);
    expect(products.single.name, 'Coffee');
  });

  test('test_checkout_is_one_api_operation', () async {
    final requests = <http.Request>[];
    final repository = JameRepository(
      api: JameApi(
        client: ApiClient(
          baseUri: Uri.parse('https://api.example.test/api/v1'),
          isWeb: true,
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode({
                'id': 42,
                'user_id': 7,
                'sale_date': '2026-11-23T12:00:00Z',
                'total_amount': 12.5,
                'payment_status': 'Completed',
                'receipt_number': 'JAME-42',
                'payment_method': 'QR',
                'description': null,
                'customer_name': null,
                'customer_phone': null,
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      ),
    );

    final sale = await repository.checkout(paymentMethod: 'QR');

    expect(sale.id, 42);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/v1/sales/checkout');
    expect(jsonDecode(requests.single.body), {'payment_method': 'QR'});
  });
}
