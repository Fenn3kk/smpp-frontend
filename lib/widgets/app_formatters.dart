import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Uma classe para centralizar todos os formatadores de texto reutilizáveis do app.
class AppFormatters {

  static final _celularMask = MaskTextInputFormatter(mask: '(##) #####-####');
  static final _fixoMask = MaskTextInputFormatter(mask: '(##) ####-####');

  /// Um formatador dinâmico que aplica a máscara de celular ou fixo
  /// dependendo do comprimento do número.
  static TextInputFormatter get dynamicPhoneMask {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

      // Limita a 11 dígitos
      if (digits.length > 11) {
        digits = digits.substring(0, 11);
      }

      // Usa a máscara de celular se tiver 11 dígitos, senão a de fixo
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

  /// Máscara para CPF.
  static final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

}
