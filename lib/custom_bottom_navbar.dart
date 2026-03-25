import 'package:flutter/material.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/screens/add_order_client_page.dart';
import 'package:goodjob/screens/edit_portfolio_master_page.dart';
import 'package:goodjob/screens/my_orders_client_page.dart';
import 'package:goodjob/screens/orders_master_page.dart';
import 'package:goodjob/screens/price_page.dart';

class CustomBottomNavBar extends StatelessWidget {
  final NavItem activeItem;
  final AccountType accountType;

  const CustomBottomNavBar({
    Key? key,
    required this.activeItem,
    required this.accountType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(54),
        topRight: Radius.circular(54),
      ),
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: accountType == AccountType.master
              ? _buildMasterNavItems(context)
              : _buildClientNavItems(context),
        ),
      ),
    );
  }

  List<Widget> _buildMasterNavItems(BuildContext context) {
    return [
      _buildNavItem(
        context,
        iconAsset: 'assets/work.png',
        label: 'Работа',
        navItem: NavItem.work,
        destination: const OrdersMasterPage(),
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/price.png',
        label: 'Прайс',
        navItem: NavItem.price,
        destination: PricePage(),
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/account.png',
        label: 'Аккаунт',
        navItem: NavItem.account,
        destination: const AccountPage(accountType: AccountType.master),
      ),
    ];
  }

  List<Widget> _buildClientNavItems(BuildContext context) {
    return [
      _buildNavItem(
        context,
        iconAsset: 'assets/work.png',
        label: 'Мои заказы',
        navItem: NavItem.orders,
        destination:
            const MyOrdersClientPage(), // Или отдельная страница "Мои заказы"
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/price.png', // Нужно добавить иконку
        label: 'Прайс',
        navItem: NavItem.price,
        destination: PricePage(),
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/account.png',
        label: 'Аккаунт',
        navItem: NavItem.account,
        destination: const AccountPage(
          accountType: AccountType.client,
        ), // Замените на вашу страницу заказов клиента
      ),
    ];
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String iconAsset,
    required String label,
    required NavItem navItem,
    required Widget destination,
  }) {
    final bool isActive = activeItem == navItem;
    final Color activeColor = const Color(0xFF0F7EDE);
    final Color inactiveColor = const Color(0xFF5F6368);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            width: 24,
            height: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? activeColor : inactiveColor,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}

// Обновленное перечисление для активного элемента навигации
enum NavItem { work, portfolio, account, orders, addOrder, price }

// Динамическая версия для управления навигацией через состояние
class CustomBottomNavBarDynamic extends StatelessWidget {
  final NavItem activeItem;
  final AccountType accountType;
  final void Function(NavItem) onItemSelected;

  const CustomBottomNavBarDynamic({
    Key? key,
    required this.activeItem,
    required this.accountType,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(54),
        topRight: Radius.circular(54),
      ),
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: accountType == AccountType.master
              ? _buildMasterNavItems()
              : _buildClientNavItems(),
        ),
      ),
    );
  }

  List<Widget> _buildMasterNavItems() {
    return [
      _buildNavItem(
        iconAsset: 'assets/work.png',
        label: 'Работа',
        navItem: NavItem.work,
      ),
      _buildNavItem(
        iconAsset: 'assets/price.png',
        label: 'Прайс',
        navItem: NavItem.price,
      ),
      _buildNavItem(
        iconAsset: 'assets/account.png',
        label: 'Аккаунт',
        navItem: NavItem.account,
      ),
    ];
  }

  List<Widget> _buildClientNavItems() {
    return [
      _buildNavItem(
        iconAsset: 'assets/work.png',
        label: 'Мои заказы',
        navItem: NavItem.work,
      ),
      _buildNavItem(
        iconAsset: 'assets/price.png',
        label: 'Прайс',
        navItem: NavItem.price,
      ),
      _buildNavItem(
        iconAsset: 'assets/add_order.png', // Добавьте эту иконку в assets
        label: 'Добавить заказ',
        navItem: NavItem.addOrder,
      ),
    ];
  }

  Widget _buildNavItem({
    required String iconAsset,
    required String label,
    required NavItem navItem,
  }) {
    final bool isActive = activeItem == navItem;
    final Color activeColor = const Color(0xFF0F7EDE);
    final Color inactiveColor = const Color(0xFF5F6368);

    return GestureDetector(
      onTap: () => onItemSelected(navItem),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconAsset,
            width: 24,
            height: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? activeColor : inactiveColor,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}

// Пример использования в StatefulWidget
class NavigationWrapper extends StatefulWidget {
  final AccountType accountType;

  const NavigationWrapper({Key? key, required this.accountType})
    : super(key: key);

  @override
  _NavigationWrapperState createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  NavItem _activeItem = NavItem.work;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: CustomBottomNavBarDynamic(
        activeItem: _activeItem,
        accountType: widget.accountType,
        onItemSelected: (item) {
          setState(() {
            _activeItem = item;
          });
        },
      ),
    );
  }

  Widget _getCurrentPage() {
    if (widget.accountType == AccountType.master) {
      switch (_activeItem) {
        case NavItem.work:
          return const OrdersMasterPage();
        case NavItem.portfolio:
          return const EditPortfolioMasterPage();
        case NavItem.price:
          return PricePage(); 
        case NavItem.account:
          return AccountPage(accountType: AccountType.master);
        default:
          return const OrdersMasterPage();
      }
    } else {
      // Клиент
      switch (_activeItem) {
        case NavItem.work:
          return const AddOrderClientPage();
        case NavItem.orders:
          return const MyOrdersClientPage(); // или ClientMyOrdersPage()
        case NavItem.price:
          return PricePage();
        case NavItem.account:
          return const AccountPage(accountType: AccountType.client);
        default:
          return const MyOrdersClientPage();
      }
    }
  }
}

// Пример использования в разных страницах:
class MasterPageExample extends StatelessWidget {
  const MasterPageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Мастер')),
      body: Container(),
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.work,
        accountType: AccountType.master,
      ),
    );
  }
}

class ClientPageExample extends StatelessWidget {
  const ClientPageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Клиент')),
      body: Container(),
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.work,
        accountType: AccountType.client,
      ),
    );
  }
}
