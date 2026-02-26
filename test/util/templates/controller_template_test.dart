import 'package:niskala_service_gen/src/util/templates/controller_template.dart';
import 'package:test/test.dart';

void main() {
  late ControllerTemplate template;

  setUp(() {
    template = ControllerTemplate();
  });

  group('ControllerTemplate', () {
    test('generate produces valid Dart code', () {
      final result = template.generate(
        serviceName: 'PurchaseRequisitionService',
        entityName: 'PurchaseRequisition',
        modelName: 'PurchaseRequisitionModel',
        searchKey: 'PurchaseRequisitionNo',
        fileName: 'purchase_requisition_controller',
        packageName: 'niskala_example',
        serviceFileName: 'purchase_requisition_service',
        resolvedImports: const [],
      );

      expect(result, isNotEmpty);
      expect(result, contains('class PurchaseRequisitionController'));
      expect(result, contains('extends AsyncNotifier'));
      expect(result, contains('List<PurchaseRequisitionModel>'));
    });

    test('generate includes pagination fields', () {
      final result = template.generate(
        serviceName: 'OrderService',
        entityName: 'Order',
        modelName: 'OrderModel',
        searchKey: 'OrderNo',
        fileName: 'order_controller',
        packageName: 'my_app',
        serviceFileName: 'order_service',
        resolvedImports: const [],
      );

      expect(result, contains('_kPageSize'));
      expect(result, contains('_currentPage'));
      expect(result, contains('_hasMore'));
    });

    test('generate includes search and filter methods', () {
      final result = template.generate(
        serviceName: 'OrderService',
        entityName: 'Order',
        modelName: 'OrderModel',
        searchKey: 'OrderNo',
        fileName: 'order_controller',
        packageName: 'my_app',
        serviceFileName: 'order_service',
        resolvedImports: const [],
      );

      expect(result, contains('setSearch'));
      expect(result, contains('setFilters'));
      expect(result, contains('loadMore'));
      expect(result, contains('refresh'));
    });

    test('generate includes correct provider name', () {
      final result = template.generate(
        serviceName: 'PurchaseRequisitionService',
        entityName: 'PurchaseRequisition',
        modelName: 'PurchaseRequisitionModel',
        searchKey: 'PurchaseRequisitionNo',
        fileName: 'purchase_requisition_controller',
        packageName: 'niskala_example',
        serviceFileName: 'purchase_requisition_service',
        resolvedImports: const [],
      );

      expect(result, contains('purchaseRequisitionControllerProvider'));
      expect(result, contains('purchaseRequisitionServiceProvider'));
    });

    test('generate includes OData filter imports', () {
      final result = template.generate(
        serviceName: 'OrderService',
        entityName: 'Order',
        modelName: 'OrderModel',
        searchKey: 'OrderNo',
        fileName: 'order_controller',
        packageName: 'my_app',
        serviceFileName: 'order_service',
        resolvedImports: const [],
      );

      expect(result, contains('odata_filter_builder.dart'));
      expect(result, contains('odata_query.dart'));
      expect(result, contains('providers.dart'));
    });

    test('generate includes search field based on entityName', () {
      final result = template.generate(
        serviceName: 'OrderService',
        entityName: 'Order',
        modelName: 'OrderModel',
        searchKey: 'OrderNo',
        fileName: 'order_controller',
        packageName: 'my_app',
        serviceFileName: 'order_service',
        resolvedImports: const [],
      );

      expect(result, contains("odataField: 'OrderNo'"));
    });

    test('generateTest produces valid Dart test', () {
      final result = template.generateTest(
        serviceName: 'OrderService',
        entityName: 'Order',
        modelName: 'OrderModel',
        fileName: 'order_controller',
        packageName: 'my_app',
        serviceFileName: 'order_service',
        resolvedImports: const [],
      );

      expect(result, isNotEmpty);
      expect(result, contains('OrderController Tests'));
      expect(result, contains('controller class exists'));
      expect(result, contains("import 'package:my_app/controllers/"));
    });
  });
}
