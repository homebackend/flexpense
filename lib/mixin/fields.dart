/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

mixin FormFields {
  String normalizeString(String value) {
    final splits = value.split('|');
    String result = '';
    bool isLink = false;
    for (final s in splits) {
      if (isLink) {
        result += '|$s';
        if (s.contains(']]')) {
          isLink = false;
        }
      } else {
        result += ' $s';
        if (s.contains('[[')) {
          isLink = true;
        }
      }
    }
    return result;
  }

  Widget verticalSpacing() {
    return const SizedBox(height: 8.0);
  }

  Widget horizontalSpacing() {
    return const SizedBox(width: 8.0);
  }

  Widget textFormField(
    String hint,
    String label,
    IconData iconData,
    TextEditingController controller,
    void Function(String) changeHandler,
    void Function(String?) saveHandler, {
    bool obscureText = false,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: changeHandler,
      onSaved: saveHandler,
      inputFormatters: formatters,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        isDense: true,
        prefixIcon: Icon(iconData),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.elliptical(8, 8),
          ),
        ),
      ),
    );
  }

  Widget submitButton(
    String title,
    GlobalKey<FormState> formKey,
    void Function() save,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton(
        onPressed: () {
          formKey.currentState!.save();
          save();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save),
            horizontalSpacing(),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget dropDownMenu<T>(
    String title,
    List<T> values,
    T value,
    String Function(T) label,
    void Function(T?) changeHandler,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title:'),
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
            contentPadding: EdgeInsets.all(4.0),
          ),
          child: DropdownButton<T>(
            isExpanded: true,
            elevation: 16,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            value: value,
            items: values.map<DropdownMenuItem<T>>(
              (value) {
                return DropdownMenuItem<T>(
                  value: value,
                  child: Text(label(value)),
                );
              },
            ).toList(),
            onChanged: (value) => changeHandler(value),
          ),
        ),
      ],
    );
  }
}
