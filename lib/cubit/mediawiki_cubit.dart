/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'mediawiki_state.dart';

class MediawikiCubit extends Cubit<MediawikiState> {
  static const String apiPath = '/wiki/api.php';
  static const String _keyLastYear = 'lastYear';
  static const String _keyLastMonth = 'lastMonth';

  final String host;
  final int port;
  final String userName;
  final String password;
  String? _loginTokenValue;
  String? _csrfTokenValue;

  MediawikiCubit(this.host, this.port, this.userName, this.password)
      : super(MediawikiInitial()) {
    _load();
  }

  Future<void> _load() async {
    try {
      if (_loginTokenValue == null) {
        _loginTokenValue = await _loginToken();
        await _login(_loginTokenValue!);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int year = prefs.getInt(_keyLastYear) ?? -1;
        int month = prefs.getInt(_keyLastMonth) ?? -1;
        if (year > 0 && month > 0) {
          await updateYearAndMonth(year, month);
        }
      }
    } catch (e) {
      log('Error: $e');
      emit(MediaWikiError(e.toString()));
    }
  }

  Future<String> _loginToken() async {
    final params = {
      'action': 'query',
      'meta': 'tokens',
      'format': 'json',
      'type': 'login',
    };

    final uri = Uri.http('$host:$port', apiPath, params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['query']['tokens']['logintoken'];
    }

    throw HttpException('Error getting login token: ${response.statusCode}');
  }

  Future<void> _login(String loginToken) async {
    final params = {
      'action': 'login',
      'lgname': userName,
      'lgpassword': password,
      'lgtoken': loginToken,
      'format': 'json',
    };

    final uri = Uri.http('$host:$port', apiPath, params);
    final response = await http.post(uri, body: params);
    if (response.statusCode == 200) {
      return;
    }
    throw HttpException('Error during login: ${response.statusCode}');
  }

  Future<String> _csrfToken() async {
    final params = {
      'action': 'query',
      'format': 'json',
      'meta': 'tokens',
    };

    final uri = Uri.http('$host:$port', apiPath, params);
    final response = await http.post(uri, body: params);
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['query']['tokens']['csrftoken'];
    }

    throw HttpException('Error during login: ${response.statusCode}');
  }

  Future<String> _read(String title) async {
    final params = {
      'action': 'query',
      'format': 'json',
      'prop': 'revisions',
      'titles': title,
      'rvslots': '*',
      'rvprop': 'content',
      'formatversion': '2',
    };

    final uri = Uri.http('$host:$port', apiPath, params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['query']['pages'][0]['revisions'][0]['slots']['main']
          ['content'];
    }

    throw HttpException('Error during page get: ${response.statusCode}');
  }

  Future<void> _update(
    String csrfToken,
    String title,
    String content, {
    bool createOnly = true,
  }) async {
    final params = {
      'action': 'edit',
      'bot': 'true',
      'format': 'json',
      'title': title,
      'text': content,
      'token': csrfToken,
    };
    if (createOnly) {
      params['createonly'] = '$createOnly';
    }

    final uri = Uri.http('$host:$port', apiPath);
    final response = await http.post(uri, body: params);
    if (response.statusCode == 200) {
      log('Update response: ${response.body}');
      return;
    }

    throw HttpException('Error during page creation: ${response.statusCode}');
  }

  String _mText(int month) {
    return month < 10 ? '0$month' : '$month';
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
      default:
        return 'December';
    }
  }

  String _pageName(int year, int month) {
    String m = _mText(month);
    return 'Expenses-$year-$m';
  }

  Future<void> updateYearAndMonth(int year, int month) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastYear, year);
      await prefs.setInt(_keyLastMonth, month);

      final content = await _read(_pageName(year, month));

      emit(
        MediaWikiUpdate(
          year,
          month,
          IncomePage.fromWikiText(content),
          ExpensePage.fromWikiText(content),
        ),
      );
    } catch (e) {
      log('Error getting content: $e');
      emit(MediaWikiError(e.toString()));
    }
  }

  void editIncomeRow({int? index}) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      emit(state.copyWith(
        isEdit: true,
        index: index,
        editType: MediaWikiPageType.incomePage,
      ));
    }
  }

  void editExpenseRow({int? index}) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      emit(state.copyWith(
        isEdit: true,
        index: index,
        editType: MediaWikiPageType.expensePage,
      ));
    }
  }

  void removeIncomeRow(int index) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      state.incomePage.rows.removeAt(index);
      emit(state.copyWith());
    }
  }

  void removeExpenseRow(int index) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      state.expensePage.rows.removeAt(index);
      emit(state.copyWith());
    }
  }

  void cancel() {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      emit(state.copyWith(isEdit: false));
    }
  }

  void addIncomeRow(IncomeRow row) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      state.incomePage.addRow(row);
      emit(state.copyWith(isEdit: false, saveEnabled: true, index: -1));
    }
  }

  void saveIncomeRow(int index, IncomeRow row) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      state.incomePage.modifyRow(index, row);
      emit(state.copyWith(isEdit: false, saveEnabled: true, index: -1));
    }
  }

  void addExpenseRow(ExpenseRow row) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      state.expensePage.addRow(row);
      emit(state.copyWith(isEdit: false, saveEnabled: true, index: -1));
    }
  }

  void saveExpenseRow(int index, ExpenseRow row) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      state.expensePage.modifyRow(index, row);
      emit(state.copyWith(isEdit: false, saveEnabled: true, index: -1));
    }
  }

  void updateFilterValue(String? value) {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      emit(state.copyWith(filterValue: value));
    }
  }

  Future<void> reset() async {
    emit(MediawikiInitial());
  }

  void save() async {
    if (state is MediaWikiUpdate) {
      var state = this.state as MediaWikiUpdate;
      String incomeText = state.incomePage.toWikiText();
      String expenseText = state.expensePage.toWikiText();
      List<String> lines = [
        '{{Clickable button 2|Expenses-${state.year}-${_mText(state.month - 1)}| ${_monthName(state.month - 1)}|class=mw-ui-progressive}}',
        '{{Clickable button 2|Expenses-${state.year}-${_mText(state.month + 1)}| ${_monthName(state.month + 1)}|class=mw-ui-progressive}}',
        '',
        '=Income=',
        '',
        '==Currency==',
        '',
        incomeText,
        '',
        expenseText,
      ];
      String content = lines.join('\n');
      try {
        _csrfTokenValue = _csrfTokenValue ?? await _csrfToken();
        await _update(
          _csrfTokenValue!,
          _pageName(state.year, state.month),
          content,
          createOnly: false,
        );
        await updateYearAndMonth(state.year, state.month);
      } catch (e) {
        log('Error: $e');
        emit(MediaWikiError(e.toString()));
      }
    }
  }
}
