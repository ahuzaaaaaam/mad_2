# PizzApp - Flutter Mobile Application

A Flutter mobile application for ordering pizzas and other food items.

## Features

- Product catalog from API with local JSON fallback
- Shopping cart with local JSON storage
- Order history with local JSON storage
- Battery status monitoring
- Shake to add random product (accelerometer)
- Store locator with maps integration
- Settings with appearance options

## Data Storage

This application uses a hybrid approach for data storage:

- **Products**: Fetched from the API at `https://ssp-sem2-host.onrender.com/api/products` with local JSON fallback
- **Cart**: Stored locally in JSON files for mobile devices, with in-memory fallback for web
- **Order History**: Stored locally in JSON files for mobile devices, with in-memory fallback for web

Local JSON files are stored in the application documents directory and provide offline functionality.

## APIs

The application interacts with a Laravel backend API at `https://ssp-sem2-host.onrender.com/api/` for product data.

## Dependencies

See the `pubspec.yaml` file for a complete list of dependencies.
