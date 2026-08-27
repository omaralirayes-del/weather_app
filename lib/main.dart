import 'dart:async';
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: "Amiri"),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// ==================== الشاشة الافتتاحية (Splash Screen) ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد أنيميشن تكبير وظهور الشعار
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // الانتقال التلقائي لشاشة الطقس بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SmartWeatherScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
              Color(0xFF0F2027),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // الشعار المتحرك
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "images/icon.png",
                    height: 120,
                    width: 120,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // عنوان التطبيق المتحرك
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'تطبيق الطقس',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'دليلك الدقيق لحالة الجو',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(),

            // مؤشر التحميل السفلي
            const WeatherCustomLoader(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ==================== مؤشر تحميل مخصص للطقس ====================
class WeatherCustomLoader extends StatefulWidget {
  const WeatherCustomLoader({super.key});

  @override
  State<WeatherCustomLoader> createState() => _WeatherCustomLoaderState();
}

class _WeatherCustomLoaderState extends State<WeatherCustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _controller,
          child: Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.1),
                  Colors.lightBlueAccent,
                  Colors.white,
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_sync_rounded,
                color: Colors.lightBlueAccent,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "Loading...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    );
  }
}

// ==================== شاشة الطقس الرئيسية ====================
class SmartWeatherScreen extends StatefulWidget {
  const SmartWeatherScreen({super.key});

  @override
  State<SmartWeatherScreen> createState() => _SmartWeatherScreenState();
}

class _SmartWeatherScreenState extends State<SmartWeatherScreen> {
  final TextEditingController _searchController = TextEditingController();

  String cityName = 'القاهرة';
  double? temp;
  double? windSpeed;
  int? humidity;
  double? visibility;
  double? uvIndex;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    searchAndFetchWeather('Cairo');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> searchAndFetchWeather(String city) async {
    setState(() => isLoading = true);

    final geocodingUrl = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=$city&count=1&language=ar&format=json',
    );

    try {
      final geoResponse = await http.get(geocodingUrl);

      if (geoResponse.statusCode == 200) {
        final geoData = jsonDecode(geoResponse.body);

        if (geoData['results'] != null && geoData['results'].isNotEmpty) {
          final double lat = geoData['results'][0]['latitude'];
          final double lon = geoData['results'][0]['longitude'];
          final String foundCityName = geoData['results'][0]['name'];

          await fetchWeatherByCoordinates(lat, lon, foundCityName);
        } else {
          _showMessage('لم يتم العثور على المدينة، جرب اسماً آخر');
          setState(() => isLoading = false);
        }
      } else {
        _showMessage('فشل في جلب بيانات المدينة');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showMessage('حدث خطأ أثناء الاتصال بالشبكة');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchWeatherByCoordinates(
    double lat,
    double lon,
    String name,
  ) async {
    final weatherUrl = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,visibility,uv_index,wind_speed_10m',
    );

    try {
      final response = await http.get(weatherUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            final current = data['current'];
            temp = (current['temperature_2m'] as num?)?.toDouble();
            windSpeed = (current['wind_speed_10m'] as num?)?.toDouble();
            humidity = (current['relative_humidity_2m'] as num?)?.toInt();
            visibility = current['visibility'] != null
                ? ((current['visibility'] as num) / 1000).toDouble()
                : null;
            uvIndex = (current['uv_index'] as num?)?.toDouble();

            cityName = name;
            isLoading = false;
          });
        }
      } else {
        _showMessage('فشل في جلب حالة الطقس');
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      _showMessage('حدث خطأ أثناء جلب الطقس');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String getBackgroundImage() {
    if (temp == null) return "images/virtual.jpg";
    return temp! > 30 ? "images/plus30.jpeg" : "images/minus30.jpeg";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(getBackgroundImage()),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 15),
                SizedBox(
                  height: 50,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'Weather',
                        textStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                        speed: const Duration(milliseconds: 200),
                      ),
                    ],
                    repeatForever: true,
                    pause: const Duration(milliseconds: 1000),
                  ),
                ),
                Image.asset("images/icon.png", height: 70, width: 80),
                const SizedBox(height: 30),

                // حقل البحث
                TextField(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  controller: _searchController,
                  decoration: InputDecoration(
                    fillColor: Colors.black.withOpacity(0.7),
                    filled: true,
                    hintText: 'Search',
                    hintStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        if (_searchController.text.trim().isNotEmpty) {
                          searchAndFetchWeather(_searchController.text.trim());
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      searchAndFetchWeather(value.trim());
                    }
                  },
                ),
                const SizedBox(height: 30),

                // عرض النتائج مع الأنيميشن المخصص عند التحميل
                if (isLoading)
                  const WeatherCustomLoader()
                else if (temp != null)
                  Card(
                    color: Colors.black.withOpacity(0.8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            cityName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$temp°C',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // سرعة الرياح
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.air, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(
                                'سرعة الرياح: $windSpeed كم/س',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // الرطوبة
                          if (humidity != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.water_drop,
                                    color: Colors.lightBlueAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'الرطوبة: $humidity%',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),

                          // مدى الرؤية
                          if (visibility != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.remove_red_eye,
                                    color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(
                                  'مدى الرؤية: ${visibility!.toStringAsFixed(1)} كم',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),

                          // مؤشر الأشعة فوق البنفسجية
                          if (uvIndex != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wb_sunny, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  'الأشعة فوق البنفسجية (UV): $uvIndex',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                        ],
                      ),
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