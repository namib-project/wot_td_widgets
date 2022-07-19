// Copyright 2022 The NAMIB Project Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:dart_wot/dart_wot.dart';
import 'package:flutter/material.dart';

import 'action_widget.dart';
import 'event_widget.dart';
import 'property_widget.dart';

/// A [StatefulWidget] representing a Thing.
class ThingWidget extends StatefulWidget {
  /// The [thingDescription] associated with this ThingWidget.
  final ThingDescription thingDescription;

  /// The maximum width of this Widget. Defaults to 400.
  final double maxWidth;

  final double defaultIconHeight;

  final double defaultIconWidth;

  final WoT _wot;

  /// Constructor.
  const ThingWidget(
    this.thingDescription,
    this._wot, {
    Key? key,
    this.maxWidth = 400,
    this.defaultIconHeight = 36.0,
    this.defaultIconWidth = 36.0,
  }) : super(key: key);

  @override
  State<ThingWidget> createState() => _ThingWidgetState();
}

class _ThingWidgetState extends State<ThingWidget> {
  late final Future<ConsumedThing> _consumedThing;

  @override
  void initState() {
    _consumedThing = widget._wot.consume(widget.thingDescription);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Row(children: const [
      Text("Loading Thing Widget..."),
      CircularProgressIndicator()
    ]);

    return FutureBuilder<ConsumedThing>(
        future: _consumedThing,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return placeholder;
          }

          if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          }

          return _buildAffordanceWidgets(context, snapshot.data!);
        });
  }

  Widget _buildIcon(BuildContext context, ThingDescription thingDescription) {
    final fallbackIcon = Icon(
      Icons.lightbulb,
      size: widget.defaultIconWidth,
    );

    final iconLinks =
        thingDescription.links.where((link) => link.rel == "icon");

    if (iconLinks.isNotEmpty) {
      final link = iconLinks.first;
      final href = link.href;
      final sizes = link.sizes;

      final parsedSizes = sizes?.split("x").map(double.tryParse).toList();
      final height = parsedSizes?[0] ?? widget.defaultIconHeight;
      final width = parsedSizes?[1] ?? widget.defaultIconWidth;

      if (href.isAbsolute) {
        return Image.network(
          href.toString(),
          height: height,
          width: width,
          errorBuilder: (context, object, stackTrace) => fallbackIcon,
        );
      }
    }

    return fallbackIcon;
  }

  Widget _buildHeader(BuildContext context, ConsumedThing consumedThing) {
    final thingDescription = consumedThing.thingDescription;

    final title = Text(
      thingDescription.title,
      style: Theme.of(context).textTheme.titleLarge,
    );

    final description = thingDescription.description;

    Widget? subtitle;
    if (description != null) {
      subtitle = Text(
        description,
        style: Theme.of(context).textTheme.subtitle1,
      );
    }

    return ListTile(
      leading: _buildIcon(context, consumedThing.thingDescription),
      tileColor: Theme.of(context).listTileTheme.tileColor,
      title: title,
      subtitle: subtitle,
      trailing: const IconButton(
        icon: Icon(
          Icons.more_vert,
        ),
        onPressed: null,
      ),
    );
  }

  void _buildPropertyWidgets(
      List<Widget> widgets, ConsumedThing consumedThing) {
    final properties = consumedThing.thingDescription.properties;

    if (properties.isEmpty) {
      return;
    }

    for (final property in properties.entries) {
      final key = property.key;
      final value = property.value;
      switch (value.type) {
        case "integer":
          widgets.add(IntegerPropertyWidget(key, consumedThing));
          break;
        default:
          widgets.add(PropertyWidget(key, consumedThing));
      }
    }
  }

  void _buildActionWidgets(List<Widget> widgets, ConsumedThing consumedThing) {
    final actions = consumedThing.thingDescription.actions;

    if (actions.isEmpty) {
      return;
    }

    for (final action in actions.keys) {
      widgets.add(ActionWidget(action, consumedThing));
    }
  }

  void _buildEventWidgets(List<Widget> widgets, ConsumedThing consumedThing) {
    final events = consumedThing.thingDescription.events;

    if (events.isEmpty) {
      return;
    }

    for (final event in events.keys) {
      widgets.add(EventWidget(event, consumedThing));
    }
  }

  Widget _buildAffordanceWidgets(
      BuildContext context, ConsumedThing consumedThing) {
    final widgets = [_buildHeader(context, consumedThing)];

    _buildPropertyWidgets(widgets, consumedThing);
    _buildActionWidgets(widgets, consumedThing);
    _buildEventWidgets(widgets, consumedThing);

    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Card(
        child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 15),
            child: Wrap(
              children: widgets,
            )),
      ),
      // ),
    );
  }
}
