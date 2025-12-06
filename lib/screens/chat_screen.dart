import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jules_client/models/jules_models.dart';
import 'package:jules_client/services/api_service.dart';
import 'package:jules_client/theme/app_theme.dart';
import 'package:jules_client/widgets/glass_container.dart';

final activitiesProvider = FutureProvider.family<List<Activity>, String>((ref, sessionId) async {
  return ref.read(apiServiceProvider).listActivities(sessionId);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    try {
      await ref.read(apiServiceProvider).sendMessage(widget.sessionId, text);
      ref.refresh(activitiesProvider(widget.sessionId));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("SESSION"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(activitiesProvider(widget.sessionId)),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: activities.length,
                  reverse: true, 
                  itemBuilder: (context, index) {
                    // Sort descending (Newest first) so index 0 is newest, which is at bottom of screen with reverse:true
                    final sortedActivities = List<Activity>.from(activities)
                      ..sort((a, b) => b.createTime.compareTo(a.createTime));
                      
                    final activity = sortedActivities[index];
                    
                    if (activity.originator == 'user') {
                         if (activity.planApproved != null) {
                             return _buildSystemMessage("Plan Approved by User");
                         }
                         // User text message logic would require inspecting artifacts or inferring from prompt if available
                         // Since the User sendMessage call is just a prompt, it might not be reflected as text in activity unless we have metadata.
                         // But if we have it:
                         // Currently the API returns 'progressUpdated' for agent.
                         // For user, it's often just the prompt creating the activity.
                         // We will display the activity name as fallback or "User Input"
                         return _buildMessageBubble("User Input: ${activity.prompt ?? 'Action'}", true);
                    } else {
                        // Agent
                        if (activity.progressUpdated != null) {
                            final title = activity.progressUpdated!.title;
                            final desc = activity.progressUpdated!.description;
                            return _buildMessageBubble("**$title**\n$desc", false);
                        } else if (activity.planGenerated != null) {
                            return _buildPlanWidget(activity.planGenerated!);
                        }
                    }
                    
                    return const SizedBox.shrink();
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: MarkdownBody(
          data: text, 
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
             p: const TextStyle(color: Colors.white),
             code: const TextStyle(backgroundColor: Colors.black26, fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlanWidget(PlanGenerated planGen) {
      return Align(
          alignment: Alignment.centerLeft,
          child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: MediaQuery.of(context).size.width * 0.85,
              child: GlassContainer(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const Text("GENERATED PLAN", style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          ...planGen.plan.steps.map((step) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text("${step.index + 1}.", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(step.title, style: const TextStyle(color: Colors.white))),
                                  ],
                              ),
                          )),
                          const SizedBox(height: 10),
                          NeonButton(text: "APPROVE PLAN", onPressed: () {
                              // Approval logic requires sessionId and planId
                              // Implementation for approval would go here
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan approval feature coming soon!")));
                          }, isLoading: false)
                      ],
                  ),
              ),
          ),
      );
  }

  Widget _buildInputArea() {
    return GlassContainer(
      borderRadius: 0,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Ask Jules...",
                  fillColor: Colors.transparent,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppTheme.accentColor),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for UI
extension ActivityUI on Activity {
    // Attempt to find a prompt if available in artifacts or name
    String? get prompt {
        // Since we don't have full prompt data in the Activity model yet (it's usually in 'Session'),
        // we might rely on naming convention or leave blank.
        // For now, return ID snippet
        return id.substring(0, 8);
    }
}
