import 'dart:convert';
import 'package:deep_pick/deep_pick.dart';
import 'package:english_speech/common_types.dart';
import 'package:english_speech/list_extension.dart';
import 'package:english_speech/settings_service.dart';
import 'package:english_speech/web_util.dart';
import 'package:http/http.dart' as http;

Future<JSONString> fetchWebArticles() async {
  const String url =
      'https://api.notion.com/v1/databases/250ca48a86538015abd0f3fee8c6a1da/query';

  final Map<String, String> headers = {
    'Authorization': await SettingsService().getNotionApiKey(),
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
  };

  const Map<String, dynamic> body = {
    "sorts": [
      {"property": "Created time", "direction": "descending"},
    ],
    "filter": {
      "property": "Processed",
      "checkbox": {"equals": false},
    },
  };

  final res = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    return res.body;
  } else {
    throw Exception(
      'Failed to web articles. Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

List<WebArticlesPage> parseWebArticles(JSONString jsonString) {
  final json = jsonDecode(jsonString);

  return pick(json, 'results').asListOrThrow((result) {
    final id = result('id').required().asString();
    final title = result(
      'properties',
      'Source',
      'title',
      0,
      'plain_text',
    ).required().asString();
    final url = result('properties', 'URL', 'url').required().asString();

    return WebArticlesPage(id: id, title: title, url: url);
  });
}

Future<List<WebArticlesPage>> enrichArticlesWithWebTitles(
  List<WebArticlesPage> articles,
) {
  Future<WebArticlesPage> enrichArticle(WebArticlesPage article) async {
    final title = await getTitleOfWebPage(article.url);
    return article.copyWith(title: title ?? article.title);
  }

  return Future.wait(articles.map(enrichArticle));
}

class WebArticlesPage {
  final String id;
  final String title;
  final String url;

  const WebArticlesPage({
    required this.id,
    required this.title,
    required this.url,
  });

  WebArticlesPage copyWith({String? title}) =>
      WebArticlesPage(id: id, title: title ?? this.title, url: url);

  @override
  String toString() {
    return 'WebArticlesPage{id: $id, title: $title}';
  }
}

Future<List<JSONString>> fetchBlockChildren(
  String pageId, {
  String startCursor = '',
}) async {
  final String url =
      'https://api.notion.com/v1/blocks/$pageId/children?page_size=5'
      '${startCursor.isNotEmpty ? '&start_cursor=$startCursor' : ''}';

  final Map<String, String> headers = {
    'Authorization': await SettingsService().getNotionApiKey(),
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
  };

  final res = await http.get(Uri.parse(url), headers: headers);

  if (res.statusCode == 200) {
    final json = jsonDecode(res.body);
    final hasMore = pick(json, 'has_more').required().asBoolOrThrow();

    if (hasMore) {
      final cursor = pick(json, 'next_cursor').required().asString();
      final rest = await fetchBlockChildren(pageId, startCursor: cursor);

      return [res.body, ...rest];
    } else {
      return [res.body];
    }
  } else {
    throw Exception(
      'Failed to fetch blocks of the web article. '
      'Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

List<Block> parseBlockChildren(List<JSONString> jsonStrings) => jsonStrings
    .map(jsonDecode)
    .map(pick)
    .expand((p) => p('results').asListOrThrow(Block.fromPick))
    .toList();

/// A convenience function that retrieves and parses the children of a given block.
Future<List<Block>> getBlockChildren(String parentId) async {
  final jsonStrings = await fetchBlockChildren(parentId);
  final directChildren = setRowNumberForTableRows(
    parseBlockChildren(jsonStrings),
  );

  final childrenWithDescendants = await Future.wait(
    directChildren.map((child) async {
      if (child.hasChildren) {
        final descendants = await getBlockChildren(child.id);
        return child.withChildren(descendants);
      } else {
        return child;
      }
    }),
  );

  return childrenWithDescendants;
}

List<Block> setRowNumberForTableRows(List<Block> blocks) {
  bool hasSameType(Block a, Block b) => a.runtimeType == b.runtimeType;

  List<Block> assignRowNumbers(List<Block> group) => switch (group) {
    [] => [],
    [final first, ...] when first is TableRow => List.generate(
      group.length,
      (i) => group.cast<TableRow>()[i].copyWith(rowNo: i + 1),
    ),
    _ => group,
  };

  return blocks.groupBy(hasSameType).expand(assignRowNumbers).toList();
}

sealed class Block {
  final String id;
  final String type;
  final bool hasChildren;
  final List<Block> children;

  const Block({
    required this.id,
    required this.type,
    required this.hasChildren,
    this.children = const [],
  });

  factory Block.fromPick(RequiredPick pick) {
    final type = pick('type').asStringOrThrow();

    switch (type) {
      case 'paragraph':
        return Paragraph.fromPick(pick);
      case 'heading_1':
      case 'heading_2':
      case 'heading_3':
        return Headings.fromPick(pick);
      case 'bulleted_list_item':
        return BulletedListItem.fromPick(pick);
      case 'image':
        return Image.fromPick(pick);
      case 'code':
        return Code.fromPick(pick);
      case 'numbered_list_item':
        return NumberedListItem.fromPick(pick);
      case 'quote':
        return Quote.fromPick(pick);
      case 'callout':
        return Callout.fromPick(pick);
      case 'table':
        return Table.fromPick(pick);
      case 'table_row':
        return TableRow.fromPick(pick);
      default:
        return OtherBlock.fromPick(pick);
    }
  }

  /// Creates a new instance of the block with the given children.
  Block withChildren(List<Block> children);

  List<String> format();

  @override
  String toString() {
    return 'Block{id: $id, type: $type, hasChildren: $hasChildren, children: ${children.length}}';
  }
}

class Paragraph extends Block {
  final RichTexts richTexts;

  Paragraph({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.richTexts,
    super.children,
  });

  factory Paragraph.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final richTexts = pick(
      'paragraph',
      'rich_text',
    ).asListOrThrow(RichText.fromPick);

    return Paragraph(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
    );
  }

  @override
  Paragraph withChildren(List<Block> children) {
    return Paragraph(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
      children: children,
    );
  }

  @override
  String toString() {
    return 'Paragraph{id: $id, type: $type, hasChildren: $hasChildren, richTexts: $richTexts, children: ${children.length}}';
  }

  @override
  List<String> format() => [formattedRichTexts(richTexts)];
}

class Headings extends Block {
  final int level;
  final RichTexts richTexts;

  Headings({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.level,
    required this.richTexts,
    super.children,
  });

  factory Headings.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final level = int.parse(type[type.length - 1]);
    final richTexts = pick(type, 'rich_text').asListOrThrow(RichText.fromPick);

    return Headings(
      id: id,
      type: type,
      hasChildren: hasChildren,
      level: level,
      richTexts: richTexts,
    );
  }

  @override
  Headings withChildren(List<Block> children) {
    return Headings(
      id: id,
      type: type,
      hasChildren: hasChildren,
      level: level,
      richTexts: richTexts,
      children: children,
    );
  }

  @override
  String toString() {
    return 'Headings{id: $id, type: $type, hasChildren: $hasChildren, '
        'level: $level, richTexts: $richTexts, '
        'children: ${children.length}}';
  }

  @override
  List<String> format() => ['#' * level + ' ' + formattedRichTexts(richTexts)];
}

class BulletedListItem extends Block {
  final RichTexts richTexts;

  BulletedListItem({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.richTexts,
    super.children,
  });

  factory BulletedListItem.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final richTexts = pick(
      'bulleted_list_item',
      'rich_text',
    ).asListOrThrow(RichText.fromPick);

    return BulletedListItem(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
    );
  }

  @override
  BulletedListItem withChildren(List<Block> children) {
    return BulletedListItem(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
      children: children,
    );
  }

  @override
  String toString() {
    return 'BulletedListItem{id: $id, type: $type, hasChildren: $hasChildren, '
        'richTexts: $richTexts, children: ${children.length}}';
  }

  @override
  List<String> format() => ['* ' + formattedRichTexts(richTexts)];
}

class Image extends Block {
  final String url;

  Image({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.url,
    super.children,
  });

  factory Image.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final imageType = pick('image', 'type').asStringOrThrow();
    final url = switch (imageType) {
      'file' => pick('image', 'file', 'url').asStringOrThrow(),
      'file_upload' => pick('image', 'file_upload', 'id').asStringOrThrow(),
      'external' => pick('image', 'external', 'url').asStringOrThrow(),
      _ => '',
    };

    return Image(id: id, type: type, hasChildren: hasChildren, url: url);
  }

  @override
  Image withChildren(List<Block> children) {
    return Image(
      id: id,
      type: type,
      hasChildren: hasChildren,
      url: url,
      children: children,
    );
  }

  @override
  String toString() {
    return 'Image{id: $id, type: $type, hasChildren: $hasChildren, '
        'url: $url, children: ${children.length}}';
  }

  @override
  List<String> format() => ['![Image]($url)'];
}

class Code extends Block {
  final RichTexts richTexts;

  Code({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.richTexts,
    super.children,
  });

  factory Code.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final richTexts = pick(
      'code',
      'rich_text',
    ).asListOrThrow(RichText.fromPick);

    return Code(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
    );
  }

  @override
  Code withChildren(List<Block> children) {
    return Code(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
      children: children,
    );
  }

  @override
  String toString() {
    return 'Code{id: $id, type: $type, hasChildren: $hasChildren, '
        'richTexts: $richTexts, children: ${children.length}}';
  }

  @override
  List<String> format() => ['```', formattedRichTexts(richTexts), '```'];
}

