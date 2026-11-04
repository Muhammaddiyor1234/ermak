// Unity o'quv markazi — ro'yxatdan o'tish ilovasi (Klassik ko'k va oq dizayn)
// pubspec.yaml ga qo'shing:
//   shared_preferences: ^2.2.3
//   url_launcher: ^6.3.0
//
// ANDROID: android/app/src/main/AndroidManifest.xml ichida <manifest> ichiga qo'shing:
//   <queries>
//     <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
//     <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
//   </queries>
// iOS: ios/Runner/Info.plist ichiga:
//   <key>LSApplicationQueriesSchemes</key><array><string>tel</string><string>sms</string></array>
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ───────────────────────── RANGLAR / KURSLAR (KLASSIK KO'K VA OQ) ─────────────────────────
const kPrimary = Color(0xFF1D4ED8); // Klassik Qirollik Ko'ki (Royal Blue)
const kPrimaryDark = Color(0xFF1E3A8A); // Chuqur To'q Ko'k (Navy Blue)
const kAccentBlue = Color(0xFF3B82F6); // Mayin Ko'k Accent
const kIceWhite = Color(0xFFF8FAFC); // Mayin Oq Fon
const kGreen = Color(0xFF059669); // Klassik Zümrad (To'lagan)
const kRed = Color(0xFFDC2626); // Klassik Qizil (To'lamagan)
const kYellow = Color(0xFFD97706); // SMS tugmasi uchun sariq

const kGradient = LinearGradient(
  colors: [kPrimaryDark, kPrimary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class Course {
  final String name;
  final IconData icon;
  final Color color;
  const Course(this.name, this.icon, this.color);
}

// Yo'nalishlar (Klassik ko'k va uning garmonik tuslari)
const kCourses = [
  Course('Ingliz tili', Icons.record_voice_over_outlined, Color(0xFF1D4ED8)),
  Course('Buxgalteriya', Icons.account_balance_wallet_outlined, Color(0xFF0D9488)),
  Course('IT', Icons.terminal_outlined, Color(0xFF0284C7)),
  Course("O'qituvchilikka tayyorlov", Icons.cast_for_education_outlined, Color(0xFF4338CA)),
];

// Hafta kunlari (1 = Dushanba ... 7 = Yakshanba)
const kDays = ['Du', 'Se', 'Chor', 'Pay', 'Ju', 'Sha', 'Yak'];

Course courseOf(String name) =>
    kCourses.firstWhere((c) => c.name == name, orElse: () => kCourses.first);

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

String fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String get currentMonthUz {
  final months = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentabr', 'Oktyabr', 'Noyabr', 'Dekabr'
  ];
  return months[DateTime.now().month - 1];
}

String fmtMoney(int amount) {
  final str = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buf.write(' ');
    }
    buf.write(str[i]);
  }
  return '${buf.toString()} so\'m';
}

Color daysBadgeColor(int days) {
  if (days < 0) return const Color(0xFFDC2626);
  if (days <= 3) return const Color(0xFFD97706);
  return const Color(0xFF059669);
}

IconData daysBadgeIcon(int days) {
  if (days < 0) return Icons.warning_amber_rounded;
  if (days <= 3) return Icons.alarm_rounded;
  return Icons.check_circle_outline_rounded;
}

String daysBadgeText(int days, int payDay, String monthName) {
  if (days < 0) {
    return "To'lov muddati ($payDay-$monthName) ${days.abs()} kun oldin o'tgan!";
  }
  if (days == 0) {
    return "🚨 BUGUN TO'LOVNING SO'NGGI KUNI ($payDay-$monthName)!";
  }
  if (days <= 3) {
    return "⏳ To'lov muddatiga ($payDay-$monthName) shoshiling: $days kun qoldi!";
  }
  return "📅 $monthName oyining $payDay-sanasigacha to'lov qilish kerak ($days kun qoldi)";
}

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color cardColor(BuildContext c) =>
    isDark(c) ? const Color(0xFF1E293B) : Colors.white;

Color tx(BuildContext c) => isDark(c) ? Colors.white : const Color(0xFF0F172A);
Color tx2(BuildContext c) => isDark(c) ? Colors.white54 : const Color(0xFF64748B);

BoxDecoration cardDeco(BuildContext c, {double r = 20}) => BoxDecoration(
  color: cardColor(c),
  borderRadius: BorderRadius.circular(r),
  border: Border.all(
    color: isDark(c) ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: isDark(c)
          ? Colors.black.withOpacity(0.25)
          : const Color(0xFF1E3A8A).withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ],
);

InputDecoration fieldDeco(BuildContext context, String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark(context) ? Colors.white60 : const Color(0xFF64748B)),
      prefixIcon: Icon(icon, color: kPrimary),
      filled: true,
      fillColor: isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kRed, width: 1.5),
      ),
    );

void snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    content: Text(text),
  ));
}

// ───────────────────────── MODEL ─────────────────────────
class Student {
  final String id;
  String ism, familiya, tel, ota, kurs;
  bool paid;
  DateTime created;

  Student({
    required this.id,
    required this.ism,
    required this.familiya,
    required this.tel,
    required this.ota,
    required this.kurs,
    this.paid = false,
    DateTime? created,
  }) : created = created ?? DateTime.now();

  String get fullName => '$ism $familiya';
  String get initials =>
      '${ism.isNotEmpty ? ism[0] : ''}${familiya.isNotEmpty ? familiya[0] : ''}'
          .toUpperCase();

  Map<String, dynamic> toJson() => {
    'id': id,
    'ism': ism,
    'familiya': familiya,
    'tel': tel,
    'ota': ota,
    'kurs': kurs,
    'paid': paid,
    'created': created.toIso8601String(),
  };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
    id: j['id'],
    ism: j['ism'],
    familiya: j['familiya'],
    tel: j['tel'],
    ota: j['ota'],
    kurs: j['kurs'],
    paid: j['paid'] ?? false,
    created: DateTime.tryParse(j['created'] ?? ''),
  );
}

class Group {
  final String id;
  String name, teacher, kurs;
  List<String> studentIds;
  List<int> days; // 1..7
  int hour, minute;

  Group({
    required this.id,
    required this.name,
    required this.teacher,
    required this.kurs,
    List<String>? studentIds,
    List<int>? days,
    this.hour = 15,
    this.minute = 0,
  })  : studentIds = studentIds ?? [],
        days = days ?? [];

  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get daysText {
    final d = [...days]..sort();
    return d.map((e) => kDays[e - 1]).join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'kurs': kurs,
    'studentIds': studentIds,
    'days': days,
    'hour': hour,
    'minute': minute,
  };

  factory Group.fromJson(Map<String, dynamic> j) => Group(
    id: j['id'],
    name: j['name'],
    teacher: j['teacher'] ?? '',
    kurs: j['kurs'] ?? kCourses.first.name,
    studentIds: List<String>.from(j['studentIds'] ?? []),
    days: List<int>.from(j['days'] ?? []),
    hour: j['hour'] ?? 15,
    minute: j['minute'] ?? 0,
  );
}

