import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:launchdarkly_flutter/launchdarkly_config.dart';
import 'package:launchdarkly_flutter/launchdarkly_flutter.dart';
import 'package:launchdarkly_flutter/launchdarkly_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('launchdarkly_flutter');

  final Map<String, void Function(String)> flagListeners = {};

  final Map<String, void Function(List<String>)> allFlagsListeners = {};

  final LaunchdarklyFlutter launchdarklyFlutter = LaunchdarklyFlutter(
      flagListeners: flagListeners, allFlagsListeners: allFlagsListeners);

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'init') {
        Map<dynamic, dynamic> args = methodCall.arguments;
        if (args['mobileKey'] == null) {
          return false;
        } else if (args['userKey'] == null) {
          return true;
        } else {
          return true;
        }
      }

      if (methodCall.method == 'identify') {
        return true;
      }

      if (methodCall.method == 'boolVariation') {
        return true;
      } else if (methodCall.method == 'boolVariationFallback') {
        Map<dynamic, dynamic> args = methodCall.arguments;
        return args['fallback'];
      }

      if (methodCall.method == 'stringVariation') {
        return 'something';
      } else if (methodCall.method == 'stringVariationFallback') {
        Map<dynamic, dynamic> args = methodCall.arguments;
        return args['fallback'];
      }

      if (methodCall.method == 'registerFeatureFlagListener') {
        return true;
      }

      if (methodCall.method == 'unregisterFeatureFlagListener') {
        return true;
      }

      if (methodCall.method == 'allFlags') {
        Map<String, dynamic> response = jsonDecode('{"flagKey":true}');
        return response;
      }

      if (methodCall.method == 'registerAllFlagsListener') {
        return true;
      }

      if (methodCall.method == 'unregisterAllFlagsListener') {
        return true;
      }

      return launchdarklyFlutter.handlerMethodCalls(methodCall);
    });
  });

  tearDown(() {
    flagListeners.clear();
    allFlagsListeners.clear();
    channel.setMockMethodCallHandler(null);
  });

  test('init with no mobile key', () async {
    expect(await launchdarklyFlutter.init(null, null), false);
  });

  test('init with no user', () async {
    expect(await launchdarklyFlutter.init('MOBILE_KEY', null), true);
  });

  test('init with mobile key and user', () async {
    expect(await launchdarklyFlutter.init('MOBILE_KEY', 'USER_ID'), true);
  });

  test('init with config', () async {
    final configExpected = LaunchDarklyConfig(
      allAttributesPrivate: true,
      privateAttributes: {'test'},
    );
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      Map<dynamic, dynamic> args = methodCall.arguments;
      final configActual = args['config'].cast<String, dynamic>();
      if (configActual['allAttributesPrivate'] != true) {
        return false;
      }
      final privateAttributes =
          configActual['privateAttributes'].cast<String>();
      if (!listEquals(['test'], privateAttributes)) {
        return false;
      }
      return true;
    });
    final result = await launchdarklyFlutter.init(
      'MOBILE_KEY',
      'USER_ID',
      config: configExpected,
    );
    expect(result, true);
  });

  test('init with all arguments', () async {
    const userExpected = {
      "secondary": 'testSecondaryKey',
      "ip": 'testIp',
      "country": 'testCountry',
      "avatar": 'testAvatar',
      "email": 'testEmail',
      "name": 'testName',
      "firstName": 'testFirstName',
      "lastName": 'testLastName',
    };
    const customExpected = {
      'string': 'value',
      'boolean': true,
      'number': 10,
      'null': null,
    };
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      Map<dynamic, dynamic> args = methodCall.arguments;
      final userActual = args['user'].cast<String, String>();
      if (!mapEquals(userExpected, userActual)) {
        return false;
      }
      final customActual = args['custom'].cast<String, dynamic>();
      if (!mapEquals(customExpected, customActual)) {
        return false;
      }
      final privateAttributes = args['privateAttributes']?.cast<String>();
      if (privateAttributes != null && privateAttributes.isNotEmpty) {
        return false;
      }
      return true;
    });
    final result = await launchdarklyFlutter.init(
      'MOBILE_KEY',
      'USER_ID',
      user: LaunchDarklyUser(
        secondaryKey: 'testSecondaryKey',
        ip: 'testIp',
        country: 'testCountry',
        avatar: 'testAvatar',
        email: 'testEmail',
        name: 'testName',
        firstName: 'testFirstName',
        lastName: 'testLastName',
      ),
      custom: customExpected,
    );
    expect(result, true);
  });

  test('init with all arguments but user key', () async {
    final configExpected = LaunchDarklyConfig(
      allAttributesPrivate: true,
      privateAttributes: {'test'},
    );
    const userExpected = {
      "secondary": 'testSecondaryKey',
      "ip": 'testIp',
      "country": 'testCountry',
      "avatar": 'testAvatar',
      "email": 'testEmail',
      "name": 'testName',
      "firstName": 'testFirstName',
      "lastName": 'testLastName',
    };
    const customExpected = {
      'string': 'value',
      'boolean': true,
      'number': 10,
      'null': null,
    };
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      Map<dynamic, dynamic> args = methodCall.arguments;
      final userActual = args['user'].cast<String, String>();
      if (!mapEquals(userExpected, userActual)) {
        return false;
      }
      final customActual = args['custom'].cast<String, dynamic>();
      if (!mapEquals(customExpected, customActual)) {
        return false;
      }
      final privateAttributes = args['privateAttributes']?.cast<String>();
      if (privateAttributes != null && privateAttributes.isNotEmpty) {
        return false;
      }
      return true;
    });
    final result = await launchdarklyFlutter.init(
      'MOBILE_KEY',
      null,
      user: LaunchDarklyUser(
        secondaryKey: 'testSecondaryKey',
        ip: 'testIp',
        country: 'testCountry',
        avatar: 'testAvatar',
        email: 'testEmail',
        name: 'testName',
        firstName: 'testFirstName',
        lastName: 'testLastName',
      ),
      custom: customExpected,
      config: configExpected,
    );
    expect(result, true);
  });

  test('init with all private arguments', () async {
    final userExpected = {
      "secondary": 'testSecondaryKey',
      "ip": 'testIp',
      "country": 'testCountry',
      "avatar": 'testAvatar',
      "email": 'testEmail',
      "name": 'testName',
      "firstName": 'testFirstName',
      "lastName": 'testLastName',
    };
    const customExpected = {
      'string': 'value',
      'boolean': true,
      'number': 10,
      'null': null,
    };
    final expectedPrivateAttributes = [
      'secondary',
      'ip',
      'country',
      'avatar',
      'email',
      'name',
      'firstName',
      'lastName',
      'string',
      'null',
      'boolean',
      'number',
    ]..sort();
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      Map<dynamic, dynamic> args = methodCall.arguments;
      final userActual = args['user'].cast<String, String>();
      if (!mapEquals(userExpected, userActual)) {
        return false;
      }
      final customActual = args['custom'].cast<String, dynamic>();
      if (!mapEquals(customExpected, customActual)) {
        return false;
      }
      final privateAttributes = args['privateAttributes']?.cast<String>()
        ..sort();
      if (!listEquals(expectedPrivateAttributes, privateAttributes)) {
        return false;
      }
      return true;
    });
    final result = await launchdarklyFlutter.init(
      'MOBILE_KEY',
      'USER_ID',
      user: LaunchDarklyUser(
        privateSecondaryKey: 'testSecondaryKey',
        privateIp: 'testIp',
        privateCountry: 'testCountry',
        privateAvatar: 'testAvatar',
        privateEmail: 'testEmail',
        privateName: 'testName',
        privateFirstName: 'testFirstName',
        privateLastName: 'testLastName',
      ),
      privateCustom: customExpected,
    );
    expect(result, true);
  });

  test('init with all private arguments but userId', () async {
    final userExpected = {
      "secondary": 'testSecondaryKey',
      "ip": 'testIp',
      "country": 'testCountry',
      "avatar": 'testAvatar',
      "email": 'testEmail',
      "name": 'testName',
      "firstName": 'testFirstName',
      "lastName": 'testLastName',
    };
    const customExpected = {
      'string': 'value',
      'boolean': true,
      'number': 10,
      'null': null,
    };
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      Map<dynamic, dynamic> args = methodCall.arguments;
      final userActual = args['user'].cast<String, String>();
      if (!mapEquals(userExpected, userActual)) {
        return false;
      }
      final customActual = args['custom'].cast<String, dynamic>();
      if (!mapEquals(customExpected, customActual)) {
        return false;
      }
      return true;
    });
    final result = await launchdarklyFlutter.init(
      'MOBILE_KEY',
      null,
      user: LaunchDarklyUser(
        privateSecondaryKey: 'testSecondaryKey',
        privateIp: 'testIp',
        privateCountry: 'testCountry',
        privateAvatar: 'testAvatar',
        privateEmail: 'testEmail',
        privateName: 'testName',
        privateFirstName: 'testFirstName',
        privateLastName: 'testLastName',
      ),
      privateCustom: customExpected,
    );
    expect(result, true);
  });

  test('identify with no user', () async {
    expect(await launchdarklyFlutter.identify(null), true);
  });

  test('identify with all arguments', () async {
    const userExpected = {
      "secondary": 'testSecondaryKey',
      "ip": 'testIp',
      "country": 'testCountry',
      "avatar": 'testAvatar',
      "email": 'testEmail',
      "name": 'testName',
      "firstName": 'testFirstName',
      "lastName": 'testLastName',
    };
    const customExpected = {
      'string': 'value',
      'boolean': true,
      'number': 10,
      'null': null,
    };
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      Map<dynamic, dynamic> args = methodCall.arguments;
      final userActual = args['user'].cast<String, String>();
      if (!mapEquals(userExpected, userActual)) {
        return false;
      }
      final customActual = args['custom'].cast<String, dynamic>();
      if (!mapEquals(customExpected, customActual)) {
        return false;
      }
      final privateAttributes = args['privateAttributes']?.cast<String>();
      if (privateAttributes != null && privateAttributes.isNotEmpty) {
        return false;
      }
      return true;
    });
    final result = await launchdarklyFlutter.identify(
      'USER_ID',
      user: LaunchDarklyUser(
        secondaryKey: 'testSecondaryKey',
        ip: 'testIp',
        country: 'testCountry',
        avatar: 'testAvatar',
        email: 'testEmail',
        name: 'testName',
        firstName: 'testFirstName',
        lastName: 'testLastName',
      ),
      custom: customExpected,
    );
    expect(result, true);
  });

  test('identify with all private arguments', () async {
    const userExpected = {
      "secondary": 'testSecondaryKey',
      "ip": 'testIp',
      "country": 'testCountry',
      "avatar": 'testAvatar',
      "email": 'testEmail',
      "name": 'testName',
      "firstName": 'testFirstName',
      "lastName": 'testLastName',
    };
    final customExpected = {
      'string': 'value',
      'boolean': true,
      'number': 10,
      'null': null,
    };
    final expectedPrivateAttrbiutes = [
      'secondary',
      'ip',
      'country',
      'avatar',
      'email',
      'name',
      'firstName',
      'lastName',
      'string',
      'null',
      'boolean',
      'number',
    ]..sort();
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      Map<dynamic, dynamic> args = methodCall.arguments;
      final userActual = args['user'].cast<String, String>();
      if (!mapEquals(userExpected, userActual)) {
        return false;
      }
      final customActual = args['custom'].cast<String, dynamic>();
      if (!mapEquals(customExpected, customActual)) {
        return false;
      }
      final privateAttributes = args['privateAttributes']?.cast<String>()
        ..sort();
      if (!listEquals(expectedPrivateAttrbiutes, privateAttributes)) {
        return false;
      }
      return true;
    });
    final result = await launchdarklyFlutter.identify(
      'USER_ID',
      user: LaunchDarklyUser(
        privateSecondaryKey: 'testSecondaryKey',
        privateIp: 'testIp',
        privateCountry: 'testCountry',
        privateAvatar: 'testAvatar',
        privateEmail: 'testEmail',
        privateName: 'testName',
        privateFirstName: 'testFirstName',
        privateLastName: 'testLastName',
      ),
      privateCustom: customExpected,
    );
    expect(result, true);
  });

  test('boolVariation with no fallback', () async {
    expect(await launchdarklyFlutter.boolVariation('ipPermitted', null), true);
  });

  test('boolVariation with fallback true', () async {
    expect(await launchdarklyFlutter.boolVariation('ipPermitted', true), true);
  });

  test('boolVariation with fallback false', () async {
    expect(
        await launchdarklyFlutter.boolVariation('ipPermitted', false), false);
  });

  test('stringVariation with no fallback', () async {
    expect(await launchdarklyFlutter.stringVariation('ipPermitted', null),
        'something');
  });

  test('stringVariation with fallback', () async {
    expect(await launchdarklyFlutter.stringVariation('ipPermitted', 'nothing'),
        'nothing');
  });

  test('registerFeatureFlagListener with flagKey and callback null', () async {
    String flagKey = 'flagKey';
    await launchdarklyFlutter.registerFeatureFlagListener(null, null);
    expect(flagListeners[flagKey], null);
  });

  test('registerFeatureFlagListener with callback null', () async {
    String flagKey = 'flagKey';
    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, null);
    expect(flagListeners[flagKey], null);
  });

  test('registerFeatureFlagListener with flagKey null', () async {
    String flagKey = 'flagKey';
    void Function(String) callback = (flagKey) {};

    await launchdarklyFlutter.registerFeatureFlagListener(null, callback);
    expect(flagListeners[flagKey], null);
  });

  test('registerFeatureFlagListener registering flagKey with callback',
      () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return flagKey;
    };

    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);
  });

  test(
      'registerFeatureFlagListener registering flagKey that already exists with different callback',
      () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return flagKey;
    };

    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);

    Function(String) callback2 = (flagKey) {
      return '';
    };

    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback2);
    expect(flagListeners[flagKey], callback2);
  });

  test('unregisterFeatureFlagListener with flagKey null', () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return 'callback';
    };
    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);
    await launchdarklyFlutter.unregisterFeatureFlagListener(null);
    expect(flagListeners[flagKey], callback);
  });

  test('unregisterFeatureFlagListener flagKey', () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return 'callback';
    };
    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);
    await launchdarklyFlutter.unregisterFeatureFlagListener(flagKey);
    expect(flagListeners[flagKey], null);
  });

  test('non-existing method callback', () async {
    String flagKey = 'flagKey';

    Map<String, String> arguments = {};
    arguments['flagKey'] = flagKey;

    try {
      await channel.invokeMethod('non-existing-method', arguments);
      fail("exception not thrown");
    } catch (e) {
      expect(e, isInstanceOf<MissingPluginException>());
    }
  });

  test(
      'registerFeatureFlagListener callback for existing callbackRegisterFeatureFlagListener method without arguments',
      () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return flagKey;
    };

    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);

    expect(
        await channel.invokeMethod('callbackRegisterFeatureFlagListener', null),
        false);
  });

  test(
      'registerFeatureFlagListener callback for existing callbackRegisterFeatureFlagListener with no flagKey argument',
      () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return flagKey;
    };

    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);

    Map<String, String> arguments = {};

    expect(
        await channel.invokeMethod(
            'callbackRegisterFeatureFlagListener', arguments),
        false);
  });

  test(
      'registerFeatureFlagListener callback for existing callbackRegisterFeatureFlagListener method with wrong flagKey',
      () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return flagKey;
    };

    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);

    Map<String, String> arguments = {};
    arguments['flagKey'] = 'wrong-flag-key';

    expect(
        await channel.invokeMethod(
            'callbackRegisterFeatureFlagListener', arguments),
        false);
  });

  test(
      'registerFeatureFlagListener callback for existing callbackRegisterFeatureFlagListener method with correct flagKey',
      () async {
    String flagKey = 'flagKey';
    Function(String) callback = (flagKey) {
      return flagKey;
    };

    await launchdarklyFlutter.registerFeatureFlagListener(flagKey, callback);
    expect(flagListeners[flagKey], callback);

    Map<String, String> arguments = {};
    arguments['flagKey'] = flagKey;

    expect(
        await channel.invokeMethod(
            'callbackRegisterFeatureFlagListener', arguments),
        true);
  });

  test('allFlags', () async {
    Map<String, dynamic> response = await launchdarklyFlutter.allFlags();

    expect(response['flagKey'], true);
  });

  test('registerAllFlagsListener with callback null', () async {
    String listenerId = 'listenerId';
    await launchdarklyFlutter.registerAllFlagsListener(listenerId, null);
    expect(allFlagsListeners[listenerId], null);
  });

  test('registerAllFlagsListener with listenerId null', () async {
    String listenerId = 'listenerId';
    void Function(List<String>) callback = (flagKeys) {};

    await launchdarklyFlutter.registerAllFlagsListener(null, callback);
    expect(allFlagsListeners[listenerId], null);
  });

  test('registerAllFlagsListener registering listenerId with callback',
      () async {
    String listenerId = 'listenerId';
    Function(List<String>) callback = (flagKeys) {
      return flagKeys;
    };

    await launchdarklyFlutter.registerAllFlagsListener(listenerId, callback);
    expect(allFlagsListeners[listenerId], callback);
  });

  test(
      'registerAllFlagsListener registering listenerId that already exists with different callback',
      () async {
    String listenerId = 'listenerId';
    Function(List<String>) callback = (flagKeys) {
      return flagKeys;
    };

    await launchdarklyFlutter.registerAllFlagsListener(listenerId, callback);
    expect(allFlagsListeners[listenerId], callback);

    Function(List<String>) callback2 = (flagKeys) {
      return '';
    };

    await launchdarklyFlutter.registerAllFlagsListener(listenerId, callback2);
    expect(allFlagsListeners[listenerId], callback2);
  });

  test('unregisterAllFlagsListener with listenerId null', () async {
    String listenerId = 'listenerId';
    Function(List<String>) callback = (flagKey) {
      return 'callback';
    };
    await launchdarklyFlutter.registerAllFlagsListener(listenerId, callback);
    expect(allFlagsListeners[listenerId], callback);
    await launchdarklyFlutter.unregisterAllFlagsListener(null);
    expect(allFlagsListeners[listenerId], callback);
  });

  test('unregisterAllFlagsListener listenerId', () async {
    String listenerId = 'listenerId';
    Function(List<String>) callback = (flagKeys) {
      return flagKeys;
    };
    await launchdarklyFlutter.registerAllFlagsListener(listenerId, callback);
    expect(allFlagsListeners[listenerId], callback);
    await launchdarklyFlutter.unregisterAllFlagsListener(listenerId);
    expect(allFlagsListeners[listenerId], null);
  });

  test(
      'registerAllFlagsListener callback for existing callbackAllFlagsListener method with no flagKeys arguments',
      () async {
    String listenerId = 'listenerId';
    Function(List<String>) callback = (flagKeys) {
      return flagKeys;
    };

    await launchdarklyFlutter.registerAllFlagsListener(listenerId, callback);
    expect(allFlagsListeners[listenerId], callback);

    expect(await channel.invokeMethod('callbackAllFlagsListener', null), false);
  });

  test(
      'registerAllFlagsListener callback for existing callbackAllFlagsListener method with no listeners',
      () async {
    Map<String, List<String>> arguments = {};
    arguments['flagKeys'] = ['flagKey1', 'flagKey2'];

    expect(await channel.invokeMethod('callbackAllFlagsListener', arguments),
        false);
  });

  test(
      'registerAllFlagsListener callback for existing callbackAllFlagsListener method with correct listenerId',
      () async {
    String listenerId = 'listenerId';
    Function(List<String>) callback = (flagKeys) {
      return flagKeys;
    };

    await launchdarklyFlutter.registerAllFlagsListener(listenerId, callback);
    expect(allFlagsListeners[listenerId], callback);

    Map<String, List<String>> arguments = {};
    arguments['flagKeys'] = ['flagKey1', 'flagKey2'];

    expect(await channel.invokeMethod('callbackAllFlagsListener', arguments),
        true);
  });
}
