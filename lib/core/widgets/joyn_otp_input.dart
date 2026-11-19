import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/joyn_colors.dart';
import '../theme/joyn_typography.dart';

class JoynOtpInput extends StatefulWidget {
  final int length;
  final String? value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const JoynOtpInput({
    super.key,
    this.length = 4,
    this.value,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<JoynOtpInput> createState() => _JoynOtpInputState();
}

class _JoynOtpInputState extends State<JoynOtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _applyValue(widget.value);
  }

  @override
  void didUpdateWidget(covariant JoynOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != oldWidget.value) {
      _applyValue(widget.value);
    }
  }

  void _applyValue(String? val) {
    if (val == null) return;
    final digits = val.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < widget.length; i++) {
      if (i < digits.length) {
        _controllers[i].text = digits[i];
      } else {
        _controllers[i].clear();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  void _onFieldChanged(String value, int index) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final code = _otpCode;
      widget.onChanged?.call(code);
      if (code.length == widget.length) {
        widget.onCompleted?.call(code);
        FocusScope.of(context).unfocus();
      } else {
        _focusNodes[digits.length < widget.length ? digits.length : widget.length - 1]
            .requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final code = _otpCode;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 64,
          height: 64,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controllers[index].text.isEmpty &&
                  index > 0) {
                _focusNodes[index - 1].requestFocus();
                _controllers[index - 1].clear();
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: index == 0,
              style: JoynTypography.titleMedium.copyWith(
                fontSize: 20,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: JoynColors.border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: JoynColors.primary, width: 1.8),
                ),
                filled: true,
                fillColor: JoynColors.background,
              ),
              onChanged: (val) => _onFieldChanged(val, index),
            ),
          ),
        );
      }),
    );
  }
}