// ───────────────────────── HOLAT (STATE) ─────────────────────────
class AppState extends ChangeNotifier {
  List<Student> students = [];
  List<Group> groups = [];
  List<String> teachers = [];
  List<String> log = [];
  bool dark = false;
  bool remind = true;
  int remindMin = 60;
  bool lessonRemind = true; // dars oldidan eslatma
  int payDay = 10; // oylik to'lov muddati (oyning nechinchi kuni)
  int monthlyFee = 400000; // standart oylik to'lov summasi (400 000 so'm)
  String centerName = 'Unity';
  Timer? _timer;
  Timer? _lessonTimer;
  final Set<String> _fired = {};
  SharedPreferences? _p;

  static const lessonLeadMin = 10; // dars boshlanishidan necha daqiqa oldin

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p!.getString('students_v2');
    if (raw == null) {
      students = [];
    } else {
      students = (jsonDecode(raw) as List)
          .map((e) => Student.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final rawG = _p!.getString('groups_v1');
    if (rawG == null) {
      groups = [];
    } else {
      groups = (jsonDecode(rawG) as List)
          .map((e) => Group.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    teachers = _p!.getStringList('teachers_v1') ?? [];
    dark = _p!.getBool('dark') ?? false;
    remind = _p!.getBool('remind') ?? true;
    remindMin = _p!.getInt('remindMin') ?? 60;
    lessonRemind = _p!.getBool('lessonRemind') ?? true;
    payDay = _p!.getInt('payDay') ?? 10;
    monthlyFee = _p!.getInt('monthlyFee') ?? 400000;
    centerName = _p!.getString('center') ?? 'Unity';
    log = _p!.getStringList('log') ?? [];
    _schedule();
    _lessonTimer?.cancel();
    _lessonTimer = Timer.periodic(const Duration(seconds: 30), (_) => checkLessons());
    if (remind) {
      Future.delayed(const Duration(seconds: 2), () => remindNow());
    }
    Future.delayed(const Duration(seconds: 4), () => checkLessons());
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setString('students_v2', jsonEncode(students.map((e) => e.toJson()).toList()));
    p.setString('groups_v1', jsonEncode(groups.map((e) => e.toJson()).toList()));
    p.setStringList('teachers_v1', teachers);
    p.setBool('dark', dark);
    p.setBool('remind', remind);
    p.setInt('remindMin', remindMin);
    p.setBool('lessonRemind', lessonRemind);
    p.setInt('payDay', payDay);
    p.setInt('monthlyFee', monthlyFee);
    p.setString('center', centerName);
    p.setStringList('log', log);
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  // — o'quvchilar —
  void add(Student s) {
    students.insert(0, s);
    _changed();
  }

  void update() => _changed();

  void remove(String id) {
    students.removeWhere((e) => e.id == id);
    for (final g in groups) {
      g.studentIds.remove(id);
    }
    _changed();
  }

  void togglePaid(Student s) {
    s.paid = !s.paid;
    _changed();
  }

  void resetPayments() {
    for (final s in students) {
      s.paid = false;
    }
    _changed();
  }

  void clearAll() {
    students.clear();
    groups.clear();
    _changed();
  }

  Student? byId(String id) {
    for (final s in students) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Student> byCourse(String kurs) =>
      students.where((s) => s.kurs == kurs).toList();

  // — guruhlar —
  Group? groupById(String id) {
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  List<Student> membersOf(Group g) =>
      g.studentIds.map((id) => byId(id)).whereType<Student>().toList();

  void addGroup(Group g) {
    groups.insert(0, g);
    _changed();
  }

  void removeGroup(String id) {
    groups.removeWhere((g) => g.id == id);
    _changed();
  }

  // — o'qituvchilar —
  void addTeacher(String t) {
    t = t.trim();
    if (t.isEmpty || teachers.contains(t)) return;
    teachers.add(t);
    _changed();
  }

  void removeTeacher(String t) {
    teachers.remove(t);
    _changed();
  }

  // — sozlamalar —
  void setDark(bool v) {
    dark = v;
    _changed();
  }

  void setRemind(bool v) {
    remind = v;
    _schedule();
    _changed();
  }

  void setRemindMin(int v) {
    remindMin = v;
    _schedule();
    _changed();
  }

  void setLessonRemind(bool v) {
    lessonRemind = v;
    _changed();
  }

  void setPayDay(int v) {
    payDay = v;
    _changed();
  }

  void setMonthlyFee(int v) {
    monthlyFee = v;
    _changed();
  }

  void setCenter(String v) {
    centerName = v.trim().isEmpty ? 'Unity' : v.trim();
    _changed();
  }

  void clearLog() {
    log.clear();
    _changed();
  }

  void note(String msg) {
    _addLog(msg);
    _changed();
  }

  int get daysUntilDeadline {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(now.year, now.month, payDay);
    return target.difference(today).inDays;
  }

  // Oylik to'lov muddati: shu oyning payDay-kuni, o'tib ketgan bo'lsa — keyingi oyniki
  DateTime get deadline {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    var d = DateTime(n.year, n.month, payDay);
    if (d.isBefore(today)) d = DateTime(n.year, n.month + 1, payDay);
    return d;
  }

  // — eslatma —
  void _schedule() {
    _timer?.cancel();
    if (remind) {
      _timer = Timer.periodic(Duration(minutes: remindMin), (_) => remindNow());
    }
  }

  void remindNow({bool manual = false}) {
    final unpaid = students.where((s) => !s.paid).toList();
    if (unpaid.isEmpty) {
      if (manual) {
        Toaster.show("Hammasi joyida 🎉", "Barcha o'quvchilar to'lov qilgan", ok: true);
      }
      return;
    }
    const maxShow = 5;
    for (final s in unpaid.take(maxShow)) {
      final msg = "${s.fullName} (${s.kurs}) to'lov qilmadi";
      Toaster.show("To'lov eslatmasi", msg);
      _addLog(msg);
    }
    if (unpaid.length > maxShow) {
      final msg = "Va yana ${unpaid.length - maxShow} ta o'quvchi to'lov qilmagan";
      Toaster.show("To'lov eslatmasi", msg);
      _addLog(msg);
    }
    _changed();
  }

  // Dars boshlanishidan 10 daqiqa oldin: to'lamagan o'quvchilar haqida ogohlantirish
  void checkLessons() {
    if (!lessonRemind) return;
    final now = DateTime.now();
    var any = false;
    for (final g in groups) {
      if (!g.days.contains(now.weekday)) continue;
      final start = DateTime(now.year, now.month, now.day, g.hour, g.minute);
      final diff = start.difference(now).inSeconds;
      if (diff < 0 || diff > lessonLeadMin * 60) continue;
      final key = '${g.id}-${now.year}-${now.month}-${now.day}';
      if (_fired.contains(key)) continue;
      _fired.add(key);
      final unpaid = membersOf(g).where((s) => !s.paid).toList();
      const maxShow = 5;
      for (final s in unpaid.take(maxShow)) {
        final msg =
            "${s.fullName} ni darsga kirgizmang, u oylik to'lovni to'lamagan (${g.name}, ${g.timeText})";
        Toaster.show("Darsga kiritmang!", msg);
        _addLog(msg);
        any = true;
      }
      if (unpaid.length > maxShow) {
        final msg =
            "${g.name}: yana ${unpaid.length - maxShow} ta o'quvchi to'lov qilmagan, darsga kirgizmang";
        Toaster.show("Darsga kiritmang!", msg);
        _addLog(msg);
        any = true;
      }
    }
    if (any) _changed();
  }

  void _addLog(String msg) {
    log.insert(0, '${fmtDate(DateTime.now())} ${fmtTime(DateTime.now())}  •  $msg');
    if (log.length > 40) log.removeRange(40, log.length);
  }
}

final app = AppState();
final navKey = GlobalKey<NavigatorState>();

// ───────────────────────── BILDIRISHNOMA (TOAST) ─────────────────────────
class _ToastData {
  final String title, body;
  final bool ok;
  _ToastData(this.title, this.body, this.ok);
}

class Toaster {
  static final List<_ToastData> _queue = [];
  static bool _busy = false;

  static void show(String title, String body, {bool ok = false}) {
    _queue.add(_ToastData(title, body, ok));
    _next();
  }

  static Future<void> _next() async {
    if (_busy || _queue.isEmpty) return;
    final overlay = navKey.currentState?.overlay;
    if (overlay == null) return;
    _busy = true;
    final d = _queue.removeAt(0);
    final entry = OverlayEntry(builder: (_) => _ToastWidget(d));
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 4200));
    entry.remove();
    _busy = false;
    _next();
  }
}

class _ToastWidget extends StatelessWidget {
  final _ToastData d;
  const _ToastWidget(this.d);

  @override
  Widget build(BuildContext context) {
    final color = d.ok ? kGreen : kRed;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 14,
      right: 14,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (c, v, child) => Transform.translate(
          offset: Offset(0, -70 * (1 - v)),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark(context) ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    d.ok ? Icons.check_circle_outline : Icons.notifications_active_outlined,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.body,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark(context) ? Colors.white70 : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── CALL / SMS ─────────────────────────
String _cleanNumber(String n) {
  final trimmed = n.trim();
  final hasPlus = trimmed.startsWith('+');
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return hasPlus ? '+$digits' : digits;
}

Future<String?> pickNumber(BuildContext context, Student s, String title) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: cardColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx(ctx))),
            const SizedBox(height: 2),
            Text(s.fullName, style: TextStyle(color: tx2(ctx))),
            const SizedBox(height: 12),
            _NumTile(Icons.person_outline, "O'quvchining o'z raqami", s.tel),
            _NumTile(Icons.family_restroom_outlined, 'Ota yoki ona raqami', s.ota),
          ],
        ),
      ),
    ),
  );
}

