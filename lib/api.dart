
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'log.dart';

import './profile.dart';
import 'package:http/http.dart' as http;

const host = "";
const port = 443;

//HttpClient httpClient = HttpClient();

// TODO
String? getToken() {
	return "";
}

Map<String, String>? _authorized(Map<String, String>? headers) {
	String? token = getToken();
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
	final authorizedHeaders = _authorized(headers);
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
	final authorizedHeaders = _authorized(headers);
	if (authorizedHeaders == null) {
		return err(null);
	}
	final res = await type(Uri.https(host, path), headers: authorizedHeaders);
	return _handle(res, ok, err);
}
T _handle<T>(http.Response res, T Function(http.Response) ok, T Function(http.Response) err) {
	if (res.statusCode == 200) {
		return ok(res);
	} else {
		return err(res);
	}
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



/*HttpClientRequest? _authorized(HttpClientRequest req) {
	String? token = null; // replace when we actually are able to get a token
	if (token == null) {
  	log.d("Attempted unauthorized HTTP request");
    return null;
  } else {
		req.headers.add("Authorization", "Bearer $token");
		return req;
  }
}
Future<HttpClientRequest?> getReq(String path) async {
	return _authorized(await httpClient.get(host, port, path));
}
Future<HttpClientRequest?> postReq(String path) async {
	return _authorized(await httpClient.post(host, port, path));
}
Future<HttpClientRequest?> patchReq(String path) async {
	return _authorized(await httpClient.patch(host, port, path));
}
Future<HttpClientResponse?> get(String path) async {
	return (await getReq(path))?.close();
}
Future<HttpClientResponse?> post(String path) async {
	return (await postReq(path))?.close();
}
Future<HttpClientResponse?> patch(String path) async {
	return (await patchReq(path))?.close();
}

Future<Profile?> getMyProfile() async {
	final res = await get("/user/me");
	log.d(res);
}
Future<bool> patchMyProfile() async {
	final re = await patch("/user/me");
	return true;
}
Future<Profile?> getProfile(String userId) async {
	final res = await get("/user/$userId");
	res?.
	return null;
}*/


/*Future<List<Profile>?> getDiscoveryProfiles(int limit, int offset) async {
	final req = await get("/nemeses/discover?offset=$offset&limit=$limit");
	if (req == null) { return null; }
	final res = await req.close();
	return null;
}
Future<bool> postLike(int userId) async { // userIds probably won't stay as int
	final req = await post("/nemeses/like/$userId");
	if (req == null) { return null; }
	final res = await req.close();
	return false;
}
Future<bool> postDislike(int userId) async {
	final req = await post("/nemeses/dislike/$userId");
	if (req == null) { return null; }
	final res = await req.close();
	return false;
}



Future<List<Profile?>> getLikedProfiles() async {
	return null;
}
Future<List<Profile?>> getDislikedProfiles() async {
	return null;
}*/
/*Future putFile() async {
	
}
Future getFile() async {
	
}*/




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

const serverURL = "https://archenemy-zusg.shuttle.app";

