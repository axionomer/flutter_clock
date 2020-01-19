// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:digital_clock/boids.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'particles.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gradient_text/gradient_text.dart';
import 'package:tinycolor/tinycolor.dart';

import 'particles.dart';

enum _Element {
  background,
  text,
  shadow,
}

final _lightTheme = {
  _Element.background: Colors.grey, //Colors.amber, //Color(0xFF007991),
  _Element.text: Colors.grey, //Color(0xFF007991),
  _Element.shadow: Color(0x99000000) //Color(0x99222E50),
};

final _darkTheme = {
  _Element.background: Color(0xFF222E50), //Colors.black,
  _Element.text: Color(0xFF222E50), //Colors.white,
  _Element.shadow: Colors.white //Color(0xFF222E50),
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  DrawableRoot _particleSvgDrawable;
  Color _particleColor = Colors.white;
  Color _backgroundColor = Colors.white;
  ParticleParameters _particleParameters = ParticleParameters(1);
  Particles _particles = Particles(ParticleParameters(10));
  Offset _tapPosition = Offset.zero;
  String _weatherSvgFile;

  Future<DrawableRoot> loadSvgDrawableRoot(String file) async{
    final String rawSvg = await rootBundle.loadString(file);
    return svg.fromSvgString(rawSvg, rawSvg);
  }

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateWeather()
  {
    switch(widget.model.weatherCondition){
      case WeatherCondition.rainy: {
        _weatherSvgFile = 'assets/raindrop.svg';
        loadSvgDrawableRoot(_weatherSvgFile).then((drawable) => setState(() {
          _backgroundColor = Colors.green;
          _particleColor = Colors.blue;
          _particleParameters = ParticleParameters(
              10,
              size: .4,
              duration: Duration(milliseconds: 5000),
              paint: Paint()..color=_particleColor.withOpacity(.5),
              svg: drawable
          );
        }));
      }
      break;
      case WeatherCondition.foggy: {
        _weatherSvgFile = 'assets/sun.svg';
        loadSvgDrawableRoot(_weatherSvgFile).then((drawable) => setState(() {
          _backgroundColor = Colors.deepPurple;
          _particleColor = Colors.grey[100];
          _particleParameters = ParticleParameters(
              10,
              size: .9,
              duration: Duration(milliseconds: 5000),
              paint: Paint()..color=_particleColor.withOpacity(.5),
              svg: drawable
          );
        }));
      }
      break;
      case WeatherCondition.cloudy: {
        _weatherSvgFile = 'assets/cloud.svg';
        loadSvgDrawableRoot(_weatherSvgFile).then((drawable) => setState(() {
          _backgroundColor = Colors.blue;
          _particleColor = Colors.grey[100];
          _particleParameters = ParticleParameters(
              10,
              size: .5,
              paint: Paint()..color=_particleColor.withOpacity(.5),
              svg: drawable
          );
        }));
      }
      break;
      case WeatherCondition.thunderstorm: {
        _weatherSvgFile = 'assets/cloud.svg';
        loadSvgDrawableRoot(_weatherSvgFile).then((drawable) => setState(() {
          _backgroundColor = Colors.red;
          _particleColor = Colors.grey;
          _particleParameters = ParticleParameters(
              10,
              size: .5,
              paint: Paint()..color=_particleColor.withOpacity(.5),
              svg: drawable
          );
        }));
      }
      break;
      default: {
        _weatherSvgFile = 'assets/sun.svg';
        loadSvgDrawableRoot(_weatherSvgFile).then((drawable) => setState(() {
          _backgroundColor = Colors.blue;
          _particleColor = Colors.amber;
          _particleParameters = ParticleParameters(
              10,
              size: 2.0,
              paint: Paint()..color=_particleColor.withOpacity(.5),
              svg: drawable
          );
        }));
      }
    }
  }

  void _updateModel() {
    _updateWeather();
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per minute. If you want to update every second, use the
      // following code.
//      _timer = Timer(
//        Duration(minutes: 1) -
//            Duration(seconds: _dateTime.second) -
//            Duration(milliseconds: _dateTime.millisecond),
//        _updateTime,
//      );
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
       _timer = Timer(
         Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
         _updateTime,
       );
    });
  }

  double scale(double x, double x0, double x1, double y0, double y1) {
    return (((x - x0) / (x1 - x0)) * (y1 - y0)) + y0;
  }

  double degrees2Radians(double degrees) {
    return degrees * (pi / 180.0);
  }

  double radians2Degrees(double radians) {
    return radians * (180 / pi);
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox referenceBox = context.findRenderObject();
    print("hello");
    setState(() {
      _tapPosition = referenceBox.globalToLocal(details.globalPosition);
    });
  }

  Widget buildClock(BuildContext context)
  {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _darkTheme;

    bool darkMode = Theme.of(context).brightness != Brightness.light;

    Color backgroundColor = darkMode ? Colors.grey[850] : Colors.grey[300]; //_backgroundColor;
    Color accentColor = Colors.white; //Colors.grey;
    Color accentColor2 = _particleColor; //Colors.grey[300];
    Color textColor = _backgroundColor; //darkMode ? Colors.grey[300] : Colors.grey[850];

    Orientation orientation = MediaQuery.of(context).orientation;
    double screenHeight = orientation == Orientation.portrait ? MediaQuery.of(context).size.width * 3/5 : MediaQuery.of(context).size.height;
    double screenWidth = orientation == Orientation.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height * 5/3;

    final hour = DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);

    final fontSize = screenHeight / 3.5;
    final weatherTextStyle = TextStyle(
      color: textColor,
      fontFamily: "roboto-mono",
      fontSize: fontSize * .25,
    );

    double hr = _dateTime.hour.toDouble();
    double min = _dateTime.minute.toDouble();
    double sec = _dateTime.second.toDouble();
    String hrStr = hour; //'09';
    String minStr = minute; //'36';

    double hourAngle = scale(hr, 0, 12, 0, 2 * pi);
    double minuteAngle = scale(min, 0, 60, 0, 2 * pi);
    double secondAngle = scale(sec, 0, 60, 0, 2 * pi);

    List<BoxShadow> softBoxShadows = [
      BoxShadow(
          color: darkMode ? Colors.black54 : Colors.grey[500],
          offset: Offset(4.0, 4.0),
          blurRadius: 15.0,
          spreadRadius: 1.0),
      BoxShadow(
          color: darkMode ? Colors.grey[800] : Colors.white,
          offset: Offset(-4.0, -4.0),
          blurRadius: 15.0,
          spreadRadius: 1.0),
    ];

    return Stack(
      children: [
        Positioned.fill(child: Container(color: backgroundColor)),
//        DemoBody(screenSize: Size(screenWidth, screenHeight)),
        Container(
          alignment: FractionalOffset(.25,.25), //Alignment(-.5, -.4),
          child: Container(
            width: screenHeight * .6,
            height: screenHeight * .6,
            decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                //borderRadius: BorderRadius.all(Radius.circular(50)),
                boxShadow: softBoxShadows
            ),
            child: Stack(
                children:[
                  Align(
                    alignment: Alignment(cos(hourAngle - pi/2), sin(hourAngle - pi/2)),
                    child: Container(
                      width: screenHeight * .05,
                      height: screenHeight * .05,
                      decoration: BoxDecoration(
                        color: _particleColor,
                        shape: BoxShape.circle,
                        boxShadow: softBoxShadows
                      ),
                    ),
                  ),
                  Center(
                    child: GradientText(
                      hrStr + '',
                      style: TextStyle(
                        color: textColor, //colors[_Element.text],
                        fontFamily: 'clock2',
                        fontSize: fontSize,
                        letterSpacing: 10,
                      ),
                      gradient:
                      LinearGradient(
                          begin: Alignment(cos(hourAngle - pi/2), sin(hourAngle - pi/2)),
                          end: Alignment(cos(hourAngle + pi/2), sin(hourAngle + pi/2)),
                          colors:[TinyColor(textColor).lighten(20).saturate(50).color, TinyColor(textColor).darken(20).saturate(50).color]
//                          colors:[Colors.white, Colors.black]
                      ),
                    )
                  ),
                ]
            ),
          ),
        ),
        Container(
          alignment: FractionalOffset(.75,.25), //Alignment(.5, -.5),
          child: Container(
            child: Container (
              width: screenWidth * .25,
              height: screenWidth  * .25,
              decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  //borderRadius: BorderRadius.all(Radius.circular(50)),
                  boxShadow: softBoxShadows
              ),
              child: Stack(
                children:[
                  Align(
                    alignment: Alignment(cos(minuteAngle - pi/2), sin(minuteAngle - pi/2)),
                    child: Container(
                      width: screenHeight * .03,
                      height: screenHeight * .03,
                      decoration: BoxDecoration(
                          color: _particleColor,
                          shape: BoxShape.circle,
                          boxShadow: softBoxShadows
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(cos(secondAngle - pi/2), sin(secondAngle - pi/2)),
                    child: Container(
                      width: screenHeight * .03,
                      height: screenHeight * .03,
                      decoration: BoxDecoration(
                          color: _particleColor,
                          shape: BoxShape.circle,
                          boxShadow: softBoxShadows
                      ),
                    ),
                  ),
                  Center(
                      child: GradientText(
                        minStr,
                        style: TextStyle(
                          color: textColor, //colors[_Element.text],
                          fontFamily: 'clock2',
                          fontSize: fontSize * .7,
                          letterSpacing: 10,
                        ),
                        gradient:
                        LinearGradient(
                          begin: Alignment(cos(minuteAngle - pi/2), sin(minuteAngle - pi/2)),
                          end: Alignment(cos(minuteAngle + pi/2), sin(minuteAngle + pi/2)),
                          colors:[TinyColor(textColor).lighten(20).saturate(50).color, TinyColor(textColor).darken(20).saturate(50).color]
                        ),
                      )
                  ),
                ]
              ),
            )
          ),
        ),
        Container(
            alignment: FractionalOffset(.61,.78), //Alignment(0.2, 0.7),
            child: Container(
              width: screenWidth * .2,
              height: screenHeight * .2,
              decoration: BoxDecoration(
                  color: backgroundColor,
                  //shape: BoxShape.circle,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  boxShadow: softBoxShadows
              ),
              child: Center(
                  child: GradientText(
                    widget.model.temperatureString,
                    style: weatherTextStyle,
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight, colors:[TinyColor(textColor).lighten(20).saturate(50).color, TinyColor(textColor).darken(20).saturate(50).color]
                    ),
                  )
              ),
              //child: Center(child: Text(widget.model.temperatureString, textAlign: TextAlign.center, style: weatherTextStyle))
            )
        ),
        Container(
            alignment: FractionalOffset(0.5, 1),
            child: Container(
              height: screenHeight * .1,
              width: screenWidth *.75,
              decoration: BoxDecoration(
                  color: backgroundColor,
                  //shape: BoxShape.circle,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenHeight * 1),
                      topRight: Radius.circular(screenHeight * 1)
                  ),
                  boxShadow: softBoxShadows
              ),
              child: Center(
                  child: GradientText(
                    widget.model.location,
                    style: weatherTextStyle,
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight, colors:[TinyColor(textColor).lighten(20).saturate(50).color, TinyColor(textColor).darken(20).saturate(50).color]
                    ),
                  )
              ),
              //child: Center(child: Text(widget.model.temperatureString, textAlign: TextAlign.center, style: weatherTextStyle))
            )
        ),
