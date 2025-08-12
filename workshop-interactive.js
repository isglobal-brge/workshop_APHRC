// Workshop Interactive Features

document.addEventListener('DOMContentLoaded', function() {
    // Back to Top Button
    const backToTopButton = document.createElement('button');
    backToTopButton.innerHTML = '<i class="bi bi-arrow-up"></i>';
    backToTopButton.className = 'back-to-top';
    backToTopButton.setAttribute('aria-label', 'Back to top');
    document.body.appendChild(backToTopButton);

    // Show/hide back to top button
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            backToTopButton.classList.add('visible');
        } else {
            backToTopButton.classList.remove('visible');
        }
    });

    // Scroll to top when clicked
    backToTopButton.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });

    // Scroll Progress Indicator
    const scrollIndicator = document.createElement('div');
    scrollIndicator.className = 'scroll-indicator';
    document.body.appendChild(scrollIndicator);

    window.addEventListener('scroll', function() {
        const winScroll = document.body.scrollTop || document.documentElement.scrollTop;
        const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
        const scrolled = (winScroll / height) * 100;
        scrollIndicator.style.width = scrolled + '%';
    });

    // Add fade-in animation to elements as they appear
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -100px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Observe feature cards and resource cards
    document.querySelectorAll('.feature-card, .resource-card').forEach(el => {
        observer.observe(el);
    });

    // Add copy functionality to code blocks
    document.querySelectorAll('pre').forEach(block => {
        const button = document.createElement('button');
        button.className = 'code-copy-button';
        button.innerHTML = '<i class="bi bi-clipboard"></i> Copy';
        
        button.addEventListener('click', async () => {
            const code = block.querySelector('code').innerText;
            try {
                await navigator.clipboard.writeText(code);
                button.innerHTML = '<i class="bi bi-check"></i> Copied!';
                setTimeout(() => {
                    button.innerHTML = '<i class="bi bi-clipboard"></i> Copy';
                }, 2000);
            } catch (err) {
                console.error('Failed to copy:', err);
            }
        });
        
        block.style.position = 'relative';
        block.appendChild(button);
    });

    // Add smooth scrolling to anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add language labels to code blocks
    document.querySelectorAll('pre.sourceCode').forEach(block => {
        const classes = block.className.split(' ');
        const langClass = classes.find(c => c.startsWith('language-'));
        if (langClass) {
            const language = langClass.replace('language-', '').toUpperCase();
            block.setAttribute('data-language', language);
        }
    });

    // Server status indicator
    document.querySelectorAll('.server-status').forEach(status => {
        // This would typically check actual server status
        // For demo purposes, we'll just show it as online
        status.title = 'Server Online';
    });
});
