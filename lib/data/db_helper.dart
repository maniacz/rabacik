import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
// import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'models/coupon.dart';

class DbHelper {
      /// Wstawia kupon z określonym id (do przywracania usuniętego kuponu)
      Future<void> insertCouponWithId(Coupon coupon) async {
        Database db = await _openDb();
        if (coupon.id != null) {
          await store.record(coupon.id).put(db, coupon.toMap());
        } else {
          await store.add(db, coupon.toMap());
        }
      }
    /// Usuwa wszystkie zarchiwizowane (przeterminowane) kupony
    Future<int> deleteArchivedCoupons() async {
      Database db = await _openDb();
      final now = DateTime.now();
      // Pobierz wszystkie kupony
      final couponsSnapshot = await store.find(db);
      int deleted = 0;
      for (final item in couponsSnapshot) {
        final coupon = Coupon.fromJSON(item.value);
        if (coupon.expiryDate != null && now.isAfter(coupon.expiryDate!)) {
          await store.record(item.key).delete(db);
          deleted++;
        }
      }
      return deleted;
    }
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

  Future<List<Coupon>> getCoupons() async {
    Database db = await _openDb();
    final finder = Finder();
    final couponsSnapshot = await store.find(db, finder: finder);
    return couponsSnapshot.map((item) {
      final coupon = Coupon.fromJSON(item.value);
      coupon.id = item.key;
      return coupon;
    }).toList();
  }

  Future<bool> deleteCoupon(int id) async {
    try {
      Database db = await _openDb();
      await store.record(id).delete(db);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  Future<bool> updateCoupon(Coupon coupon) async {
    try {
      Database db = await _openDb();
      final finder = Finder(filter: Filter.byKey(coupon.id));
      await store.update(db, coupon.toMap(), finder: finder);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }
}