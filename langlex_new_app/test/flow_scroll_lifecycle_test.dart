import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langlex_new_app/features/dashboard/widgets/flow_scroll_view.dart';

void main() {
  testWidgets('floating header survives detach, reattach and another snap', (
    tester,
  ) async {
    final scrollKey = GlobalKey();
    final controller = ScrollController();
    Widget view(bool moved) {
      final scroll = FlowScrollView(
        key: scrollKey,
        controller: controller,
        header: const SizedBox(height: 180, child: Text('Header')),
        child: const SizedBox(height: 2400, child: Text('Content')),
      );
      return MaterialApp(
        home: Scaffold(
          body: moved
              ? Padding(padding: EdgeInsets.zero, child: scroll)
              : Align(child: scroll),
        ),
      );
    }

    await tester.pumpWidget(view(false));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 4; i++) {
      await tester.pumpWidget(view(i.isEven));
      await tester.drag(
        find.byType(CustomScrollView),
        Offset(0, i.isEven ? 40 : -40),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    expect(tester.takeException(), isNull);
  });
}
