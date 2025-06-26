class TextProcessor {
  static String processHierarchy(String content) {
    final lines = content.split('\n');
    final processedLines = lines.map((line) {
      // Remove X.0 patterns where X is any number
      line = line.replaceAll(RegExp(r'\d+\.0\s+'), '');

      // Handle markdown headers
      if (line.startsWith('##')) {
        return line.replaceFirst('##', '').trim();
      } else if (line.startsWith('#')) {
        return line.replaceFirst('#', '').trim();
      }

      // Clean up any multiple spaces
      return line.replaceAll(RegExp(r'\s+'), ' ').trim();
    }).toList();

    return processedLines.join('\n');
  }
}

