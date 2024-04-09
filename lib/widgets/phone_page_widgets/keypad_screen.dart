import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_call/widgets/keypad.dart';
import 'package:text_call/widgets/logout_menu_anchor.dart';
import 'package:text_call/widgets/message_writer.dart';

class KeypadScreen extends ConsumerStatefulWidget {
  const KeypadScreen({super.key});

  @override
  ConsumerState<KeypadScreen> createState() => _KeypadScreenState();
}

class _KeypadScreenState extends ConsumerState<KeypadScreen> {
  final _inputedDigitsTextController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _inputedDigitsTextController.dispose();
    super.dispose();
  }

  void _addDigit(String myText) {
    // _inputedDigitsTextController.value =
    //     _inputedDigitsTextController.value.copyWith(
    //   text: _inputedDigitsTextController.text + digit,
    //   selection: TextSelection.collapsed(
    //       offset: _inputedDigitsTextController.text.length + 1),
    // );

    // _inputedDigitsTextController.text += digit;
    // _inputedDigitsTextController.selection = TextSelection.collapsed(
    //     offset: _inputedDigitsTextController.text.length);
    // void _insertText(String myText) {
    final text = _inputedDigitsTextController.text;
    final textSelection = _inputedDigitsTextController.selection;
    final newText = text.replaceRange(
      textSelection.start,
      textSelection.end,
      myText,
    );
    final myTextLength = myText.length;
    _inputedDigitsTextController.text = newText;
    _inputedDigitsTextController.selection = textSelection.copyWith(
      baseOffset: textSelection.start + myTextLength,
      extentOffset: textSelection.start + myTextLength,
    );
  }

  void _backspace() {
    final text = _inputedDigitsTextController.text;
    final textSelection = _inputedDigitsTextController.selection;
    final selectionLength = textSelection.end - textSelection.start;

    // There is a selection.
    if (selectionLength > 0) {
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        '',
      );
      _inputedDigitsTextController.text = newText;
      _inputedDigitsTextController.selection = textSelection.copyWith(
        baseOffset: textSelection.start,
        extentOffset: textSelection.start,
      );
      return;
    }

    // The cursor is at the beginning.
    if (textSelection.start == 0) {
      return;
    }

    // Delete the previous character
    final newStart = textSelection.start - 1;
    final newEnd = textSelection.start;
    final newText = text.replaceRange(
      newStart,
      newEnd,
      '',
    );
    _inputedDigitsTextController.text = newText;
    _inputedDigitsTextController.selection = textSelection.copyWith(
      baseOffset: newStart,
      extentOffset: newStart,
    );
  }

  void _showModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => MessageWriter(
        calleePhoneNumber: '+234${_inputedDigitsTextController.text.substring(1)}',
      ),
    );
  }

  Future<bool> _checkIfNumberExists() async {
    final db = FirebaseFirestore.instance;
    final docRef = db
        .collection("users")
        .doc('+234${_inputedDigitsTextController.text.substring(1)}');
    final document = await docRef.get();

    if (document.exists == false) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => const AlertDialog.adaptive(
          backgroundColor: Color.fromARGB(255, 255, 166, 160),
          // i am pretty much using this row to center the text
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Number doesn\'t exist',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }

    return document.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            const LogOutMenuAnchor(),
          ],
        ),
        const Spacer(),
        TextField(
          onChanged: (value) {},
          autofocus: true,
          cursorColor: Colors.green,
          keyboardType: TextInputType.none,
          textAlign: TextAlign.center,
          controller: _inputedDigitsTextController,
          decoration: const InputDecoration(border: InputBorder.none),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        Keypad(
          onButtonPressed: _addDigit,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.video_camera_front),
            ),

            const SizedBox(
              width: 65,
            ),

            // call button
            IconButton(
              onPressed: () async {
                if (await _checkIfNumberExists()) {
                  _showModalBottomSheet();
                }
              },
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.message,
                  size: 35,
                ),
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(
              width: 65,
            ),

            // backspace button
            IconButton(
              onPressed: _backspace,
              icon: const Icon(Icons.backspace),
            )
          ],
        ),
        const SizedBox(
          height: 15,
        )
      ],
    );
  }
}
