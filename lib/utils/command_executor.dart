import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';

class Command {
  final String id;
  final String name;
  final String description;
  final String route;
  final List<String> keywords;
  final List<Map<String, dynamic>> params;
  final List<String> dependencies;
  final String action;

  Command({
    required this.id,
    required this.name,
    required this.description,
    this.route = '',
    this.keywords = const [],
    this.params = const [],
    this.dependencies = const [],
    this.action = '',
  });
}

class CommandExecutor {
  static final CommandExecutor _instance = CommandExecutor._();
  factory CommandExecutor() {
    if (!Get.isRegistered<CommandExecutor>()) {
      Get.put(_instance, permanent: true);
    }
    return _instance;
  }

  CommandExecutor._();

  static final List<Command> _commands = [
    Command(
      id: 'search_products',
      name: '搜索商品',
      description: '通过关键词搜索商品',
      route: '/search',
      keywords: ['搜索', '查找', '查询', '找商品', '搜商品'],
      params: [
        {
          'name': 'keyword',
          'type': 'string',
          'required': true,
          'description': '搜索关键词'
        }
      ],
    ),
    Command(
      id: 'view_product_detail',
      name: '查看商品详情',
      description: '查看商品的详细信息',
      route: '/product/detail',
      keywords: ['商品详情', '产品详情', '查看详情', '详细信息'],
      params: [
        {
          'name': 'productId',
          'type': 'integer',
          'required': true,
          'description': '商品ID'
        }
      ],
      dependencies: ['search_products'],
    ),
    Command(
      id: 'add_to_cart',
      name: '加入购物车',
      description: '将商品添加到购物车',
      keywords: ['加购', '加入购物车', '添加购物车', '放入购物车'],
      params: [
        {
          'name': 'productId',
          'type': 'integer',
          'required': true,
          'description': '商品ID'
        },
        {
          'name': 'quantity',
          'type': 'integer',
          'required': true,
          'description': '购买数量'
        }
      ],
      dependencies: ['view_product_detail'],
    ),
    Command(
      id: 'view_cart',
      name: '查看购物车',
      description: '查看购物车中的商品',
      route: '/cart',
      keywords: ['购物车', '查看购物车', '我的购物车'],
    ),
    Command(
      id: 'create_order',
      name: '创建订单',
      description: '从购物车中选择商品创建订单',
      keywords: ['下单', '创建订单', '提交订单', '生成订单'],
      params: [
        {
          'name': 'addressId',
          'type': 'integer',
          'required': true,
          'description': '收货地址ID'
        },
        {
          'name': 'items',
          'type': 'array',
          'required': true,
          'description': '订单商品列表'
        }
      ],
      dependencies: ['add_to_cart', 'select_address'],
    ),
    Command(
      id: 'view_orders',
      name: '查看订单列表',
      description: '查看所有订单或特定状态的订单',
      route: '/orders',
      keywords: ['订单列表', '我的订单', '查看订单', '订单记录'],
      params: [
        {
          'name': 'status',
          'type': 'string',
          'required': false,
          'description': '订单状态'
        }
      ],
    ),
    Command(
      id: 'view_order_detail',
      name: '查看订单详情',
      description: '查看特定订单的详细信息',
      route: '/order/detail',
      keywords: ['订单详情', '订单信息', '查看订单详情'],
      params: [
        {
          'name': 'orderNo',
          'type': 'string',
          'required': true,
          'description': '订单号'
        }
      ],
      dependencies: ['view_orders'],
    ),
    Command(
      id: 'view_address_list',
      name: '查看地址列表',
      description: '查看所有收货地址',
      route: '/address/list',
      keywords: ['地址列表', '收货地址', '我的地址'],
    ),
    Command(
      id: 'add_address',
      name: '添加地址',
      description: '添加新的收货地址',
      route: '/address/edit',
      keywords: ['新增地址', '添加地址', '新建地址'],
    ),
    Command(
      id: 'edit_address',
      name: '编辑地址',
      description: '编辑已有的收货地址',
      route: '/address/edit',
      keywords: ['修改地址', '编辑地址', '更新地址'],
      params: [
        {
          'name': 'addressId',
          'type': 'integer',
          'required': true,
          'description': '地址ID'
        }
      ],
      dependencies: ['view_address_list'],
    ),
    Command(
      id: 'select_address',
      name: '选择收货地址',
      description: '选择收货地址用于下单',
      route: '/address/list',
      keywords: ['选择地址', '选地址', '设置收货地址'],
      params: [
        {
          'name': 'selectMode',
          'type': 'boolean',
          'required': true,
          'description': '是否为选择模式'
        }
      ],
      dependencies: ['view_address_list'],
    ),
    Command(
      id: 'login',
      name: '用户登录',
      description: '用户登录账号',
      route: '/login',
      keywords: ['登录', '登陆', '用户登录', '账号登录'],
    ),
    Command(
      id: 'register',
      name: '用户注册',
      description: '注册新用户账号',
      route: '/register',
      keywords: ['注册', '注册账号', '新用户注册'],
    ),
    Command(
      id: 'logout',
      name: '退出登录',
      description: '退出当前登录账号',
      keywords: ['退出', '登出', '退出登录', '注销'],
      dependencies: ['login'],
    ),
    Command(
      id: 'view_profile',
      name: '查看个人信息',
      description: '查看个人资料信息',
      route: '/profile',
      keywords: ['个人信息', '我的信息', '个人资料'],
      dependencies: ['login'],
    ),
  ];

  static List<String> getCommandNames() {
    return _commands.map((command) => command.name).toList();
  }

  static List<Command> getMatchingCommands(String input) {
    if (input.isEmpty) {
      return _commands;
    }
    
    final lowercaseInput = input.toLowerCase();
    return _commands.where((command) {
      // 检查命令名称和描述
      if (command.name.toLowerCase().contains(lowercaseInput) ||
          command.description.toLowerCase().contains(lowercaseInput)) {
        return true;
      }
      
      // 检查关键词
      return command.keywords.any((keyword) => 
        keyword.toLowerCase().contains(lowercaseInput));
    }).toList();
  }

  static Command? findCommandById(String id) {
    try {
      return _commands.firstWhere((command) => command.id == id);
    } catch (e) {
      return null;
    }
  }

  void executeCommand(String commandId, [Map<String, dynamic>? params]) {
    final command = findCommandById(commandId);
    if (command == null) return;

    // 检查依赖
    if (command.dependencies.isNotEmpty) {
      final authController = Get.find<AuthController>();
      if (command.dependencies.contains('login') && !(authController.isLoggedIn as bool)) {
        Get.toNamed('/login');
        return;
      }
    }

    // 执行命令
    switch (commandId) {
      case 'add_to_cart':
        if (params != null) {
          final cartController = Get.find<CartController>();
          cartController.addToCart(
            params['productId'] as int,
            params['quantity'] as int? ?? 1,
          );
        }
        break;
      
      case 'create_order':
        if (params != null) {
          final orderController = Get.find<OrderController>();
          orderController.createOrder(
            params['addressId'] as int,
            params['items'] as List<Map<String, dynamic>>,
          );
        }
        break;
      
      case 'logout':
        final authController = Get.find<AuthController>();
        authController.logout();
        break;
      
      default:
        // 处理路由导航
        if (command.route.isNotEmpty) {
          if (params != null && params.isNotEmpty) {
            Get.toNamed(command.route, arguments: params);
          } else {
            Get.toNamed(command.route);
          }
        }
    }
  }
}