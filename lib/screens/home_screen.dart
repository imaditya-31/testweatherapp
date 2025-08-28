import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String apiKey = '13b8d81b3803bd2448095f136ab939ef';
  final TextEditingController _controller = TextEditingController();

  final List<String> defaultCities = [
    'Delhi',
    'Mumbai',
    'Pune',
    'Bengaluru',
    'Chennai',
    'Kolkata',
    'Hyderabad',
    'Ahmedabad',
  ];

  List<Map<String, dynamic>> weatherList = [];
  List<String> recentSearches = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadDefaultCities();
  }

  /// Load recent searches from shared preferences
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recent_weather') ?? [];
    });
  }

  /// Save search term to shared preferences
  Future<void> _saveSearch(String city) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches.remove(city);
      recentSearches.insert(0, city);
      if (recentSearches.length > 8) {
        recentSearches = recentSearches.sublist(0, 8);
      }
    });
    await prefs.setStringList('recent_weather', recentSearches);
  }

  /// Fetch default cities' weather on app start
  Future<void> _loadDefaultCities() async {
    setState(() {
      isLoading = true;
      weatherList.clear();
    });

    for (final city in defaultCities) {
      final data = await _fetchWeather(city);
      if (data != null) weatherList.add(data);
    }

    setState(() => isLoading = false);
  }

  /// API call to get weather data
  Future<Map<String, dynamic>?> _fetchWeather(String city) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');

    final res = await http.get(url);
    if (res.statusCode == 200) {
      print('=====${res.body}======');
      return json.decode(res.body);
    }
    return null;
  }

  /// Search for a city
  Future<void> _searchCity(String city) async {
    if (city.trim().isEmpty) return;

    setState(() => isLoading = true);

    final data = await _fetchWeather(city.trim());
    if (data != null) {
      _saveSearch(city.trim());
      weatherList.removeWhere(
        (e) => (e['name'] as String).toLowerCase() == city.toLowerCase(),
      );
      weatherList.insert(0, data);
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        centerTitle: true,
        title: const Text(
          'City Weather',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// Search Bar
            TextField(
              controller: _controller,
              onSubmitted: _searchCity,
              decoration: InputDecoration(
                hintText: 'Search a City',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchCity(_controller.text),
                ),
              ),
            ),

            /// Recent Searches
            if (recentSearches.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentSearches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => ActionChip(
                    label: Text(recentSearches[i]),
                    onPressed: () {
                      _controller.text = recentSearches[i];
                      _searchCity(recentSearches[i]);
                    },
                  ),
                ),
              ),

            const SizedBox(height: 8),

            /// Loading Indicator
            if (isLoading) const LinearProgressIndicator(),

            const SizedBox(height: 8),

            /// Weather List
            Expanded(
              child: ListView.builder(
                itemCount: weatherList.length,
                itemBuilder: (ctx, i) {
                  final weather = weatherList[i];
                  final name = weather['name'] ?? '';
                  final main = weather['weather']?[0]?['main'] ?? '';
                  final desc = weather['weather']?[0]?['description'] ?? '';
                  final temp = weather['main']?['temp']?.round();
                  final icon = weather['weather']?[0]?['icon'];
                  final iconUrl = icon != null
                      ? 'https://openweathermap.org/img/wn/$icon@2x.png'
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      border: Border.all(width: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      leading: iconUrl != null
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Image.network(iconUrl, width: 56),
                            )
                          : const Icon(Icons.cloud),
                      title: Text('$name • $main'),
                      subtitle: Text(desc.toString()),
                      trailing: Text(
                        temp != null ? '$temp°C' : '-°C',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
