// lib/services/notification_service.dart
//
// Advanced Notification Service for Nigerian Market
// Push notifications, email/SMS alerts, in-app notifications, compliance notifications
//

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType {
  transaction,
  payment,
  invoice,
  expense,
  compliance,
  system,
  marketing,
  reminder,
}

enum NotificationPriority { low, medium, high, urgent }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  String? _fcmToken;
  final StreamController<InAppNotification> _notificationController =
      StreamController.broadcast();

  // Notification preferences
  static const String _preferencesKey = 'notification_preferences';
  static const String _tokenKey = 'fcm_token';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications (mobile only)
      if (!kIsWeb) {
        await _initializeLocalNotifications();
      }

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Request permissions (mobile only)
      if (!kIsWeb) {
        await _requestPermissions();
      }

      // Load preferences
      await _loadPreferences();

      _isInitialized = true;
      debugPrint(
        'Notification service initialized${kIsWeb ? ' (web mode)' : ''}',
      );
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      rethrow;
    }
  }

  // Send push notification
  Future<void> sendPushNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? userId,
    String? deviceId,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Check if notifications are enabled for this type
      if (!await _isNotificationTypeEnabled(type)) {
        debugPrint('Notifications disabled for type: $type');
        return;
      }

      // Create notification payload
      final payload = {
        'title': title,
        'body': body,
        'type': type.name,
        'priority': priority.name,
        'userId': userId,
        'deviceId': deviceId,
        'data': data ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send via Firebase Cloud Messaging (server-side)
      // For now, we'll simulate this with local notification (mobile only)
      if (!kIsWeb) {
        await _showLocalNotification(
          title: title,
          body: body,
          type: type,
          data: data,
          priority: priority,
        );
      }

      // Add to in-app notifications
      _addInAppNotification(
        title: title,
        body: body,
        type: type,
        data: data,
        priority: priority,
      );

      debugPrint('Push notification sent: $title');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  // Send transaction notification
  Future<void> sendTransactionNotification({
    required String transactionId,
    required String type,
    required double amount,
    required String currency,
    String? counterparty,
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    final title = 'Transaction $type';
    final body =
        '$currency ${amount.toStringAsFixed(2)} ${counterparty != null ? 'from $counterparty' : ''}';

    await sendPushNotification(
      title: title,
      body: body,
      type: NotificationType.transaction,
      data: {
        'transactionId': transactionId,
        'amount': amount,
        'currency': currency,
        'counterparty': counterparty,
        'transactionType': type,
      },
      priority: priority,
    );
  }

  // Send payment notification
  Future<void> sendPaymentNotification({
    required String paymentId,
    required double amount,
    required String currency,
    String? invoiceNumber,
    String? customerEmail,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    final title = 'Payment Received';
    final body =
        '$currency ${amount.toStringAsFixed(2)}${invoiceNumber != null ? ' for invoice $invoiceNumber' : ''}';

    await sendPushNotification(
      title: title,
      body: body,
      type: NotificationType.payment,
      data: {
        'paymentId': paymentId,
        'amount': amount,
        'currency': currency,
        'invoiceNumber': invoiceNumber,
        'customerEmail': customerEmail,
      },
      priority: priority,
    );

    // Send email notification
    await _sendEmailNotification(
      subject: title,
      body: _generatePaymentEmailBody(
        amount,
        currency,
        invoiceNumber,
        customerEmail,
      ),
      recipient: customerEmail,
    );
  }

  // Send invoice notification
  Future<void> sendInvoiceNotification({
    required String invoiceId,
    required String invoiceNumber,
    required double amount,
    required String currency,
    String? customerEmail,
    String? dueDate,
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    final title = 'Invoice $invoiceNumber';
    final body =
        '$currency ${amount.toStringAsFixed(2)}${dueDate != null ? ' due $dueDate' : ''}';

    await sendPushNotification(
      title: title,
      body: body,
      type: NotificationType.invoice,
      data: {
        'invoiceId': invoiceId,
        'invoiceNumber': invoiceNumber,
        'amount': amount,
        'currency': currency,
        'customerEmail': customerEmail,
        'dueDate': dueDate,
      },
      priority: priority,
    );

    // Send email notification
    await _sendEmailNotification(
      subject: title,
      body: _generateInvoiceEmailBody(invoiceNumber, amount, currency, dueDate),
      recipient: customerEmail,
    );
  }

  // Send expense notification
  Future<void> sendExpenseNotification({
    required String expenseId,
    required String category,
    required double amount,
    required String currency,
    String? description,
    NotificationPriority priority = NotificationPriority.medium,
  }) async {
    final title = 'Expense Submitted';
    final body = '$category: $currency ${amount.toStringAsFixed(2)}';

    await sendPushNotification(
      title: title,
      body: body,
      type: NotificationType.expense,
      data: {
        'expenseId': expenseId,
        'category': category,
        'amount': amount,
        'currency': currency,
        'description': description,
      },
      priority: priority,
    );
  }

  // Send compliance notification
  Future<void> sendComplianceNotification({
    required String title,
    required String body,
    required String complianceType,
    String? actionUrl,
    NotificationPriority priority = NotificationPriority.urgent,
  }) async {
    await sendPushNotification(
      title: title,
      body: body,
      type: NotificationType.compliance,
      data: {'complianceType': complianceType, 'actionUrl': actionUrl},
      priority: priority,
    );

    // Send SMS for urgent compliance notifications
    if (priority == NotificationPriority.urgent) {
      await _sendSMSNotification(body: body);
    }
  }

  // Send reminder notification
  Future<void> sendReminderNotification({
    required String title,
    required String body,
    required String reminderType,
    DateTime? scheduledTime,
    NotificationPriority priority = NotificationPriority.low,
  }) async {
    await sendPushNotification(
      title: title,
      body: body,
      type: NotificationType.reminder,
      data: {
        'reminderType': reminderType,
        'scheduledTime': scheduledTime?.toIso8601String(),
      },
      priority: priority,
    );
  }

  // Get in-app notifications stream
  Stream<InAppNotification> get inAppNotifications =>
      _notificationController.stream;

  // Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('in_app_notifications') ?? [];
      return notifications.where((n) => !n.contains('read:')).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('in_app_notifications') ?? [];

      // Update notification status
      final updatedNotifications = notifications.map((n) {
        if (n.contains('id:$notificationId')) {
          return '$n|read:true';
        }
        return n;
      }).toList();

      await prefs.setStringList('in_app_notifications', updatedNotifications);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('in_app_notifications');

      debugPrint('All notifications cleared');
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));
      debugPrint('Notification preferences updated');
    } catch (e) {
      debugPrint('Error updating preferences: $e');
    }
  }

  // Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesStr = prefs.getString(_preferencesKey);

      if (preferencesStr != null) {
        return NotificationPreferences.fromJson(jsonDecode(preferencesStr));
      }

      // Return default preferences
      return NotificationPreferences();
    } catch (e) {
      debugPrint('Error getting preferences: $e');
      return NotificationPreferences();
    }
  }

Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings, 
    );

    // FIX: Add the 'settings:' label here
    await _localNotifications.initialize(
      settings: initializationSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle your logic when a notification is tapped
      },
    );

    await _createNotificationChannels();
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    await _firebaseMessaging.requestPermission();

    // Get token
    _fcmToken = await _firebaseMessaging.getToken();
    await _saveFCMToken(_fcmToken!);

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _saveFCMToken(token);
    });

    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen(_handleFirebaseMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFirebaseMessage);
  }

  Future<void> _requestPermissions() async {
    // Request notification permissions
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _createNotificationChannels() async {
    const androidChannels = [
      AndroidNotificationChannel(
        'transactions',
        'Transactions',
        description: 'Transaction related notifications',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'payments',
        'Payments',
        description: 'Payment related notifications',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'invoices',
        'Invoices',
        description: 'Invoice related notifications',
        importance: Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'compliance',
        'Compliance',
        description: 'Compliance related notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'reminders',
        'Reminders',
        description: 'Reminder notifications',
        importance: Importance.low,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    ];

    for (final channel in androidChannels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    required NotificationPriority priority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type), // Channel ID
      'Default Notifications', // Channel Name (Static)
      channelDescription:
          'Notifications for app updates', // Channel Description
      importance: _getImportance(priority),
      priority: _getAndroidPriority(priority),
      sound: const RawResourceAndroidNotificationSound('notification'),
      // Note: title and body do NOT go here anymore
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Fix: Use 'iOS' instead of 'ios'
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      ), // Added 'id:'
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  void _addInAppNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    required NotificationPriority priority,
  }) {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      data: data ?? {},
      priority: priority,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notificationController.add(notification);

    // Save to persistent storage
    _saveInAppNotification(notification);
  }

  Future<void> _saveInAppNotification(InAppNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('in_app_notifications') ?? [];
      notifications.add(jsonEncode(notification.toJson()));
      await prefs.setStringList('in_app_notifications', notifications);
    } catch (e) {
      debugPrint('Error saving in-app notification: $e');
    }
  }

  Future<void> _handleFirebaseMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'DayFi',
        body: notification.body ?? 'New notification',
        type: _parseNotificationType(message.data),
        data: message.data,
        priority: _parseNotificationPriority(message.data),
      );

      _addInAppNotification(
        title: notification.title ?? 'DayFi',
        body: notification.body ?? 'New notification',
        type: _parseNotificationType(message.data),
        data: message.data,
        priority: _parseNotificationPriority(message.data),
      );
    }
  }

  NotificationType _parseNotificationType(Map<String, dynamic>? data) {
    final typeStr = data?['type'] as String?;
    switch (typeStr) {
      case 'transaction':
        return NotificationType.transaction;
      case 'payment':
        return NotificationType.payment;
      case 'invoice':
        return NotificationType.invoice;
      case 'expense':
        return NotificationType.expense;
      case 'compliance':
        return NotificationType.compliance;
      case 'system':
        return NotificationType.system;
      case 'marketing':
        return NotificationType.marketing;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.system;
    }
  }

  NotificationPriority _parseNotificationPriority(Map<String, dynamic>? data) {
    final priorityStr = data?['priority'] as String?;
    switch (priorityStr) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.medium;
    }
  }

  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return 'transactions';
      case NotificationType.payment:
        return 'payments';
      case NotificationType.invoice:
        return 'invoices';
      case NotificationType.compliance:
        return 'compliance';
      case NotificationType.reminder:
        return 'reminders';
      default:
        return 'transactions';
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  // 1. Change the return type to Priority
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        // -2 corresponds to min
        return Priority.min;
      case NotificationPriority.medium:
        // 0 corresponds to default
        return Priority.defaultPriority;
      case NotificationPriority.high:
        // 1 corresponds to high
        return Priority.high;
      case NotificationPriority.urgent:
        // 2 corresponds to max
        return Priority.max;
      default:
        return Priority.defaultPriority;
    }
  }

  Future<bool> _isNotificationTypeEnabled(NotificationType type) async {
    final preferences = await getPreferences();
    switch (type) {
      case NotificationType.transaction:
        return preferences.enableTransactionNotifications;
      case NotificationType.payment:
        return preferences.enablePaymentNotifications;
      case NotificationType.invoice:
        return preferences.enableInvoiceNotifications;
      case NotificationType.expense:
        return preferences.enableExpenseNotifications;
      case NotificationType.compliance:
        return preferences.enableComplianceNotifications;
      case NotificationType.system:
        return preferences.enableSystemNotifications;
      case NotificationType.marketing:
        return preferences.enableMarketingNotifications;
      case NotificationType.reminder:
        return preferences.enableReminderNotifications;
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint('FCM token saved: $token');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _loadPreferences() async {
    await getPreferences(); // This will load and cache preferences
  }

  Future<void> _sendEmailNotification({
    required String subject,
    required String body,
    required String? recipient,
  }) async {
    // This would integrate with an email service like SendGrid, Mailgun, etc.
    // For now, we'll simulate it
    debugPrint('Email notification sent to $recipient: $subject');
  }

  Future<void> _sendSMSNotification({required String body}) async {
    // This would integrate with an SMS service like Twilio, MessageBird, etc.
    // For now, we'll simulate it
    debugPrint('SMS notification sent: $body');
  }

  String _generatePaymentEmailBody(
    double amount,
    String currency,
    String? invoiceNumber,
    String? customerEmail,
  ) {
    return '''
Dear $customerEmail,

We're pleased to inform you that we've received your payment of $currency ${amount.toStringAsFixed(2)}${invoiceNumber != null ? ' for invoice $invoiceNumber' : ''}.

Payment Details:
- Amount: $currency ${amount.toStringAsFixed(2)}
- Date: ${DateTime.now().toString().split(' ')[0]}
- Invoice: ${invoiceNumber ?? 'N/A'}

Thank you for your business! The payment has been processed and will be reflected in your account shortly.

Best regards,
DayFi Team
    ''';
  }

  String _generateInvoiceEmailBody(
    String invoiceNumber,
    double amount,
    String currency,
    String? dueDate,
  ) {
    return '''
Dear Customer,

This is a reminder that your invoice $invoiceNumber for $currency ${amount.toStringAsFixed(2)} is due${dueDate != null ? ' on $dueDate' : ''}.

Invoice Details:
- Invoice Number: $invoiceNumber
- Amount: $currency ${amount.toStringAsFixed(2)}
- Due Date: ${dueDate ?? 'Immediate'}

Please ensure payment is made on time to avoid any late fees. You can make payment directly through the DayFi app.

If you have any questions or need assistance, please don't hesitate to contact us.

Best regards,
DayFi Team
    ''';
  }

  // Cleanup
  void dispose() {
    _notificationController.close();
  }
}

// Notification data classes
class InAppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
  });

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      data: json['data'] as Map<String, dynamic>,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'priority': priority.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class NotificationPreferences {
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSMSNotifications;
  final bool enableTransactionNotifications;
  final bool enablePaymentNotifications;
  final bool enableInvoiceNotifications;
  final bool enableExpenseNotifications;
  final bool enableComplianceNotifications;
  final bool enableSystemNotifications;
  final bool enableMarketingNotifications;
  final bool enableReminderNotifications;

  const NotificationPreferences({
    this.enablePushNotifications = true,
    this.enableEmailNotifications = true,
    this.enableSMSNotifications = false,
    this.enableTransactionNotifications = true,
    this.enablePaymentNotifications = true,
    this.enableInvoiceNotifications = true,
    this.enableExpenseNotifications = true,
    this.enableComplianceNotifications = true,
    this.enableSystemNotifications = true,
    this.enableMarketingNotifications = false,
    this.enableReminderNotifications = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enablePushNotifications: json['enablePushNotifications'] as bool? ?? true,
      enableEmailNotifications:
          json['enableEmailNotifications'] as bool? ?? true,
      enableSMSNotifications: json['enableSMSNotifications'] as bool? ?? false,
      enableTransactionNotifications:
          json['enableTransactionNotifications'] as bool? ?? true,
      enablePaymentNotifications:
          json['enablePaymentNotifications'] as bool? ?? true,
      enableInvoiceNotifications:
          json['enableInvoiceNotifications'] as bool? ?? true,
      enableExpenseNotifications:
          json['enableExpenseNotifications'] as bool? ?? true,
      enableComplianceNotifications:
          json['enableComplianceNotifications'] as bool? ?? true,
      enableSystemNotifications:
          json['enableSystemNotifications'] as bool? ?? true,
      enableMarketingNotifications:
          json['enableMarketingNotifications'] as bool? ?? false,
      enableReminderNotifications:
          json['enableReminderNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSMSNotifications': enableSMSNotifications,
      'enableTransactionNotifications': enableTransactionNotifications,
      'enablePaymentNotifications': enablePaymentNotifications,
      'enableInvoiceNotifications': enableInvoiceNotifications,
      'enableExpenseNotifications': enableExpenseNotifications,
      'enableComplianceNotifications': enableComplianceNotifications,
      'enableSystemNotifications': enableSystemNotifications,
      'enableMarketingNotifications': enableMarketingNotifications,
      'enableReminderNotifications': enableReminderNotifications,
    };
  }
}
