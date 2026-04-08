-- Mandafesto Admin Magic Link Authentication
-- Run this in your Supabase SQL Editor to set up the magic link system

-- Create magic links table
CREATE TABLE IF NOT EXISTS magic_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '15 minutes'),
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create auth sessions table
CREATE TABLE IF NOT EXISTS admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_token TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create posts table (for future use)
CREATE TABLE IF NOT EXISTS blog_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    category TEXT DEFAULT 'Personal',
    status TEXT DEFAULT 'draft',
    author_email TEXT NOT NULL,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to send magic link
CREATE OR REPLACE FUNCTION send_magic_link(
    user_email TEXT,
    site_name TEXT DEFAULT 'Mandafesto',
    redirect_url TEXT DEFAULT 'https://mandafesto.com/admin'
)
RETURNS JSON AS $$
DECLARE
    magic_token TEXT;
    result JSON;
BEGIN
    -- Only allow Amanda's email
    IF user_email NOT IN ('amanda.bradford@gmail.com', 'pearlouise.bradford@gmail.com') THEN
        RETURN json_build_object('error', 'Unauthorized email address');
    END IF;

    -- Generate magic token
    magic_token := encode(gen_random_bytes(32), 'base64');
    
    -- Clean up old tokens
    DELETE FROM magic_links 
    WHERE email = user_email AND (expires_at < NOW() OR used = TRUE);
    
    -- Insert new token
    INSERT INTO magic_links (token, email, expires_at)
    VALUES (magic_token, user_email, NOW() + INTERVAL '15 minutes');
    
    -- TODO: In production, send email here
    -- For now, we'll return the token for testing
    result := json_build_object(
        'success', TRUE,
        'message', 'Magic link sent',
        'debug_token', magic_token,
        'debug_url', redirect_url || '?token=' || magic_token
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to verify magic link
CREATE OR REPLACE FUNCTION verify_magic_link(magic_token TEXT)
RETURNS JSON AS $$
DECLARE
    user_email TEXT;
    session_token TEXT;
    result JSON;
BEGIN
    -- Find valid magic link
    SELECT email INTO user_email
    FROM magic_links
    WHERE token = magic_token 
        AND expires_at > NOW() 
        AND used = FALSE
    LIMIT 1;
    
    IF user_email IS NULL THEN
        RETURN json_build_object('valid', FALSE, 'error', 'Invalid or expired token');
    END IF;
    
    -- Mark token as used
    UPDATE magic_links SET used = TRUE WHERE token = magic_token;
    
    -- Generate session token
    session_token := encode(gen_random_bytes(32), 'base64');
    
    -- Clean up old sessions
    DELETE FROM admin_sessions 
    WHERE email = user_email AND expires_at < NOW();
    
    -- Create new session
    INSERT INTO admin_sessions (session_token, email, expires_at)
    VALUES (session_token, user_email, NOW() + INTERVAL '7 days');
    
    result := json_build_object(
        'valid', TRUE,
        'session_token', session_token,
        'expires_at', (NOW() + INTERVAL '7 days')::TEXT,
        'email', user_email
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to verify session token
CREATE OR REPLACE FUNCTION verify_session(session_token TEXT)
RETURNS JSON AS $$
DECLARE
    user_email TEXT;
    result JSON;
BEGIN
    SELECT email INTO user_email
    FROM admin_sessions
    WHERE session_token = session_token 
        AND expires_at > NOW()
    LIMIT 1;
    
    IF user_email IS NULL THEN
        RETURN json_build_object('valid', FALSE, 'error', 'Invalid or expired session');
    END IF;
    
    result := json_build_object(
        'valid', TRUE,
        'email', user_email
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Clean up old records (run periodically)
CREATE OR REPLACE FUNCTION cleanup_auth_tables()
RETURNS VOID AS $$
BEGIN
    DELETE FROM magic_links WHERE expires_at < NOW() - INTERVAL '1 day';
    DELETE FROM admin_sessions WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Grant permissions (adjust based on your Supabase setup)
GRANT EXECUTE ON FUNCTION send_magic_link TO anon, authenticated;
GRANT EXECUTE ON FUNCTION verify_magic_link TO anon, authenticated;
GRANT EXECUTE ON FUNCTION verify_session TO anon, authenticated;
GRANT EXECUTE ON FUNCTION cleanup_auth_tables TO authenticated;

-- Row Level Security (RLS) policies
ALTER TABLE magic_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

-- Allow read access to magic_links for verification
CREATE POLICY "Allow magic link verification" ON magic_links FOR SELECT TO anon, authenticated USING (TRUE);
CREATE POLICY "Allow session verification" ON admin_sessions FOR SELECT TO anon, authenticated USING (TRUE);

-- Only allow Amanda's emails to manage posts
CREATE POLICY "Only Amanda can manage posts" ON blog_posts FOR ALL TO authenticated 
USING (author_email IN ('amanda.bradford@gmail.com', 'pearlouise.bradford@gmail.com'));

-- Test the functions (remove in production)
-- SELECT send_magic_link('amanda.bradford@gmail.com');
-- SELECT verify_magic_link('test-token');