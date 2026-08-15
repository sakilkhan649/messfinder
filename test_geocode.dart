// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyD6PVD0fm6Qte1lUd3Ca-Lbg-vj5aXlzMc';
  final query = 'Mohakhali';
  final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey';
  final response = await http.get(Uri.parse(url));
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
