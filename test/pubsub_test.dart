// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'dart:async';
import 'dart:js';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:node_interop/child_process.dart';
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  App app = initFirebaseApp();

  group('Pubsub', () {
    tearDownAll(() async {
      await app.delete();
    });

    test('save to database', () async {
      var payload = new DateTime.now().toUtc().toIso8601String();
      var command =
          'gcloud -q beta pubsub topics publish testTopic --message \'{"payload":"$payload"}\'';
      var exitCode = await exec(command);
      expect(exitCode, 0);

      var snapshot = await app
          .database()
          .ref('/tests/pubsubToDatabase')
          .once<String>('value');
      while (snapshot.val() != payload) {
        snapshot = await app
            .database()
            .ref('/tests/pubsubToDatabase')
            .once<String>('value');
      }
      expect(snapshot.val(), payload);
    }, timeout: const Timeout(const Duration(seconds: 20)));
  });
}

Future<int> exec(String command) {
  Completer<int> completer = new Completer<int>();
  childProcess.exec(command, new ExecOptions(),
      allowInterop((error, stdout, stderr) {
    int result = (error == null) ? 0 : error.code;
    print(stdout);
    if (error != null) {
      print(error);
      print(stderr);
    }
    completer.complete(result);
  }));
  return completer.future;
}
