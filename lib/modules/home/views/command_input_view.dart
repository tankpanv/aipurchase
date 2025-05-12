import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/command_executor.dart';
import 'command_list_view.dart';

class CommandInputView extends StatefulWidget {
  const CommandInputView({super.key});

  @override
  State<CommandInputView> createState() => _CommandInputViewState();
}

class _CommandInputViewState extends State<CommandInputView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final RxString _input = ''.obs;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      _input.value = _textController.text;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onExecute(String commandId) {
    final command = CommandExecutor.findCommandById(commandId);
    if (command != null) {
      Get.back();
      Get.toNamed(command.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '输入命令...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => CommandListView(
              input: _input.value,
              onExecute: _onExecute,
            )),
          ],
        ),
      ),
    );
  }
} 