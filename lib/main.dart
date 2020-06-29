import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:noise_meter/noise_meter.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:location/location.dart';
import 'package:flutter_sparkline/flutter_sparkline.dart';
import 'package:mailer/mailer.dart' as ma;
import 'package:mailer/smtp_server.dart';
import 'submissions.dart';
GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
  ],
);
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Sign In',
      home: MyApp(),
    ),
  );
}
class MyApp extends StatefulWidget {
  @override
  State createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  GoogleSignInAccount _currentUser;
  bool _isRecording = false;
  StreamSubscription<NoiseReading> _noiseSubscription;
  NoiseMeter _noiseMeter = new NoiseMeter();
  String _noiseLevel;
  String ns;
  File _imageFile;
  String albumName ='noise_report';
  ScreenshotController screenshotController = ScreenshotController();
  int i=0;
  double val=0.0;
  var data = new List<double>.generate(100, (i) => 0.0);
  var location = new Location();
  Map<String, double> userLocation;
  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
      }
    });
    _googleSignIn.signInSilently();
    _getLocation().then((value) {
      setState(() {
        userLocation = value;
      });
    });
  }
  void onData(NoiseReading noiseReading) {
    this.setState(() {
      this._noiseLevel = "${noiseReading.meanDecibel} dB";
      ns='${noiseReading.meanDecibel}';
      val = double.tryParse(ns) ?? 20.0;
      for(int i=1;i<99;i++)
      {
        data[i]=data[i+1];
      }
      data[99]=val;
      print(data);
      if (!this._isRecording) {
        this._isRecording = true;
      }
    });
  }

  void startRecorder() async {
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
    } catch (exception) {
      print(exception);
    }
  }

  void stopRecorder() async {
    try {
      if (_noiseSubscription != null) {
        _noiseSubscription.cancel();
        _noiseSubscription = null;
      }
      this.setState(() {
        this._isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() async {
    _googleSignIn.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.purple[500],
          title: Text("Sound Pollution Reporter"),
        ),
        drawer: new Drawer(
            child: new ListView(
              children: <Widget>[
                new DrawerHeader(
                  child:
                  Align(
                    child: ListTile(
                      leading: GoogleUserCircleAvatar(
                        identity: _currentUser,
                      ),
                      title: Text(_currentUser.displayName ?? ''),
                      subtitle: Text(_currentUser.email ?? ''),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left:15.0),
                  child: new ListTile(
                    leading: Icon(Icons.library_books),
                    title: new Text('My submissions',style: new TextStyle(fontSize: 20.0,fontWeight: FontWeight.normal)),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Submissions(),
                          ));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left:15.0),
                  child: new ListTile(
                    leading: Icon(Icons.exit_to_app),
                    title: new Text('Sign Out',style: new TextStyle(fontSize: 20.0,fontWeight: FontWeight.normal)),
                    onTap: () {
                      _handleSignOut();
                    },
                  ),
                ),
              ],
            )),
        body: Screenshot(
          controller: screenshotController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text("Noise Level"),
                  Text(
                    _noiseLevel == null ? 'Press Record' : '$_noiseLevel',
                  ),
                ],
              ),
              userLocation == null
                  ? Text("Allow location permission for the app")
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.location_on,size: 19.0,),
                  Text(" Location:" +
                      userLocation["latitude"].toString() +
                      " , " +
                      userLocation["longitude"].toString(), style: TextStyle(fontSize: 19.0),),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Sparkline(
                  data: data,
                  lineColor: Color(0xffff6101),
                  lineWidth: 1.0,
                ),
              ),
              val>80.0?Text('Sound Level:High'):Text('Sound Level:Normal'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  FlatButton.icon(color: Colors.green,padding: EdgeInsets.all(10.0),onPressed: () {
                    if (!this._isRecording) {
                      return this.startRecorder();
                    }
                    this.stopRecorder();
                  }, icon: Icon(this._isRecording ? Icons.stop : Icons.mic, color: Colors.white,), label: this._isRecording ?Text("   Stop   ",style: TextStyle(color: Colors.white,fontSize: 20.0),):Text("  Record",style: TextStyle(color: Colors.white,fontSize: 20.0),)),
                  Divider(),
                  FlatButton(padding: EdgeInsets.all(10.0),onPressed: () {
                    _imageFile = null;
                    screenshotController
                        .capture()
                        .then((File image) async {
                      //print("Capture Done");
                      setState(() {
                        _imageFile = image;
                      });
                      final result =
                      await GallerySaver.saveImage(image.path, albumName: albumName); // Save image to gallery,  Needs plugin  https://pub.dev/packages/image_gallery_saver
                      print(result);
                    }).catchError((onError) {
                      print(onError);
                    });
                    Future.delayed(const Duration(seconds: 2), () {
                      sendmail();
                    });
                  }, child: Text("Send Report",style: TextStyle(color: Colors.white,fontSize: 20.0),),
                    color: Colors.red,)
                ],
              )
            ],
          ),
        ),
      );
    }
    else{
      return Scaffold(
        body: Container(
            color: Colors.purple[500],
            constraints: const BoxConstraints.expand(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text("Welcome,", style: TextStyle(color: Colors.white,fontSize: 35.0),),
                    Text("Please sign in to continue", style: TextStyle(color: Colors.white,fontSize: 20.0),),
                  ],
                ),
                FlatButton.icon(
                  color: Colors.white,
                  padding: EdgeInsets.all(20.0),
                  icon: Image.asset("assets/images/google.png",height: 15.0,),
                  label:Text('Sign in with Google',style: TextStyle(fontSize: 15.0)),
                  onPressed: _handleSignIn,
                ),
              ],
            )
        ),

      );

    }
  }
  sendmail() async{
    String username = 'sawantkartik999@gmail.com';
    String password = 'kartik123';

    final smtpServer = gmail(username, password);

    final message = new ma.Message()
      ..from = new ma.Address(username, 'Noise reporter')
      ..recipients.add('kartiksawant100@gmail.com')
      ..subject = 'High noise level '
      ..attachments.add(ma.FileAttachment(_imageFile))
      ..html = "Location:" +
          userLocation["latitude"].toString() +
          " , " +
          userLocation["longitude"].toString()+ " at time ${new DateTime.now()}<br> Reported by "
          + _currentUser.displayName + " | Email: "+ _currentUser.email ;

    ma.send(message, smtpServer);
  }
  Future<Map<String, double>> _getLocation() async {
    var currentLocation = <String, double>{};
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      currentLocation = null;
    }
    return currentLocation;
  }
}
