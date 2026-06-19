import 'package:nofak/utils/api.dart';

class RenewItemRepositoryRepository {
  Future<Map> renewItem({
    int? itemId,
    Iterable<int>? itemIds,
  }) async {
    assert(
      (itemId != null && itemIds == null) ||
          (itemId == null && itemIds != null),
      "Either itemId or itemIds must be provided, but not both.",
    );

    Map<String, dynamic> parameters = {};

    if (itemId != null) {
      parameters[Api.itemId] = itemId;
    } else if (itemIds != null) {
      parameters[Api.itemIds] = itemIds.join(', ');
    }

    parameters.addAll({
      Api.showOnlyToPremium: 0,
    });

    Map response = await Api.post(url: Api.renewItemApi, parameter: parameters);
    return response;
  }
}

