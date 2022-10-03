// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Interop library for Firebase Functions Node.js SDK.
///
/// Use [functions] object as main entry point.
///
/// To create your cloud function see corresponding namespaces on
/// [FirebaseFunctions] class:
///
/// - [FirebaseFunctions.https] for creating HTTPS triggers
/// - [FirebaseFunctions.database] for creating Realtime Database triggers
/// - [FirebaseFunctions.firestore] for creating Firestore triggers
///
/// Here is an example of creating and exporting an HTTPS trigger:
///
///     import 'package:firebase_functions_interop/firebase_functions_interop.dart';
///
///     void main() {
///       // Registers helloWorld function under path prefix `/helloWorld`
///       functions['helloWorld'] = functions.https
///         .onRequest(helloWorld);
///     }
///
///     // Simple function which returns a response with a body containing
///     // "Hello world".
///     void helloWorld(ExpressHttpRequest request) {
///       request.response.writeln("Hello world");
///       request.response.close();
///     }
library firebase_functions_interop;

import 'dart:async';
import 'dart:js';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:meta/meta.dart';
import 'package:node_interop/http.dart';
import 'package:node_interop/node.dart';
import 'package:node_interop/util.dart';

import 'src/bindings.dart' as js;
import 'src/express.dart';

export 'package:firebase_admin_interop/firebase_admin_interop.dart';
export 'package:node_io/node_io.dart' show HttpRequest, HttpResponse;

export 'src/bindings.dart'
    show CloudFunction, HttpsFunction, EventAuthInfo, RuntimeOptions;
export 'src/express.dart';

part 'src/https.dart';

final js.FirebaseFunctions _module = require('firebase-functions');

/// Main library object which can be used to create and register Firebase
/// Cloud functions.
final FirebaseFunctions functions = FirebaseFunctions._(_module);

typedef DataEventHandler<T> = FutureOr<void> Function(
    T data, EventContext context);
typedef ChangeEventHandler<T> = FutureOr<void> Function(
    Change<T> data, EventContext context);

/// Global namespace for Firebase Cloud Functions functionality.
///
/// Use [functions] as a singleton instance of this class to export function
/// triggers.
class FirebaseFunctions {
  final js.FirebaseFunctions _functions;

  /// Configuration object for Firebase functions.
  final Config config;

  /// HTTPS functions.
  final HttpsFunctions https;

  /// Realtime Database functions.
  final DatabaseFunctions database;

  /// Firestore functions.
  final FirestoreFunctions firestore;

  /// Pubsub functions.
  final PubsubFunctions pubsub;

  /// Storage functions.
  final StorageFunctions storage;

  /// Authentication functions.
  final AuthFunctions auth;

  FirebaseFunctions._(js.FirebaseFunctions functions)
      : _functions = functions,
        config = Config._(functions),
        https = HttpsFunctions._(functions),
        database = DatabaseFunctions._(functions),
        firestore = FirestoreFunctions._(functions),
        pubsub = PubsubFunctions._(functions),
        storage = StorageFunctions._(functions),
        auth = AuthFunctions._(functions);

  /// Configures the regions to which to deploy and run a function.
  ///
  /// For a list of valid values see https://firebase.google.com/docs/functions/locations
  FirebaseFunctions region(String region) {
    return FirebaseFunctions._(_functions.region(region));
  }

  /// Configures memory allocation and timeout for a function.
  FirebaseFunctions runWith(js.RuntimeOptions options) {
    return FirebaseFunctions._(_functions.runWith(options));
  }
