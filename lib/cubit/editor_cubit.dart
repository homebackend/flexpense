/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mediawiki_cubit.dart';

part 'editor_state.dart';

class BaseEditorCubit extends Cubit<EditorState> {
  BaseEditorCubit(super.initialState);

  void updateDate(String? value) {
    emit(state.copyWith(date: value));
  }

  void updateDescription(String? value) {
    emit(state.copyWith(description: value));
  }

  void updateTransaction(String? value) {
    emit(state.copyWith(transaction: value));
  }
}

class IncomeEditorCubit extends BaseEditorCubit {
  IncomeEditorCubit(
    String date,
    String description,
    String transaction,
  ) : super(
          IncomeEditorUpdatedState(
            date: date,
            description: description,
            transaction: transaction,
          ),
        );
}

class ExpenseEditorCubit extends BaseEditorCubit {
  ExpenseEditorCubit(
    String section,
    String date,
    String description,
    String transaction,
    ExpenseType expenseType,
    String expenseText,
  ) : super(ExpenseEditorUpdatedState(
          section: section,
          date: date,
          description: description,
          transaction: transaction,
          expenseType: expenseType,
          expenseText: expenseText,
        ));

  void updateSection(String? value) {
    if (state is ExpenseEditorUpdatedState) {
      var state = this.state as ExpenseEditorUpdatedState;
      emit(state.copyWith(section: value));
    }
  }

  void updateExpenseType(ExpenseType expenseType) {
    if (state is ExpenseEditorUpdatedState) {
      var state = this.state as ExpenseEditorUpdatedState;
      emit(state.copyWith(expenseType: expenseType));
    }
  }

  void updateExpenseText(String? value) {
    if (state is ExpenseEditorUpdatedState) {
      var state = this.state as ExpenseEditorUpdatedState;
      emit(state.copyWith(expenseText: value));
    }
  }
}
