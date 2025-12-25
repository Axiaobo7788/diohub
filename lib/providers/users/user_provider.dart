import 'dart:async';

import 'package:diohub/app/global.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends BaseDataProvider<GuserInfoData_user> {
  UserProvider(this._userName) {
    if (kDebugMode) {
      log.d('[UserProvider] Constructor called with _userName: "$_userName"');
    }
  }
  final String _userName;

  @override
  Future<GuserInfoData_user> setInitData(
          {final bool isInitialisation = false}) async {
    if (kDebugMode) {
      log.d(
          '[UserProvider] setInitData() called for _userName: "$_userName", isInitialisation: $isInitialisation');
    }
    final result = await UserInfoService.getUserInfoGraphQL(_userName);
    if (kDebugMode) {
      log.d(
          '[UserProvider] setInitData() completed for _userName: "$_userName", result.login: "${result.login}"');
      if (_userName != result.login) {
        log.w(
            '[UserProvider] ⚠️ MISMATCH: _userName ("$_userName") != result.login ("${result.login}")');
      }
    }
    return result;
  }
}