class _NumTile extends StatelessWidget {
  final IconData icon;
  final String label, number;
  const _NumTile(this.icon, this.label, this.number);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDeco(context, r: 16),
      child: ListTile(
        leading: Icon(icon, color: kPrimary),
        title: Text(label, style: TextStyle(fontSize: 12.5, color: tx2(context))),
        subtitle: Text(
          number,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tx(context)),
        ),
        onTap: () => Navigator.pop(context, number),
      ),
    );
  }
}

Future<void> callStudent(BuildContext context, Student s) async {
  final number = await pickNumber(context, s, "Qaysi raqamga qo'ng'iroq qilamiz?");
  if (number == null || number.trim().isEmpty) return;
  final clean = _cleanNumber(number);
  final uri = Uri.parse('tel:$clean');

  bool launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {}

  if (!launched) {
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  if (!launched) {
    await Clipboard.setData(ClipboardData(text: clean));
    if (context.mounted) {
      snack(
        context,
        "Qo'ng'iroq ochilmadi (Brauzer/PC). Raqam nusxalandi: $clean",
      );
    }
  }
}

Future<void> smsStudent(BuildContext context, Student s) async {
  final number = await pickNumber(context, s, 'Qaysi raqamga SMS yuboramiz?');
  if (number == null || number.trim().isEmpty) return;
  final clean = _cleanNumber(number);
  final text =
      "${s.ism}, iltimos ${fmtDate(app.deadline)} gacha oylik to'lovni to'lang, aks holda darsga kiritilmaysiz.";
  final uri = Uri.parse('sms:$clean?body=${Uri.encodeComponent(text)}');

  bool launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {}

  if (!launched) {
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  if (launched) {
    app.note("SMS: ${s.fullName} ga to'lov eslatmasi yuborildi");
  } else {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      snack(context, "SMS ilovasi ochilmadi. Xabar matni nusxalandi!");
    }
  }
}

class ContactButtons extends StatelessWidget {
  final Student s;
  final double height;
  const ContactButtons(this.s, {super.key, this.height = 40});

  Widget _btn(IconData icon, String label, Color c, VoidCallback onTap) {
    final r = BorderRadius.circular(14);
    return Material(
      color: c.withOpacity(0.10), // shaffof fon
      shape: RoundedRectangleBorder(
        borderRadius: r,
        side: BorderSide(color: c.withOpacity(0.55), width: 1.2),
      ),
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _btn(Icons.call_outlined, 'Call', kPrimary, () => callStudent(context, s))),
        const SizedBox(width: 10),
        Expanded(child: _btn(Icons.sms_outlined, 'SMS', kYellow, () => smsStudent(context, s))),
      ],
    );
  }
}

// ───────────────────────── MAIN ─────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const UnityApp());
}

class UnityApp extends StatelessWidget {
  const UnityApp({super.key});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      primaryColor: kPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        primary: kPrimary,
        secondary: kAccentBlue,
        surface: dark ? const Color(0xFF1E293B) : Colors.white,
        brightness: b,
      ),
      scaffoldBackgroundColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: dark ? const Color(0xFF1E293B) : kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'Unity',
        debugShowCheckedModeBanner: false,
        navigatorKey: navKey,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: app.dark ? ThemeMode.dark : ThemeMode.light,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _i,
        children: [
          DashboardPage(onNavigateToPayments: () => setState(() => _i = 1)),
          const MonthlyPaymentPage(),
          const GroupsPage(),
          const CoursesPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor(context),
          border: Border(
            top: BorderSide(
              color: isDark(context)
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: cardColor(context),
          surfaceTintColor: Colors.transparent,
          indicatorColor: isDark(context)
              ? kPrimary.withOpacity(0.25)
              : const Color(0xFFDBEAFE),
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded, color: kPrimary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments, color: kPrimary),
              label: 'To\'lovlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups, color: kPrimary),
              label: 'Guruhlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: kPrimary),
              label: 'Kurslar',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: kPrimary),
              label: 'Sozlamalar',
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── UMUMIY WIDGETLAR ─────────────────────────
class StatusBadge extends StatelessWidget {
  final bool paid;
  const StatusBadge(this.paid, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = paid ? kGreen : kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paid ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: c,
          ),
          const SizedBox(width: 4),
          Text(
            paid ? "To'lagan" : "To'lamagan",
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student s;
  final VoidCallback? onLongPress;
  const StudentCard(this.s, {super.key, this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final c = courseOf(s.kurs);
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StudentPage(id: s.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(context),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.color, c.color.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    s.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(c.icon, size: 14, color: c.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              s.kurs,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.color,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.tel,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(s.paid),
              ],
            ),
            const SizedBox(height: 12),
            ContactButtons(s),
          ],
        ),
      ),
    );
  }
}