class NumberedListItem extends Block {
  final RichTexts richTexts;

  NumberedListItem({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.richTexts,
    super.children,
  });

  factory NumberedListItem.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final richTexts = pick(
      'numbered_list_item',
      'rich_text',
    ).asListOrThrow(RichText.fromPick);

    return NumberedListItem(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
    );
  }

  @override
  NumberedListItem withChildren(List<Block> children) {
    return NumberedListItem(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
      children: children,
    );
  }

  @override
  String toString() {
    return 'NumberedListItem{id: $id, type: $type, hasChildren: $hasChildren, '
        'richTexts: $richTexts, children: ${children.length}}';
  }

  @override
  List<String> format() => ['- ' + formattedRichTexts(richTexts)];
}

class Quote extends Block {
  final RichTexts richTexts;

  Quote({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.richTexts,
    super.children,
  });

  factory Quote.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final richTexts = pick(
      'quote',
      'rich_text',
    ).asListOrThrow(RichText.fromPick);

    return Quote(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
    );
  }

  @override
  Quote withChildren(List<Block> children) {
    return Quote(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
      children: children,
    );
  }

  @override
  String toString() {
    return 'Quote{id: $id, type: $type, hasChildren: $hasChildren, '
        'richTexts: $richTexts, children: ${children.length}}';
  }

  @override
  List<String> format() => ['> ' + formattedRichTexts(richTexts)];
}

