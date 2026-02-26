import 'package:niskala_service_gen/src/util/type_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('TypeMapper', () {
    late TypeMapper mapper;
    final modelMap = {
      'UserModel': 'lib/models/user_model.dart',
      'OrderModel': 'lib/models/order_model.dart',
    };

    setUp(() {
      mapper = TypeMapper(modelMap);
    });

    test('should format strings using StringX', () {
      expect(mapper.toPascalCase('hello_world'), equals('HelloWorld'));
      expect(mapper.toCamelCase('HelloWorld'), equals('helloWorld'));
      expect(mapper.toSnakeCase('HelloWorld'), equals('hello_world'));
    });

    test('should detect reserved keywords', () {
      expect(mapper.isReserved('class'), isTrue);
      expect(mapper.isReserved('something'), isFalse);
    });

    test('should find best model match', () {
      expect(mapper.findBestModelMatch('UserModel'), equals('UserModel'));
      // Case insensitive match
      expect(mapper.findBestModelMatch('usermodel'), equals('UserModel'));
      // Suffix matching
      expect(mapper.findBestModelMatch('UserRequest'), equals('UserModel'));
    });

    test('should map array to set and matched transformed name', () {
      final map = {'UserSet': 'lib/models/user_set.dart'};
      final customMapper = TypeMapper(map);
      // UserArray -> userarray -> userset -> UserSet
      expect(customMapper.findBestModelMatch('UserArray'), equals('UserSet'));

      // userarrayrequest -> usersetmodel
      final map2 = {'UserSetModel': 'lib/models/user_set_model.dart'};
      final customMapper2 = TypeMapper(map2);
      expect(
        customMapper2.findBestModelMatch('UserArrayRequest'),
        equals('UserSetModel'),
      );
    });

    test('should handle direct match with normalization', () {
      final map = {'User_Model': 'lib/models/user_model.dart'};
      final customMapper = TypeMapper(map);
      expect(
        customMapper.findBestModelMatch('UserModel'),
        equals('User_Model'),
      );
    });
  });
}
