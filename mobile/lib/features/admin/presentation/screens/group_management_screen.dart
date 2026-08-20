import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/presentation/providers/admin_provider.dart';

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingGroupsAsync = ref.watch(pendingGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Management')),
      body: pendingGroupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load groups: $error'),
              TextButton(
                onPressed: () => ref
                    .read(pendingGroupsProvider.notifier)
                    .loadPendingGroups(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('No groups pending approval.'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Slug: ${group.slug}\nVisibility: ${group.visibility.name}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        tooltip: 'Approve',
                        onPressed: () async {
                          final success = await ref
                              .read(pendingGroupsProvider.notifier)
                              .approveGroup(group.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Group ${group.name} approved.'),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () async {
                          final success = await ref
                              .read(pendingGroupsProvider.notifier)
                              .rejectGroup(group.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Group ${group.name} rejected.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
