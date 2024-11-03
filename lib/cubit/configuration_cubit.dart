/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'configuration_state.dart';

class ConfigurationCubit extends Cubit<ConfigurationState> {
  static const String _keyHost = 'host';
  static const String _keyPort = 'port';
  static const String _keyUserName = 'userName';
  static const String _keyPassword = 'pasword';

  ConfigurationCubit() : super(const ConfigurationUpdatedState()) {
    _load();
  }

  Future<void> _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    emit(state.copyWith(
      host: prefs.getString(_keyHost),
      port: prefs.getInt(_keyPort),
      userName: prefs.getString(_keyUserName),
      password: prefs.getString(_keyPassword),
    ));
  }

  void updateHost(String value) {
    emit(state.copyWith(host: value));
  }

  void updatePort(int value) {
    emit(state.copyWith(port: value));
  }

  void updateUserName(String value) {
    emit(state.copyWith(userName: value));
  }

  void updatePassword(String value) {
    emit(state.copyWith(password: value));
  }

  void save(String host, int port, String userName, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHost, host);
    await prefs.setInt(_keyPort, port);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyPassword, password);
  }
}