class Callout extends Block {
  final RichTexts richTexts;

  Callout({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.richTexts,
    super.children,
  });

  factory Callout.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final richTexts = pick(
      'callout',
      'rich_text',
    ).asListOrThrow(RichText.fromPick);

    return Callout(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
    );
  }

  @override
  Callout withChildren(List<Block> children) {
    return Callout(
      id: id,
      type: type,
      hasChildren: hasChildren,
      richTexts: richTexts,
      children: children,
    );
  }

  @override
  String toString() {
    return 'Callout{id: $id, type: $type, hasChildren: $hasChildren, '
        'richTexts: $richTexts, children: ${children.length}}';
  }

  @override
  List<String> format() => ['>>> ' + formattedRichTexts(richTexts)];
}

class Table extends Block {
  final int tableWidth;
  final bool hasColumnHeader;
  final bool hasRowHeader;

  Table({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.tableWidth,
    required this.hasColumnHeader,
    required this.hasRowHeader,
    super.children,
  });

  factory Table.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final tableWidth = pick('table', 'table_width').asIntOrThrow();
    final hasColumnHeader = pick('table', 'has_column_header').asBoolOrThrow();
    final hasRowHeader = pick('table', 'has_row_header').asBoolOrThrow();

    return Table(
      id: id,
      type: type,
      hasChildren: hasChildren,
      tableWidth: tableWidth,
      hasColumnHeader: hasColumnHeader,
      hasRowHeader: hasRowHeader,
    );
  }

  @override
  Table withChildren(List<Block> children) {
    return Table(
      id: id,
      type: type,
      hasChildren: hasChildren,
      tableWidth: tableWidth,
      hasColumnHeader: hasColumnHeader,
      hasRowHeader: hasRowHeader,
      children: children,
    );
  }

  @override
  String toString() {
    return 'Table{'
        'id: $id, '
        'type: $type, '
        'hasChildren: $hasChildren, '
        'tableWidth: $tableWidth, '
        'hasColumnHeader: $hasColumnHeader, '
        'hasRowHeader: $hasRowHeader, '
        'children: ${children.length}'
        '}';
  }

  @override
  List<String> format() => [];
}