//        Container(
//            alignment: FractionalOffset(0, 0),
//            child: Container(
//              height: screenWidth *.15 /2,
//              width: screenWidth *.2,
//              decoration: BoxDecoration(
//                  color: backgroundColor,
//                  //shape: BoxShape.circle,
//                  borderRadius: BorderRadius.only(
//                      //topLeft: Radius.circular(screenHeight * 1),
//                      bottomRight: Radius.circular(screenWidth * .15 * .5)
//                  ),
//                  boxShadow: softBoxShadows
//              ),
//              child: Container(
//                  alignment: FractionalOffset(.2,.1),
//                  child: GradientText(
//                    'L: '+ widget.model.lowString + '\n' + 'H: '+ widget.model.highString,
//                    style: TextStyle(fontSize: 20),
//                    textAlign: TextAlign.left,
//                    gradient: LinearGradient(
//                        begin: Alignment.topLeft,
//                        end: Alignment.bottomRight, colors:[TinyColor(textColor).lighten(20).saturate(50).color, TinyColor(textColor).darken(20).saturate(50).color]
//                    ),
//                  )
//              ),
//              //child: Center(child: Text(widget.model.temperatureString, textAlign: TextAlign.center, style: weatherTextStyle))
//            )
//        ),
//        Container(
//            alignment: FractionalOffset(1, 0),
//            child: Container(
//              height: screenWidth *.15 /2,
//              width: screenWidth *.15,
//              decoration: BoxDecoration(
//                  color: backgroundColor,
//                  //shape: BoxShape.circle,
//                  borderRadius: BorderRadius.only(
//                    //topLeft: Radius.circular(screenHeight * 1),
//                      bottomLeft: Radius.circular(screenWidth * .15 * .5)
//                  ),
//                  boxShadow: softBoxShadows
//              ),
//              child: Container(
//                  alignment: FractionalOffset(.9,.4),
//                  child: GradientText(
//                    widget.model.weatherString,
//                    style: TextStyle(fontSize: 20),
//                    textAlign: TextAlign.right,
//                    gradient: LinearGradient(
//                        begin: Alignment.topLeft,
//                        end: Alignment.bottomRight, colors:[TinyColor(textColor).lighten(20).saturate(50).color, TinyColor(textColor).darken(20).saturate(50).color]
//                    ),
//                  )
//              ),
//              //child: Center(child: Text(widget.model.temperatureString, textAlign: TextAlign.center, style: weatherTextStyle))
//            )
//        ),
        Positioned.fill(
            child: Particles(_particleParameters)
        ),
        Positioned.fill(
            child: Vehicles(10,_tapPosition, 'assets/bird1.svg')
        ),
      ],
    );
  }

  Widget buildVehicleTest(BuildContext context)
  {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: Container(color: Colors.amber)),
