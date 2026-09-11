import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/presentation/widgets/stock_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Stock _stock({double change = 15.2}) => Stock(
      symbol: 'RELIANCE',
      companyName: 'Reliance Industries Ltd',
      logoUrl: '',
      ltp: 1420.5,
      change: change,
      changePercent: change >= 0 ? 1.08 : -1.08,
      open: 1400,
      high: 1425,
      low: 1399,
      previousClose: 1405.3,
      exchange: 'NSE',
      industry: 'Energy',
      marketCap: 1000000,
      currency: 'USD',
    );

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders symbol, company name, LTP and signed change',
      (tester) async {
    await tester.pumpWidget(host(StockCard(stock: _stock(), onTap: () {})));

    expect(find.text('RELIANCE'), findsOneWidget);
    expect(find.text('Reliance Industries Ltd'), findsOneWidget);
    expect(find.textContaining('1,420.50'), findsOneWidget);
    expect(find.textContaining('+15.20'), findsOneWidget);
    expect(find.textContaining('+1.08%'), findsOneWidget);
  });

  testWidgets('tapping the card invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(StockCard(stock: _stock(), onTap: () => tapped = true)),
    );

    await tester.tap(find.byType(StockCard));
    expect(tapped, isTrue);
  });

  testWidgets('omitting trailing renders no extra widget', (tester) async {
    await tester.pumpWidget(host(StockCard(stock: _stock(), onTap: () {})));

    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('a supplied trailing widget renders and responds to taps',
      (tester) async {
    var trailingTapped = false;
    await tester.pumpWidget(host(StockCard(
      stock: _stock(),
      onTap: () {},
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => trailingTapped = true,
      ),
    )));

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(trailingTapped, isTrue);
  });

  testWidgets('a gain is green; a loss is not', (tester) async {
    await tester.pumpWidget(host(StockCard(stock: _stock(), onTap: () {})));
    final gain = tester.widget<Text>(find.textContaining('+15.20'));
    expect(gain.style?.color, Colors.green.shade700);

    await tester.pumpWidget(
      host(StockCard(stock: _stock(change: -8), onTap: () {})),
    );
    final loss = tester.widget<Text>(find.textContaining('-8.00'));
    expect(loss.style?.color, isNot(Colors.green.shade700));
    expect(loss.style?.color, isNotNull);
  });
}
