import 'package:flutter/material.dart';

// Импортируйте страницу заказов мастера
import 'orders_master_page.dart'; // Убедитесь, что путь правильный

class EditPortfolioMasterPage extends StatefulWidget {
  const EditPortfolioMasterPage({super.key});

  @override
  State<EditPortfolioMasterPage> createState() => _EditPortfolioMasterPageState();
}

class _EditPortfolioMasterPageState extends State<EditPortfolioMasterPage> {
  final List<String> _portfolioImages = List.generate(14, (index) => 'assets/work_sample.png');
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF41454A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Мои работы',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF41454A),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Image.asset('assets/logout.png', width: 22, height: 22),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 4,
                  right: 4,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _portfolioImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _portfolioImages.length) {
                      return GestureDetector(
                        onTap: () {
                          _addNewWork();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 32,
                                  color: Color(0xFF0F7EDE),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    final row = (index / 3).floor();
                    final column = index % 3;
                    
                    return Container(
                      margin: EdgeInsets.only(
                        right: column == 2 ? 4 : 0,
                        left: column == 0 ? 4 : 0,
                        top: row == 0 ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(_portfolioImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () {
                                _deleteWork(index);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F7EDE),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/close.png',
                                    width: 14,
                                    height: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: ClipRRect(
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
            children: [
              // Работа
              GestureDetector(
                onTap: () {
                  // Навигация на страницу заказов мастера
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrdersMasterPage(),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/work.png',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF5F6368),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Работа',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              // Прайс
              GestureDetector(
                onTap: () {
                  // Можно добавить навигацию на страницу прайса
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => PricePage()));
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/price.png',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF5F6368),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Прайс',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              // Аккаунт (активная)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/account.png',
                    width: 24,
                    height: 24,
                    color: const Color(0xFF0F7EDE),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Аккаунт',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F7EDE),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _addNewWork() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Добавить работу',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0F7EDE)),
                title: const Text(
                  'Выбрать из галереи',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _simulateImageAdd();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0F7EDE)),
                title: const Text(
                  'Сделать фото',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _simulateImageAdd();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Color(0xFF5F6368),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _simulateImageAdd() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Изображение добавлено (симуляция)'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _deleteWork(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Удалить работу?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF41454A),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          content: const Text(
            'Вы уверены, что хотите удалить эту работу из портфолио?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF5F6368),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Color(0xFF5F6368),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _portfolioImages.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Работа удалена'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Удалить',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}