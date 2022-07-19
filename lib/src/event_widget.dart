// Copyright 2022 The NAMIB Project Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:dart_wot/dart_wot.dart';
import 'package:flutter/material.dart';

/// A [StatefulWidget] that can be used to display events that are emitted by a
/// Thing.
class EventWidget extends StatefulWidget {
  /// The key of the event. Used to access it in the [consumedThing].
  final String eventKey;

  /// The [ConsumedThing] associated with this property.
  final ConsumedThing consumedThing;

  /// Creates a new [EventWidget] for interacting with a property of a
  /// [ConsumedThing]. That property is specified by its [eventKey].
  const EventWidget(this.eventKey, this.consumedThing, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => EventState();
}

/// Represents the state of an event.
class EventState extends State<EventWidget> {
  /// The currently value of the propety.
  Object? _eventValue;
  bool _updating = false;

  Subscription? _subscription;

  @override
  void dispose() {
    _subscription?.stop();
    super.dispose();
  }

  String get _propertyTitle {
    final title =
        widget.consumedThing.thingDescription.actions[widget.eventKey]?.title;

    return title ?? widget.eventKey;
  }

  String? get _propertyDescription {
    return widget.consumedThing.thingDescription.properties[widget.eventKey]
        ?.description;
  }

  @override
  Widget build(BuildContext context) {
    final Widget button;

    if (_updating) {
      button = const CircularProgressIndicator();
    } else {
      button = IconButton(
          onPressed: _subscribeEvent,
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
                  '${_eventValue ?? "Unknown"}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeEvent() async {
    setState(() {
      _updating = true;
    });

    Subscription? subscription = _subscription;

    // Workaround for dealing with HTTP forms with subprotocol longpolling
    // which is currently unsupported
    final affordance =
        widget.consumedThing.thingDescription.events[widget.eventKey];
    for (var formIndex = 0;
        formIndex < (affordance?.forms.length ?? 0);
        formIndex++) {
      try {
        subscription = await widget.consumedThing.subscribeEvent(
          widget.eventKey,
          ((data) async {
            final value = await data.value();
            setState(() {
              _eventValue = value.toString();
            });
          }),
          null,
          InteractionOptions(
            formIndex: formIndex,
          ),
        );
        break;
      } on UnimplementedError {
        continue;
      }
    }

    setState(() {
      _subscription = subscription;
      _updating = false;
    });
  }
}
