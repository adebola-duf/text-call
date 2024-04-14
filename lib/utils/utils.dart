import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:text_call/widgets/message_writer.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

void createAwesomeNotification({String? title, String? body}) {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 123,
      channelKey: 'basic_channel',
      color: Colors.white,
      title: title,
      body: body,
      category: NotificationCategory.Call,
      fullScreenIntent: true,
      autoDismissible: false,
      wakeUpScreen: true,
      backgroundColor: Colors.orange,
      locked: true,
      chronometer: Duration.zero, // Chronometer starts to count at 0 seconds
      timeoutAfter: const Duration(seconds: 20),
    ),
    actionButtons: [
      NotificationActionButton(
        key: 'ACCEPT',
        label: 'Accept Call',
        color: Colors.green,
        autoDismissible: true,
      ),
      NotificationActionButton(
        key: 'REJECT',
        label: 'Reject Call',
        color: Colors.red,
        autoDismissible: true,
        actionType: ActionType.SilentBackgroundAction,
      ),
    ],
  );
}

String changeLocalToIntl({required String localPhoneNumber}) =>
    '+234${localPhoneNumber.substring(1)}';

void showMessageWriterModalSheet(
    {required BuildContext context,
    required String calleeName,
    required String calleePhoneNumber}) {
  showModalBottomSheet(
    isDismissible: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    context: context,
    builder: (ctx) => MessageWriter(
      calleeName: calleeName,
      calleePhoneNumber: calleePhoneNumber,
    ),
  );
}

Future<sql.Database> getDatabase() async {
  final databasesPath = await sql.getDatabasesPath();

  final db = await sql.openDatabase(
    path.join(databasesPath, 'contacts.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute(
          'CREATE TABLE contacts (phoneNumber TEXT PRIMARY KEY, name TEXT)');
      await db.execute(
          'CREATE TABLE recents (callTime TEXT PRIMARY KEY, phoneNumber TEXT, name TEXT, categoryName TEXT)');
    },
  );
  return db;
}
