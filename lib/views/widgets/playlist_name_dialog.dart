import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class PlaylistNameDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const PlaylistNameDialog({
    super.key,
    required this.title,
    this.initialValue = '',
  });

  @override
  State<PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<PlaylistNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bar,
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Nama playlist',
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accent),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text(
            'Simpan',
            style: TextStyle(color: AppColors.accent),
          ),
        ),
      ],
    );
  }
}
