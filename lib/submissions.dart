import 'package:flutter/material.dart';
import 'package:flutter_file_utils/utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:intl/intl.dart';

class Submissions extends StatefulWidget {
  @override
  _SubmissionsState createState() => _SubmissionsState();
}

class _SubmissionsState extends State<Submissions> {
  @override
  Widget build(BuildContext context) {
    SimplePermissions.requestPermission(Permission.ReadExternalStorage);
    return Scaffold(
      appBar: AppBar(title: Text("My submissions"),),
      body: FutureBuilder(
          future: buildImages(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                primary: false,
                itemCount: snapshot.data.length, // equals the recents files length
                itemBuilder: (context, index) {
                  var now = snapshot.data[index].statSync().modified;
                  var formatter = new DateFormat('dd-MM-yyyy  /  hh:mm a');
                  String dated = formatter.format(now);
                  return new Card(
                    child: new ListTile(
                        leading: Image.file(snapshot.data[index]),
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Report "+(index+1).toString()),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Date: ' + dated.toString(),style: TextStyle(fontSize: 13.0),),
                        ),
                        onTap: () {
                          File img=snapshot.data[index];
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DisplayPage(img),
                              ));
                        }
                    ),
                  );
                },
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Loading");
            }
            return Container();
          }),
    );
  }
  Future buildImages() async {
    List<File> files =
    await listFiles("/storage/emulated/0/noise_report", extensions: ["png", "jpg"]);
    return files;
  }
}
class DisplayPage extends StatefulWidget {
  final disimg;
  DisplayPage(this.disimg);
  @override
  _DisplayPageState createState() => _DisplayPageState(this.disimg);
}

class _DisplayPageState extends State<DisplayPage> {
  final disimg;
  _DisplayPageState(this.disimg);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(title:Text("Report")),
      body: Container(child: Image.file(disimg),),
    );
  }
}

