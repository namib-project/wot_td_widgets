// Copyright 2022 The NAMIB Project Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:dart_wot/dart_wot.dart' hide Form;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntegerPropertyWidget extends StatefulWidget {
  /// The key of the property. Used to access it in the [consumedThing].
  final String propertyKey;

  /// The [ConsumedThing] associated with this property.
  final ConsumedThing consumedThing;

  const IntegerPropertyWidget(this.propertyKey, this.consumedThing,
      {super.key});

  @override
  State<StatefulWidget> createState() => IntegerPropertyState();
}

class IntegerPropertyState extends State<IntegerPropertyWidget> {
  double currentValue = 0;
  double oldValue = 0;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> updateThingProperty(double? newValue) async {
    if (newValue == null) {
      return;
    }

    await widget.consumedThing.writeProperty(widget.propertyKey, newValue);
    try {
      final output =
          await widget.consumedThing.readProperty(widget.propertyKey);
      Object? value = await output.value();
      if (value is int) {
        value = value.toDouble();
      }
      if (value is double) {
        setState(() {
          currentValue = value as double;
          oldValue = currentValue;
        });
      }
    } on Exception {
      setState(() {
        currentValue = oldValue;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final property =
        widget.consumedThing.thingDescription.properties[widget.propertyKey];
    final description = property?.description;
    final minimum = property?.minimum;
    final maximum = property?.maximum;

    final widgets = <Widget>[];
    Widget? subtitle;
    if (description != null) {
      subtitle = Text(description);
    }

    final header = ListTile(
      title: Text(property?.title ?? widget.propertyKey),
      subtitle: subtitle,
    );

    widgets.add(header);

    if (minimum != null && maximum != null) {
      int? devisions;

      if (property?.type == "integer") {
        devisions = (maximum - minimum).toInt();
      }
      widgets.add(Slider(
        value: currentValue,
        min: minimum.toDouble(),
        max: maximum.toDouble(),
        divisions: devisions,
        label: currentValue.round().toString(),
        onChangeEnd: (value) => updateThingProperty(value),
        onChanged: (double value) {
          setState(() {
            currentValue = value;
          });
        },
      ));
    } else {
      final formField = TextFormField(
        initialValue: currentValue.toString(),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.right,
        onSaved: ((newValue) =>
            updateThingProperty(double.tryParse(newValue ?? ""))),
        onFieldSubmitted: ((value) {
          updateThingProperty(double.tryParse(value));
        }),
      );
      final button = Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState?.save();
                }
              },
              child: const Text('Submit')));

      final form = Form(
          key: _formKey,
          child: Column(
            children: [
              formField,
              button,
            ],
          ));

      widgets.add(form);
    }

    return Column(
      children: widgets,
    );
  }
}

/// A [StatefulWidget] that can be used to read, write, and observe properties
/// offered by a Thing.
class PropertyWidget extends StatefulWidget {
  /// The key of the property. Used to access it in the [consumedThing].
  final String propertyKey;

  /// The [ConsumedThing] associated with this property.
  final ConsumedThing consumedThing;

  /// Creates a new [PropertyWidget] for interacting with a property of a
  /// [ConsumedThing]. That property is specified by its [propertyKey].
  const PropertyWidget(this.propertyKey, this.consumedThing, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => PropertyState();
}

/// Represents the state of a property.
class PropertyState extends State<PropertyWidget> {
  /// The currently value of the propety.
  Object? _propertyValue;
  bool _updating = false;

  String get _propertyTitle {
    final title = widget
        .consumedThing.thingDescription.actions[widget.propertyKey]?.title;

    return title ?? widget.propertyKey;
  }

  String? get _propertyDescription {
    return widget.consumedThing.thingDescription.properties[widget.propertyKey]
        ?.description;
  }

  @override
  Widget build(BuildContext context) {
    final Widget button;

    if (_updating) {
      button = const CircularProgressIndicator();
    } else {
      button = IconButton(
          onPressed: _readProperty,
          icon: const Icon(
            Icons.refresh,
            size: 30,
          ));
    }

    Widget? description;
    if (_propertyDescription != null) {
      description = Text(
        _propertyDescription!,
        style: Theme.of(context).textTheme.subtitle2,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          _propertyTitle,
                          style: Theme.of(context).textTheme.headline5,
                          textAlign: TextAlign.left,
                        ),
                        if (description != null) description
                      ]),
                ),
                button
              ]),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 15, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Value',
                ),
                Text(
                  '${_propertyValue ?? "Unknown"}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _readProperty() async {
    setState(() {
      _updating = true;
    });

    Object? value;

    try {
      final status =
          await widget.consumedThing.readProperty(widget.propertyKey, null);
      value = await status.value();
    } on Exception {
      setState(() {
        _updating = false;
        return;
      });
    }

    setState(() {
      _updating = false;
      _propertyValue = value.toString();
    });
  }
}
