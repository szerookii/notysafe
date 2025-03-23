import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppDialog extends StatelessWidget {
  final PackageInfo packageInfo;

  const AboutAppDialog({
    super.key,
    required this.packageInfo,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About NotySafe'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Version: ${packageInfo.version} (Build: ${packageInfo.buildNumber})',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text("Developed by "),
              InkWell(
                onTap: () {
                  launchUrl(
                    Uri.parse("https://github.com/szerookii"),
                  );
                },
                child: const Text(
                  "szerookii",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}