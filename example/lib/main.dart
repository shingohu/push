import 'package:flutter/material.dart';
import 'package:push/push.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("state: $state");
  }

  PushConnector pushConnector = PushConnector();

  String pushMessage = "";
  String pushToken = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pushConnector.requestPermission().then((success) {
      print("是否有通知权限:$success");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('推送demo'),
          centerTitle: true,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: double.infinity,
                child: SelectableText(
                  pushToken,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Container(
                  height: 200,
                  child: SelectableText(
                    pushMessage,
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
                onPressed: () {
                  pushConnector.register(onLaunch: (pushType, message) {
                    pushMessage = message.toString();
                    setState(() {});
                  }, onToken: (pushType, token) {
                    print("token: $token");
                    this.pushToken = "${pushType}:$token";
                    setState(() {});
                  });
                },
                child: Text(
                  "注册",
                  style: TextStyle(fontSize: 18),
                )),
            TextButton(
                onPressed: () {
                  pushConnector.unregister();
                  pushMessage = "";
                  pushToken = "";
                  setState(() {});
                },
                child: Text(
                  "取消注册",
                  style: TextStyle(fontSize: 18),
                )),
            TextButton(
                onPressed: () {
                  pushConnector.openNotificationSettings();
                },
                child: Text(
                  "跳转通知",
                  style: TextStyle(fontSize: 18),
                ))
          ],
        ),
      ),
    );
  }
}
