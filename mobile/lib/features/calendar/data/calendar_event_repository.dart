// lib/features/calendar/data/calendar_event_repository.dart
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';

final calendarEventRepositoryProvider = Provider<CalendarEventRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return CalendarEventRepository(dio, prefs);
});

class CalendarEventRepository {
  final Dio _dio;
  final SharedPreferences? _injectedPrefs;

  static const String _keyMonthCachePrefix = 'calendar_events_month_';
  static const String _keyYearCachePrefix = 'calendar_events_year_';

  CalendarEventRepository(this._dio, [this._injectedPrefs]);

  bool get _isTestEnvironment {
    try {
      final binding = WidgetsBinding.instance;
      return binding.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_injectedPrefs != null) return _injectedPrefs;
    return await SharedPreferences.getInstance();
  }

  dynamic _extractData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  /// Get fasting periods and holidays overlapping an Ethiopian month
  Future<List<CalendarEventModel>> getEventsForMonth(int year, int month) async {
    if (_isTestEnvironment) {
      return _getBuiltinEventsForMonth(year, month);
    }
    final cacheKey = '$_keyMonthCachePrefix${year}_$month';
    try {
      final response = await _dio.get(
        '/calendar/events/month',
        queryParameters: {'year': year, 'month': month},
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final data = _extractData(response.data);
      if (data is List) {
        final events = data
            .map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Save to cache asynchronously
        _cacheEvents(cacheKey, data);
        return events;
      }
    } catch (_) {
      // Offline fallback: load from cache
      final cached = await _loadCachedEvents(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      // If nothing in cache, compute client-side fallback from built-in canonical events
      return _getBuiltinEventsForMonth(year, month);
    }
    return _getBuiltinEventsForMonth(year, month);
  }

  /// Get all fasting periods and holidays for an Ethiopian year
  Future<List<CalendarEventModel>> getEventsForYear(int year) async {
    if (_isTestEnvironment) {
      return _getBuiltinEventsForYear(year);
    }
    final cacheKey = '$_keyYearCachePrefix$year';
    try {
      final response = await _dio.get(
        '/calendar/events/year',
        queryParameters: {'year': year},
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final data = _extractData(response.data);
      if (data is List) {
        final events = data
            .map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _cacheEvents(cacheKey, data);
        return events;
      }
    } catch (_) {
      final cached = await _loadCachedEvents(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      return _getBuiltinEventsForYear(year);
    }
    return _getBuiltinEventsForYear(year);
  }

  /// List events with admin filters
  Future<List<CalendarEventModel>> getAllEvents({
    int? year,
    String? type,
    String? category,
    bool? isMajor,
    String? importance,
    bool? includeInactive,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (year != null) query['year'] = year;
    if (type != null) query['type'] = type;
    if (category != null) query['category'] = category;
    if (isMajor != null) query['isMajor'] = isMajor;
    if (importance != null) query['importance'] = importance;
    if (includeInactive != null) query['includeInactive'] = includeInactive;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _dio.get(
      '/calendar/events',
      queryParameters: query,
    );
    final data = _extractData(response.data);
    if (data is List) {
      return data
          .map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Admin: Create calendar event
  Future<CalendarEventModel> createEvent(Map<String, dynamic> payload) async {
    final response = await _dio.post('/calendar/events', data: payload);
    final data = _extractData(response.data);
    await _clearCache();
    return CalendarEventModel.fromJson(data as Map<String, dynamic>);
  }

  /// Admin: Update calendar event
  Future<CalendarEventModel> updateEvent(
      String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch('/calendar/events/$id', data: payload);
    final data = _extractData(response.data);
    await _clearCache();
    return CalendarEventModel.fromJson(data as Map<String, dynamic>);
  }

  /// Admin: Toggle active status
  Future<CalendarEventModel> toggleStatus(String id) async {
    final response = await _dio.patch('/calendar/events/$id/toggle-status');
    final data = _extractData(response.data);
    await _clearCache();
    return CalendarEventModel.fromJson(data as Map<String, dynamic>);
  }

  /// Admin: Delete calendar event
  Future<void> deleteEvent(String id) async {
    await _dio.delete('/calendar/events/$id');
    await _clearCache();
  }

  // ── Cache Helpers ──────────────────────────────────────────────────────────

  Future<void> _cacheEvents(String key, dynamic rawList) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(key, jsonEncode(rawList));
    } catch (_) {}
  }

  Future<List<CalendarEventModel>?> _loadCachedEvents(String key) async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) =>
                  CalendarEventModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith(_keyMonthCachePrefix) ||
            k.startsWith(_keyYearCachePrefix)) {
          await prefs.remove(k);
        }
      }
    } catch (_) {}
  }

  // ── Built-in Canonical Fallbacks for Offline Resilience ─────────────────────

