import 'package:flutter/material.dart';

class ThesisTable extends StatelessWidget {
  final String title;
  final List<List<String>> data;
  final String source;

  const ThesisTable({
    Key? key,
    required this.title,
    required this.data,
    required this.source,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11),
        ),
        Table(
          border: TableBorder.all(),
          children: data.map((row) {
            return TableRow(
              children: row.map((cell) {
                return Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(cell),
                );
              }).toList(),
            );
          }).toList(),
        ),
        Text(
          'Source: $source',
          style: TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
