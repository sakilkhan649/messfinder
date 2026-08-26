import 'dart:developer';

void main() {
  String? value = 'test';
  var map = {
    'key1': 'value1',
    'key2': value,
  };
  log(map.toString());
}
