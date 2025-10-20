import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  FirebaseDatabase? _database;
  FirebaseAuth? _auth;

  Future<void> initialize() async {
    // Firebase is already initialized in main()
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConstants.firebaseUrl,
    );
    _auth = FirebaseAuth.instance;
  }

  // Getters with null checks
  FirebaseDatabase get database {
    if (_database == null) {
      throw Exception(
          'FirebaseService not initialized. Call initialize() first.');
    }
    return _database!;
  }

  FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception(
          'FirebaseService not initialized. Call initialize() first.');
    }
    return _auth!;
  }

  // Database References
  DatabaseReference get adminRef => database.ref('admin');
  DatabaseReference get voucherRef => database.ref('voucher');
  DatabaseReference get addressRef => database.ref('address');
  DatabaseReference get categoryRef => database.ref('category');
  DatabaseReference get productRef => database.ref('product');
  DatabaseReference get feedbackRef => database.ref('feedback');
  DatabaseReference get orderRef => database.ref('order');

  // Specific references
  DatabaseReference getProductDetailRef(int productId) =>
      database.ref('product/$productId');

  DatabaseReference getCategoryDetailRef(int categoryId) =>
      database.ref('category/$categoryId');

  DatabaseReference getRatingProductRef(String productId) =>
      database.ref('product/$productId/rating');

  DatabaseReference getOrderDetailRef(int orderId) =>
      database.ref('order/$orderId');

  // Auth methods
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => auth.currentUser;
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Helper methods for data operations
  Future<DataSnapshot> getData(String path) async {
    return await database.ref(path).get();
  }

  Future<void> setData(String path, Map<String, dynamic> data) async {
    await database.ref(path).set(data);
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await database.ref(path).update(data);
  }

  Future<void> removeData(String path) async {
    await database.ref(path).remove();
  }

  Stream<DatabaseEvent> listenToData(String path) {
    return database.ref(path).onValue;
  }

  Stream<DatabaseEvent> listenToChildAdded(String path) {
    return database.ref(path).onChildAdded;
  }

  Stream<DatabaseEvent> listenToChildChanged(String path) {
    return database.ref(path).onChildChanged;
  }

  Stream<DatabaseEvent> listenToChildRemoved(String path) {
    return database.ref(path).onChildRemoved;
  }

  // Query methods
  Query orderByChild(String path, String child) {
    return database.ref(path).orderByChild(child);
  }

  Query orderByValue(String path) {
    return database.ref(path).orderByValue();
  }

  Query orderByKey(String path) {
    return database.ref(path).orderByKey();
  }

  Query limitToFirst(String path, int limit) {
    return database.ref(path).limitToFirst(limit);
  }

  Query limitToLast(String path, int limit) {
    return database.ref(path).limitToLast(limit);
  }

  Query equalTo(String path, dynamic value) {
    return database.ref(path).equalTo(value);
  }
}
