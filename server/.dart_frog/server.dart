// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../main.dart' as entrypoint;
import '../routes/planos/index.dart' as planos_index;
import '../routes/planos/[id].dart' as planos_$id;
import '../routes/pacientes/index.dart' as pacientes_index;
import '../routes/pacientes/[id].dart' as pacientes_$id;
import '../routes/medicos/index.dart' as medicos_index;
import '../routes/medicos/[id].dart' as medicos_$id;

import '../routes/_middleware.dart' as middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return entrypoint.run(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/medicos', (context) => buildMedicosHandler()(context))
    ..mount('/pacientes', (context) => buildPacientesHandler()(context))
    ..mount('/planos', (context) => buildPlanosHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildMedicosHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => medicos_index.onRequest(context,))..all('/<id>', (context,id,) => medicos_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildPacientesHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => pacientes_index.onRequest(context,))..all('/<id>', (context,id,) => pacientes_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

Handler buildPlanosHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => planos_index.onRequest(context,))..all('/<id>', (context,id,) => planos_$id.onRequest(context,id,));
  return pipeline.addHandler(router);
}

