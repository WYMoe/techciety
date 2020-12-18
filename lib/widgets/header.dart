import 'package:flutter/material.dart';

AppBar header(context,{bool isAppTitleEnabled,String text,bool backButtonRemove = false}) {
  



  
  return AppBar(
    automaticallyImplyLeading: backButtonRemove ? false:true ,
    title: isAppTitleEnabled ?Text(text): Text('FlutterShare',
    style: TextStyle(
      fontFamily: "Signatra",
      fontSize: 50.0
    ),),

    centerTitle: true,
    backgroundColor: Theme.of(context).primaryColor,
  );
}
