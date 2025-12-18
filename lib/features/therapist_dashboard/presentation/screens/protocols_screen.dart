import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/presentation/providers/protocols_provider.dart';

class ProtocolsScreen extends ConsumerWidget {
  const ProtocolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocolsAsync = ref.watch(protocolsListProvider());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocols'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create protocol screen
            },
          ),
        ],
      ),
      body: protocolsAsync.when(
        data: (protocols) {
          if (protocols.isEmpty) {
            return const Center(
              child: Text('No protocols found. Create one to get started.'),
            );
          }
          return ListView.builder(
            itemCount: protocols.length,
            itemBuilder: (context, index) {
              final protocol = protocols[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(protocol.name),
                  subtitle: Text(
                    '${protocol.condition} • ${protocol.phase}',
                  ),
                  trailing: Chip(
                    label: Text(protocol.status.name),
                    backgroundColor: Colors.grey[200],
                  ),
                  onTap: () {
                    // TODO: Navigate to protocol details
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
