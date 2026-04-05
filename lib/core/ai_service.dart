import 'api_client.dart';

class AiService {
  Future<String> enhancePrompt(String prompt) async {
    final response = await ApiClient.instance.post(
      '/ai/enhance-prompt',
      data: {'prompt': prompt},
    );
    return response.data['enhancedPrompt'] as String;
  }

  Future<String> inpaint(String imageBase64, String maskBase64, String prompt) async {
    final response = await ApiClient.instance.post(
      '/ai/inpaint',
      data: {'image': imageBase64, 'mask': maskBase64, 'prompt': prompt},
    );
    return response.data['resultImage'] as String;
  }

  Future<String> styleTransfer(String imageBase64, String stylePrompt) async {
    final response = await ApiClient.instance.post(
      '/ai/style-transfer',
      data: {'image': imageBase64, 'style': stylePrompt},
    );
    return response.data['resultImage'] as String;
  }
}