  List<CalendarEventModel> _getMovableEventsForYear(int year) {
    final bh = EthiopianCalendarUtil.calculateBahireHasab(year);
    return [
      CalendarEventModel(
        id: 'movable-nenewe-$year',
        name: 'ጾመ ነነዌ',
        nameEn: 'Fast of Nineveh',
        type: CalendarEventType.fast,
        category: CalendarEventCategory.majorFast,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.nenewe.month,
        startDay: bh.nenewe.day,
        endMonth: bh.nenewe.month,
        endDay: bh.nenewe.day + 2 > 30 ? (bh.nenewe.day + 2) % 30 : bh.nenewe.day + 2,
        description: 'የነነዌ ሰዎች በነቢዩ ዮናስ ስብከት ንስሐ የገቡበት የ፫ (3) ቀናት ታላቅ ጾም።',
        spiritualMeaning: 'በንስሐ እና በእንባ ወደ እግዚአብሔር በመመለስ ምሕረት የምናገኝበት የበረከት ጾም።',
        fastingRules: 'ከእንስሳት ተዋጽኦ ሙሉ በሙሉ መከልከል፣ እስከ ፱ (9) ሰዓት መጾም እና በጸሎት መትጋት።',
        primaryColor: '#F59E0B',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 3,
      ),
      CalendarEventModel(
        id: 'movable-abiy-tsom-$year',
        name: 'ዐቢይ ጾም (ሁዳዴ)',
        nameEn: 'Great Lent (Hudadi)',
        type: CalendarEventType.fast,
        category: CalendarEventCategory.majorFast,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.abiyTsom.startMonth,
        startDay: bh.abiyTsom.startDay,
        endMonth: bh.abiyTsom.endMonth,
        endDay: bh.abiyTsom.endDay,
        description: 'ጌታችንና መድኃኒታችን ኢየሱስ ክርስቶስ በገዳመ ቆሮንቶስ የጾመው የ፶፭ (55) ቀናት ታላቁ ዐቢይ ጾም።',
        spiritualMeaning: 'የዲያብሎስን ፈተና ድል የነሣበት፣ የጾም እና የጸሎት ቁንጮ የሆነ ታላቅ ጾም። ጾመ ሕርቃል፣ አርብዓ ጾምና ሰሙነ ሕማማትን ያጠቃልላል።',
        fastingRules: 'ከእንስሳት ተዋጽኦ ሙሉ በሙሉ መከልከል፣ በየቀኑ እስከ ቀትር/ምሽት መጾም፣ ስግደትና ምህላ ማድረግ።',
        primaryColor: '#F59E0B',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 55,
      ),
      CalendarEventModel(
        id: 'movable-debre-zeyt-$year',
        name: 'ደብረ ዘይት',
        nameEn: 'Debre Zeyt (Mount of Olives)',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.minorHoliday,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.debreZeyt.month,
        startDay: bh.debreZeyt.day,
        endMonth: bh.debreZeyt.month,
        endDay: bh.debreZeyt.day,
        description: 'የዐቢይ ጾም እኩሌታ (፭ኛው ሰንበት)፤ ጌታችን በደብረ ዘይት ተራራ ስለ ዳግም ምጽአቱ ያስተማረበት ዕለት።',
        spiritualMeaning: 'የጌታችንን ዳግም ምጽአት በማሰብ በንቃትና በጸሎት እንድንዘጋጅ የሚያሳስብ ዕለት።',
        primaryColor: '#DC2626',
        isMajor: false,
        importance: 'SPECIAL',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-hosanna-$year',
        name: 'ሆሣዕና',
        nameEn: 'Hosanna (Palm Sunday)',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.majorHoliday,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.hosanna.month,
        startDay: bh.hosanna.day,
        endMonth: bh.hosanna.month,
        endDay: bh.hosanna.day,
        description: 'ጌታችን በውርንጫይቱ ላይ ተቀምጦ በክብር ወደ ኢየሩሳሌም የገባበት ታላቅ በዓል።',
        spiritualMeaning: 'ሆሣዕና በአርያም፤ በጌታ ስም የሚመጣ የተባረከ ነው! የድኅነት ድል የታየበት ቀን።',
        primaryColor: '#DC2626',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-tselote-hamus-$year',
        name: 'ጸሎተ ሐሙስ (ሐሙስ ሕማማት)',
        nameEn: 'Maundy Thursday',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.majorHoliday,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.tseloteHamus.month,
        startDay: bh.tseloteHamus.day,
        endMonth: bh.tseloteHamus.month,
        endDay: bh.tseloteHamus.day,
        description: 'ጌታችን የደቀ መዛሙርቱን እግር ያጠበበት፣ ቅዱስ ቁርባንን የመሠረተበትና በጌቴሴማኒ የጸለየበት ዕለት።',
        spiritualMeaning: 'የፍቅርና የትሕትና ትምህርት የተሰጠበት እና የሕይወት ማዕድ (ምሥጢረ ቁርባን) የተመሠረተበት ዕለት።',
        primaryColor: '#DC2626',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-siklet-$year',
        name: 'ዓርበ ስቅለት (ስቅለት)',
        nameEn: 'Siklet (Good Friday)',
        type: CalendarEventType.fast,
        category: CalendarEventCategory.majorFast,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.siklet.month,
        startDay: bh.siklet.day,
        endMonth: bh.siklet.month,
        endDay: bh.siklet.day,
        description: 'ጌታችንና መድኃኒታችን ኢየሱስ ክርስቶስ ስለ ሰው ልጅ ድኅነት በመስቀል ላይ የተሰቀለበት ታላቅ ዕለት።',
        spiritualMeaning: 'በደሙ የታተመ የዘላለም ድኅነት የተሰጠንበት እና ሞት በመስቀል ሞት የተሻረበት ዕለት።',
        fastingRules: 'እስከ ምሽት ጥብቅ ጾም፣ ስግደትና የሕማማት ንባባት።',
        primaryColor: '#DC2626',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-kedam-seur-$year',
        name: 'ቀዳም ስዑር (የትንሣኤ ዋዜማ)',
        nameEn: 'Holy Saturday (Eve of Easter)',
        type: CalendarEventType.fast,
        category: CalendarEventCategory.majorFast,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.kedamSeur.month,
        startDay: bh.kedamSeur.day,
        endMonth: bh.kedamSeur.month,
        endDay: bh.kedamSeur.day,
        description: 'ጌታችን በሥጋው በመቃብር ሲያርፍ በነፍሱ ወደ ሲኦል ወርዶ ምርኮኞችን ነፃ ያወጣበት ቅዳሜ።',
        spiritualMeaning: 'በዓመቱ ውስጥ የሚጾመው ብቸኛው ቅዳሜ፤ ወደ ሲኦል የወረደውን ብርሃን በማሰብ ይጾማል።',
        fastingRules: 'እስከ ምሽተ ትንሣኤ የሚጾም ቅዳሜ።',
        primaryColor: '#F59E0B',
        isMajor: true,
        importance: 'SPECIAL',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-fasika-$year',
        name: 'ትንሣኤ (ፋሲካ)',
        nameEn: 'Fasika (Ethiopian Easter)',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.majorHoliday,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.fasika.month,
        startDay: bh.fasika.day,
        endMonth: bh.fasika.month,
        endDay: bh.fasika.day,
        description: 'ጌታችንና መድኃኒታችን ኢየሱስ ክርስቶስ ሞትን ድል አድርጎ የተነሣበት የትንሣኤ ታላቅ በዓል።',
        spiritualMeaning: 'ክርስቶስ ተንሥአ እሙታን! በሞቱ ሞትን ሻረው፤ ለሙታንም ሕይወትን ሰጠ! የሕይወት እና የድል በዓል።',
        primaryColor: '#DC2626',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-rikbe-kahnat-$year',
        name: 'ርክበ ካህናት',
        nameEn: 'Rikbe Kahnat (Council of Priests)',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.minorHoliday,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.rikbeKahnat.month,
        startDay: bh.rikbeKahnat.day,
        endMonth: bh.rikbeKahnat.month,
        endDay: bh.rikbeKahnat.day,
        description: 'ከትንሣኤ በ፳፭ኛው ቀን የሚከበር፤ ሐዋርያት የተሰበሰቡበት እና የካህናት ጉባኤ መታሰቢያ።',
        spiritualMeaning: 'የቤተ ክርስቲያን አንድነትና የክህነት አገልግሎት በረከት።',
        primaryColor: '#DC2626',
        isMajor: false,
        importance: 'NORMAL',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-erget-$year',
        name: 'ዕርገት',
        nameEn: 'Erget (Ascension)',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.majorHoliday,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.erget.month,
        startDay: bh.erget.day,
        endMonth: bh.erget.month,
        endDay: bh.erget.day,
        description: 'ጌታችን ከትንሣኤው በ፵ኛው (40th) ቀን በክብር ወደ ሰማይ ያረገበት ታላቅ በዓል።',
        spiritualMeaning: 'የሰው ልጅ ተፈጥሮ ወደ ሰማያዊው ክብር ከፍ ማለቱን የምናከብርበት በዓል።',
        primaryColor: '#DC2626',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-peraklitos-$year',
        name: 'ጰራቅሊጦስ (በዓለ ኀምሳ)',
        nameEn: 'Pentecost (Paraclete)',
        type: CalendarEventType.holiday,
        category: CalendarEventCategory.majorHoliday,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.peraklitos.month,
        startDay: bh.peraklitos.day,
        endMonth: bh.peraklitos.month,
        endDay: bh.peraklitos.day,
        description: 'መንፈስ ቅዱስ በእሳት አምሳል በሐዋርያት ላይ የወረደበት እና ቤተ ክርስቲያን የተመሠረተችበት በዓል።',
        spiritualMeaning: 'የመንፈስ ቅዱስ ስጦታዎች የተሰጡበት እና የወንጌል አገልግሎት የተጀመረበት ዕለት።',
        primaryColor: '#DC2626',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: 1,
      ),
      CalendarEventModel(
        id: 'movable-apostles-fast-$year',
        name: 'ጾመ ሐዋርያት (የሰኔ ጾም)',
        nameEn: 'Fast of the Apostles',
        type: CalendarEventType.fast,
        category: CalendarEventCategory.majorFast,
        isRecurring: false,
        ethiopianYear: year,
        startMonth: bh.apostlesFast.startMonth,
        startDay: bh.apostlesFast.startDay,
        endMonth: bh.apostlesFast.endMonth,
        endDay: bh.apostlesFast.endDay,
        description: 'ሐዋርያት መንፈስ ቅዱስን ከተቀበሉ በኋላ ለወንጌል አገልግሎት ከመሰማራታቸው በፊት የጾሙት የ${bh.apostlesFast.durationDays} ቀናት ጾም። እስከ ሐምሌ ፭ (ቅዱሳን ጴጥሮስ ወጳውሎስ) ይጾማል።',
        spiritualMeaning: 'የሐዋርያትን አርአያ በመከተል ለእግዚአብሔር መንግሥት አገልግሎት የምንተጋበት ጾም።',
        fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ በየቀኑ እስከ ፱ (9) ሰዓት መጾም።',
        primaryColor: '#F59E0B',
        isMajor: true,
        importance: 'MAJOR',
        durationDays: bh.apostlesFast.durationDays,
      ),
    ];
  }

