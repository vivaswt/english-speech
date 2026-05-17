import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:http/http.dart' show Client;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:path/path.dart' as p;

import 'package:english_speech/fp/either.dart';
import 'package:english_speech/service/log.dart';
import 'package:english_speech/parser/srt.dart';

class GoogleAuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: const GoogleSignInParams(
      clientId:
          '1069551861301-96r18euhpajbtqrk75fdek7t2v0s7dhf.apps.googleusercontent.com',
      clientSecret: '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',
      scopes: [
        'openid',
        'email',
        'profile',
        'https://www.googleapis.com/auth/youtube',
        'https://www.googleapis.com/auth/youtubepartner',
        'https://www.googleapis.com/auth/youtube.force-ssl',
      ],
    ),
  );

  static final instance = GoogleAuthService._internal();
  GoogleSignInCredentials? credentials;
  UserInfo? userInfo;

  GoogleAuthService._internal() {
    _googleSignIn.authenticationState.listen((state) {
      credentials = state;
      if (state != null) {
        final idToken = state.idToken;
        if (idToken == null) {
          throw Exception('idToken is null');
        }

        Map<String, dynamic> payload = Jwt.parseJwt(idToken);
        userInfo = UserInfo(
          userId: payload['sub'],
          name: payload['name'],
          email: payload['email'],
          pictureUrl: payload['picture'],
        );
      } else {
        userInfo = null;
      }

      notifyListeners();
    });

    _googleSignIn.silentSignIn();
  }

  factory GoogleAuthService() => instance;

  get isSignedIn => credentials != null;

  Future<void> signIn() async {
    // 1. Try silent first (no user interaction)
    final silentCreds = await _googleSignIn.silentSignIn();
    if (silentCreds != null) return;

    // 2. Try lightweight (minimal interaction)
    final lightCreds = await _googleSignIn.lightweightSignIn();
    if (lightCreds != null) return;

    // 3. Fallback to full flow (complete OAuth)
    await _googleSignIn.signInOnline();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<Client?> authenticatedClient() => _googleSignIn.authenticatedClient;
}

class UserInfo {
  final String name;
  final String email;
  final String pictureUrl;
  final String userId;

  UserInfo({
    required this.userId,
    required this.name,
    required this.email,
    required this.pictureUrl,
  });
}

class PlayList {
  final String id;
  final String title;

  PlayList({required this.id, required this.title});
}

class PlayListItem {
  final String id;
  final String title;
  final String videoId;
  final String? thumbnailUrl;

  String get url => 'https://www.youtube.com/watch?v=$videoId';

  PlayListItem({
    required this.id,
    required this.title,
    required this.videoId,
    this.thumbnailUrl,
  });
}

Future<List<PlayList>> getPlaylists(Client client) async {
  final api = YouTubeApi(client);
  final playlistsResponse = await api.playlists.list(
    ['snippet'],
    mine: true,
    maxResults: 30,
  );
  return playlistsResponse.items!
      .map(
        (playlist) =>
            PlayList(id: playlist.id!, title: playlist.snippet!.title!),
      )
      .toList();
}

Future<List<PlayListItem>> getPlaylistItems({
  required Client client,
  required String title,
}) async {
  final api = YouTubeApi(client);

  final playlistsResponse = await api.playlists.list(
    ['snippet'],
    mine: true,
    maxResults: 50,
  );
  final playlist = playlistsResponse.items
      ?.where((i) => i.snippet?.title == title)
      .singleOrNull;
  if (playlist == null) {
    throw Exception('Playlist "$title" not found');
  }

  final playListItemsReponse = await api.playlistItems.list(
    ['snippet'],
    playlistId: playlist.id,
    maxResults: 50,
  );

  if (playListItemsReponse.items == null) {
    throw Exception('PlayListItem is null');
  }

  final result = playListItemsReponse.items!.map((item) {
    final snippet = item.snippet;
    if (item.id == null) throw Exception('PlayListItem id is null');
    if (snippet == null) throw Exception('PlayListItem snippet is null');
    if (snippet.title == null) throw Exception('PlayListItem title is null');
    if (snippet.resourceId == null) {
      throw Exception('PlayListItem resourceId is null');
    }
    return PlayListItem(
      id: item.id!,
      title: snippet.title!,
      videoId: snippet.resourceId!.videoId!,
      thumbnailUrl: snippet.thumbnails?.default_?.url,
    );
  }).toList();
  return result;
}

Future<void> deletePlayListItem({
  required Client client,
  required String id,
}) async {
  final api = YouTubeApi(client);
  await api.playlistItems.delete(id);
}

Future<List<String>> downloadSubtitle(
  String videoUrl, {
  required String folder,
}) async {
  final result = await Process.run('yt-dlp', [
    '--force-overwrites',
    '--write-subs',
    '--write-auto-subs',
    '--sub-format',
    'srt/ttml/srv3/srv2/vtt',
    '--skip-download',
    '-P',
    folder,
    videoUrl,
  ]);

  if (result.exitCode != 0) {
    throw Exception('Error downloading subtitle: ${result.stderr}');
  }

  final fileName = _getFileNameFromLog(result.stdout);
  if (fileName == null) {
    throw Exception('Error downloading subtitle: cannot find file name');
  }

  final file = File(fileName);
  final fileContents = await file.readAsLines();

  try {
    final texts = _extractTexts(fileName, fileContents);
    return texts;
  } catch (e) {
    rethrow;
  } finally {
    await file.delete();
  }
}

String? _getFileNameFromLog(String logText) {
  final result = RegExp(
    r'\[download\] Destination: (.+)',
  ).firstMatch(logText)?.groups([1]);
  return result?.first;
}

List<String> _extractTexts(String fileName, List<String> lines) {
  final extesionName = _getExtensionName(fileName);
  final extract = _extrancTextsFunction(extesionName);
  final result = extract(lines);

  switch (result) {
    case Right(value: final texts):
      return texts;
    case Left(value: final message):
      talker.error('error in extracting texts in file "$fileName")');
      talker.error(message);
      throw Exception('Fail to extranct texts from file "$fileName"');
  }
}

String _getExtensionName(String fileName) => p.extension(fileName);

Either<String, List<String>> Function(List<String>) _extrancTextsFunction(
  String extensionName,
) => switch (extensionName) {
  '.srt' => _extractTextsFromSrt,
  _ => (texts) {
    talker.warning('unsupported subtitle format: $extensionName');
    return Either.of(texts);
  },
};

Either<String, List<String>> _extractTextsFromSrt(List<String> lines) =>
    SrtParser.parse(lines.join('\n'))
        .map((entries) => entries.expand((e) => e.lines).toList())
        .map(_combineFragmentsIntoLines);

List<String> _combineFragmentsIntoLines(
  List<String> subtitleTexts, [
  int lineSize = 80,
]) => subtitleTexts.fold(
  <String>[],
  (previousValue, element) => switch (previousValue) {
    [] => [element],
    [...(final others), final last]
        when last.length + element.length < lineSize =>
      [...others, '$last $element'],
    _ => [...previousValue, element],
  },
);
