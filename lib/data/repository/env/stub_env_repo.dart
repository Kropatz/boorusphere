import 'package:boorusphere/data/repository/version/entity/app_version.dart';
import 'package:boorusphere/domain/repository/env_repo.dart';
import 'package:boorusphere/pigeon/app_env.pi.dart';

class StubEnvRepo implements EnvRepo {
  StubEnvRepo({required this.env});

  @override
  final Env env;

  @override
  int get sdkVersion => 1;
  @override
  AppVersion get appVersion => AppVersion.fromString("99.0.0");
}
