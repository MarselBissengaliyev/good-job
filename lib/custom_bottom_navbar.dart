import 'package:flutter/material.dart';
import 'package:goodjob/screens/account_page.dart';
import 'package:goodjob/screens/add_order_client_page.dart';
import 'package:goodjob/screens/edit_portfolio_master_page.dart';
import 'package:goodjob/screens/my_orders_client_page.dart';
import 'package:goodjob/screens/orders_master_page.dart';
import 'package:goodjob/screens/price_page.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

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
    final appLocalizations = AppLocalizations.of(context);
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: accountType == AccountType.master
              ? _buildMasterNavItems(context, appLocalizations)
              : _buildClientNavItems(context, appLocalizations),
        ),
      ),
    );
  }

  List<Widget> _buildMasterNavItems(BuildContext context, AppLocalizations? appLocalizations) {
    return [
      _buildNavItem(
        context,
        iconAsset: 'assets/work.png',
        label: appLocalizations?.translate('work') ?? 'Работа',
        navItem: NavItem.work,
        destination: const OrdersMasterPage(),
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/price.png',
        label: appLocalizations?.translate('price') ?? 'Прайс',
        navItem: NavItem.price,
        destination: PricePage(),
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/account.png',
        label: appLocalizations?.translate('account') ?? 'Аккаунт',
        navItem: NavItem.account,
        destination: const AccountPage(accountType: AccountType.master),
      ),
    ];
  }

  List<Widget> _buildClientNavItems(BuildContext context, AppLocalizations? appLocalizations) {
    return [
      _buildNavItem(
        context,
        iconAsset: 'assets/work.png',
        label: appLocalizations?.translate('my_orders') ?? 'Мои заказы',
        navItem: NavItem.orders,
        destination: const MyOrdersClientPage(),
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/price.png',
        label: appLocalizations?.translate('price') ?? 'Прайс',
        navItem: NavItem.price,
        destination: PricePage(),
      ),
      _buildNavItem(
        context,
        iconAsset: 'assets/account.png',
        label: appLocalizations?.translate('account') ?? 'Аккаунт',
        navItem: NavItem.account,
        destination: const AccountPage(accountType: AccountType.client),
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
      onTap: isActive
          ? null // Если активна - отключаем нажатие
          : () {
              Navigator.push(
                context,
                _createPageRoute(destination),
              );
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
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
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageRouteBuilder _createPageRoute(Widget destination) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

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
    final appLocalizations = AppLocalizations.of(context);
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: accountType == AccountType.master
              ? _buildMasterNavItems(appLocalizations)
              : _buildClientNavItems(appLocalizations),
        ),
      ),
    );
  }

  List<Widget> _buildMasterNavItems(AppLocalizations? appLocalizations) {
    return [
      _buildNavItem(
        iconAsset: 'assets/work.png',
        label: appLocalizations?.translate('work') ?? 'Работа',
        navItem: NavItem.work,
      ),
      _buildNavItem(
        iconAsset: 'assets/price.png',
        label: appLocalizations?.translate('price') ?? 'Прайс',
        navItem: NavItem.price,
      ),
      _buildNavItem(
        iconAsset: 'assets/account.png',
        label: appLocalizations?.translate('account') ?? 'Аккаунт',
        navItem: NavItem.account,
      ),
    ];
  }

  List<Widget> _buildClientNavItems(AppLocalizations? appLocalizations) {
    return [
      _buildNavItem(
        iconAsset: 'assets/work.png',
        label: appLocalizations?.translate('my_orders') ?? 'Мои заказы',
        navItem: NavItem.orders,
      ),
      _buildNavItem(
        iconAsset: 'assets/price.png',
        label: appLocalizations?.translate('price') ?? 'Прайс',
        navItem: NavItem.price,
      ),
      _buildNavItem(
        iconAsset: 'assets/add_order.png',
        label: appLocalizations?.translate('add_order') ?? 'Добавить заказ',
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
      onTap: isActive
          ? null // Если активна - отключаем нажатие
          : () => onItemSelected(navItem),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
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
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NavigationWrapper с поддержкой локализации
class NavigationWrapper extends StatefulWidget {
  final AccountType accountType;

  const NavigationWrapper({Key? key, required this.accountType}) : super(key: key);

  @override
  _NavigationWrapperState createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  NavItem _activeItem = NavItem.work;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _getInitialPageIndex());
  }

  int _getInitialPageIndex() {
    if (widget.accountType == AccountType.master) {
      switch (_activeItem) {
        case NavItem.work: return 0;
        case NavItem.price: return 1;
        case NavItem.account: return 2;
        default: return 0;
      }
    } else {
      switch (_activeItem) {
        case NavItem.orders: return 0;
        case NavItem.price: return 1;
        case NavItem.addOrder: return 2;
        default: return 0;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _activeItem = _getNavItemFromIndex(index);
          });
        },
        children: _getPages(),
      ),
      bottomNavigationBar: CustomBottomNavBarDynamic(
        activeItem: _activeItem,
        accountType: widget.accountType,
        onItemSelected: (item) {
          // Проверяем, не активен ли уже этот пункт
          if (_activeItem == item) return;
          
          setState(() {
            _activeItem = item;
            _pageController.animateToPage(
              _getIndexFromNavItem(item),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          });
        },
      ),
    );
  }

  int _getIndexFromNavItem(NavItem item) {
    if (widget.accountType == AccountType.master) {
      switch (item) {
        case NavItem.work: return 0;
        case NavItem.price: return 1;
        case NavItem.account: return 2;
        default: return 0;
      }
    } else {
      switch (item) {
        case NavItem.orders: return 0;
        case NavItem.price: return 1;
        case NavItem.addOrder: return 2;
        default: return 0;
      }
    }
  }

  NavItem _getNavItemFromIndex(int index) {
    if (widget.accountType == AccountType.master) {
      switch (index) {
        case 0: return NavItem.work;
        case 1: return NavItem.price;
        case 2: return NavItem.account;
        default: return NavItem.work;
      }
    } else {
      switch (index) {
        case 0: return NavItem.orders;
        case 1: return NavItem.price;
        case 2: return NavItem.addOrder;
        default: return NavItem.orders;
      }
    }
  }

  List<Widget> _getPages() {
    if (widget.accountType == AccountType.master) {
      return [
        const OrdersMasterPage(),
        PricePage(),
        const AccountPage(accountType: AccountType.master),
      ];
    } else {
      return [
        const MyOrdersClientPage(),
        PricePage(),
        const AddOrderClientPage(),
      ];
    }
  }
}