//        Positioned.fill(
//            child: Particles(_particleParameters)
//        ),
        Positioned.fill(
          child: Vehicles(5,_tapPosition, 'assets/bird1.svg')
        ),
        Positioned.fill(
          child: GestureDetector(
            onTapDown: _handleTapDown,
          )
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(child: buildClock(context));
  }
}

//class GradientText extends StatelessWidget {
//  GradientText(
//      this.text, {
//        @required this.gradient, @required this.rect, this.style
//      });
//
//  final String text;
//  final Gradient gradient;
//  final TextStyle style;
//  final Rect rect;
//
//  @override
//  Widget build(BuildContext context) {
//    return ShaderMask(
//      shaderCallback: (bounds) => gradient.createShader(
////          Offset.zero & bounds.size
//        rect,
//      ),
//      child: Text(
//        text,
//        style: style
//      ),
//    );
//  }
//}

//Color lighten(Color color, [double amount = .1]) {
//  assert(amount >= 0 && amount <= 1);
//
//  final hsl = HSLColor.fromColor(color);
//  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
//
//  return hslLight.toColor();
//}
//
//Color darken(Color color, [double amount = .1]) {
//  assert(amount >= 0 && amount <= 1);
//
//  final hsl = HSLColor.fromColor(color);
//  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
//
//  return hslDark.toColor();
//}