import 'dart:math';

/* ============================== CITIES ============================== */

class City {
  final String key;
  final String name;
  final double lat;
  final double lon;
  const City(this.key, this.name, this.lat, this.lon);
}

// India time (IST) is used for every city.
const List<City> kCities = [
  City('delhi', 'New Delhi', 28.6139, 77.2090),
  City('jaipur', 'Jaipur', 26.9124, 75.7873),
  City('mumbai', 'Mumbai', 19.0760, 72.8777),
  City('kolkata', 'Kolkata', 22.5726, 88.3639),
  City('chennai', 'Chennai', 13.0827, 80.2707),
  City('bengaluru', 'Bengaluru', 12.9716, 77.5946),
  City('hyderabad', 'Hyderabad', 17.3850, 78.4867),
  City('ahmedabad', 'Ahmedabad', 23.0225, 72.5714),
  City('pune', 'Pune', 18.5204, 73.8567),
  City('lucknow', 'Lucknow', 26.8467, 80.9462),
  City('kanpur', 'Kanpur', 26.4499, 80.3319),
  City('nagpur', 'Nagpur', 21.1458, 79.0882),
  City('indore', 'Indore', 22.7196, 75.8577),
  City('bhopal', 'Bhopal', 23.2599, 77.4126),
  City('patna', 'Patna', 25.5941, 85.1376),
  City('chandigarh', 'Chandigarh', 30.7333, 76.7794),
  City('amritsar', 'Amritsar', 31.6340, 74.8723),
  City('ludhiana', 'Ludhiana', 30.9010, 75.8573),
  City('dehradun', 'Dehradun', 30.3165, 78.0322),
  City('haridwar', 'Haridwar', 29.9457, 78.1642),
  City('varanasi', 'Varanasi', 25.3176, 82.9739),
  City('prayagraj', 'Prayagraj', 25.4358, 81.8463),
  City('ayodhya', 'Ayodhya', 26.7922, 82.1998),
  City('mathura', 'Mathura', 27.4924, 77.6737),
  City('agra', 'Agra', 27.1767, 78.0081),
  City('ujjain', 'Ujjain', 23.1765, 75.7885),
  City('jodhpur', 'Jodhpur', 26.2389, 73.0243),
  City('udaipur', 'Udaipur', 24.5854, 73.7125),
  City('kota', 'Kota', 25.2138, 75.8648),
  City('bikaner', 'Bikaner', 28.0229, 73.3119),
  City('ajmer', 'Ajmer', 26.4499, 74.6399),
  City('surat', 'Surat', 21.1702, 72.8311),
  City('vadodara', 'Vadodara', 22.3072, 73.1812),
  City('rajkot', 'Rajkot', 22.3039, 70.8022),
  City('raipur', 'Raipur', 21.2514, 81.6296),
  City('ranchi', 'Ranchi', 23.3441, 85.3096),
  City('bhubaneswar', 'Bhubaneswar', 20.2961, 85.8245),
  City('guwahati', 'Guwahati', 26.1445, 91.7362),
  City('thiruvananthapuram', 'Thiruvananthapuram', 8.5241, 76.9366),
  City('kochi', 'Kochi', 9.9312, 76.2673),
  City('visakhapatnam', 'Visakhapatnam', 17.6868, 83.2185),
  City('coimbatore', 'Coimbatore', 11.0168, 76.9558),
  City('madurai', 'Madurai', 9.9252, 78.1198),
  City('srinagar', 'Srinagar', 34.0837, 74.7973),
  City('shimla', 'Shimla', 31.1048, 77.1734),
  City('gurugram', 'Gurugram', 28.4595, 77.0266),
  City('noida', 'Noida', 28.5355, 77.3910),
  City('meerut', 'Meerut', 28.9845, 77.7064),
  City('gorakhpur', 'Gorakhpur', 26.7606, 83.3732),
  City('jabalpur', 'Jabalpur', 23.1815, 79.9864),
  City('gwalior', 'Gwalior', 26.2183, 78.1828),
  City('nashik', 'Nashik', 19.9975, 73.7898),
];

City cityByKey(String key) {
  for (final c in kCities) {
    if (c.key == key) return c;
  }
  return kCities.first;
}

/* ============================== SUNRISE / SUNSET ============================== */
// NOAA solar-position algorithm; matches a high-precision ephemeris to within
// a few seconds for Indian latitudes.

double _rad(double d) => d * pi / 180;
double _deg(double r) => r * 180 / pi;

double _julianDay(int y, int m, int d) {
  var yy = y;
  var mm = m;
  if (mm <= 2) {
    yy -= 1;
    mm += 12;
  }
  final a = yy ~/ 100;
  final b = 2 - a + a ~/ 4;
  return (365.25 * (yy + 4716)).floorToDouble() + (30.6001 * (mm + 1)).floorToDouble() + d + b - 1524.5;
}

