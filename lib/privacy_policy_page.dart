import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/brand_colors.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/fast_glass.dart';

const _ink = BrandColors.ink;

/// Privacy Policy for Innovator — written for the product we are shipping:
/// a liquid-glass space to capture innovations, learn, shop, collaborate,
/// and message with care for learner and creator data.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _updated = '28 July 2026';

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(animate: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
                  child: Row(
                    children: [
                      FastTap(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .55),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .95),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: _ink.withValues(alpha: .85),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Privacy & Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -.3,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.shield_outlined,
                        size: 22,
                        color: _ink.withValues(alpha: .45),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + bottom),
                    children: [
                      FastGlass(
                        borderRadius: BorderRadius.circular(24),
                        opacity: .42,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Innovator',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Where every innovation gets captured — with '
                              'respect for your identity, creations, learning, '
                              'and commerce.',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: _ink.withValues(alpha: .62),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Last updated · $_updated',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _ink.withValues(alpha: .4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _Section(
                        title: '1. Who we are',
                        body:
                            'Innovator is a student- and creator-focused platform '
                            'built to share innovations, collaborate with peers, '
                            'learn through courses, shop digital tools, and stay '
                            'connected through chat and notifications.\n\n'
                            'This Privacy Policy explains what information we '
                            'collect, how we use it, and the choices you have. '
                            'By using Innovator, you agree to this policy.',
                      ),
                      const _Section(
                        title: '2. Information we collect',
                        body:
                            'Account & profile\n'
                            '• Name, display name, email, phone, date of birth, '
                            'gender, and addresses you choose to add\n'
                            '• Education details (school, faculty, degree, major, '
                            'year, student ID, education level, enrollment year)\n'
                            '• Bio, skills, hobbies, learning goals, languages, '
                            'portfolio, and social links (Facebook, LinkedIn, '
                            'Instagram, GitHub)\n'
                            '• Profile photo, cover image, and CV / résumé files '
                            'you upload\n\n'
                            'Activity on Innovator\n'
                            '• Posts, innovations, likes, comments, reposts, and '
                            'shares on the feed\n'
                            '• Messages you send and receive in chat\n'
                            '• Courses you browse, enroll in, or complete in '
                            'e-learning\n'
                            '• Products you view, add to cart, or purchase in '
                            'the shop\n'
                            '• Collaborators, collaborating lists, and follows\n'
                            '• Notifications preferences and interactions\n\n'
                            'Technical data\n'
                            '• Device type, app version, approximate region, and '
                            'basic diagnostics needed to keep Innovator reliable '
                            'and secure\n'
                            '• Sign-in method (email or Google) when you choose '
                            'that path',
                      ),
                      const _Section(
                        title: '3. How we use your information',
                        body:
                            'We use your information to:\n'
                            '• Create and personalize your Innovator profile\n'
                            '• Show your innovations, learning progress, and '
                            'shop activity where you expect them\n'
                            '• Power chat, notifications, search, and '
                            'collaboration features\n'
                            '• Process cart, checkout, delivery, and refund '
                            'flows for digital products\n'
                            '• Improve liquid-glass performance, safety, and '
                            'product quality\n'
                            '• Communicate important updates about your account, '
                            'orders, or courses\n'
                            '• Protect the community from abuse, fraud, and '
                            'unauthorized access\n\n'
                            'We do not sell your personal information.',
                      ),
                      const _Section(
                        title: '4. Sharing & visibility',
                        body:
                            'What you publish\n'
                            'Content you post (innovations, captions, public '
                            'profile details, and collaboration status) can be '
                            'seen by other Innovator members according to the '
                            'feature’s design.\n\n'
                            'Private by default where it matters\n'
                            'Chat messages, cart contents, payment details, and '
                            'editable profile fields you keep private are not '
                            'shown as public feed content.\n\n'
                            'Service partners\n'
                            'We may share limited data with trusted providers '
                            'who help us run Innovator — for example hosting, '
                            'analytics, payments (such as Khalti), email, or '
                            'file storage — only as needed to operate the '
                            'product and under appropriate safeguards.\n\n'
                            'Legal requests\n'
                            'We may disclose information if required by law or '
                            'to protect the rights, safety, and integrity of '
                            'Innovator and its community.',
                      ),
                      const _Section(
                        title: '5. Learning, shop & payments',
                        body:
                            'E-learning\n'
                            'Course progress, certificates, and learning goals '
                            'help us personalize your experience. Instructors '
                            'and mentors only receive what is needed to deliver '
                            'the course.\n\n'
                            'Shop & cart\n'
                            'Orders, downloads, and refund requests (including '
                            'our 7-day refund policy where applicable) are kept '
                            'to fulfill purchases and support. Payment partners '
                            'process card or wallet details under their own '
                            'policies; Innovator does not store full payment '
                            'credentials on device for this demo experience.\n\n'
                            'Digital goods\n'
                            'Licenses and downloads are tied to your account so '
                            'you can access what you bought securely.',
                      ),
                      const _Section(
                        title: '6. Messages, media & auto-delete',
                        body:
                            'Chat is meant for collaboration and support. You '
                            'are responsible for what you send. Features like '
                            'message auto-delete (for example after 24 hours) '
                            'are tools you control; once deleted, messages may '
                            'not be recoverable.\n\n'
                            'Photos, cover images, and CVs you upload remain '
                            'under your account until you replace or remove '
                            'them. Please avoid uploading sensitive documents '
                            'you would not want stored with your profile.',
                      ),
                      const _Section(
                        title: '7. Your choices & controls',
                        body:
                            'You can:\n'
                            '• Edit or clear profile fields anytime in Edit '
                            'information\n'
                            '• Change cover, avatar, and CV from your profile '
                            'menu\n'
                            '• Manage notifications and mute what you do not '
                            'need\n'
                            '• Block or report harmful content and accounts\n'
                            '• Sign out from the drawer when you leave a shared '
                            'device\n'
                            '• Request account deletion or a copy of your data '
                            'by contacting Innovator support\n\n'
                            'If you sign in with Google, you can also review '
                            'permissions in your Google account settings.',
                      ),
                      const _Section(
                        title: '8. Data retention & security',
                        body:
                            'We keep information only as long as needed to '
                            'provide Innovator, meet legal obligations, resolve '
                            'disputes, and enforce our policies.\n\n'
                            'We use reasonable technical and organizational '
                            'measures — including encrypted transport where '
                            'available, access controls, and careful handling '
                            'of uploads — to protect your data. No system is '
                            'perfectly secure; please use a strong password and '
                            'treat shared devices carefully.',
                      ),
                      const _Section(
                        title: '9. Children & learners',
                        body:
                            'Innovator is designed for students and creators. '
                            'If you are under the age required by your local '
                            'law to consent to online services, please use '
                            'Innovator only with a parent or guardian’s '
                            'involvement. We do not knowingly collect personal '
                            'data from children in violation of applicable law.',
                      ),
                      const _Section(
                        title: '10. International use',
                        body:
                            'Innovator may be accessed from Nepal and beyond. '
                            'If you use the app from another country, your '
                            'information may be processed where our service '
                            'infrastructure operates. We aim to apply '
                            'protections consistent with this policy wherever '
                            'your data is handled.',
                      ),
                      const _Section(
                        title: '11. Changes to this policy',
                        body:
                            'As Innovator grows — new learning tools, shop '
                            'features, or collaboration modes — we may update '
                            'this Privacy Policy. We will refresh the “Last '
                            'updated” date and, for meaningful changes, give '
                            'notice in the app when practical. Continued use '
                            'after an update means you accept the revised '
                            'policy.',
                      ),
                      const _Section(
                        title: '12. Contact',
                        body:
                            'Questions about privacy, data requests, or this '
                            'policy:\n\n'
                            'Innovator Support\n'
                            'privacy@innovator.app\n'
                            'Kathmandu, Nepal\n\n'
                            'We are building a place where innovations are '
                            'captured proudly — and protected carefully. Thank '
                            'you for trusting Innovator.',
                        isLast: true,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '© Innovator · Built with liquid care',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _ink.withValues(alpha: .35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 8 : 16),
      child: FastGlass(
        borderRadius: BorderRadius.circular(20),
        opacity: .34,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: _ink.withValues(alpha: .68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
