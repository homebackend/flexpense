/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

part of 'mediawiki_cubit.dart';

const _keyTemplate = 'Template';
final RegExp _sectionRegExp =
    RegExp('\\s*\\|\\s*${ExpenseRow.keySection}(\\d+)\\s*=\\s*(.*)\\s*');
final RegExp _dateRegExp =
    RegExp('\\s*\\|\\s*${IncomeRow.keyDate}(\\d+)\\s*=\\s*(.*)\\s*');
final RegExp _descriptionRegExp =
    RegExp('\\s*\\|\\s*${IncomeRow.keyDescription}(\\d+)\\s*=\\s*(.*)\\s*');
final RegExp _transactionRegExp =
    RegExp('\\s*\\|\\s*${IncomeRow.keyTransaction}(\\d+)\\s*=\\s*(.*)\\s*');
final RegExp _descriptionSubRegExp =
    RegExp('(.*)\\s*%\\s*(.*)\\s*%\\s*@\\s*(.*)\\s*@\\s*');

class IncomeRow {
  static const String keyDate = 'date';
  static const String keyDescription = 'desc';
  static const String keyTransaction = 'txn';

  final bool modified;
  final String date;
  final String description;
  final String transaction;

  IncomeRow({
    this.modified = false,
    this.date = '',
    this.description = '',
    this.transaction = '',
  });

  IncomeRow copyWith({
    bool? modified,
    String? date,
    String? description,
    String? transaction,
  }) =>
      IncomeRow(
        modified: modified ?? this.modified,
        date: date ?? this.date,
        description: description ?? this.description,
        transaction: transaction ?? this.transaction,
      );

  List<String> toList(int id) {
    return [
      '  |$keyDate$id=$date',
      '  |$keyDescription$id=$description',
      '  |$keyTransaction$id=$transaction',
    ];
  }
}

abstract class BasePage<T extends IncomeRow> {
  final List<T> rows;
  final String templateName;

  BasePage(this.rows, this.templateName);

  void addRow(T row) {
    rows.add(row);
    sortRows(rows);
  }

  void insertRow(int i, T row) {
    rows.insert(i, row);
    sortRows(rows);
  }

  void modifyRow(int i, T row) {
    rows.replaceRange(i, i + 1, [row]);
    sortRows(rows);
  }

  void removeRow(int i) {
    rows.remove(i);
  }

  static void sortRows<T extends IncomeRow>(List<T> rows) {
    rows.sort((a, b) {
      try {
        int d1 = int.parse(a.date);
        int d2 = int.parse(b.date);

        if (d1 != d2) {
          return d1 - d2;
        }
      } catch (e) {
        log('Error during int parsing: $e');
      }

      return a.description.compareTo(b.description);
    });
  }

  List<String> initialLines() {
    return [];
  }

  String toWikiText() {
    List<String> lines = initialLines();
    for (var e in rows.asMap().entries) {
      lines.addAll(e.value.toList(e.key + 1));
    }

    return '{{$_keyTemplate:$templateName\n' + lines.join('\n') + '\n}}';
  }

  T createEmptyRow();
  BasePage<T> createEmpty();

  void multiProcessLines(Map<int, T> idToRow, String line);

  bool processLine(
    Map<int, T> idToRow,
    RegExp regex,
    String line,
    T Function(T, String) handler,
  ) {
    var match = regex.firstMatch(line);
    if (match != null) {
      int id = int.parse(match[1] ?? '-1');
      if (id < 0) {
        return false;
      }
      String value = match[2] ?? '';
      if (!idToRow.containsKey(id)) {
        idToRow[id] = createEmptyRow();
      }

      idToRow[id] = handler(idToRow[id]!, value);
      return true;
    }

    return false;
  }

  BasePage<T> fromWikiTextInternal(String text) {
    Map<int, T> idToRow = {};

    int start = text.indexOf('{{$_keyTemplate:$templateName');
    if (start < 0) {
      return createEmpty();
    }
    int end = text.indexOf('}}', start);
    if (end < 0) {
      return createEmpty();
    }

    String templateText = text.substring(start, end);
    List<String> lines = templateText.split('\n');
    for (String line in lines) {
      if (!line.contains('=')) {
        continue;
      }

      multiProcessLines(idToRow, line);
    }

    List<T> rows = [];
    for (T r in idToRow.values) {
      rows.add(r);
    }

    sortRows(rows);

    this.rows.addAll(rows);
    return this;
  }
}

class IncomePage extends BasePage<IncomeRow> {
  static const String _templateName = 'IncomePage';

  IncomePage(List<IncomeRow> rows) : super(rows, _templateName);

  factory IncomePage.fromWikiText(String text) {
    IncomePage incomePage = IncomePage([]);
    incomePage.fromWikiTextInternal(text);
    return incomePage;
  }

  @override
  IncomePage createEmpty() {
    return IncomePage([]);
  }

  @override
  IncomeRow createEmptyRow() {
    return IncomeRow();
  }

  @override
  void multiProcessLines(Map<int, IncomeRow> idToRow, String line) {
    processLine(idToRow, _dateRegExp, line, (o, v) => o.copyWith(date: v));
    processLine(idToRow, _descriptionRegExp, line,
        (o, v) => o.copyWith(description: v));
    processLine(idToRow, _transactionRegExp, line,
        (o, v) => o.copyWith(transaction: v));
  }
}

