/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

part of 'configuration_cubit.dart';

@immutable
sealed class ConfigurationState {
  final String host;
  final int port;
  final String userName;
  final String password;

  const ConfigurationState({
    this.host = '',
    this.port = 80,
    this.userName = '',
    this.password = '',
  });

  ConfigurationState copyWith({
    String? host,
    int? port,
    String? userName,
    String? password,
  });
}

final class ConfigurationUpdatedState extends ConfigurationState {
  const ConfigurationUpdatedState({
    super.host,
    super.port,
    super.userName,
    super.password,
  });

  @override
  ConfigurationUpdatedState copyWith({
    String? host,
    int? port,
    String? userName,
    String? password,
  }) =>
      ConfigurationUpdatedState(
        host: host ?? this.host,
        port: port ?? this.port,
        userName: userName ?? this.userName,
        password: password ?? this.password,
      );
}
