
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'log.dart';

import './profile.dart';
import 'package:http/http.dart' as http;

const host = "https://archenemy-zusg.shuttle.app";
const port = 443;

/* Unclear if the auth logic will look like this going forward */
User? user;

Future<void> init() async {
	
	FirebaseAuth.instance
		.idTokenChanges()
		.listen((User? newUser) {
			user = newUser;
			if (user == null) {
				log.w("User signed out");
			} else {
				log.i("User signed in");
			}
		});
	
	await Firebase.initializeApp(
		options: DefaultFirebaseOptions.currentPlatform
	);
}

Future<String?> getToken() async {
	return await user?.getIdToken();
}
Future<Profile?> getMyProfile() async {
	return _get<Profile?>("/user/me",
		ok: (res) => Profile.fromJson(res.body),
		err: (_) => null
	);
}
Future<bool> patchMyProfile(Profile newProfile) async {
	return _req<bool>(http.patch, "/user/me",
		body: newProfile.toJson(),
		ok: (res) => true,
		err: (_) => false
	);
}



//HttpClient httpClient = HttpClient();

Future<Map<String, String>?> _authorized(Map<String, String>? headers) async {
	String? token = await getToken();
	if (token == null) {
  	log.d("Attempted unauthorized HTTP request");
    return null;
  }
	headers ??= {};
	headers["Authorization"] = "Bearer $token";
	return headers;
}

/* Nightmare methods that will make things easier and cleaner */
/*typedef Getter = Future<http.Response> Function(Uri uri, {
	Map<String, String>? headers
});*/
typedef Requestor = Future<http.Response> Function(Uri uri, {
	Map<String, String>? headers,
	String? body
});

/* Getters, and only getters, work differently than everything else does */
Future<T> _get<T>(
	String path,
	{
		Map<String, String>? headers,
		required T Function(http.Response) ok,
		required T Function(http.Response?) err
	}
) async {
	final authorizedHeaders = await _authorized(headers);
	if (authorizedHeaders == null) {
		return err(null);
	}
	final res = await http.get(Uri.https(host, path), headers: authorizedHeaders);
	return _handle(res, ok, err);
}
Future<T> _req<T>(
	Requestor type,
	String path,
	{
		Map<String, String>? headers,
		String? body,
		required T Function(http.Response) ok,
		required T Function(http.Response?) err
	}
) async {
	final authorizedHeaders = await _authorized(headers);
	if (authorizedHeaders == null) return err(null);
	final res = await type(Uri.https(host, path), headers: authorizedHeaders);
	return _handle(res, ok, err);
}
T _handle<T>(http.Response res, T Function(http.Response) ok, T Function(http.Response) err) {
	if (res.statusCode == 200) return ok(res);
	return err(res);
}


