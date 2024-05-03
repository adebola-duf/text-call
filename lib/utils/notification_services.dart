import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_call/models/message.dart';
import 'package:text_call/models/recent.dart';

import 'package:text_call/screens/sent_message_screen.dart';
import 'package:text_call/text_call.dart';
import 'package:text_call/utils/utils.dart';

Future<String> _getCallerName(String phoneNumber) async {
  final db = await getDatabase();
  final data = await db
      .query('contacts', where: 'phoneNumber = ?', whereArgs: [phoneNumber]);
  await db.close();
  if (data.isEmpty) {
    return changeIntlToLocal(intlPhoneNumber: phoneNumber);
  } else {
    return data[0]['name'] as String;
  }
}

Future<void> messageHandler(RemoteMessage message) async {
  final String notificationPurpose = message.data['purpose'];
  if (notificationPurpose == 'access_request') {
    final String recentId = message.data['message_id'];
    final String requesterPhoneNumber = message.data['requester_phone_number'];

    final String requesterName = await _getCallerName(requesterPhoneNumber);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('recentId', recentId);
    await prefs.setString('requesterPhoneNumber', requesterPhoneNumber);

    createAwesomeNotification(
      title: '$requesterName is Requesting access to see a message',
      body: 'Click on this notification to see this message',
      notificationPurpose: NotificationPurpose.forAccessRequest,
    );
    return;
  }

  if (notificationPurpose == 'request_status') {
    final String recentId = message.data['message_id'];
    final String accessRequestStatus = message.data['access_request_status'];
    final String requesteePhoneNumber = message.data['requestee_phone_number'];
    final String requesteeName = await _getCallerName(requesteePhoneNumber);

    if (accessRequestStatus == 'granted') {
      final DateTime currentDate = DateTime.now();
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('recentId', recentId);
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: int.parse(
              '12${currentDate.day}${currentDate.hour}${currentDate.minute}${currentDate.second}'),
          channelKey: 'access_requests_channel',
          color: Colors.black,
          title: 'Access Request Update',
          body: '$requesteeName has granted your request. Tap to see message',
          autoDismissible: true,
          category: NotificationCategory.Call,
          fullScreenIntent: true,
          wakeUpScreen: true,
          backgroundColor: Colors.green,
          locked: false,
        ),
      );
    }
    if (accessRequestStatus == 'denied') {
      final DateTime currentDate = DateTime.now();

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: int.parse(
              '11${currentDate.day}${currentDate.hour}${currentDate.minute}${currentDate.second}'),
          channelKey: 'access_requests_channel',
          color: Colors.black,
          title: 'Access Request Update',
          body: '$requesteeName has denied your request',
          autoDismissible: true,
          category: NotificationCategory.Call,
          fullScreenIntent: true,
          wakeUpScreen: true,
          backgroundColor: Colors.green,
          locked: false,
        ),
      );
    }
  }

  final String callMessage = message.data['message'];
  final String callerPhoneNumber = message.data['caller_phone_number'];
  final Map<String, int> backgroundColorMap = {
    'red': int.parse(message.data['red']),
    'blue': int.parse(message.data['blue']),
    'green': int.parse(message.data['green']),
    'alpha': int.parse(message.data['alpha']),
  };
  final String recentId = message.data['message_id'];
  final String callerName = await _getCallerName(callerPhoneNumber);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('callMessage', callMessage);
  await prefs.setString('callerPhoneNumber', callerPhoneNumber);
  await prefs.setString('recentId', recentId);
  await prefs.setString(
    'backgroundColor',
    json.encode(backgroundColorMap),
  );
  createAwesomeNotification(
    title: '$callerName is calling',
    body: 'Might be urgent. Schrödinger\'s message',
    notificationPurpose: NotificationPurpose.forCall,
  );
}

Future<void> fcmSetup() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      await messageHandler(message);
    },
  );
}