enum ExpenseType {
  none('none'),
  cashback('cashback'),
  expense('expense'),
  invoicedExpense('invoiced-expense');

  static ExpenseType fromString(String value) {
    switch (value) {
      case 'cashback':
        return cashback;
      case 'invoiced-expense':
        return invoicedExpense;
      case 'expense':
      default:
        return expense;
    }
  }

  const ExpenseType(this.value);

  final String value;
}

class ExpenseRow extends IncomeRow {
  static const String keySection = 'section';

  final String section;
  final ExpenseType expenseType;
  final String expenseText;

  ExpenseRow({
    super.modified,
    this.section = '',
    super.date,
    super.description,
    super.transaction,
    this.expenseType = ExpenseType.none,
    this.expenseText = '',
  });

  @override
  ExpenseRow copyWith({
    bool? modified,
    String? section,
    String? date,
    String? description,
    String? transaction,
    ExpenseType? expenseType,
    String? expenseText,
  }) {
    return ExpenseRow(
      modified: modified ?? this.modified,
      section: section ?? this.section,
      date: date ?? this.date,
      description: description ?? this.description,
      transaction: transaction ?? this.transaction,
      expenseType: expenseType ?? this.expenseType,
      expenseText: expenseText ?? this.expenseText,
    );
  }

  @override
  List<String> toList(int id) {
    return [
      '  |$keySection$id=$section',
      '  |${IncomeRow.keyDate}$id=$date',
      '  |${IncomeRow.keyDescription}$id=$description' +
          (expenseType == ExpenseType.none
              ? ''
              : ' %${expenseType.value}% @$expenseText@'),
      '  |${IncomeRow.keyTransaction}$id=$transaction',
    ];
  }
}

class ExpensePage extends BasePage<ExpenseRow> {
  static const String _templateName = 'ExpensePage';

  final Map<String, String> sectionData;

  ExpensePage(this.sectionData, List<ExpenseRow> rows)
      : super(rows, _templateName);

  factory ExpensePage.fromWikiText(String text) {
    ExpensePage page = ExpensePage({}, []);
    page.fromWikiTextInternal(text);

    List<ExpenseRow> rows = page.rows.map((row) {
      var match = _descriptionSubRegExp.firstMatch(row.description);
      if (match == null) {
        return row;
      } else {
        return row.copyWith(
          description: match[1]!.trim(),
          expenseType: ExpenseType.fromString(match[2]!),
          expenseText: match[3]!.trim(),
        );
      }
    }).toList();
    page.rows.clear();
    page.rows.addAll(rows);

    return page;
  }

  @override
  ExpensePage createEmpty() {
    return ExpensePage({}, []);
  }

  @override
  ExpenseRow createEmptyRow() {
    return ExpenseRow();
  }

  @override
  void multiProcessLines(Map<int, ExpenseRow> idToRow, String line) {
    if (processLine(
        idToRow, _sectionRegExp, line, (o, v) => o.copyWith(section: v))) {
      return;
    }
    if (processLine(
        idToRow, _dateRegExp, line, (o, v) => o.copyWith(date: v))) {
      return;
    }
    if (processLine(idToRow, _descriptionRegExp, line,
        (o, v) => o.copyWith(description: v))) {
      return;
    }
    if (processLine(idToRow, _transactionRegExp, line,
        (o, v) => o.copyWith(transaction: v))) {
      return;
    }

    List<String> splits = line.split('=');
    if (splits.length < 2) {
      return;
    }

    String section = splits[0].replaceAll('|', '').trim();
    splits.removeAt(0);
    String value = splits.join(' ');
    sectionData[section] = value;
  }

  @override
  List<String> initialLines() {
    return sectionData.keys
        .map((key) => '  |$key=${sectionData[key]}')
        .toList();
  }
}

@immutable
sealed class MediawikiState {}

final class MediawikiInitial extends MediawikiState {}

final class MediaWikiError extends MediawikiState {
  final String error;

  MediaWikiError(this.error);
}

enum MediaWikiPageType {
  incomePage,
  expensePage,
}

final class MediaWikiUpdate extends MediawikiState {
  final int year;
  final int month;
  final bool saveEnabled;
  final IncomePage incomePage;
  final ExpensePage expensePage;
  final bool isEdit;
  final int? index;
  final MediaWikiPageType editType;
  final String? filterValue;

  MediaWikiUpdate(
    this.year,
    this.month,
    this.incomePage,
    this.expensePage, {
    this.saveEnabled = false,
    this.isEdit = false,
    this.index,
    this.editType = MediaWikiPageType.incomePage,
    this.filterValue,
  });

  MediaWikiUpdate copyWith({
    int? year,
    int? month,
    bool? saveEnabled,
    IncomePage? incomePage,
    ExpensePage? expensePage,
    bool? isEdit,
    int? index,
    MediaWikiPageType? editType,
    String? filterValue,
  }) =>
      MediaWikiUpdate(
        year ?? this.year,
        month ?? this.month,
        incomePage ?? this.incomePage,
        expensePage ?? this.expensePage,
        saveEnabled: saveEnabled ?? this.saveEnabled,
        isEdit: isEdit ?? this.isEdit,
        index: index ?? this.index,
        editType: editType ?? this.editType,
        filterValue: filterValue ?? this.filterValue,
      );
}
