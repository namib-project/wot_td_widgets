// Copyright 2022 The NAMIB Project Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wot_td_widgets/wot_td_widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoT TD Widgets Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WoT TD Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class WotContainer {
  WoT wot;

  ThingDescription thingDescription;

  WotContainer(this.wot, this.thingDescription);
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<WoT> _createWotRuntime() async {
    final servient = Servient()..addClientFactory(HttpClientFactory());

    if (!kIsWeb) {
      final coapConfig = CoapConfig(blocksize: 64);
      final coapClientFactory = CoapClientFactory(coapConfig);

      servient.addClientFactory(coapClientFactory);
    }

    return servient.start();
  }

  Future<WotContainer> getThingDescription() async {
    final wot = await _createWotRuntime();
    const thingUrl = "coap://plugfest.thingweb.io:5683/testthing";
    await for (final thingDescription in wot.discover(ThingFilter(
        url: Uri.parse(thingUrl), method: DiscoveryMethod.direct))) {
      return WotContainer(wot, thingDescription);
    }

    throw Exception("Error retrieving Thing Description");
  }

  Widget createThingWidget() {
    return FutureBuilder<WotContainer>(
        future: getThingDescription(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            final wotContainer = snapshot.data;
            if (wotContainer == null) {
              throw Exception("Error retrieving Thing Description");
            }
            return Center(
                child: Column(children: [
              ThingWidget(wotContainer.thingDescription, wotContainer.wot)
            ]));
          }
          List<Widget> children;

          if (snapshot.hasError) {
            children = <Widget>[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ];
          } else {
            children = const <Widget>[
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Awaiting result...'),
              )
            ];
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: createThingWidget(),
        ),
      ),
    );
  }
}
