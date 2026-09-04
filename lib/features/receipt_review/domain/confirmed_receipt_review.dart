import 'package:splitlens/core/money/money.dart';

final class ConfirmedReceiptReview {
  const ConfirmedReceiptReview({
    required this.merchant,
    required this.date,
    required this.currencyCode,
    required this.total,
    required this.receiptImagePath,
    required this.rawOcrText,
  });

  final String merchant;
  final DateTime date;
  final String currencyCode;
  final Money total;
  final String receiptImagePath;
  final String rawOcrText;
}
