import 'dart:math';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

Future<ui.Image> loadImage(String file) async{
  final ByteData data = await rootBundle.load(file);
//  return svg.fromSvgString(rawSvg, rawSvg);

  Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image image) {
    completer.complete(image);
  });
  return completer.future;
}

class Particles extends StatefulWidget {
  final int maxNumberOfParticles;
  final ParticleParameters parameters;
  Particles(this.maxNumberOfParticles, [this.parameters]);

  @override
  _ParticlesState createState() => _ParticlesState();
}

class _ParticlesState extends State<Particles> {
  final Random random = Random();

  final List<ParticleModel> particles = [];

  ui.Image _image;

  @override
  void initState() {
    List.generate(widget.maxNumberOfParticles, (index) {
      particles.add(ParticleModel(random, widget.parameters));
    });
    loadImage('assets/cloud2.png').then((image) => setState(() {
      _image = image;
    }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Rendering(
      startTime: Duration(seconds: 30),
      onTick: _simulateParticles,
      builder: (context, time) {
        return CustomPaint(
          painter: ParticlePainter(particles, time, widget.parameters, _image),
        );
      },
    );
  }

  _simulateParticles(Duration time) {
    for(int i = 0; i < particles.length && i < widget.parameters.count; ++i) {
      particles[i].maintainRestart(time);
    }
  }
}

class ParticleParameters
{
  int count = 0;
  double size = 1;
  //Offset startPosition; Offset(0.5, 0);
  //Offset endPosition = Offset(0.5, 1);
  //Curve xCurve = Curves.linear;
  //Curve yCurve = Curves.linear;
  Duration duration = Duration(seconds: 0);
  Paint paint;
  DrawableRoot svg;
  Color color = Colors.cyan;

  ParticleParameters(this.count, {double size, Duration duration, Paint paint, DrawableRoot svg}) :
    size = size,
    duration = duration,
    paint = paint,
    svg = svg;
}

class ParticleModel {
  Animatable tween;
  double scale;
  AnimationProgress animationProgress;
  Random random;

  ParticleParameters parameters;

  ParticleModel(this.random, this.parameters) {
    restart();
  }

  restart({Duration time = Duration.zero}) {
    bool flip = random.nextBool();

    double startX = -0.2 + 1.4 * random.nextDouble();
    double startY = 1.2 + random.nextDouble();
    double endX = -0.2 + 1.4 * random.nextDouble();
    double endY = -0.2 - random.nextDouble();
    final startPosition = flip ? Offset(startX, startY) : Offset(endX, endY);
    final endPosition = flip ? Offset(endX, endY) : Offset(startX, startY);

    Duration duration = Duration(milliseconds: 40000 + random.nextInt(10000));

    tween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: Curves.linear),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: Curves.linear),
    ]);
    animationProgress = AnimationProgress(duration: duration, startTime: time);
    scale =  random.nextDouble() + .5;
  }

  maintainRestart(Duration time) {
    if (animationProgress.progress(time) == 1.0) {
      restart(time: time);
    }
  }
}

class ParticlePainter extends CustomPainter {
  List<ParticleModel> particles;
  Duration time;
  ParticleParameters parameters;
  ui.Image image;
  ParticlePainter(this.particles, this.time, this.parameters, this.image);

  @override
  void paint(Canvas canvas, Size size) {
    if(parameters.svg != null) {
      for(int i = 0; i < particles.length && i < parameters.count; ++i) {
        particles[i].maintainRestart(time);
        var progress = particles[i].animationProgress.progress(time);
        final animation = particles[i].tween.transform(progress);
        final position = Offset(
            animation["x"] * size.width, animation["y"] * size.height);

        Paint paint1 = Paint();
        //paint1.maskFilter = MaskFilter.blur(BlurStyle.normal, 10);
        paint1.blendMode = BlendMode.colorBurn;
        //paint1.color = Colors.black26;

        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.scale(parameters.size * particles[i].scale);
        //canvas.drawImage(image, Offset.zero, paint1);
//        canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),  paint1);
        parameters.svg.draw(
            canvas, ColorFilter.mode(parameters.paint.color, BlendMode.src),
            Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}