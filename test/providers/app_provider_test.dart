import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jame/models/product.dart';
import 'package:jame/providers/app_provider.dart';
import 'package:jame/services/api_client.dart';
import 'package:jame/services/jame_api.dart';
import 'package:jame/services/jame_repository.dart';

void main() {
  test(
    'successful checkout updates provider from the server response',
    () async {
      final requests = <http.Request>[];
      final provider = AppProvider(
        repository: JameRepository(
          api: JameApi(
            client: ApiClient(
              baseUri: Uri.parse('https://api.example.test/api/v1'),
              isWeb: true,
              httpClient: MockClient((request) async {
                requests.add(request);
                if (request.url.path == '/api/v1/sales/checkout') {
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
                }
                return http.Response('[]', 200);
              }),
            ),
          ),
        ),
      );
      provider.addToCart(
        Product(
          userId: 7,
          name: 'Coffee',
          price: 12.5,
          quantity: 5,
          code: 'COFFEE-1',
        ),
      );

      final success = await provider.completeSale(
        7,
        'owner',
        paymentMethod: 'QR',
      );

      expect(success, isTrue);
      expect(provider.cartItems, isEmpty);
      expect(provider.sales.single.id, 42);
      expect(
        requests
            .where((request) => request.method == 'POST')
            .map((request) => request.url.path),
        ['/api/v1/sales/checkout'],
      );
    },
  );

  test('failed checkout preserves the local cart', () async {
    final provider = AppProvider(
      repository: JameRepository(
        api: JameApi(
          client: ApiClient(
            baseUri: Uri.parse('https://api.example.test/api/v1'),
            isWeb: true,
            httpClient: MockClient(
              (_) async => http.Response(
                '{"detail":{"code":"insufficient_stock","message":"Insufficient stock."}}',
                409,
                headers: {'content-type': 'application/json'},
              ),
            ),
          ),
        ),
      ),
    );
    provider.addToCart(
      Product(
        userId: 7,
        name: 'Coffee',
        price: 12.5,
        quantity: 5,
        code: 'COFFEE-1',
      ),
    );

    final success = await provider.completeSale(7, 'owner');

    expect(success, isFalse);
    expect(provider.cartItems, hasLength(1));
    expect(provider.error, contains('Insufficient stock.'));
  });

  test('test_cart_api_failure_is_not_reported_as_empty_cart', () async {
    final provider = AppProvider(
      repository: JameRepository(
        api: JameApi(
          client: ApiClient(
            baseUri: Uri.parse('https://api.example.test/api/v1'),
            isWeb: true,
            httpClient: MockClient(
              (_) async => http.Response(
                '{"detail":{"code":"service_unavailable","message":"Unavailable"}}',
                503,
                headers: {'content-type': 'application/json'},
              ),
            ),
          ),
        ),
      ),
    );
    provider.addToCart(
      Product(
        userId: 7,
        name: 'Coffee',
        price: 12.5,
        quantity: 5,
        code: 'COFFEE-1',
      ),
    );

    await expectLater(provider.loadCartItems(7), throwsA(isA<ApiException>()));

    expect(provider.cartItems, hasLength(1));
    expect(provider.error, isNotNull);
  });

  test('test_report_error_is_exposed_to_provider', () async {
    final provider = AppProvider(
      repository: JameRepository(
        api: JameApi(
          client: ApiClient(
            baseUri: Uri.parse('https://api.example.test/api/v1'),
            isWeb: true,
            httpClient: MockClient(
              (_) async => http.Response(
                '{"detail":{"code":"service_unavailable","message":"Unavailable"}}',
                503,
                headers: {'content-type': 'application/json'},
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      provider.getSalesByDateRange(
        7,
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(provider.error, isNotNull);
  });
}
