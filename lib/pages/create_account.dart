import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String username;

  submit() {
    final form = _formKey.currentState;

    if (form.validate()) {
      form.save();
      SnackBar snackbar = SnackBar(content: Text("Welcome $username!"));
      _scaffoldKey.currentState.showSnackBar(snackbar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, username);
        print('hi');
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context,
          isAppTitleEnabled: true,
          text: 'Set up your profile',
          backButtonRemove: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'Create a username',
              style: TextStyle(fontSize: 25.0, letterSpacing: 3.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
                key: _formKey,
                child: TextFormField(
                  validator: (val) {
                    if (val.trim().length < 3 || val.isEmpty) {
                      return "Username too short";
                    } else if (val.trim().length > 12) {
                      return "Username too long";
                    } else {
                      return null;
                    }
                  },
                  onSaved: (val) {
                    username = val;
                  },
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      labelText: 'Username',
                      labelStyle: TextStyle(fontSize: 15.0),
                      hintText: 'Must be at least 3 characters'),
                )),
          ),
          GestureDetector(
            onTap: submit,
            child: Container(
              width: 300.0,
              height: 50.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Colors.deepPurple,
              ),
              child: Center(
                child: Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
