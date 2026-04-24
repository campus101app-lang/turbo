import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class PublicRequestPayScreen extends StatefulWidget {
  final String requestNumber;
  const PublicRequestPayScreen({super.key, required this.requestNumber});

  @override
  State<PublicRequestPayScreen> createState() => _PublicRequestPayScreenState();
}

class _PublicRequestPayScreenState extends State<PublicRequestPayScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiService.getPublicRequest(widget.requestNumber);
  }

  void _retry() {
    setState(() {
      _future = apiService.getPublicRequest(widget.requestNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Payment')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              message: apiService.parseError(snap.error),
              onRetry: _retry,
            );
          }
          final data = snap.data?['request'] as Map<String, dynamic>?;
          if (data == null) {
            return _ErrorState(
              message: 'Request details are unavailable.',
              onRetry: _retry,
            );
          }
          return _RequestBody(request: data, onRefresh: _retry);
        },
      ),
    );
  }
}

class _RequestBody extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onRefresh;
  const _RequestBody({required this.request, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final status = (request['status'] ?? 'pending').toString();
    final amount = (request['amount'] is num)
        ? (request['amount'] as num).toDouble()
        : double.tryParse('${request['amount']}') ?? 0;
    final asset = (request['asset'] ?? 'USDC').toString();
    final symbol = asset == 'NGNT' ? 'N' : '\$';
    final payee = request['user'] as Map<String, dynamic>? ?? {};
    final payeeName = (payee['businessName'] ?? payee['username'] ?? 'DayFi merchant').toString();
    final stellarAddress = (payee['stellarPublicKey'] ?? '').toString();
    final createdAt = DateTime.tryParse('${request['createdAt'] ?? ''}');
    final expiresAt = DateTime.tryParse('${request['expiresAt'] ?? ''}');

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '$symbol${NumberFormat('#,##0.00').format(amount)} $asset',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text('Request: ${request['requestNumber'] ?? ''}'),
          const SizedBox(height: 8),
          Text('Pay to: $payeeName'),
          if (request['note'] != null && '${request['note']}'.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Note: ${request['note']}'),
          ],
          const SizedBox(height: 20),
          _StatusBanner(status: status),
          const SizedBox(height: 20),
          if (stellarAddress.isNotEmpty) ...[
            _AddressCard(address: stellarAddress),
            const SizedBox(height: 16),
          ],
          if (status == 'pending') ...[
            ElevatedButton(
              onPressed: stellarAddress.isEmpty
                  ? null
                  : () async {
                      final uri = Uri.parse('web+stellar:pay?destination=$stellarAddress&amount=$amount&asset_code=$asset');
                      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open wallet app.')),
                        );
                      }
                    },
              child: const Text('Pay With Wallet App'),
            ),
            TextButton(onPressed: onRefresh, child: const Text('I already paid - Refresh status')),
          ] else if (status == 'paid') ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 44),
            const SizedBox(height: 6),
            const Text('Payment received.'),
          ],
          if (createdAt != null) Text('Created: ${DateFormat('MMM d, yyyy').format(createdAt)}'),
          if (expiresAt != null) Text('Expires: ${DateFormat('MMM d, yyyy').format(expiresAt)}'),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color color;
    String message;
    if (s == 'paid') {
      color = Colors.green;
      message = 'Paid';
    } else if (s == 'expired') {
      color = Colors.orange;
      message = 'Expired';
    } else if (s == 'cancelled') {
      color = Colors.red;
      message = 'Cancelled';
    } else {
      color = Theme.of(context).colorScheme.primary;
      message = 'Pending payment';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
      ),
      child: SelectableText(address, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Unable to load payment request',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
