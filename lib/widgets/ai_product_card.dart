import 'package:flutter/material.dart';
import './product_action_buttons.dart';

class AIProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const AIProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name'] ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (product['特色描述'] != null)
              ...List<String>.from(product['特色描述']).map(
                (desc) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(desc),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '现价：${product['现价'] ?? ''}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                if (product['原价'] != null)
                  Text(
                    '原价：${product['原价']}',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ProductActionButtons(productId: product['id']),
          ],
        ),
      ),
    );
  }
} 