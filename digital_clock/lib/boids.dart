//adapted from nature of code by Daniel Shiffman

import 'dart:math';
import 'dart:ui';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;

class Boids extends StatefulWidget {
  final int numberOfBoids;
  final Offset target;
  final String svgFile;
  final Color color;
  Boids(this.numberOfBoids, this.target, this.svgFile, {this.color});

  @override
  _BoidsState createState() => _BoidsState();
}

class _BoidsState extends State<Boids> {
  final Random random = Random();
  final List<Boid> boids = [];
  DrawableRoot _drawable;

  Future<DrawableRoot> loadSvgDrawableRoot(String file) async {
    final String rawSvg = await rootBundle.loadString(file);
    return svg.fromSvgString(rawSvg, rawSvg);
  }

  @override
  void initState() {
    loadSvgDrawableRoot(widget.svgFile).then((drawable) => setState(() {
          _drawable = drawable;
        }));
    List.generate(widget.numberOfBoids, (index) {
      boids.add(Boid(0, 0, random));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Rendering(
      startTime: Duration(seconds: 60),
      onTick: _simulateBoids,
      builder: (context, time) {
        return CustomPaint(
          painter: VehiclePainter(boids, time, _drawable, widget.color),
        );
      },
    );
  }

  _simulateBoids(Duration time) {
    Vector2 bounds = Vector2(material.MediaQuery.of(context).size.width,
        material.MediaQuery.of(context).size.height);
    boids.forEach((boid) {
      boid.run(boids, bounds);
    });
  }
}

class Boid {
  Vector2 position;
  Vector2 velocity;
  Vector2 acceleration;

  double r;
  double maxForce; //Maximum steering force
  double maxSpeed; //Maximum speed
  double d;

  double wanderTheta = 0;
  Random random;

  Boid(double x, double y, Random rand) {
    acceleration = Vector2(0, 0);
    velocity = Vector2(rand.nextDouble() * 2 - 1, -rand.nextDouble() * 2 - 1);
    position = Vector2(x, y);
    r = 10.0;
    maxSpeed = 1.0;
    maxForce = 0.005;
    d = -300;
    random = rand;
  }

  Vector2 limit(Vector2 v, double max) {
    if ((v.x * v.x) + (v.y * v.y) > (max * max)) {
      v.normalize();
      v.multiply(Vector2(max, max));
    }
    return v;
  }

  double angle(Vector2 v) {
    return atan2(v.y, v.x);
  }

  void run(List<Boid> boids, Vector2 bounds) {
    flock(boids);
    update();
    borders(bounds);
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
    } else if (position.x > bounds.x - d) {
      desired = new Vector2(-maxSpeed, velocity.y);
    }

    if (position.y < d) {
      desired = new Vector2(velocity.x, maxSpeed);
    } else if (position.y > bounds.y - d) {
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
    if (position.x < -r) position.x = bounds.x + r;
    if (position.y < -r) position.y = bounds.y + r;
    if (position.x > bounds.x + r) position.x = -r;
    if (position.y > bounds.y + r) position.y = -r;
  }

  void wander(Random random) {
    double wanderR = 25; // Radius for our "wander circle"
    double wanderD = 80; // Distance for our "wander circle"
    double change = 0.3;
    wanderTheta += (random.nextDouble() * change * 2) -
        change; // Randomly change wander theta
    // Now we have to calculate the new position to steer towards on the wander circle
    Vector2 circlePos = velocity; // Start with velocity
    circlePos.normalize(); // Normalize to get heading
    circlePos.multiply(Vector2(wanderD, wanderD)); // Multiply by distance
    circlePos.add(position); // Make it relative to boid's position

    double h =
        angle(velocity); // We need to know the heading to offset wandertheta

    Vector2 circleOffSet =
        Vector2(wanderR * cos(wanderTheta + h), wanderR * sin(wanderTheta + h));
    Vector2 target = circlePos + circleOffSet;
    seek(target);

    // Render wandering circle, etc.
    //if (debug) drawWanderStuff(position,circlePos,target,wanderR);
  }

  Vector2 seek(Vector2 target) {
    Vector2 desired = target;
    desired.sub(position);
    desired.normalize();
    desired.multiply(Vector2(maxSpeed, maxSpeed));

    Vector2 steer = desired - velocity;
    limit(steer, maxForce);
    return steer;
  }

  // We accumulate a new acceleration each time based on three rules
  void flock(List<Boid> boids) {
    Vector2 sep = separate(boids); // Separation
    Vector2 ali = align(boids); // Alignment
    Vector2 coh = cohesion(boids); // Cohesion
    // Arbitrarily weight these forces
    sep.multiply(Vector2(1.5, 1.5));
    ali.multiply(Vector2(1.0, 1.0));
    coh.multiply(Vector2(1.0, 1.0));
    // Add the force vectors to acceleration
    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }

  void applyForce(Vector2 force) {
    acceleration.add(force);
  }

  // Separation
  // Method checks for nearby boids and steers away
  Vector2 separate(List<Boid> boids) {
    double desiredSeparation = 25.0;
    Vector2 steer = Vector2(0, 0);
    double count = 0;
    // For every boid in the system, check if it's too close
    boids.forEach((other) {
      double d = position.distanceTo(other.position);
      // If the distance is greater than 0 and less than an arbitrary amount (0 when you are yourself)
      if ((d > 0) && (d < desiredSeparation)) {
        // Calculate vector pointing away from neighbor
        Vector2 diff = position - other.position;
        diff.normalize();
        diff /= d; // Weight by distance
        steer.add(diff);
        count++; // Keep track of how many
      }
    });
    // Average -- divide by how many
    if (count > 0) {
      steer /= count;
    }

    // As long as the vector is greater than 0
    if (steer.length > 0) {
      // Implement Reynolds: Steering = Desired - Velocity
      steer.normalize();
      steer *= maxSpeed;
      steer.sub(velocity);
      limit(steer, maxForce);
    }
    return steer;
  }

  // Alignment
  // For every nearby boid in the system, calculate the average velocity
  Vector2 align(List<Boid> boids) {
    double neighborDist = 50;
    Vector2 sum = Vector2(0, 0);
    double count = 0;
    boids.forEach((other) {
      double d = position.distanceTo(other.position);
      if ((d > 0) && (d < neighborDist)) {
        sum.add(other.velocity);
        count++;
      }
    });
    if (count > 0) {
      sum /= count;
      sum.normalize();
      sum *= maxSpeed;
      Vector2 steer = sum - velocity;
      limit(steer, maxForce);
      return steer;
    } else {
      return new Vector2(0, 0);
    }
  }

  // Cohesion
  // For the average position (i.e. center) of all nearby boids, calculate steering vector towards that position
  Vector2 cohesion(List<Boid> boids) {
    double neighborDist = 30;
    Vector2 sum = new Vector2(
        0, 0); // Start with empty vector to accumulate all positions
    double count = 0;
    boids.forEach((other) {
      double d = position.distanceTo(other.position);
      if ((d > 0) && (d < neighborDist)) {
        sum.add(other.position); // Add position
        count++;
      }
    });
    if (count > 0) {
      sum /= count;
      return seek(sum); // Steer towards the position
    } else {
      return new Vector2(0, 0);
    }
  }
}

class VehiclePainter extends CustomPainter {
  List<Boid> vehicles;
  Duration time;
  DrawableRoot svg;
  Color color;

  VehiclePainter(this.vehicles, this.time, this.svg, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (svg != null) {
      vehicles.forEach((vehicle) {
        double theta = atan2(vehicle.velocity.y, vehicle.velocity.x) + pi / 2;
        canvas.save();
        canvas.translate(vehicle.position.x, vehicle.position.y);
        canvas.rotate(theta);
        canvas.scale(5);
        svg.draw(canvas, ColorFilter.mode(color, material.BlendMode.src),
            Rect.fromLTWH(0, 0, size.width, size.height));
        canvas.restore();
      });
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
