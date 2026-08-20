// @dart=3.0
import 'dart:io';
void main() async { try { await Socket.connect('127.0.0.1', 5000); } catch (e) { print(e); } }
