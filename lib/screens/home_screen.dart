
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/fcm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FCMService _fcmService = FCMService();

  String title = 'Campus Updates';
  String asset = 'default';
  String lastHandler = 'No message received';
  String diagnostic = 'Waiting for a cloud message';
  String messageId = 'None';

  int receiptCount = 0;

  void handleMessage(RemoteMessage message, String handler) {
    if (!mounted) return;

    final action = message.data['action'];
    final selectedAsset = message.data['asset'];

    setState(() {
      receiptCount++;
      lastHandler = handler;
      messageId = message.messageId ?? 'Not provided';

      if (action != 'update_ui') {
        diagnostic = 'Unsupported or missing action';
        return;
      }

      if (selectedAsset != 'default' &&
          selectedAsset != 'promo') {
        diagnostic = 'Unsupported or missing asset';
        return;
      }

      asset = selectedAsset!;

      title = asset == 'promo'
          ? 'Special Offer from Cloud Courier'
          : 'Campus Updates';

      diagnostic = 'Valid payload received';
    });
  }

  @override
  void initState() {
    super.initState();

    _fcmService.initialize(
      onMessage: handleMessage,
    ).catchError((Object error) {
      if (mounted) {
        setState(() {
          diagnostic = 'FCM setup error: $error';
        });
      }
    });
  }

  void demoInvalidPayload() {
    handleMessage(
      const RemoteMessage(
        data: {
          'action': 'update_ui',
          'asset': 'unknown',
        },
        messageId: 'local-demo-t4',
      ),
      'Local simulation (not FCM)',
    );
  }

  @override
  void dispose() {
    _fcmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPromo = asset == 'promo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cloud Courier',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0766D9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/$asset.png',
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF071642),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              isPromo
                  ? 'Save 20% on your next delivery with our limited-time promotion.'
                  : 'Stay updated with the latest campus announcements.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),

            if (isPromo) ...[
              const SizedBox(height: 16),
              const Chip(
                label: Text('Use Code: CLOUD20'),
              ),
            ],

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('Last Handler: $lastHandler'),
                  const SizedBox(height: 8),
                  Text('Receipt Count: $receiptCount'),
                  const SizedBox(height: 8),
                  Text('Message ID: $messageId'),
                  const SizedBox(height: 12),
                  Text(
                    diagnostic,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: diagnostic.startsWith('Unsupported')
                          ? Colors.red
                          : const Color(0xFF071642),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: demoInvalidPayload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0766D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'Demo T4: Invalid Payload',
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Demo uses local data, not a delivered Firebase message.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
