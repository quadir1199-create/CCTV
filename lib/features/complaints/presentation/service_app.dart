import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../auth/presentation/sign_in_screen.dart';
import '../../auth/domain/customer_profile.dart';
import '../domain/complaint.dart';

const _ink = Color(0xFF142B36);
const _teal = Color(0xFF007F78);
String statusLabel(ComplaintStatus status) => switch (status) {
  ComplaintStatus.submitted => 'Submitted',
  ComplaintStatus.assigned => 'Assigned',
  ComplaintStatus.inProgress => 'In progress',
  ComplaintStatus.resolved => 'Resolved',
};
String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';

class ServiceApp extends ConsumerWidget {
  const ServiceApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'CameraCare',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _teal),
      scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F7F8),
        foregroundColor: _ink,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    ),
    // Keep the sign-in screen alive until verification and profile saving finish.
    home: ref.watch(authFlowBusyProvider)
        ? const SignInScreen()
        : ref
              .watch(currentUserProvider)
              .when(
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SignInScreen(),
                data: (user) => user == null
                    ? const SignInScreen()
                    : ref
                          .watch(customerProfileProvider)
                          .when(
                            loading: () => const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, _) => ProfileLoadError(
                              onRetry: () =>
                                  ref.invalidate(customerProfileProvider),
                            ),
                            data: (profile) => profile == null
                                ? CompleteProfileScreen(user: user)
                                : Dashboard(profile: profile),
                          ),
              ),
  );
}

class ProfileLoadError extends StatelessWidget {
  const ProfileLoadError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'We could not load your account. Check your connection.',
            ),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.profile});
  final CustomerProfile profile;
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final titles = [
      'CameraCare',
      'Service requests',
      'Help centre',
      'My account',
    ];
    final pages = [
      HomeTab(
        profile: widget.profile,
        onViewAll: () => setState(() => _index = 1),
      ),
      const RequestsTab(),
      const HelpTab(),
      AccountTab(profile: widget.profile),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Help',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.profile, required this.onViewAll});
  final CustomerProfile profile;
  final VoidCallback onViewAll;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(complaintsProvider);
    final firstName = profile.fullName.trim().split(' ').first;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(complaintsProvider);
        await ref.read(complaintsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        children: [
          if (ref.watch(demoModeProvider))
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'DEMO • Sample data is stored in memory',
                style: TextStyle(color: _teal, fontWeight: FontWeight.w600),
              ),
            ),
          Text(
            'Hello, $firstName',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _teal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your security.\nOur support.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Report a camera issue and follow its repair journey.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.support_agent,
                  color: Color(0xFF85DFCF),
                  size: 32,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Need a hand with your camera?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us what happened. We’ll take it from here.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF85DFCF),
                    foregroundColor: _ink,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NewComplaintScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Register complaint'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          complaints.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) {
              final active = items
                  .where((item) => item.status != ComplaintStatus.resolved)
                  .length;
              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'All requests',
                      value: '${items.length}',
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'In progress',
                      value: '$active',
                      icon: Icons.hourglass_top,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent requests',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View all')),
            ],
          ),
          complaints.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _InlineError(onRetry: () => ref.invalidate(complaintsProvider)),
            data: (items) => items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No service requests yet. Register a complaint when you need support.',
                    ),
                  )
                : Column(
                    children: items
                        .take(3)
                        .map((item) => ComplaintCard(item: item))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: _teal),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    ),
  );
}

class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});
  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab> {
  int _filter = 0;
  @override
  Widget build(BuildContext context) => ref
      .watch(complaintsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _InlineError(onRetry: () => ref.invalidate(complaintsProvider)),
        data: (items) {
          final filtered = items
              .where(
                (item) => switch (_filter) {
                  0 => true,
                  1 => item.status != ComplaintStatus.resolved,
                  _ => item.status == ComplaintStatus.resolved,
                },
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('All')),
                  ButtonSegment(value: 1, label: Text('Active')),
                  ButtonSegment(value: 2, label: Text('Resolved')),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) =>
                    setState(() => _filter = selection.first),
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined, size: 48, color: _teal),
                      const SizedBox(height: 12),
                      Text(
                        items.isEmpty
                            ? 'No requests yet'
                            : 'Nothing in this filter',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your camera service requests will appear here.',
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((item) => ComplaintCard(item: item)),
            ],
          );
        },
      );
}

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({super.key, required this.item});
  final Complaint item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F4F1),
          child: Icon(Icons.videocam_outlined, color: _teal),
        ),
        title: Text(
          item.product,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${statusLabel(item.status)} · ${dateLabel(item.createdAt)}',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ComplaintDetail(id: item.id)),
        ),
      ),
    ),
  );
}

