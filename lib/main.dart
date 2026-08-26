import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SmartWeatherScreen());
}

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
  bool isLoading = false;

  // 1. البحث الذكي تحويل اسم المدينة إلى إحداثيات
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

          // 2. جلب الطقس بالإحداثيات المستخرجة
          await fetchWeatherByCoordinates(lat, lon, foundCityName);
        } else {
          _showMessage('لم يتم العثور على المدينة، جرب اسماً آخر');
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      _showMessage('حدث خطأ أثناء الاتصال بالشبكة');
      setState(() => isLoading = false);
    }
  }

  // 2. جلب بيانات الطقس من Open-Meteo
  Future<void> fetchWeatherByCoordinates(
    double lat,
    double lon,
    String name,
  ) async {
    final weatherUrl = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
    );

    final response = await http.get(weatherUrl);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        temp = data['current_weather']['temperature'];
        windSpeed = data['current_weather']['windspeed'];
        cityName = name;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void initState() {
    super.initState();
    // جلب طقس القاهرة كمدينة افتراضية عند التشغيل
    searchAndFetchWeather('Cairo');
  }

  String getBackgroundImage() {
  if (temp == null) return "images/virtual.jpg"; // خلفية افتراضية قبل تحميل البيانات
  return temp! > 30 ? "images/plus30.jpeg" : "images/minus30.jpeg";
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: "Amiri"
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        
          
          
          
        
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(getBackgroundImage(),),fit: BoxFit.cover
              
        
            ),
          ),
          child: Column(
            children: [
               Column(
            children: [
              const SizedBox(height: 25,),
              SizedBox(
              height: 60, // تحديد ارتفاع ثابت لمنع اهتزاز الشاشة
              child: AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'Weather', // النص الذي سيتم كتابته ومسحه
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                    speed: const Duration(milliseconds: 200), // سرعة الكتابة (خفيفة جداً)
                  ),
                ],
                repeatForever: true, // تكرار الأنميشن طالما التطبيق شغال
                pause: const Duration(milliseconds: 1000), // وقفة بسيطة بين كل إعادة
              ),
            ),
            Image.asset("images/icon.png", height: 70, width: 80),
          ],
        ),
            
          const SizedBox(height: 50,),
        
              // حقل البحث
              TextField(
                
                style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.w500),
                controller: _searchController,
                
              
                decoration: InputDecoration(
                  fillColor: Colors.black,
                  filled: true,
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search,color: Colors.white,),
                    onPressed: () {
                      if (_searchController.text.trim().isNotEmpty) {
                        searchAndFetchWeather(_searchController.text.trim());
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    searchAndFetchWeather(value.trim());
                  }
                },
              ),
              const SizedBox(height: 40),

              // عرض النتائج
              if (isLoading)
                const CircularProgressIndicator()
              else if (temp != null)
                Card(
                  color: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                        const SizedBox(height: 15),
                        Text(
                          '$temp°C',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.air, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'سرعة الرياح: $windSpeed كم/س',
                              style: const TextStyle(fontSize: 16,color: Colors.white),
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
    );
  }
}
