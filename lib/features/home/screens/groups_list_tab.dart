import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/features/home/providers/chat_providers.dart';
import 'package:flutter_app/features/home/widgets/group_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

/// A widget that displays the list of all user groups.
///
/// It uses [ConsumerWidget] to listen to [myGroupsProvider] from Riverpod.
/// It also overrides the proxy providers (`apiServiceProvider` and
/// `socketServiceProvider`) to make the global services from Provider
// Provider
/// available to Riverpod.
class GroupsListTab extends ConsumerWidget {
  const GroupsListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bridge Provider services to Riverpod providers.
    final apiService = p.Provider.of<ApiService>(context, listen: false);
    final socketService = p.Provider.of<SocketService>(context, listen: false);

    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(apiService),
        socketServiceProvider.overrideWithValue(socketService),
      ],
      // We need a new Consumer to access the overridden providers
      child: Consumer(
        builder: (context, ref, child) {
          // Now we watch the provider that depends on the services
          final asyncGroupList = ref.watch(myGroupsProvider);

          // Handle the different states of the FutureProvider
          return asyncGroupList.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ChatHubTheme.primary),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error: ${err.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (groups) {
              if (groups.isEmpty) {
                return const Center(
                  child: Text(
                    'You are not in any groups.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              // Display the list of groups
              return RefreshIndicator(
                color: ChatHubTheme.primary,
                backgroundColor: ChatHubTheme.surface,
                onRefresh: () => ref.refresh(myGroupsProvider.future),
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return GroupListTile(group: group);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

