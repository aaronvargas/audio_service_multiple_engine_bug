import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

late MyAudioHandler _audioHandler;
class MyAudioHandler extends BaseAudioHandler
    with
        QueueHandler, // mix in default queue callback implementations
        SeekHandler {
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Native called background task: $task"); //simpleTask will be emitted here.
    return Future.value(true);
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
      androidNotificationChannelName: 'Music playback',
    ),
  );

  await Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  void startAudioService() {
    _audioHandler.playbackState.add(_audioHandler.playbackState.value.copyWith(
        playing: true,
        controls: [
          MediaControl.pause,
          MediaControl.stop,
        ]
    ));

    _audioHandler.mediaItem.add(
      MediaItem(
        id: Random().nextInt(99999).toString(),
        album: 'album',
        title: 'title',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton(onPressed: (){
              startAudioService();
            }, child: Text("start audio service")),
            OutlinedButton(onPressed: (){
              Workmanager().registerOneOffTask("oneOffTask", "backgroundWork");
            }, child: Text("run background task")),
            OutlinedButton(onPressed: (){
              flutterLocalNotificationsPlugin.initialize(InitializationSettings(android: AndroidInitializationSettings("ic_launcher")), onSelectNotification: onSelectNotification);
              var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
                  "androidChannel", "androidChannelName",
                  channelDescription: "androidChannelDesc",
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'New Notification available');
              flutterLocalNotificationsPlugin.show(0, "title", "message", NotificationDetails(android: androidPlatformChannelSpecifics),
                  payload: "responsePayload");
            }, child: Text("show notification")),
            Text("now click the notification, crashes...")
          ],
        ),
      ),
    );
  }
}

Future<void>? onSelectNotification(String? payload) {
  print("onSelectNotification(payload: $payload)");
  return null;
}
