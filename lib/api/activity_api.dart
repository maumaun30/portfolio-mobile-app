import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import 'api_client.dart';

class ActivityApi {
  ActivityApi(this._ref);
  final Ref _ref;

  Future<List<Activity>> list() async {
    final dio = _ref.read(dioProvider);
    final res = await dio.get<Map<String, dynamic>>('/api/activity');
    final list = (res.data?['entries'] as List?) ?? const [];
    return list
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final activityApiProvider = Provider<ActivityApi>((ref) => ActivityApi(ref));

final activityListProvider =
    FutureProvider.autoDispose<List<Activity>>((ref) {
  return ref.watch(activityApiProvider).list();
});
