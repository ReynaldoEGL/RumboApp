import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumboapp/features/road_routes/data/here_routing_service.dart';

const String _hereApiKey = String.fromEnvironment('HERE_API_KEY');

final hereRoutingServiceProvider = Provider<HereRoutingService>((ref) {
  final service = HereRoutingService(apiKey: _hereApiKey);

  ref.onDispose(service.close);

  return service;
});
