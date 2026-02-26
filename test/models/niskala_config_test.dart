import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('NiskalaConfig Full Coverage', () {
    test('fromYaml and getters', () {
      final yaml =
          loadYaml('''
apiDefinitions:
  - name: User
    projection: User.svc
    method: GET
    endpoint: /UserSet
odataEnvironments:
  - name: dev
    baseUrl: https://dev.api.com
    realms: test
    clientId: foo
    clientSecret: bar
niskala_service_gen:
  resource_path: api
  output: build
''')
              as YamlMap;

      final config = NiskalaConfig.fromYaml(yaml, configDir: '/root');
      expect(config.environments.length, equals(1));
      expect(config.endpoints.length, equals(1));
      expect(config.baseDirectory, contains('build'));
      expect(config.outputDirectory, contains('api'));
      expect(config.resourcePath, contains('api'));

      final endpoint = config.endpoints.first;
      expect(endpoint.name, equals('User'));
    });
  });
}
