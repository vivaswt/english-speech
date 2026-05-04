import 'package:english_speech/fp/either.dart';
import 'package:english_speech/fp/parser.dart';

class SrtEntry {
  final int index;
  final Duration start;
  final Duration end;
  final List<String> lines;

  SrtEntry({
    required this.index,
    required this.start,
    required this.end,
    required this.lines,
  });

  @override
  String toString() => '[$index] $start --> $end: ${lines.join(" ")}';
}

/// A parser for the SubRip (SRT) subtitle format.
class SrtParser {
  static final Parser<int> _integer = many1(
    digit,
  ).map((ds) => int.parse(ds.join()));

  static final Parser<Duration> _timestamp = Parser.doNotation(($) {
    final hh = $(_integer);
    $(char(':'));
    final mm = $(_integer);
    $(char(':'));
    final ss = $(_integer);
    $(char(','));
    final ms = $(_integer);
    return Duration(hours: hh, minutes: mm, seconds: ss, milliseconds: ms);
  });

  static final Parser<String> _line = Parser.doNotation(($) {
    // Parse characters until a newline
    final content = $(many1(noneOf('\n')));
    $(newLine);
    return content.join().trim();
  });

  static final Parser<SrtEntry> _entry = Parser.doNotation(($) {
    final index = $(_integer);
    $(newLine);

    final start = $(_timestamp);
    $(string(' --> '));
    final end = $(_timestamp);
    $(newLine);

    // SRT lines end when we hit an empty line or end of input
    final lines = $(many1(_line));

    // Optional trailing newline to separate entries
    $(optional(newLine));

    return SrtEntry(index: index, start: start, end: end, lines: lines);
  });

  /// The main parser for an entire SRT file.
  static final Parser<List<SrtEntry>> srtFile = many1(_entry);

  /// Helper method to parse a string.
  static Either<ParserErrorMessage, List<SrtEntry>> parse(String input) {
    // Ensure consistent line endings and trailing newline for the parser logic
    final normalizedInput = '${input.replaceAll('\r\n', '\n').trim()}\n';
    final result = srtFile(ParserInput(normalizedInput));

    return result.map((res) => res.$1);
  }
}