// Обновленное перечисление для активного элемента навигации
enum NavItem { work, portfolio, account, orders, addOrder, price }

// Пример использования в разных страницах:
class MasterPageExample extends StatelessWidget {
  const MasterPageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations?.translate('master') ?? 'Мастер'),
      ),
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
    final appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations?.translate('client') ?? 'Клиент'),
      ),
      body: Container(),
      bottomNavigationBar: CustomBottomNavBar(
        activeItem: NavItem.orders,
        accountType: AccountType.client,
      ),
    );
  }
}

// Language selector для навигации (если нужно добавить в AppBar)
class LanguageSelectorForNavBar extends StatelessWidget {
  const LanguageSelectorForNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(
            context: context,
            code: 'RU',
            locale: const Locale('ru'),
            isActive: languageProvider.locale.languageCode == 'ru',
            languageProvider: languageProvider,
          ),
          _buildLanguageOption(
            context: context,
            code: 'KZ',
            locale: const Locale('kk'),
            isActive: languageProvider.locale.languageCode == 'kk',
            languageProvider: languageProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String code,
    required Locale locale,
    required bool isActive,
    required LanguageProvider languageProvider,
  }) {
    return GestureDetector(
      onTap: () {
        languageProvider.setLanguage(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale.languageCode == 'ru' 
                  ? 'Язык изменен на русский' 
                  : 'Тіл қазақшаға өзгертілді',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          code,
          style: TextStyle(
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}