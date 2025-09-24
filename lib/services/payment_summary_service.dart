import '../models/payment.dart';
import '../models/payment_summary.dart';
import 'payment_service.dart';
import 'customer_event_service.dart';
import '../helpers/database_helper.dart';

class PaymentSummaryService {
  final PaymentService _paymentService = PaymentService();
  final CustomerEventService _customerEventService = CustomerEventService();

  /// Groups payments by customer event and creates summary objects
  Future<List<PaymentSummary>> getPaymentSummaries() async {
    try {
      // Clean up any orphaned payment records first
      await DatabaseHelper.instance.cleanupOrphanedPayments();

      // Get all payments and customer events
      final payments = await _paymentService.getAllPayments();
      final customerEvents = await _customerEventService.getAllCustomerEvents();

      // Filter out cancelled customer events unless they have payments
      final activeEvents = customerEvents
          .where(
            (event) =>
                event.status != 'cancelled' ||
                payments.any(
                  (payment) => payment.customerEventNo == event.eventNo,
                ),
          )
          .toList();

      // Create a map of customer events for quick lookup
      final eventMap = {for (var event in activeEvents) event.eventNo: event};

      // Group payments by customer event number
      final groupedPayments = <String, List<Payment>>{};
      for (var payment in payments) {
        // Only include payments for active events (or cancelled events with existing payments)
        if (eventMap.containsKey(payment.customerEventNo)) {
          if (groupedPayments.containsKey(payment.customerEventNo)) {
            groupedPayments[payment.customerEventNo]!.add(payment);
          } else {
            groupedPayments[payment.customerEventNo] = [payment];
          }
        }
      }

      // Create payment summaries
      final summaries = <PaymentSummary>[];

      // Add summaries for events with payments
      for (var eventNo in groupedPayments.keys) {
        final event = eventMap[eventNo];
        if (event != null) {
          summaries.add(
            PaymentSummary(
              customerEventNo: eventNo,
              customerName: event.customerName,
              eventName: event.eventName,
              agreedAmount: event.agreedAmount,
              payments: groupedPayments[eventNo]!,
              customerEventStatus: event.status, // Add customer event status
            ),
          );
        }
      }

      // Add summaries for active events without payments (don't show cancelled events without payments)
      for (var event in activeEvents) {
        if (!groupedPayments.containsKey(event.eventNo) &&
            event.status == 'active') {
          summaries.add(
            PaymentSummary(
              customerEventNo: event.eventNo,
              customerName: event.customerName,
              eventName: event.eventName,
              agreedAmount: event.agreedAmount,
              payments: [],
              customerEventStatus: event.status, // Add customer event status
            ),
          );
        }
      }

      // Sort by last payment date (newest first) and then by event number
      summaries.sort((a, b) {
        if (a.lastPaymentDate == null && b.lastPaymentDate == null) {
          return a.customerEventNo.compareTo(b.customerEventNo);
        }
        if (a.lastPaymentDate == null) return 1;
        if (b.lastPaymentDate == null) return -1;
        return b.lastPaymentDate!.compareTo(a.lastPaymentDate!);
      });

      return summaries;
    } catch (e) {
      print('Error getting payment summaries: $e');
      return [];
    }
  }

  /// Gets summary for a specific customer event
  Future<PaymentSummary?> getPaymentSummaryForEvent(String eventNo) async {
    try {
      final summaries = await getPaymentSummaries();
      return summaries.where((s) => s.customerEventNo == eventNo).firstOrNull;
    } catch (e) {
      print('Error getting payment summary for event $eventNo: $e');
      return null;
    }
  }

  /// Gets statistics for all payment summaries
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      final summaries = await getPaymentSummaries();

      final totalEvents = summaries.length;
      final completedEvents = summaries
          .where((s) => s.status == 'completed')
          .length;
      final partialEvents = summaries
          .where((s) => s.status == 'partial')
          .length;
      final overpaidEvents = summaries
          .where((s) => s.status == 'overpaid')
          .length;
      final notStartedEvents = summaries
          .where((s) => s.status == 'not_started')
          .length;

      final totalAgreedAmount = summaries.fold(
        0.0,
        (sum, s) => sum + s.agreedAmount,
      );
      final totalPaidAmount = summaries.fold(
        0.0,
        (sum, s) => sum + s.totalPaid,
      );
      final totalRemainingAmount = summaries.fold(
        0.0,
        (sum, s) => sum + (s.remainingAmount > 0 ? s.remainingAmount : 0),
      );

      return {
        'totalEvents': totalEvents,
        'completedEvents': completedEvents,
        'partialEvents': partialEvents,
        'overpaidEvents': overpaidEvents,
        'notStartedEvents': notStartedEvents,
        'totalAgreedAmount': totalAgreedAmount,
        'totalPaidAmount': totalPaidAmount,
        'totalRemainingAmount': totalRemainingAmount,
        'completionPercentage': totalAgreedAmount > 0
            ? (totalPaidAmount / totalAgreedAmount * 100)
            : 0,
      };
    } catch (e) {
      print('Error getting payment statistics: $e');
      return {};
    }
  }
}
