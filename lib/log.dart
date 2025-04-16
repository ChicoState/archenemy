/* In its own file so that everyone can share a single logger instance */
import 'package:logger/logger.dart';
var log = Logger();

/* One-letter function names be gone */
void info(dynamic what) => log.i(what);
void trace(dynamic what) => log.t(what);
void debug(dynamic what) => log.d(what);
void warning(dynamic what) => log.w(what);
void error(dynamic what) => log.e(what);
void fatal(dynamic what) => log.f(what);


