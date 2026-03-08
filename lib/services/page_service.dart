import '../models/page_model.dart';
import './api/api_client.dart';

class PageService {
  final ApiClient _apiClient = ApiClient();

  Future<PageModel> getPageBySlug(String slug) async {
    try {
      final response = await _apiClient.get('/pages/$slug');
      
      if (response != null && response['data'] != null) {
        return PageModel.fromJson(response['data']);
      }
      
      throw Exception('Не удалось загрузить страницу');
    } catch (e) {
      throw Exception('Ошибка загрузки страницы: $e');
    }
  }
}