import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reward_controller.dart';

class RewardAdPage extends ConsumerStatefulWidget {
  const RewardAdPage({super.key});

  @override
  ConsumerState<RewardAdPage> createState() => _RewardAdPageState();
}

class _RewardAdPageState extends ConsumerState<RewardAdPage> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider to trigger the automatic ad loading defined in RewardController.build()
    // We use a post-frame callback to safely read the provider during init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rewardControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rewardControllerProvider);

    // Listen for errors (like "Ad not ready") and show snackbar
    ref.listen(rewardControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Check if we moved from loading -> data (success)
      if (next.hasValue && !next.isLoading && (prev?.isLoading ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reward Earned! Credit added."),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Earn Credits")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill, size: 100, color: Colors.amber),
            const SizedBox(height: 30),
            Text(
              "Run out of credits?",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Watch a short video ad to instantly generate 1 more image.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: state.isLoading
                    ? null
                    : () => ref
                        .read(rewardControllerProvider.notifier)
                        .showAdToEarnCredit(),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.video_library),
                label: const Text("Watch Ad (+1 Credit)"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}