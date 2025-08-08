# 💰 Finapp – AI-Powered Personal Finance Tracker

> A smart, cross-platform personal finance app built with Flutter and Flask, featuring AI-powered financial insights and comprehensive expense tracking.

---

## 🧩 Overview

**Finapp** is a comprehensive cross-platform personal finance management app that enables users to:
- Track income & expenses with detailed categorization
- Set and monitor budgets & savings goals  
- Analyze spending patterns with interactive charts
- Receive personalized AI-generated financial insights
- Get local notifications for financial reminders
- Export financial reports as PDF documents
- Manage user profiles with secure authentication

The app features a **Flutter frontend** with a clean, intuitive interface, a **Flask + SQLite backend** for secure data management, and a **local NLP model (DistilGPT2)** to generate contextual insights based on monthly transaction trends.

---

## 🛠️ Tech Stack

| Layer        | Technologies                                    |
|--------------|------------------------------------------------|
| Frontend     | Flutter 3.7+, Dart, Provider (State Management)|
| UI Components| Material Design, Syncfusion Charts, FL Chart   |
| Backend      | Python Flask, SQLAlchemy, SQLite, JWT          |
| AI/NLP       | HuggingFace Transformers (`distilgpt2`)       |
| Notifications| Flutter Local Notifications                    |
| Permissions  | Permission Handler                             |
| PDF Export   | Printing Package, PDF Generator                |
| Security     | JWT Authentication, bcrypt password hashing   |
| HTTP Client  | Dart HTTP package                              |

---

## ⚙️ Features

- 📊 **Expense Tracking**: Add and categorize income & expenses with detailed notes
- 🏷️ **Smart Categorization**: Organize transactions by customizable categories  
- 📅 **Monthly Summaries**: Automatic calculation of income, expenses, and savings
- 🧠 **AI-Powered Insights**: Personalized financial advice using machine learning
- 🎯 **Budget Management**: Set category-wise budgets and track spending
- 🏆 **Goal Setting**: Create and monitor savings goals with progress tracking
- 📊 **Interactive Analytics**: Visual charts and reports for spending analysis
- 📱 **Cross-Platform**: Native performance on Android, iOS, and desktop
- 🔔 **Local Notifications**: Reminders and financial alerts
- 📄 **PDF Reports**: Export financial summaries and reports
- 🔒 **Secure Authentication**: JWT-based user authentication with password encryption
- 👤 **Profile Management**: User profile with image upload capability

---

## 🧠 AI Insight Module

The backend analyzes **previous vs current month** financial data:
- Income & expense trend comparison
- Top spending category analysis
- Spending pattern identification
- Generates personalized insights using `distilgpt2` model

_Example Output_:
> “Your food spending increased this month. Try reducing takeout orders.”
**AI Analysis Factors**:
- Monthly income/expense changes
- Category-wise spending shifts  
- Historical spending patterns
- Comparative analysis between periods

---

## 📱 Project Structure

```
Finapp/
├── lib/                          # Flutter frontend source code
│   ├── main.dart                 # Application entry point
│   ├── app_state.dart           # Global state management with Provider
│   ├── screens/                 # UI screens
│   │   ├── login_screen.dart    # User authentication
│   │   ├── home_screen.dart     # Dashboard overview
│   │   ├── expense_tracking_screen.dart  # Transaction management
│   │   ├── budget_goals_screen.dart      # Budget and goals
│   │   ├── analytics_reports_screen.dart # Charts and analytics
│   │   └── profile_screen.dart  # User profile management
│   └── services/
│       └── api_service.dart     # Backend API communication
├── Backend/                     # Flask backend
│   ├── app.py                   # Main Flask application
│   └── requirements.txt         # Python dependencies
├── pubspec.yaml                 # Flutter dependencies
└── README.md                    # Project documentation
```

---

## 🗄️ Database Schema

### `User`
- `id` (Integer, Primary Key)
- `name` (String, 120 chars)
- `email` (String, 120 chars, Unique)
- `phone` (String, 20 chars)
- `password_hash` (String, 128 chars)
- `registered_on` (DateTime, Auto-generated)

### `Transaction`
- `id` (Integer, Primary Key)
- `user_id` (Integer, Foreign Key → User.id)
- `type` (String, 'income' or 'expense')
- `category` (String, 50 chars)
- `amount` (Float)
- `date` (DateTime, Auto-generated)
- `notes` (String, 255 chars, Optional)

### `BudgetCategory`
- `id` (Integer, Primary Key)
- `user_id` (Integer, Foreign Key → User.id)
- `category` (String, 50 chars)
- `budget` (Float)

### `Goal`
- `id` (Integer, Primary Key)
- `user_id` (Integer, Foreign Key → User.id)
- `title` (String, 120 chars)
- `target` (Float)
- `saved` (Float)
- `date` (String, 20 chars)

---

## 🚀 Getting Started

### ✅ Prerequisites
- Python 3.10+
- Flutter SDK 3.7.0+
- Dart SDK
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- Git

### ⚙️ Backend Setup

```bash
# Clone the repository
git clone https://github.com/Buvan501/Finapp.git
cd Finapp/Backend

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# On Windows:
.venv\Scripts\activate
# On macOS/Linux:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the Flask server
python app.py
```

The backend will run on `http://localhost:5000`

### 📱 Frontend Setup

```bash
# Navigate to project root
cd Finapp

# Install Flutter dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Update API base URL in lib/services/api_service.dart
# Replace the IP address with your backend server IP

# Run on emulator or connected device
flutter run

# Or build for specific platform
flutter build apk          # Android
flutter build ios          # iOS  
flutter build web          # Web
flutter build windows      # Windows
flutter build macos        # macOS
flutter build linux        # Linux
```

---

## 🔧 Configuration

### Backend Configuration
- Update `JWT_SECRET_KEY` in `Backend/app.py` for production
- Database is created automatically on first run
- Default port: 5000

### Frontend Configuration
- Update API base URL in `lib/services/api_service.dart`:
  ```dart
  static const String _baseUrl = 'http://YOUR_IP:5000';
  ```
- For local development, use your machine's IP address
- For production, use your server's domain/IP

---

## 📋 API Endpoints

### Authentication
- `POST /signup` - User registration
- `POST /login` - User login
- `GET /profile` - Get user profile (requires JWT)

### Transactions
- `POST /transaction` - Add new transaction
- `GET /transactions` - List all user transactions
- `GET /summary` - Get monthly summary

### Budget & Goals
- `GET /budgets` - Get budget categories with spending
- `POST /budgets` - Set/update budget for category
- `GET /goals` - List user goals
- `POST /goals` - Create new goal
- `PUT /goals` - Update existing goal

### AI Insights
- `GET /insights` - Get AI-generated financial insights

---

## 🧪 Testing

### Run Flutter Tests
```bash
flutter test
```

### Test Backend Locally
```bash
cd Backend
python -m pytest  # If tests exist
```

### Manual Testing
1. Start the backend server
2. Run the Flutter app
3. Test user registration/login
4. Add sample transactions
5. Check AI insights generation

---

## 🚀 Deployment

### Backend Deployment (Flask)
- Can be deployed on any cloud platform (AWS, Azure, DigitalOcean)
- Recommended: Use Gunicorn for production
- Set up environment variables for sensitive data

### Frontend Deployment
- **Android**: Build APK or AAB for Google Play Store
- **iOS**: Build for App Store Connect
- **Web**: Deploy to any static hosting service
- **Desktop**: Build platform-specific executables

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

For support, please open an issue in the GitHub repository or contact the maintainers.

---

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- HuggingFace for the transformers library
- Syncfusion for chart components
- Community contributors and testers