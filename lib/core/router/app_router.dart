import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';

final GoRouter appRouter=GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context,state){
          return const Scaffold(
            body: Center(
              child: Text(
                '骨架搭建成功',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    ],
);