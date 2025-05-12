import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRefresh;

  const EmptyPlaceholder({
    super.key,
    required this.icon,
    required this.message,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.w),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          if (onRefresh != null) ...[
            SizedBox(height: 24.w),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ],
      ),
    );
  }
} 