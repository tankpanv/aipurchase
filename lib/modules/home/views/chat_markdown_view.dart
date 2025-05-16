import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/ai_chat_controller.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ChatMarkdownView extends GetView<AIChatController> {
  const ChatMarkdownView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Markdown对话',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => SingleChildScrollView(
              controller: controller.scrollController.value,
              padding: EdgeInsets.all(16.r),
              child: Markdown(
                data: _buildMarkdownContent(),
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    _launchUrl(href);
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  h2: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  h3: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  p: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
                  strong: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  em: TextStyle(fontStyle: FontStyle.italic),
                  blockquote: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('无法打开链接 $url');
    }
  }

  String _buildMarkdownContent() {
    if (controller.messages.isEmpty) {
      return "## 暂无对话记录";
    }

    StringBuffer markdownText = StringBuffer();
    
    // 标题
    markdownText.writeln("# 对话记录\n");
    
    // 当前选择的智能体
    if (controller.selectedAgent.value != null) {
      final agent = controller.selectedAgent.value!;
      markdownText.writeln("## 当前智能体: ${agent.name}\n");
      markdownText.writeln("*${agent.description}*\n");
    }
    
    // 对话内容
    markdownText.writeln("## 对话内容\n");
    
    for (int i = 0; i < controller.messages.length; i++) {
      final message = controller.messages[i];
      final isUser = message['isUser'] as bool;
      final content = message['content'] as String;
      final time = message['time'] as DateTime;
      final sender = message['sender'] as String;
      
      // 时间格式化
      final timeFormatted = "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
      
      if (isUser) {
        markdownText.writeln("### 🧑 用户 (${timeFormatted})\n");
      } else {
        markdownText.writeln("### 🤖 ${sender} (${timeFormatted})\n");
      }
      
      // 尝试解析AI返回的JSON内容
      if (!isUser && content != '正在思考中...') {
        try {
          final aiResponse = json.decode(content);
          if (aiResponse != null && aiResponse['content'] != null) {
            markdownText.writeln("${aiResponse['content']}\n");
          } else {
            markdownText.writeln("$content\n");
          }
          
          // 处理产品列表
          if (aiResponse['commands'] != null) {
            final commands = List<Map<String, dynamic>>.from(aiResponse['commands']);
            for (final command in commands) {
              // 商品列表
              if (command['found_products'] != null) {
                final products = List<Map<String, dynamic>>.from(command['found_products']);
                if (products.isNotEmpty) {
                  markdownText.writeln("#### 找到的商品\n");
                  
                  for (final product in products) {
                    markdownText.writeln("- **${product['name']}**");
                    markdownText.writeln("  - 价格: ¥${product['price']}");
                    markdownText.writeln("  - 描述: ${product['description']}");
                    if (product['image_url'] != null) {
                      markdownText.writeln("  - ![商品图片](${product['image_url']})");
                    }
                    markdownText.writeln("");
                  }
                }
              }
              
              // 地址列表
              if (command['address_list'] != null) {
                final addresses = List<Map<String, dynamic>>.from(command['address_list']);
                if (addresses.isNotEmpty) {
                  markdownText.writeln("#### 地址列表\n");
                  
                  for (final address in addresses) {
                    markdownText.writeln("- **${address['name']}** ${address['phone']}");
                    markdownText.writeln("  - 地址: ${address['province']} ${address['city']} ${address['district']} ${address['detail']}");
                    if (address['is_default'] == true) {
                      markdownText.writeln("  - *默认地址*");
                    }
                    markdownText.writeln("");
                  }
                }
              }
              
              // 订单列表
              if (command['order_list'] != null) {
                final orders = List<Map<String, dynamic>>.from(command['order_list']);
                if (orders.isNotEmpty) {
                  markdownText.writeln("#### 订单列表\n");
                  
                  for (final order in orders) {
                    final status = _getOrderStatusText(order['status'] as String);
                    markdownText.writeln("- **订单号**: ${order['order_no']}");
                    markdownText.writeln("  - 状态: $status");
                    markdownText.writeln("  - 总金额: ¥${order['total_amount']}");
                    
                    if (order['items'] != null) {
                      final items = List<Map<String, dynamic>>.from(order['items']);
                      markdownText.writeln("  - 商品清单:");
                      for (final item in items) {
                        markdownText.writeln("    - ${item['product_name']} × ${item['quantity']} = ¥${item['price'] * (item['quantity'] as num)}");
                      }
                    }
                    markdownText.writeln("");
                  }
                }
              }
            }
          }
        } catch (e) {
          // 解析失败，作为普通文本处理
          markdownText.writeln("$content\n");
        }
      } else {
        markdownText.writeln("$content\n");
      }
      
      markdownText.writeln("---\n");
    }

    return markdownText.toString();
  }

  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return '待付款';
      case 'pending_delivery':
        return '待发货';
      case 'pending_receipt':
        return '待收货';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '未知状态';
    }
  }
} 