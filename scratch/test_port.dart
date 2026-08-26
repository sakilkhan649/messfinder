// @dart=3.0
import 'dart:io';
import 'dart:developer';
void main() async { try { await Socket.connect('127.0.0.1', 5000); } catch (e) { log(e.toString()); } }
