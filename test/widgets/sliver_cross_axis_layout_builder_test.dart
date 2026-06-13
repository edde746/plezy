import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/widgets/sliver_cross_axis_layout_builder.dart';

void main() {
  testWidgets('builder runs on width change and widget update, never from scrolling', (tester) async {
    var builderCalls = 0;
    var firstItemBuilds = 0;
    double? lastExtent;

    Widget app(double width) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: 400,
          child: CustomScrollView(
            slivers: [
              SliverCrossAxisLayoutBuilder(
                builder: (context, crossAxisExtent) {
                  builderCalls++;
                  lastExtent = crossAxisExtent;
                  return SliverList.builder(
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Builder(
                          builder: (context) {
                            firstItemBuilds++;
                            return const SizedBox(height: 50);
                          },
                        );
                      }
                      return const SizedBox(height: 50);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(300));
    expect(builderCalls, 1);
    expect(lastExtent, 300);
    expect(firstItemBuilds, 1);

    // Scrolling changes SliverConstraints.scrollOffset but not the cross-axis
    // extent: the builder must not re-run, and the realized first item (still
    // within the cache extent) must not be rebuilt.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(builderCalls, 1, reason: 'scrolling must not re-invoke the builder');
    expect(firstItemBuilds, 1, reason: 'scrolling must not rebuild realized children');

    // A real width change re-runs the builder with the new extent.
    await tester.pumpWidget(app(250));
    await tester.pumpAndSettle();
    expect(builderCalls, 2);
    expect(lastExtent, 250);

    // Updating the widget (new builder closure from a parent rebuild) re-runs
    // it even at the same width — data changes must always propagate.
    await tester.pumpWidget(app(250));
    await tester.pumpAndSettle();
    expect(builderCalls, 3);
  });
}
