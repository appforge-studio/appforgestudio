import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../services/arri_client.rpc.dart';

class ArriService extends GetxService {
  late final ArriClient client;

  Future<ArriService> init() async {
    client = ArriClient(
      baseUrl: "http://localhost:5000",
      httpClient: http.Client(),
    );
    return this;
  }
}
