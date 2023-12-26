import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final LocalAuthentication auth;
  bool _supportState = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    auth = LocalAuthentication();
    auth.isDeviceSupported().then((bool isSuported) => setState(() {
          _supportState = isSuported;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('INstagram'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (_supportState)
            const Text('this device is supported')
          else
            const Text('this device is not supported'),
          const Divider(
            height: 100,
          ),
          Divider(
            height: 100,
          ),
          ElevatedButton(onPressed: _authenticate, child: Text('Authenticate')),
        ],
      ),
    );
  }

  Future<void> _getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();

    print('list of availableBiometrics : $availableBiometrics');

    if (!mounted) {
      return;
    }
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
          localizedReason: 'Verify It\'s You ',
          options: const AuthenticationOptions(
              stickyAuth: true, biometricOnly: false));

      print("Authenticated : $authenticated");
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
