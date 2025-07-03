import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AppFormatters {

  static final _celularMask = MaskTextInputFormatter(mask: '(##) #####-####');
  static final _fixoMask = MaskTextInputFormatter(mask: '(##) ####-####');

  static TextInputFormatter get dynamicPhoneMask {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

      if (digits.length > 11) {
        digits = digits.substring(0, 11);
      }

      final usedMask = digits.length > 10 ? _celularMask : _fixoMask;

      return usedMask.formatEditUpdate(
        oldValue,
        TextEditingValue(
          text: digits,
          selection: TextSelection.collapsed(offset: digits.length),
        ),
      );
    });
  }

  static final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

}
