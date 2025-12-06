import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jules_client/models/jules_models.dart';
import 'package:jules_client/screens/chat_screen.dart';
import 'package:jules_client/services/api_service.dart';
import 'package:jules_client/services/storage_service.dart';
import 'package:jules_client/screens/onboarding_screen.dart';
import 'package:jules_client/theme/app_theme.dart';
import 'package:jules_client/widgets/glass_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Providers
final sourcesProvider = FutureProvider<List<Source>>((ref) async {
  return ref.read(apiServiceProvider).listSources();
});

final sessionsProvider = FutureProvider<List<Session>>((ref) async {
  return ref.read(apiServiceProvider).listSessions();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(sourcesProvider);
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("DASHBOARD"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(sessionsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            onPressed: () async {
               final storage = ref.read(storageServiceProvider);
               await storage.clearAll();
               if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                   (route) => false,
                 );
               }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F1A), Colors.black],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(sessionsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 30),
            children: [
              _buildSectionHeader(context, "ACTIVE SOURCES"),
              sourcesAsync.when(
                data: (sources) => SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sources.length,
                    itemBuilder: (ctx, index) {
                      final source = sources[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        child: GlassContainer(
                          borderRadius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.code, color: AppTheme.accentColor, size: 32),
                              const Spacer(),
                              Text(
                                source.githubRepo?.repo ?? 'Unknown Repo',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                source.githubRepo?.owner ?? 'Unknown Owner',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (100 * index).ms).slideX();
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading sources: $err', style: const TextStyle(color: Colors.red)),
              ),

              const SizedBox(height: 30),
              
              _buildSectionHeader(context, "RECENT SESSIONS"),
              sessionsAsync.when(
                data: (sessions) => Column(
                  children: sessions.map((session) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(sessionId: session.name), // session.name is the full ID path usually
                            ),
                          );
                        },
                        child: GlassContainer(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      session.prompt,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1);
                  }).toList(),
                ),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (err, _) => Text('Error loading sessions: $err', style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            // Logic to show create session dialog would go here
            // For simplicity, we can just show a SnackBar or a simple dialog
            _showCreateSessionDialog(context, ref);
        },
        backgroundColor: AppTheme.primaryColor,
        label: const Text("NEW SESSION"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: AppTheme.accentColor,
        ),
      ),
    );
  }

  void _showCreateSessionDialog(BuildContext context, WidgetRef ref) {
    // Simplified dialog
    final promptController = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text("Start New Session"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: promptController,
              decoration: const InputDecoration(hintText: "What do you want to build?"),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            // In a real app, we'd select a source here
            const Text("Source: Default (First available)", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            child: const Text("START"),
            onPressed: () async {
              // Quick hack to get first source
              try {
                final sources = await ref.read(apiServiceProvider).listSources();
                if (sources.isNotEmpty) {
                    await ref.read(apiServiceProvider).createSession(
                        prompt: promptController.text, 
                        sourceName: sources.first.name
                    );
                    ref.refresh(sessionsProvider);
                    if(context.mounted) Navigator.pop(ctx);
                }
              } catch (e) {
                 // handle error
              }
            },
          ),
        ],
      )
    );
  }
}
