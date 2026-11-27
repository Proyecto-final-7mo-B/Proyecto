import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/base_local/base_local.dart';

void main() {
  test('abre en memoria', () async {
    final b = BaseLocal(NativeDatabase.memory());
    await b.into(b.categorias).insert(CategoriasCompanion.insert(id: 'c', nombre: 'X', datos: '{}', orden: 0));
    expect(await b.select(b.categorias).get(), hasLength(1));
    await b.close();
  });
}
