import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_call/models/contact.dart';
import 'package:text_call/models/message.dart';
import 'package:text_call/models/recent.dart';
import 'package:text_call/screens/auth_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:text_call/screens/phone_page_screen.dart';
import 'package:text_call/screens/sent_message_screen.dart';
import 'package:text_call/utils/utils.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

String? kToken;
String? kCallMessage;
String? kCallerPhoneNumber;
String? kCallerName;
Map<String, int>? kBackgroundColorMap;

Future<void> _messageHandler(RemoteMessage message) async {
  kCallMessage = message.data['message'];
  kCallerPhoneNumber = message.data['caller_phone_number'];
  kBackgroundColorMap = message.data['background_color'];
  kBackgroundColorMap = {
    'red': int.parse(message.data['red']),
    'blue': int.parse(message.data['blue']),
    'green': int.parse(message.data['green']),
    'alpha': int.parse(message.data['alpha']),
  };
  final db = await getDatabase();
  final data = await db.query('contacts',
      where: 'phoneNumber = ?', whereArgs: [kCallerPhoneNumber]);

  if (data.isEmpty) {
    kCallerName = 'Unknown';
  } else {
    kCallerName = data[0]['name'] as String;
  }
  await db.close();
  createAwesomeNotification(
    title: kCallerName != 'Unknown'
        ? '$kCallerName is calling '
        : '$kCallerPhoneNumber is calling',
    body: 'Might be urgent. Schrödinger\'s message',
  );
}

Future<void> _fcmSetup() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();
  kToken = await fcm.getToken();
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      await _messageHandler(message);
    },
  );
}

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await _messageHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color.fromARGB(255, 151, 73, 214),
          ledColor: Colors.white,
          defaultRingtoneType: DefaultRingtoneType.Ringtone,
          locked: true,
          channelShowBadge: true,
          importance: NotificationImportance.Max,
        )
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group')
      ],
      debug: true);
  await _fcmSetup();
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  ReceivedAction? receivedAction =
      await AwesomeNotifications().getInitialNotificationAction(
    removeFromActionEvents: false,
  );

  runApp(
    receivedAction == null
        ? const ProviderScope(
            child: TextCall(),
          )
        : MaterialApp(
            home: SentMessageScreen(
              backgroundColor: deJsonifyColor(kBackgroundColorMap!),
              message: kCallMessage == null || kCallMessage!.isEmpty
                  ? 'Bolexyro making innovations bro.'
                  : kCallMessage!,
              fromTerminated: true,
            ),
          ),
  );
}

class TextCall extends StatefulWidget {
  const TextCall({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String name = 'Awesome Notifications - Example App';
  static const Color mainColor = Colors.deepPurple;

  @override
  State<TextCall> createState() => _TextCallState();
}

class _TextCallState extends State<TextCall> {
  late Future<bool> _isUserLoggedIn;

  Future<bool> isUserLoggedIn() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? isUserLoggedIn = prefs.getBool('isUserLoggedIn');

    // Save an boolean value to 'repeat' key.
    return isUserLoggedIn ?? false;
  }

  @override
  void initState() {
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod);
    _isUserLoggedIn = isUserLoggedIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
      ),
      navigatorKey: TextCall.navigatorKey,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _isUserLoggedIn,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            if (snapshot.data!) {
              return const PhonePageScreen();
            }
          }
          return const AuthScreen();
        },
      ),
    );
  }
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
      ReceivedAction receivedAction) async {}

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
    if (receivedAction.buttonKeyPressed == 'REJECT') {
      final url = Uri.https('text-call-backend.onrender.com',
          'call/rejected/$kCallerPhoneNumber');
      http.get(url);
    }
    if (receivedAction.buttonKeyPressed == 'ACCEPT') {
      final url = Uri.https('text-call-backend.onrender.com',
          'call/accepted/$kCallerPhoneNumber');
      http.get(url);

      final db = await getDatabase();
      final newRecent = Recent(
        message: Message(
          message: kCallMessage!,
          backgroundColor: deJsonifyColor(kBackgroundColorMap!),
        ),
        contact: Contact(name: kCallerName!, phoneNumber: kCallerPhoneNumber!),
        category: RecentCategory.incomingAccepted,
      );

      db.insert(
        'recents',
        {
          'backgroundColorJson':
              jsonifyColor(newRecent.message.backgroundColor),
          'message': newRecent.message.message,
          'callTime': newRecent.callTime.toString(),
          'phoneNumber': newRecent.contact.phoneNumber,
          'name': newRecent.contact.name,
          'categoryName': newRecent.category.name,
        },
      );
      await db.close();
      Navigator.of(TextCall.navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) => SentMessageScreen(
            backgroundColor: deJsonifyColor(kBackgroundColorMap!),
            message: kCallMessage == null || kCallMessage!.isEmpty
                ? 'Bolexyro making innovations bro.'
                : kCallMessage!,
          ),
        ),
      );
    }
  }
}