// From what I understand, the onBackgroudMessage handler is in a different isolate and thus has no access to the data from the main isolate.
// Hence everything is pretty much null.
// https://stackoverflow.com/questions/65664203/flutter-global-variable-becomes-null-when-app-is-in-background
// https://github.com/firebase/flutterfi  re/issues/1878
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await messageHandler(message);
}

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.channelKey == 'calls_channel') {
      print('call ended');
      return;
    }
    print('notification dismissed');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'REJECT_CALL') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final String? callMessage = prefs.getString('callMessage');
      final String? backgroundColor = prefs.getString('backgroundColor');
      final String? callerPhoneNumber = prefs.getString('callerPhoneNumber');
      final String? recentId = prefs.getString('recentId');

      final url = Uri.https(
          'text-call-backend.onrender.com', 'call/rejected/$callerPhoneNumber');
      http.get(url);

      final db = await getDatabase();
      final newRecent = Recent.withoutContactObject(
          category: RecentCategory.incomingRejected,
          message: Message(
            message: callMessage!,
            backgroundColor: deJsonifyColor(json.decode(backgroundColor!)),
          ),
          id: recentId!,
          phoneNumber: callerPhoneNumber!);

      db.insert(
        'recents',
        {
          'id': newRecent.id,
          'backgroundColorAlpha': newRecent.message.backgroundColor.alpha,
          'backgroundColorRed': newRecent.message.backgroundColor.red,
          'backgroundColorGreen': newRecent.message.backgroundColor.green,
          'backgroundColorBlue': newRecent.message.backgroundColor.blue,
          'message': newRecent.message.message,
          'callTime': newRecent.callTime.toString(),
          'phoneNumber': newRecent.contact.phoneNumber,
          'categoryName': newRecent.category.name,
        },
      );
      await db.close();
    } else if (receivedAction.buttonKeyPressed == 'ACCEPT_CALL') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final String? callerPhoneNumber = prefs.getString('callerPhoneNumber');

      final url = Uri.https(
          'text-call-backend.onrender.com', 'call/accepted/$callerPhoneNumber');
      http.get(url);

      final bool? isUserLoggedIn = prefs.getBool('isUserLoggedIn');
      print('isUserLoggedIn $isUserLoggedIn');
      if (isUserLoggedIn != true) {
        showFlushBar(Colors.blue, 'You have to login to see the message.',
            FlushbarPosition.TOP, TextCall.navigatorKey.currentContext!);
        return;
      }
      final String? callMessage = prefs.getString('callMessage');
      final String? backgroundColor = prefs.getString('backgroundColor');
      final Message message = Message(
        message: callMessage!,
        backgroundColor: deJsonifyColor(json.decode(backgroundColor!)),
      );
      Navigator.of(TextCall.navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) => SentMessageScreen(
            message: message,
            howSmsIsOpened: HowSmsIsOpened.notFromTerminatedForPickedCall,
          ),
        ),
      );
    } else if (receivedAction.buttonKeyPressed == 'GRANT_ACCESS') {
      sendAccessRequestStatus(AccessRequestStatus.granted);
    } else if (receivedAction.buttonKeyPressed == 'DENY_ACCESS') {
      sendAccessRequestStatus(AccessRequestStatus.denied);
    }

    // for when the notification is tapped and not any buttons
    // notification ids beginning with 11, when we tap on them, nothing should happen. It would just open the app sha. This should be used for when notificatino shown is to tell you access request denied
    // notification ids beginning with 10, when we tap on them, we should be shown a message screen. this one shoudld be used when we are sending do you want to grant or deny access request.
    // notification ids beginning with 12, when we tap on them, we should be shown a message screen. but this one should be used when an access request has been granted.
    // so that you don't end up seeing the grant and deny buttons on the message screen.
    else {
      if (receivedAction.channelKey == 'access_requests_channel') {
        if (receivedAction.id!.toString().startsWith('11')) {
          return;
        }

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? recentId = prefs.getString('recentId');

        final db = await getDatabase();
        final data =
            await db.query('recents', where: 'id = ?', whereArgs: [recentId]);

        if (data.isEmpty) {
          return;
        }
        Navigator.of(TextCall.navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => SentMessageScreen(
              howSmsIsOpened: receivedAction.id!.toString().startsWith('10')
                  ? HowSmsIsOpened.notfromTerminatedForRequestAccess
                  : HowSmsIsOpened.notFromTerminatedToShowMessage,
              message: Message(
                message: data[0]['message'] as String,
                backgroundColor: Color.fromARGB(
                  data[0]['backgroundColorAlpha'] as int,
                  data[0]['backgroundColorRed'] as int,
                  data[0]['backgroundColorGreen'] as int,
                  data[0]['backgroundColorBlue'] as int,
                ),
              ),
            ),
          ),
        );
      } else if (receivedAction.channelKey == 'calls_channel') {}
    }
  }
}