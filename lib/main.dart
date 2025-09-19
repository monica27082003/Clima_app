import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Librería para hacer peticiones HTTP

Future<void> main() async {
  runApp(const ClimaApp()); // Punto de entrada de la app
}

class ClimaApp extends StatelessWidget {
  const ClimaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clima',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(), // Pantalla inicial
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ⚠ API Key de OpenWeatherMap (reemplazar con tu propia clave)
  static const String _apiKey = '90907f9b1645932fe01212706697d308';

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  // Lista de ciudades con sus IDs oficiales de OpenWeatherMap
  final Map<String, String> _ciudades = {
    "Ciudad de México, MX": "3530597",
    "Madrid, ES": "3117735",
    "Tokyo, JP": "1850147",
    "New York, US": "5128581",
    "Buenos Aires, AR": "3435910",
    "Santiago, CL": "3871336",
    "Toronto, CA": "6167865",
    "Paris, FR": "2988507",
    "Berlin, DE": "2950159",
    "Rome, IT": "3169070",
    "Sydney, AU": "2147714",
  };

  String _ciudadSeleccionada = "3530597"; // ID de Ciudad de México

  // Función que busca el clima llamando a la API
  Future<void> _buscarClima() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'id': _ciudadSeleccionada, // usamos el ID único
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'es',
    });

    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _data = json;
          _loading = false;
        });
      } else {
        String msg = 'Error ${resp.statusCode}';
        try {
          final j = jsonDecode(resp.body);
          if (j is Map && j['message'] is String) msg = j['message'];
        } catch (_) {}
        setState(() {
          _error = 'No se pudo obtener el clima: $msg';
          _loading = false;
          _data = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de red: $e'; // Ej. sin Internet
        _loading = false;
        _data = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _data != null;
    String? nombreCiudad;
    String? pais;
    String? descripcion;
    String? icono;
    num? temp;
    num? tempMin;
    num? tempMax;
    num? sensacion;
    num? humedad;

    if (hasData) {
      final d = _data!;
      nombreCiudad = d['name'];
      pais = (d['sys']?['country'])?.toString();
      final weather = (d['weather'] as List?)?.cast<Map<String, dynamic>>();
      if (weather != null && weather.isNotEmpty) {
        descripcion = weather.first['description']?.toString();
        icono = weather.first['icon']?.toString(); // Código del icono (ej. 10d)
      }
      final main = d['main'] as Map<String, dynamic>?;
      temp = main?['temp'];
      tempMin = main?['temp_min'];
      tempMax = main?['temp_max'];
      sensacion = main?['feels_like'];
      humedad = main?['humidity'];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App del Clima - Mónica Martín Bautista'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Menú desplegable de ciudades
              DropdownButton<String>(
                value: _ciudadSeleccionada,
                items: _ciudades.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.value,
                        child: Text(entry.key),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _ciudadSeleccionada = value;
                    });
                    _buscarClima();
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_loading) const LinearProgressIndicator(),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Muestra clima si hay datos
              if (hasData)
                _ClimaCard(
                  ciudad: nombreCiudad ?? '',
                  pais: pais ?? '',
                  descripcion: descripcion ?? '',
                  iconCode: icono,
                  temp: temp?.toDouble(),
                  tempMin: tempMin?.toDouble(),
                  tempMax: tempMax?.toDouble(),
                  sensacion: sensacion?.toDouble(),
                  humedad: humedad?.toInt(),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text('Selecciona una ciudad para ver su clima'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget tarjeta para mostrar clima actual
class _ClimaCard extends StatelessWidget {
  final String ciudad;
  final String pais;
  final String descripcion;
  final String? iconCode;
  final double? temp;
  final double? tempMin;
  final double? tempMax;
  final double? sensacion;
  final int? humedad;
  const _ClimaCard({
    required this.ciudad,
    required this.pais,
    required this.descripcion,
    required this.iconCode,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.sensacion,
    required this.humedad,
  });
  @override
  Widget build(BuildContext context) {
    final iconUrl = iconCode != null
        ? 'https://openweathermap.org/img/wn/$iconCode@4x.png'
        : null;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    '$ciudad${pais.isNotEmpty ? ", $pais" : ""}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (iconUrl != null)
                    Image.network(iconUrl, width: 120, height: 120),
                  const SizedBox(height: 8),
                  Text(
                    descripcion.isNotEmpty
                        ? (descripcion[0].toUpperCase() +
                              descripcion.substring(1))
                        : '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (temp != null)
                    Text(
                      '${temp!.toStringAsFixed(1)}°C',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (humedad != null)
                        _InfoChip(
                          icon: Icons.water_drop,
                          label: 'Humedad',
                          value: '$humedad%',
                        ),
                      if (sensacion != null)
                        _InfoChip(
                          icon: Icons.thermostat,
                          label: 'Sensación',
                          value: '${sensacion!.toStringAsFixed(1)}°C',
                        ),
                      if (tempMin != null)
                        _InfoChip(
                          icon: Icons.arrow_downward,
                          label: 'Mín',
                          value: '${tempMin!.toStringAsFixed(1)}°C',
                        ),
                      if (tempMax != null)
                        _InfoChip(
                          icon: Icons.arrow_upward,
                          label: 'Máx',
                          value: '${tempMax!.toStringAsFixed(1)}°C',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Chip reutilizable para mostrar pares "Etiqueta: Valor"
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon), label: Text('$label: $value'));
  }
}
