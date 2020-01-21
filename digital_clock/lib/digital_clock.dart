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
import 'package:gradient_text/gradient_text.dart';
import 'package:tinycolor/tinycolor.dart';


class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  Color _particleColor = Colors.white;
  Color _weatherColor = Colors.white;
  Offset _tapPosition = Offset.zero;
  String _weatherParticleSvgFile;
  ParticleParameters _weatherParticleParameters;
  Particles _weatherParticles = Particles(50);

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
        _weatherParticleSvgFile = 'assets/raindrop.svg';
        loadSvgDrawableRoot(_weatherParticleSvgFile).then((drawable) => setState(() {
          _weatherColor = Colors.green;
          _particleColor = Colors.blue;
          _weatherParticleParameters = ParticleParameters(
              50,
              scale: 20,
              color: _particleColor.withOpacity(.5),
              svg: drawable
          );
          _weatherParticles.updateParameters(_weatherParticleParameters);
        }));
      }
      break;
      case WeatherCondition.foggy: {
        _weatherParticleSvgFile = 'assets/sun.svg';
        loadSvgDrawableRoot(_weatherParticleSvgFile).then((drawable) => setState(() {
          _weatherColor = Colors.deepPurple;
          _particleColor = Colors.grey[100];
          _weatherParticleParameters = ParticleParameters(
              10,
              scale: 50,
              color: _particleColor.withOpacity(.5),
              svg: drawable
          );
          _weatherParticles.updateParameters(_weatherParticleParameters);
        }));
      }
      break;
      case WeatherCondition.cloudy: {
        _weatherParticleSvgFile = 'assets/cloud3.svg';
        loadSvgDrawableRoot(_weatherParticleSvgFile).then((drawable) => setState(() {
          _weatherColor = Colors.blue;
          _particleColor = Colors.grey[100];
          _weatherParticleParameters = ParticleParameters(
              25,
              scale: 30,
              color: _particleColor.withOpacity(.5),
              svg: drawable
          );
          _weatherParticles.updateParameters(_weatherParticleParameters);
        }));
      }
      break;
      case WeatherCondition.thunderstorm: {
        _weatherParticleSvgFile = 'assets/cloud.svg';
        loadSvgDrawableRoot(_weatherParticleSvgFile).then((drawable) => setState(() {
          _weatherColor = Colors.red;
          _particleColor = Colors.grey;
          _weatherParticleParameters = ParticleParameters(
              20,
              scale: 30,
              color: _particleColor.withOpacity(.5),
              svg: drawable
          );
          _weatherParticles.updateParameters(_weatherParticleParameters);
        }));
      }
      break;
      case WeatherCondition.snowy: {
        _weatherParticleSvgFile = 'assets/snowflake.svg';
        loadSvgDrawableRoot(_weatherParticleSvgFile).then((drawable) => setState(() {
          _weatherColor = Colors.cyan;
          _particleColor = Colors.white;
          _weatherParticleParameters = ParticleParameters(
              10,
              scale: 30,
              color: _particleColor.withOpacity(.5),
              svg: drawable
          );
          _weatherParticles.updateParameters(_weatherParticleParameters);
        }));
      }
      break;
      case WeatherCondition.windy: {
        _weatherParticleSvgFile = 'assets/wind.svg';
        loadSvgDrawableRoot(_weatherParticleSvgFile).then((drawable) => setState(() {
          _weatherColor = Color(0xFF196E2B);
          _particleColor = Colors.white;
          _weatherParticleParameters = ParticleParameters(
              10,
              scale: 30,
              scaleRandomness: Offset(1,1),
              color: _particleColor.withOpacity(.5),
              svg: drawable,
          );
          _weatherParticles.updateParameters(_weatherParticleParameters);
        }));
      }
      break;
      default: {
        _weatherParticleSvgFile = 'assets/sun.svg';
        loadSvgDrawableRoot(_weatherParticleSvgFile).then((drawable) => setState(() {
          _weatherColor = Colors.blue;
          _particleColor = Colors.amber;
          _weatherParticleParameters = ParticleParameters(
              10,
              scale: 45,
              color: _particleColor.withOpacity(.5),
              svg: drawable
          );
          _weatherParticles.updateParameters(_weatherParticleParameters);
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

  Widget buildClock(BuildContext context)
  {
    bool darkMode = Theme.of(context).brightness != Brightness.light;
    Color backgroundColor = darkMode ? Colors.grey[850] : Colors.grey[300];
    Color accentColor = darkMode ? Colors.grey[500] : Colors.white;
    Color textColor = _weatherColor;

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
      fontWeight: FontWeight.bold
    );

    double hr = _dateTime.hour.toDouble();
    double min = _dateTime.minute.toDouble();
    double sec = _dateTime.second.toDouble();

    double hourAngle = scale(hr, 0, 12, 0, 2 * pi);
    double minuteAngle = scale(min, 0, 60, 0, 2 * pi);
    double secondAngle = scale(sec, 0, 60, 0, 2 * pi);

    List<BoxShadow> softBoxShadows = [
      BoxShadow(
        color: darkMode ? Colors.black54 : Colors.grey[500],
        offset: Offset(4.0, 4.0),
        blurRadius: 15.0,
        spreadRadius: 1.0
      ),
      BoxShadow(
        color: darkMode ? Colors.grey[800] : Colors.white,
        offset: Offset(-4.0, -4.0),
        blurRadius: 15.0,
        spreadRadius: 1.0
      ),
    ];

    List<Color> darkModeColors = [TinyColor(textColor).lighten(30).saturate(50).color, TinyColor(textColor).darken(10).saturate(50).color];
    List<Color> lightModeColors = [TinyColor(textColor).lighten(20).saturate(50).color, TinyColor(textColor).darken(20).saturate(50).color];
    List<Color> gradientColors = darkMode ? darkModeColors : lightModeColors;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: backgroundColor
          )
        ),
        Positioned.fill(
          child: _weatherParticles,
        ),
        Container(
          alignment: FractionalOffset(.25,.25),
          child: Container(
            width: screenHeight * .6,
            height: screenHeight * .6,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: textColor
              ),
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
                    hour,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'clock2',
                      fontSize: fontSize,
                      letterSpacing: 10,
                    ),
                    gradient:
                    LinearGradient(
                      begin: Alignment(cos(hourAngle - pi/2), sin(hourAngle - pi/2)),
                      end: Alignment(cos(hourAngle + pi/2), sin(hourAngle + pi/2)),
                      colors: gradientColors,
                    ),
                  )
                ),
              ]
            ),
          ),
        ),
        Container(
          alignment: FractionalOffset(.75,.25),
          child: Container(
            child: Container (
              width: screenWidth * .25,
              height: screenWidth  * .25,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: softBoxShadows,
                gradient:
                LinearGradient(
                  begin: Alignment(cos(minuteAngle - pi/2), sin(minuteAngle - pi/2)),
                  end: Alignment(cos(minuteAngle + pi/2), sin(minuteAngle + pi/2)),
                  colors: gradientColors,
                ),
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
                        boxShadow: softBoxShadows,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      minute,
                      style: TextStyle(
                        color: backgroundColor,
                        fontFamily: 'clock2',
                        fontSize: fontSize * .7,
                        letterSpacing: 10,
                      ),
                    )
                  ),
                ]
              ),
            )
          ),
        ),
        Container(
            alignment: FractionalOffset(.61,.78),
            child: Container(
              width: screenWidth * .2,
              height: screenHeight * .2,
              decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  boxShadow: softBoxShadows
              ),
              child: Center(
                  child: GradientText(
                    widget.model.temperatureString,
                    style: weatherTextStyle,
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                    ),
                  )
              ),
            )
        ),
        Container(
          alignment: FractionalOffset(0.5, 1),
          child: Container(
            height: screenHeight * .1,
            width: screenWidth *.75,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenHeight * 1),
                topRight: Radius.circular(screenHeight * 1)
              ),
              boxShadow: softBoxShadows
            ),
            child: Center(
              child: Text(
                widget.model.location,
                style: weatherTextStyle,
              )
            ),
          )
        ),
        Positioned.fill(
          child: Boids(40,_tapPosition, 'assets/bird2.svg', color: accentColor,)
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(child: buildClock(context));
  }
}