import 'package:flutter/material.dart';

class MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onClose;

  const MessageBanner({
    super.key,
    required this.message,
    this.isError = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final bgColor = isError ? Colors.red.shade50 : Colors.green.shade50;
    final borderColor = isError ? Colors.red.shade200 : Colors.green.shade200;
    final iconColor = isError ? Colors.red.shade700 : Colors.green.shade700;
    final textColor = isError ? Colors.red.shade900 : Colors.green.shade900;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  Icons.close,
                  color: iconColor,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
