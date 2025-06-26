class Reference {
  String title;
  String author;
  String year;
  String source;

  Reference({
    required this.title,
    required this.author,
    required this.year,
    required this.source,
  });
}

class Subchapter {
  String title;
  String content;

  Subchapter({
    required this.title,
    required this.content,
  });
}

class ThesisStructure {
  String title;
  String author;
  List<Chapter> chapters;
  List<Reference> references;

  ThesisStructure({
    required this.title,
    required this.author,
    required this.chapters,
    required this.references,
  });
}

class Chapter {
  String title;
  String content;
  List<Subchapter> subchapters;

  Chapter({
    required this.title,
    required this.content,
    required this.subchapters,
  });
}