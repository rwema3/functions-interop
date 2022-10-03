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

  /// Export [function] under specified [key].
  ///
  /// For HTTPS functions the [key] defines URL path prefix.
  operator []=(String key, dynamic function) {
    assert(function is js.HttpsFunction || function is js.CloudFunction);
    setExport(key, function);
  }
}

/// Provides access to environment configuration of Firebase Functions.
///
/// See also:
/// - [https://firebase.google.com/docs/functions/config-env](https://firebase.google.com/docs/functions/config-env)
class Config {
  final js.FirebaseFunctions _functions;

  Config._(this._functions);

  /// Returns configuration value specified by it's [key].
  ///
  /// This method expects keys to be fully qualified (namespaced), e.g.
  /// `some_service.client_secret` or `some_service.url`.
  /// This is different from native JS implementation where namespaced
  /// keys are broken into nested JS object structure, e.g.
  /// `functions.config().some_service.client_secret`.
  dynamic get(String key) {
    final List<String> parts = key.split('.');
    var data = dartify(_functions.config());
    var value;
    for (var subKey in parts) {
      if (data is! Map) return null;
      value = data[subKey];
      if (value == null) break;
      data = value;
    }
    return value;
  }
}

/// Container for events that change state, such as Realtime Database or
/// Cloud Firestore `onWrite` and `onUpdate`.
class Change<T> {
  Change(this.after, this.before);

  /// The state after the event.
  final T after;

  /// The state prior to the event.
  final T before;
}

/// The context in which an event occurred.
///
/// An EventContext describes:
///
///   * The time an event occurred.
///   * A unique identifier of the event.
///   * The resource on which the event occurred, if applicable.
///   * Authorization of the request that triggered the event, if applicable
///     and available.
class EventContext {
  EventContext._(this.auth, this.authType, this.eventId, this.eventType,
      this.params, this.resource, this.timestamp);

  factory EventContext(js.EventContext data) {
    return new EventContext._(
      data.auth,
      data.authType,
      data.eventId,
      data.eventType,
      new Map<String, String>.from(dartify(data.params)),
      data.resource,
      DateTime.parse(data.timestamp),
    );
  }

  /// Authentication information for the user that triggered the function.
  ///
  /// For an unauthenticated user, this field is null. For event types that do
  /// not provide user information (all except Realtime Database) or for
  /// Firebase admin users, this field will not exist.
  final js.EventAuthInfo auth;

  /// The level of permissions for a user.
  ///
  /// Valid values are: `ADMIN`, `USER`, `UNAUTHENTICATED` and `null`.
  final String authType;

  /// The event’s unique identifier.
  final String eventId;

  /// Type of event.
  final String eventType;

  /// An object containing the values of the wildcards in the path parameter
  /// provided to the ref() method for a Realtime Database trigger.
  final Map<String, String> params;

  /// The resource that emitted the event.
  final js.EventContextResource resource;

  /// Timestamp for the event.
  final DateTime timestamp;
}