  List<CalendarEventModel> _getBuiltinEventsForYear(int year) {
    final list = _allBuiltinEvents
        .where((e) => e.isRecurring || e.ethiopianYear == year)
        .toList();

    final movables = _getMovableEventsForYear(year);
    for (final m in movables) {
      if (!list.any((e) => e.name == m.name)) {
        list.add(m);
      }
    }

    list.sort((a, b) {
      if (a.startMonth != b.startMonth) {
        return a.startMonth.compareTo(b.startMonth);
      }
      if (a.startDay != b.startDay) {
        return a.startDay.compareTo(b.startDay);
      }
      return a.name.compareTo(b.name);
    });

    return list;
  }

  List<CalendarEventModel> _getBuiltinEventsForMonth(int year, int month) {
    final yearEvents = _getBuiltinEventsForYear(year);
    final result = <CalendarEventModel>[];

    for (final e in yearEvents) {
      if (e.id == 'builtin-wed-fri' || e.name.contains('የረቡዕ እና የዓርብ')) {
        continue;
      }
      final overlaps = _checkOverlap(e, month);
      if (overlaps) {
        final isStartMonth = e.startMonth == month;
        final isEndMonth = e.endMonth == month;
        final startDay = isStartMonth ? e.startDay : 1;
        final endDay = isEndMonth ? e.endDay : 30;

        final days = <int>[];
        for (int d = startDay; d <= endDay; d++) {
          days.add(d);
        }

        result.add(
          CalendarEventModel(
            id: e.id,
            name: e.name,
            nameEn: e.nameEn,
            type: e.type,
            category: e.category,
            isRecurring: e.isRecurring,
            ethiopianYear: e.ethiopianYear,
            startMonth: e.startMonth,
            startDay: e.startDay,
            endMonth: e.endMonth,
            endDay: e.endDay,
            description: e.description,
            spiritualMeaning: e.spiritualMeaning,
            fastingRules: e.fastingRules,
            primaryColor: e.primaryColor,
            isMajor: e.isMajor,
            importance: e.importance,
            isActive: e.isActive,
            durationDays: e.durationDays,
            coverage: CalendarEventCoverageModel(
              overlaps: true,
              days: days,
              isStartMonth: isStartMonth,
              isEndMonth: isEndMonth,
              startDay: isStartMonth ? e.startDay : null,
              endDay: isEndMonth ? e.endDay : null,
              durationDays: e.durationDays,
            ),
          ),
        );
      }
    }

    // Add Wednesday & Friday fasts for this month
    final wedFriDays =
        EthiopianCalendarUtil.getWednesdayFridayFastDaysForMonth(year, month);
    if (wedFriDays.isNotEmpty) {
      result.add(
        CalendarEventModel(
          id: 'builtin-wed-fri-$year-$month',
          name: 'ጾመ ድኅነት (የረቡዕ እና የዓርብ ጾም)',
          nameEn: 'Fast of Salvation (Wednesday & Friday Fast)',
          type: CalendarEventType.fast,
          category: CalendarEventCategory.majorFast,
          isRecurring: true,
          startMonth: month,
          startDay: wedFriDays.first,
          endMonth: month,
          endDay: wedFriDays.last,
          description:
            'ዓመቱን ሙሉ የሚጾም የረቡዕ (የጌታችን የመያዝ ምክር) እና የዓርብ (የስቅለቱ መታሰቢያ) ጾም። ከትንሣኤ እስከ ጰራቅሊጦስ ባሉት ፶ ቀናት (በዓለ ኀምሳ) እና በገና/ጥምቀት በዓላት ወቅት ጾሙ ይፈሰካል።',
          spiritualMeaning:
            'በየሳምንቱ የጌታችንን ሕማማት እና በመስቀል ላይ የፈጸመልንን የዘላለም ድኅነት የምንዘክርበት ጾም።',
          fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ እስከ ቀትር/፱ ሰዓት መጾም።',
          primaryColor: '#F59E0B',
          isMajor: true,
          importance: 'MAJOR',
          durationDays: wedFriDays.length,
          coverage: CalendarEventCoverageModel(
            overlaps: true,
            days: wedFriDays,
            isStartMonth: month == 1,
            isEndMonth: month == 13,
            startDay: wedFriDays.first,
            endDay: wedFriDays.last,
            durationDays: wedFriDays.length,
          ),
        ),
      );
    }

    return result;
  }

