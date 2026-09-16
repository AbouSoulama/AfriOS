import 'package:flutter/material.dart';

import '../theme/afri_colors.dart';
import 'api_config.dart';

/// Shared dialog to configure / test the API base URL.
Future<bool> showApiUrlDialog(BuildContext context) async {
  final controller = TextEditingController(text: ApiConfig.baseUrl);
  String? testMessage;
  bool? testOk;
  var testing = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: const Text('URL du serveur API'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: ApiConfig.productionUrl,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Par défaut l\'app parle au serveur AfriOS en ligne. '
                    'Ne change cette URL que pour tester une API locale.',
                    style: TextStyle(fontSize: 12, color: AfriColors.slate),
                  ),
                  if (testMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      testMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: testOk == true
                            ? AfriColors.teal
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await ApiConfig.resetBaseUrl();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Par défaut'),
              ),
              TextButton(
                onPressed: testing
                    ? null
                    : () async {
                        setLocal(() {
                          testing = true;
                          testMessage = null;
                          testOk = null;
                        });
                        final err =
                            await ApiConfig.testConnection(controller.text);
                        setLocal(() {
                          testing = false;
                          testOk = err == null;
                          testMessage = err == null ? 'Connexion OK' : err;
                        });
                      },
                child: Text(testing ? 'Test…' : 'Tester'),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler')),
              TextButton(
                onPressed: () async {
                  await ApiConfig.setBaseUrl(controller.text);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
    },
  );

  return saved == true;
}