class StudentList extends StatelessWidget {
  final List<Student> list;
  final String empty;
  final VoidCallback? onAdd;
  const StudentList(this.list, {super.key, this.empty = "O'quvchilar yo'q", this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: isDark(context) ? Colors.white38 : const Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              empty,
              style: TextStyle(
                color: isDark(context) ? Colors.white60 : const Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text("Birinchi o'quvchini qo'shing"),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => StudentCard(list[i]),
    );
  }
}

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const StatBox(this.label, this.value, this.icon, {super.key});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirm(BuildContext context, String title, String body) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardColor(context),
      title: Text(
        title,
        style: TextStyle(
          color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        body,
        style: TextStyle(
          color: isDark(context) ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ha'),
        ),
      ],
    ),
  );
  return r ?? false;
}

// ───────────────────────── DASHBOARD ─────────────────────────
class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToPayments;
  const DashboardPage({super.key, this.onNavigateToPayments});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final all = app.students.where((s) {
          if (q.isEmpty) return true;
          return s.fullName.toLowerCase().contains(q) ||
              s.tel.contains(q) ||
              s.kurs.toLowerCase().contains(q);
        }).toList();
        final paid = all.where((s) => s.paid).toList();
        final unpaid = all.where((s) => !s.paid).toList();

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 14,
                  20,
                  20,
                ),
                decoration: const BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x331E3A8A),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Icon(Icons.school_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.centerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                "O'quv markazi paneli",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => showStudentForm(context),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, color: kPrimary, size: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        StatBox('Jami', '${app.students.length}', Icons.groups_outlined),
                        const SizedBox(width: 10),
                        StatBox("To'lagan", '${app.students.where((s) => s.paid).length}', Icons.check_circle_outline),
                        const SizedBox(width: 10),
                        StatBox("To'lamagan", '${app.students.where((s) => !s.paid).length}', Icons.schedule_outlined),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Oylik To'lov Tezkor Banneri
                    InkWell(
                      onTap: widget.onNavigateToPayments,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Icon(daysBadgeIcon(app.daysUntilDeadline), color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Oylik to'lov muddati: ${app.payDay}-$currentMonthUz",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    daysBadgeText(app.daysUntilDeadline, app.payDay, currentMonthUz),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_outlined, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _q = v),
                      style: TextStyle(
                        color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ism, raqam yoki kurs bo\'yicha qidirish',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark(context) ? Colors.white54 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.search_outlined,
                          color: isDark(context) ? Colors.white70 : kPrimary,
                        ),
                        filled: true,
                        fillColor: cardColor(context),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: kPrimary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                dividerColor: isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                indicatorColor: kPrimary,
                labelColor: isDark(context) ? Colors.white : kPrimary,
                unselectedLabelColor: isDark(context) ? Colors.white60 : const Color(0xFF64748B),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: [
                  Tab(text: 'Umumiy (${all.length})'),
                  Tab(text: "To'lagan (${paid.length})"),
                  Tab(text: "To'lamagan (${unpaid.length})"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    StudentList(
                      all,
                      empty: "Hozircha o'quvchi yo'q",
                      onAdd: app.students.isEmpty ? () => showStudentForm(context) : null,
                    ),
                    StudentList(paid, empty: "To'lov qilgan o'quvchi yo'q"),
                    StudentList(unpaid, empty: "Hamma to'lov qilgan 🎉"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── OYLIK TO'LOV SAHIFASI ─────────────────────────
class MonthlyPaymentPage extends StatefulWidget {
  const MonthlyPaymentPage({super.key});

  @override
  State<MonthlyPaymentPage> createState() => _MonthlyPaymentPageState();
}

class _MonthlyPaymentPageState extends State<MonthlyPaymentPage> {
  String _searchQuery = '';

  void _showPayDayPicker(BuildContext context) {
    int selected = app.payDay;
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Oylik to'lov sanasini tanlang",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: tx(ctx),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Har oyning qaysi sanasigacha oylik to'lov qilinishi kerak?",
                style: TextStyle(fontSize: 13.5, color: tx2(ctx)),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [5, 10, 15, 20, 25, 28, 30].map((day) {
                  final isSel = selected == day;
                  return ChoiceChip(
                    selected: isSel,
                    showCheckmark: false,
                    label: Text("$day-chi sana"),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : tx(ctx),
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: kPrimary,
                    backgroundColor: isDark(ctx)
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    onSelected: (_) {
                      setModalState(() => selected = day);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    app.setPayDay(selected);
                    Navigator.pop(ctx);
                    snack(
                      context,
                      "To'lov muddati har oyning $selected-sanasiga o'zgartirildi ✅",
                    );
                  },
                  child: const Text(
                    "Saqlash",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthlyFeeDialog(BuildContext context) {
    final ctrl = TextEditingController(text: app.monthlyFee.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Oylik to'lov summasi", style: TextStyle(color: tx(ctx))),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: tx(ctx)),
          decoration: InputDecoration(
            labelText: "Standart oylik to'lov (so'm)",
            labelStyle: TextStyle(color: tx2(ctx)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) {
                app.setMonthlyFee(val);
                Navigator.pop(ctx);
                snack(context, "Oylik to'lov summasi saqlandi ✅");
              }
            },
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final now = DateTime.now();
        final daysLeft = app.daysUntilDeadline;
        final totalCount = app.students.length;
        final paidStudents = app.students.where((s) => s.paid).toList();
        final unpaidStudents = app.students.where((s) => !s.paid).toList();
        final paidCount = paidStudents.length;
        final unpaidCount = unpaidStudents.length;

        final totalExpected = totalCount * app.monthlyFee;
        final totalCollected = paidCount * app.monthlyFee;
        final totalPending = unpaidCount * app.monthlyFee;
        final progressRatio = totalCount == 0 ? 0.0 : (paidCount / totalCount);

        // Qidiruv filtri
        final q = _searchQuery.toLowerCase();
        final filteredAll = app.students.where((s) {
          if (q.isEmpty) return true;
          return s.fullName.toLowerCase().contains(q) ||
              s.tel.contains(q) ||
              s.kurs.toLowerCase().contains(q);
        }).toList();
        final filteredPaid = filteredAll.where((s) => s.paid).toList();
        final filteredUnpaid = filteredAll.where((s) => !s.paid).toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            body: Column(
              children: [
                // Tepa Header Banner
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 14,
                    20,
                    20,
                  ),
                  decoration: const BoxDecoration(
                    gradient: kGradient,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x331E3A8A),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Oylik To'lovlar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  "$currentMonthUz ${now.year} oyi uchun",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showPayDayPicker(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${app.payDay}-$currentMonthUz",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Sanoq status badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: daysBadgeColor(daysLeft),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              daysBadgeIcon(daysLeft),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                daysBadgeText(daysLeft, app.payDay, currentMonthUz),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Financial Summary Cards
                      Row(
                        children: [
                          StatBox(
                            'Kutilmoqda',
                            fmtMoney(totalExpected),
                            Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(width: 8),
                          StatBox(
                            'Yig\'ildi',
                            fmtMoney(totalCollected),
                            Icons.check_circle_outline,
                          ),
                          const SizedBox(width: 8),
                          StatBox(
                            'Qarzdorlik',
                            fmtMoney(totalPending),
                            Icons.error_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "To'lov foizi",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${(progressRatio * 100).toInt()}% ($paidCount/$totalCount kishi)",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              color: kGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Quick Action Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickActionChip(
                          icon: Icons.tune_outlined,
                          label: "Narx: ${fmtMoney(app.monthlyFee)}",
                          color: kPrimary,
                          onTap: () => _showMonthlyFeeDialog(context),
                        ),
                        const SizedBox(width: 8),
                        _QuickActionChip(
                          icon: Icons.notifications_active_outlined,
                          label: "Barchaga SMS eslatma",
                          color: kYellow,
                          onTap: () => app.remindNow(manual: true),
                        ),
                        const SizedBox(width: 8),
                        _QuickActionChip(
                          icon: Icons.published_with_changes_outlined,
                          label: "Yangi oy boshlash",
                          color: kRed,
                          onTap: () async {
                            if (await confirm(
                              context,
                              'Yangi oy',
                              "Barcha o'quvchilar «to'lamagan» deb belgilansinmi?",
                            )) {
                              app.resetPayments();
                              snack(
                                context,
                                "Barcha to'lovlar yangi oy uchun nollandi 🔄",
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Qidiruv maydoni
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: tx(context)),
                    decoration: InputDecoration(
                      hintText: "Ism, raqam yoki kurs bo'yicha qidirish...",
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark(context)
                            ? Colors.white54
                            : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search_outlined,
                        color: isDark(context) ? Colors.white70 : kPrimary,
                      ),
                      filled: true,
                      fillColor: cardColor(context),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark(context)
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: kPrimary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                TabBar(
                  dividerColor: isDark(context)
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  indicatorColor: kPrimary,
                  labelColor: isDark(context) ? Colors.white : kPrimary,
                  unselectedLabelColor:
                      isDark(context) ? Colors.white60 : const Color(0xFF64748B),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'Hammasi (${filteredAll.length})'),
                    Tab(text: "To'lagan (${filteredPaid.length})"),
                    Tab(text: "To'lamagan (${filteredUnpaid.length})"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      PaymentStudentList(filteredAll),
                      PaymentStudentList(filteredPaid),
                      PaymentStudentList(filteredUnpaid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentStudentCard extends StatelessWidget {
  final Student s;
  const PaymentStudentCard(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = courseOf(s.kurs);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardDeco(context),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.color, c.color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  s.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: tx(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(c.icon, size: 13, color: c.color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            s.kurs,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fmtMoney(app.monthlyFee),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: s.paid ? kGreen : kRed,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(s.paid),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: s.paid ? kRed : kGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => app.togglePaid(s),
                    icon: Icon(s.paid ? Icons.close : Icons.check, size: 16),
                    label: Text(
                      s.paid ? "Bekor qilish" : "To'ladi ✅",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => callStudent(context, s),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.call_outlined, color: kPrimary, size: 18),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => smsStudent(context, s),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kYellow.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sms_outlined, color: kYellow, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentStudentList extends StatelessWidget {
  final List<Student> list;
  const PaymentStudentList(this.list, {super.key});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, size: 56, color: tx2(context)),
            const SizedBox(height: 8),
            Text(
              "O'quvchi topilmadi",
              style: TextStyle(color: tx2(context), fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => PaymentStudentCard(list[i]),
    );
  }
}

// ───────────────────────── O'QUVCHI QO'SHISH / TAHRIRLASH ─────────────────────────
Future<void> showStudentForm(BuildContext context, {Student? edit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: cardColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => StudentForm(edit: edit),
  );
}

class StudentForm extends StatefulWidget {
  final Student? edit;
  const StudentForm({super.key, this.edit});
  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _ism, _fam, _tel, _ota;
  late String _kurs;
  late bool _paid;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _ism = TextEditingController(text: e?.ism ?? '');
    _fam = TextEditingController(text: e?.familiya ?? '');
    _tel = TextEditingController(text: e?.tel ?? '+998');
    _ota = TextEditingController(text: e?.ota ?? '+998');
    _kurs = e?.kurs ?? kCourses.first.name;
    _paid = e?.paid ?? false;
  }

  @override
  void dispose() {
    _ism.dispose();
    _fam.dispose();
    _tel.dispose();
    _ota.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => fieldDeco(context, label, icon);

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'To\'ldiring' : null;
  String? _phone(String? v) => (v == null || v.trim().length < 9) ? "Raqamni to'g'ri kiriting" : null;

  void _submit() {
    if (!_key.currentState!.validate()) return;
    final e = widget.edit;
    if (e == null) {
      app.add(Student(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        ism: _ism.text.trim(),
        familiya: _fam.text.trim(),
        tel: _tel.text.trim(),
        ota: _ota.text.trim(),
        kurs: _kurs,
        paid: _paid,
      ));
    } else {
      e.ism = _ism.text.trim();
      e.familiya = _fam.text.trim();
      e.tel = _tel.text.trim();
      e.ota = _ota.text.trim();
      e.kurs = _kurs;
      e.paid = _paid;
      app.update();
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(e == null ? "O'quvchi qo'shildi ✅" : "O'zgarishlar saqlandi ✅"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.edit == null ? "Yangi o'quvchi" : "O'quvchini tahrirlash",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ism,
                      validator: _req,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Ism', Icons.person_outlined),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _fam,
                      validator: _req,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Familiya', Icons.badge_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tel,
                validator: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec('Telefon raqami', Icons.phone_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ota,
                validator: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec('Ota yoki ona raqami', Icons.family_restroom_outlined),
              ),
              const SizedBox(height: 16),
              Text(
                "Yo'nalish",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCourses.map((c) {
                  final sel = _kurs == c.name;
                  return ChoiceChip(
                    selected: sel,
                    avatar: Icon(c.icon, size: 18, color: sel ? Colors.white : c.color),
                    label: Text(c.name),
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : (isDark(context) ? Colors.white70 : const Color(0xFF334155)),
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: c.color,
                    backgroundColor: isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _kurs = c.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _paid,
                onChanged: (v) => setState(() => _paid = v),
                title: Text(
                  "To'lov qilgan",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(
                    widget.edit == null ? "Qo'shish" : 'Saqlash',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── O'QUVCHI SAHIFASI ─────────────────────────
class StudentPage extends StatelessWidget {
  final String id;
  const StudentPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final s = app.byId(id);
        if (s == null) return const Scaffold(body: Center(child: Text("O'quvchi topilmadi")));
        final c = courseOf(s.kurs);
        final groupNames =
        app.groups.where((g) => g.studentIds.contains(s.id)).map((g) => g.name).join(', ');
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text("O'quvchi ma'lumotlari"),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showStudentForm(context, edit: s),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outlined),
                onPressed: () async {
                  if (await confirm(context, "O'chirish", "${s.fullName} ro'yxatdan o'chirilsinmi?")) {
                    app.remove(s.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                decoration: const BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x331E3A8A),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Text(
                        s.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.kurs,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: StatusBadge(s.paid),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ContactButtons(s, height: 50),
                    const SizedBox(height: 14),
                    _InfoTile(Icons.phone_outlined, 'Telefon raqami', s.tel, copy: true),
                    _InfoTile(Icons.family_restroom_outlined, 'Ota yoki ona raqami', s.ota, copy: true),
                    _InfoTile(c.icon, "Yo'nalish", s.kurs, color: c.color),
                    if (groupNames.isNotEmpty)
                      _InfoTile(Icons.groups_outlined, 'Guruh', groupNames),
                    _InfoTile(Icons.event_outlined, "Qo'shilgan sana", fmtDate(s.created)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: s.paid ? kRed : kGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () => app.togglePaid(s),
                        icon: Icon(s.paid ? Icons.close : Icons.check),
                        label: Text(
                          s.paid ? "To'lovni bekor qilish" : "To'lov qildi deb belgilash",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (!s.paid) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark(context) ? const Color(0xFF334155) : kPrimary,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () => Toaster.show("To'lov eslatmasi", "${s.fullName} (${s.kurs}) to'lov qilmadi"),
                          icon: const Icon(Icons.notifications_active_outlined, color: kPrimary),
                          label: const Text(
                            'Eslatma yuborish',
                            style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool copy;
  final Color color;
  const _InfoTile(this.icon, this.label, this.value, {this.copy = false, this.color = kPrimary});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDeco(context, r: 18),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        trailing: copy ? Icon(Icons.copy_outlined, size: 18, color: isDark(context) ? Colors.white54 : const Color(0xFF64748B)) : null,
        onTap: copy
            ? () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Nusxalandi'),
            ),
          );
        }
            : null,
      ),
    );
  }
}

// ───────────────────────── GURUHLAR ─────────────────────────
class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guruhlar',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: tx(context))),
                    Text("${app.groups.length} ta guruh", style: TextStyle(color: tx2(context))),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showGroupForm(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (app.groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(Icons.groups_outlined, size: 64, color: tx2(context)),
                  const SizedBox(height: 10),
                  Text("Hozircha guruh yo'q", style: TextStyle(color: tx2(context), fontSize: 15)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => showGroupForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Birinchi guruhni qo'shing"),
                  ),
                ],
              ),
            ),
          ...app.groups.map((g) {
            final c = courseOf(g.kurs);
            final members = app.membersOf(g);
            final unpaid = members.where((s) => !s.paid).length;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GroupDetailPage(id: g.id)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: cardDeco(context),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c.color, c.color.withOpacity(0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(c.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: tx(context))),
                          const SizedBox(height: 3),
                          Text("${g.kurs}  •  ${g.teacher}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.color, fontSize: 12.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.schedule_outlined, size: 14, color: tx2(context)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text("${g.daysText}  •  ${g.timeText}",
                                    style: TextStyle(fontSize: 12.5, color: tx2(context))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${members.length} ta',
                            style: TextStyle(fontWeight: FontWeight.w800, color: tx(context))),
                        const SizedBox(height: 4),
                        if (unpaid > 0)
                          Text("$unpaid ta to'lamagan",
                              style: const TextStyle(color: kRed, fontSize: 11.5, fontWeight: FontWeight.w600))
                        else if (members.isNotEmpty)
                          const Text("Hammasi to'lagan",
                              style: TextStyle(color: kGreen, fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

Future<void> showGroupForm(BuildContext context, {Group? edit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: cardColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => GroupForm(edit: edit),
  );
}

class GroupForm extends StatefulWidget {
  final Group? edit;
  const GroupForm({super.key, this.edit});
  @override
  State<GroupForm> createState() => _GroupFormState();
}

class _GroupFormState extends State<GroupForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _kurs;
  String? _teacher;
  late Set<int> _days;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _name = TextEditingController(text: e?.name ?? '');
    _kurs = e?.kurs ?? kCourses.first.name;
    _teacher = (e == null || e.teacher.isEmpty) ? null : e.teacher;
    _days = <int>{...?e?.days};
    _time = TimeOfDay(hour: e?.hour ?? 15, minute: e?.minute ?? 0);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _newTeacher() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardColor(context),
        title: Text("Yangi o'qituvchi", style: TextStyle(color: tx(context), fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: tx(context)),
          decoration: const InputDecoration(hintText: 'Ism familiya'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text("Qo'shish")),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      app.addTeacher(name);
      setState(() => _teacher = name.trim());
    }
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (_days.isEmpty) {
      snack(context, 'Kamida bitta dars kunini tanlang');
      return;
    }
    final e = widget.edit;
    if (e == null) {
      app.addGroup(Group(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        teacher: _teacher!,
        kurs: _kurs,
        days: _days.toList()..sort(),
        hour: _time.hour,
        minute: _time.minute,
      ));
    } else {
      e.name = _name.text.trim();
      e.teacher = _teacher!;
      e.kurs = _kurs;
      e.days = _days.toList()..sort();
      e.hour = _time.hour;
      e.minute = _time.minute;
      app.update();
    }
    Navigator.pop(context);
    snack(context, e == null ? "Guruh qo'shildi ✅" : "O'zgarishlar saqlandi ✅");
  }

  @override
  Widget build(BuildContext context) {
    final teacherItems = <String>{...app.teachers, if (_teacher != null) _teacher!}.toList();
    final timeText =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.edit == null ? 'Yangi guruh' : 'Guruhni tahrirlash',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: tx(context))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                validator: (v) => (v == null || v.trim().isEmpty) ? "To'ldiring" : null,
                textCapitalization: TextCapitalization.words,
                decoration: fieldDeco(context, 'Guruh nomi', Icons.groups_outlined),
              ),
              const SizedBox(height: 16),
              Text("Yo'nalish", style: TextStyle(fontWeight: FontWeight.w700, color: tx(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCourses.map((c) {
                  final sel = _kurs == c.name;
                  return ChoiceChip(
                    selected: sel,
                    avatar: Icon(c.icon, size: 18, color: sel ? Colors.white : c.color),
                    label: Text(c.name),
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : (isDark(context) ? Colors.white70 : const Color(0xFF334155)),
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: c.color,
                    backgroundColor: isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _kurs = c.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _teacher,
                      isExpanded: true,
                      dropdownColor: cardColor(context),
                      validator: (v) => v == null ? "O'qituvchini tanlang" : null,
                      decoration: fieldDeco(context, "O'qituvchi", Icons.school_outlined),
                      items: teacherItems
                          .map((t) => DropdownMenuItem(
                          value: t, child: Text(t, style: TextStyle(color: tx(context)))))
                          .toList(),
                      onChanged: (v) => setState(() => _teacher = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      tooltip: "Yangi o'qituvchi",
                      icon: const Icon(Icons.person_add_alt_outlined, color: kPrimary),
                      onPressed: _newTeacher,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Dars kunlari', style: TextStyle(fontWeight: FontWeight.w700, color: tx(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final d = i + 1;
                  final sel = _days.contains(d);
                  return FilterChip(
                    selected: sel,
                    showCheckmark: false,
                    label: Text(kDays[i]),
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : (isDark(context) ? Colors.white70 : const Color(0xFF334155)),
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: kPrimary,
                    backgroundColor: isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    onSelected: (v) => setState(() => v ? _days.add(d) : _days.remove(d)),
                  );
                }),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark(context) ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: kPrimary),
                      const SizedBox(width: 12),
                      Text('Dars vaqti', style: TextStyle(color: tx2(context))),
                      const Spacer(),
                      Text(timeText,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx(context))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: Text(widget.edit == null ? "Qo'shish" : 'Saqlash',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── GURUHNI BOSHQARISH ─────────────────────────
class GroupDetailPage extends StatelessWidget {
  final String id;
  const GroupDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final g = app.groupById(id);
        if (g == null) return const Scaffold(body: Center(child: Text('Guruh topilmadi')));
        final c = courseOf(g.kurs);
        final members = app.membersOf(g);
        return Scaffold(
          appBar: AppBar(
            backgroundColor: c.color,
            foregroundColor: Colors.white,
            title: const Text('Guruhni boshqarish'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showGroupForm(context, edit: g),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outlined),
                onPressed: () async {
                  if (await confirm(context, "Guruhni o'chirish", "«${g.name}» guruhi o'chirilsinmi? (O'quvchilar o'chmaydi)")) {
                    app.removeGroup(g.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                decoration: BoxDecoration(
                  color: c.color,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: c.color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(g.kurs, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(g.teacher,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text("${g.daysText}  •  ${g.timeText}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        StatBox("O'quvchilar", '${members.length}', Icons.groups_outlined),
                        const SizedBox(width: 10),
                        StatBox("To'lagan", '${members.where((s) => s.paid).length}', Icons.check_circle_outline),
                        const SizedBox(width: 10),
                        StatBox("To'lamagan", '${members.where((s) => !s.paid).length}', Icons.schedule_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => showAddStudents(context, g),
                    icon: const Icon(Icons.person_add_alt_outlined),
                    label: const Text("O'quvchi qo'shish",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              if (members.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                  child: Text("Guruhdan chiqarish uchun o'quvchi kartasini bosib turing",
                      style: TextStyle(fontSize: 12, color: tx2(context))),
                ),
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 60, color: tx2(context)),
                      const SizedBox(height: 8),
                      Text("Guruhda hozircha o'quvchi yo'q", style: TextStyle(color: tx2(context))),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    for (final s in members)
                      StudentCard(
                        s,
                        onLongPress: () async {
                          if (await confirm(context, 'Guruhdan chiqarish',
                              "${s.fullName} «${g.name}» guruhidan chiqarilsinmi?")) {
                            g.studentIds.remove(s.id);
                            app.update();
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showAddStudents(BuildContext context, Group g) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: cardColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => AddStudentsSheet(group: g),
  );
}

class AddStudentsSheet extends StatefulWidget {
  final Group group;
  const AddStudentsSheet({super.key, required this.group});
  @override
  State<AddStudentsSheet> createState() => _AddStudentsSheetState();
}

class _AddStudentsSheetState extends State<AddStudentsSheet> {
  final Set<String> _sel = {};

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final list = app.students.where((s) => !g.studentIds.contains(s.id)).toList()
      ..sort((a, b) {
        final x = a.kurs == g.kurs ? 0 : 1;
        final y = b.kurs == g.kurs ? 0 : 1;
        return x.compareTo(y);
      });
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Guruhga o'quvchi qo'shish",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: tx(context))),
            Text("«${g.name}» uchun o'quvchilarni belgilang", style: TextStyle(color: tx2(context))),
            const SizedBox(height: 10),
            Expanded(
              child: list.isEmpty
                  ? Center(
                child: Text(
                  "Qo'shish mumkin bo'lgan o'quvchi yo'q.\nAvval Dashboard orqali yangi o'quvchi qo'shing.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tx2(context)),
                ),
              )
                  : ListView(
                children: list.map((s) {
                  final c = courseOf(s.kurs);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: kPrimary,
                    value: _sel.contains(s.id),
                    onChanged: (v) => setState(() => v == true ? _sel.add(s.id) : _sel.remove(s.id)),
                    title: Text(s.fullName,
                        style: TextStyle(fontWeight: FontWeight.w700, color: tx(context))),
                    subtitle: Text(s.kurs,
                        style: TextStyle(color: c.color, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    secondary: CircleAvatar(
                      backgroundColor: c.color,
                      child: Text(s.initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _sel.isEmpty
                    ? null
                    : () {
                  g.studentIds.addAll(_sel);
                  app.update();
                  Navigator.pop(context);
                },
                child: Text("Qo'shish (${_sel.length})",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── KURSLAR ─────────────────────────
class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
        children: [
          Text(
            'Kurslar',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            "${kCourses.length} ta yo'nalish",
            style: TextStyle(
              color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ...kCourses.map((c) {
            final list = app.byCourse(c.name);
            final paid = list.where((s) => s.paid).length;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CourseDetailPage(course: c)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.color, c.color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: c.color.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Icon(c.icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${list.length} ta o'quvchi  •  $paid ta to'lagan",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_outlined, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class CourseDetailPage extends StatefulWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});
  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int _f = 0;
  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final all = app.byCourse(c.name);
        final list = _f == 0 ? all : all.where((s) => s.paid == (_f == 1)).toList();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: c.color,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(c.name),
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                decoration: BoxDecoration(
                  color: c.color,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: c.color.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    StatBox("O'quvchilar", '${all.length}', Icons.groups_outlined),
                    const SizedBox(width: 10),
                    StatBox("To'lagan", '${all.where((s) => s.paid).length}', Icons.check_circle_outline),
                    const SizedBox(width: 10),
                    StatBox("To'lamagan", '${all.where((s) => !s.paid).length}', Icons.schedule_outlined),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    for (final e in ['Hammasi', "To'lagan", "To'lamagan"].asMap().entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _f == e.key,
                          selectedColor: c.color,
                          backgroundColor: isDark(context) ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: _f == e.key ? Colors.white : (isDark(context) ? Colors.white70 : const Color(0xFF334155)),
                            fontWeight: FontWeight.w600,
                          ),
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _f = e.key),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: StudentList(list, empty: "Bu kursda o'quvchi yo'q")),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────── SOZLAMALAR ─────────────────────────
class TeachersDialog extends StatefulWidget {
  const TeachersDialog({super.key});
  @override
  State<TeachersDialog> createState() => _TeachersDialogState();
}

class _TeachersDialogState extends State<TeachersDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardColor(context),
        title: Text("O'qituvchilar", style: TextStyle(color: tx(context), fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: tx(context)),
                      decoration: const InputDecoration(hintText: 'Ism familiya'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: kPrimary),
                    onPressed: () {
                      app.addTeacher(_c.text);
                      _c.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (app.teachers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text("Hozircha o'qituvchi yo'q", style: TextStyle(color: tx2(context))),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: app.teachers
                        .map((t) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.school_outlined, color: kPrimary),
                      title: Text(t, style: TextStyle(color: tx(context), fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: kRed),
                        onPressed: () => app.removeTeacher(t),
                      ),
                    ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Yopish')),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _intervals = <int, String>{
    1: '1 daqiqa (test uchun)',
    15: '15 daqiqa',
    30: '30 daqiqa',
    60: '1 soat',
    180: '3 soat',
    720: '12 soat',
  };

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          Container(
            decoration: cardDeco(context),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _icon(IconData i, Color c) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: c.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(i, color: c, size: 22),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
        children: [
          Text(
            'Sozlamalar',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 18),
          _section(context, 'Eslatmalar', [
            SwitchListTile(
              secondary: _icon(Icons.notifications_active_outlined, kRed),
              title: Text(
                "To'lov eslatmasi",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                "To'lov qilmagan o'quvchilarni bildirishnoma qilib eslatadi",
                style: TextStyle(
                  color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              value: app.remind,
              onChanged: app.setRemind,
            ),
            if (app.remind)
              ListTile(
                leading: _icon(Icons.timer_outlined, Colors.amber.shade700),
                title: Text(
                  'Eslatma oralig\'i',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                trailing: DropdownButton<int>(
                  value: _intervals.containsKey(app.remindMin) ? app.remindMin : 60,
                  underline: const SizedBox(),
                  dropdownColor: cardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  items: _intervals.entries
                      .map(
                        (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (v) => app.setRemindMin(v!),
                ),
              ),
            SwitchListTile(
              secondary: _icon(Icons.alarm_on_outlined, kYellow),
              title: Text('Dars oldidan ogohlantirish',
                  style: TextStyle(fontWeight: FontWeight.w600, color: tx(context))),
              subtitle: Text(
                "Dars boshlanishidan ${AppState.lessonLeadMin} daqiqa oldin to'lamagan o'quvchini darsga kiritmaslik haqida bildirishnoma",
                style: TextStyle(color: tx2(context)),
              ),
              value: app.lessonRemind,
              onChanged: app.setLessonRemind,
            ),
            ListTile(
              leading: _icon(Icons.campaign_outlined, kPrimary),
              title: Text(
                'Hozir eslatish',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                "To'lamaganlar uchun bildirishnomani hozir ko'rsatish",
                style: TextStyle(
                  color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              onTap: () => app.remindNow(manual: true),
            ),
          ]),
          _section(context, "To'lov", [
            ListTile(
              leading: _icon(Icons.event_available_outlined, kGreen),
              title: Text("To'lov muddati",
                  style: TextStyle(fontWeight: FontWeight.w600, color: tx(context))),
              subtitle: Text(
                "SMS'dagi sana: ${fmtDate(app.deadline)}",
                style: TextStyle(color: tx2(context)),
              ),
              trailing: DropdownButton<int>(
                value: app.payDay,
                underline: const SizedBox(),
                dropdownColor: cardColor(context),
                borderRadius: BorderRadius.circular(16),
                items: List.generate(28, (i) => i + 1)
                    .map((d) => DropdownMenuItem(
                  value: d,
                  child: Text('Har oy $d-sana', style: TextStyle(color: tx(context))),
                ))
                    .toList(),
                onChanged: (v) => app.setPayDay(v!),
              ),
            ),
          ]),
          _section(context, "Ko'rinish", [
            SwitchListTile(
              secondary: _icon(Icons.dark_mode_outlined, kAccentBlue),
              title: Text(
                "Qorong'u rejim",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              value: app.dark,
              onChanged: app.setDark,
            ),
          ]),
          _section(context, 'Markaz', [
            ListTile(
              leading: _icon(Icons.apartment_outlined, kGreen),
              title: Text(
                'Markaz nomi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                app.centerName,
                style: TextStyle(
                  color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              trailing: Icon(Icons.edit_outlined, size: 18, color: isDark(context) ? Colors.white54 : const Color(0xFF64748B)),
              onTap: () async {
                final ctrl = TextEditingController(text: app.centerName);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: cardColor(context),
                    title: Text(
                      'Markaz nomi',
                      style: TextStyle(
                        color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      style: TextStyle(
                        color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Saqlash')),
                    ],
                  ),
                );
                if (ok == true) app.setCenter(ctrl.text);
              },
            ),
            ListTile(
              leading: _icon(Icons.school_outlined, kPrimary),
              title: Text("O'qituvchilar",
                  style: TextStyle(fontWeight: FontWeight.w600, color: tx(context))),
              subtitle: Text("${app.teachers.length} ta o'qituvchi",
                  style: TextStyle(color: tx2(context))),
              trailing: Icon(Icons.chevron_right, color: tx2(context)),
              onTap: () => showDialog(context: context, builder: (_) => const TeachersDialog()),
            ),
            ListTile(
              leading: _icon(Icons.autorenew_outlined, Colors.amber.shade700),
              title: Text(
                'Yangi oy boshlandi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                "Barcha to'lovlarni «to'lamagan» holatiga qaytarish",
                style: TextStyle(
                  color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              onTap: () async {
                if (await confirm(context, 'Yangi oy', "Barcha o'quvchilar «to'lamagan» deb belgilansinmi?")) {
                  app.resetPayments();
                }
              },
            ),
            ListTile(
              leading: _icon(Icons.delete_sweep_outlined, kRed),
              title: Text(
                "Barcha ma'lumotlarni o'chirish",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark(context) ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              onTap: () async {
                if (await confirm(context, "O'chirish", "Barcha o'quvchilar va guruhlar o'chiriladi. Davom etasizmi?")) {
                  app.clearAll();
                }
              },
            ),
          ]),
          _section(context, 'Bildirishnomalar tarixi', [
            if (app.log.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    "Hozircha bildirishnoma yo'q",
                    style: TextStyle(
                      color: isDark(context) ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else ...[
              for (final l in app.log.take(8))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.notifications_none_outlined, color: kRed),
                  title: Text(
                    l,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark(context) ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: app.clearLog,
                icon: const Icon(Icons.clear_all_outlined, color: kRed),
                label: const Text('Tarixni tozalash', style: TextStyle(color: kRed)),
              ),
            ],
          ]),
          Center(
            child: Text(
              '${app.centerName} • v1.1',
              style: TextStyle(
                color: isDark(context) ? Colors.white38 : const Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
