import 'package:english_speech/google/gemini.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fetchSummurizedContent', () {
    test('should return a non-empty summary for valid content', () async {
      final result = await fetchSummurizedContent(sampleArticle1);
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });
  });
}

final List<String> sampleArticle1 =
    '''
## What exactly is a native desktop app?
What are we calling a “native” desktop application, anyway?
Mostly, this comes down to the difference between a program that uses web technology—a web UI, packaged in an instance of a web browser—versus a program that uses the platform’s own GUI system, or a third-party, cross-platform GUI that isn’t primarily web-based.
Desktop applications like [Visual Studio Code](https://www.infoworld.com/article/2254808/get-started-with-visual-studio-code.html) or the Slack client are web-based. They build atop technologies like [Electron or Tauri](https://www.infoworld.com/article/3547072/electron-vs-tauri-which-cross-platform-framework-is-for-you.html), where your app’s front end is built with HTML, CSS, and [JavaScript](https://www.infoworld.com/article/2263137/what-is-javascript-the-full-stack-programming-language.html). (The back end can also be JavaScript but it’s not required.)
True desktop applications like the full-blown Visual Studio product, Microsoft Word, or the Adobe Creative Suite don’t use a web-based front end or packaging. Some of that is the weight of a legacy codebase, created before web UI apps and Electron: if it isn’t broken, don’t change it. But native apps also provide much finer control over the user experience, at the cost of requiring more development.
The biggest advantage of a web UI app over a native desktop app is its ability to leverage the massive ecosystem of web-based UI components. If there’s some UI element you want to present to the user, odds are a web version of it exists. Not only that, but it will often be far easier to implement than a platform-native version would be.
'''
        .split('\n');
