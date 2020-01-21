import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

class Particles extends StatefulWidget {
  final int maxNumberOfParticles;
  final _ParticlesState ps = _ParticlesState();
  Particles(this.maxNumberOfParticles);

  void updateParameters(ParticleParameters parameters) {
    ps.updateParameters(parameters);
  }

  @override
  _ParticlesState createState() => ps;
}

class _ParticlesState extends State<Particles> {
  final Random random = Random();
  final List<ParticleModel> particles = [];
  ParticleParameters _parameters = ParticleParameters(0);

  void updateParameters(ParticleParameters parameters) {
    setState(() {
      _parameters = parameters;
    });
  }

  @override
  void initState() {
    List.generate(widget.maxNumberOfParticles, (index) {
      particles.add(ParticleModel(random, _parameters));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Rendering(
      startTime: Duration(seconds: 30),
      onTick: _simulateParticles,
      builder: (context, time) {
        return CustomPaint(
          painter: ParticlePainter(particles, time, _parameters),
        );
      },
    );
  }

  _simulateParticles(Duration time) {
    for (int i = 0; i < particles.length && i < _parameters.count; ++i) {
      particles[i].maintainRestart(time);
    }
  }
}

class ParticleParameters {
  int count;
  double scale;
  Offset scaleRandomness;
  Offset startPosition;
  Offset startPositionRandomness;
  Offset endPosition;
  Offset endPositionRandomness;
  bool directionRandomness;
  Curve xCurve;
  Curve yCurve;
  int durationMs;
  int durationRandomness;
  Color color;
  DrawableRoot svg;

  ParticleParameters(this.count,
      {this.scale = 15,
      this.scaleRandomness = const Offset(1, 1.5),
      this.startPosition = const Offset(-.2, 1.2),
      this.startPositionRandomness = const Offset(1.4, 1),
      this.endPosition = const Offset(-.2, -.2),
      this.endPositionRandomness = const Offset(1.4, -1),
      this.directionRandomness = true,
      this.xCurve = Curves.linear,
      this.yCurve = Curves.linear,
      this.durationMs = 40000,
      this.durationRandomness = 10000,
      this.color = Colors.black,
      this.svg});
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
    bool flip = parameters.directionRandomness ? random.nextBool() : false;
    double startX = parameters.startPosition.dx +
        parameters.startPositionRandomness.dx * random.nextDouble();
    double startY = parameters.startPosition.dy +
        parameters.startPositionRandomness.dy * random.nextDouble();
    double endX = parameters.endPosition.dx +
        parameters.endPositionRandomness.dx * random.nextDouble();
    double endY = parameters.endPosition.dy +
        parameters.endPositionRandomness.dy * random.nextDouble();
    final startPosition = flip ? Offset(startX, startY) : Offset(endX, endY);
    final endPosition = flip ? Offset(endX, endY) : Offset(startX, startY);

    Duration duration = Duration(
        milliseconds: parameters.durationMs +
            random.nextInt(parameters.durationRandomness));

    tween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: parameters.xCurve),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: parameters.yCurve),
    ]);
    animationProgress = AnimationProgress(duration: duration, startTime: time);
    scale = parameters.scale *
        (parameters.scaleRandomness.dx +
            parameters.scaleRandomness.dy * random.nextDouble());
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
  ParticlePainter(this.particles, this.time, this.parameters);

  @override
  void paint(Canvas canvas, Size size) {
    if (parameters.svg != null) {
      for (int i = 0; i < particles.length && i < parameters.count; ++i) {
        particles[i].maintainRestart(time);
        var progress = particles[i].animationProgress.progress(time);
        final animation = particles[i].tween.transform(progress);
        final position =
            Offset(animation["x"] * size.width, animation["y"] * size.height);
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.scale(particles[i].scale);
        parameters.svg.draw(
            canvas,
            ColorFilter.mode(parameters.color, BlendMode.src),
            Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
