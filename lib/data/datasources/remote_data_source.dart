import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';

abstract class RemoteDataSource {
  Future<GoogleSignInAccount?> signIn();
  Future<void> signInSilently();
  Future<void> signOut();
  bool get isSignedIn;
  GoogleSignInAccount? get currentUser;

  Future<bool> uploadJson(String jsonContent, String filename);
  Future<String?> downloadJson(String filename);

  Future<bool> uploadFile(File localFile, String filename);
  Future<bool> downloadFile(String driveFilename, File targetFile);

  Future<void> uploadFiles(Map<String, File> files); // filename -> localFile
  Future<void> downloadFiles(Map<String, File> files); // driveFilename -> targetFile
}
