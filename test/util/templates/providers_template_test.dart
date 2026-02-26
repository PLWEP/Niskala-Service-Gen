import 'package:niskala_service_gen/src/util/templates/providers_template.dart';
import 'package:test/test.dart';

void main() {
  late ProvidersTemplate template;

  setUp(() {
    template = ProvidersTemplate();
  });

  group('ProvidersTemplate', () {
    test('generate produces valid Dart code', () {
      final result = template.generate(
        packageName: 'niskala_example',
        serviceNames: ['PurchaseRequisitionService'],
        serviceFileNames: ['purchase_requisition_service'],
      );

      expect(result, isNotEmpty);
      expect(result, contains('apiClientProvider'));
      expect(result, contains('ODataEncodingInterceptor'));
    });

    test('generate includes service providers', () {
      final result = template.generate(
        packageName: 'my_app',
        serviceNames: ['PurchaseRequisitionService', 'OrderService'],
        serviceFileNames: ['purchase_requisition_service', 'order_service'],
      );

      expect(result, contains('purchaseRequisitionServiceProvider'));
      expect(result, contains('orderServiceProvider'));
    });

    test('generate includes correct imports', () {
      final result = template.generate(
        packageName: 'my_app',
        serviceNames: ['OrderService'],
        serviceFileNames: ['order_service'],
      );

      expect(result, contains("import 'package:dio/dio.dart'"));
      expect(
        result,
        contains("import 'package:flutter_riverpod/flutter_riverpod.dart'"),
      );
      expect(
        result,
        contains("import 'package:my_app/service/api/api_client.dart'"),
      );
      expect(
        result,
        contains("import 'package:my_app/service/api/order_service.dart'"),
      );
    });

    test('generate includes OData encoding interceptor', () {
      final result = template.generate(
        packageName: 'my_app',
        serviceNames: ['OrderService'],
        serviceFileNames: ['order_service'],
      );

      expect(result, contains('class ODataEncodingInterceptor'));
      expect(result, contains('extends Interceptor'));
      expect(result, contains("replaceAll('+', '%20')"));
    });

    test('generate includes autoDispose providers', () {
      final result = template.generate(
        packageName: 'my_app',
        serviceNames: ['OrderService'],
        serviceFileNames: ['order_service'],
      );

      expect(result, contains('Provider.autoDispose'));
    });

    test('generate uses correct camelCase for provider names', () {
      final result = template.generate(
        packageName: 'my_app',
        serviceNames: ['PurchaseReqLinePartService'],
        serviceFileNames: ['purchase_req_line_part_service'],
      );

      expect(result, contains('purchaseReqLinePartServiceProvider'));
    });

    test('generate handles multiple services', () {
      final result = template.generate(
        packageName: 'my_app',
        serviceNames: ['ServiceA', 'ServiceB', 'ServiceC'],
        serviceFileNames: ['service_a', 'service_b', 'service_c'],
      );

      expect(result, contains('serviceAProvider'));
      expect(result, contains('serviceBProvider'));
      expect(result, contains('serviceCProvider'));
    });
  });
}
