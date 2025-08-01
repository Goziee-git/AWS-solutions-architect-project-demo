// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('nav a, .footer-links a, .hero a');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            // Only apply to links that start with #
            if(this.getAttribute('href').startsWith('#')) {
                e.preventDefault();
                
                const targetId = this.getAttribute('href');
                
                // Skip if it's just #
                if(targetId === '#') return;
                
                const targetElement = document.querySelector(targetId);
                
                if(targetElement) {
                    // Get the header height for offset
                    const headerHeight = document.querySelector('header').offsetHeight;
                    
                    // Calculate the position to scroll to
                    const targetPosition = targetElement.offsetTop - headerHeight;
                    
                    // Smooth scroll to the target
                    window.scrollTo({
                        top: targetPosition,
                        behavior: 'smooth'
                    });
                    
                    // Update active link
                    navLinks.forEach(link => link.classList.remove('active'));
                    this.classList.add('active');
                }
            }
        });
    });
    
    // Handle contact form submission
    const contactForm = document.getElementById('contactForm');
    if(contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get form values
            const name = document.getElementById('name').value;
            const email = document.getElementById('email').value;
            const message = document.getElementById('message').value;
            
            // Simple validation
            if(!name || !email || !message) {
                alert('Please fill in all fields');
                return;
            }
            
            // In a real application, you would send this data to a server
            // For this demo, we'll just show a success message
            alert(`Thank you, ${name}! Your message has been received. We'll get back to you soon.`);
            
            // Reset the form
            contactForm.reset();
        });
    }
    
    // Handle newsletter form submission
    const newsletterForm = document.getElementById('newsletterForm');
    if(newsletterForm) {
        newsletterForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get email value
            const email = this.querySelector('input[type="email"]').value;
            
            // Simple validation
            if(!email) {
                alert('Please enter your email address');
                return;
            }
            
            // In a real application, you would send this data to a server
            // For this demo, we'll just show a success message
            alert(`Thank you! You've been subscribed to our newsletter.`);
            
            // Reset the form
            newsletterForm.reset();
        });
    }
    
    // Highlight active navigation link based on scroll position
    window.addEventListener('scroll', function() {
        const scrollPosition = window.scrollY;
        
        // Get all sections
        const sections = document.querySelectorAll('section');
        const headerHeight = document.querySelector('header').offsetHeight;
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop - headerHeight - 100; // Offset for better UX
            const sectionBottom = sectionTop + section.offsetHeight;
            
            if(scrollPosition >= sectionTop && scrollPosition < sectionBottom) {
                // Get the corresponding nav link
                const id = section.getAttribute('id');
                if(id) {
                    navLinks.forEach(link => {
                        link.classList.remove('active');
                        if(link.getAttribute('href') === `#${id}`) {
                            link.classList.add('active');
                        }
                    });
                }
            }
        });
        
        // Add shadow to header on scroll
        const header = document.querySelector('header');
        if(scrollPosition > 50) {
            header.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.1)';
        } else {
            header.style.boxShadow = 'none';
        }
    });
    
    // Simple image lazy loading
    const images = document.querySelectorAll('img');
    
    if('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if(entry.isIntersecting) {
                    const image = entry.target;
                    image.src = image.dataset.src;
                    observer.unobserve(image);
                }
            });
        });
        
        images.forEach(img => {
            if(img.dataset.src) {
                imageObserver.observe(img);
            }
        });
    } else {
        // Fallback for browsers that don't support IntersectionObserver
        images.forEach(img => {
            if(img.dataset.src) {
                img.src = img.dataset.src;
            }
        });
    }
});
