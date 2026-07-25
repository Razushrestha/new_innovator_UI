import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:innovator/main.dart';
import 'package:innovator/shop_models.dart';
import 'package:innovator/widgets/liquid_nav_bar.dart';

void main() {
  testWidgets('Login page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Sign up link opens signup page', (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('Sign up'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Sign up'));
    // Route transition (450ms) + entrance animation (900ms).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('Sign In goes straight to the dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));

    // Auth is bypassed: no credentials needed.
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Aarav Sharma'), findsOneWidget); // feed content

    // Nav bar: Chat, E-learning, Search · [logo] · Post, Shop, Menu.
    for (final label in [
      'Chat',
      'E-learning',
      'Search',
      'Post',
      'Shop',
      'Menu',
    ]) {
      expect(find.byTooltip(label), findsOneWidget);
    }
    expect(find.byTooltip('Feed'), findsOneWidget);

    // The drawer opens from the nav bar's menu icon.
    await tester.tap(find.byTooltip('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Premium Member'), findsOneWidget);
    for (final label in [
      'Profile',
      'Shop',
      'E-learning',
      'Privacy & Policy',
      'Settings',
      'FAQ',
      'Logout',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    // Logout from the drawer returns to the login page.
    await tester.tap(find.text('Logout'));
    await tester.pump(const Duration(milliseconds: 300)); // liquid delay
    await tester.pump(const Duration(milliseconds: 500)); // route fade
    await tester.pump(const Duration(seconds: 1)); // entrance animation
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Post page opens from the nav bar with composer and attachments',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // The Post nav icon swaps the compose section in under the nav bar.
    await tester.tap(find.byTooltip('Post'));
    await tester.pump(const Duration(milliseconds: 500)); // section switch
    await tester.pump(const Duration(milliseconds: 800)); // entrance

    expect(find.byTooltip('Feed'), findsOneWidget); // nav bar stays
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('Share something inspiring…'), findsOneWidget);
    expect(find.text('Attachment'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);

    // Typing enables the Post action.
    await tester.enterText(
        find.byType(TextField), 'Shipping the liquid post composer!');
    await tester.pump();

    // The attachment sheet lists every supported kind.
    await tester.tap(find.text('Attachment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Add attachment'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('PDF document'), findsOneWidget);
    expect(find.text('Browse files'), findsOneWidget);
    expect(find.text('Any file type is supported'), findsOneWidget);

    // Dismiss the sheet, post, and land back on the dashboard.
    await tester.tapAt(const Offset(400, 80));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Post'));
    await tester.pump(const Duration(milliseconds: 500)); // liquid wave
    await tester.pump(const Duration(milliseconds: 600)); // wave + pop
    await tester.pump(const Duration(milliseconds: 400)); // route settles
    expect(find.text('Aarav Sharma'), findsOneWidget); // feed content
    expect(find.text('Your post is live'), findsOneWidget);
  });

  testWidgets('Shop page shows featured, categories and products',
      (WidgetTester tester) async {
    Cart.instance.clear(); // the cart singleton outlives individual tests
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byTooltip('Shop'));
    await tester.pump(const Duration(milliseconds: 500)); // section switch
    await tester.pump(const Duration(seconds: 1)); // entrance

    // The nav bar stays present while the shop section swaps in.
    expect(find.byTooltip('Post'), findsOneWidget);
    expect(find.byTooltip('Feed'), findsOneWidget);

    // Featured carousel, categories, and the product grid.
    expect(find.text('Innovator Pro Bundle'), findsOneWidget);
    expect(find.text('Save 40%'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Pitch Deck Kit'), findsOneWidget);
    expect(find.text('Brand Identity Pack'), findsOneWidget);

    // Category chips filter the grid.
    // One pump starts the grid cross-fade, the rest let it finish.
    await tester.tap(find.text('Courses').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('UX Research Course'), findsOneWidget);
    expect(find.text('Pitch Deck Kit'), findsNothing);
    await tester.tap(find.text('All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Pitch Deck Kit'), findsOneWidget);

    // Adding to cart bumps the badge on the floating cart orb.
    expect(find.byTooltip('Cart'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.add_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1'), findsOneWidget);

    // The cart orb opens the cart section: table with S.N, item, qty,
    // price and total, plus the VAT/delivery summary and Khalti checkout.
    await tester.tap(find.byTooltip('Cart'));
    await tester.pump(const Duration(milliseconds: 500)); // section switch
    await tester.pump(const Duration(seconds: 1)); // entrance
    expect(find.text('Your cart'), findsOneWidget);
    for (final label in ['S.N', 'Item', 'Qty', 'Price', 'Total']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Pitch Deck Kit'), findsOneWidget);
    expect(find.text('VAT (13%)'), findsOneWidget);
    expect(find.text('Delivery (Nepal)'), findsOneWidget);
    expect(find.text('Rs 200'), findsOneWidget);
    expect(find.text('Checkout with Khalti'), findsOneWidget);
    // 2400 + 13% VAT + 200 delivery = 2912.
    expect(find.text('Rs 2,912'), findsAtLeastNWidgets(1));

    // The + control raises the quantity and the totals follow.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2'), findsOneWidget);
    // 4800 + 624 VAT + 200 delivery = 5624.
    expect(find.text('Rs 5,624'), findsAtLeastNWidgets(1));

    // Checkout opens the Khalti sheet; a wallet number pays the bill.
    await tester.ensureVisible(find.text('Checkout with Khalti'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Checkout with Khalti'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Khalti'), findsOneWidget);
    expect(find.text('Digital wallet · Nepal'), findsOneWidget);
    expect(find.textContaining('Pay Rs'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '9800000001');
    await tester.tap(find.textContaining('Pay Rs'));
    await tester.pump(const Duration(milliseconds: 1000)); // processing
    expect(find.text('Payment successful'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000)); // sheet closes
    await tester.pump(const Duration(milliseconds: 400));

    // Cart is cleared after a successful payment.
    expect(find.text('Your cart is empty'), findsOneWidget);

    // Let the confirmation snackbar clear the nav bar before tapping it.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // The logo brings the feed back, nav bar never left.
    await tester.tap(find.byTooltip('Feed'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Aarav Sharma'), findsOneWidget); // feed content
  });

  testWidgets('Profile opens from the drawer with stats and innovations',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byTooltip('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 300)); // drawer close
    await tester.pump(const Duration(milliseconds: 500)); // section switch
    await tester.pump(const Duration(seconds: 1)); // entrance

    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    expect(find.text('Innovator'), findsOneWidget);
    expect(find.text('Collaborators'), findsOneWidget);
    expect(find.text('Collaborating'), findsOneWidget);
    expect(find.text('Innovation'), findsOneWidget);
    expect(find.text('Innovations'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    // Title badge cycles through the role set.
    await tester.tap(find.text('Innovator'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Creator'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Liquid Glass Nav'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Liquid Glass Nav'), findsOneWidget);
  });

  testWidgets('Chat opens from the nav bar, sends and receives messages',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // The Chat nav icon swaps in the conversation list.
    await tester.tap(find.byTooltip('Chat'));
    await tester.pump(const Duration(milliseconds: 500)); // section switch
    await tester.pump(const Duration(seconds: 1)); // entrance
    expect(find.text('Search chats & people…'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget); // recent chat circle
    expect(find.text('Sita'), findsOneWidget); // recent follower circle
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Maya Chen'), findsWidgets);
    expect(find.text('Innovator Team'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // unread droplet

    // Opening a conversation from the clean list.
    await tester.tap(find.text('Maya Chen').last);
    await tester.pump(const Duration(milliseconds: 500)); // switch
    await tester.pump(const Duration(milliseconds: 600)); // bubbles pop in
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Ship it to the team build today?'), findsOneWidget);
    expect(find.text('Message…'), findsOneWidget);

    // Sending launches a bouncy water drop; the bubble lands after it arrives.
    await tester.enterText(find.byType(TextField), 'The liquid chat is done!');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // drop in flight
    await tester.pump(const Duration(milliseconds: 500)); // drop lands
    expect(find.text('The liquid chat is done!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600)); // typing starts
    await tester.pump(const Duration(milliseconds: 1600)); // reply arrives
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Love that — let’s do it.'), findsOneWidget);

    // The liquid 3-dot opens a small popover card just below it.
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Auto delete after 24 hour'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);

    await tester.tap(find.text('Auto delete after 24 hour'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Auto delete in 24 hours'), findsOneWidget);

    // Back returns to the conversation list.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Messages'), findsOneWidget);
  });

  testWidgets('E-learning shows featured, top selling, categories and courses',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byTooltip('E-learning'));
    await tester.pump(const Duration(milliseconds: 500)); // section switch
    await tester.pump(const Duration(seconds: 1)); // entrance

    // Nav bar persists; featured carousel and top-selling rail render.
    expect(find.byTooltip('Feed'), findsOneWidget);
    expect(find.text('Flutter Masterclass'), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('Top selling'), findsOneWidget);
    expect(find.text('#1 bestseller'), findsOneWidget);
    expect(find.text('Certificates'), findsOneWidget);

    // Scroll down to the categories row.
    await tester.scrollUntilVisible(
      find.text('Categories'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Categories'), findsOneWidget);

    // Category chips filter the course grid with the liquid cross-fade.
    await tester.ensureVisible(find.text('Design'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Design'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(
      find.text('Design Systems Pro'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Design Systems Pro'), findsAtLeastNWidgets(1));
    expect(find.text('Brand Storytelling'), findsNothing);

    // View courses sits beside Enroll now; both are liquid pressables.
    expect(find.text('View courses'), findsWidgets);
    expect(find.text('Enroll now'), findsWidgets);

    // Enroll now floods with liquid and becomes Enrolled.
    await tester.ensureVisible(find.text('Enroll now').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Enroll now').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Enrolled'), findsOneWidget);

    // Card tap / View courses opens the liquid detail sheet.
    await tester.tap(find.text('View courses').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('premium liquid-designed course'),
      findsOneWidget,
    );
  });

  testWidgets('Search bar elongates from the nav icon and filters live',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // The Search nav icon swaps in the search section: a droplet that
    // stretches into a full search pill, with trending chips beneath.
    await tester.tap(find.byTooltip('Search'));
    await tester.pump(const Duration(milliseconds: 500)); // section switch
    await tester.pump(const Duration(seconds: 1)); // pill elongation
    expect(find.text('Search people, products…'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Design'), findsOneWidget);

    // Typing filters people live, right beneath the bar.
    await tester.enterText(find.byType(TextField), 'aarav');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Product Designer'), findsOneWidget);
    expect(find.text('1 result'), findsOneWidget);

    // Products match too, on name or category.
    await tester.enterText(find.byType(TextField), 'course');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('UX Research Course', findRichText: true),
        findsOneWidget);
    expect(find.text('Growth Marketing 101', findRichText: true),
        findsOneWidget);

    // Nonsense queries get the liquid empty state.
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('No matches'), findsOneWidget);

    // Clearing brings trending back; a chip fills the query.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Template'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Pitch Deck Kit', findRichText: true), findsOneWidget);
  });

  testWidgets('Nav bar drags and docks to every edge',
      (WidgetTester tester) async {
    await tester.pumpWidget(const InnovatorApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Sign In'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // Drags from the bar's center to [target] in steps, then releases.
    Future<void> dragBarTo(Offset target) async {
      final start = tester.getCenter(find.byType(LiquidNavBar));
      final gesture = await tester.startGesture(start);
      final step = (target - start) / 5;
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(step);
        await tester.pump(const Duration(milliseconds: 30));
      }
      await gesture.up();
      // Let the spring-in animation settle.
      await tester.pump(const Duration(milliseconds: 700));
    }

    // Screen in tests is 800x600. Left edge -> vertical rail on the left.
    await dragBarTo(const Offset(30, 300));
    var rect = tester.getRect(find.byType(LiquidNavBar));
    expect(rect.width, lessThan(rect.height),
        reason: 'left dock should be a vertical rail');
    expect(rect.left, lessThan(100));

    // Top edge -> horizontal bar at the top.
    await dragBarTo(const Offset(400, 30));
    rect = tester.getRect(find.byType(LiquidNavBar));
    expect(rect.width, greaterThan(rect.height),
        reason: 'top dock should be a horizontal bar');
    expect(rect.top, lessThan(120));

    // Right edge -> vertical rail on the right.
    await dragBarTo(const Offset(770, 300));
    rect = tester.getRect(find.byType(LiquidNavBar));
    expect(rect.width, lessThan(rect.height),
        reason: 'right dock should be a vertical rail');
    expect(rect.right, greaterThan(700));

    // Bottom edge -> horizontal bar at the bottom.
    await dragBarTo(const Offset(400, 570));
    rect = tester.getRect(find.byType(LiquidNavBar));
    expect(rect.width, greaterThan(rect.height),
        reason: 'bottom dock should be a horizontal bar');
    expect(rect.bottom, greaterThan(480));

    // Icons still work after all that moving around.
    expect(find.byTooltip('Chat'), findsOneWidget);
    expect(find.byTooltip('Feed'), findsOneWidget);
  });
}
