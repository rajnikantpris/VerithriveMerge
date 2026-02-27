// This is a simple test file to verify authentication functionality
// Run this in debug mode to test the implementation

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_service.dart';
import '../core/values/sharePrefrenceConst.dart';

class AuthTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Auth Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                bool isLoggedIn = await AuthService.isLoggedIn();
                print('Is logged in: $isLoggedIn');
                Get.snackbar('Auth Status', 'Logged in: $isLoggedIn');
              },
              child: Text('Check Login Status'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool isGuest = await AuthService.isGuest();
                print('Is guest: $isGuest');
                Get.snackbar('Guest Status', 'Guest: $isGuest');
              },
              child: Text('Check Guest Status'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool canAccess = await AuthService.requireAuth();
                print('Can access: $canAccess');
              },
              child: Text('Test Auth Requirement'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool canCallApi = await AuthService.canMakeApiCall('profession-types/all');
                print('Can call home API: $canCallApi');
                Get.snackbar('API Access', 'Home API: $canCallApi');
              },
              child: Text('Test Home API Access'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool canCallApi = await AuthService.canMakeApiCall('bookings/list');
                print('Can call bookings API: $canCallApi');
                Get.snackbar('API Access', 'Bookings API: $canCallApi');
              },
              child: Text('Test Bookings API Access'),
            ),
          ],
        ),
      ),
    );
  }
}
