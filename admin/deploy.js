// Mandafesto Auto-Deploy Script
// This script regenerates the main site when new posts are published

async function deployPost(postData) {
    try {
        // Validate post data
        if (!postData.title || !postData.content || !postData.excerpt) {
            throw new Error('Missing required post fields');
        }

        // Load current posts
        const posts = await loadPosts();
        
        // Add or update post
        if (postData.id) {
            const index = posts.findIndex(p => p.id === postData.id);
            if (index !== -1) {
                posts[index] = { ...posts[index], ...postData, updatedAt: new Date().toISOString() };
            } else {
                throw new Error('Post not found for update');
            }
        } else {
            // New post
            postData.id = generateId();
            postData.createdAt = new Date().toISOString();
            postData.updatedAt = new Date().toISOString();
            posts.unshift(postData); // Add to beginning
        }

        // Save posts.json
        await savePosts(posts);
        
        // Regenerate index.html
        await generateIndexHTML(posts);
        
        // Commit to GitHub (if in production)
        if (typeof window !== 'undefined' && window.location.hostname === 'mandafesto.com') {
            await commitToGitHub(postData);
        }
        
        return { success: true, post: postData };
        
    } catch (error) {
        console.error('Deploy error:', error);
        return { success: false, error: error.message };
    }
}

async function loadPosts() {
    try {
        const response = await fetch('../posts.json');
        if (!response.ok) return [];
        return await response.json();
    } catch {
        return [];
    }
}

async function savePosts(posts) {
    // In a real deployment, this would save to GitHub or a backend
    // For now, we'll use localStorage as a demo
    localStorage.setItem('mandafesto_posts', JSON.stringify(posts));
}

async function generateIndexHTML(posts) {
    const template = await fetch('../index-template.html');
    let html = await template.text();
    
    // If template doesn't exist, use current index.html as base
    if (!template.ok) {
        const current = await fetch('../index.html');
        html = await current.text();
    }
    
    // Generate posts HTML
    const postsHTML = posts
        .filter(post => post.status === 'published')
        .map(post => generatePostHTML(post))
        .join('\n');
    
    // Replace posts section
    html = html.replace(
        /<!-- POSTS_START -->.*<!-- POSTS_END -->/s,
        `<!-- POSTS_START -->\n${postsHTML}\n        <!-- POSTS_END -->`
    );
    
    // Save new index.html (in production, this would commit to GitHub)
    console.log('Generated new index.html with posts:', posts.length);
    return html;
}

function generatePostHTML(post) {
    const date = new Date(post.publishedAt || post.createdAt).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
    
    if (post.type === 'link' && post.url) {
        // External link post
        return `
        <article class="post">
            <div class="post-meta">
                <span class="post-tag">${escapeHtml(post.category)}</span>
                ${date}
            </div>
            <h2>${escapeHtml(post.title)}</h2>
            <p class="post-excerpt">${escapeHtml(post.excerpt)}</p>
            <a href="${escapeHtml(post.url)}" target="_blank" class="read-toggle">Read more →</a>
        </article>`;
    } else {
        // Full post with content
        return `
        <article class="post">
            <div class="post-meta">
                <span class="post-tag">${escapeHtml(post.category)}</span>
                ${date}
            </div>
            <h2>${escapeHtml(post.title)}</h2>
            <p class="post-excerpt">${escapeHtml(post.excerpt)}</p>
            <button class="read-toggle" onclick="togglePost(this)">Read more →</button>
            <div class="post-body collapsed">
                ${formatPostContent(post.content)}
            </div>
        </article>`;
    }
}

function formatPostContent(content) {
    // Convert markdown-like formatting to HTML
    return content
        .split('\n\n')
        .map(paragraph => {
            paragraph = paragraph.trim();
            if (!paragraph) return '';
            
            // Handle blockquotes
            if (paragraph.startsWith('>')) {
                const quote = paragraph.replace(/^>\s*/gm, '');
                return `<blockquote>${escapeHtml(quote)}</blockquote>`;
            }
            
            // Handle regular paragraphs
            let html = escapeHtml(paragraph);
            html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
            html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');
            
            return `<p>${html}</p>`;
        })
        .join('\n                ');
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

async function commitToGitHub(postData) {
    // GitHub API integration for auto-commit
    // This would use the GitHub API to commit the updated files
    console.log('Would commit to GitHub:', postData.title);
    return true;
}

// Demo function to test deployment
async function testDeploy() {
    const testPost = {
        title: "Test Post from Admin",
        content: "This is a test post created from the admin interface.\n\n**Bold text** and *italic text* work.\n\n> This is a blockquote.\n\nRegular paragraph here.",
        excerpt: "This is a test post to verify the admin system is working correctly.",
        category: "Update",
        status: "published",
        type: "original"
    };
    
    const result = await deployPost(testPost);
    console.log('Deploy result:', result);
    return result;
}

// Export for use in editor
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { deployPost, loadPosts };
}

// Make available globally in browser
if (typeof window !== 'undefined') {
    window.mandafestoAdmin = { deployPost, loadPosts, testDeploy };
}