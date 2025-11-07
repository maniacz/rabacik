import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
// import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'models/coupon.dart';

class DbHelper {
  DatabaseFactory dbFactory = databaseFactoryIo;
  Database? db;
  final store = intMapStoreFactory.store('quotes');

  Future<Database> _openDb() async {
    final docsPath = await getApplicationDocumentsDirectory();
    final dbPath = join(docsPath.path, 'coupons.db');
    final db = await dbFactory.openDatabase(dbPath);
    return db;
  }

  Future<int> insertCoupon(Coupon coupon) async {
    try {
      Database db = await _openDb();
      int id = await store.add(db, coupon.toMap());
      return id;
    } on Exception catch (_) {
      return 0;
    }
  }
}