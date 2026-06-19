import 'package:nofak/data/model/custom_field/custom_field_model.dart';
import 'package:nofak/data/model/user/verification_request_model.dart';
import 'package:nofak/utils/api.dart';

class SellerVerificationFieldRepository {
  Future<List<VerificationFieldModel>> getSellerVerificationFields({String? type}) async {
    try {
      Map<String, dynamic> parameters = {};
      if (type != null) {
        parameters['type'] = type;
      }

      Map<String, dynamic> response = await Api.get(
          url: Api.getVerificationFieldApi, queryParameters: parameters);

      List<VerificationFieldModel> modelList = (response['data'] as List)
          .map((e) => VerificationFieldModel.fromMap(e))
          .toList();

      return modelList;
    } catch (e) {
      throw "$e";
    }
  }

  Future<Map> sendVerificationField(
      {required Map<String, dynamic> data}) async {
    try {
      Map response =
          await Api.post(url: Api.sendVerificationRequestApi, parameter: data);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<VerificationRequestModel> getVerificationRequest({String? type}) async {
    try {
      Map<String, dynamic> parameters = {};
      if (type != null) {
        parameters['type'] = type;
      }

      Map<String, dynamic> response = await Api.get(
          url: Api.getVerificationRequestApi, queryParameters: parameters);

      VerificationRequestModel model =
          VerificationRequestModel.fromJson(response['data']);

      return model;
    } catch (e) {
      throw "$e";
    }
  }
}
