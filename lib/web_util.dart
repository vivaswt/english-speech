import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

Future<String?> getTitleOfWebPage(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final document = parse(response.body);
    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.isNotEmpty) {
      return titleElement.text.trim();
    }
  }

  return null;
}
