-- Migration Script: Add Authentication Support
-- Run this in your Supabase SQL Editor to add auth support to existing schema

-- Step 1: Add the auth_user_id column to user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Step 2: Create index for the new column
CREATE INDEX IF NOT EXISTS idx_user_profiles_auth_user_id ON public.user_profiles(auth_user_id);

-- Step 3: Drop existing RLS policies that don't work with auth
DROP POLICY IF EXISTS "Allow all operations on user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Allow all operations on tasks" ON public.tasks;

-- Step 4: Create new RLS policies for user_profiles
-- Users can only access their own profile
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can delete own profile" ON public.user_profiles
    FOR DELETE USING (auth.uid() = auth_user_id);

-- Step 5: Create new RLS policies for tasks
-- Users can only access tasks linked to their profile
CREATE POLICY "Users can view own tasks" ON public.tasks
    FOR SELECT USING (
        user_profile_id IN (
            SELECT id FROM public.user_profiles WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own tasks" ON public.tasks
    FOR INSERT WITH CHECK (
        user_profile_id IN (
            SELECT id FROM public.user_profiles WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own tasks" ON public.tasks
    FOR UPDATE USING (
        user_profile_id IN (
            SELECT id FROM public.user_profiles WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own tasks" ON public.tasks
    FOR DELETE USING (
        user_profile_id IN (
            SELECT id FROM public.user_profiles WHERE auth_user_id = auth.uid()
        )
    );

-- Step 6: For development/testing - temporarily allow operations without auth
-- (Remove these policies when you have real authentication working)
CREATE POLICY "Allow anonymous operations on user_profiles" ON public.user_profiles
    FOR ALL USING (auth.uid() IS NULL) WITH CHECK (auth.uid() IS NULL);

CREATE POLICY "Allow anonymous operations on tasks" ON public.tasks
    FOR ALL USING (
        auth.uid() IS NULL OR 
        user_profile_id IN (
            SELECT id FROM public.user_profiles WHERE auth_user_id IS NULL
        )
    ) WITH CHECK (
        auth.uid() IS NULL OR 
        user_profile_id IN (
            SELECT id FROM public.user_profiles WHERE auth_user_id IS NULL
        )
    );

-- Step 7: Grant permissions (if not already granted)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.user_profiles TO anon, authenticated;
GRANT ALL ON public.tasks TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
