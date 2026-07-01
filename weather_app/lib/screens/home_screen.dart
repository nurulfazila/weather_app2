import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  final WeatherService? weatherService;
  const HomeScreen({super.key, this.weatherService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WeatherService _weatherService;
  final TextEditingController _searchController = TextEditingController();

  WeatherModel? _weather;
  List<ForecastItem> _forecastItems = [];
  List<ForecastItem> _hourlyForecastItems = [];
  List<String> _favoriteCities = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFahrenheit = false;
  bool _isDarkMode = false;

  final _popularCities = [
    'Banda Aceh',
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Medan'
  ];

  @override
  void initState() {
    super.initState();
    _weatherService = widget.weatherService ?? WeatherService();
    _loadFavorites();
    _fetchWeather('Banda Aceh');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
        () => _favoriteCities = prefs.getStringList('favorite_cities') ?? []);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_cities', _favoriteCities);
  }

  Future<void> _toggleFavorite(String city) async {
    final normalized = city.trim();
    if (normalized.isEmpty) return;
    setState(() {
      final exists = _favoriteCities
          .any((c) => c.toLowerCase() == normalized.toLowerCase());
      if (exists) {
        _favoriteCities
            .removeWhere((c) => c.toLowerCase() == normalized.toLowerCase());
      } else {
        _favoriteCities.insert(0, normalized);
      }
    });
    await _saveFavorites();
  }

  Future<void> _fetchWeather(String city) async {
    final normalizedCity = city.trim();
    if (normalizedCity.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _forecastItems = [];
      _hourlyForecastItems = [];
    });

    try {
      final weather = await _weatherService.getWeatherByCity(normalizedCity);
      final forecasts =
          await _weatherService.getFiveDayForecastByCity(normalizedCity);
      final hourly =
          await _weatherService.getHourlyForecastByCity(normalizedCity);

      setState(() {
        _weather = weather;
        _forecastItems = forecasts;
        _hourlyForecastItems = hourly;
        _isLoading = false;
      });

      if (!_favoriteCities
          .any((c) => c.toLowerCase() == normalizedCity.toLowerCase())) {
        _favoriteCities.insert(0, normalizedCity);
        await _saveFavorites();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _forecastItems = [];
      _hourlyForecastItems = [];
    });

    try {
      final position = await _determinePosition();
      final weather = await _weatherService.getWeatherByLocation(
          position.latitude, position.longitude);
      final forecasts = await _weatherService.getFiveDayForecastByLocation(
          position.latitude, position.longitude);
      final hourly = await _weatherService.getHourlyForecastByLocation(
          position.latitude, position.longitude);

      setState(() {
        _weather = weather;
        _forecastItems = forecasts;
        _hourlyForecastItems = hourly;
        _isLoading = false;
        _searchController.text = weather.cityName;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Layanan lokasi nonaktif.');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  String _buildNotificationMessage(WeatherModel weather) {
    final main = weather.mainCondition.toLowerCase();
    if (main.contains('rain') || main.contains('drizzle')) {
      return 'Hati-hati hujan, bawa payung!';
    }
    if (main.contains('clear')) {
      return 'Cuaca cerah, cocok untuk aktivitas luar!';
    }
    return 'Cuaca ${weather.description} sekarang.';
  }

  // Helpers
  String _temperatureUnit() => _isFahrenheit ? '°F' : '°C';
  String _windUnit() => _isFahrenheit ? 'mph' : 'm/s';
  double _displayTemperature(double t) => _isFahrenheit ? (t * 9 / 5) + 32 : t;
  double _displayWindSpeed(double v) => _isFahrenheit ? v * 2.23694 : v;

  Color _whiteOpacity(double o) => Color.fromRGBO(255, 255, 255, o);

  @override
  Widget build(BuildContext context) {
    final gradient = _isDarkMode
        ? [const Color(0xFF0B1221), const Color(0xFF18283D)]
        : [const Color(0xFF1E88E5), const Color(0xFF7DD3FC)];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradient)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Cuaca Hari Ini',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold))),
                    IconButton(
                        onPressed: () => _fetchWeather(
                            _searchController.text.isEmpty
                                ? 'Banda Aceh'
                                : _searchController.text),
                        icon: const Icon(Icons.refresh_rounded),
                        color: Colors.white),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: ElevatedButton.icon(
                            onPressed: _fetchWeatherByLocation,
                            icon: const Icon(Icons.my_location_rounded),
                            label: const Text('Gunakan Lokasi'))),
                    const SizedBox(width: 8),
                    IconButton(
                        onPressed: () =>
                            setState(() => _isDarkMode = !_isDarkMode),
                        icon: Icon(_isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded),
                        color: Colors.white),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                      decoration: BoxDecoration(
                          color: _whiteOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              hintText: 'Cari nama kota...',
                              border: InputBorder.none),
                          onSubmitted: (v) => _fetchWeather(v))),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      children: _popularCities
                          .map((c) => ActionChip(
                              label: Text(c),
                              onPressed: () => _fetchWeather(c)))
                          .toList()),
                  const SizedBox(height: 12),
                  const Text('Favorit',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_favoriteCities.isEmpty)
                    Text('Belum ada kota favorit. Tambahkan dari hasil cuaca.',
                        style: TextStyle(color: _whiteOpacity(0.8)))
                  else
                    Wrap(
                        spacing: 8,
                        children: _favoriteCities
                            .map((c) => InputChip(
                                label: Text(c),
                                onPressed: () => _fetchWeather(c),
                                onDeleted: () => _toggleFavorite(c)))
                            .toList()),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                  else if (_errorMessage != null)
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: _whiteOpacity(0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Text(_errorMessage!,
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                              onPressed: () => _fetchWeather('Banda Aceh'),
                              child: const Text('Coba Lagi'))
                        ]))
                  else if (_weather != null)
                    _buildWeatherContent()
                ]),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    final w = _weather!;
    return Column(children: [
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: _whiteOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('${w.cityName}, ${w.country}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))),
              IconButton(
                  onPressed: () => _toggleFavorite(w.cityName),
                  icon: const Icon(Icons.favorite_border_rounded),
                  color: Colors.white)
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Image.network(
                  'https://openweathermap.org/img/wn/${w.icon}@2x.png',
                  width: 80,
                  height: 80),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${_displayTemperature(w.temperature).round()}${_temperatureUnit()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold)),
                    Text(_capitalize(w.description),
                        style: const TextStyle(color: Colors.white))
                  ]))
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildUnitToggle()),
              const SizedBox(width: 8),
              Text(
                  'Diperbarui ${DateFormat('HH:mm', 'id_ID').format(DateTime.now())}',
                  style: TextStyle(color: _whiteOpacity(0.8)))
            ]),
          ])),
      const SizedBox(height: 12),
      _buildDetailsGrid(w),
      const SizedBox(height: 12),
      _buildHourlyForecastSection(),
      const SizedBox(height: 12),
      _buildChartSection(),
      const SizedBox(height: 12),
      _buildForecastSection(),
    ]);
  }

  Widget _buildUnitToggle() {
    return ToggleButtons(
        isSelected: [_isFahrenheit == false, _isFahrenheit == true],
        onPressed: (i) => setState(() => _isFahrenheit = i == 1),
        children: const [Text('°C'), Text('°F')]);
  }

  Widget _buildHourlyForecastSection() {
    if (_hourlyForecastItems.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Prakiraan per Jam',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      SizedBox(
          height: 110,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _hourlyForecastItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final it = _hourlyForecastItems[index];
                return Container(
                    width: 88,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _whiteOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('HH:mm', 'id_ID').format(it.dateTime),
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Image.network(
                              'https://openweathermap.org/img/wn/${it.icon}@2x.png',
                              width: 40,
                              height: 40),
                          const SizedBox(height: 6),
                          Text(
                              '${_displayTemperature(it.temperature).round()}${_temperatureUnit()}',
                              style: const TextStyle(color: Colors.white))
                        ]));
              })),
    ]);
  }

  Widget _buildChartSection() {
    // Chart removed per user request.
    return const SizedBox.shrink();
  }

  Widget _buildForecastSection() {
    if (_forecastItems.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Prakiraan 5 Hari',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      SizedBox(
          height: 140,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _forecastItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final it = _forecastItems[index];
                return Container(
                    width: 104,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: _whiteOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(DateFormat('E', 'id_ID').format(it.dateTime),
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Image.network(
                              'https://openweathermap.org/img/wn/${it.icon}@2x.png',
                              width: 42,
                              height: 42),
                          const SizedBox(height: 6),
                          Text(
                              '${_displayTemperature(it.temperature).round()}${_temperatureUnit()}',
                              style: const TextStyle(color: Colors.white))
                        ]));
              })),
    ]);
  }

  Widget _buildDetailsGrid(WeatherModel weather) {
    final windValue = weather.windSpeed > 0
        ? '${_displayWindSpeed(weather.windSpeed).toStringAsFixed(1)} ${_windUnit()}'
        : 'Data angin belum tersedia';
    final items = [
      _DetailItem(
          Icons.water_drop_rounded, 'Kelembapan', '${weather.humidity}%'),
      _DetailItem(Icons.air_rounded, 'Angin', windValue),
      _DetailItem(Icons.speed_rounded, 'Tekanan', '${weather.pressure} hPa'),
      _DetailItem(Icons.thermostat_rounded, 'Terasa',
          '${_displayTemperature(weather.feelsLike).round()}${_temperatureUnit()}'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: items.map((it) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _whiteOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(it.icon, color: Colors.white),
              const SizedBox(height: 6),
              Text(it.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(it.value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem(this.icon, this.label, this.value);
}
