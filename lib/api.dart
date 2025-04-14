
import 'log.dart' as log;


import 'package:http/http.dart' as http;
import './auth.dart' as auth;
import 'dart:convert';
import './profile.dart';

// this IP is specified by android
// use it if you're using an emulator and hosting the server locally
//const root = "10.0.2.2";
//const root = "archenemy-zusg.shuttle.app";
//const port = 8000;
//const host = "10.0.2.2:8000";
const host = "archenemy-zusg.shuttle.app";
const https = true;

Profile? _profileFromMap(dynamic map) {
		if (map case {
		// Rare dart W, this is great
		'id': String id,
		'username': String username,
		'display_name': String? displayName,
		'avatar_url': String avatarUrl,
		'bio': String bio,
		/*'embedding': dynamic _,
		'created_at': dynamic _,
		'updated_at': dynamic _*/
	}) {
		return Profile(
			id: id,
			username: username,
			displayName: displayName ?? "<no-name-yet>",
			avatarUrl: avatarUrl,
			bio: bio,
			tags: map["tags"] is List<String> ? map["tags"] : null
		);
	} else {
		log.warning("Failed to decode profile: $map");
		return null;
	}
}
Profile? _profileFromJson(String raw) {
	return _profileFromMap(json.decode(raw));
}
List<Profile>? _profilesFromJson(String raw) {
	var list = json.decode(raw);
	List<Profile> decoded = [];
	if (list is List) {
		for (final raw in list) {
			if (_profileFromMap(raw) case Profile profile) {
				decoded.add(profile);
			}
		}
	}
	return decoded;
}
String _profileToJson(Profile profile) {
	return json.encode({
		'id': profile.id,
		'username': profile.username,
		'display_name': profile.displayName,
		'avatar_url': profile.avatarUrl,
		'bio': profile.bio,
		'tags': profile.tags
	});
}

Future<Profile?> getMyProfile() {
	return _get("/user/me",
		ok: (res) => _profileFromJson(res.body),
		err: (_) => null
	);
}
Future<bool> patchMyProfile(Profile profile) {
	return _req<bool>(http.patch, "/user/me",
		headers: {
			"Content-Type": "application/json",
		},
		body: json.encode({
			"username": profile.username,
			"display_name": profile.displayName,
			"avatar_url": profile.avatarUrl,
			"bio": profile.bio
		}),
		ok: (res) => true,
		err: (_) => false
	);
}

List<Profile> _exploreProfiles = [];
Future<List<Profile>?>? _exploreRequest;

Future<Profile?> getNextExploreProfile() async {
	if (_exploreProfiles.length <= 3) {
		_addExploreProfiles(); // don't await
	}
	
	if (_exploreProfiles.isEmpty) {
		await _exploreRequest; // need to wait now
	}
	
	return _exploreProfiles.firstOrNull;
}
Future<void> _addExploreProfiles({ int paginationOffset = 0 }) async {
	if (_exploreRequest == null) {
		_exploreRequest = _getExploreProfiles(
			paginationOffset: paginationOffset
		);
		final profiles = await _exploreRequest;
		_exploreRequest = null;
		if (profiles != null) {
			_exploreProfiles.addAll(profiles);
		}
	}
}
Future<List<Profile>?> _getExploreProfiles({ int paginationOffset = 0 }) {
	return _get("/nemeses/discover",
		params: { "offset": paginationOffset.toString() },
		ok: (res) => _profilesFromJson(res.body),
		err: (_) => null,
	);
}
Future<bool> postLike(String nemesisId) {
	return _req(http.post, "/nemesis/like/$nemesisId",
		ok: (_) => true,
		err: (_) => false
	);
}
Future<bool> postDislike(String nemesisId) {
	return _req(http.post, "/nemesis/dislike/$nemesisId",
		ok: (_) => true,
		err: (_) => false
	);
}
Future<bool> popExploreProfile({ required bool liked }) async {
	final profile = _exploreProfiles.firstOrNull;
	if (profile == null) return false;
	final result = await (liked ? postLike(profile.id) : postDislike(profile.id));
	if (result) _exploreProfiles.removeAt(0);
	return result;
}

Uri _uri(String path, Map<String, String>? params) {
	return https ? Uri.https(host, path, params) : Uri.http(host, path, params);
}
Future<Map<String, String>?> _authorized(Map<String, String>? headers) async {
	String? token = await auth.user?.getIdToken();
	if (token == null) {
  	log.warning("Attempted unauthorized HTTP request");
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

/* Get works differently than everything else does */
Future<T> _get<T>(
	String path,
	{
		Map<String, String>? headers,
		Map<String, String>? params,
		required T Function(http.Response) ok,
		required T Function(http.Response?) err
	}
) async {
	final authorizedHeaders = await _authorized(headers);
	if (authorizedHeaders == null) return err(null);
	final res = await http.get(_uri(path, params), headers: authorizedHeaders);
	return _handle(res, ok, err);
}
Future<T> _req<T>(
	Requestor type,
	String path,
	{
		Map<String, String>? headers,
		Map<String, String>? params,
		String? body,
		required T Function(http.Response) ok,
		required T Function(http.Response?) err
	}
) async {
	final authorizedHeaders = await _authorized(headers);
	if (authorizedHeaders == null) return err(null);
	final res = await type(_uri(path, params), headers: authorizedHeaders, body: body);
	return _handle(res, ok, err);
}
T _handle<T>(http.Response res, T Function(http.Response) ok, T Function(http.Response) err) {
	if (res.statusCode == 200) return ok(res);
	log.error("invalid HTTP response code: ${res.statusCode}");
	return err(res);
}


