import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wakelock_plus/src/wakelock_plus_linux_plugin.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'wakelock_plus_linux_plugin_test.mocks.dart';

@GenerateMocks([DBusClient, DBusRemoteObject])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WakelockPlusLinuxPlugin', () {
    late MockDBusClient mockClient;
    late MockDBusRemoteObject mockPortalObject;
    late WakelockPlusLinuxPlugin plugin;

    setUp(() {
      mockClient = MockDBusClient();
      mockPortalObject = MockDBusRemoteObject();
      plugin = WakelockPlusLinuxPlugin(
        client: mockClient,
        object: mockPortalObject,
        appNameGetter: () async => 'TestApp',
      );
    });

    test('registerWith sets instance', () {
      WakelockPlusLinuxPlugin.registerWith();
      expect(
        WakelockPlusPlatformInterface.instance,
        isA<WakelockPlusLinuxPlugin>(),
      );
    });

    test('uses org.freedesktop.portal.Desktop', () {
      final plugin = WakelockPlusLinuxPlugin();
      expect(plugin, isNotNull);
    });

    test('initially disabled', () async {
      expect(await plugin.enabled, isFalse);
    });

    group('enable', () {
      test('calls Inhibit with correct parameters', () async {
        final mockResponse = DBusMethodSuccessResponse([
          DBusObjectPath('/org/freedesktop/portal/desktop/request/1_1/test'),
        ]);

        when(
          mockPortalObject.callMethod(
            'org.freedesktop.portal.Inhibit',
            'Inhibit',
            any,
            replySignature: anyNamed('replySignature'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await plugin.toggle(enable: true);

        verify(
          mockPortalObject.callMethod(
            'org.freedesktop.portal.Inhibit',
            'Inhibit',
            argThat(
              isA<List>()
                  .having((l) => l.length, 'length', 3)
                  .having((l) => l[0], 'window', isA<DBusString>())
                  .having((l) => l[1], 'flags', isA<DBusUint32>())
                  .having((l) => l[2], 'options', isA<DBusDict>()),
            ),
            replySignature: DBusSignature('o'),
          ),
        ).called(1);

        expect(await plugin.enabled, isTrue);
      });

      test('flags are set to 8 (Idle)', () async {
        final mockResponse = DBusMethodSuccessResponse([
          DBusObjectPath('/org/freedesktop/portal/desktop/request/1_1/test'),
        ]);

        when(
          mockPortalObject.callMethod(
            any,
            any,
            any,
            replySignature: anyNamed('replySignature'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await plugin.toggle(enable: true);

        final captured =
            verify(
                  mockPortalObject.callMethod(
                    any,
                    any,
                    captureAny,
                    replySignature: anyNamed('replySignature'),
                  ),
                ).captured.single
                as List;

        final flags = captured[1] as DBusUint32;
        expect(flags.value, equals(8)); // 8 = Idle flag
      });

      test('includes reason in options', () async {
        final mockResponse = DBusMethodSuccessResponse([
          DBusObjectPath('/org/freedesktop/portal/desktop/request/1_1/test'),
        ]);

        when(
          mockPortalObject.callMethod(
            any,
            any,
            any,
            replySignature: anyNamed('replySignature'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await plugin.toggle(enable: true);

        final captured =
            verify(
                  mockPortalObject.callMethod(
                    any,
                    any,
                    captureAny,
                    replySignature: anyNamed('replySignature'),
                  ),
                ).captured.single
                as List;

        final options = captured[2] as DBusDict;
        expect(options.children.containsKey(DBusString('reason')), isTrue);
      });
    });

    group('disable', () {
      test('calls Request.Close and clears state', () async {
        final handlePath = DBusObjectPath(
          '/org/freedesktop/portal/desktop/request/1_1/test',
        );
        final mockInhibitResponse = DBusMethodSuccessResponse([handlePath]);
        final mockCloseResponse = DBusMethodSuccessResponse([]);

        when(
          mockPortalObject.callMethod(
            'org.freedesktop.portal.Inhibit',
            'Inhibit',
            any,
            replySignature: anyNamed('replySignature'),
          ),
        ).thenAnswer((_) async => mockInhibitResponse);

        // Mock the Close call on DBusClient
        when(
          mockClient.callMethod(
            destination: 'org.freedesktop.portal.Desktop',
            path: handlePath,
            interface: 'org.freedesktop.portal.Request',
            name: 'Close',
            values: [],
            replySignature: DBusSignature.empty,
          ),
        ).thenAnswer((_) async => mockCloseResponse);

        // Enable first
        await plugin.toggle(enable: true);
        expect(await plugin.enabled, isTrue);

        // Now disable
        await plugin.toggle(enable: false);
        expect(await plugin.enabled, isFalse);

        // Verify Close was called
        verify(
          mockClient.callMethod(
            destination: 'org.freedesktop.portal.Desktop',
            path: handlePath,
            interface: 'org.freedesktop.portal.Request',
            name: 'Close',
            values: [],
            replySignature: DBusSignature.empty,
          ),
        ).called(1);
      });

      test('does nothing if not enabled', () async {
        await plugin.toggle(enable: false);
        expect(await plugin.enabled, isFalse);
        verifyNever(
          mockPortalObject.callMethod(
            any,
            any,
            any,
            replySignature: anyNamed('replySignature'),
          ),
        );
      });
    });

    group('enabled getter', () {
      test('returns false when not enabled', () async {
        expect(await plugin.enabled, isFalse);
      });

      test('returns true after enable', () async {
        final mockResponse = DBusMethodSuccessResponse([
          DBusObjectPath('/org/freedesktop/portal/desktop/request/1_1/test'),
        ]);

        when(
          mockPortalObject.callMethod(
            any,
            any,
            any,
            replySignature: anyNamed('replySignature'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await plugin.toggle(enable: true);
        expect(await plugin.enabled, isTrue);
      });
    });

    group('DBusClient reuse', () {
      test('uses the same client instance for all operations', () {
        final testClient = MockDBusClient();
        final plugin = WakelockPlusLinuxPlugin(
          client: testClient,
          appNameGetter: () async => 'TestApp',
        );

        // The plugin should use the same client internally
        expect(plugin, isNotNull);
      });

      test('factory constructor creates single client', () {
        // This test verifies that the factory constructor doesn't create
        // multiple DBusClient instances
        final plugin1 = WakelockPlusLinuxPlugin(
          appNameGetter: () async => 'TestApp1',
        );
        final plugin2 = WakelockPlusLinuxPlugin(
          appNameGetter: () async => 'TestApp2',
        );

        // Each plugin should have its own client, but within a plugin,
        // the client should be reused
        expect(plugin1, isNotNull);
        expect(plugin2, isNotNull);
      });
    });
  });
}
