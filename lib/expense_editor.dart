/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

import 'package:flexpense/cubit/editor_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/mediawiki_cubit.dart';
import 'mixin/fields.dart';

class ExpenseEditor extends StatefulWidget with FormFields {
  final BuildContext context;
  final MediaWikiUpdate state;

  const ExpenseEditor(this.context, this.state, {super.key});

  @override
  State<ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<ExpenseEditor> {
  final _formKey = GlobalKey<FormState>();

  String _section = '';
  String _date = '';
  String _description = '';
  String _transaction = '';
  ExpenseType _expenseType = ExpenseType.none;
  String _expenseText = '';

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _transactionController = TextEditingController();
  final TextEditingController _expenseTextController = TextEditingController();

  @override
  void initState() {
    _section = widget.state.filterValue ?? '';
    super.initState();
  }

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
    return BlocProvider<ExpenseEditorCubit>(
      create: (context) {
        if (widget.state.index != null && widget.state.index! >= 0) {
          int index = widget.state.index!;
          ExpenseRow row = widget.state.expensePage.rows[index];
          return ExpenseEditorCubit(row.section, row.date, row.description,
              row.transaction, row.expenseType, row.expenseText);
        } else {
          return ExpenseEditorCubit('', '', '', '', ExpenseType.none, '');
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: BlocBuilder<ExpenseEditorCubit, EditorState>(
          builder: (context, state) {
            return Column(
              children: [
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: Column(
                    children: [
                      _sectionWidget(
                          context, state as ExpenseEditorUpdatedState),
                      widget.verticalSpacing(),
                      _dateWidget(context, state),
                      widget.verticalSpacing(),
                      _descriptionWidget(context, state),
                      widget.verticalSpacing(),
                      _transactionWidget(context, state),
                      widget.verticalSpacing(),
                      _expenseTypeWidget(context, state),
                      widget.verticalSpacing(),
                      _expenseTextWidget(context, state),
                    ],
                  ),
                ),
                widget.verticalSpacing(),
                widget.submitButton(
                  'Save Expense Row',
                  _formKey,
                  () {
                    final row = ExpenseRow(
                      modified: true,
                      section: _section,
                      date: _date,
                      description: widget.normalizeString(_description),
                      transaction: widget.normalizeString(_transaction),
                      expenseType: _expenseType,
                      expenseText: widget.normalizeString(_expenseText),
                    );
                    _section = '';
                    //_date = '';
                    _description = '';
                    _transaction = '';
                    _expenseType = ExpenseType.none;
                    _expenseText = '';
                    if (widget.state.index == null || widget.state.index! < 0) {
                      context.read<MediawikiCubit>().addExpenseRow(row);
                    } else {
                      context
                          .read<MediawikiCubit>()
                          .saveExpenseRow(widget.state.index!, row);
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
            );
          },
        ),
      ),
    );
  }

  Widget _sectionWidget(
    BuildContext context,
    ExpenseEditorUpdatedState stateExpense,
  ) {
    final values = List<String>.from(widget.state.expensePage.sectionData.keys);
    if (!values.contains('Expense')) {
      values.add('Expense');
    }

    if (_section.isEmpty || !values.contains(_section)) {
      if ((stateExpense.section.isEmpty && values.isNotEmpty) ||
          !values.contains(stateExpense.section)) {
        _section = values[0];
      } else {
        _section = stateExpense.section;
      }
    }

    return widget.dropDownMenu<String>(
      'Section Name',
      values,
      _section,
      (section) => section,
      (value) {
        _section = value!;
        context.read<ExpenseEditorCubit>().updateSection(value);
      },
    );
  }

  Widget _dateWidget(
    BuildContext context,
    ExpenseEditorUpdatedState stateExpense,
  ) {
    _dateController.text = stateExpense.date.isEmpty
        ? DateTime.now().day.toString()
        : stateExpense.date;

    return widget.textFormField(
      '',
      'Date',
      Icons.date_range,
      _dateController,
      context.read<ExpenseEditorCubit>().updateDate,
      (value) {
        _date = value!;
      },
    );
  }

  Widget _descriptionWidget(
    BuildContext context,
    ExpenseEditorUpdatedState stateExpense,
  ) {
    _descriptionController.text = stateExpense.description;

    return widget.textFormField(
      'Enter description',
      'Description',
      Icons.description,
      _descriptionController,
      context.read<ExpenseEditorCubit>().updateDescription,
      (value) {
        _description = value!;
      },
    );
  }

  Widget _transactionWidget(
    BuildContext context,
    ExpenseEditorUpdatedState stateExpense,
  ) {
    _transactionController.text = stateExpense.transaction;

    return widget.textFormField(
      'Enter transaction',
      'Transaction',
      Icons.abc,
      _transactionController,
      context.read<ExpenseEditorCubit>().updateTransaction,
      (value) {
        _transaction = value!;
      },
    );
  }

  Widget _expenseTypeWidget(
    BuildContext context,
    ExpenseEditorUpdatedState stateExpense,
  ) {
    _expenseType = stateExpense.expenseType;

    return widget.dropDownMenu(
      'Expense Type',
      ExpenseType.values,
      stateExpense.expenseType,
      (expenseType) => expenseType.value,
      (value) {
        _expenseType = value!;
        context.read<ExpenseEditorCubit>().updateExpenseType(value!);
      },
    );
  }

  Widget _expenseTextWidget(
    BuildContext context,
    ExpenseEditorUpdatedState stateExpense,
  ) {
    if (stateExpense.expenseType == ExpenseType.none) {
      return const SizedBox.shrink();
    }

    _expenseTextController.text = stateExpense.expenseText;

    return widget.textFormField(
      'description',
      'Expense Text',
      Icons.abc,
      _expenseTextController,
      context.read<ExpenseEditorCubit>().updateExpenseText,
      (value) {
        _expenseText = value!;
      },
    );
  }
}
