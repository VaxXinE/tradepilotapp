import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradepilotapp/widgets/analysis_note_card.dart';
import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('adds and clears a private note without duplicate submission', (
    tester,
  ) async {
    final saved = <String>[];
    String? note;

    Future<void> pump() => tester.pumpWidget(
      localizedTestApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AnalysisNoteCard(
              note: note,
              isSaving: false,
              onSave: (value) async {
                saved.add(value);
                setState(() => note = value.trim().isEmpty ? null : value);
                return true;
              },
            ),
          ),
        ),
      ),
    );

    await pump();
    await tester.tap(find.byTooltip('Add note'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'refleksi privat');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(saved, ['refleksi privat']);
    expect(find.text('refleksi privat'), findsOneWidget);

    await tester.tap(find.text('Delete note'));
    await tester.pump();
    expect(saved, ['refleksi privat', '']);
    expect(find.text('No note for this analysis yet.'), findsOneWidget);
  });

  testWidgets('saving state disables controls', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: AnalysisNoteCard(
            note: 'ada',
            isSaving: true,
            onSave: (_) async => true,
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is TextButton && widget.onPressed == null,
      ),
      findsOneWidget,
    );
  });
}