class HelpTab extends StatelessWidget {
  const HelpTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Text(
        'How can we help?',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text('Answers to common service questions.'),
      const SizedBox(height: 20),
      _Faq(
        question: 'How do I register a camera issue?',
        answer:
            'Tap Register complaint on the Home screen. Add the model, serial number, installation address and a short description of the issue.',
      ),
      _Faq(
        question: 'Where can I track my repair?',
        answer:
            'Open Service requests to see the latest status. Tap a request to view its reference number and progress.',
      ),
      _Faq(
        question: 'Where can I find my camera serial number?',
        answer:
            'Look for the product label on the camera body, packaging or purchase invoice. The label is often near the mounting base.',
      ),
      _Faq(
        question: 'What happens after I submit a complaint?',
        answer:
            'Your request is recorded as Submitted. A service representative can assign and update it as work progresses.',
      ),
      const SizedBox(height: 18),
      Card(
        color: _ink,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.support_agent,
                color: Color(0xFF85DFCF),
                size: 30,
              ),
              const SizedBox(height: 12),
              const Text(
                'Still need help?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Send us the details through a service request and our support team can follow up.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NewComplaintScreen(),
                  ),
                ),
                child: const Text('Register a complaint'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});
  final String question, answer;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [Text(answer)],
    ),
  );
}

class AccountTab extends ConsumerWidget {
  const AccountTab({super.key, required this.profile});
  final CustomerProfile profile;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Center(
        child: Column(
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFE7F4F1),
              child: Icon(Icons.person, size: 42, color: _teal),
            ),
            const SizedBox(height: 12),
            Text(
              profile.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(profile.email, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Card(
        color: Colors.white,
        elevation: 0,
        child: Column(
          children: [
            if (profile.phone.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: _teal),
                title: const Text('Mobile number'),
                subtitle: Text(profile.phone),
              ),
              const Divider(height: 1, indent: 56),
            ],
            ListTile(
              leading: const Icon(Icons.email_outlined, color: _teal),
              title: const Text('Email address'),
              subtitle: Text(profile.email),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Card(
        color: Colors.white,
        elevation: 0,
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Account security'),
              subtitle: Text(
                'Your account is protected by mobile verification.',
              ),
            ),
            const Divider(height: 1, indent: 56),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('CameraCare'),
              subtitle: Text('CCTV service and repair support'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () async {
          try {
            await ref.read(authRepositoryProvider).signOut();
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not sign out. Try again.')),
              );
            }
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
    ],
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 10),
          const Text('Could not load requests. Check your connection.'),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class NewComplaintScreen extends ConsumerStatefulWidget {
  const NewComplaintScreen({super.key});
  @override
  ConsumerState<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends ConsumerState<NewComplaintScreen> {
  final _form = GlobalKey<FormState>();
  final _product = TextEditingController(),
      _serial = TextEditingController(),
      _issue = TextEditingController(),
      _address = TextEditingController();
  @override
  void dispose() {
    for (final c in [_product, _serial, _issue, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final id = await ref
        .read(submissionProvider.notifier)
        .submit(
          ComplaintDraft(
            product: _product.text,
            serialNumber: _serial.text,
            description: _issue.text,
            address: _address.text,
          ),
        );
    if (!mounted) return;
    if (id != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complaint registered. Follow progress in your service requests.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submissionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Register complaint')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Let’s get it sorted.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Share your product and installation details.'),
              const SizedBox(height: 28),
              _field(_product, 'Product / camera model', 100),
              const SizedBox(height: 16),
              _field(_serial, 'Serial number', 100),
              const SizedBox(height: 16),
              _field(_issue, 'Describe the issue', 2000, lines: 4, minimum: 10),
              const SizedBox(height: 16),
              _field(_address, 'Installation address', 500, lines: 3),
              const SizedBox(height: 20),
              if (state.hasError)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Could not submit. Check your connection and try again.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton(
                onPressed: state.isLoading ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    state.isLoading ? 'Submitting…' : 'Submit complaint',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    int maximum, {
    int lines = 1,
    int minimum = 1,
  }) => TextFormField(
    controller: controller,
    maxLength: maximum,
    maxLines: lines,
    decoration: InputDecoration(labelText: label),
    validator: (v) => (v?.trim().length ?? 0) >= minimum
        ? null
        : 'Enter at least $minimum characters',
  );
}

class ComplaintDetail extends ConsumerWidget {
  const ComplaintDetail({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Request details')),
    body: ref
        .watch(complaintsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Could not load this request.')),
          data: (items) {
            final matching = items.where((c) => c.id == id);
            if (matching.isEmpty) {
              return const Center(child: Text('Request not found.'));
            }
            final item = matching.first;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  item.product,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText('Reference: ${item.id}'),
                Text('Registered ${dateLabel(item.createdAt)}'),
                const SizedBox(height: 28),
                ...ComplaintStatus.values.map((status) {
                  final reached = status.index <= item.status.index;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      reached ? Icons.check_circle : Icons.circle_outlined,
                      color: reached ? _teal : Colors.grey,
                    ),
                    title: Text(statusLabel(status)),
                    subtitle: status == item.status
                        ? const Text('Current status')
                        : null,
                  );
                }),
                const Divider(height: 40),
                const Text(
                  'Issue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(item.description),
                const SizedBox(height: 24),
                const Text(
                  'Serial number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item.serialNumber),
                const SizedBox(height: 24),
                const Text(
                  'Installation address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(item.address),
              ],
            );
          },
        ),
  );
}
