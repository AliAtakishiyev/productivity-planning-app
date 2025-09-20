# Productivity Planning App

A comprehensive Flutter mobile application for creating and managing long-term learning and productivity plans with a TikTok-inspired streak system.

<img width="1290" height="2796" alt="simulator_screenshot_996C5187-849E-4991-ADEA-5DFEBDB48D1E" src="https://github.com/user-attachments/assets/9fd976ff-1a68-47cc-bac6-013e8c176ed3" />




## 🚀 Features

### Core Functionality
- **Plan Creation**: Create long-term plans (e.g., "Learn Flutter") with customizable duration
- **Hierarchical Structure**: Automatic breakdown into Monthly → Weekly → Daily tasks
- **Progress Tracking**: Visual progress indicators at all levels
- **Streak System**: TikTok-style daily streak tracking to maintain motivation

### Plan Management
- **Monthly Plans**: Organize goals by month with progress tracking
- **Weekly Plans**: Break down monthly goals into manageable weekly chunks
- **Daily Tasks**: Specific actionable tasks for each day
- **Completion Tracking**: Mark tasks as complete to unlock next levels

### User Experience
- **Beautiful UI**: Modern Material Design 3 with gradient themes
- **Responsive Design**: Optimized for mobile devices
- **Dark/Light Theme**: Automatic theme switching based on system preference
- **Intuitive Navigation**: Tab-based interface for easy plan management

### Streak System
- **Daily Streaks**: Track consecutive days of task completion
- **Best Streak Records**: Keep track of personal bests
- **Visual Feedback**: Fire icons and progress indicators
- **Motivation**: Gamified experience to encourage consistency

## 🛠️ Technical Stack

- **Framework**: Flutter 3.0+
- **State Management**: Provider pattern
- **Local Storage**: SharedPreferences for data persistence
- **UI Components**: Custom widgets with Material Design 3
- **Date Handling**: Intl package for date formatting
- **Architecture**: Clean architecture with separation of concerns

## 📱 Screenshots

The app includes the following main screens:
- **Home Screen**: Overview of all plans with streak display
- **Create Plan**: Form to create new plans with duration selection
- **Plan Detail**: Detailed view with monthly/weekly/daily breakdowns
- **Monthly View**: Expandable cards showing weekly progress
- **Weekly View**: List of all weekly plans across months
- **Daily View**: Recent daily tasks with completion checkboxes

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 2.17.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android device/emulator or iOS device/simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd productivity-planning-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── plan.dart            # Plan, MonthlyPlan, WeeklyPlan, DailyTask
├── providers/                # State management
│   └── plan_provider.dart   # Plan operations and streak tracking
├── screens/                  # UI screens
│   ├── home_screen.dart     # Main home screen
│   ├── create_plan_screen.dart # Plan creation form
│   └── plan_detail_screen.dart # Detailed plan view
├── widgets/                  # Reusable UI components
│   ├── plan_card.dart       # Plan overview cards
│   ├── streak_display.dart  # Streak tracking widget
│   └── monthly_plan_card.dart # Monthly plan expansion cards
└── utils/                    # Utilities
    └── app_theme.dart       # Theme configuration
```

## 📋 Usage Guide

### Creating a Plan
1. Tap the "+" button on the home screen
2. Enter plan title (e.g., "Learn Flutter")
3. Add description of your goal
4. Select start date
5. Choose duration in months (1-12)
6. Tap "Create Plan"

### Managing Tasks
1. **Monthly Level**: View overall monthly progress
2. **Weekly Level**: See weekly breakdowns and completion status
3. **Daily Level**: Mark individual tasks as complete
4. **Streak Maintenance**: Complete daily tasks to maintain your streak

### Understanding Progress
- **Green**: Completed successfully
- **Blue**: Currently active/in progress
- **Grey**: Not yet started
- **Progress Bars**: Visual representation of completion percentage

## 🔥 Streak System

The streak system works like TikTok:
- Complete daily tasks to maintain your streak
- Streaks reset if you miss a day
- Track your best streak record
- Visual fire icons increase with streak length
- Motivation to maintain consistency

## 🎯 Example Use Case

**Learning Flutter in 3 Months:**
- **Month 1**: Dart basics and Flutter fundamentals
- **Month 2**: UI development and state management
- **Month 3**: Advanced concepts and project building

Each month is broken into weeks, and each week into daily tasks. Complete daily tasks to unlock weekly goals, complete weekly goals to unlock monthly goals, and complete monthly goals to finish your plan!

## 🚧 Future Enhancements

- [ ] Calendar integration
- [ ] Push notifications for daily reminders
- [ ] Progress analytics and charts
- [ ] Social sharing of achievements
- [ ] Cloud sync across devices
- [ ] Custom task templates
- [ ] Export/import functionality

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for design guidelines
- TikTok for inspiring the streak system concept

---

**Built with ❤️ using Flutter**
