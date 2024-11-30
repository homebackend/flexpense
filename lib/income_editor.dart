/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/editor_cubit.dart';
import 'cubit/mediawiki_cubit.dart';
import 'mixin/fields.dart';

class IncomeEditor extends StatefulWidget with FormFields {
  final BuildContext context;
  final MediaWikiUpdate state;
  const IncomeEditor(this.context, this.state, {super.key});

  @override
  State<IncomeEditor> createState() => _IncomeEditorState();
}

class _IncomeEditorState extends State<IncomeEditor> {
  final _formKey = GlobalKey<FormState>();

  String _date = '';
  String _description = '';
  String _transaction = '';

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  final TextEditingController _expenseTextController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _descriptionController.dispose();
    _transactionController.dispose();
    _expenseTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        if (widget.state.index != null && widget.state.index! >= 0) {
          int index = widget.state.index!;
          IncomeRow row = widget.state.incomePage.rows[index];
          return IncomeEditorCubit(row.date, row.description, row.transaction);
        } else {
          return IncomeEditorCubit('', '', '');
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.always,
              child: Column(
                children: [
                  _dateWidget(),
                  widget.verticalSpacing(),
                  _descriptionWidget(),
                  widget.verticalSpacing(),
                  _transactionWidget(),
                ],
              ),
            ),
            widget.verticalSpacing(),
            widget.submitButton(
              'Save Income Row',
              _formKey,
              () {
                final row = IncomeRow(
                  modified: true,
                  date: _date,
                  description: widget.normalizeString(_description),
                  transaction: widget.normalizeString(_transaction),
                );
                _date = '';
                _description = '';
                _transaction = '';
                if (widget.state.index == null || widget.state.index! < 0) {
                  context.read<MediawikiCubit>().addIncomeRow(row);
                } else {
                  context
                      .read<MediawikiCubit>()
                      .saveIncomeRow(widget.state.index!, row);
                }
              },
            ),
            widget.verticalSpacing(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<MediawikiCubit>().cancel();
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateWidget() {
    return BlocBuilder<IncomeEditorCubit, EditorState>(
      builder: (context, state) {
        _dateController.text = state.date;

        return widget.textFormField(
          '',
          'Date',
          Icons.date_range,
          _dateController,
          context.read<IncomeEditorCubit>().updateDate,
          (value) {
            _date = value!;
          },
        );
      },
    );
  }

  Widget _descriptionWidget() {
    return BlocBuilder<IncomeEditorCubit, EditorState>(
      builder: (context, state) {
        _descriptionController.text = state.description;

        return widget.textFormField(
          'Enter description',
          'Description',
          Icons.description,
          _descriptionController,
          context.read<IncomeEditorCubit>().updateDescription,
          (value) {
            _description = value!;
          },
        );
      },
    );
  }

  Widget _transactionWidget() {
    return BlocBuilder<IncomeEditorCubit, EditorState>(
      builder: (context, state) {
        _transactionController.text = state.transaction;

        return widget.textFormField(
          'Enter transaction',
          'Transaction',
          Icons.abc,
          _transactionController,
          context.read<IncomeEditorCubit>().updateTransaction,
          (value) {
            _transaction = value!;
          },
        );
      },
    );
  }
}