// Returns [declination in degrees, equation of time in minutes].
List<double> _sunParams(double jd) {
  final t = (jd - 2451545.0) / 36525.0;
  final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
  final mDeg = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final m = _rad(mDeg);
  final c = sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
      sin(2 * m) * (0.019993 - 0.000101 * t) +
      sin(3 * m) * 0.000289;
  final trueLong = l0 + c;
  final omega = 125.04 - 1934.136 * t;
  final lam = trueLong - 0.00569 - 0.00478 * sin(_rad(omega));
  final sec = 21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813));
  final e0 = 23 + (26 + sec / 60) / 60;
  final eps = e0 + 0.00256 * cos(_rad(omega));
  final decl = _deg(asin(sin(_rad(eps)) * sin(_rad(lam))));
  final y = pow(tan(_rad(eps) / 2), 2).toDouble();
  final l0r = _rad(l0);
  final eq = y * sin(2 * l0r) -
      2 * e * sin(m) +
      4 * e * y * sin(m) * cos(2 * l0r) -
      0.5 * y * y * sin(4 * l0r) -
      1.25 * e * e * sin(2 * m);
  return [decl, _deg(eq) * 4];
}

double? _riseSetUtc(bool rise, double jd, double lat, double lon) {
  final p = _sunParams(jd);
  final decl = p[0];
  final eq = p[1];
  final arg = cos(_rad(90.833)) / (cos(_rad(lat)) * cos(_rad(decl))) - tan(_rad(lat)) * tan(_rad(decl));
  if (arg < -1 || arg > 1) return null;
  var ha = acos(arg);
  if (!rise) ha = -ha;
  final delta = lon + _deg(ha);
  return 720 - 4 * delta - eq;
}

class SunTimes {
  final double sunrise; // minutes after local midnight (IST)
  final double sunset;
  const SunTimes(this.sunrise, this.sunset);
}

SunTimes? sunTimes(DateTime date, City city, {double tz = 5.5}) {
  final jd = _julianDay(date.year, date.month, date.day);
  final res = <double>[];
  for (final rise in [true, false]) {
    final t1 = _riseSetUtc(rise, jd, city.lat, city.lon);
    if (t1 == null) return null;
    final t2 = _riseSetUtc(rise, jd + t1 / 1440.0, city.lat, city.lon);
    if (t2 == null) return null;
    res.add(t2 + tz * 60);
  }
  return SunTimes(res[0], res[1]);
}

/* ============================== DAILY MUHURAT ============================== */

class TimeRange {
  final double start;
  final double end;
  const TimeRange(this.start, this.end);
}

class DayMuhurat {
  final double sunrise;
  final double sunset;
  final TimeRange rahu;
  final TimeRange yamaganda;
  final TimeRange gulika;
  final TimeRange brahma;
  final TimeRange? abhijit; // not observed on Wednesdays

  const DayMuhurat({
    required this.sunrise,
    required this.sunset,
    required this.rahu,
    required this.yamaganda,
    required this.gulika,
    required this.brahma,
    required this.abhijit,
  });
}

// Which eighth of the daytime (1-8) each inauspicious period falls in,
// by weekday (Monday = 1 ... Sunday = 7).
const Map<int, int> _rahuPart = {1: 2, 2: 7, 3: 5, 4: 6, 5: 4, 6: 3, 7: 8};
const Map<int, int> _yamaPart = {1: 4, 2: 3, 3: 2, 4: 1, 5: 7, 6: 6, 7: 5};
const Map<int, int> _gulikaPart = {1: 6, 2: 5, 3: 4, 4: 3, 5: 2, 6: 1, 7: 7};

DayMuhurat? muhuratFor(DateTime date, City city) {
  final st = sunTimes(date, city);
  if (st == null) return null;
  final dayLen = st.sunset - st.sunrise;
  final part = dayLen / 8;
  TimeRange nth(int n) => TimeRange(st.sunrise + (n - 1) * part, st.sunrise + n * part);
  final wd = date.weekday;
  final muhurta = dayLen / 15;
  return DayMuhurat(
    sunrise: st.sunrise,
    sunset: st.sunset,
    rahu: nth(_rahuPart[wd]!),
    yamaganda: nth(_yamaPart[wd]!),
    gulika: nth(_gulikaPart[wd]!),
    brahma: TimeRange(st.sunrise - 96, st.sunrise - 48),
    abhijit: wd == 3 ? null : TimeRange(st.sunrise + 7 * muhurta, st.sunrise + 8 * muhurta),
  );
}

// 6:42 AM
String clockText(double minutes) {
  final total = minutes.round();
  final h = (total ~/ 60) % 24;
  final m = total % 60;
  final ap = h >= 12 ? 'PM' : 'AM';
  var h12 = h % 12;
  if (h12 == 0) h12 = 12;
  return '$h12:${m.toString().padLeft(2, '0')} $ap';
}

String rangeText(TimeRange r) => '${clockText(r.start)} - ${clockText(r.end)}';
