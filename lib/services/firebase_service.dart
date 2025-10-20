import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();

  late FirebaseDatabase _database;
  late FirebaseAuth _auth;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConstants.firebaseUrl,
    );
    _auth = FirebaseAuth.instance;
  }

  // Database References
  DatabaseReference get adminRef => _database.ref('admin');
  DatabaseReference get voucherRef => _database.ref('voucher');
  DatabaseReference get addressRef => _database.ref('address');
  DatabaseReference get categoryRef => _database.ref('category');
  DatabaseReference get productRef => _database.ref('product');
  DatabaseReference get feedbackRef => _database.ref('feedback');
  DatabaseReference get orderRef => _database.ref('order');

  // Specific references
  DatabaseReference getProductDetailRef(int productId) => 
      _database.ref('product/$productId');
  
  DatabaseReference getCategoryDetailRef(int categoryId) => 
      _database.ref('category/$categoryId');
  
  DatabaseReference getRatingProductRef(String productId) => 
      _database.ref('product/$productId/rating');
  
  DatabaseReference getOrderDetailRef(int orderId) => 
      _database.ref('order/$orderId');

  // Auth methods
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper methods for data operations
  Future<DataSnapshot> getData(String path) async {
    return await _database.ref(path).get();
  }

  Future<void> setData(String path, Map<String, dynamic> data) async {
    await _database.ref(path).set(data);
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _database.ref(path).update(data);
  }

  Future<void> removeData(String path) async {
    await _database.ref(path).remove();
  }

  Stream<DatabaseEvent> listenToData(String path) {
    return _database.ref(path).onValue;
  }

  Stream<DatabaseEvent> listenToChildAdded(String path) {
    return _database.ref(path).onChildAdded;
  }

  Stream<DatabaseEvent> listenToChildChanged(String path) {
    return _database.ref(path).onChildChanged;
  }

  Stream<DatabaseEvent> listenToChildRemoved(String path) {
    return _database.ref(path).onChildRemoved;
  }

  // Query methods
  Query orderByChild(String path, String child) {
    return _database.ref(path).orderByChild(child);
  }

  Query orderByValue(String path) {
    return _database.ref(path).orderByValue();
  }

  Query orderByKey(String path) {
    return _database.ref(path).orderByKey();
  }

  Query limitToFirst(String path, int limit) {
    return _database.ref(path).limitToFirst(limit);
  }

  Query limitToLast(String path, int limit) {
    return _database.ref(path).limitToLast(limit);
  }

  Query equalTo(String path, dynamic value) {
    return _database.ref(path).equalTo(value);
  }
}
