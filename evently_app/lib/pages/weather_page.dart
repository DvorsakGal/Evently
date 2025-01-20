import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:evently_app/auth.dart';
import 'package:dio/dio.dart';
import 'package:evently_app/consts.dart';

class WeatherPage extends StatefulWidget {
  final String location;

  const WeatherPage({Key? key, required this.location}) : super(key: key);

  @override
  State<WeatherPage> createState() => _HomePageState();
}

class _HomePageState extends State<WeatherPage> {
  Widget _title() {
    return const Text("Weather app");
  }

  // WEATHER VARIABLES:
  final WeatherFactory _weatherFactory =
      WeatherFactory(OPENWEATHER_API_KEY); //to se zaj vec ne uporablja
  final TextEditingController _cityController = TextEditingController();

  Weather? _weather;
  List<dynamic>? _forecast;

  // API calls with DIO
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "https://api.openweathermap.org/data/2.5/",
    queryParameters: {"appId": OPENWEATHER_API_KEY, "units": "metric"},
  ));

  Future<void> fetchWeather(String city) async {
    try {
      final currentWeatherResponse = await _dio.get(
        "weather",
        queryParameters: {
          "q": city,
          "units": "metric",
        },
      );
      final forecastResponse =
          await _dio.get("forecast", queryParameters: {"q": city});

      print("Weather Data: ${currentWeatherResponse.data}"); // Debugging

      setState(() {
        _weather = Weather(currentWeatherResponse.data);
        _forecast = forecastResponse.data["list"];
      });
    } catch (e) {
      print("Error: $e");
    }

    print("Weather Object: $_weather");
    print("Temperature in _weather: ${_weather?.temperature?.celsius}");
  }

  @override
  void initState() {
    super.initState();
    fetchWeather(widget.location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (_weather == null) {
      return const Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
          ],
        ),
      );
    }
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 10,
          ),
          //_searchBar(),
          _locationHeader(),
          _dateTimeInfo(),
          _weatherIcon(),
          _currentTemp(),
          _extraInfo(),
          _forecastList(),
        ],
      ),
    );
  }

  Widget _locationHeader() {
    return Text(
      _weather?.areaName ?? "",
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = _weather!.date!;
    return Column(
      children: [
        Text(
          DateFormat("h:mm a").format(now),
          style: const TextStyle(
            fontSize: 35,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat("EEEE").format(now),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "  ${DateFormat("d.M.y").format(now)}",
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _weatherIcon() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.2,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: NetworkImage(
                    "https://openweathermap.org/img/wn/${_weather?.weatherIcon}@4x.png")),
          ),
        ),
        Text(
          _weather?.weatherDescription ?? "",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _currentTemp() {
    final double? temp = (_weather?.temperature?.celsius)! + 273;

    return Text(
      "${temp!.toStringAsFixed(0)}°C",
      style: const TextStyle(
        color: Colors.black,
        fontSize: 80,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _extraInfo() {
    final double? maxtemp = (_weather?.tempMax?.celsius)! + 273;
    final double? mintemp = (_weather?.tempMin?.celsius)! + 273;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.15,
      width: MediaQuery.sizeOf(context).width * 0.80,
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Max: ${maxtemp?.toStringAsFixed(0)}°C",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              Text(
                "Min: ${mintemp?.toStringAsFixed(0)}°C",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              )
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Wind: ${_weather?.windSpeed?.toStringAsFixed(0)} m/s",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              Text(
                "Humidity: ${_weather?.humidity?.toStringAsFixed(0)} %",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: "Enter city name",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              fetchWeather(_cityController.text);
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _forecastList() {
    if (_forecast == null) return SizedBox();

    return Expanded(
      child: ListView.builder(
        itemCount: _forecast!.length,
        itemBuilder: (context, index) {
          final item = _forecast![index];
          final date =
              DateFormat("EEEE, d.MM").format(DateTime.parse(item["dt_txt"]));
          final temp = item["main"]["temp"];
          final description = item["weather"][0]["description"];
          final iconCode = item["weather"][0]["icon"]; // Icon code from API
          return ListTile(
            title: Text("$date: ${temp.toStringAsFixed(0)}°C"),
            subtitle: Text(description),
            trailing: Image.network(
              "https://openweathermap.org/img/wn/$iconCode@2x.png",
            ),
          );
        },
      ),
    );
  }
}

/*
image: NetworkImage(
                    "https://openweathermap.org/img/wn/${_weather?.weatherIcon}@4x.png"))
children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.04,
          ),
          _userUid(),
          _signOutButton(),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.06,
          ),
          _locationHeader(),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.06,
          ),
          _dateTimeInfo(),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.05,
          ),
          _weatherIcon(),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.02,
          ),
          _currentTemp(),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.02,
          ),
          _extraInfo(),
        ],
*/