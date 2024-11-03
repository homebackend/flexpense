/*
 * Copyright (c) 2024 Neeraj Jakhar
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/configuration_cubit.dart';
import 'mixin/fields.dart';

class Settings extends StatefulWidget with FormFields {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _host = '';
  int _port = 80;
  String _userName = '';
  String _password = '';

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flexpense Settings'),
      ),
      body: BlocProvider(
        create: (context) => ConfigurationCubit(),
        child: BlocBuilder<ConfigurationCubit, ConfigurationState>(
          builder: (context, state) {
            _hostController.text = state.host;
            _portController.text = state.port.toString();
            _userNameController.text = state.userName;
            _passwordController.text = state.password;

            return Column(
              children: [
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.always,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        widget.textFormField(
                          '192.168.1.10',
                          'Host Name',
                          Icons.computer,
                          _hostController,
                          context.read<ConfigurationCubit>().updateHost,
                          (value) {
                            _host = value!;
                          },
                        ),
                        widget.verticalSpacing(),
                        widget.textFormField(
                          '80',
                          'Port',
                          Icons.power_input,
                          _portController,
                          formatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          (value) {
                            try {
                              context
                                  .read<ConfigurationCubit>()
                                  .updatePort(int.parse(value));
                            } catch (e) {
                              log('Error: $e');
                            }
                          },
                          (value) {
                            _port = int.parse(value!);
                          },
                        ),
                        widget.verticalSpacing(),
                        widget.textFormField(
                          'username',
                          'User name',
                          Icons.person,
                          _userNameController,
                          context.read<ConfigurationCubit>().updateUserName,
                          (value) {
                            _userName = value!;
                          },
                        ),
                        widget.verticalSpacing(),
                        widget.textFormField(
                          'password',
                          'Password',
                          Icons.lock,
                          _passwordController,
                          obscureText: true,
                          context.read<ConfigurationCubit>().updatePassword,
                          (value) {
                            _password = value!;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                widget.verticalSpacing(),
                widget.submitButton(
                  'Save configuration',
                  _formKey,
                  () {
                    context
                        .read<ConfigurationCubit>()
                        .save(_host, _port, _userName, _password);
                  },
                ),
                widget.verticalSpacing(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 8),
                      Text('Back'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
