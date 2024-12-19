import 'package:flutter/material.dart' hide ConnectionState;
import 'package:reactive_notifier/reactive_notifier.dart';

import 'service/connection_service.dart';
import 'viewmodel/connection_state_viewmodel.dart';

class ConnectionStateWidget extends StatelessWidget {
  const ConnectionStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<ConnectionManager>(
      valueListenable: ConnectionService.instance,
      builder: ( service, keep) {

        final state = service.notifier;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: state.color.withValues(alpha: 255 * 0.2),
                  child: Icon(
                    state.icon,
                    color: state.color,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (state.isError || state == ConnectionState.disconnected)
                  keep(
                    ElevatedButton.icon(
                      onPressed: () => service.manualReconnect(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
                    ),
                  ),
                if (state.isSyncing) const LinearProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}
