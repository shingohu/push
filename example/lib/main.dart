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

class _MyAppState extends State<MyApp> {
  PushConnector pushConnector = PushConnector();

  String pushMessage = "";
  int i = 0;

  @override
  void initState() {
    super.initState();
    pushConnector.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PUSH DEMO'),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              i.toString(),
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              pushMessage,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  TextButton(
                      onPressed: () {
                        pushConnector.register(onLaunch: (pushType, message) {
                          i++;
                          pushMessage = message.toString();
                          setState(() {});
                        }, onToken: (pushType, token) {
                          print(pushType.name + " token->" + token);
                        });
                      },
                      child: Text(
                        "注册",
                        style: TextStyle(fontSize: 18),
                      )),
                  TextButton(
                      onPressed: () {
                        pushConnector.unregister();
                      },
                      child: Text(
                        "取消注册",
                        style: TextStyle(fontSize: 18),
                      )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