class TableRow extends Block {
  final List<RichTexts> cells;
  final int rowNo;

  TableRow({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.cells,
    this.rowNo = 0,
    super.children,
  });

  factory TableRow.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final cells = pick(
      'table_row',
      'cells',
    ).asListOrThrow((cellPick) => cellPick.asListOrThrow(RichText.fromPick));

    return TableRow(id: id, type: type, hasChildren: hasChildren, cells: cells);
  }

  TableRow copyWith({int? rowNo}) => TableRow(
    id: id,
    type: type,
    hasChildren: hasChildren,
    cells: cells,
    rowNo: rowNo ?? this.rowNo,
    children: children,
  );

  @override
  TableRow withChildren(List<Block> children) {
    return TableRow(
      id: id,
      type: type,
      hasChildren: hasChildren,
      cells: cells,
      children: children,
    );
  }

  @override
  String toString() =>
      '|${cells.map((cell) => cell.map((richText) => richText.toString()).join('')).join('|')}|';

  @override
  List<String> format() {
    final divider = '|' + '---|' * cells.length;
    return [toString()] + (rowNo == 1 ? [divider] : []);
  }
}

class OtherBlock extends Block {
  final String content;

  OtherBlock({
    required super.id,
    required super.type,
    required super.hasChildren,
    required this.content,
    super.children,
  });

  factory OtherBlock.fromPick(RequiredPick pick) {
    final id = pick('id').asStringOrThrow();
    final type = pick('type').asStringOrThrow();
    final hasChildren = pick('has_children').asBoolOrThrow();

    final content = pick.asString();

    return OtherBlock(
      id: id,
      type: type,
      hasChildren: hasChildren,
      content: content,
    );
  }

  @override
  OtherBlock withChildren(List<Block> children) {
    return OtherBlock(
      id: id,
      type: type,
      hasChildren: hasChildren,
      content: content,
      children: children,
    );
  }

  @override
  String toString() {
    return 'OtherBlock{id: $id, type: $type, hasChildren: $hasChildren, '
        'content: $content, children: ${children.length}}';
  }

  @override
  List<String> format() => ['★Unknown block type: $type'];
}

typedef RichTexts = List<RichText>;

class RichText {
  final String plainText;

  RichText({required this.plainText});

  factory RichText.fromPick(RequiredPick pick) {
    return RichText(plainText: pick('plain_text').asStringOrThrow());
  }

  @override
  String toString() {
    return plainText;
  }
}

String formattedRichTexts(RichTexts richTexts) =>
    richTexts.map((richText) => richText.plainText).join();
