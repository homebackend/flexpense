import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/configuration_cubit.dart';
import 'cubit/mediawiki_cubit.dart';
import 'expense_editor.dart';
import 'income_editor.dart';
import 'mixin/fields.dart';
import 'settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flexpense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Homepage(),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with FormFields {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Flexpense',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(child: Container()),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Settings(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ),
      body: BlocProvider(
        create: (context) => ConfigurationCubit(),
        child: BlocBuilder<ConfigurationCubit, ConfigurationState>(
          builder: (context, configState) {
            if (configState.host.isEmpty ||
                configState.userName.isEmpty ||
                configState.password.isEmpty) {
              return const Center(
                child: Text(
                  'Please provide Mediawiki configuration',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              );
            }
            return BlocProvider(
              create: (context) => MediawikiCubit(
                configState.host,
                configState.port,
                configState.userName,
                configState.password,
              ),
              child: BlocBuilder<MediawikiCubit, MediawikiState>(
                builder: (context, state) {
                  if (state is MediaWikiError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Failed to connect to host: ${state.error}',
                          ),
                        ),
                        verticalSpacing(),
                        SizedBox(
                          width: 400,
                          child: _cancel(context),
                        ),
                      ],
                    );
                  } else if (state is MediawikiInitial) {
                    return _showInitial(context);
                  } else if (state is MediaWikiUpdate) {
                    if (state.isEdit) {
                      return LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          if (constraints.maxWidth > 600) {
                            return SizedBox(
                              child: Center(
                                child: SizedBox(
                                  width: 600,
                                  child: Center(
                                    child: _showEditor(context, state),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return _showEditor(context, state);
                          }
                        },
                      );
                    } else {
                      return _showViewer(context, state);
                    }
                  }

                  return Container();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _showInitial(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              onPressed: () async {
                var update = context.read<MediawikiCubit>().updateYearAndMonth;
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateUtils.dateOnly(DateTime.now()),
                  firstDate: DateUtils.dateOnly(
                    DateTime.now().subtract(const Duration(days: 365 * 2)),
                  ),
                  lastDate: DateUtils.dateOnly(DateTime.now()),
                );

                if (selectedDate == null) {
                  return;
                }

                update(selectedDate.year, selectedDate.month);
              },
              child: const Text('Select a date'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _showEditor(BuildContext context, MediaWikiUpdate state) {
    switch (state.editType) {
      case MediaWikiPageType.incomePage:
        return IncomeEditor(context, state);
      case MediaWikiPageType.expensePage:
        return ExpenseEditor(context, state);
    }
  }

  Widget _showViewer(BuildContext context, MediaWikiUpdate state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: state.saveEnabled
                      ? null
                      : () {
                          int previousMonth = state.month - 1;
                          int previousYear = state.year;
                          if (previousMonth < 1) {
                            previousMonth = 12;
                            previousYear--;
                          }
                          context
                              .read<MediawikiCubit>()
                              .updateYearAndMonth(previousYear, previousMonth);
                        },
                  icon: const Icon(Icons.skip_previous),
                ),
                horizontalSpacing(),
                Text(
                  'Showing data for ${state.month}/${state.year}',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                horizontalSpacing(),
                IconButton(
                  onPressed: state.saveEnabled
                      ? null
                      : () {
                          int nextMonth = state.month + 1;
                          int nextYear = state.year;
                          if (nextMonth > 12) {
                            nextMonth = 1;
                            nextYear++;
                          }
                          context
                              .read<MediawikiCubit>()
                              .updateYearAndMonth(nextYear, nextMonth);
                        },
                  icon: const Icon(Icons.skip_next),
                ),
                horizontalSpacing(),
                IconButton(
                  onPressed: state.saveEnabled
                      ? null
                      : () {
                          context.read<MediawikiCubit>().reset();
                        },
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                ),
                horizontalSpacing(),
                ElevatedButton(
                  onPressed: state.saveEnabled
                      ? () {
                          context.read<MediawikiCubit>().save();
                        }
                      : null,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.save,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text('Save'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _cancel(context),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _showIncomePage(context, state.incomePage),
          const SizedBox(height: 8),
          _showExpensePage(context, state.filterValue, state.expensePage),
        ],
      ),
    );
  }

  Widget _showPageData(
    BuildContext context,
    String title,
    List<String> columns,
    List<List<String>> rows,
    List<bool> rowModified,
    void Function() add,
    void Function(int) edit,
    void Function(int) remove, {
    int? filterColumn,
    List<String>? filterValues,
    String? filteredValue,
    List<TextAlign>? columnAlignments,
  }) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No Data Available',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18.0,
          ),
        ),
      );
    }

    int size = rows[0].length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20.0,
                ),
              ),
              filterValues == null
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 400,
                          child: dropDownMenu<String>(
                            'Filter',
                            filterValues,
                            filteredValue ?? 'All',
                            (v) => v,
                            (value) {
                              context
                                  .read<MediawikiCubit>()
                                  .updateFilterValue(value);
                            },
                          ),
                        ),
                      ],
                    ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => add(),
                icon: const Icon(
                  Icons.add_box,
                  color: Colors.green,
                  weight: 100.0,
                ),
              ),
            ],
          ),
        ),
        Table(
          border: TableBorder.all(),
          columnWidths: () {
            var columnWidths = <int, TableColumnWidth>{};
            for (int i = 0; i < size + 1; i++) {
              columnWidths[i] = const IntrinsicColumnWidth();
            }
            return columnWidths;
          }(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: () {
            List<TableRow> tableRows = [];
            tableRows.add(
              TableRow(
                children: () {
                  List<Widget> header = [];

                  header.addAll(columns
                      .map(
                        (name) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      )
                      .toList());

                  header.add(
                    const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_attributes),
                    ),
                  );

                  return header;
                }(),
              ),
            );

            tableRows.addAll(
              rows
                  .asMap()
                  .entries
                  .where((entry) => filterValues == null ||
                          filterColumn == null ||
                          filteredValue == null ||
                          filteredValue == 'All' ||
                          entry.value.contains(filteredValue)
                      ? true
                      : false)
                  .map(
                    (entry) => TableRow(
                      children: () {
                        bool modified = rowModified[entry.key];
                        List<Widget> widgets = [];
                        for (int i = 0; i < entry.value.length; i++) {
                          String r = entry.value[i];
                          widgets.add(
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Container(
                                  color: modified
                                      ? Theme.of(context).highlightColor
                                      : Theme.of(context).dialogBackgroundColor,
                                  child: Text(
                                    r,
                                    textAlign: columnAlignments == null
                                        ? TextAlign.left
                                        : columnAlignments[i],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        widgets.add(
                          TableCell(
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Colors.blue,
                                  onPressed: () {
                                    edit(entry.key);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () {
                                    remove(entry.key);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                        return widgets;
                      }(),
                    ),
                  )
                  .toList(),
            );

            return tableRows;
          }(),
        ),
      ],
    );
  }

  Widget _showIncomePage(BuildContext context, IncomePage incomePage) {
    return _showPageData(
      context,
      'Income page data',
      <String>[
        'Date',
        'Description',
        'Transaction',
      ],
      columnAlignments: [
        TextAlign.left,
        TextAlign.left,
        TextAlign.right,
      ],
      incomePage.rows
          .map((row) => <String>[
                row.date,
                row.description,
                row.transaction,
              ])
          .toList(),
      incomePage.rows.map((row) => row.modified).toList(),
      () => context.read<MediawikiCubit>().editIncomeRow(),
      (index) => context.read<MediawikiCubit>().editIncomeRow(index: index),
      (index) => context.read<MediawikiCubit>().removeIncomeRow(index),
    );
  }

  Widget _showExpensePage(
      BuildContext context, String? filterValue, ExpensePage expensePage) {
    return _showPageData(
        context,
        'Expense page data',
        <String>[
          'Section',
          'Date',
          'Description',
          'Transaction',
        ],
        columnAlignments: [
          TextAlign.left,
          TextAlign.left,
          TextAlign.left,
          TextAlign.right,
        ],
        expensePage.rows
            .map((row) => <String>[
                  row.section,
                  row.date,
                  row.expenseType == ExpenseType.none
                      ? row.description
                      : '${row.description} %${row.expenseType.value}% @${row.expenseText}@',
                  row.transaction,
                ])
            .toList(),
        expensePage.rows.map((row) => row.modified).toList(),
        () => context.read<MediawikiCubit>().editExpenseRow(),
        (index) => context.read<MediawikiCubit>().editExpenseRow(index: index),
        (index) => context.read<MediawikiCubit>().removeExpenseRow(index),
        filterColumn: 0, // section column number
        filteredValue: filterValue,
        filterValues: List<String>.from(expensePage.sectionData.keys)
          ..add('Expense')
          ..add('All'));
  }

  Widget _cancel(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read<MediawikiCubit>().reset();
      },
      child: const Row(
        children: [
          Icon(
            Icons.cancel,
            color: Colors.red,
          ),
          SizedBox(width: 8),
          Text('Cancel'),
        ],
      ),
    );
  }
}
