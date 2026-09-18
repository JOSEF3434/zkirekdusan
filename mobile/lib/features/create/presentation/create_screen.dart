import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (_, ref, _) => Text(ref.watch(trProvider)('common.create')),
        ),
      ),
      body: const Center(
        child: Text('Create posts, videos, and live streams here.'),
      ),
    );
  }
}
