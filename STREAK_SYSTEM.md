# Streak System Implementation

## Overview
This productivity planning app now features a comprehensive streak system inspired by Duolingo and TikTok, with both global and per-task streak tracking.

## How It Works

### Global Streak
- **Requirement**: Complete ALL active plans for the day
- **Display**: Shown prominently on the main screen
- **Logic**: Only increases when every active plan has been completed that day
- **Reset**: Resets to 0 if you miss a day and have no skip days remaining

### Per-Task Streaks
- **Individual tracking**: Each plan maintains its own streak
- **Independent**: Can continue even if global streak breaks
- **Display**: Shown on each plan card with fire emoji
- **Best record**: Tracks the highest streak achieved for each plan

### Skip Day System
- **Monthly allowance**: 3 skip days per month
- **Automatic reset**: Skip count resets on the 1st of each month
- **Automatic usage**: Skip days are automatically used after 24 hours if tasks aren't completed
- **No manual intervention**: System handles skip days automatically to preserve streaks

## Push Notifications

### Daily Reminders
- **Time**: 9:00 AM daily
- **Message**: "Don't lose your streak! Complete all today's tasks 🔥"

### Plan-Specific Reminders
- **Time**: 6:00 PM daily
- **Message**: "Your [Plan Name] plan is waiting! Keep your streak alive."

### Skip Day Notifications
- **Trigger**: When skip day is automatically used after 24 hours
- **Message**: "You used X of your 3 monthly skips. Y skips left this month."

### Streak Lost Notifications
- **Trigger**: When streak breaks after using all skip days
- **Message**: "Streak lost 💔. Start fresh today and build a new streak! 💪"

### Milestone Celebrations
- **Triggers**: 7 days, 30 days, 100 days
- **Messages**: 
  - 7 days: "🔥 Amazing! You've maintained a 7-day streak!"
  - 30 days: "🔥🔥🔥 Incredible! 30 days of consistency!"
  - 100 days: "🔥🔥🔥🔥🔥 LEGENDARY! 100 days streak!"

### End-of-Day Warnings
- **Time**: 10:00 PM daily
- **Message**: "Last chance to save your streak! Complete your tasks before midnight."

## UI Features

### Main Screen
- **Global streak display**: Large fire icon with current streak count
- **Auto-skip tracker**: Shows remaining automatic skip days for the month
- **Risk indicator**: Orange warning when streak is at risk

### Plan Cards
- **Per-task streak**: Fire emoji with individual streak count
- **Best record**: Shows highest streak achieved for that plan
- **Progress tracking**: Visual progress bars and completion status

## Database Schema

### Global Streak Table
```sql
CREATE TABLE global_streak (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  currentStreak INTEGER DEFAULT 0,
  bestStreak INTEGER DEFAULT 0,
  lastCompletedDate TEXT NOT NULL,
  skipDaysUsedThisMonth INTEGER DEFAULT 0,
  lastSkipDate TEXT NOT NULL,
  currentMonth INTEGER NOT NULL,
  currentYear INTEGER NOT NULL
)
```

## Technical Implementation

### Key Classes
- `GlobalStreak`: Model for global streak data
- `NotificationService`: Handles all push notifications
- `PlanProvider`: Manages streak logic and state
- `StreakDisplay`: UI component for global streak

### Streak Logic Flow
1. User completes a task in any plan
2. System checks if all active plans are completed for today
3. If all plans completed:
   - Update global streak (continue or start new)
   - Check for milestone notifications
4. If not all plans completed:
   - Check if 24 hours have passed since last completion
   - Automatically use skip day if available
   - Reset streak if no skip days left

### End-of-Day Check
- Automatically runs when home screen loads
- Evaluates if all tasks were completed
- Updates global streak accordingly
- Triggers appropriate notifications

## Usage Tips

1. **Complete all active plans daily** to maintain your global streak
2. **Don't worry about skip days** - they're used automatically after 24 hours
3. **Check the auto-skip counter** to know how many grace days you have left
4. **Watch for risk indicators** when your streak is in danger
5. **Celebrate milestones** when you reach 7, 30, or 100 days

## Future Enhancements

- Calendar view with streak visualization
- Streak recovery options
- Social sharing of streak achievements
- Customizable notification times
- Streak statistics and analytics
