import 'package:flutter/material.dart';

/// A text widget that automatically handles overflow
class SafeText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;

  const SafeText(
    this.data, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines = 3,
    this.softWrap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: softWrap,
    );
  }
}

/// A flexible text widget that automatically handles overflow in rows/columns
class FlexibleText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final int flex;

  const FlexibleText(
    this.data, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines = 2,
    this.flex = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex,
      child: Text(
        data,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
