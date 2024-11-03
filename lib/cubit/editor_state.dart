/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

part of 'editor_cubit.dart';

@immutable
sealed class EditorState {
  final String date;
  final String description;
  final String transaction;

  const EditorState({
    this.date = '',
    this.description = '',
    this.transaction = '',
  });

  EditorState copyWith({
    String? date,
    String? description,
    String? transaction,
  });
}

final class IncomeEditorUpdatedState extends EditorState {
  const IncomeEditorUpdatedState({
    super.date,
    super.description,
    super.transaction,
  });

  @override
  EditorState copyWith({
    String? date,
    String? description,
    String? transaction,
  }) {
    return IncomeEditorUpdatedState(
      date: date ?? this.date,
      description: description ?? this.description,
      transaction: transaction ?? this.transaction,
    );
  }
}

final class ExpenseEditorUpdatedState extends EditorState {
  final String section;
  final ExpenseType expenseType;
  final String expenseText;

  const ExpenseEditorUpdatedState({
    this.section = '',
    super.date,
    super.description,
    super.transaction,
    this.expenseType = ExpenseType.none,
    this.expenseText = '',
  });

  @override
  ExpenseEditorUpdatedState copyWith({
    String? section,
    String? date,
    String? description,
    String? transaction,
    ExpenseType? expenseType,
    String? expenseText,
  }) {
    return ExpenseEditorUpdatedState(
      section: section ?? this.section,
      date: date ?? this.date,
      description: description ?? this.description,
      transaction: transaction ?? this.transaction,
      expenseType: expenseType ?? this.expenseType,
      expenseText: expenseText ?? this.expenseText,
    );
  }
}
