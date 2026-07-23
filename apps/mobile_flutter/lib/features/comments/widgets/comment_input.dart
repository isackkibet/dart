import 'package:flutter/material.dart';

class CommentInput extends StatefulWidget {
  final String hint;
  final void Function(String text) onSend;
  final bool loading;

  const CommentInput({
    super.key,
    required this.hint,
    required this.onSend,
    required this.loading,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Colors.white54),
            ),
            onSubmitted: (_) => widget.loading ? null : _send(),
          ),
        ),
        IconButton(
          onPressed: widget.loading ? null : _send,
          icon: const Icon(Icons.send, color: Colors.white),
        ),
      ],
    );
  }
}
