# Supabase Integration Setup for AI Task Manager

This guide will help you set up Supabase integration for the AI Task Manager iOS app.

## Prerequisites

1. A Supabase account (free tier is sufficient)
2. Xcode 14+ with iOS 15+ deployment target
3. Basic understanding of SwiftUI and iOS development

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click "New Project"
3. Choose your organization
4. Name your project (e.g., "ai-task-manager")
5. Generate a strong database password
6. Select a region close to your users
7. Click "Create new project"

## Step 2: Set Up Database Schema

1. Once your project is created, go to the SQL Editor in your Supabase dashboard
2. Copy the contents of `ai-task-manager/Core/Database/supabase_schema.sql`
3. Paste it into the SQL Editor and run it
4. This will create the necessary tables, indexes, and security policies

**Note**: If you encounter a permission error like `42501: permission denied to set parameter`, simply ignore the JWT secret line - Supabase handles this automatically.

## Step 2.5: Enable Email Authentication (New!)

1. In your Supabase dashboard, go to Authentication > Settings
2. Under "Auth Providers", make sure "Email" is enabled
3. Configure email templates if desired (optional)
4. Set your site URL to your app's URL scheme (for production) or leave as default for development

## Step 3: Get Your Supabase Credentials

1. In your Supabase dashboard, go to Settings > API
2. Copy your:
   - Project URL (something like `https://your-project-id.supabase.co`)
   - Anon/Public key (starts with `eyJ...`)

## Step 4: Configure the iOS App

1. Open `ai-task-manager/Core/Network/SupabaseService.swift`
2. Replace the placeholder values in `SupabaseConfig`:

```swift
struct SupabaseConfig {
    static let projectUrl = "https://your-project-id.supabase.co"
    static let anonKey = "your-anon-key-here"
}
```

## Step 5: Switch from Mock to Real Supabase Service

1. Open `ai-task-manager/Core/Utils/DIContainer.swift`
2. In the `configureForProduction()` method, uncomment the line:

```swift
func configureForProduction() {
    // Uncomment this line:
    // supabaseService = SupabaseService()
}
```

3. Call this method in your app initialization if you want to use the real Supabase service instead of the mock.

## Step 6: Test the Integration

1. Build and run the app
2. You'll see the authentication screen first
3. Create a new account or sign in with existing credentials
4. Create a user profile in Settings
5. Create a new task - it should sync to Supabase with proper user isolation
6. Check your Supabase dashboard > Table Editor > tasks to see if the task was created
7. Sign out and sign in again to verify data persistence

## Database Structure

### Tables Created

1. **user_profiles**: Stores user profile information
   - `id`: UUID primary key
   - `auth_user_id`: Reference to Supabase auth user (UUID, foreign key)
   - `name`: User's name
   - `email`: User's email (unique)
   - `profile_image_url`: Optional profile image URL
   - `preferences`: JSON object with user preferences
   - `created_at`/`updated_at`: Timestamps

2. **tasks**: Stores all tasks
   - `id`: UUID primary key
   - `title`: Task title
   - `description`: Task description
   - `priority`: Enum (Low, Medium, High)
   - `category`: Enum (Meeting, Shopping, Work, etc.)
   - `is_completed`: Boolean
   - `created_at`: Creation timestamp
   - `due_date`: Optional due date
   - `estimated_duration`: AI-estimated duration
   - `keywords`: Array of keywords from NL processing
   - `user_profile_id`: Reference to user profile

## Features Included

- ✅ **User Authentication**: Sign up, sign in, sign out, password reset
- ✅ **Secure Data Access**: Row Level Security ensures users only see their own data
- ✅ **Real-time data sync** with Supabase
- ✅ **Offline-first architecture** (works without internet)
- ✅ **Multi-user support** with proper data isolation
- ✅ **User profile management**
- ✅ **Task analytics and insights**
- ✅ **Natural language processing integration**
- ✅ **Error handling and retry logic**
- ✅ **Session management** with automatic token refresh

## Security Notes

- **Row Level Security (RLS)** is enabled on all tables
- **Multi-user authentication** with proper data isolation
- **Users can only access their own data** through RLS policies
- **JWT tokens** are handled automatically by Supabase
- **Session management** includes automatic token refresh
- **Password reset** functionality via email

## Troubleshooting

### Common Issues

1. **"Failed to save task to cloud"**
   - Check your internet connection
   - Verify your Supabase URL and anon key are correct
   - Check the Supabase dashboard for any errors

2. **"Database connection failed"**
   - Ensure your Supabase project is active
   - Check if the database schema was applied correctly
   - Verify the project URL format

3. **"Permission denied to set parameter" during schema setup**
   - This is normal - Supabase doesn't allow setting JWT secrets directly
   - The schema will still work correctly, just ignore this error
   - All other tables and policies should be created successfully

4. **Tasks not appearing**
   - Check the Network tab in Xcode debugger
   - Look at Supabase logs in the dashboard
   - Verify RLS policies are applied correctly

### Development vs Production

- The app currently uses `MockSupabaseService` by default for development
- To use real Supabase, call `DIContainer.shared.configureForProduction()` in your app initialization
- You can switch between mock and real services for testing

## Optional Enhancements

1. **Add Authentication**: Implement Supabase Auth for user accounts
2. **Real-time Subscriptions**: Use Supabase real-time features for live updates
3. **File Storage**: Use Supabase Storage for profile images
4. **Edge Functions**: Add server-side AI processing with Supabase Edge Functions

## Support

If you encounter issues:
1. Check the Supabase documentation: [docs.supabase.com](https://docs.supabase.com)
2. Review the app's error logs in Xcode
3. Check Supabase dashboard logs and metrics
