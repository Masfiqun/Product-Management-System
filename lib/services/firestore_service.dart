import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/models/product.dart';
import 'package:record/models/shipment.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Products ─────────────────────────────────────

  Future<String> addProduct(Product product) async {
    final docRef = await _firestore.collection('products').add(product.toMap());
    return docRef.id;
  }

  Future<List<Product>> getProducts({bool? isCheckedOut}) async {
    Query query = _firestore.collection('products');

    if (isCheckedOut != null) {
      query = query.where('checkedOutAt', isNull: !isCheckedOut);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<Product>> getCheckedOutProducts() async {
    final snapshot = await _firestore.collection('products')
        .where('checkedOutAt', isNull: false)
        .where('originalProductId', isNull: false)
        .get();

    return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> updateProduct(Product product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
  }

  Stream<List<Product>> streamProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<List<Product>> getProductsByShipment(String shipmentId) async {
    final snapshot = await _firestore
        .collection('products')
        .where('shipmentId', isEqualTo: shipmentId)
        .get();

    return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
  }

  // ─── Check-In ─────────────────────────────────────

  Future<void> checkInProduct({
    required String productId,
    required String shipmentId,
    required int alreadyCheckedIn,
    required int totalProductCount,
  }) async {
    final shipmentRef = _firestore.collection('shipments').doc(shipmentId);
    final productRef = _firestore.collection('products').doc(productId);
    final checkInTime = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final shipmentSnap = await transaction.get(shipmentRef);
      final productSnap = await transaction.get(productRef);

      if (!shipmentSnap.exists || !productSnap.exists) {
        throw Exception('Shipment or Product not found');
      }

      final shipment = Shipment.fromMap(shipmentSnap.data()!, shipmentSnap.id);
      final product = Product.fromMap(productSnap.data()!, productSnap.id);

      // Update shipment if product not already checked in
      if (!shipment.checkedInProductIds.contains(productId)) {
        final updatedCheckedIn = [...shipment.checkedInProductIds, productId];
        final isCompleted = updatedCheckedIn.length == totalProductCount;

        final updatedShipment = shipment.copyWith(
          checkedInProductIds: updatedCheckedIn,
          isCompleted: isCompleted,
        );

        transaction.update(shipmentRef, updatedShipment.toMap());
      }

      // Update product check-in time
      final updatedProduct = product.copyWith(checkedInAt: checkInTime);
      transaction.update(productRef, updatedProduct.toMap());
    });
  }

  // ─── Shipments ─────────────────────────────────────

  Future<String> createShipment(Shipment shipment) async {
    final docRef = await _firestore.collection('shipments').add(shipment.toMap());
    return docRef.id;
  }

  Future<List<Shipment>> getShipments({bool? isCompleted}) async {
    Query query = _firestore.collection('shipments');

    if (isCompleted != null) {
      query = query.where('isCompleted', isEqualTo: isCompleted);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Shipment.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateShipment(Shipment shipment) async {
    await _firestore.collection('shipments').doc(shipment.id).update(shipment.toMap());
  }

  Future<void> deleteShipment(String shipmentId) async {
    await _firestore.collection('shipments').doc(shipmentId).delete();

    final productsSnapshot = await _firestore
        .collection('products')
        .where('shipmentId', isEqualTo: shipmentId)
        .get();

    for (final doc in productsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<Shipment> getShipment(String shipmentId) async {
    final doc = await _firestore.collection('shipments').doc(shipmentId).get();
    return Shipment.fromMap(doc.data()!, doc.id);
  }

  Stream<Shipment> streamShipment(String shipmentId) {
    return _firestore.collection('shipments').doc(shipmentId).snapshots().map(
          (snapshot) => Shipment.fromMap(snapshot.data()!, snapshot.id),
        );
  }

  Stream<List<Shipment>> streamShipments() {
    return _firestore.collection('shipments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Shipment.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
