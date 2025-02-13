import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    //return Placeholder();

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('My Profile'),
        ),
        body: Center(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(style: TextStyle(fontSize: 64), 'Jane Doe'),
                    Expanded(child: Placeholder()),
                    Text('Diskiles....'),
                    Text('chocolate'),
                    Text('ur mom'),
                    Text('Chevrolet')
                  ])),
        ));
  }
}
