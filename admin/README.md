# Mandafesto Admin System

A magic link authenticated blogging system for mandafesto.com.

## Features

- **Magic Link Authentication** - Secure email-based login
- **Rich Post Editor** - Write with markdown-like formatting
- **Live Preview** - See how your post will look
- **Auto-save** - Never lose your work
- **Mobile Friendly** - Works great on all devices

## Setup

### 1. Supabase Configuration

Run the SQL in `supabase-setup.sql` in your Supabase SQL Editor:

```sql
-- This creates the tables and functions needed for magic links
```

### 2. Update Email Settings

In the admin files, update the Supabase credentials:
- Replace `kxyqdzkoyuzszcyfvpee.supabase.co` with your project URL
- Replace `sb_publishable_aXDS4SvG7aMZKExyNPTbgA_mBzZdQZU` with your anon key

### 3. Deploy to GitHub Pages

1. Push the `mandafesto.com` folder to your GitHub repository
2. Enable GitHub Pages in repository settings
3. Set custom domain to `mandafesto.com`

## Usage

### Accessing Admin

1. Go to `mandafesto.com/admin`
2. Enter your email (amanda.bradford@gmail.com)
3. Click the magic link in your email
4. Start writing!

### Writing Posts

- **Title**: Keep under 60 characters for best SEO
- **Excerpt**: Write a compelling summary (shows on homepage)
- **Category**: Choose from predefined categories
- **Content**: Write using simple markdown:
  - `**bold**` for **bold text**
  - `*italic*` for *italic text*
  - `> quote` for blockquotes

### Keyboard Shortcuts

- `Ctrl+S` (Cmd+S) - Save draft
- `Ctrl+Enter` (Cmd+Enter) - Publish post

## File Structure

```
mandafesto.com/
├── index.html          # Main blog page
├── posts.json          # Posts data
├── admin/
│   ├── index.html      # Login page
│   ├── dashboard.html  # Posts management
│   ├── editor.html     # Post editor
│   ├── deploy.js       # Deployment logic
│   └── supabase-setup.sql # Database setup
└── README.md
```

## Security

- Only authorized emails can access admin
- Magic links expire in 15 minutes
- Sessions expire in 7 days
- All data stored in Supabase with RLS enabled

## Customization

### Adding Categories

Edit the `<select>` options in `editor.html`:

```html
<option value="NewCategory">New Category</option>
```

### Styling

The admin interface uses the same design system as the main site. Customize the CSS variables at the top of each HTML file.

### Email Templates

Modify the `send_magic_link` function in Supabase to customize the magic link email.

## Development

### Local Testing

1. Serve the files with any static server:
   ```bash
   python -m http.server 8000
   ```

2. Visit `localhost:8000/admin`

### Debugging

- Magic link tokens are returned in the API response for testing
- Check browser console for errors
- Use Supabase dashboard to view auth tables

## Production Deployment

### Email Integration

Replace the TODO in `send_magic_link` function with actual email sending:

```sql
-- Use Supabase Edge Functions or external email service
SELECT net.http_post(
    'https://api.sendgrid.com/v3/mail/send',
    -- Email data
);
```

### GitHub Auto-Deploy

The `deploy.js` script includes GitHub API integration for automatic commits when posts are published.

## Support

If you need help:
1. Check browser developer tools for errors
2. Verify Supabase functions are working
3. Test magic link generation manually
4. Ensure GitHub Pages is properly configured

---

**Happy writing! 📝**