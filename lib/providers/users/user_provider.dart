import 'dart:async';

import 'package:diohub/app/global.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends BaseDataProvider<GuserInfoData_user> {
  UserProvider(this._userName) {  }
  final String _userName;

  @override
  Future<GuserInfoData_user> setInitData(
          {final bool isInitialisation = false}) async {    final result = await UserInfoService.getUserInfoGraphQL(_userName);
    if (kDebugMode) {      if (_userName != result.login) {      }
    }
    return result;
  }
}