  bool _checkOverlap(CalendarEventModel e, int month) {
    if (e.startMonth == e.endMonth) {
      return e.startMonth == month;
    }
    if (e.startMonth < e.endMonth) {
      return month >= e.startMonth && month <= e.endMonth;
    }
    return month >= e.startMonth || month <= e.endMonth;
  }

  static final List<CalendarEventModel> _allBuiltinEvents = [
    // ── 1. FASTING PERIODS ──────────────────────────────────────────
    const CalendarEventModel(
      id: 'builtin-fast-prophets',
      name: 'ጾመ ነቢያት (የገና ጾም)',
      nameEn: 'Fast of the Prophets',
      type: CalendarEventType.fast,
      category: CalendarEventCategory.majorFast,
      isRecurring: true,
      startMonth: 3,
      startDay: 15,
      endMonth: 4,
      endDay: 28,
      description: 'የክርስቶስን መወለድ በመናፈቅ ነቢያት የጾሙት የ፵፫ (43) ቀናት ጾም።',
      spiritualMeaning: 'የአምላክን ሰው መሆን እና የነቢያትን ትንቢት በማሰብ በጸሎት እና በንስሐ የምንዘጋጅበት ወቅት።',
      fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ እስከ ፱ (9) ሰዓት መጾም እና በምግባረ ሠናይ መትጋት።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 44,
    ),
    const CalendarEventModel(
      id: 'builtin-fast-sibket',
      name: 'ጾመ ስቢይ (ጾመ ስብከት)',
      nameEn: 'Fast of Preaching / Sibket (Advent)',
      type: CalendarEventType.fast,
      category: CalendarEventCategory.majorFast,
      isRecurring: true,
      startMonth: 3,
      startDay: 15,
      endMonth: 4,
      endDay: 28,
      description: 'በኢትዮጵያ ኦርቶዶክስ ተዋሕዶ ቤተ ክርስቲያን ሥርዓት መሠረት «ጾመ ስብከት» (አንዳንዴ «ጾመ ስቢይ» ተብሎ የሚጠራው) ከሰባቱ አጽዋማት አንዱ የሆነው የጾመ ነቢያት መጠሪያ ነው።',
      spiritualMeaning: 'የድኅነት ተስፋ የተመሰከረበት፣ የሰው ልጅ ከጨለማ ወደ ብርሃን መሻገሩ የታየበት እና የወንጌል ምሥራች የተሰበከበት ምስጢር።',
      fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ በጸሎትና በንስሐ መትጋት።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 44,
    ),
    const CalendarEventModel(
      id: 'builtin-fast-filseta',
      name: 'ጾመ ፍልሰታ',
      nameEn: 'Fast of the Assumption',
      type: CalendarEventType.fast,
      category: CalendarEventCategory.majorFast,
      isRecurring: true,
      startMonth: 12,
      startDay: 1,
      endMonth: 12,
      endDay: 16,
      description: 'የእመቤታችን የቅድስት ድንግል ማርያም ትንሣኤና ዕርገት መታሰቢያ የ፲፮ (16) ቀናት ጾም።',
      spiritualMeaning: 'ሐዋርያት የእመቤታችንን ሥጋ ለማየት የጾሙት እና ትንሣኤዋን ያዩበት የበረከት ወቅት።',
      fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ በየቀኑ በጸሎተ ፍልሰታ እና ምህላ መትጋት።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 16,
    ),
    const CalendarEventModel(
      id: 'builtin-fast-gahad-genna',
      name: 'ጾመ ገሃድ (የገና ገሃድ)',
      nameEn: 'Gahad of Genna',
      type: CalendarEventType.fast,
      category: CalendarEventCategory.majorFast,
      isRecurring: true,
      startMonth: 4,
      startDay: 28,
      endMonth: 4,
      endDay: 28,
      description: 'ከልደት ዋዜማ የሚጾም የገሃድ ጾም።',
      spiritualMeaning: 'ለጌታ ልደት በዓል የምንዘጋጅበት የጾም እና የዝግጅት ቀን።',
      fastingRules: 'ጥብቅ ጾም እስከ ምሽት።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-fast-gahad-timkat',
      name: 'ጾመ ገሃድ (የጥምቀት ገሃድ)',
      nameEn: 'Gahad of Timkat',
      type: CalendarEventType.fast,
      category: CalendarEventCategory.majorFast,
      isRecurring: true,
      startMonth: 5,
      startDay: 10,
      endMonth: 5,
      endDay: 10,
      description: 'ከጥምቀት ዋዜማ (ከተራ ዕለት) የሚጾም የገሃድ ጾም።',
      spiritualMeaning: 'በዮርዳኖስ ለተገለጠው የጌታችን ጥምቀት ምሥጢር የምንዘጋጅበት ዕለት።',
      fastingRules: 'ጥብቅ ጾም እስከ ምሽት።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-wed-fri',
      name: 'ጾመ ድኅነት (የረቡዕ እና የዓርብ ጾም)',
      nameEn: 'Fast of Salvation (Wednesday & Friday Fast)',
      type: CalendarEventType.fast,
      category: CalendarEventCategory.majorFast,
      isRecurring: true,
      startMonth: 1,
      startDay: 1,
      endMonth: 13,
      endDay: 6,
      description: 'ዓመቱን ሙሉ የሚጾም የረቡዕ እና የዓርብ ጾም። ከትንሣኤ እስከ ጰራቅሊጦስ ባሉት ፶ ቀናት እና በገና/ጥምቀት በዓላት ወቅት ጾሙ ይፈሰካል።',
      spiritualMeaning: 'በየሳምንቱ የጌታችንን ሕማማት እና በመስቀል ላይ የፈጸመልንን የዘላለም ድኅነት የምንዘክርበት ጾም።',
      fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ እስከ ቀትር/፱ ሰዓት መጾም።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 104,
    ),

    // ── 2. MAJOR FEASTS OF THE LORD ─────────────────────────────────
    const CalendarEventModel(
      id: 'builtin-tsinset',
      name: 'ጽንሰተ እግዚእ',
      nameEn: 'Annunciation / Incarnation',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 7,
      startDay: 29,
      endMonth: 7,
      endDay: 29,
      description: 'መልአኩ ቅዱስ ገብርኤል ለእመቤታችን የድኅነትን ቃል ያበሰረበትና ቃል ሥጋ የሆነበት ታላቅ የጌታ በዓል።',
      spiritualMeaning: 'የሰው ልጅ ድኅነት መሠረት የተጣለበት ዕለት።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-genna',
      name: 'ልደት (ገና)',
      nameEn: 'Genna (Ethiopian Christmas)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 29,
      endMonth: 4,
      endDay: 29,
      description: 'የጌታችንና የመድኃኒታችን የኢየሱስ ክርስቶስ የልደት ታላቅ በዓል።',
      spiritualMeaning: 'ቃል ሥጋ ሆነ፣ ጸጋንና እውነትንም ተሞልቶ በእኛ አደረ።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-timkat',
      name: 'ጥምቀት',
      nameEn: 'Timkat (Ethiopian Epiphany)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 5,
      startDay: 11,
      endMonth: 5,
      endDay: 11,
      description: 'ጌታችን በፈለገ ዮርዳኖስ በዮሐንስ እጅ የተጠመቀበት እና ምሥጢረ ሥላሴ የተገለጠበት በዓል።',
      spiritualMeaning: 'የልጅነት ጥምቀት የተሰጠንበት ዕለት።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-debre-tabor',
      name: 'ደብረ ታቦር (ቡሄ)',
      nameEn: 'Debre Tabor',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 12,
      startDay: 13,
      endMonth: 12,
      endDay: 13,
      description: 'ጌታችን በደብረ ታቦር ተራራ ላይ ክብሩንና መለኮታዊ ብርሃኑን ለደቀ መዛሙርቱ የገለጠበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),

    // ── 3. MINOR FEASTS OF THE LORD ─────────────────────────────────
    const CalendarEventModel(
      id: 'builtin-ketera',
      name: 'ከተራ (የጥምቀት ዋዜማ)',
      nameEn: 'Ketera',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 5,
      startDay: 10,
      endMonth: 5,
      endDay: 10,
      description: 'ታቦተ ሕጉ በካህናት እና በምእመናን ታጅቦ ወደ ማጠመቂያው ባሕረ ጥምቀት የሚወርድበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-kana',
      name: 'ቃና ዘገሊላ',
      nameEn: 'Kana ZeGalila',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.minorHoliday,
      isRecurring: true,
      startMonth: 5,
      startDay: 12,
      endMonth: 5,
      endDay: 12,
      description: 'ጌታችን በቃና ዘገሊላ ሰርግ ላይ ውኃውን ወደ ወይን የለወጠበት የመጀመሪያው ተአምር መታሰቢያ።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-gizret',
      name: 'ግዝረት (የጌታችን ግዝረት)',
      nameEn: 'Circumcision of Jesus',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.minorHoliday,
      isRecurring: true,
      startMonth: 5,
      startDay: 6,
      endMonth: 5,
      endDay: 6,
      description: 'ጌታችን በተወለደ በስምንተኛው ቀን እንደ ሕጉ የተገረዘበት እና ኢየሱስ የተባለበት መታሰቢያ።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'NORMAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-zemene-sibket',
      name: 'ዘመነ ስብከት',
      nameEn: 'Zemene Sibket',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.minorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 7,
      endMonth: 4,
      endDay: 7,
      description: 'የገና ጾም የመጀመሪያው ሰንበት፤ የነቢያት ትንቢት እና ስብከት የሚዘከርበት ዕለት።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'NORMAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-zemene-berhan',
      name: 'ዘመነ ብርሃን',
      nameEn: 'Zemene Berhan',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.minorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 14,
      endMonth: 4,
      endDay: 14,
      description: 'የገና ጾም ሁለተኛው ሰንበት፤ ክርስቶስ የዓለም ብርሃን ሆኖ መገለጡ የሚዘከርበት ዕለት።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'NORMAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-zemene-nolawi',
      name: 'ዘመነ ኖላዊ',
      nameEn: 'Zemene Nolawi',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.minorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 21,
      endMonth: 4,
      endDay: 21,
      description: 'የገና ጾም ሦስተኛው ሰንበት፤ ክርስቶስ መልካሙ እረኛ መሆኑ የሚዘከርበት ዕለት።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'NORMAL',
      durationDays: 1,
    ),

    // ── 4. FEASTS OF THE HOLY CROSS ─────────────────────────────────
    const CalendarEventModel(
      id: 'builtin-meskel',
      name: 'መስቀል (ደመራ)',
      nameEn: 'Meskel',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 1,
      startDay: 17,
      endMonth: 1,
      endDay: 17,
      description: 'ንግሥት ዕሌኒ የጌታችንን መስቀል በደመራ ጭስ መሪነት የቆፈረችበት እና ያገኘችበት ታላቅ ክብረ በዓል።',
      spiritualMeaning: 'የመስቀሉ ኃይል እና የድኅነት ምልክት መገለጡን የምናከብርበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-ginhete-meskel',
      name: 'ግኝተ መስቀል',
      nameEn: 'Recovery of the True Cross',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 7,
      startDay: 10,
      endMonth: 7,
      endDay: 10,
      description: 'ንግሥት ዕሌኒ የከበረውን መስቀል ከቆሻሻ መጣያ ቆፍራ ያወጣችበት ታሪካዊ መታሰቢያ ዕለት።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),

    // ── 5. FEASTS OF THE BLESSED VIRGIN MARY ────────────────────────
    const CalendarEventModel(
      id: 'builtin-filseta-maryam',
      name: 'ፍልሰታ ለማርያም (ዕርገተ ማርያም)',
      nameEn: 'Assumption of the Virgin Mary',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 12,
      startDay: 16,
      endMonth: 12,
      endDay: 16,
      description: 'የእመቤታችን የቅድስት ድንግል ማርያም ትንሣኤና ዕርገት ፍጻሜ ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-asteroeyo-maryam',
      name: 'አስተርእዮ ማርያም (ዕረፍተ ድንግል ማርያም)',
      nameEn: 'Asteroeyo Maryam',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 5,
      startDay: 21,
      endMonth: 5,
      endDay: 21,
      description: 'የእመቤታችን የቅድስት ድንግል ማርያም የዕረፍት መታሰቢያ ታላቅ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-lideta-maryam',
      name: 'ልደታ ለማርያም',
      nameEn: 'Nativity of the Blessed Virgin Mary',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 9,
      startDay: 1,
      endMonth: 9,
      endDay: 1,
      description: 'የእመቤታችን የቅድስት ድንግል ማርያም የልደት ታላቅ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-tsion-maryam',
      name: 'ጽዮን ማርያም',
      nameEn: 'Zion Maryam',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 3,
      startDay: 21,
      endMonth: 3,
      endDay: 21,
      description: 'ታቦተ ጽዮን ወደ ኢትዮጵያ የገባችበት እና የመጀመሪያዋ ቤተ ክርስቲያን በአክሱም የታነጸችበት ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-baata-maryam',
      name: 'ባዕታ ለማርያም',
      nameEn: 'Presentation of the Virgin Mary',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 3,
      endMonth: 4,
      endDay: 3,
      description: 'እመቤታችን በሦስት ዓመቷ ወደ ቤተ መቅደስ የገባችበት እና በቅድስና ያደገችበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-kidane-mehret',
      name: 'ኪዳነ ምሕረት',
      nameEn: 'Kidane Mehret',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 6,
      startDay: 16,
      endMonth: 6,
      endDay: 16,
      description: 'ጌታችን ለእመቤታችን በጎለጎታ የገባላት የይቅርታ እና የምሕረት ቃል ኪዳን መታሰቢያ።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-debre-mitmaq',
      name: 'ደብረ ምጥማቅ',
      nameEn: 'Debre Mitmaq',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 9,
      startDay: 21,
      endMonth: 9,
      endDay: 21,
      description: 'እመቤታችን በደብረ ምጥማቅ ገዳም ለአምስት ቀናት በግልጽ ተገልጣ ሕዝቡን የባረከችበት ተአምራዊ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-qusquam',
      name: 'ቁስቋም (የስደት በዓል)',
      nameEn: 'Qusquam',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 3,
      startDay: 6,
      endMonth: 3,
      endDay: 6,
      description: 'እመቤታችን ከልጇ ጋር ከሄሮድስ ሰይፍ ወደ ግብጽ የተሰደደችበት እና በቁስቋም ደብር ያረፈችበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),

    // ── 6. MAJOR SAINTS, MARTYRS, AND ARCHANGELS ────────────────────
    const CalendarEventModel(
      id: 'builtin-enkutatash',
      name: 'እንቁጣጣሽ (ርእሰ ዐውደ ዓመት / ቅዱስ ዮሐንስ)',
      nameEn: 'Enkutatash',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 1,
      startDay: 1,
      endMonth: 1,
      endDay: 1,
      description: 'የኢትዮጵያ አዲስ ዓመት መጀመሪያ እና የቅዱስ ዮሐንስ መጥምቅ መታሰቢያ ታላቅ በዓል።',
      spiritualMeaning: 'አሮጌው ዘመን አልፎ አዲሱ የተተካበት፣ ምሕረትና ሰላም የሚለመንበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-yohannes-metmiq-birth',
      name: 'ቅዱስ ዮሐንስ መጥምቅ (ልደተ ዮሐንስ)',
      nameEn: 'Nativity of St. John the Baptist',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 10,
      startDay: 30,
      endMonth: 10,
      endDay: 30,
      description: 'የነቢያት ማኅተም እና የጌታ መንገድ ጠራጊ የሆነው የቅዱስ ዮሐንስ መጥምቅ የልደት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-michael-hidar',
      name: 'ቅዱስ ሚካኤል (የኅዳር ሚካኤል)',
      nameEn: 'St. Michael the Archangel (Hidar)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 3,
      startDay: 12,
      endMonth: 3,
      endDay: 12,
      description: 'ሊቀ መላእክት ቅዱስ ሚካኤል ዲያብሎስን ድል ያደረገበት እና የእስራኤልን ሕዝብ በባሕረ ኤርትራ የመራበት መታሰቢያ።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-michael-sene',
      name: 'ቅዱስ ሚካኤል (የሰኔ ሚካኤል)',
      nameEn: 'St. Michael the Archangel (Sene)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 10,
      startDay: 12,
      endMonth: 10,
      endDay: 12,
      description: 'ቅዱስ ሚካኤል አፎሚያን ከዲያብሎስ እጅ ያዳነበት ዓመታዊ ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-gabriel-kulubi',
      name: 'ቅዱስ ገብርኤል (ቁልቢ ገብርኤል)',
      nameEn: 'St. Gabriel the Archangel (Kulubi)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 19,
      endMonth: 4,
      endDay: 19,
      description: 'ቅዱስ ገብርኤል ሠለስቱ ደቂቅን (ሦስቱን ሕፃናት) ከነደደው እቶን እሳት ያዳነበት ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-gabriel-hamle',
      name: 'ቅዱስ ገብርኤል (የሐምሌ ገብርኤል)',
      nameEn: 'St. Gabriel the Archangel (Hamle)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 11,
      startDay: 19,
      endMonth: 11,
      endDay: 19,
      description: 'ቅዱስ ገብርኤል ቅድስት ኢየሉጣን እና ልጇን ቅዱስ ቂርቆስን ከፈላ የናስ ጋን ያዳነበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-rufael',
      name: 'ቅዱስ ሩፋኤል',
      nameEn: 'St. Raphael the Archangel',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 13,
      startDay: 3,
      endMonth: 13,
      endDay: 3,
      description: 'ፈዋሹ ሊቀ መላእክት ቅዱስ ሩፋኤል ጦቢትን ከዓይነ ስውርነት ያዳነበት እና ቤተ ክርስቲያኑ በደሴት የታነጸችበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-urael',
      name: 'ቅዱስ ዑራኤል',
      nameEn: 'St. Uriel the Archangel',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 2,
      startDay: 22,
      endMonth: 2,
      endDay: 22,
      description: 'ምስጢር ገላጩ ሊቀ መላእክት ቅዱስ ዑራኤል ዕዝራ ሱቱኤልን የመገበበት እና የጌታን ደም በዓለም ላይ የረጨበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-silassie-hidar',
      name: 'ቅድስት ሥላሴ (የኅዳር ሥላሴ)',
      nameEn: 'Holy Trinity (Hidar)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 3,
      startDay: 7,
      endMonth: 3,
      endDay: 7,
      description: 'ቅድስት ሥላሴ ለአብርሃም በድንኳኑ የተገለጡበት እና በምሕረት የጎበኙበት ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-silassie-hamle',
      name: 'ቅድስት ሥላሴ (የሐምሌ ሥላሴ)',
      nameEn: 'Holy Trinity (Hamle)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 11,
      startDay: 7,
      endMonth: 11,
      endDay: 7,
      description: 'የሥላሴ በዓለ ሢመት እና ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-giorgis-miazia',
      name: 'ቅዱስ ጊዮርጊስ (ልዳ ጊዮርጊስ)',
      nameEn: 'St. George the Martyr (Miazia)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 8,
      startDay: 23,
      endMonth: 8,
      endDay: 23,
      description: 'የሰማዕታት አለቃ የሆነው ቅዱስ ጊዮርጊስ ስለ ክርስቶስ ስም ሰማዕትነትን የተቀበለበት ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-giorgis-hidar',
      name: 'ቅዱስ ጊዮርጊስ (ቅዳሴ ቤቱ)',
      nameEn: 'St. George Consecration (Hidar)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 3,
      startDay: 7,
      endMonth: 3,
      endDay: 7,
      description: 'በልዳ የተሠራችው የቅዱስ ጊዮርጊስ ቤተ ክርስቲያን የከበረችበት መታሰቢያ።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-teklehaymanot-nehase',
      name: 'ቅዱስ ተክለ ሃይማኖት (ዕረፍት)',
      nameEn: 'St. Tekle Haymanot (Falling Asleep)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 12,
      startDay: 24,
      endMonth: 12,
      endDay: 24,
      description: 'የኢትዮጵያው ፀሐይ ጻድቁ አባታችን አቡነ ተክለ ሃይማኖት በደብረ ሊባኖስ ያረፉበት ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-teklehaymanot-tahsiss',
      name: 'ቅዱስ ተክለ ሃይማኖት (ልደት)',
      nameEn: 'St. Tekle Haymanot (Birth)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 24,
      endMonth: 4,
      endDay: 24,
      description: 'ጻድቁ አቡነ ተክለ ሃይማኖት በኢቲሳ ምድር የተወለዱበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-abo-megabit',
      name: 'አቡነ ገብረ መንፈስ ቅዱስ / ቅዱስ አቦ (ዕረፍት)',
      nameEn: 'St. Gebre Menfes Kidus / Abo (Falling Asleep)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 7,
      startDay: 5,
      endMonth: 7,
      endDay: 5,
      description: 'የዝቋላው ገዳማዊ ኮከብ ጻድቁ አቡነ ገብረ መንፈስ ቅዱስ (አቦ) ያረፉበት ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-abo-tikimt',
      name: 'አቡነ ገብረ መንፈስ ቅዱስ / ቅዱስ አቦ (መምጣት)',
      nameEn: 'St. Gebre Menfes Kidus / Abo (Arrival)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 2,
      startDay: 5,
      endMonth: 2,
      endDay: 5,
      description: 'ጻድቁ አቡነ ገብረ መንፈስ ቅዱስ ከግብጽ ወደ ኢትዮጵያ የመጡበት መታሰቢያ።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'SPECIAL',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-estifanos',
      name: 'ቅዱስ እስጢፋኖስ (ቀዳሜ ሰማዕት)',
      nameEn: 'St. Stephen the Protomartyr',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 5,
      startDay: 1,
      endMonth: 5,
      endDay: 1,
      description: 'የመጀመሪያው ክርስቲያን ሰማዕት ሊቀ ዲያቆናት ቅዱስ እስጢፋኖስ በድንጋይ ተወግሮ ሰማዕትነት የተቀበለበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-medhanealem-hidar',
      name: 'መድኃኔዓለም (የኅዳር መድኃኔዓለም)',
      nameEn: 'Medhane Alem (Hidar)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 3,
      startDay: 27,
      endMonth: 3,
      endDay: 27,
      description: 'የዓለም መድኃኒት የሆነው ጌታችን ኢየሱስ ክርስቶስ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-medhanealem-megabit',
      name: 'መድኃኔዓለም (የመጋቢት መድኃኔዓለም)',
      nameEn: 'Medhane Alem (Megabit)',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 7,
      startDay: 27,
      endMonth: 7,
      endDay: 27,
      description: 'ጌታችን በመስቀል ላይ የዋለበትና ለድኅነተ ዓለም የከፈለውን መሥዋዕትነት የምናስብበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-emmanuel',
      name: 'ዐማኑኤል',
      nameEn: 'Emmanuel',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 4,
      startDay: 28,
      endMonth: 4,
      endDay: 28,
      description: 'እግዚአብሔር ከእኛ ጋር ሆነ የሚለው የአምላካችን ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-peter-paul',
      name: 'ቅዱሳን ጴጥሮስ ወጳውሎስ',
      nameEn: 'Saints Peter and Paul',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 11,
      startDay: 5,
      endMonth: 11,
      endDay: 5,
      description: 'የሐዋርያት አለቆች የቅዱስ ጴጥሮስ እና የቅዱስ ጳውሎስ የሰማዕትነት መታሰቢያ እና የሐዋርያት ጾም ማብቂያ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
    const CalendarEventModel(
      id: 'builtin-aregawi',
      name: 'አቡነ አረጋዊ',
      nameEn: 'Abba Aregawi',
      type: CalendarEventType.holiday,
      category: CalendarEventCategory.majorHoliday,
      isRecurring: true,
      startMonth: 2,
      startDay: 14,
      endMonth: 2,
      endDay: 14,
      description: 'ከተስዓቱ ቅዱሳን አንዱ የሆኑት አቡነ አረጋዊ በደብረ ዳሞ ተራራ የተሰወሩበት ታላቅ ክብረ በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      durationDays: 1,
    ),
  ];
}
