import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  // Stores the response returned by the FastAPI server.
  String message = 'Press the button to test the API.';

  // Controls the loading state while the request is running.
  bool isLoading = false;

  // Calls the FastAPI /test endpoint.
  Future<void> testConnection() async {
    setState(() {
      isLoading = true;
      message = 'Connecting to AgriGuide API...';
    });

    try {
      // Sends the HTTP request to FastAPI.
      final response = await ApiService().testApi();

      // Displays the response received from FastAPI.
      setState(() {
        message = response;
      });
    } catch (error) {
      // Displays an error if the connection fails.
      setState(() {
        message = 'Connection failed:\n$error';
      });
    } finally {
      // Stops the loading indicator.
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Displays the current API response.
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              // Runs the API test.
              ElevatedButton(
                onPressed: isLoading ? null : testConnection,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Test API'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}