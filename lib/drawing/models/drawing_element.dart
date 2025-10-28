import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Base class for all drawing elements rendered on the map.
abstract class DrawingElement {
  final String id;
  String layerId;
  ElementStyle style;

  DrawingElement({required this.id, required this.layerId, required this.style});
}

class ElementStyle {
  Color strokeColor;
  double strokeWidth;
  Color fillColor;
  double fillOpacity;
  bool dashed;

  ElementStyle({
    this.strokeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.fillColor = Colors.transparent,
    this.fillOpacity = 0.0,
    this.dashed = false,
  });
}

class TreeElement extends DrawingElement {
  LatLng center;
  String treeId;
  String species;
  double dbhCm;
  double canopyRadiusM;
  String condition;

  TreeElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.center,
    required this.treeId,
    this.species = '',
    this.dbhCm = 0.0,
    this.canopyRadiusM = 0.0,
    this.condition = 'Good',
  });
}

class LineElement extends DrawingElement {
  final LatLng a;
  final LatLng b;

  LineElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.a,
    required this.b,
  });
}

class PolylineElement extends DrawingElement {
  final List<LatLng> points;

  PolylineElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.points,
  });
}

class PolygonElement extends DrawingElement {
  final List<LatLng> points;

  PolygonElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.points,
  });
}

class CircleElement extends DrawingElement {
  final LatLng center;
  final double radiusMeters;

  CircleElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.center,
    required this.radiusMeters,
  });
}

class RectElement extends DrawingElement {
  final LatLng a;
  final LatLng b;

  RectElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.a,
    required this.b,
  });
}

class ArrowElement extends DrawingElement {
  final LatLng from;
  final LatLng to;

  ArrowElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.from,
    required this.to,
  });
}

class TextElement extends DrawingElement {
  final LatLng anchor;
  final String text;

  TextElement({
    required super.id,
    required super.layerId,
    required super.style,
    required this.anchor,
    required this.text,
  });
}



