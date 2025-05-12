import 'package:get/get.dart';
import '../modules/home/home_page.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/views/product_detail_view.dart';
import '../modules/home/views/cart_view.dart';
import '../modules/home/views/orders_view.dart';
import '../modules/home/views/order_detail_view.dart';
import '../modules/auth/login_page.dart';
import '../modules/auth/register_page.dart';
import '../modules/auth/user_info_page.dart';
import '../modules/auth/change_password_page.dart';
import '../modules/home/views/address_list_view.dart';
import '../modules/home/views/address_edit_view.dart';
import '../modules/home/views/command_input_view.dart';
import '../controllers/address_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/main_controller.dart';
import '../modules/home/views/product_list_view.dart';
import '../controllers/product_list_controller.dart';
import '../modules/home/views/search_result_view.dart';
import '../controllers/search_result_controller.dart';
import '../modules/home/views/settings_view.dart';
import '../modules/home/views/about_view.dart';
import '../controllers/ai_chat_controller.dart';
import '../modules/home/bindings/ai_chat_binding.dart';
import '../modules/home/views/ai_assistant_view_travel.dart';
import '../modules/home/bindings/ai_travel_binding.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => HomePage(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
        Get.put(MainController());
        Get.put(CartController());
        Get.put(AIChatController());
      }),
      bindings: [
        AIChatBinding(),
      ],
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginPage(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterPage(),
    ),
    GetPage(
      name: Routes.USER_INFO,
      page: () => UserInfoPage(),
    ),
    GetPage(
      name: Routes.CHANGE_PASSWORD,
      page: () => ChangePasswordPage(),
    ),
    GetPage(
      name: Routes.ADDRESS_LIST,
      page: () => const AddressListView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AddressController());
      }),
    ),
    GetPage(
      name: Routes.ADDRESS_EDIT,
      page: () => AddressEditView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AddressController());
      }),
    ),
    GetPage(
      name: Routes.PRODUCT_DETAIL,
      page: () => const ProductDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProductDetailController());
      }),
    ),
    GetPage(
      name: Routes.CART,
      page: () => const CartView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CartController());
        Get.lazyPut(() => OrderController());
      }),
    ),
    GetPage(
      name: Routes.ORDERS,
      page: () => OrdersView(
        initialStatus: Get.arguments?['status'],
      ),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController());
      }),
    ),
    GetPage(
      name: Routes.ORDER_DETAIL,
      page: () {
        final orderNo = Get.parameters['orderNo'] ?? Get.arguments['orderNo'];
        return OrderDetailView(orderNo: orderNo);
      },
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController());
      }),
    ),
    GetPage(
      name: Routes.PRODUCTS,
      page: () => const ProductListView(),
      binding: BindingsBuilder(() {
        Get.put(ProductListController());
      }),
    ),
    GetPage(
      name: Routes.SEARCH,
      page: () => const SearchResultView(),
      binding: BindingsBuilder(() {
        Get.put(SearchResultController());
      }),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => const SettingsView(),
    ),
    GetPage(
      name: Routes.ABOUT,
      page: () => const AboutView(),
    ),
    GetPage(
      name: Routes.COMMANDS,
      page: () => const CommandInputView(),
    ),
    GetPage(
      name: Routes.AI_TRAVEL,
      page: () => const AiAssistantTravelView(),
      binding: AiTravelBinding(),
    ),
  ];
} 