## 📸 PrakritiAI App

<img src="assets/jj.png" width="250"/>
<img src="assets/pppp4.png" width="250"/>

# PrakritiAI - Ayurvedic Health Analysis App

PrakritiAI is an intelligent Ayurvedic application that analyzes Vata, Pitta, and Kapha doshas to recommend personalized therapies, treatments, and clinics based on individual constitution.

## Features!!

- **Prakriti Analysis**: Determine your unique Ayurvedic constitution
- **Personalized Recommendations**: Get tailored therapy suggestions
- **Clinic Finder**: Locate nearby Ayurvedic practitioners and clinics
- **Health Insights**: Track and monitor your health journey

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+

### Setup!

1. Clone the repository:
```bash
git clone https://github.com/sandeepswain54/PrakritiAI-.git
cd PrakritiAI-
```

2. Create a `.env` file from `.env.example`:
```bash
cp .env.example .env
```

3. Add your credentials to `.env`:
```env
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
# ... other credentials
```

4. Install dependencies:
```bash
flutter pub get
```

5. Run the app:
```bash
flutter run
```

## Security

- Never commit `.env` file or sensitive credentials to version control
- See `.env.example` for environment variable templates
- All API keys and tokens should be loaded from environment variables

## Documentation

For more information about Flutter development, visit the [official Flutter docs](https://docs.flutter.dev/)
