import 'dart:math';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<DrawableRoot> loadSvgDrawableRoot(String file) async{
  final String rawSvg = await rootBundle.loadString(file);
  return svg.fromSvgString(rawSvg, rawSvg);
}

class Vehicles extends StatefulWidget {
  final int numberOfVehicles;
  final Offset target;
  final String svgFile;
  Vehicles(this.numberOfVehicles, this.target, this.svgFile);

  @override
  _VehiclesState createState() => _VehiclesState();
}

class _VehiclesState extends State<Vehicles> {
  final Random random = Random();
  final List<Vehicle> vehicles = [];
  DrawableRoot _drawable;

  @override
  void initState() {
    List.generate(widget.numberOfVehicles, (index) {
      vehicles.add(Vehicle(0,0,random));
    });
    loadSvgDrawableRoot(widget.svgFile).then((drawable) => setState(() {
      _drawable = drawable;
    }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Rendering(
      startTime: Duration(seconds: 30),
      onTick: _simulateVehicles,
      builder: (context, time) {
        return CustomPaint(
          painter: VehiclePainter(vehicles, time, _drawable),
        );
      },
    );
  }

  _simulateVehicles(Duration time) {
    Vector2 bounds = Vector2(material.MediaQuery.of(context).size.width, material.MediaQuery.of(context).size.height);
    vehicles.forEach((vehicle){
        //vehicle.seek(Vector2(widget.target.dx, widget.target.dy));
        vehicle.boundaries(bounds);
        //vehicle.wander(random);
        //vehicle.borders(bounds);
        vehicle.update();
      }
    );
  }
}

class Vehicle
{
  Vector2 position;
  Vector2 velocity;
  Vector2 acceleration;

  double r;
  double maxForce; //Maximum steering force
  double maxSpeed; //Maximum speed
  double d;

  double wanderTheta = 0;

  Random random;

  Vehicle(double x, double y, Random rand) {
    acceleration = Vector2(0,0);
    velocity = Vector2(rand.nextDouble() * 3 + 2, -rand.nextDouble() * 3 + 2);
    position = Vector2(rand.nextDouble() * 100, rand.nextDouble() * 100);
    r = 10.0;
    maxSpeed = 2;
    maxForce = 0.05;
    d = -300;
    random = rand;
  }

  Vector2 limit(Vector2 v, double max) {
    if((v.x*v.x)+(v.y*v.y) > (max*max)){
      v.normalize();
      v.multiply(Vector2(max,max));
    }
    return v;
  }

  double angle(Vector2 v) {
    return atan2(v.y, v.x);
  }

  void update() {
    velocity.add(acceleration);
    limit(velocity, maxSpeed);
    position.add(velocity);
    acceleration = Vector2.zero();
  }

  void boundaries(Vector2 bounds) {
    Vector2 desired;

    if (position.x < d) {
      desired = new Vector2(maxSpeed, velocity.y);
    }
    else if (position.x > bounds.x - d) {
      desired = new Vector2(-maxSpeed, velocity.y);
    }

    if (position.y < d) {
      desired = new Vector2(velocity.x, maxSpeed);
    }
    else if (position.y > bounds.y - d) {
      desired = new Vector2(velocity.x, -maxSpeed);
    }

    if (desired != null) {
      desired.normalize();
      desired.multiply(Vector2(maxSpeed, maxSpeed));
      Vector2 steer = desired;
      steer.sub(velocity);
      limit(steer, maxForce);
      applyForce(steer);
    }
  }

  void borders(Vector2 bounds) {
    if (position.x < -r) position.x = bounds.x+r;
    if (position.y < -r) position.y = bounds.y+r;
    if (position.x > bounds.x+r) position.x = -r;
    if (position.y > bounds.y+r) position.y = -r;
  }

  void wander(Random random) {
    double wanderR = 25;         // Radius for our "wander circle"
    double wanderD = 80;         // Distance for our "wander circle"
    double change = 0.3;
    wanderTheta += (random.nextDouble() * change * 2) - change;     // Randomly change wander theta
    // Now we have to calculate the new position to steer towards on the wander circle
    Vector2 circlePos = velocity;    // Start with velocity
    circlePos.normalize();            // Normalize to get heading
    circlePos.multiply(Vector2(wanderD,wanderD));          // Multiply by distance
    circlePos.add(position);               // Make it relative to boid's position

    double h = angle(velocity);        // We need to know the heading to offset wandertheta

    Vector2 circleOffSet = Vector2(wanderR*cos(wanderTheta+h),wanderR*sin(wanderTheta+h));
    Vector2 target = circlePos +circleOffSet;
    seek(target);

    // Render wandering circle, etc.
    //if (debug) drawWanderStuff(position,circlePos,target,wanderR);
  }

  void seek(Vector2 target)
  {
    Vector2 desired = target;
    desired.sub(position);
    desired.normalize();
    desired.multiply(Vector2(maxSpeed, maxSpeed));

    Vector2 steer = desired - velocity;
    limit(steer, maxForce);
    applyForce(steer);
  }

  void applyForce(Vector2 force)
  {
    acceleration.add(force);
  }
}

class VehiclePainter extends CustomPainter {
  List<Vehicle> vehicles;
  Duration time;
  DrawableRoot svg;

  VehiclePainter(this.vehicles, this.time, this.svg);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color=(material.Colors.black);
    //final DrawableRoot drawableSvg = parameters.svg;
    if(svg != null) {
      vehicles.forEach((vehicle) {
        double theta = atan2(vehicle.velocity.y, vehicle.velocity.x) + pi / 2;
        canvas.save();
        canvas.translate(vehicle.position.x, vehicle.position.y);
        canvas.rotate(theta);
        //      Path path = Path();
        //      path.lineTo(-vehicle.r, vehicle.r*5);
        //      path.lineTo(vehicle.r, vehicle.r*5);
        //      canvas.drawPath(path, paint);
        canvas.scale(20);
        svg.draw(canvas,
            ColorFilter.mode(material.Colors.black38, material.BlendMode.src),
            Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.restore();
      });
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
