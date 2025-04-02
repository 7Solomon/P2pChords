import 'package:P2pChords/styling/Button.dart';
import 'package:P2pChords/mainPage/page.dart';
import 'package:P2pChords/networking/Pages/client/clientPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:P2pChords/state.dart';

import 'server/serverPage.dart';

class ChooseSCStatePage extends StatelessWidget {
  const ChooseSCStatePage({super.key});

  void _setUserStateAndNavigate(BuildContext context, UserState state) {
    final songSyncProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    songSyncProvider.setUserState(state);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (state == UserState.server) {
            return const ServerPage(); // Navigate to ServerPage
          }
          if (state == UserState.client) {
            return const ClientPage(); // Navigate to ClientPage
          } else {
            return const MainPage();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerätetyp wählen'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.15),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.device_hub,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Wähle deine Rolle',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wähle, ob du Songs teilen oder empfangen möchtest',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Server Role Card
                  _buildRoleCard(
                    context,
                    title: 'Server',
                    description: 'Teile Songs mit anderen Geräten',
                    icon: Icons.upload,
                    color: theme.colorScheme.primary,
                    onTap: () =>
                        _setUserStateAndNavigate(context, UserState.server),
                  ),

                  const SizedBox(height: 24),

                  // Client Role Card
                  _buildRoleCard(
                    context,
                    title: 'Client',
                    description: 'Empfange Songs von einem Server',
                    icon: Icons.download,
                    color: theme.colorScheme.secondary,
                    onTap: () =>
                        _setUserStateAndNavigate(context, UserState.client),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
